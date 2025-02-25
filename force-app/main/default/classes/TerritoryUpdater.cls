public class TerritoryUpdater {

    // Main entry point for updating account owners
    public static void updateOwners(List<Territory__c> newTerritories, Map<Id, Territory__c> oldTerritoryMap) {
        Set<String> zipCodes = getZipCodesFromTerritories(newTerritories);

        List<Account> accounts = fetchAccountsByZipCodes(zipCodes);
        List<Account> accountsToUpdate = findAccountsToUpdate(accounts, oldTerritoryMap);

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    // Helper method to extract zip codes from territories
    private static Set<String> getZipCodesFromTerritories(List<Territory__c> territories) {
        Set<String> zipCodes = new Set<String>();
        for (Territory__c terr : territories) {
            zipCodes.add(terr.Zip_Code__c);
        }
        return zipCodes;
    }

    // Helper method to fetch accounts by zip code
    private static List<Account> fetchAccountsByZipCodes(Set<String> zipCodes) {
        return [SELECT BillingPostalCode, OwnerId FROM Account WHERE BillingPostalCode IN :zipCodes];
    }

    // Helper method to find accounts whose owners have changed
    private static List<Account> findAccountsToUpdate(List<Account> accounts, Map<Id, Territory__c> oldTerritoryMap) {
        List<Account> accountsToUpdate = new List<Account>();
        
        for (Account acc : accounts) {
            Territory__c oldTerritory = oldTerritoryMap.get(acc.Id);
            if (oldTerritory != null && acc.OwnerId != oldTerritory.Owner__c) {
                acc.OwnerId = oldTerritory.Owner__c;
                accountsToUpdate.add(acc);
            }
        }

        return accountsToUpdate;
    }
}
