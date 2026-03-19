Custom Sales Territory Management for Firebolt Motors Inc.
Scenario:

Firebolt Motors Inc. is experiencing exponential sales growth after releasing their hit Model F solar-powered sports car. They employ a Sales team that sells vehicles to auto dealers across the United States. Each sales representative is assigned to one or more zip codes and is responsible for managing relationships with all auto dealers in those territories.

Firebolt Motors Inc. uses Salesforce to manage its sales operations, including:

Accounts: Represent automobile dealers.

Opportunities: Represent sales of vehicles to those dealers.

Contacts: Represent dealer employees.

Currently, the Sales Operations team manually assigns Account Owners based on a spreadsheet that maps zip codes to sales representatives. As the team has tripled in size, maintaining this process manually has become inefficient. A scalable, automated solution is needed within Salesforce.

Requirements:

Territory Custom Object (Territory__c)

Fields: Zip Code (Text, used as Name field), Owner (Lookup to User).

Field history tracking should be enabled on all fields.

Ownership Automation on Account Zip Code Change

When an Account’s BillingPostalCode is changed or first set:

Reassign the Account Owner to the Territory Owner.

Update the Owner of all related Contacts and Open Opportunities.

If no matching Territory is found, do nothing.

Multiple Sales Reps per Zip Code

Support up to 3 reps per zip code.

If multiple reps exist, randomly select one to assign as the owner.

Limit Sales Rep Assignments

Prevent more than 3 sales reps from being assigned to the same zip code.

Display a validation error if exceeded.

Assignment History Object (Assignment_History__c)

Track changes to Account ownership with:

Previous Owner (Lookup to User)

New Owner (Lookup to User)

Previous Territory (Lookup to Territory__c)

New Territory (Lookup to Territory__c)

Account (Master-Detail to Account)

Changed By (Lookup to User)

History Logging

Automatically create Assignment_History__c records when an Account’s zip code is changed or initially set.

Territory Owner Change Automation

When the Owner of a Territory__c record changes, reassign all Accounts under that Territory accordingly.

Test Coverage

Implement Apex test classes that ensure at least 75% code coverage, covering both positive and negative test cases.

Skills Implemented
Coding Skills

Apex Triggers and Classes:

Implemented trigger logic for zip code change detection, random assignment, and owner reassignment to ensure correct ownership flow.

SOQL and SOSL Queries:

Used SOQL for retrieving relevant Users, Accounts, Contacts, Opportunities, and Territories, ensuring efficient querying of large data sets.

Custom Object Design:

Created Territory__c and Assignment_History__c to support dynamic, scalable automation.

Bulkification:

All logic supports bulk operations to adhere to Salesforce governor limits. The solution is optimized for scalability and performance, ensuring smooth execution even with large datasets (e.g., thousands of Accounts and Territories). No SOQL or DML operations occur inside loops.

Randomization Logic:

Implemented Apex-based logic for randomly selecting a sales rep when multiple reps exist for a zip code, ensuring fairness in ownership assignment.

Exception Handling:

Built-in logic gracefully handles unexpected conditions such as missing or invalid data. Any errors are logged, and appropriate notifications are triggered to ensure transparency and easy debugging.

Test-Driven Development:

Developed test classes to validate all features and ensure 75%+ code coverage. Tests include scenarios for bulk processing, random ownership assignment, territory reassignment, and handling of invalid or missing data (e.g., zip codes, territories).

Declarative Skills

Validation Rules:

Enforced a maximum of three sales reps per zip code with validation to ensure data integrity and prevent over-assignment.

Field History Tracking:

Enabled field history tracking for all relevant Territory fields to ensure auditability of changes and adherence to compliance standards.

Custom Fields & Relationships:

Configured lookups, master-detail relationships, and UI visibility settings in Salesforce Setup to enable seamless data relationships and user access controls.

Detailed Technical Considerations (Kevin O'Hara Trigger Framework)
Separation of Concerns Using Kevin O'Hara's Trigger Framework

To ensure that the solution is modular, maintainable, and scalable, I followed Kevin O'Hara's Trigger Framework, which enforces the Separation of Concerns pattern. This framework helps to keep trigger logic simple and delegates the heavy lifting to dedicated service classes, ensuring better maintainability and testing.

Trigger Handler (AccountTriggerHandler):

The AccountTrigger is kept lightweight and free from business logic. Instead of cluttering the trigger with complex logic, the trigger delegates the responsibilities to the AccountTriggerHandler class. This handler is only responsible for defining which methods should run at different trigger events (before insert, before update, after update), allowing for cleaner and more understandable code.

Service Class (AccountService):

The AccountService class contains all the business logic and is designed with the single responsibility principle in mind. Each method in AccountService focuses on a specific task, ensuring that the code is highly modular and reusable.

For example:

collectUpdatedPostalCodes(List<Account> newAccounts, Map<Id, Account> oldAccountMap) – Handles logic to track zip code changes.

assignTerritoryOwner(List<Account> newAccounts, List<String> updatedPostalCodes) – Manages the reassignment of account owners based on zip codes.

createAssignmentHistory(List<Account> newAccounts, Map<Id, Account> oldAccountMap) – Handles history logging for changes in account ownership.

Key Benefits of This Approach:

Maintainability: By following the Single Responsibility Principle, each class and method does one thing and does it well, making the code easier to maintain and extend over time.

Testability: This architecture allows for unit testing of individual service methods without needing to invoke the entire trigger flow, improving test coverage and the ability to isolate problems.

Reusability: Methods like setOpportunityOwners and setContactOwners are reusable in different contexts or triggers, allowing the code to scale and adapt as needed.

Clarity: The business logic is clearly separated from the trigger event-handling logic, making the flow of operations easier to understand and debug.

Edge Cases & Performance Considerations

The solution is designed to handle bulk operations efficiently, with key edge cases considered:

Null and Invalid Data: Missing territories or invalid zip codes are handled gracefully, ensuring that no unnecessary updates or errors occur.

Randomization Logic: When more than one sales rep is assigned to a zip code, a random selection ensures that ownership is fairly distributed, while the logic prevents more than three reps from being assigned to the same zip code.

Territory Owner Change: When a Territory's owner changes, the solution updates all related Account Owners accordingly. The process ensures data consistency and avoids manual intervention.

Error Handling and Logging

The system has built-in error handling to catch unexpected issues and ensure smooth operation:

Error Logging: In case of data integrity issues or DML errors, detailed logs are generated, which helps in troubleshooting and ensures no silent failures.

Graceful Fallbacks: Where possible, operations are designed to fail gracefully (e.g., when a Territory is deleted or a zip code has no corresponding Territory), and users are provided with meaningful error messages.

Test Coverage

Comprehensive Apex tests ensure that all requirements are met, with a focus on both positive and negative scenarios:

Bulk Operations: Tests simulate large volumes of data to ensure the solution scales appropriately.

Edge Cases: Tests include scenarios where zip codes or territories are missing or invalid, ensuring the system behaves as expected in these cases.

Random Ownership: Tests verify that the random assignment logic works when multiple reps are assigned to the same territory.

 
