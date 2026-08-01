public virtual class AccountTriggerHandler extends TriggerHandler {
    public override void beforeUpdate() {
        AccountService.processUpdatedAccounts((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.oldMap);
    }
}