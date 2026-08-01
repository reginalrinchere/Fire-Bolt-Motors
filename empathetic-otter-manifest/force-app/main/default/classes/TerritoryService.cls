public class TerritoryService {
    public static void validateTerritoryOwners(List<Territory__c> newTerritories, Map<Id, Territory__c> oldTerritoryMap) {
        List<String> zipCodes = new List<String>();
        for(Territory__c newTerritory : newTerritories) {
            zipCodes.add(newTerritory.Zip_Code__c);
        }
        List<Territory__c> territoryRecords = [SELECT Id, Zip_Code__c, Owner__c FROM Territory__c WHERE Zip_Code__c IN :zipCodes];
        Map<String, List<Id>> territoryOwnerMap = new Map<String, List<Id>>();
        for(Territory__c terr : territoryRecords) {
            if(!territoryOwnerMap.containsKey(terr.Zip_Code__c)) {
                territoryOwnerMap.put(terr.Zip_Code__c, new List<Id>());
            }
            territoryOwnerMap.get(terr.Zip_Code__c).add(terr.Owner__c);
        }
        for(Territory__c newTerritory : newTerritories) {
            List<Id> owners = territoryOwnerMap.get(newTerritory.Zip_Code__c);
            if(owners != null && !owners.isEmpty()) {
                if(owners.size() > 2) {
                    newTerritory.addError('Three sales representatives at most can be assigned to a single zip code.');
                }
            }
        }
    }
    public static void reassignTerritoryOwners(List<Territory__c> newTerritories, Map<Id, Territory__c> oldTerritoryMap) {
        List<String> zipCodes =new List<String>();
        Map<String, Id> territoryOwnerMap = new Map<String, Id>();
        for(Territory__c newTerritory : newTerritories) {
            Territory__c oldTerritory = oldTerritoryMap.get(newTerritory.Id);
            if(oldTerritory == null) continue;
            if(oldTerritory != null && oldTerritory.Owner__c != newTerritory.Owner__c) {
                zipCodes.add(newTerritory.Zip_Code__c);
                territoryOwnerMap.put(newTerritory.Zip_Code__c, newTerritory.Owner__c);
            }
        }
        List<Account> accountsToUpdate = new List<Account>();
        List<Account> affectedAccounts = [SELECT Id, OwnerId, BillingPostalCode FROM Account WHERE BillingPostalCode IN :zipCodes];
        for(Account acc : affectedAccounts) {
            if(acc.OwnerId != territoryOwnerMap.get(acc.BillingPostalCode)) {
                acc.OwnerId = territoryOwnerMap.get(acc.BillingPostalCode);
                accountsToUpdate.add(acc);
            }
        }
        if(!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
            AccountService.assignTerritoryOwners(zipCodes, accountsToUpdate);
        }
    }
}
