trigger TerritoryTrigger on Territory__c (before insert, after update) {
new TerritoryTriggerHandler().run();
}