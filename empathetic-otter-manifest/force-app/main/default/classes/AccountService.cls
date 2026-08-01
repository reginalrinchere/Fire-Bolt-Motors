public class AccountService {
    public static void processUpdatedAccounts(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        List<String> updatedPostalCodes = new List<String>();
        for(Account newAccount : newAccounts) {
            Account oldAccount = oldAccountsMap.get(newAccount.Id);
            if(oldAccount == null) continue;
            String oldPostalCode = oldAccount.BillingPostalCode;
            String newPostalCode = newAccount.BillingPostalCode;
            Boolean isFirstTimeChanged = oldPostalCode == null && newPostalCode != null;
            Boolean isValueChanged = oldPostalCode != newPostalCode;
            if(isValueChanged || isFirstTimeChanged) {
                updatedPostalCodes.add(newAccount.BillingPostalCode);
            }
        }
        if(!updatedPostalCodes.isEmpty()) {
            assignTerritoryOwners(updatedPostalCodes, newAccounts);
        }
        AssignmentHistoryService.createAssignmentHistoryRecords(newAccounts, oldAccountsMap);
    }
    public static void assignTerritoryOwners(List<String> zipCodes, List<Account> newAccounts) {
        List<Territory__c> territoryRecords = [SELECT Id, Owner__c, Zip_Code__c FROM Territory__c WHERE Zip_Code__C IN :zipCodes];
        if(territoryRecords.isEmpty()) return;
        Map<String, List<Id>> territoryOwnerMap = new Map<String, List<Id>>();
        for(Territory__c terr : territoryRecords) {
            if(! territoryOwnerMap.containsKey(terr.Zip_Code__c)) {
                territoryOwnerMap.put(terr.Zip_Code__c, new List<Id>());
            }
            territoryOwnerMap.get(terr.Zip_Code__c).add(terr.Owner__c);
        }
        Map<Id, Id> accountOwnerMap = new Map<Id, Id>();
        for(Account newAccount : newAccounts) {
            List<Id> owners = territoryOwnerMap.get(newAccount.BillingPostalCode);
            if(owners != null && !owners.isEmpty()) {
                if(owners.size() > 1) {
                    Integer randomIndex = Math.Mod(Math.Abs(Crypto.getRandomInteger()), owners.size());
                    newAccount.OwnerId = owners[randomIndex];
                } else {
                    newAccount.OwnerId = owners[0];
                }
            }
            accountOwnerMap.put(newAccount.Id, newAccount.OwnerId);
        }
        if(!accountOwnerMap.isEmpty() && accountOwnerMap != null) {
            ContactService.updateContactOwners(accountOwnerMap);
            OpportunityService2.updateOpportunityOwners(accountOwnerMap);
        }
    }
}