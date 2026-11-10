public class AssignmentHistoryService {
 public static void createAssignmentHistoryRecords(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        List<String> zipCodes = new List<String>();
        for(Account newAccount : newAccounts) {
            Account oldAccount = oldAccountsMap.get(newAccount.Id);
            if(oldAccount != null && oldAccount.BillingPostalCode != null) {
                zipCodes.add(oldAccount.BillingPostalCode);
            }
            if(newAccount.BillingPostalCode != null) {
                zipCodes.add(newAccount.BillingPostalCode);
            }
        }
        List<Territory__c> territories = [SELECT Id, Owner__c, Zip_Code__c FROM Territory__c WHERE Zip_Code__c IN :zipCodes];
        Map<String, Territory__c> territoryMap = new Map<String, Territory__c>();
        for(Territory__c terr : territories) {
            if(!territoryMap.containsKey(terr.Zip_Code__c)) {
                territoryMap.put(terr.Zip_Code__c, terr);
            }
        }
        List<Assignment_History__c> assignmentHistoryRecordsToInsert = new List<Assignment_History__c>();
        for(Account newAccount : newAccounts) {
            Account oldAccount = oldAccountsMap.get(newAccount.Id);
            if(oldAccount == null || String.isBlank(oldAccount.OwnerId)) {
                continue;
            }
            Assignment_History__c history = new Assignment_History__c();
            history.Previous_Owner__c = oldAccount.OwnerId;
            history.New_Owner__c = newAccount.OwnerId;
            history.Previous_Territory__c = territoryMap.get(oldAccount.BillingPostalCode).Id;
            history.New_Territory__c = territoryMap.get(newAccount.BillingPostalCode).Id;
            history.Account__c = newAccount.Id;
            history.Changed_By__c = userInfo.getUserId();
            assignmentHistoryRecordsToInsert.add(history);
        }
        if(!assignmentHistoryRecordsToInsert.isEmpty()) {
            insert assignmentHistoryRecordsToInsert;
        }
    }
}
