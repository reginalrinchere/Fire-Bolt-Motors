trigger TerritoryValidator on Territory__c (after insert, after update) {
    // Call the handler method for insert
    if (Trigger.isInsert) {
        TerritoryValidator.validateTerritoryOwners(Trigger.new);
    } 
    
    // Call the handler method for update
    else if (Trigger.isUpdate) {
        // Call the handleUpdate method in TerritoryUpdater with correct arguments
        TerritoryUpdater.handleUpdate(Trigger.new, Trigger.oldMap);
    }
}