## Scenario: Custom Sales Territory Management

Firebolt Motors Inc. is experiencing exponential sales growth after releasing their hit Model F solar powered sports car.

They employ a Sales team that sells vehicles to auto dealers across the United States. Each sales representative has a territory of one or more zip codes. Sales reps own the relationship with all auto dealers in their zip code territories.

Firebolt Motors Inc. currently uses Salesforce to track their sales activities, including:
- **Accounts:** Each account represents an automobile dealer.
- **Opportunities:** A sale of vehicles to an automobile dealer.
- **Contacts:** Automobile dealer employees.

The Sales Operations team uses a combination of Salesforce and spreadsheets to manage each sales rep’s territory. They are manually setting the Account Owner field to the sales rep’s User record when the Account’s Zip Code belongs to the sales rep. Currently, a list of zip codes and their sales rep is stored in spreadsheet that looks like this:

| Zip Code | Sales Representative |
| -------- | -------------------- |
| 91000    | Blake                |
| 91001    | Blake                |
| 91002    | Blake                |
| 91002    | Jacqueline           |
| 91010    | Jacqueline           |
| 91020    | Jacqueline           |
| 92010    | Denise               |
| 92020    | Aaron                |

Since Firebolt Motors Inc.’s sales team has tripled in size in the past year, the Sales Operations team is having trouble keeping up with all the sales territory changes. This process must be automated!

---

## Requirements

### 1. Territory Custom Object (`Territory__c`)
- Fields:
  - **Zip Code** (Text, Name field)
  - **Owner** (Lookup to User)
- Enable field history tracking on all fields.

### 2. Ownership Automation on Account Zip Code Change
- When an Account’s `BillingPostalCode` changes or is first populated:
  - Change the Account Owner to the Territory Owner assigned to that zip code.
  - Change Owners of related Contacts and Open Opportunities to the same user.
- If no matching Territory exists, do nothing.

### 3. Multiple Sales Reps per Territory
- Allow up to 3 sales reps per zip code.
- If multiple reps exist, randomly assign one as the owner.

### 4. Limit on Sales Reps per Zip Code
- Prevent associating more than 3 sales reps with a single zip code.
- Display an error if this limit is exceeded.

### 5. Assignment History Object (`Assignment_History__c`)
- Fields:
  - Previous Owner (Lookup User)
  - New Owner (Lookup User)
  - Previous Territory (Lookup Territory__c)
  - New Territory (Lookup Territory__c)
  - Account (Master-Detail Account)
  - Changed By (Lookup User)

### 6. History Logging
- Create a record in `Assignment_History__c` whenever an Account’s `BillingPostalCode` is changed or first set.

### 7. Territory Owner Change Impact
- When a Territory Owner changes, update ownership for all related Accounts accordingly.

### 8. Test Coverage
- Achieve at least 90% Apex test coverage with positive and negative test cases.

---

## Skills Implemented

- Apex Triggers and Classes  
- SOQL and SOSL Queries  
- Salesforce Custom Objects and Fields  
- Lookup and Master-Detail Relationships  
- Apex Test Classes and Code Coverage  
- Salesforce Declarative Tools (Validation Rules, Process Builder, Flows)  
- Bulkification and Governor Limits Best Practices  
- Exception Handling and Error Messaging  
- Use of Randomization Logic in Apex  
- Field History Tracking  
- Deployment to Salesforce Developer Org  

---
