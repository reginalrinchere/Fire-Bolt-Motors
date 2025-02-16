@isTest
private class AccountPostalCodeChangeTest {

    // Test method for validating account owner change when postal code changes
    @isTest
    static void testManageTerritoryOwners() {
        // 1. Setup test data: Accounts with different postal codes
        List<Account> testAccounts = new List<Account>();
        
        // Create sample accounts with BillingPostalCode
        testAccounts.add(new Account(
            Name = 'Test Account 1', 
            BillingPostalCode = '12345'
        ));
        
        testAccounts.add(new Account(
            Name = 'Test Account 2', 
            BillingPostalCode = '67890'
        ));

        insert testAccounts;

        // 2. Simulate update with a change in postal code
        List<Account> updatedAccounts = new List<Account>();
        
        // Modify BillingPostalCode
        for (Account acc : testAccounts) {
            updatedAccounts.add(new Account(
                Id = acc.Id,
                BillingPostalCode = acc.BillingPostalCode == '12345' ? '54321' : '98765'
            ));
        }

        Test.startTest();
        // Call the method to test, simulating a trigger execution
        AccountPostalCodeHandler.manageTerritoryOwners(updatedAccounts, new Map<Id, Account>());
        Test.stopTest();
        
        // 3. Assertions: Ensure the accounts were processed correctly
        List<Account> accountsFromDb = [SELECT BillingPostalCode FROM Account WHERE Id IN :updatedAccounts];
        
        // Validate that the postal codes were updated as expected
        System.assertEquals('54321', accountsFromDb[0].BillingPostalCode);
        System.assertEquals('98765', accountsFromDb[1].BillingPostalCode);
        
        // Add more specific assertions based on the logic you expect (e.g., account owner changes)
    }
    
    // Test method for validating edge case where no postal code change occurs
    @isTest
    static void testNoPostalCodeChange() {
        // Create an account without changing postal code
        Account testAccount = new Account(
            Name = 'Test Account 3',
            BillingPostalCode = '11111'
        );
        insert testAccount;

        // Call method with no change in postal code
        List<Account> updatedAccounts = new List<Account>();
        updatedAccounts.add(new Account(Id = testAccount.Id, BillingPostalCode = '11111'));

        Test.startTest();
        AccountPostalCodeHandler.manageTerritoryOwners(updatedAccounts, new Map<Id, Account>());
        Test.stopTest();
        
        // Query the account to verify no changes were made
        Account accountFromDb = [SELECT BillingPostalCode FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('11111', accountFromDb.BillingPostalCode);
    }
    
    // Test method for bulk testing (testing large number of records)
    @isTest
    static void testBulkAccountUpdates() {
        // Setup bulk data - 200 accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                BillingPostalCode = '10000' + i
            ));
        }
        insert testAccounts;

        // Simulate a bulk update
        List<Account> updatedAccounts = new List<Account>();
        for (Account acc : testAccounts) {
            updatedAccounts.add(new Account(
                Id = acc.Id,
                BillingPostalCode = acc.BillingPostalCode == '10000' ? '20000' : '30000'
            ));
        }

        Test.startTest();
        // Test bulk update
        AccountPostalCodeHandler.manageTerritoryOwners(updatedAccounts, new Map<Id, Account>());
        Test.stopTest();

        // Assertions: Check if the postal codes were updated correctly
        List<Account> accountsFromDb = [SELECT BillingPostalCode FROM Account WHERE Id IN :updatedAccounts];
        for (Integer i = 0; i < accountsFromDb.size(); i++) {
            System.assert(accountsFromDb[i].BillingPostalCode == '20000' || accountsFromDb[i].BillingPostalCode == '30000');
        }
    }

    // Test method to ensure correct error handling
    @isTest
    static void testErrorHandling() {
        // Simulate invalid data
        Account invalidAccount = new Account(Name = null); // Missing required field
        try {
            insert invalidAccount;
            System.assert(false, 'Expected an exception due to missing required fields');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('INSERT_FAILED'));
        }
    }
}
