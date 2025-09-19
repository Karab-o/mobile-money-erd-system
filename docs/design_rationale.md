# Design Rationale and Justification

The MoMo SMS system database is designed to provide a robust, scalable, and secure foundation for managing mobile money transactions. The design reflects careful consideration of operational requirements, regulatory compliance, and the unique challenges of mobile financial services, including high transaction volumes, multi-party participation, and integration with third-party systems.

## Hybrid Relationship Model
The database employs a hybrid relationship model by combining direct foreign keys (`SenderID` and `ReceiverID` in the `Transactions` table) with a junction table (`Transaction_Participants`). 

**Why this choice was made:**  
- Most transactions involve a simple sender-receiver relationship, so direct foreign keys optimize query performance for the majority of cases.  
- Mobile money systems, however, often require multi-party interactions, such as transactions involving agents, merchants, or third-party services. The junction table provides the necessary flexibility to represent these complex scenarios accurately without introducing redundant data or compromising referential integrity.

**Why this is appropriate for the business:**  
- Mobile money platforms must support both standard P2P transfers and more complex financial operations efficiently. This hybrid model allows the system to scale as business requirements grow, while ensuring that all participant roles are accurately captured and traceable.

## Normalization and Data Integrity
The `Transaction_Categories` table is separated from the `Transactions` table to enforce normalization. Similarly, the `BalanceAfter` field in `Transactions` captures a snapshot of user balances.

**Why this choice was made:**  
- Normalization eliminates redundant data, reduces storage costs, and ensures consistency when adding new transaction types.  
- Recording the balance after each transaction ensures data integrity and prevents errors caused by concurrent operations.

**Why this is appropriate for the business:**  
- Mobile money platforms process thousands of transactions daily. Maintaining normalized tables and accurate balances is critical to prevent discrepancies, support reconciliation, and comply with financial regulations.

## Audit Trail and Compliance
The `System_Logs` table tracks all system activity and links logs to transactions and users. The `LogType` field categorizes events (e.g., OTP, errors, informational messages).

**Why this choice was made:**  
- Comprehensive logging is essential for troubleshooting, monitoring system health, and detecting fraudulent activity.  
- Categorized logs allow administrators to filter and analyze system events efficiently.

**Why this is appropriate for the business:**  
- Financial services are highly regulated. Maintaining a detailed audit trail supports compliance with laws and regulations, such as anti-money laundering and electronic transaction reporting. It also builds trust with users by enabling transparency and accountability.

## User Role Flexibility
A single `Users` table with a `UserType` attribute supports customers, agents, and merchants.

**Why this choice was made:**  
- Consolidating all user roles into one table simplifies schema management, avoids duplication, and allows consistent enforcement of constraints and relationships.

**Why this is appropriate for the business:**  
- Mobile money platforms must handle multiple user types with distinct permissions. This design provides flexibility to implement role-specific business logic in the application while maintaining a single source of truth for all user data.

## Scalability and Performance
The composite primary key in `Transaction_Participants` (`TransactionID`, `UserID`) ensures data integrity and efficient lookups. Indexing strategies and potential table partitioning further enhance scalability.

**Why this choice was made:**  
- High-volume systems require optimized access paths and minimal query overhead to maintain responsiveness. Composite keys and indexing reduce the risk of data inconsistency and improve query performance.

**Why this is appropriate for the business:**  
- Mobile money systems handle thousands of transactions per second. This design ensures that the platform can scale with user growth and transaction volume without compromising accuracy or speed.

## Integration and Extensibility
Fields such as `ExternalReference` in `Transactions` support integration with banks, USSD systems, and third-party payment providers.

**Why this choice was made:**  
- Mobile money platforms often interact with multiple external systems. Tracking external references ensures traceability and simplifies reconciliation.

**Why this is appropriate for the business:**  
- Integration with external systems is essential for expanding services, enabling interoperability, and providing users with seamless financial experiences.

## Overall Justification
This design provides a strong balance between **operational efficiency, regulatory compliance, and future extensibility**. Each table and relationship has been structured to:  
1. Support high-volume mobile money transactions.  
2. Maintain data integrity and accurate balance tracking.  
3. Accommodate multiple user roles and complex transaction scenarios.  
4. Ensure transparency and auditability for regulatory compliance.  
5. Facilitate future growth through modular, normalized, and scalable structures.

Overall, the database architecture aligns perfectly with the operational, regulatory, and business needs of a mobile money platform, providing a reliable foundation for secure and efficient financial services.
