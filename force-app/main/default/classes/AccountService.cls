/**
* AccountService
*
* This utility class handles all logic related to assigning account, contact,
* and opportunity owners based on the custom Territory__c object. It also
* tracks owner assignment history in the Assignment_History__c object.
*/
public with sharing class AccountService {
    // ========================================================================================================================
    // COLLECT UPDATED ACCOUNTS
    // ========================================================================================================================
    public static void collectUpdatedAccounts(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        List<String> updatedPostalCodes = new List<String>();
        for (Account updatedAccount : newAccounts) {            
            Account oldAccount = oldAccounts.get(updatedAccount.Id);
            // if (oldAccount == null) {
            //   continue;
            //}
            String oldPostalCode = oldAccount.BillingPostalCode;
            String newPostalCode = updatedAccount.BillingPostalCode;            
            Boolean firstTimeChanged = oldPostalCode == null && newPostalCode != null;
            Boolean isValueChanged = oldPostalCode != newPostalCode;
            if (firstTimeChanged || isValueChanged) {
                updatedPostalCodes.add(updatedAccount.BillingPostalCode);
            }
        }
        if (updatedPostalCodes.isEmpty()) {
            return;
        }
        assignTerritoryOwner(updatedPostalCodes, newAccounts);
        createAssignmentHistoryRecord(updatedPostalCodes, newAccounts, oldAccounts);
    }
    // ========================================================================================================================
    // ASSIGN TERRITORY OWNERS
    // ========================================================================================================================
    public static void assignTerritoryOwner(List<String> updatedPostalCodes, List<Account> newAccounts) {
        Map<String, List<Id>> terrOwnersMap = new Map<String, List<Id>>();
        List<Account> accountsToUpdate = new List<Account>();
        for (Territory__c terr : [SELECT Owner__c, Zip_Code__c FROM Territory__c WHERE Zip_Code__c IN :updatedPostalCodes]) {
            if (!terrOwnersMap.containsKey(terr.Zip_Code__c)) {
                terrOwnersMap.put(terr.Zip_Code__c, new List<Id>());
            }
            terrOwnersMap.get(terr.Zip_Code__c).add(terr.Owner__c);
        }
        Map<Id, Id> accountToOwnerMap = new Map<Id, Id>();
        for (Account newAccount : newAccounts) {
            List<Id> owners = terrOwnersMap.get(newAccount.BillingPostalCode);
            if (owners != null && !owners.isEmpty()) {
                Id selectedOwner;
                if (owners.size() > 1) {
                    Integer randIndex = Math.mod(Crypto.getRandomInteger(), owners.size());
                    newAccount.OwnerId = owners[randIndex];
                } else {
                    newAccount.OwnerId = owners[0];
                }
            }
            accountsToUpdate.add(newAccount);
            accountToOwnerMap.put(newAccount.Id, newAccount.OwnerId);
        }
        setContactOwner(accountToOwnerMap);
        setOpportunityOwner(accountToOwnerMap);
    }
    // ========================================================================================================================
    // UPDATE CONTACT OWNERS
    // ========================================================================================================================
    public static void setContactOwner(Map<Id, Id> accountOwnerMap) {
        List<Contact> updatedContacts = new List<Contact>();
        for (Contact con : [SELECT AccountId, OwnerId FROM Contact WHERE AccountId IN :accountOwnerMap.keySet()]) {
            if (con.OwnerId != accountOwnerMap.get(con.AccountId)) {
                con.OwnerId = accountOwnerMap.get(con.AccountId);
                updatedContacts.add(con);
            }
        }
        if (!updatedContacts.isEmpty()) {
            try {
                update updatedContacts;
            } catch (DmlException e) {
                system.debug('DML Error: ' +e.getMessage());
            }
        }
    }
    // ========================================================================================================================
    // UPDATE OPPORTUNITY OWNERS
    // ========================================================================================================================
    public static void setOpportunityOwner(Map<Id, Id> accountOwnerMap) {
        List<Opportunity> updatedOpportunities = new List<Opportunity>();
        for (Opportunity opp : [SELECT AccountId, OwnerId FROM Opportunity WHERE AccountId IN :accountOwnerMap.keySet()]) {
            if (opp.OwnerId != accountOwnerMap.get(opp.AccountId)) {
                opp.OwnerId = accountOwnerMap.get(opp.AccountId);
                updatedOpportunities.add(opp);
            }
        }
        if (!updatedOpportunities.isEmpty()) {
            try {
                update updatedOpportunities;
            } catch (DmlException e) {
                system.debug('DML Error: ' +e.getMessage());
            }
        }
    }
    // ========================================================================================================================
    // TERRITORY VALIDATION
    // ========================================================================================================================
    public static void validateTerritoryOwners(List<Territory__c> newTerritories) {
        if (newTerritories == null || newTerritories.isEmpty()) {
            return;
        }
        
        List<String> zipCodes = new List<String>();
        for (Territory__c terr : newTerritories) {
            if (terr.Zip_Code__c != null) {
                zipCodes.add(terr.Zip_Code__c);
            }
        }
        
        if (zipCodes.isEmpty()) return;
        
        Map<String, List<Id>> zipCodeToOwner = new Map<String, List<Id>>();        
        for (Territory__c terr : [
            SELECT Zip_Code__c, Owner__c 
            FROM Territory__c 
            WHERE Zip_Code__c IN :zipCodes
        ]) {
            if (!zipCodeToOwner.containsKey(terr.Zip_Code__c)) {
                zipCodeToOwner.put(terr.Zip_Code__c, new List<Id>());
            }
            zipCodeToOwner.get(terr.Zip_Code__c).add(terr.Owner__c);
        }
        
        for (Territory__c terr : newTerritories) {
            List<Id> owners = zipCodeToOwner.get(terr.Zip_Code__c);
            if (owners != null && owners.size() > 2) {
                terr.addError('Three sales representatives at most can be assigned to a single zip code.');
            }
        }
    }
    
    // ========================================================================================================================
    // CREATE ASSIGNMENT HISTORY RECORD
    // ========================================================================================================================
    public static void createAssignmentHistoryRecord(
        List<String> updatedPostalCodes,
        List<Account> newAccounts,
        Map<Id, Account> oldAccounts
    ) {
        // Step 1: Gather all involved postal codes
        Set<String> allPostalCodes = new Set<String>();
        for (Account acc : newAccounts) {
            allPostalCodes.add(acc.BillingPostalCode);
            Account oldAcc = oldAccounts.get(acc.Id);
            if (oldAcc != null && oldAcc.BillingPostalCode != null) {
                allPostalCodes.add(oldAcc.BillingPostalCode);
            }
        }
        
        // Step 2: Query all relevant Territory__c records
        Map<String, Territory__c> zipToTerritoryMap = new Map<String, Territory__c>();
        for (Territory__c terr : [
            SELECT Id, Zip_Code__c FROM Territory__c
            WHERE Zip_Code__c IN :allPostalCodes
        ]) {
            // Only store one per zip (as original code only uses [0])
            if (!zipToTerritoryMap.containsKey(terr.Zip_Code__c)) {
                zipToTerritoryMap.put(terr.Zip_Code__c, terr);
            }
        }
        
        // Step 3: Build Assignment_History__c records
        List<Assignment_History__c> newAssignmentRecords = new List<Assignment_History__c>();
        for (Account updatedAccount : newAccounts) {
            Account oldAccount = oldAccounts.get(updatedAccount.Id);
            if (oldAccount == null) continue;
            
            Assignment_History__c assignmentHistory = new Assignment_History__c();
            assignmentHistory.Previous_Owner__c = oldAccount.OwnerId;
            assignmentHistory.New_Owner__c = updatedAccount.OwnerId;
            assignmentHistory.Account__c = updatedAccount.Id;
            assignmentHistory.Changed_By__c = UserInfo.getUserId();
            
            // Step 4: Lookup territories from map instead of querying
            if (oldAccount.BillingPostalCode != null && zipToTerritoryMap.containsKey(oldAccount.BillingPostalCode)) {
                assignmentHistory.Previous_Territory__c = zipToTerritoryMap.get(oldAccount.BillingPostalCode).Id;
            }
            
            if (updatedAccount.BillingPostalCode != null && zipToTerritoryMap.containsKey(updatedAccount.BillingPostalCode)) {
                assignmentHistory.New_Territory__c = zipToTerritoryMap.get(updatedAccount.BillingPostalCode).Id;
            }
            
            newAssignmentRecords.add(assignmentHistory);
        }
        
        if (!newAssignmentRecords.isEmpty()) {
            try {
                insert newAssignmentRecords;
            } catch (DmlException e) {
                system.debug('DML ERROR: ' +e.getMessage());
            }
        }
    }
    // ========================================================================================================================
    // REASSIGN BASED ON TERRITORY CHANGE
    // ========================================================================================================================
    public static void reassignTerritoryOwner(List<Territory__c> newTerr, Map<Id, Territory__c> oldTerritoryMap) {
        List<String> changedZipCodes = new List<String>();
        for (Territory__c terr : newTerr) {
            if (oldTerritoryMap.containsKey(terr.Id)) {
                Territory__c oldTerr = oldTerritoryMap.get(terr.Id);
            if (oldTerr.Owner__c != terr.Owner__c) {
                changedZipCodes.add(terr.Zip_Code__c);
            }
            }
        }
        List<Account> affectedAccounts = [SELECT Id, OwnerId, BillingPostalCode FROM Account WHERE BillingPostalCode IN :changedZipCodes];
        if (affectedAccounts.isEmpty()) {
            return;
        }
        assignTerritoryOwner(changedZipCodes, affectedAccounts);
        Map<Id, Account> oldAccounts = new Map<Id, Account>();
        for (Account acc : affectedAccounts) {
            oldAccounts.put(acc.Id, acc);
        }
        if (!affectedAccounts.isEmpty()) {
            try {
                update affectedAccounts;
            } catch (DmlException e) {
                system.debug('DML Exception: ' +e.getMessage());
            }
        }
        createAssignmentHistoryRecord(changedZipCodes, affectedAccounts, oldAccounts);
    }
}