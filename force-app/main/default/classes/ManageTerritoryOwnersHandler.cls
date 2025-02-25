public class ManageTerritoryOwnersHandler {

    public static void changeAccountOwner(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        List<String> updatedZipCodes = new List<String>();
        List<Assignment_History__c> newAssignmentRecords = new List<Assignment_History__c>();
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

        // Identify zip codes that have changed
        identifyUpdatedZipCodes(newAccounts, oldAccounts, updatedZipCodes);

        // If no zip codes have changed, exit early
        if (updatedZipCodes.isEmpty()) {
            return;
        }

        // Retrieve territory owners based on updated zip codes
        Map<String, Id> territoryOwners = getTerritoryOwners(updatedZipCodes);

        // If no territory owners found, exit early
        if (territoryOwners.isEmpty()) {
            return;
        }

        // Group territory owners by zip code
        Map<String, List<Id>> terrOwner = groupTerritoryOwnersByZipCode(updatedZipCodes);

        // Process account ownership changes and track history
        processAccountOwnershipChanges(newAccounts, oldAccounts, territoryOwners, terrOwner, newAssignmentRecords);

        // Update related contacts and opportunities
        updateRelatedContactsAndOpportunities(newAccounts, contactsToUpdate, opportunitiesToUpdate, territoryOwners);

        // Insert history records and update related entities
        insertHistoryAndUpdateEntities(newAssignmentRecords, contactsToUpdate, opportunitiesToUpdate);
    }

    // Helper methods

    private static void identifyUpdatedZipCodes(List<Account> newAccounts, Map<Id, Account> oldAccounts, List<String> updatedZipCodes) {
        for (Account newAccount : newAccounts) {
            Account oldAccount = oldAccounts.get(newAccount.Id);
            if (hasPostalCodeChanged(oldAccount, newAccount)) {
                updatedZipCodes.add(newAccount.BillingPostalCode);
            }
        }
    }

    private static Boolean hasPostalCodeChanged(Account oldAccount, Account newAccount) {
        return (oldAccount.BillingPostalCode == null && newAccount.BillingPostalCode != null) ||
               (oldAccount.BillingPostalCode != newAccount.BillingPostalCode);
    }

    private static Map<String, Id> getTerritoryOwners(List<String> updatedZipCodes) {
        List<Territory__c> territoryOwner = [SELECT Owner__c, Zip_Code__c FROM Territory__c WHERE Zip_Code__c IN :updatedZipCodes];
        Map<String, Id> territoryOwners = new Map<String, Id>();

        for (Territory__c terr : territoryOwner) {
            territoryOwners.put(terr.Zip_Code__c, terr.Owner__c);
        }

        return territoryOwners;
    }

    private static Map<String, List<Id>> groupTerritoryOwnersByZipCode(List<String> updatedZipCodes) {
        Map<String, List<Id>> terrOwner = new Map<String, List<Id>>();
        List<Territory__c> territoryOwner = [SELECT Owner__c, Zip_Code__c FROM Territory__c WHERE Zip_Code__c IN :updatedZipCodes];

        for (Territory__c terr : territoryOwner) {
            if (!terrOwner.containsKey(terr.Zip_Code__c)) {
                terrOwner.put(terr.Zip_Code__c, new List<Id>());
            }
            terrOwner.get(terr.Zip_Code__c).add(terr.Owner__c);
        }

        return terrOwner;
    }

    private static void processAccountOwnershipChanges(List<Account> newAccounts, Map<Id, Account> oldAccounts,
                                                       Map<String, Id> territoryOwners, Map<String, List<Id>> terrOwner,
                                                       List<Assignment_History__c> newAssignmentRecords) {
        for (Account newAccount : newAccounts) {
            Account oldAccount = oldAccounts.get(newAccount.Id);
            if (hasPostalCodeChanged(oldAccount, newAccount)) {
                Id ownerId = territoryOwners.get(newAccount.BillingPostalCode);
                List<Id> owners = terrOwner.get(newAccount.BillingPostalCode);
                Id selectedOwner = selectOwner(owners);

                // Assign owner to account
                newAccount.OwnerId = selectedOwner != null ? selectedOwner : ownerId;

                // Create history record for account owner change
                createAssignmentHistory(newAccount, oldAccount, newAssignmentRecords);
            }
        }
    }

    private static Id selectOwner(List<Id> owners) {
        if (owners != null && owners.size() > 1) {
            Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), owners.size());
            return owners[randomIndex];
        }
        return owners != null && owners.size() == 1 ? owners[0] : null;
    }

    private static void createAssignmentHistory(Account newAccount, Account oldAccount, List<Assignment_History__c> newAssignmentRecords) {
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

    private static void updateRelatedContactsAndOpportunities(List<Account> newAccounts, List<Contact> contactsToUpdate,
                                                              List<Opportunity> opportunitiesToUpdate, Map<String, Id> territoryOwners) {
        List<Contact> relatedContacts = [SELECT Id, AccountId FROM Contact WHERE AccountId IN :newAccounts];
        List<Opportunity> relatedOpportunities = [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :newAccounts];

        for (Contact con : relatedContacts) {
            con.OwnerId = territoryOwners.get(con.AccountId.BillingPostalCode);
            contactsToUpdate.add(con);
        }

        for (Opportunity opp : relatedOpportunities) {
            opp.OwnerId = territoryOwners.get(opp.AccountId.BillingPostalCode);
            opportunitiesToUpdate.add(opp);
        }
    }

    private static void insertHistoryAndUpdateEntities(List<Assignment_History__c> newAssignmentRecords,
                                                       List<Contact> contactsToUpdate, List<Opportunity> opportunitiesToUpdate) {
        if (!newAssignmentRecords.isEmpty()) {
            insert newAssignmentRecords;
        }

        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }

        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }
}