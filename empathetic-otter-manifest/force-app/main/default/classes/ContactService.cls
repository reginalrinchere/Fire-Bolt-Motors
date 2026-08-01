public class ContactService {
    public static void updateContactOwners(Map<Id, Id> accountOwnerMap) {
        List<Contact> contactRecords = [SELECT Id, AccountId, OwnerId FROM Contact WHERE AccountId IN :accountOwnerMap.keySet()];
        List<Contact> contactsToUpdate = new List<Contact>();
        for(Contact con : contactRecords) {
            if(con.OwnerId != accountOwnerMap.get(con.AccountId)) {
                con.OwnerId = accountOwnerMap.get(con.AccountId);
                contactsToUpdate.add(con);
            }
        }
        if(!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }
}