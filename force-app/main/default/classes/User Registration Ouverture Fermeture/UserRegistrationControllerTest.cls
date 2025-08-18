@isTest
public class UserRegistrationControllerTest {
   
    @testSetup
    static void setupTestData() {


        UserRole role = TestDataFactory.createTestUserRole();
        insert role;
        System.debug(role);

        User testUser = TestDataFactory.createTestUser('Data','Migration User',role.Id);
        insert testUser;
        System.debug(testUser);


    }


    @isTest
    public static void testPublishUserRegistrationEvent() {
        Map<String, Object> testData = TestDataFactory.createRegistrationData();
        String jsonData = JSON.serialize(testData);
        Postal_Code__c testPostalCode = TestDataFactory.createPostalCode('000 000');
        insert testPostalCode;

        test.StartTest(); 
        UserRegistrationController.publishUserRegistrationEvent(jsonData);
        test.StopTest(); 

    }

   @isTest
    public static void testGetURLConfiguration() {

        test.StartTest(); 
        UserRegistrationController.getURLConfiguration();
        test.StopTest(); 

    }
}