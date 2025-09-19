-- =====================================================
-- Mobile Money System - Sample Queries & Results
-- =====================================================
-- Team Member: Karabo Divine
-- Purpose: Demonstrate database functionality with sample queries
-- Instructions: Run these queries after executing database_setup.sql

-- =====================================================
-- 1. BASIC CRUD OPERATIONS
-- =====================================================

-- CREATE: Insert a new user
INSERT INTO Users (FullName, PhoneNumber, AccountNumber, UserType, Balance) 
VALUES ('Test Customer', '+250788999888', 'ACC999', 'Customer', 15000.00);

-- Expected Result: 1 row affected
-- Query OK, 1 row affected (0.01 sec)

-- READ: Get all active users
SELECT UserID, FullName, PhoneNumber, UserType, Balance, IsActive
FROM Users 
WHERE IsActive = TRUE
ORDER BY UserID;

-- Expected Results:
-- +--------+----------------------+----------------+----------+----------+----------+
-- | UserID | FullName             | PhoneNumber    | UserType | Balance  | IsActive |
-- +--------+----------------------+----------------+----------+----------+----------+
-- |      1 | Bwiza Lisa           | +250788123456  | Customer | 50000.00 |        1 |
-- |      2 | Rwema Sammy          | +250788234567  | Customer | 75000.00 |        1 |
-- |      3 | Agent Karabo Sidney  | +250788345678  | Agent    | 500000.00|        1 |
-- |      4 | Keza Lola            | +250788456789  | Merchant | 25000.00 |        1 |
-- |      5 | Rugero Brian         | +250788567890  | Customer | 30000.00 |        1 |
-- |      6 | Agent Rubimbura      | +250788678901  | Agent    | 750000.00|        1 |
-- |      7 | Kami Riley           | +250788999888  | Customer | 15000.00 |        1 |
-- +--------+----------------------+----------------+----------+----------+----------+
-- 7 rows in set (0.00 sec)

-- UPDATE: Modify user balance
UPDATE Users 
SET Balance = Balance + 5000.00 
WHERE UserID = 7;

-- Expected Result: 1 row affected
-- Query OK, 1 row affected (0.01 sec)
-- Rows matched: 1  Changed: 1  Warnings: 0

-- DELETE: Remove test user (soft delete by setting IsActive = FALSE)
UPDATE Users 
SET IsActive = FALSE 
WHERE UserID = 7;

-- Expected Result: 1 row affected

-- =====================================================
-- 2. TRANSACTION ANALYSIS QUERIES
-- =====================================================

-- Get transaction summary with user details
SELECT 
    t.TransactionID,
    DATE(t.TransactionDateTime) as TransactionDate,
    tc.CategoryName,
    sender.FullName as SenderName,
    receiver.FullName as ReceiverName,
    t.Amount,
    t.Fee,
    t.Status
FROM Transactions t
JOIN Transaction_Categories tc ON t.TransactionTypeID = tc.TransactionTypeID
JOIN Users sender ON t.SenderID = sender.UserID
LEFT JOIN Users receiver ON t.ReceiverID = receiver.UserID
ORDER BY t.TransactionDateTime DESC;

-- Expected Results:
-- +----------------+----------------+------------------+----------------------+----------------------+----------+--------+-----------+
-- | TransactionID  | TransactionDate| CategoryName     | SenderName           | ReceiverName         | Amount   | Fee    | Status    |
-- +----------------+----------------+------------------+----------------------+----------------------+----------+--------+-----------+
-- | TXN20250919006 | 2025-09-19     | Agent_Withdrawal | Customer Mary Johnson| Agent Sarah Brown    | 20000.00 | 235.00 | Failed    |
-- | TXN20250919005 | 2025-09-19     | Airtime_Purchase | John Doe Customer    | NULL                 | 3000.00  | 50.00  | Completed |
-- | TXN20250919004 | 2025-09-19     | Utility_Bill     | Customer Mary Johnson| NULL                 | 15000.00 | 180.00 | Completed |
-- | TXN20250919003 | 2025-09-19     | Merchant_Payment | Jane Smith Customer  | Merchant Store ABC   | 5000.00  | 40.00  | Completed |
-- | TXN20250919002 | 2025-09-19     | Agent_Deposit    | John Doe Customer    | Agent Mike Wilson    | 25000.00 | 125.00 | Completed |
-- | TXN20250919001 | 2025-09-19     | P2P_Transfer     | John Doe Customer    | Jane Smith Customer  | 10000.00 | 150.00 | Completed |
-- +----------------+----------------+------------------+----------------------+----------------------+----------+--------+-----------+
-- 6 rows in set (0.01 sec)

-- Daily transaction volume by category
SELECT 
    tc.CategoryName,
    COUNT(*) as TransactionCount,
    SUM(t.Amount) as TotalAmount,
    SUM(t.Fee) as TotalFees,
    AVG(t.Amount) as AvgAmount
FROM Transactions t
JOIN Transaction_Categories tc ON t.TransactionTypeID = tc.TransactionTypeID
WHERE DATE(t.TransactionDateTime) = CURDATE()
GROUP BY tc.CategoryName
ORDER BY TotalAmount DESC;

-- Expected Results:
-- +------------------+------------------+-------------+-----------+-----------+
-- | CategoryName     | TransactionCount | TotalAmount | TotalFees | AvgAmount |
-- +------------------+------------------+-------------+-----------+-----------+
-- | Agent_Deposit    |                1 |    25000.00 |    125.00 |  25000.00 |
-- | Agent_Withdrawal |                1 |    20000.00 |    235.00 |  20000.00 |
-- | Utility_Bill     |                1 |    15000.00 |    180.00 |  15000.00 |
-- | P2P_Transfer     |                1 |    10000.00 |    150.00 |  10000.00 |
-- | Merchant_Payment |                1 |     5000.00 |     40.00 |   5000.00 |
-- | Airtime_Purchase |                1 |     3000.00 |     50.00 |   3000.00 |
-- +------------------+------------------+-------------+-----------+-----------+
-- 6 rows in set (0.00 sec)

-- =====================================================
-- 3. USER BALANCE AND ACTIVITY ANALYSIS
-- =====================================================

-- User balance summary with activity indicators
SELECT 
    u.UserID,
    u.FullName,
    u.UserType,
    u.Balance,
    CASE 
        WHEN u.Balance > 100000 THEN 'High Balance'
        WHEN u.Balance > 10000 THEN 'Medium Balance'
        ELSE 'Low Balance'
    END as BalanceCategory,
    COUNT(t.TransactionID) as TransactionCount,
    COALESCE(SUM(CASE WHEN t.SenderID = u.UserID THEN t.Amount + t.Fee ELSE 0 END), 0) as TotalSent,
    COALESCE(SUM(CASE WHEN t.ReceiverID = u.UserID THEN t.Amount ELSE 0 END), 0) as TotalReceived
FROM Users u
LEFT JOIN Transactions t ON (u.UserID = t.SenderID OR u.UserID = t.ReceiverID)
WHERE u.IsActive = TRUE
GROUP BY u.UserID, u.FullName, u.UserType, u.Balance
ORDER BY u.Balance DESC;

-- Expected Results:
-- +--------+----------------------+----------+----------+----------------+------------------+-----------+---------------+
-- | UserID | FullName             | UserType | Balance  | BalanceCategory| TransactionCount | TotalSent | TotalReceived |
-- +--------+----------------------+----------+----------+----------------+------------------+-----------+---------------+
-- |      6 | Agent Sarah Brown    | Agent    | 750000.00| High Balance   |                1 |      0.00 |      20000.00 |
-- |      3 | Agent Mike Wilson    | Agent    | 500000.00| High Balance   |                1 |      0.00 |      25000.00 |
-- |      2 | Jane Smith Customer  | Customer |  75000.00| Medium Balance |                2 |   5040.00 |      10000.00 |
-- |      1 | John Doe Customer    | Customer |  50000.00| Medium Balance |                3 |  38300.00 |      25000.00 |
-- |      5 | Customer Mary Johnson| Customer |  30000.00| Medium Balance |                2 |  35415.00 |       0.00 |
-- |      4 | Merchant Store ABC   | Merchant |  25000.00| Medium Balance |                1 |      0.00 |       5000.00 |
-- +--------+----------------------+----------+----------+----------------+------------------+-----------+---------------+
-- 6 rows in set (0.01 sec)

-- =====================================================
-- 4. RELATIONSHIP QUERIES (MANY-TO-MANY)
-- =====================================================

-- Transaction participants with roles
SELECT 
    tp.TransactionID,
    t.TransactionDateTime,
    tp.Role,
    u.FullName,
    u.PhoneNumber,
    u.UserType,
    t.Amount,
    t.Status
FROM Transaction_Participants tp
JOIN Transactions t ON tp.TransactionID = t.TransactionID
JOIN Users u ON tp.UserID = u.UserID
ORDER BY t.TransactionDateTime DESC, tp.TransactionID, tp.Role;

-- Expected Results:
-- +----------------+---------------------+----------+----------------------+----------------+----------+----------+-----------+
-- | TransactionID  | TransactionDateTime | Role     | FullName             | PhoneNumber    | UserType | Amount   | Status    |
-- +----------------+---------------------+----------+----------------------+----------------+----------+----------+-----------+
-- | TXN20250919006 | 2025-09-19 10:45:30| Agent    | Agent Sarah Brown    | +250788678901  | Agent    | 20000.00 | Failed    |
-- | TXN20250919006 | 2025-09-19 10:45:30| Sender   | Customer Mary Johnson| +250788567890  | Customer | 20000.00 | Failed    |
-- | TXN20250919005 | 2025-09-19 10:45:30| Sender   | John Doe Customer    | +250788123456  | Customer | 3000.00  | Completed |
-- | TXN20250919004 | 2025-09-19 10:45:30| Sender   | Customer Mary Johnson| +250788567890  | Customer | 15000.00 | Completed |
-- | TXN20250919003 | 2025-09-19 10:45:30| Merchant | Merchant Store ABC   | +250788456789  | Merchant | 5000.00  | Completed |
-- | TXN20250919003 | 2025-09-19 10:45:30| Sender   | Jane Smith Customer  | +250788234567  | Customer | 5000.00  | Completed |
-- | TXN20250919002 | 2025-09-19 10:45:30| Agent    | Agent Mike Wilson    | +250788345678  | Agent    | 25000.00 | Completed |
-- | TXN20250919002 | 2025-09-19 10:45:30| Receiver | John Doe Customer    | +250788123456  | Customer | 25000.00 | Completed |
-- | TXN20250919001 | 2025-09-19 10:45:30| Receiver | Jane Smith Customer  | +250788234567  | Customer | 10000.00 | Completed |
-- | TXN20250919001 | 2025-09-19 10:45:30| Sender   | John Doe Customer    | +250788123456  | Customer | 10000.00 | Completed |
-- +----------------+---------------------+----------+----------------------+----------------+----------+----------+-----------+
-- 10 rows in set (0.00 sec)

-- =====================================================
-- 5. SYSTEM LOGS AND AUDIT QUERIES
-- =====================================================

-- System activity log with user context
SELECT 
    sl.LogID,
    sl.LogDateTime,
    sl.LogType,
    sl.Message,
    u.FullName as UserName,
    t.Amount as TransactionAmount,
    sl.IPAddress
FROM System_Logs sl
LEFT JOIN Users u ON sl.UserID = u.UserID
LEFT JOIN Transactions t ON sl.TransactionID = t.TransactionID
ORDER BY sl.LogDateTime DESC
LIMIT 10;

-- Expected Results:
-- +-------+---------------------+----------+--------------------------------------------------+----------------------+-------------------+---------------+
-- | LogID | LogDateTime         | LogType  | Message                                          | UserName             | TransactionAmount | IPAddress     |
-- +-------+---------------------+----------+--------------------------------------------------+----------------------+-------------------+---------------+
-- |     6 | 2025-09-19 10:45:30 | ERROR    | Transaction failed: Insufficient balance        | Customer Mary Johnson|           20000.00| 192.168.1.104 |
-- |     5 | 2025-09-19 10:45:30 | INFO     | Airtime purchase successful                      | John Doe Customer    |            3000.00| 192.168.1.100 |
-- |     4 | 2025-09-19 10:45:30 | INFO     | Utility bill payment processed                   | Customer Mary Johnson|           15000.00| 192.168.1.103 |
-- |     3 | 2025-09-19 10:45:30 | INFO     | Merchant payment completed                       | Jane Smith Customer  |            5000.00| 192.168.1.102 |
-- |     2 | 2025-09-19 10:45:30 | INFO     | Agent deposit processed                          | Agent Mike Wilson    |           25000.00| 192.168.1.101 |
-- |     1 | 2025-09-19 10:45:30 | INFO     | P2P transfer completed successfully              | John Doe Customer    |           10000.00| 192.168.1.100 |
-- +-------+---------------------+----------+--------------------------------------------------+----------------------+-------------------+---------------+
-- 6 rows in set (0.00 sec)

-- Error analysis
SELECT 
    LogType,
    COUNT(*) as LogCount,
    DATE(LogDateTime) as LogDate
FROM System_Logs 
WHERE LogDateTime >= DATE_SUB(NOW(), INTERVAL 7 DAYS)
GROUP BY LogType, DATE(LogDateTime)
ORDER BY LogDate DESC, LogCount DESC;

-- Expected Results:
-- +----------+----------+------------+
-- | LogType  | LogCount | LogDate    |
-- +----------+----------+------------+
-- | INFO     |        5 | 2025-09-19 |
-- | ERROR    |        1 | 2025-09-19 |
-- +----------+----------+------------+
-- 2 rows in set (0.00 sec)

-- =====================================================
-- 6. ADVANCED ANALYTICAL QUERIES
-- =====================================================

-- Agent performance analysis
SELECT 
    u.FullName as AgentName,
    u.PhoneNumber,
    COUNT(tp.TransactionID) as TransactionsHandled,
    SUM(CASE WHEN t.Status = 'Completed' THEN t.Amount ELSE 0 END) as VolumeProcessed,
    SUM(CASE WHEN t.Status = 'Completed' THEN t.Fee ELSE 0 END) as FeesGenerated,
    ROUND(AVG(CASE WHEN t.Status = 'Completed' THEN t.Amount END), 2) as AvgTransactionSize,
    ROUND(
        (SUM(CASE WHEN t.Status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(tp.TransactionID)), 
        2
    ) as SuccessRate
FROM Users u
JOIN Transaction_Participants tp ON u.UserID = tp.UserID
JOIN Transactions t ON tp.TransactionID = t.TransactionID
WHERE u.UserType = 'Agent' AND tp.Role = 'Agent'
GROUP BY u.UserID, u.FullName, u.PhoneNumber
ORDER BY VolumeProcessed DESC;

-- Expected Results:
-- +-------------------+----------------+---------------------+-----------------+---------------+---------------------+-------------+
-- | AgentName         | PhoneNumber    | TransactionsHandled | VolumeProcessed | FeesGenerated | AvgTransactionSize  | SuccessRate |
-- +-------------------+----------------+---------------------+-----------------+---------------+---------------------+-------------+
-- | Agent Mike Wilson | +250788345678  |                   1 |        25000.00 |        125.00 |            25000.00 |      100.00 |
-- | Agent Sarah Brown | +250788678901  |                   1 |            0.00 |          0.00 |                NULL |        0.00 |
-- +-------------------+----------------+---------------------+-----------------+---------------+---------------------+-------------+
-- 2 rows in set (0.00 sec)

-- Monthly transaction trends
SELECT 
    YEAR(TransactionDateTime) as Year,
    MONTH(TransactionDateTime) as Month,
    MONTHNAME(TransactionDateTime) as MonthName,
    COUNT(*) as TransactionCount,
    SUM(Amount) as TotalVolume,
    SUM(Fee) as TotalFees,
    ROUND(AVG(Amount), 2) as AvgTransactionSize
FROM Transactions 
WHERE TransactionDateTime >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
GROUP BY YEAR(TransactionDateTime), MONTH(TransactionDateTime)
ORDER BY Year DESC, Month DESC;

-- Expected Results (current month):
-- +------+-------+-----------+------------------+-------------+-----------+---------------------+
-- | Year | Month | MonthName | TransactionCount | TotalVolume | TotalFees | AvgTransactionSize  |
-- +------+-------+-----------+------------------+-------------+-----------+---------------------+
-- | 2025 |     9 | September |                6 |    78000.00 |    780.00 |            13000.00 |
-- +------+-------+-----------+------------------+-------------+-----------+---------------------+
-- 1 row in set (0.00 sec)

-- =====================================================
-- 7. SECURITY AND CONSTRAINT VALIDATION
-- =====================================================

-- Test constraint: Negative balance (should fail)
INSERT INTO Users (FullName, PhoneNumber, UserType, Balance) 
VALUES ('Test Negative', '+250788111222', 'Customer', -1000.00);

-- Expected Result: ERROR
-- ERROR 3819 (HY000): Check constraint 'chk_balance_positive' is violated.

-- Test constraint: Invalid phone format (should fail)
INSERT INTO Users (FullName, PhoneNumber, UserType, Balance) 
VALUES ('Test Invalid Phone', 'invalid-phone', 'Customer', 1000.00);

-- Expected Result: ERROR
-- ERROR 3819 (HY000): Check constraint 'chk_phone_format' is violated.

-- Test constraint: Negative transaction amount (should fail)
INSERT INTO Transactions (TransactionID, TransactionTypeID, SenderID, Amount) 
VALUES ('TXN_TEST_NEG', 1, 1, -500.00);

-- Expected Result: ERROR
-- ERROR 3819 (HY000): Check constraint 'chk_amount_positive' is violated.

-- Test foreign key constraint: Invalid sender ID (should fail)
INSERT INTO Transactions (TransactionID, TransactionTypeID, SenderID, Amount) 
VALUES ('TXN_TEST_FK', 1, 999, 500.00);

-- Expected Result: ERROR
-- ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails

-- =====================================================
-- 8. PERFORMANCE TESTING QUERIES
-- =====================================================

-- Index usage verification
EXPLAIN SELECT * FROM Users WHERE