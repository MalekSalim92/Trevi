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
            // First, update non-setup objects (Account, Contact)
            update contact; 
            update account; 
            
            // Then, in a separate context, update setup objects (User)
            // Use a future method to avoid MIXED_DML_OPERATION
            updateUserAsync(user.Id, JSON.serialize(user));
                     
        } catch (Exception e) { 
            throw new AuraHandledException(e.getMessage()); 
        } 
    } 
    
    @future
    public static void updateUserAsync(Id userId, String userJson) {
        try {
            // Deserialize the user object
            User userToUpdate = (User) JSON.deserialize(userJson, User.class);
            
             userToUpdate.Id = userId;
            
            update userToUpdate;
        } catch (Exception e) {
            System.debug('Error updating user: ' + e.getMessage());
        }
    }
}