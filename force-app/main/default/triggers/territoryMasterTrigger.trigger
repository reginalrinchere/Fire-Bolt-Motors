trigger territoryMasterTrigger on Territory__c (before insert, after insert, after update) {
    new AccountTriggerHandler().run();
}