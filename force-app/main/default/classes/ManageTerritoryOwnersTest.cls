@isTest
private class ManageTerritoryOwnersTest {

    @isTest
    static void testManageTerritoryOwners() {
        List<Account> testAccounts = createTestAccounts(new String[] { '12345', '67890' });

        insert testAccounts;
        List<Account> updatedAccounts = prepareUpdatedAccounts(testAccounts);

        Test.startTest();
        AccountPostalCodeHandler.manageTerritoryOwners(updatedAccounts, new Map<Id, Account>());
        Test.stopTest();

        validatePostalCodeUpdate(updatedAccounts);
    }

    @isTest
    static void testNoPostalCodeChange() {
        Account testAccount = createTestAccount('11111');
        insert testAccount;

        List<Account> updatedAccounts = new List<Account>{ new Account(Id = testAccount.Id, BillingPostalCode = '11111') };

        Test.startTest();
        AccountPostalCodeHandler.manageTerritoryOwners(updatedAccounts, new Map<Id, Account>());
        Test.stopTest();

        validateNoChange(testAccount);
    }

    @isTest
    static void testBulkAccountUpdates() {
        List<Account> testAccounts = createBulkTestAccounts(200);
        insert testAccounts;

        List<Account> updatedAccounts = prepareUpdatedAccounts(testAccounts);

        Test.startTest();
        AccountPostalCodeHandler.manageTerritoryOwners(updatedAccounts, new Map<Id, Account>());
        Test.stopTest();

        validateBulkPostalCodeUpdate(updatedAccounts);
    }

    @isTest
    static void testErrorHandling() {
        Account invalidAccount = new Account(Name = null); // Missing required field
        try {
            insert invalidAccount;
            System.assert(false, 'Expected an exception due to missing required fields');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('INSERT_FAILED'));
        }
    }

    // Helper methods

    private static List<Account> createTestAccounts(String[] postalCodes) {
        List<Account> accounts = new List<Account>();
        for (String postalCode : postalCodes) {
            accounts.add(new Account(Name = 'Test Account', BillingPostalCode = postalCode));
        }
        return accounts;
    }

    private static Account createTestAccount(String postalCode) {
        return new Account(Name = 'Test Account', BillingPostalCode = postalCode);
    }

    private static List<Account> createBulkTestAccounts(Integer count) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i, BillingPostalCode = '10000' + i));
        }
        return accounts;
    }

    private static List<Account> prepareUpdatedAccounts(List<Account> originalAccounts) {
        List<Account> updatedAccounts = new List<Account>();
        for (Account acc : originalAccounts) {
            updatedAccounts.add(new Account(
                Id = acc.Id,
                BillingPostalCode = acc.BillingPostalCode == '12345' ? '54321' : '98765'
            ));
        }
        return updatedAccounts;
    }

    private static void validatePostalCodeUpdate(List<Account> updatedAccounts) {
        List<Account> accountsFromDb = [SELECT BillingPostalCode FROM Account WHERE Id IN :updatedAccounts];
        System.assertEquals('54321', accountsFromDb[0].BillingPostalCode);
        System.assertEquals('98765', accountsFromDb[1].BillingPostalCode);
    }

    private static void validateNoChange(Account testAccount) {
        Account accountFromDb = [SELECT BillingPostalCode FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('11111', accountFromDb.BillingPostalCode);
    }

    private static void validateBulkPostalCodeUpdate(List<Account> updatedAccounts) {
        List<Account> accountsFromDb = [SELECT BillingPostalCode FROM Account WHERE Id IN :updatedAccounts];
        for (Integer i = 0; i < accountsFromDb.size(); i++) {
            System.assert(accountsFromDb[i].BillingPostalCode == '20000' || accountsFromDb[i].BillingPostalCode == '30000');
        }
    }
}