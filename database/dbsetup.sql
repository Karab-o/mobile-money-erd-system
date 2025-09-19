-- =====================================================
-- Mobile Money SMS System - Database Setup Script
-- =====================================================
-- Team: [Your Team Name]
-- Date: September 2025
-- Description: Complete database schema for MoMo SMS processing system

-- Drop database if exists (for clean setup)
DROP DATABASE IF EXISTS momo_sms_system;

-- Create database
CREATE DATABASE momo_sms_system 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE momo_sms_system;

-- =====================================================
-- Table 1: USERS (Customers, Agents, Merchants)
-- =====================================================
CREATE TABLE Users (
    UserID INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique identifier for each user',
    FullName VARCHAR(100) NOT NULL COMMENT 'Complete name of the user',
    PhoneNumber VARCHAR(15) NOT NULL UNIQUE COMMENT 'Mobile phone number (unique identifier)',
    AccountNumber VARCHAR(20) UNIQUE COMMENT 'Account number for formal accounts',
    UserType ENUM('Customer', 'Agent', 'Merchant') NOT NULL COMMENT 'Type of user in the system',
    Balance DECIMAL(15,2) DEFAULT 0.00 COMMENT 'Current account balance',
    CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Account creation timestamp',
    LastLoginDate TIMESTAMP NULL COMMENT 'Last system access timestamp',
    IsActive BOOLEAN DEFAULT TRUE COMMENT 'Account status flag',
    
    -- Constraints
    CONSTRAINT chk_balance_positive CHECK (Balance >= 0),
    CONSTRAINT chk_phone_format CHECK (PhoneNumber REGEXP '^[0-9+]{10,15}$')
) ENGINE=InnoDB COMMENT='Stores all system users: customers, agents, and merchants';

-- Index for performance
CREATE INDEX idx_users_phone ON Users(PhoneNumber);
CREATE INDEX idx_users_type ON Users(UserType);
CREATE INDEX idx_users_active ON Users(IsActive);

-- =====================================================
-- Table 2: TRANSACTION_CATEGORIES (Payment Types)
-- =====================================================
CREATE TABLE Transaction_Categories (
    TransactionTypeID INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique transaction type identifier',
    CategoryName VARCHAR(50) NOT NULL UNIQUE COMMENT 'Name of transaction category',
    Description TEXT COMMENT 'Detailed description of the transaction type',
    FeeStructure JSON COMMENT 'Fee calculation rules in JSON format',
    IsActive BOOLEAN DEFAULT TRUE COMMENT 'Whether this category is currently available',
    CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Category creation date'
) ENGINE=InnoDB COMMENT='Defines all types of transactions supported';

-- Index for performance
CREATE INDEX idx_categories_active ON Transaction_Categories(IsActive);

-- =====================================================
-- Table 3: TRANSACTIONS (Core Transaction Records)
-- =====================================================
CREATE TABLE Transactions (
    TransactionID VARCHAR(50) PRIMARY KEY COMMENT 'Unique transaction identifier',
    TransactionTypeID INT NOT NULL COMMENT 'Reference to transaction category',
    SenderID INT NOT NULL COMMENT 'User who initiates the transaction',
    ReceiverID INT NULL COMMENT 'User who receives the transaction (null for some types)',
    Amount DECIMAL(15,2) NOT NULL COMMENT 'Transaction amount',
    Fee DECIMAL(15,2) DEFAULT 0.00 COMMENT 'Transaction fee charged',
    BalanceAfter DECIMAL(15,2) COMMENT 'Sender balance after transaction',
    TransactionDateTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Transaction timestamp',
    ExternalReference VARCHAR(100) COMMENT 'External system reference (bank, utility)',
    Status ENUM('Pending', 'Completed', 'Failed', 'Cancelled') DEFAULT 'Pending' COMMENT 'Transaction status',
    Description TEXT COMMENT 'Transaction description or notes',
    
    -- Foreign Key Constraints
    FOREIGN KEY (TransactionTypeID) REFERENCES Transaction_Categories(TransactionTypeID) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (SenderID) REFERENCES Users(UserID) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (ReceiverID) REFERENCES Users(UserID) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
        
    -- Business Logic Constraints
    CONSTRAINT chk_amount_positive CHECK (Amount > 0),
    CONSTRAINT chk_fee_non_negative CHECK (Fee >= 0),
    CONSTRAINT chk_balance_non_negative CHECK (BalanceAfter >= 0)
) ENGINE=InnoDB COMMENT='Core transaction records with complete audit trail';

-- Indexes for performance
CREATE INDEX idx_transactions_sender ON Transactions(SenderID);
CREATE INDEX idx_transactions_receiver ON Transactions(ReceiverID);
CREATE INDEX idx_transactions_datetime ON Transactions(TransactionDateTime);
CREATE INDEX idx_transactions_status ON Transactions(Status);
CREATE INDEX idx_transactions_type ON Transactions(TransactionTypeID);

-- =====================================================
-- Table 4: SYSTEM_LOGS (Audit Trail)
-- =====================================================
CREATE TABLE System_Logs (
    LogID INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique log entry identifier',
    TransactionID VARCHAR(50) NULL COMMENT 'Related transaction (if applicable)',
    LogDateTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Log entry timestamp',
    LogType ENUM('INFO', 'WARNING', 'ERROR', 'DEBUG', 'SECURITY') NOT NULL COMMENT 'Type of log entry',
    Message TEXT NOT NULL COMMENT 'Log message content',
    IPAddress VARCHAR(45) COMMENT 'IP address of the request (IPv4/IPv6)',
    UserAgent TEXT COMMENT 'User agent string',
    UserID INT NULL COMMENT 'User associated with this log entry',
    
    -- Foreign Key Constraints
    FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID) 
        ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) 
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Complete system activity and audit log';

-- Indexes for performance
CREATE INDEX idx_logs_datetime ON System_Logs(LogDateTime);
CREATE INDEX idx_logs_type ON System_Logs(LogType);
CREATE INDEX idx_logs_transaction ON System_Logs(TransactionID);

-- =====================================================
-- Table 5: TRANSACTION_PARTICIPANTS (Many-to-Many Resolution)
-- =====================================================
CREATE TABLE Transaction_Participants (
    TransactionID VARCHAR(50) NOT NULL COMMENT 'Reference to transaction',
    UserID INT NOT NULL COMMENT 'Reference to participating user',
    Role ENUM('Sender', 'Receiver', 'Agent', 'Merchant') NOT NULL COMMENT 'Role in this transaction',
    ProcessedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When this participant was processed',
    
    -- Composite Primary Key
    PRIMARY KEY (TransactionID, UserID),
    
    -- Foreign Key Constraints
    FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (UserID) REFERENCES Users(UserID) 
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Junction table resolving many-to-many transaction relationships';

-- Indexes for performance
CREATE INDEX idx_participants_role ON Transaction_Participants(Role);

-- =====================================================
-- SECURITY ENHANCEMENTS
-- =====================================================

-- Create dedicated database user with limited privileges
CREATE USER IF NOT EXISTS 'momo_app'@'localhost' IDENTIFIED BY 'SecurePassword123!';
GRANT SELECT, INSERT, UPDATE ON momo_sms_system.* TO 'momo_app'@'localhost';
GRANT DELETE ON momo_sms_system.System_Logs TO 'momo_app'@'localhost';

-- Create read-only user for reporting
CREATE USER IF NOT EXISTS 'momo_readonly'@'localhost' IDENTIFIED BY 'ReadOnly123!';
GRANT SELECT ON momo_sms_system.* TO 'momo_readonly'@'localhost';

-- =====================================================
-- SAMPLE DATA INSERTION
-- =====================================================

-- Insert Transaction Categories
INSERT INTO Transaction_Categories (CategoryName, Description, FeeStructure) VALUES
('P2P_Transfer', 'Person-to-person money transfer', '{"flat_fee": 100, "percentage": 0.01}'),
('Agent_Deposit', 'Cash deposit through agent', '{"flat_fee": 50, "percentage": 0.005}'),
('Agent_Withdrawal', 'Cash withdrawal through agent', '{"flat_fee": 75, "percentage": 0.008}'),
('Merchant_Payment', 'Payment to merchant', '{"flat_fee": 25, "percentage": 0.003}'),
('Utility_Bill', 'Utility bill payment', '{"flat_fee": 150, "percentage": 0.002}'),
('Airtime_Purchase', 'Mobile airtime purchase', '{"flat_fee": 20, "percentage": 0.001}');

-- Insert Sample Users
INSERT INTO Users (FullName, PhoneNumber, AccountNumber, UserType, Balance) VALUES
('John Doe Customer', '+250788123456', 'ACC001', 'Customer', 50000.00),
('Jane Smith Customer', '+250788234567', 'ACC002', 'Customer', 75000.00),
('Agent Mike Wilson', '+250788345678', 'AGT001', 'Agent', 500000.00),
('Merchant Store ABC', '+250788456789', 'MER001', 'Merchant', 25000.00),
('Customer Mary Johnson', '+250788567890', 'ACC003', 'Customer', 30000.00),
('Agent Sarah Brown', '+250788678901', 'AGT002', 'Agent', 750000.00);

-- Insert Sample Transactions
INSERT INTO Transactions (TransactionID, TransactionTypeID, SenderID, ReceiverID, Amount, Fee, BalanceAfter, ExternalReference, Status, Description) VALUES
('TXN20250919001', 1, 1, 2, 10000.00, 150.00, 39850.00, NULL, 'Completed', 'Money transfer to Jane Smith'),
('TXN20250919002', 2, 1, 3, 25000.00, 125.00, 14725.00, 'DEP001', 'Completed', 'Cash deposit via Agent Mike'),
('TXN20250919003', 4, 2, 4, 5000.00, 40.00, 69960.00, 'PAY001', 'Completed', 'Payment to Merchant Store ABC'),
('TXN20250919004', 5, 5, NULL, 15000.00, 180.00, 14820.00, 'UTIL001', 'Completed', 'Electricity bill payment'),
('TXN20250919005', 6, 1, NULL, 3000.00, 50.00, 11675.00, 'AIR001', 'Completed', 'Airtime purchase'),
('TXN20250919006', 3, 5, 6, 20000.00, 235.00, -5415.00, 'WD001', 'Failed', 'Insufficient balance for withdrawal');

-- Insert Transaction Participants
INSERT INTO Transaction_Participants (TransactionID, UserID, Role) VALUES
('TXN20250919001', 1, 'Sender'),
('TXN20250919001', 2, 'Receiver'),
('TXN20250919002', 1, 'Receiver'),
('TXN20250919002', 3, 'Agent'),
('TXN20250919003', 2, 'Sender'),
('TXN20250919003', 4, 'Merchant'),
('TXN20250919004', 5, 'Sender'),
('TXN20250919005', 1, 'Sender'),
('TXN20250919006', 5, 'Sender'),
('TXN20250919006', 6, 'Agent');

-- Insert System Logs
INSERT INTO System_Logs (TransactionID, LogType, Message, IPAddress, UserID) VALUES
('TXN20250919001', 'INFO', 'P2P transfer completed successfully', '192.168.1.100', 1),
('TXN20250919002', 'INFO', 'Agent deposit processed', '192.168.1.101', 3),
('TXN20250919003', 'INFO', 'Merchant payment completed', '192.168.1.102', 2),
('TXN20250919004', 'INFO', 'Utility bill payment processed', '192.168.1.103', 5),
('TXN20250919005', 'INFO', 'Airtime purchase successful', '192.168.1.100', 1),
('TXN20250919006', 'ERROR', 'Transaction failed: Insufficient balance', '192.168.1.104', 5);

-- =====================================================
-- PERFORMANCE OPTIMIZATION
-- =====================================================

-- Additional composite indexes for common queries
CREATE INDEX idx_transactions_sender_date ON Transactions(SenderID, TransactionDateTime);
CREATE INDEX idx_transactions_receiver_date ON Transactions(ReceiverID, TransactionDateTime);
CREATE INDEX idx_logs_user_type ON System_Logs(UserID, LogType);

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- View for transaction summary with user details
CREATE VIEW v_transaction_summary AS
SELECT 
    t.TransactionID,
    t.TransactionDateTime,
    tc.CategoryName,
    u1.FullName AS SenderName,
    u1.PhoneNumber AS SenderPhone,
    u2.FullName AS ReceiverName,
    u2.PhoneNumber AS ReceiverPhone,
    t.Amount,
    t.Fee,
    t.Status
FROM Transactions t
JOIN Transaction_Categories tc ON t.TransactionTypeID = tc.TransactionTypeID
JOIN Users u1 ON t.SenderID = u1.UserID
LEFT JOIN Users u2 ON t.ReceiverID = u2.UserID;

-- View for user balance summary
CREATE VIEW v_user_balances AS
SELECT 
    UserID,
    FullName,
    PhoneNumber,
    UserType,
    Balance,
    CASE 
        WHEN Balance > 100000 THEN 'High'
        WHEN Balance > 10000 THEN 'Medium'
        ELSE 'Low'
    END AS BalanceCategory
FROM Users 
WHERE IsActive = TRUE;

-- =====================================================
-- STORED PROCEDURES FOR COMMON OPERATIONS
-- =====================================================

DELIMITER //

-- Procedure to process a P2P transfer
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
    
    -- Calculate total amount to deduct
    SET total_deduction = p_amount + p_fee;
    
    -- Get sender's current balance
    SELECT Balance INTO sender_balance FROM Users WHERE UserID = p_sender_id;
    
    -- Check if sufficient balance
    IF sender_balance >= total_deduction THEN
        -- Start transaction
        START TRANSACTION;
        
        -- Update sender balance
        UPDATE Users 
        SET Balance = Balance - total_deduction 
        WHERE UserID = p_sender_id;
        
        -- Update receiver balance
        UPDATE Users 
        SET Balance = Balance + p_amount 
        WHERE UserID = p_receiver_id;
        
        -- Insert transaction record
        INSERT INTO Transactions (TransactionID, TransactionTypeID, SenderID, ReceiverID, Amount, Fee, BalanceAfter, Status)
        VALUES (p_transaction_id, 1, p_sender_id, p_receiver_id, p_amount, p_fee, sender_balance - total_deduction, 'Completed');
        
        -- Log the transaction
        INSERT INTO System_Logs (TransactionID, LogType, Message, UserID)
        VALUES (p_transaction_id, 'INFO', CONCAT('P2P transfer completed: ', p_amount), p_sender_id);
        
        COMMIT;
    ELSE
        -- Log failed transaction
        INSERT INTO System_Logs (LogType, Message, UserID)
        VALUES ('ERROR', CONCAT('P2P transfer failed: Insufficient balance for transaction ', p_transaction_id), p_sender_id);
    END IF;
END //

DELIMITER ;

-- =====================================================
-- TRIGGERS FOR AUDIT TRAIL
-- =====================================================

DELIMITER //

-- Trigger to log balance changes
CREATE TRIGGER tr_user_balance_update
AFTER UPDATE ON Users
FOR EACH ROW
BEGIN
    IF OLD.Balance != NEW.Balance THEN
        INSERT INTO System_Logs (LogType, Message, UserID)
        VALUES ('INFO', CONCAT('Balance updated from ', OLD.Balance, ' to ', NEW.Balance), NEW.UserID);
    END IF;
END //

DELIMITER ;

-- =====================================================
-- FINAL STATUS CHECK
-- =====================================================

-- Display table creation status
SELECT 
    TABLE_NAME,
    TABLE_ROWS,
    TABLE_COMMENT
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'momo_sms_system'
ORDER BY TABLE_NAME;

-- Display sample data counts
SELECT 'Users' AS TableName, COUNT(*) AS RecordCount FROM Users
UNION ALL
SELECT 'Transaction_Categories', COUNT(*) FROM Transaction_Categories
UNION ALL
SELECT 'Transactions', COUNT(*) FROM Transactions
UNION ALL
SELECT 'Transaction_Participants', COUNT(*) FROM Transaction_Participants
UNION ALL
SELECT 'System_Logs', COUNT(*) FROM System_Logs;

-- =====================================================
-- END OF SCRIPT
-- =====================================================