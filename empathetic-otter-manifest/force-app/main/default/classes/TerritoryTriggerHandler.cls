public virtual class TerritoryTriggerHandler extends TriggerHandler {
    public override void beforeInsert() {
        TerritoryService.validateTerritoryOwners((List<Territory__c>) Trigger.new, (Map<Id, Territory__c>) Trigger.oldMap);        
    }
    public override void afterUpdate( ){
        TerritoryService.reassignTerritoryOwners((List<Territory__c>) Trigger.new, (Map<Id, Territory__c>) Trigger.oldMap);
    }
}