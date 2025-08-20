## Scenario: Custom Sales Territory Management

Firebolt Motors Inc. is experiencing exponential sales growth after releasing their hit Model F solar-powered sports car.

They employ a Sales team that sells vehicles to auto dealers across the United States. Each sales representative is assigned to one or more zip codes and is responsible for managing relationships with all auto dealers in those territories.

Firebolt Motors Inc. uses Salesforce to manage its sales operations, including:
- **Accounts:** Represent automobile dealers.
- **Opportunities:** Represent sales of vehicles to those dealers.
- **Contacts:** Represent dealer employees.

Currently, the Sales Operations team manually assigns Account Owners based on a spreadsheet that maps zip codes to sales representatives. An example of that spreadsheet is shown below:

| Zip Code | Sales Representative |
|----------|----------------------|
| 91000    | Blake                |
| 91001    | Blake                |
| 91002    | Blake                |
| 91002    | Jacqueline           |
| 91010    | Jacqueline           |
| 91020    | Jacqueline           |
| 92010    | Denise               |
| 92020    | Aaron                |

As the team has tripled in size, maintaining this process manually has become inefficient. A scalable, automated solution is needed within Salesforce.

---

## Requirements

### 1. Territory Custom Object (`Territory__c`)
- Fields:
  - **Zip Code** (Text, used as Name field)
  - **Owner** (Lookup to User)
- Field history tracking should be enabled on all fields.

### 2. Ownership Automation on Account Zip Code Change
- When an Account’s `BillingPostalCode` is changed or first set:
  - Reassign the Account Owner to the Territory Owner.
  - Also update the Owner of all related Contacts and Open Opportunities.
- If no matching Territory is found, do nothing.

### 3. Multiple Sales Reps per Zip Code
- Support up to 3 reps per zip code.
- If multiple reps exist, randomly select one to assign as owner.

### 4. Limit Sales Rep Assignments
- Prevent more than 3 sales reps from being assigned to the same zip code.
- Display a validation error if exceeded.

### 5. Assignment History Object (`Assignment_History__c`)
Track changes to Account ownership with:
- `Previous Owner` (Lookup to User)
- `New Owner` (Lookup to User)
- `Previous Territory` (Lookup to Territory__c)
- `New Territory` (Lookup to Territory__c)
- `Account` (Master-Detail to Account)
- `Changed By` (Lookup to User)

### 6. History Logging
- Automatically create `Assignment_History__c` records when an Account’s zip code is changed or initially set.

### 7. Territory Owner Change Automation
- When the Owner of a `Territory__c` record changes, reassign all Accounts under that Territory accordingly.

### 8. Test Coverage
- Implement Apex test classes that ensure at least 75% code coverage, covering both positive and negative test cases.

---

## Skills Implemented

### 👨‍💻 Coding Skills
- **Apex Triggers and Classes:** Implemented trigger logic for zip code change detection, random assignment, and owner reassignment.
- **SOQL and SOSL Queries:** Used for retrieving relevant Users, Accounts, Contacts, Opportunities, and Territories.
- **Custom Object Design:** Created `Territory__c` and `Assignment_History__c` to support dynamic, scalable automation.
- **Bulkification:** All logic supports bulk operations to adhere to governor limits.
- **Randomization Logic:** Used Apex to randomly assign an owner when multiple reps exist per zip code.
- **Exception Handling:** Built-in logic to gracefully handle unexpected conditions.
- **Test-Driven Development:** Developed test classes to validate functionality and maintain 75%+ code coverage.

### ⚙️ Declarative Skills
- **Validation Rules:** Enforced a maximum of three sales reps per zip code.
- **Field History Tracking:** Enabled on Territory fields for audit purposes.
- **Custom Fields & Relationships:** Configured lookups, master-detail relationships, and UI visibility settings in Salesforce Setup.

---

## Contact

**Reginal Rinchere**  
📧 reginalrinchere@gmail.com
