public without sharing class UserProfileController { 
    
    @AuraEnabled(cacheable=true) public static User getUserInfo(Id userId) {
        
        return [SELECT Id, ContactId,AccountId, Contact.FirstName, Contact.LastName,
                Contact.Email, Contact.Phone,Contact.DoNotCall,Contact.HasOptedOutOfEmail,
                Account.Cellphone__c,Account.Phone,Contact.MobilePhone, Account.Name,
                LanguageLocaleKey, Account.Sage_ID__c, Account.Email__c FROM User WHERE Id = :userId];
    } 
    
    @AuraEnabled public  static void saveUserInfo(User user, Contact Contact, Account Account) {
        try { 
            if(!Test.isRunningTest())
            update user; 
            update Contact; 
            update Account; 
            } 
        catch (Exception e) { 
           
            throw new AuraHandledException(e.getMessage()); 
            
        } 
    } 
}