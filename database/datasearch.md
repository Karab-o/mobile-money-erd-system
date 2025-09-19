# MoMo SMS System – Data Dictionary

This document defines the structure of the database schema for the MoMo SMS System.  
It describes all tables, their columns, data types, constraints, and purposes.  
Sample rows are provided to illustrate how the schema works in practice.

---

## 1. Users Table

Holds information about customers, agents, and merchants.

| Column Name   | Data Type                     | Constraints                              | Description                              |
|---------------|-------------------------------|------------------------------------------|------------------------------------------|
| UserID        | INT                           | PRIMARY KEY, AUTO_INCREMENT              | Unique identifier for each user           |
| FullName      | VARCHAR(100)                  | NOT NULL                                 | User’s full name                          |
| PhoneNumber   | VARCHAR(20)                   | NOT NULL, UNIQUE                         | Mobile phone number (unique per user)     |
| AccountNumber | VARCHAR(50)                   | UNIQUE                                   | Internal account number for MoMo account  |
| UserType      | ENUM('Customer','Agent','Merchant') | NOT NULL                           | Role type of the user                     |
| Balance       | DECIMAL(15,2)                 | DEFAULT 0.00                             | Current account balance                   |
| CreatedDate   | TIMESTAMP                     | DEFAULT CURRENT_TIMESTAMP                | Account creation timestamp                |
| Status        | ENUM('Active','Suspended','Closed') | DEFAULT 'Active'                   | Status of the user’s account              |

**Sample Data**

| UserID | FullName      | PhoneNumber | AccountNumber | UserType  | Balance   | CreatedDate          | Status  |
|--------|---------------|-------------|---------------|-----------|-----------|----------------------|---------|
| 1      | Alice Nkurunziza | +250788111111 | ACC1001      | Customer | 50000.00  | 2025-01-02 09:15:00 | Active  |
| 2      | John Mukiza   | +250788222222 | ACC2001      | Agent    | 150000.00 | 2025-01-05 14:45:00 | Active  |
| 3      | Kigali Supermarket | +250788333333 | ACC3001      | Merchant | 200000.00 | 2025-01-07 10:20:00 | Active  |

---

## 2. Transaction_Categories Table

Defines the different categories/types of transactions.

| Column Name       | Data Type     | Constraints                                | Description                               |
|-------------------|---------------|--------------------------------------------|-------------------------------------------|
| TransactionTypeID | INT           | PRIMARY KEY, AUTO_INCREMENT                | Unique identifier for each transaction type |
| CategoryName      | VARCHAR(50)   | NOT NULL, UNIQUE                           | Category name (e.g., Deposit, Withdrawal) |
| Description       | TEXT          | NULL                                       | Detailed description of the category      |
| IsActive          | BOOLEAN       | DEFAULT TRUE                               | Whether the category is active            |
| CreatedDate       | TIMESTAMP     | DEFAULT CURRENT_TIMESTAMP                  | Timestamp when the category was created   |

**Sample Data**

| TransactionTypeID | CategoryName | Description                 | IsActive | CreatedDate          |
|-------------------|--------------|-----------------------------|----------|----------------------|
| 1                 | Deposit      | Cash deposit via agent      | TRUE     | 2025-01-01 08:00:00 |
| 2                 | Withdrawal   | Cash withdrawal via agent   | TRUE     | 2025-01-01 08:00:00 |
| 3                 | Transfer     | P2P money transfer          | TRUE     | 2025-01-01 08:00:00 |
| 4                 | Payment      | Payment to merchant/service | TRUE     | 2025-01-01 08:00:00 |

---

## 3. Transactions Table

Stores information about all transactions processed in the system.

| Column Name        | Data Type       | Constraints                                | Description                               |
|--------------------|-----------------|--------------------------------------------|-------------------------------------------|
| TransactionID      | VARCHAR(50)     | PRIMARY KEY                                | Unique transaction identifier             |
| TransactionTypeID  | INT             | FOREIGN KEY → Transaction_Categories       | Transaction category/type                  |
| SenderID           | INT             | FOREIGN KEY → Users(UserID)                | ID of user initiating the transaction     |
| ReceiverID         | INT             | FOREIGN KEY → Users(UserID), NULL          | ID of user receiving the transaction      |
| Amount             | DECIMAL(15,2)   | NOT NULL, CHECK (Amount > 0)               | Amount involved in the transaction        |
| Fee                | DECIMAL(10,2)   | DEFAULT 0.00                               | Transaction fee charged                   |
| BalanceAfter       | DECIMAL(15,2)   | NOT NULL                                   | Sender’s balance after transaction        |
| TransactionDateTime| TIMESTAMP       | DEFAULT CURRENT_TIMESTAMP                  | Date and time of transaction              |
| ExternalReference  | VARCHAR(100)    | NULL                                       | Reference ID from external system         |
| Status             | ENUM('Pending','Completed','Failed','Cancelled') | DEFAULT 'Pending' | Status of the transaction |
| Description        | VARCHAR(255)    | NULL                                       | Optional transaction description          |

**Sample Data**

| TransactionID | TransactionTypeID | SenderID | ReceiverID | Amount   | Fee   | BalanceAfter | TransactionDateTime | ExternalReference | Status     | Description          |
|---------------|-------------------|----------|------------|----------|-------|--------------|---------------------|------------------|------------|----------------------|
| TX10001       | 1                 | 2        | 1          | 20000.00 | 200.00| 130000.00    | 2025-01-10 09:00:00 | REF98765         | Completed | Cash deposit         |
| TX10002       | 3                 | 1        | 3          | 5000.00  | 50.00 | 44950.00     | 2025-01-11 11:15:00 | REF12345         | Completed | Payment transfer     |

---

## 4. Transaction_Participants Table

Links transactions to multiple participants (e.g., customers, agents, merchants).

| Column Name    | Data Type       | Constraints                                | Description                               |
|----------------|-----------------|--------------------------------------------|-------------------------------------------|
| TransactionID  | VARCHAR(50)     | FOREIGN KEY → Transactions(TransactionID)  | Related transaction ID                    |
| UserID         | INT             | FOREIGN KEY → Users(UserID)                | Participant’s user ID                     |
| Role           | ENUM('Sender','Receiver','Agent','Merchant') | NOT NULL     | Role of the participant                   |
| AmountInvolved | DECIMAL(15,2)   | NULL                                       | Amount specific to this participant       |
| CreatedDate    | TIMESTAMP       | DEFAULT CURRENT_TIMESTAMP                  | Timestamp of participant record           |

**Sample Data**

| TransactionID | UserID | Role     | AmountInvolved | CreatedDate          |
|---------------|--------|----------|----------------|----------------------|
| TX10001       | 2      | Agent    | 20000.00       | 2025-01-10 09:00:00 |
| TX10001       | 1      | Customer | 20000.00       | 2025-01-10 09:00:00 |
| TX10002       | 1      | Sender   | 5000.00        | 2025-01-11 11:15:00 |
| TX10002       | 3      | Merchant | 5000.00        | 2025-01-11 11:15:00 |

---

## 5. System_Logs Table

Tracks all system events, errors, and audits for compliance and debugging.

| Column Name   | Data Type       | Constraints                                | Description                               |
|---------------|-----------------|--------------------------------------------|-------------------------------------------|
| LogID         | BIGINT          | PRIMARY KEY, AUTO_INCREMENT                | Unique identifier for each log entry      |
| TransactionID | VARCHAR(50)     | FOREIGN KEY → Transactions(TransactionID), NULL | Related transaction (if any)        |
| LogDateTime   | TIMESTAMP       | DEFAULT CURRENT_TIMESTAMP                  | Timestamp of log entry                    |
| Message       | TEXT            | NOT NULL                                   | Content/details of the log entry          |
| LogType       | ENUM('OTP','Info','Error','Warning','Debug') | NOT NULL      | Type/category of the log                  |
| UserID        | INT             | FOREIGN KEY → Users(UserID), NULL          | Related user (if applicable)              |
| IPAddress     | VARCHAR(45)     | NULL                                       | IP address of the client                  |
| UserAgent     | VARCHAR(255)    | NULL                                       | User agent string of the client           |

**Sample Data**

| LogID | TransactionID | LogDateTime         | Message                     | LogType | UserID | IPAddress     | UserAgent            |
|-------|---------------|---------------------|-----------------------------|---------|--------|---------------|----------------------|
| 1     | TX10001       | 2025-01-10 09:00:05 | Deposit successful          | Info    | 1      | 192.168.1.10  | Mozilla/5.0          |
| 2     | TX10002       | 2025-01-11 11:15:10 | Payment to merchant success | Info    | 1      | 192.168.1.15  | Chrome/119.0         |
| 3     | NULL          | 2025-01-12 08:45:30 | OTP sent to +250788111111   | OTP     | 1      | 192.168.1.20  | Safari/17.2          |

---

## Notes

- All **foreign keys** enforce referential integrity.  
- ENUM values are designed to support **business-specific roles and statuses**.  
- CHECK constraints ensure valid data entry (e.g., positive transaction amounts).  
- Composite keys in **Transaction_Participants** prevent duplicate participant records.  
- This schema ensures **data consistency, auditability, and scalability** for mobile money operations.
