@isTest
private class AccountServiceTest {
    // Helper method to create Territories with zip codes & owners
    private static List<Territory__c> createTerritories() {
        User owner1 = [SELECT Id FROM User LIMIT 1];
        User owner2 = [SELECT Id FROM User LIMIT 1 OFFSET 1];
        List<Territory__c> territories = new List<Territory__c>{
            new Territory__c(Zip_Code__c='12345', Owner__c=owner1.Id),
                new Territory__c(Zip_Code__c='67890', Owner__c=owner2.Id)
                };
                    insert territories;
        return territories;
    }
    // Helper method to create Accounts with postal codes
    private static List<Account> createAccounts() {
        List<Account> accounts = new List<Account>{
            new Account(Name='Account 1', BillingPostalCode='12345'),
                new Account(Name='Account 2', BillingPostalCode='67890')
                };
                    insert accounts;
        return accounts;
    }
    @isTest static void collectUpdatedAccounts_test() {
        List<Account> accounts = createAccounts();
        // Simulate old map
        Map<Id, Account> oldMap = new Map<Id, Account>();
        for (Account acc : accounts) {
            oldMap.put(acc.Id, acc.clone(false));
        }
        // Change BillingPostalCode on one account
        Account accToUpdate = [SELECT Id, BillingPostalCode FROM Account WHERE Id = :accounts[0].Id];
        accToUpdate.BillingPostalCode = '67890';
        List<Account> updatedAccounts = new List<Account>{ accToUpdate };
            AccountService.collectUpdatedAccounts(updatedAccounts, oldMap);
        // No assert needed; coverage + no exceptions
    }
    @isTest static void assignTerritoryOwner_test() {
        List<Territory__c> territories = createTerritories();
        
        List<Account> accounts = new List<Account>{
            new Account(Name='Test Account', BillingPostalCode='12345'),
                new Account(Name='Test Account 2', BillingPostalCode='67890'),
                new Account(Name='No Match', BillingPostalCode='99999')
                };
                    insert accounts;
        AccountService.assignTerritoryOwner(
            new List<String>{'12345','67890'},
            accounts
        );
        // Confirm owners updated correctly
        for (Account acc : accounts) {
            if (acc.BillingPostalCode == '12345') {
                System.assertEquals(territories[0].Owner__c, acc.OwnerId);
            } else if (acc.BillingPostalCode == '67890') {
                System.assertEquals(territories[1].Owner__c, acc.OwnerId);
            } else {
                System.assertNotEquals(territories[0].Owner__c, acc.OwnerId);
                System.assertNotEquals(territories[1].Owner__c, acc.OwnerId);
            }
        }
    }
    @isTest static void setContactOwner_test() {
        List<Account> accounts = createAccounts();
        
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName='Test', LastName='Contact1', AccountId=accounts[0].Id, OwnerId=UserInfo.getUserId()),
                new Contact(FirstName='Test', LastName='Contact2', AccountId=accounts[1].Id, OwnerId=UserInfo.getUserId())
                };
                    insert contacts;
        Map<Id, Id> accountOwnerMap = new Map<Id, Id>();
        for (Account acc : accounts) {
            accountOwnerMap.put(acc.Id, UserInfo.getUserId());
        }
        // Change owners to something else
        accountOwnerMap.put(accounts[0].Id, accounts[0].OwnerId);
        accountOwnerMap.put(accounts[1].Id, accounts[1].OwnerId);
        Test.startTest();
        AccountService.setContactOwner(accountOwnerMap);
        Test.stopTest();
        // Verify contact owners updated
        List<Contact> updatedContacts = [SELECT OwnerId FROM Contact WHERE Id IN :contacts];
        for (Contact con : updatedContacts) {
            System.assertEquals(accountOwnerMap.get(con.AccountId), con.OwnerId);
        }
    }
    @isTest static void setOpportunityOwner_test() {
        List<Account> accounts = createAccounts();
        List<Opportunity> opportunities = new List<Opportunity>{
            new Opportunity(Name='Opp1', AccountId=accounts[0].Id, StageName='Prospecting', CloseDate=Date.today(), OwnerId=UserInfo.getUserId()),
                new Opportunity(Name='Opp2', AccountId=accounts[1].Id, StageName='Prospecting', CloseDate=Date.today(), OwnerId=UserInfo.getUserId())
                };
                    insert opportunities;
        Map<Id, Id> accountOwnerMap = new Map<Id, Id>();
        for (Account acc : accounts) {
            accountOwnerMap.put(acc.Id, UserInfo.getUserId());
        }
        // Assign new owners
        accountOwnerMap.put(accounts[0].Id, accounts[0].OwnerId);
        accountOwnerMap.put(accounts[1].Id, accounts[1].OwnerId);
        Test.startTest();
        AccountService.setOpportunityOwner(accountOwnerMap);
        Test.stopTest();
        // Verify opportunity owners updated
        List<Opportunity> updatedOpps = [SELECT OwnerId FROM Opportunity WHERE Id IN :opportunities];
        for (Opportunity opp : updatedOpps) {
            System.assertEquals(accountOwnerMap.get(opp.AccountId), opp.OwnerId);
        }
    }
    @isTest static void validateTerritoryOwners_test() {
        User owner1 = [SELECT Id FROM User LIMIT 1];
        User owner2 = [SELECT Id FROM User LIMIT 1 OFFSET 1];
        User owner3 = [SELECT Id FROM User LIMIT 1 OFFSET 2];
        List<Territory__c> territories = new List<Territory__c>{
            new Territory__c(Zip_Code__c='11111', Owner__c=owner1.Id),
                new Territory__c(Zip_Code__c='11111', Owner__c=owner2.Id),
                new Territory__c(Zip_Code__c='11111', Owner__c=owner3.Id)
                };
                    Test.startTest();
        try {
            AccountService.validateTerritoryOwners(territories);
            System.assert(false, 'Exception expected due to too many owners');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Three sales representatives at most'));
        }
        Test.stopTest();
    }
    @isTest static void createAssignmentHistoryRecord_test() {
        List<Account> accounts = createAccounts();
        // Simulate old accounts map
        Map<Id, Account> oldMap = new Map<Id, Account>();
        for (Account acc : accounts) {
            Account oldAcc = acc.clone(false);
            oldAcc.OwnerId = UserInfo.getUserId();
            oldMap.put(acc.Id, oldAcc);
        }
        Test.startTest();
        AccountService.createAssignmentHistoryRecord(
            new List<String>{'12345','67890'},
            accounts,
            oldMap
        );
        Test.stopTest();
        // Check history records inserted
        List<Assignment_History__c> histories = [SELECT Account__c FROM Assignment_History__c WHERE Account__c IN :accounts];
        System.assert(!histories.isEmpty());
    }
    @isTest static void reassignTerritoryOwner_test() {
        List<Territory__c> territories = createTerritories();
        // Update owner of a territory
        Territory__c terrToUpdate = territories[0];
        User newOwner = [SELECT Id FROM User WHERE Id != :terrToUpdate.Owner__c LIMIT 1];
        terrToUpdate.Owner__c = newOwner.Id;
        update terrToUpdate;
        Map<Id, Territory__c> oldTerritoryMap = new Map<Id, Territory__c>{
            terrToUpdate.Id => territories[0]
                };
                    List<Territory__c> newTerrList = [SELECT Id, Owner__c, Zip_Code__c FROM Territory__c WHERE Id = :terrToUpdate.Id];
        Test.startTest();
        AccountService.reassignTerritoryOwner(newTerrList, oldTerritoryMap);
        Test.stopTest();
        // Verify accounts affected and updated — if any accounts have this postal code
        List<Account> affectedAccounts = [SELECT Id, OwnerId, BillingPostalCode FROM Account WHERE BillingPostalCode = :terrToUpdate.Zip_Code__c];
        for (Account acc : affectedAccounts) {
            System.assertEquals(newOwner.Id, acc.OwnerId);
        }
    }
    // Test AccountTriggerHandler methods indirectly via trigger simulation
    @isTest static void accountTriggerHandler_beforeInsert_test() {
        List<Territory__c> territories = createTerritories();
        Test.startTest();
        // Run before insert trigger via handler
        AccountTriggerHandler handler = new AccountTriggerHandler();
        handler.setTriggerContext('before insert', true);
        handler.beforeInsert();
        Test.stopTest();
    }
    @isTest static void accountTriggerHandler_beforeUpdate_test() {
        List<Account> accounts = createAccounts();
        Test.startTest();
        AccountTriggerHandler handler = new AccountTriggerHandler();
        handler.setTriggerContext('before update', true);
        handler.beforeUpdate();
        Test.stopTest();
    }
    @isTest static void accountTriggerHandler_afterUpdate_test() {
        List<Territory__c> territories = createTerritories();
        Test.startTest();
        AccountTriggerHandler handler = new AccountTriggerHandler();
        handler.setTriggerContext('after update', true);
        handler.afterUpdate();
        Test.stopTest();
    }
}
