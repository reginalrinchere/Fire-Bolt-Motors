@isTest
private class TerritoryTriggerTest {

    @testSetup
    static void setupData() {

        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];


        List<User> users = new List<User>();


        for(Integer i = 1; i <= 4; i++) {

            users.add(
                new User(
                    Alias = 'terr' + i,
                    Email = 'territoryuser' + i + '@test.com',
                    EmailEncodingKey = 'UTF-8',
                    LastName = 'TerritoryUser' + i,
                    LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US',
                    TimeZoneSidKey = 'America/New_York',
                    ProfileId = p.Id,
                    Username =
                        'territoryuser' +
                        i +
                        System.currentTimeMillis() +
                        '@test.com'
                )
            );
        }


        insert users;



        insert new Territory__c(
            Zip_Code__c = '33010',
            Owner__c = users[0].Id
        );



        Account acc = new Account(
            Name = 'Test Account',
            BillingPostalCode = '33010',
            OwnerId = users[0].Id
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



    private static List<User> getTestUsers() {

        return [
            SELECT Id
            FROM User
            WHERE LastName LIKE 'TerritoryUser%'
            ORDER BY LastName
        ];
    }



    @isTest
    static void testAllowsThreeOwnersForSameZipCode() {


        List<User> users = getTestUsers();



        Test.startTest();


        insert new List<Territory__c>{

            new Territory__c(
                Zip_Code__c = '55555',
                Owner__c = users[0].Id
            ),

            new Territory__c(
                Zip_Code__c = '55555',
                Owner__c = users[1].Id
            ),

            new Territory__c(
                Zip_Code__c = '55555',
                Owner__c = users[2].Id
            )
        };


        Test.stopTest();



        Integer countTerritories = [
            SELECT COUNT()
            FROM Territory__c
            WHERE Zip_Code__c = '55555'
        ];



        System.assertEquals(
            3,
            countTerritories,
            'Three owners should be allowed for the same ZIP code.'
        );
    }



    @isTest
    static void testPreventsFourthOwnerForSameZipCode() {


        List<User> users = getTestUsers();



        insert new List<Territory__c>{

            new Territory__c(
                Zip_Code__c = '77777',
                Owner__c = users[0].Id
            ),

            new Territory__c(
                Zip_Code__c = '77777',
                Owner__c = users[1].Id
            ),

            new Territory__c(
                Zip_Code__c = '77777',
                Owner__c = users[2].Id
            )
        };



        Test.startTest();


        Database.SaveResult result =
            Database.insert(
                new Territory__c(
                    Zip_Code__c = '77777',
                    Owner__c = users[3].Id
                ),
                false
            );


        Test.stopTest();



        System.assertEquals(
            false,
            result.isSuccess(),
            'Fourth territory owner should fail.'
        );


        System.assert(
            result.getErrors().size() > 0,
            'A validation error should be returned.'
        );
    }




    @isTest
    static void testTerritoryOwnerChangeUpdatesRelatedRecords() {


        List<User> users = getTestUsers();



        Territory__c territory = [
            SELECT Id,
                   Owner__c
            FROM Territory__c
            WHERE Zip_Code__c = '33010'
            LIMIT 1
        ];



        Account acc = [
            SELECT Id
            FROM Account
            WHERE BillingPostalCode = '33010'
            LIMIT 1
        ];



        Test.startTest();



        territory.Owner__c = users[1].Id;

        update territory;



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



        System.assertEquals(
            users[1].Id,
            updatedAccount.OwnerId,
            'Account owner should update.'
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



        Assignment_History__c history = [
            SELECT Previous_Owner__c,
                   New_Owner__c
            FROM Assignment_History__c
            WHERE Account__c = :acc.Id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];



        System.assertEquals(
            users[0].Id,
            history.Previous_Owner__c
        );



        System.assertEquals(
            users[1].Id,
            history.New_Owner__c
        );
    }





    @isTest
    static void testBulkTerritoryOwnerUpdate() {


        List<User> users = getTestUsers();



        List<Territory__c> territories = new List<Territory__c>();



        for(Integer i = 0; i < 200; i++) {

            territories.add(
                new Territory__c(
                    Zip_Code__c = '88' + i,
                    Owner__c = users[0].Id
                )
            );
        }



        insert territories;



        Test.startTest();



        for(Territory__c territory : territories) {

            territory.Owner__c = users[1].Id;

        }



        update territories;



        Test.stopTest();



        Integer updatedCount = [
            SELECT COUNT()
            FROM Territory__c
            WHERE Owner__c = :users[1].Id
        ];



        System.assert(
            updatedCount >= 200,
            'All territory records should be updated.'
        );
    }
}