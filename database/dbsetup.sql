-- =====================================================
-- Mobile Money SMS System Database
-- =====================================================

SET FOREIGN_KEY_CHECKS = 0;
SET sql_mode = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';

-- Drop existing DB
DROP DATABASE IF EXISTS momo_sms_system;
CREATE DATABASE momo_sms_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE momo_sms_system;

-- =====================================================
-- Table: Users
-- =====================================================
CREATE TABLE Users (
    UserID INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each user',
    FullName VARCHAR(100) NOT NULL COMMENT 'Complete name of the user',
    PhoneNumber VARCHAR(15) NOT NULL UNIQUE COMMENT 'Mobile phone number',
    AccountNumber VARCHAR(20) UNIQUE COMMENT 'Account number for formal accounts',
    UserType ENUM('Customer', 'Agent', 'Merchant') NOT NULL COMMENT 'User role type',
    Balance DECIMAL(15,2) DEFAULT 0.00 COMMENT 'Current account balance',
    CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Account creation timestamp',
    LastLoginDate TIMESTAMP NULL COMMENT 'Last login timestamp',
    IsActive BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Account status flag',
    CONSTRAINT chk_phone_format CHECK (PhoneNumber REGEXP '^[0-9+]{10,15}$'),
    CONSTRAINT chk_balance_non_negative CHECK (Balance >= 0)
) ENGINE=InnoDB;

CREATE INDEX idx_users_phone ON Users(PhoneNumber);
CREATE INDEX idx_users_type ON Users(UserType);
CREATE INDEX idx_users_active ON Users(IsActive);

-- =====================================================
-- Table: Transaction Categories
-- =====================================================
CREATE TABLE Transaction_Categories (
    TransactionTypeID INT AUTO_INCREMENT PRIMARY KEY,
    CategoryName VARCHAR(50) NOT NULL UNIQUE,
    Description TEXT,
    FeeStructure JSON,
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE INDEX idx_categories_active_status ON Transaction_Categories(IsActive);

-- =====================================================
-- Table: Transactions
-- =====================================================
DELIMITER //

CREATE TABLE Transactions (
    TransactionID VARCHAR(50) PRIMARY KEY,
    TransactionTypeID INT NOT NULL,
    SenderID INT NOT NULL,
    ReceiverID INT NULL,
    Amount DECIMAL(15,2) NOT NULL,
    Fee DECIMAL(15,2) DEFAULT 0.00,
    BalanceAfter DECIMAL(15,2) NOT NULL,
    InitialBalance DECIMAL(15,2) NOT NULL,
    TransactionDateTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ExternalReference VARCHAR(100) UNIQUE,
    Status ENUM('Pending', 'Completed', 'Failed', 'Cancelled') DEFAULT 'Pending',
    Description TEXT,
    CONSTRAINT chk_amount_positive CHECK (Amount > 0),
    CONSTRAINT chk_fee_non_negative CHECK (Fee >= 0),
    CONSTRAINT chk_balance_non_negative_status CHECK (BalanceAfter >= 0),
    FOREIGN KEY (TransactionTypeID) REFERENCES Transaction_Categories(TransactionTypeID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (SenderID) REFERENCES Users(UserID) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (ReceiverID) REFERENCES Users(UserID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TRIGGER trg_check_sender_receiver_insert
BEFORE INSERT ON Transactions
FOR EACH ROW
BEGIN
    IF NEW.SenderID = NEW.ReceiverID THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'SenderID and ReceiverID cannot be the same.';
    END IF;
END;
//

CREATE TRIGGER trg_check_sender_receiver_update
BEFORE UPDATE ON Transactions
FOR EACH ROW
BEGIN
    IF NEW.SenderID = NEW.ReceiverID THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'SenderID and ReceiverID cannot be the same.';
    END IF;
END;
//

DELIMITER ;


CREATE INDEX idx_transactions_sender ON Transactions(SenderID);
CREATE INDEX idx_transactions_receiver ON Transactions(ReceiverID);
CREATE INDEX idx_transactions_type ON Transactions(TransactionTypeID);
CREATE INDEX idx_transactions_datetime ON Transactions(TransactionDateTime);
CREATE INDEX idx_transactions_status ON Transactions(Status);

-- =====================================================
-- Table: Transaction Participants
-- =====================================================
CREATE TABLE Transaction_Participants (
    TransactionID VARCHAR(50) NOT NULL,
    UserID INT NOT NULL,
    Role ENUM('Sender', 'Receiver', 'Agent', 'Merchant') NOT NULL,
    ProcessedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (TransactionID, UserID),
    FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_participants_role ON Transaction_Participants(Role);

-- =====================================================
-- Table: SMS Notifications
-- =====================================================
CREATE TABLE SMS (
    SMSID INT AUTO_INCREMENT PRIMARY KEY,
    TransactionID VARCHAR(50),
    Message VARCHAR(500),
    UserID INT,
    FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_sms_transaction ON SMS(TransactionID);
CREATE INDEX idx_sms_user ON SMS(UserID);

-- =====================================================
-- Table: System Logs
-- =====================================================
CREATE TABLE System_Logs (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    TransactionID VARCHAR(50) NULL,
    LogDateTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    LogType ENUM('INFO','WARNING','ERROR','DEBUG','SECURITY') NOT NULL,
    Message TEXT NOT NULL,
    IPAddress VARCHAR(45),
    UserAgent TEXT,
    UserID INT NULL,
    FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_logs_datetime ON System_Logs(LogDateTime);
CREATE INDEX idx_logs_type ON System_Logs(LogType);
CREATE INDEX idx_logs_transaction ON System_Logs(TransactionID);

-- =====================================================
-- Stored Procedure: Process P2P Transfer
-- =====================================================
DELIMITER //
CREATE PROCEDURE ProcessP2PTransfer(
    IN p_transaction_id VARCHAR(50),
    IN p_sender_id INT,
    IN p_receiver_id INT,
    IN p_amount DECIMAL(15,2),
    IN p_fee DECIMAL(15,2)
)
BEGIN
    DECLARE sender_balance DECIMAL(15,2);
    DECLARE total_deduction DECIMAL(15,2);
    SET total_deduction = p_amount + p_fee;
    SELECT Balance INTO sender_balance FROM Users WHERE UserID = p_sender_id;

    IF sender_balance >= total_deduction THEN
        START TRANSACTION;
        UPDATE Users SET Balance = Balance - total_deduction WHERE UserID = p_sender_id;
        UPDATE Users SET Balance = Balance + p_amount WHERE UserID = p_receiver_id;
        INSERT INTO Transactions(TransactionID, TransactionTypeID, SenderID, ReceiverID, Amount, Fee, BalanceAfter, InitialBalance, Status)
        VALUES(p_transaction_id, 1, p_sender_id, p_receiver_id, p_amount, p_fee, sender_balance - total_deduction, sender_balance, 'Completed');
        INSERT INTO System_Logs(TransactionID, LogType, Message, UserID)
        VALUES(p_transaction_id, 'INFO', CONCAT('P2P transfer completed: ', p_amount), p_sender_id);
        COMMIT;
    ELSE
        INSERT INTO System_Logs(LogType, Message, UserID)
        VALUES('ERROR', CONCAT('P2P transfer failed: Insufficient balance for transaction ', p_transaction_id), p_sender_id);
    END IF;
END //
DELIMITER ;

-- =====================================================
-- Trigger: Log User Balance Changes
-- =====================================================
DELIMITER //
CREATE TRIGGER tr_user_balance_update
AFTER UPDATE ON Users
FOR EACH ROW
BEGIN
    IF OLD.Balance != NEW.Balance THEN
        INSERT INTO System_Logs(LogType, Message, UserID)
        VALUES('INFO', CONCAT('Balance updated from ', OLD.Balance, ' to ', NEW.Balance), NEW.UserID);
    END IF;
END //
DELIMITER ;

SET FOREIGN_KEY_CHECKS = 1;
