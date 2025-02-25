public class TerritoryValidator {

    // Main method to validate the territory owners
    public static void validateTerritoryOwners(List<Territory__c> newTerritories) {
        Set<String> zipCodes = extractZipCodes(newTerritories);
        Map<String, List<Id>> zipToOwner = fetchTerritoryOwnersByZip(zipCodes);
        validateMaxOwnersPerZip(newTerritories, zipToOwner);
    }

    // Helper method to extract zip codes from the new territories
    private static Set<String> extractZipCodes(List<Territory__c> territories) {
        Set<String> zipCodes = new Set<String>();
        for (Territory__c terr : territories) {
            zipCodes.add(terr.Zip_Code__c);
        }
        return zipCodes;
    }

    // Helper method to fetch territory owners by zip code
    private static Map<String, List<Id>> fetchTerritoryOwnersByZip(Set<String> zipCodes) {
        List<Territory__c> territories = [SELECT Zip_Code__c, Owner__c FROM Territory__c WHERE Zip_Code__c IN :zipCodes];
        Map<String, List<Id>> zipToOwner = new Map<String, List<Id>>();

        for (Territory__c territory : territories) {
            if (!zipToOwner.containsKey(territory.Zip_Code__c)) {
                zipToOwner.put(territory.Zip_Code__c, new List<Id>());
            }
            zipToOwner.get(territory.Zip_Code__c).add(territory.Owner__c);
        }
        return zipToOwner;
    }

    // Helper method to validate if no more than three owners are assigned to a zip code
    private static void validateMaxOwnersPerZip(List<Territory__c> territories, Map<String, List<Id>> zipToOwner) {
        for (Territory__c terr : territories) {
            List<Id> owners = zipToOwner.get(terr.Zip_Code__c);
            if (owners != null && owners.size() > 3) {
                terr.addError('No more than three Sales Representatives can be assigned to a zip code.');
            }
        }
    }
}
