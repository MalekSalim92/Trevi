public without sharing class UserProfileController { 
    
    @AuraEnabled(cacheable=true) 
    public static User getUserInfo(Id userId) {
        return [SELECT Id, ContactId, AccountId, Contact.FirstName, Contact.LastName,
                Contact.Email, Contact.Phone, Contact.DoNotCall, Contact.HasOptedOutOfEmail,
                Account.Cellphone__c, Account.Phone, Contact.MobilePhone, Account.Name,
                LanguageLocaleKey, Account.Sage_ID__c, Account.Email__c 
                FROM User WHERE Id = :userId];
    } 
    
    @AuraEnabled 
    public static void saveUserInfo(User user, Contact contact, Account account) {
        try { 
            // First, update setup object (User) synchronously
            update user; 
            
            // Then, update non-setup objects (Account, Contact) asynchronously
            updateContactAccountAsync(JSON.serialize(contact), JSON.serialize(account));
                     
        } catch (Exception e) { 
            throw new AuraHandledException(e.getMessage()); 
        } 
    } 
    
    @future
    public static void updateContactAccountAsync(String contactJson, String accountJson) {
        try {
            // Deserialize objects
            Contact contactToUpdate = (Contact) JSON.deserialize(contactJson, Contact.class);
            Account accountToUpdate = (Account) JSON.deserialize(accountJson, Account.class);
            
            update contactToUpdate;
            update accountToUpdate;
            
        } catch (Exception e) {
            System.debug('Error updating contact/account: ' + e.getMessage());
        }
    }
}