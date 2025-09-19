# Database Schema Documentation

## Table Specifications

### 1. Users Table

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| UserID | INT | PRIMARY KEY, AUTO_INCREMENT | Unique user identifier |
| FullName | VARCHAR(100) | NOT NULL | User's full name |
| PhoneNumber | VARCHAR(20) | NOT NULL, UNIQUE | Mobile phone number |
| AccountNumber | VARCHAR(50) | UNIQUE | Account number for transactions |
| UserType | ENUM('Customer', 'Agent', 'Merchant') | NOT NULL | User role type |
| Balance | DECIMAL(15,2) | DEFAULT 0.00 | Current account balance |
| CreatedDate | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Account creation date |
| Status | ENUM('Active', 'Suspended', 'Closed') | DEFAULT 'Active' | Account status |

**Indexes:**
- PRIMARY KEY (UserID)
- UNIQUE INDEX (PhoneNumber)
- UNIQUE INDEX (AccountNumber)
- INDEX (UserType)

---

### 2. Transaction_Categories Table

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| TransactionTypeID | INT | PRIMARY KEY, AUTO_INCREMENT | Unique category identifier |
| CategoryName | VARCHAR(50) | NOT NULL, UNIQUE | Transaction category name |
| Description | TEXT | NULL | Detailed category description |
| IsActive | BOOLEAN | DEFAULT TRUE | Category status |
| CreatedDate | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Category creation date |

**Sample Data:**
- Payment, Transfer, Deposit, Withdrawal, Airtime, Utility, Commission

**Indexes:**
- PRIMARY KEY (TransactionTypeID)
- UNIQUE INDEX (CategoryName)

---

### 3. Transactions Table

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| TransactionID | VARCHAR(50) | PRIMARY KEY | Unique transaction identifier |
| TransactionTypeID | INT | FOREIGN KEY → Transaction_Categories | Transaction category |
| SenderID | INT | FOREIGN KEY → Users | Transaction sender |
| ReceiverID | INT | FOREIGN KEY → Users, NULL | Transaction receiver |
| Amount | DECIMAL(15,2) | NOT NULL, CHECK > 0 | Transaction amount |
| Fee | DECIMAL(10,2) | DEFAULT 0.00 | Transaction fee |
| BalanceAfter | DECIMAL(15,2) | NOT NULL | Sender's balance after transaction |
| TransactionDateTime | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Transaction timestamp |
| ExternalReference | VARCHAR(100) | NULL | External system reference |
| Status | ENUM('Pending', 'Completed', 'Failed', 'Cancelled') | DEFAULT 'Pending' | Transaction status |
| Description | VARCHAR(255) | NULL | Transaction description |

**Indexes:**
- PRIMARY KEY (TransactionID)
- FOREIGN KEY (TransactionTypeID) REFERENCES Transaction_Categories(TransactionTypeID)
- FOREIGN KEY (SenderID) REFERENCES Users(UserID)
- FOREIGN KEY (ReceiverID) REFERENCES Users(UserID)
- INDEX (TransactionDateTime)
- INDEX (Status)
- INDEX (SenderID, TransactionDateTime)
- INDEX (ReceiverID, TransactionDateTime)

---

### 4. Transaction_Participants Table

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| TransactionID | VARCHAR(50) | FOREIGN KEY → Transactions | Transaction reference |
| UserID | INT | FOREIGN KEY → Users | Participant user ID |
| Role | ENUM('Sender', 'Receiver', 'Agent', 'Merchant') | NOT NULL | Participant role |
| AmountInvolved | DECIMAL(15,2) | NULL | Amount specific to this participant |
| CreatedDate | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Participation record date |

**Constraints:**
- COMPOSITE PRIMARY KEY (TransactionID, UserID)
- FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID)
- FOREIGN KEY (UserID) REFERENCES Users(UserID)

**Indexes:**
- PRIMARY KEY (TransactionID, UserID)
- INDEX (UserID, Role)
- INDEX (TransactionID, Role)

---

### 5. System_Logs Table

| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| LogID | BIGINT | PRIMARY KEY, AUTO_INCREMENT | Unique log identifier |
| TransactionID | VARCHAR(50) | FOREIGN KEY → Transactions, NULL | Related transaction |
| LogDateTime | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Log entry timestamp |
| Message | TEXT | NOT NULL | Log message content |
| LogType | ENUM('OTP', 'Info', 'Error', 'Warning', 'Debug') | NOT NULL | Log entry type |
| UserID | INT | FOREIGN KEY → Users, NULL | Related user |
| IPAddress | VARCHAR(45) | NULL | Client IP address |
| UserAgent | VARCHAR(255) | NULL | Client user agent |

**Indexes:**
- PRIMARY KEY (LogID)
- FOREIGN KEY (TransactionID) REFERENCES Transactions(TransactionID)
- FOREIGN KEY (UserID) REFERENCES Users(UserID)
- INDEX (LogDateTime)
- INDEX (LogType)
- INDEX (TransactionID, LogDateTime)

## Business Rules & Constraints

### Transaction Rules
1. **Balance Validation**: Sender must have sufficient balance + fees
2. **User Type Restrictions**: 
   - Customers can send/receive payments
   - Agents can process cash-in/cash-out
   - Merchants can receive payments only
3. **Transaction Limits**: Implement daily/monthly transaction limits per user type
4. **Fee Calculation**: Fees calculated based on transaction type and amount

### Data Integrity Rules
1. **Referential Integrity**: All foreign keys must reference valid records
2. **Balance Consistency**: BalanceAfter must equal previous balance ± transaction amount ± fees
3. **Audit Trail**: Every transaction must generate corresponding system log entries
4. **Phone Number Uniqueness**: Each phone number can only be associated with one active account

### Security Considerations
1. **Sensitive Data**: Encrypt personal information at rest
2. **Transaction IDs**: Use UUIDs or secure random generation
3. **Audit Logging**: Log all system access and modifications
4. **Data Retention**: Implement data archival policies for old transactions

## Sample Queries

### Get User Transaction History
```sql
SELECT t.TransactionID, tc.CategoryName, t.Amount, t.Fee, 
       t.TransactionDateTime, t.Status
FROM Transactions t
JOIN Transaction_Categories tc ON t.TransactionTypeID = tc.TransactionTypeID
WHERE t.SenderID = ? OR t.ReceiverID = ?
ORDER BY t.TransactionDateTime DESC;
```

### Calculate Daily Transaction Volume
```sql
SELECT DATE(TransactionDateTime) as TransactionDate,
       COUNT(*) as TransactionCount,
       SUM(Amount) as TotalAmount
FROM Transactions
WHERE Status = 'Completed'
  AND TransactionDateTime >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DATE(TransactionDateTime)
ORDER BY TransactionDate DESC;
```

### Get Multi-Party Transaction Details
```sql
SELECT t.TransactionID, u.FullName, tp.Role, tp.AmountInvolved
FROM Transactions t
JOIN Transaction_Participants tp ON t.TransactionID = tp.TransactionID
JOIN Users u ON tp.UserID = u.UserID
WHERE t.TransactionID = ?
ORDER BY tp.Role;
```

## Performance Optimization

### Recommended Indexes
- Composite indexes on frequently queried column combinations
- Partial indexes on active records only
- Full-text indexes on description fields if needed

### Partitioning Strategy
- Partition Transactions table by date (monthly)
- Partition System_Logs table by date (weekly)
- Archive old data to separate tables/databases

### Caching Strategy
- Cache user balance information
- Cache transaction categories and limits
- Implement Redis for session management and OTP storage