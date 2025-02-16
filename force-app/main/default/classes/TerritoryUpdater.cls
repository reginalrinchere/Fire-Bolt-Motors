public class TerritoryUpdater {
    public static void updateOwners(List<Territory__c> newTerritories, Map<Id, Territory__c> oldTerritoryMap) {
        Set<String> zipCodes = new Set<String>();
        for (Territory__c terr : newTerritories) {
            zipCodes.add(terr.Zip_Code__c);
        }

        List<Account> accounts = [SELECT BillingPostalCode, OwnerId FROM Account WHERE BillingPostalCode IN :zipCodes];
        List<Account> accountsToUpdate = new List<Account>();

        for (Account acc : accounts) {
            if (acc.OwnerId != oldTerritoryMap.get(acc.Id).Owner__c) {
                acc.OwnerId = oldTerritoryMap.get(acc.Id).Owner__c;
                accountsToUpdate.add(acc);
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}