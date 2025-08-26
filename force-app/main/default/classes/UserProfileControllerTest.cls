@isTest
public class UserProfileControllerTest {
    
    @isTest
    static void testGetUserInfo() {
        // Create a new Account
        Account testAccount = new Account(Name = 'Test Account', 
                                          BillingStreet='123',BillingState='Quebec',BillingCity='Montreal',BillingPostalCode='A0A 0A0',BillingCountry='Canada', Email__c = 'acc@testing.com',
                                  Phone = '1234567890', ShippingStreet='111',ShippingState='Quebec',ShippingCity='Montreal',ShippingPostalCode='A0A 0A0',ShippingCountry='Canada');
        insert testAccount;

        // Create a new Contact associated with the Account
        Contact testContact = new Contact(FirstName = 'John', LastName = 'Doe', AccountId = testAccount.Id, MobilePhone='1234567890');
        insert testContact;

        // Create a portal user
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'Client Community Login' LIMIT 1];

        User portalUser = new User(
            Username = 'portaluser@example.com',
            LastName='test',
            Email = 'portaluser@example.com',
            Alias = 'puser',
            ProfileId = portalProfile.Id,
            ContactId = testContact.Id,
            IsActive = true,
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert portalUser;

        // Test getUserInfo method
        User retrievedUser = UserProfileController.getUserInfo(portalUser.Id);
        
        System.assertEquals(portalUser.Id, retrievedUser.Id, 'The user ID should match');
        System.assertEquals(testContact.FirstName, retrievedUser.Contact.FirstName, 'The first name should match');
        System.assertEquals(testContact.LastName, retrievedUser.Contact.LastName, 'The last name should match');
        System.assertEquals(testAccount.Name, retrievedUser.Account.Name, 'The account name should match');
    }

    @isTest
    static void testSaveUserInfo() {
        // Create a new Account
        Account testAccount = new Account(Name = 'Test Account 2', 
                                          BillingStreet='123',BillingState='Quebec',BillingCity='Montreal',BillingPostalCode='A0A 0A0',BillingCountry='Canada', Email__c = 'acc@testing.com',
                                  Phone = '1234567890', ShippingStreet='111',ShippingState='Quebec',ShippingCity='Montreal',ShippingPostalCode='A0A 0A0',ShippingCountry='Canada');
        insert testAccount;

        // Create a new Contact associated with the Account
        Contact testContact = new Contact(FirstName = 'Jane', LastName = 'Doe', AccountId = testAccount.Id, MobilePhone='1234567890');
        insert testContact;

        // Create a portal user
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'Client Community Login' LIMIT 1];

        User portalUser = new User(
            Username = 'portaluser2@example.com',
            LastName='test',
            Email = 'portaluser2@example.com',
            Alias = 'puser2',
            ProfileId = portalProfile.Id,
            ContactId = testContact.Id,
            IsActive = true,
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert portalUser;

        // Update user, contact, and account
        
        testContact.Email = 'jane.doe@example.com';
        testAccount.Phone = '123-456-7890';

        // Save the changes
        Test.startTest();
        UserProfileController.saveUserInfo(portalUser, testContact, testAccount);
        Test.stopTest();

        
        testContact = [SELECT Email FROM Contact WHERE Id = :testContact.Id];
        testAccount = [SELECT Phone FROM Account WHERE Id = :testAccount.Id];

  
        System.assertEquals('jane.doe@example.com', testContact.Email, 'The contact email should be updated');
        System.assertEquals('123-456-7890', testAccount.Phone, 'The account phone should be updated');
    }
}