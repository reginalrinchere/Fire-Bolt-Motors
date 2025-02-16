trigger ManageOwners on Territory__c (after insert, after update) {
    if (Trigger.isInsert) {
        TerritoryValidator.validateTerritoryOwners(Trigger.new);
    } else if (Trigger.isUpdate) {
        TerritoryUpdater.updateOwners(Trigger.new, Trigger.oldMap);
    }
}