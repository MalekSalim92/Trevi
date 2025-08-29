@isTest
private class UserProfileControllerTest {
    
    @TestSetup
    static void setup() {
        // Create a test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = '123',
            BillingState = 'Quebec',
            BillingCity = 'Montreal',
            BillingPostalCode = 'A0A 0A0',
            BillingCountry = 'Canada',
            Email__c = 'acc@testing.com',
            Phone = '1234567890',
            ShippingStreet = '111',
            ShippingState = 'Quebec',
            ShippingCity = 'Montreal',
            ShippingPostalCode = 'A0A 0A0',
            ShippingCountry = 'Canada'
        );
        insert testAccount;

        // Create a test Contact
        Contact testContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            Email = 'portaluser_' + String.valueOf(Math.random()).substring(2, 9) + '@example.com',
            AccountId = testAccount.Id,
            MobilePhone = '1234567890'
        );
        insert testContact;


    }

    @isTest
    static void testSaveUserInfo() {
        // Retrieve test data
        User testUser = [SELECT Id, ContactId, AccountId, LanguageLocaleKey FROM User LIMIT 1];
        Contact testContact = [SELECT Id, FirstName, LastName, Email, MobilePhone, AccountId FROM Contact LIMIT 1];
        Account testAccount = [SELECT Id, Name, Phone, Email__c FROM Account LIMIT 1];

        // Update values
        testUser.LanguageLocaleKey = 'fr';
        testContact.Email = 'jane.doe@example.com';
        testAccount.Phone = '987-654-3210';

        // Test the method
        Test.startTest();
        UserProfileController.saveUserInfo(testUser, testContact, testAccount);
        Test.stopTest();

        // Verify results
        User updatedUser = [SELECT LanguageLocaleKey FROM User WHERE Id = :testUser.Id];
        Contact updatedContact = [SELECT Email FROM Contact WHERE Id = :testContact.Id];
        Account updatedAccount = [SELECT Phone FROM Account WHERE Id = :testAccount.Id];

        System.assertEquals('fr', updatedUser.LanguageLocaleKey, 'User language should be updated to French');
        System.assertEquals('jane.doe@example.com', updatedContact.Email, 'Contact email should be updated');
        System.assertEquals('987-654-3210', updatedAccount.Phone, 'Account phone should be updated');
    }

    @isTest
    static void testGetUserInfo() {
        User testUser = [SELECT Id, ContactId, AccountId FROM User LIMIT 1];

        Test.startTest();
        User retrievedUser = UserProfileController.getUserInfo(testUser.Id);
        Test.stopTest();

        System.assertEquals(testUser.Id, retrievedUser.Id, 'Retrieved user ID should match');
    }
}