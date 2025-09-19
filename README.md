# mobile-money-erd-system
Entity Relationship Diagram for Mobile Money System Database Design
# Database Documentation

## Entity Relationship Diagram

![Mobile Money System ERD](erd_diagram.png)

## Database Entities

### Users
- Stores customer, agent, and merchant information
- Manages account balances and user types

### Transactions
- Central transaction log with complete audit trail
- Links to categories and participants

### Transaction_Categories
- Normalized transaction types (P2P, Agent, Merchant, etc.)
- Configurable fee structures

### System_Logs
- Complete audit trail for compliance
- Tracks all system activities and errors

### Transaction_Participants
- Resolves many-to-many relationships
- Supports complex multi-party transactions
Step 5: GitHub Integration
Option A: Using VS Code Git Integration

Initialize Git (if not done):

bash   git init

Stage files:

Open Source Control panel (Ctrl+Shift+G)
Click + next to files to stage them


Commit:

Write commit message: "Add ERD diagram and documentation"
Click ✓ to commit


Push to GitHub:

Click "..." → "Push" or use git push



Option B: Using Terminal in VS Code

Open terminal (Ctrl+ `)
Add files:

bash   git add docs/
   git commit -m "Add ERD diagram and database documentation"
   git push origin main
