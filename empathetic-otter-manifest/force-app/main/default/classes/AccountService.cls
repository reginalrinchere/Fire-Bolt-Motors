public class AccountService {
    public static void processUpdatedAccounts(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        List<Account> qualifiedAccounts = new List<Account>();
        for(Account newAccount : newAccounts) {
            Account oldAccount = oldAccountsMap.get(newAccount.Id);
            if(oldAccount == null) {
                continue;
            }
            String oldPostalCode = oldAccount.BillingPostalCode;
            String newPostalCode = newAccount.BillingPostalCode;
            Boolean isFirstTimeChanged = oldPostalCode == null && newPostalCode != null;
            Boolean isValueChanged = oldPostalCode != newPostalCode;
            if(isValueChanged || isFirstTimeChanged) {
                qualifiedAccounts.add(newAccount);
            }
        }
        if(!qualifiedAccounts.isEmpty()) {
            assignTerritoryOwners(qualifiedAccounts);
            AssignmentHistoryService.createAssignmentHistoryRecords(qualifiedAccounts, oldAccountsMap);
        }
    }
    public static void assignTerritoryOwners(List<Account> qualifiedAccounts) {
        List<String> updatedPostalCodes = new List<String>();
        for(Account qualifiedAccount : qualifiedAccounts) {
            updatedPostalCodes.add(qualifiedAccount.BillingPostalCode);
            
        }
        List<Territory__c> territories = [SELECT Owner__c, Zip_Code__c FROM Territory__c WHERE Zip_Code__c IN :updatedPostalCodes];
        Map<String, List<Id>> territoryMap = new Map<String, List<Id>>();
        for(Territory__c terr : territories) {
            if(!territoryMap.containsKey(terr.Zip_Code__c)) {
                territoryMap.put(terr.Zip_Code__c, new List<Id>());
            }
            territoryMap.get(terr.Zip_Code__c).add(terr.Owner__c);
        }
        Map<Id, Id> accountOwnerMap = new Map<Id, Id>();
        for(Account qualifiedAccount : qualifiedAccounts) {
            List<Id> owners = territoryMap.get(qualifiedAccount.BillingPostalCode);
            if(owners != null && !owners.isEmpty()) {
                if(owners.size() > 1) {
                    Integer randomInteger = Math.Mod(Math.Abs(Crypto.getRandomInteger()), owners.size());
                    qualifiedAccount.OwnerId = owners[randomInteger];
                } else {
                    qualifiedAccount.OwnerId = owners[0];
                }
            }
            accountOwnerMap.put(qualifiedAccount.Id, qualifiedAccount.OwnerId);
        }
        if(!accountOwnerMap.isEmpty()) {
            ContactService.updateContactOwner(accountOwnerMap);
            OpportunityService.updateOpportunityOwner(accountOwnerMap);
        }
    }
}
