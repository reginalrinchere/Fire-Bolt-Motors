# Custom Sales Territory Management – Firebolt Motors Inc.

**Overview:**  
Firebolt Motors Inc., a fast-growing auto company, needed an automated solution to assign Account owners (sales reps) based on zip codes. Previously, the Sales Operations team managed assignments manually via spreadsheets—a process that became unsustainable as the team scaled. This Salesforce solution automates territory management, owner assignments, and tracks history to ensure data integrity and efficient operations.

---

## Key Features

- **Automated Owner Assignment**  
  - Assigns Accounts to Territory owners when `BillingPostalCode` is set or updated.  
  - Automatically updates related Contacts and open Opportunities.  
  - Supports up to 3 sales reps per zip code, selecting randomly when multiple owners exist.

- **Validation & Data Integrity**  
  - Prevents more than 3 sales reps per zip code.  
  - Generates meaningful error messages when limits are exceeded.  

- **Assignment History Tracking**  
  - Tracks all Account ownership changes in a custom `Assignment_History__c` object.  
  - Records previous and new owners, previous and new territories, and the user who made the change.

- **Territory Owner Change Automation**  
  - Reassigns all Accounts under a Territory automatically when its owner changes.  

---

## Technical Highlights

- **Apex Trigger Framework**  
  - Implemented using the Kevin O’Hara Trigger Framework for modular, maintainable triggers.  
  - Trigger handlers are lightweight; business logic lives in service classes.  

- **Service-Oriented Architecture**  
  - `AccountService` handles all business logic: zip code change detection, owner assignment, contact/opportunity updates, and history logging.  
  - Methods are reusable, bulk-safe, and optimized for performance.  

- **Bulk & Edge-Case Safe**  
  - Supports bulk operations for thousands of records.  
  - Handles null or missing territories gracefully.  
  - Ensures fair random selection when multiple owners exist.  

- **Test Coverage & Quality**  
  - Comprehensive Apex test classes covering 75%+ of the code.  
  - Tests include positive/negative scenarios, bulk operations, and random assignment validation.  

---

## Skills Demonstrated

- **Apex Development:** Triggers, classes, service-oriented design  
- **Salesforce Architecture:** Custom objects, lookups, master-detail relationships, validation rules  
- **Best Practices:** Bulkification, separation of concerns, test-driven development, error handling  
- **Data Management:** Contact and Opportunity owner propagation, history tracking  

---

## Business Impact

- Eliminated manual account assignment errors  
- Enabled scalable, automated territory management for a growing sales team  
- Provided audit-ready ownership tracking and compliance with business rules  
