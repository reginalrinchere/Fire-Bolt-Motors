public class TerritoryValidator {
    public static void validateTerritoryOwners(List<Territory__c> newTerritories) {
        Set<String> zipCodes = new Set<String>();
        for (Territory__c terr : newTerritories) {
            zipCodes.add(terr.Zip_Code__c);
        }

        List<Territory__c> territories = [SELECT Zip_Code__c, Owner__c FROM Territory__c WHERE Zip_Code__c IN :zipCodes];
        Map<String, List<Id>> zipToOwner = new Map<String, List<Id>>();

        for (Territory__c territory : territories) {
            if (!zipToOwner.containsKey(territory.Zip_Code__c)) {
                zipToOwner.put(territory.Zip_Code__c, new List<Id>());
            }
            zipToOwner.get(territory.Zip_Code__c).add(territory.Owner__c);
        }

        for (Territory__c terr : newTerritories) {
            List<Id> owners = zipToOwner.get(terr.Zip_Code__c);
            if (owners.size() > 3) {
                terr.addError('No more than three Sales Representatives can be assigned to a zip code.');
            }
        }
    }
}