public class AccountTriggerHandler extends TriggerHandler {
    public override void beforeUpdate() {
        AccountService.collectUpdatedAccounts((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.oldMap);
    }
    public override void beforeInsert() {
        AccountService.validateTerritoryOwners((List<Territory__c>) Trigger.new);
    }
    public override void afterUpdate() {
        AccountService.reassignTerritoryOwner((List<Territory__c>)Trigger.new, (Map<Id, Territory__c>) Trigger.oldMap);
    }
}