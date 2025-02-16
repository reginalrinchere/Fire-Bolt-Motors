public class AccountPostalCodeHandler {

    public static void manageTerritoryOwners(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        List<String> updatedZipCodes = getUpdatedZipCodes(newAccounts, oldAccounts);
        if (updatedZipCodes.isEmpty()) {
            return; // Early return if no zip code changes
        }

        Map<String, Id> zipCodeToOwnerMap = getZipCodeToOwnerMap(updatedZipCodes);
        Map<String, List<Id>> repsPerZipCodeMap = getRepsPerZipCodeMap(updatedZipCodes);
        
        List<Assignment_History__c> newAssignmentRecords = new List<Assignment_History__c>();
        updateAccountOwners(newAccounts, oldAccounts, zipCodeToOwnerMap, repsPerZipCodeMap, newAssignmentRecords);
        
        insertNewAssignmentRecords(newAssignmentRecords);
    }

    // Extracted method to handle record insert
    private static void insertNewAssignmentRecords(List<Assignment_History__c> newAssignmentRecords) {
        if (!newAssignmentRecords.isEmpty()) {
            insert newAssignmentRecords;
        }
    }

    // Refactor to get updated zip codes
    private static List<String> getUpdatedZipCodes(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        List<String> updatedZipCodes = new List<String>();

        for (Account newAccount : newAccounts) {
            if (isPostalCodeChanged(newAccount, oldAccounts)) {
                updatedZipCodes.add(newAccount.BillingPostalCode);
            }
        }
        return updatedZipCodes;
    }

    // Check if the postal code has changed
    private static Boolean isPostalCodeChanged(Account newAccount, Map<Id, Account> oldAccounts) {
        Account oldAccount = oldAccounts.get(newAccount.Id);
        return (oldAccount.BillingPostalCode == null && newAccount.BillingPostalCode != null) ||
               (oldAccount.BillingPostalCode != newAccount.BillingPostalCode);
    }

    // Get zip code to owner map
    private static Map<String, Id> getZipCodeToOwnerMap(List<String> updatedZipCodes) {
        Map<String, Id> zipCodeToOwnerMap = new Map<String, Id>();
        List<Territory__c> relatedTerritories = [SELECT Owner__c, Zip_Code__c FROM Territory__c WHERE Zip_Code__c IN :updatedZipCodes];

        for (Territory__c terr : relatedTerritories) {
            zipCodeToOwnerMap.put(terr.Zip_Code__c, terr.Owner__c);
        }
        return zipCodeToOwnerMap;
    }

    // Get reps per zip code map
    private static Map<String, List<Id>> getRepsPerZipCodeMap(List<String> updatedZipCodes) {
        Map<String, List<Id>> repsPerZipCodeMap = new Map<String, List<Id>>();
        List<Territory__c> relatedTerritories = [SELECT Owner__c, Zip_Code__c FROM Territory__c WHERE Zip_Code__c IN :updatedZipCodes];

        for (Territory__c terr : relatedTerritories) {
            if (!repsPerZipCodeMap.containsKey(terr.Zip_Code__c)) {
                repsPerZipCodeMap.put(terr.Zip_Code__c, new List<Id>());
            }
            repsPerZipCodeMap.get(terr.Zip_Code__c).add(terr.Owner__c);
        }
        return repsPerZipCodeMap;
    }

    // Update account owners based on territory zip code
    private static void updateAccountOwners(List<Account> newAccounts, Map<Id, Account> oldAccounts, Map<String, Id> zipCodeToOwnerMap, Map<String, List<Id>> repsPerZipCodeMap, List<Assignment_History__c> newAssignmentRecords) {
        for (Account newAccount : newAccounts) {
            if (isPostalCodeChanged(newAccount, oldAccounts)) {
                Id ownerId = zipCodeToOwnerMap.get(newAccount.BillingPostalCode);
                List<Id> repsPerZipCode = repsPerZipCodeMap.get(newAccount.BillingPostalCode);

                assignOwnerBasedOnReps(newAccount, ownerId, repsPerZipCode);
                recordOwnerChange(newAccount, oldAccounts.get(newAccount.Id), newAssignmentRecords);
            }
        }
    }

    // Assign the owner based on reps
    private static void assignOwnerBasedOnReps(Account newAccount, Id ownerId, List<Id> repsPerZipCode) {
        if (repsPerZipCode.size() > 1) {
            Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), repsPerZipCode.size());
            newAccount.OwnerId = repsPerZipCode[randomIndex];
            return; // Early return to reduce nesting
        }

        newAccount.OwnerId = ownerId != null ? ownerId : (repsPerZipCode.isEmpty() ? null : repsPerZipCode[0]);
    }

    // Record the owner change in the Assignment History
    private static void recordOwnerChange(Account newAccount, Account oldAccount, List<Assignment_History__c> newAssignmentRecords) {
        Assignment_History__c history = new Assignment_History__c();
        history.Previous_Owner__c = oldAccount.OwnerId;
        history.New_Owner__c = newAccount.OwnerId;
        history.Changed_By__c = UserInfo.getUserId();
        history.Account__c = newAccount.Id;

        List<Territory__c> newTerritories = [SELECT Id FROM Territory__c WHERE Zip_Code__c = :newAccount.BillingPostalCode];
        List<Territory__c> previousTerritories = [SELECT Id FROM Territory__c WHERE Zip_Code__c = :oldAccount.BillingPostalCode];

        if (!previousTerritories.isEmpty()) {
            history.Previous_Territory__c = previousTerritories[0].Id;
        }
        if (!newTerritories.isEmpty()) {
            history.New_Territory__c = newTerritories[0].Id;
        }

        newAssignmentRecords.add(history);
    }
}