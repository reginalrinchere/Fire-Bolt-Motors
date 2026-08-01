public class OpportunityService2 {
    public static void updateOpportunityOwnerS(Map<Id, Id> accountOwnerMap) {
        List<Opportunity> opportunityRecords = [SELECT Id, AccountId, OwnerId, StageName FROM Opportunity WHERE AccountId IN 
                                                :accountOwnerMap.keySet() AND StageName NOT IN ('Closed Won','Closed Lost')];
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for(Opportunity opp : opportunityRecords) {
            if(opp.OwnerId != accountOwnerMap.get(opp.AccountId)) {
                opp.OwnerId = accountOwnerMap.get(opp.AccountId);
                opportunitiesToUpdate.add(opp);
            }
        }
        if(!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }
    }
}