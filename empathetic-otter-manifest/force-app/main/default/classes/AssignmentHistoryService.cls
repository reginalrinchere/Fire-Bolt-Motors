public class AssignmentHistoryService {
    public static void createAssignmentHistoryRecords(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        List<String> zipCodes = new List<String>();
        for(Account newAccount : newAccounts) {
            Account oldAccount = oldAccountsMap.get(newAccount.Id);
            if(oldAccount == null) {
                continue;
            } else {
                zipCodes.add(oldAccount.BillingPostalCode);
            }
            zipCodes.add(newAccount.BillingPostalCode);
        }
        List<Territory__c> territoryRecords = [SELECT Id, Owner__c, Zip_Code__c FROM Territory__c WHERE Zip_Code__c IN :zipCodes];
        Map<String, Territory__c> territoryMap = new Map<String, Territory__c>();
        for(Territory__c terr : territoryRecords) {
            if(!territoryMap.containskey(terr.Zip_Code__c)) {
                territoryMap.put(terr.Zip_Code__c, terr);
            } 
        }
        List<Assignment_History__c> assignmentHistoryRecordsToInsert = new List<Assignment_History__c>();
        for(Account newAccount : newAccounts) {
            Account oldAccount = oldAccountsMap.get(newAccount.Id);
            if(oldAccount == null) continue;
            Assignment_History__c history = new Assignment_History__c();
            if(oldAccount.OwnerId != null) {
                history.Previous_Owner__c = oldAccount.OwnerId;
            }
            history.New_Owner__c = newAccount.OwnerId;
            if(territoryMap.get(oldAccount.BillingPostalCode).Id != null) {
                history.Previous_Territory__c = territoryMap.get(oldAccount.BillingPostalCode).Id;
            }
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