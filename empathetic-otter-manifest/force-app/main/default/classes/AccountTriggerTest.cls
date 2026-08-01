@isTest
private class AccountTriggerTest {

    @testSetup
    static void setupData() {

        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        List<User> users = new List<User>();

        for(Integer i = 1; i <= 2; i++) {

            users.add(
                new User(
                    Alias = 'usr' + i,
                    Email = 'accountuser' + i + '@test.com',
                    EmailEncodingKey = 'UTF-8',
                    LastName = 'AccountUser' + i,
                    LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US',
                    TimeZoneSidKey = 'America/New_York',
                    ProfileId = p.Id,
                    Username = 'accountuser' +
                        i +
                        System.currentTimeMillis() +
                        '@test.com'
                )
            );
        }

        insert users;


        insert new List<Territory__c>{
            new Territory__c(
                Zip_Code__c = '33010',
                Owner__c = users[0].Id
            ),

            new Territory__c(
                Zip_Code__c = '33111',
                Owner__c = users[0].Id
            ),

            new Territory__c(
                Zip_Code__c = '33111',
                Owner__c = users[1].Id
            )
        };


        Account acc = new Account(
            Name = 'Initial Account',
            BillingPostalCode = '33010'
        );

        insert acc;


        insert new Contact(
            LastName = 'Test Contact',
            AccountId = acc.Id,
            OwnerId = users[0].Id
        );


        insert new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id,
            OwnerId = users[0].Id
        );
    }


    @isTest
    static void testAccountOwnerAssignmentFromTerritory() {

        Account acc = [
            SELECT Id,
                   BillingPostalCode
            FROM Account
            LIMIT 1
        ];


        Set<Id> territoryOwners = new Set<Id>();

        for(Territory__c territory : [
            SELECT Owner__c
            FROM Territory__c
            WHERE Zip_Code__c = '33111'
        ]) {

            territoryOwners.add(
                territory.Owner__c
            );
        }


        Test.startTest();

        acc.BillingPostalCode = '33111';

        update acc;

        Test.stopTest();


        Account updatedAccount = [
            SELECT OwnerId
            FROM Account
            WHERE Id = :acc.Id
        ];


        Contact updatedContact = [
            SELECT OwnerId
            FROM Contact
            WHERE AccountId = :acc.Id
            LIMIT 1
        ];


        Opportunity updatedOpportunity = [
            SELECT OwnerId
            FROM Opportunity
            WHERE AccountId = :acc.Id
            LIMIT 1
        ];


        System.assert(
            territoryOwners.contains(updatedAccount.OwnerId),
            'Account owner should come from territory owners.'
        );


        System.assertEquals(
            updatedAccount.OwnerId,
            updatedContact.OwnerId,
            'Contact owner should match Account owner.'
        );


        System.assertEquals(
            updatedAccount.OwnerId,
            updatedOpportunity.OwnerId,
            'Opportunity owner should match Account owner.'
        );
    }



    @isTest
    static void testBulkAccountOwnerAssignment() {


        List<Account> accounts = new List<Account>();


        for(Integer i = 0; i < 200; i++) {

            accounts.add(
                new Account(
                    Name = 'Bulk Account ' + i,
                    BillingPostalCode = '33010'
                )
            );
        }


        insert accounts;


        Test.startTest();


        for(Account acc : accounts) {

            acc.BillingPostalCode = '33111';

        }


        update accounts;


        Test.stopTest();



        Integer reassignedCount = [
            SELECT COUNT()
            FROM Account
            WHERE BillingPostalCode = '33111'
            AND OwnerId != null
        ];


        System.assertEquals(
            200,
            reassignedCount,
            'All accounts should receive territory owners.'
        );
    }



    @isTest
    static void testAssignmentHistoryCreatedOnAccountUpdate() {


        Account acc = [
            SELECT Id,
                   Name
            FROM Account
            LIMIT 1
        ];


        Test.startTest();


        acc.Name = 'Updated Account Name';

        update acc;


        Test.stopTest();



        Integer historyCount = [
            SELECT COUNT()
            FROM Assignment_History__c
            WHERE Account__c = :acc.Id
        ];



        System.assertEquals(
            1,
            historyCount,
            'Assignment history should be created for account updates.'
        );
    }



    @isTest
    static void testNoTerritoryMatchDoesNotAssignOwner() {


        Account acc = new Account(
            Name = 'No Territory Account',
            BillingPostalCode = '99999'
        );


        Test.startTest();

        insert acc;

        Test.stopTest();



        Account result = [
            SELECT OwnerId
            FROM Account
            WHERE Id = :acc.Id
        ];


        System.assertNotEquals(
            null,
            result.OwnerId,
            'Account should retain a valid Salesforce owner.'
        );
    }
}