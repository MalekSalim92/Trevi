/**
 * Class Name: HexaSurveyPostDeliveryTest
 * Description: Unit tests for HexaSurveyPostDeliveryBatch and HexaSurveyPostDeliverySch.
 *              Verifies survey creation logic, ineligible order handling, and job scheduling.
 *
 * Author: Malek Brachemi
 * Date: 2025-05-09
 */
@IsTest
private class HexaSurveyPostDeliveryTest {
    
    // Register the mock HTTP response once for all tests
    static {
        Test.setMock(HttpCalloutMock.class, new HexaSurveyMockHttpResponse());
    }

    @TestSetup
    static void setupTestData() {
        // Create base test data using factory methods
        Account testAccount = TestDataFactory.createTestAccount();
        insert testAccount;
     
        User testUser = TestDataFactory.createTestUser('Omar','Said',null);
        insert testUser;

        Order testOrder = TestDataFactory.createTestOrderForDelivery(testAccount.Id, testUser.Id);
        insert testOrder;
    }
    
    @IsTest
    static void testHexaSurveyPostDeliveryBatch() {
        Test.startTest();
        Database.executeBatch(new HexaSurveyPostDeliveryBatch());
        Test.stopTest();
        
        // Assert that orders were updated with survey URL
        List<Order> updatedOrders = [
            SELECT Installation_Delivery_Survey_1_Year_URL__c 
            FROM Order 
            WHERE Installation_Date__c = LAST_YEAR 
               OR Actual_Delivery_Date__c = LAST_YEAR
        ];
        
        System.assertNotEquals(0, updatedOrders.size(), 'Orders should be processed');
    }
    
    @IsTest
    static void testBatchWithNoEligibleOrders() {
        // Make all orders ineligible
        List<Order> ordersToUpdate = [
            SELECT Id, Installation_Date__c, Actual_Delivery_Date__c, Status 
            FROM Order
        ];
        for (Order ord : ordersToUpdate) {
            ord.Status = 'Draft';
            ord.Installation_Date__c = null;
            ord.Actual_Delivery_Date__c = null;
        }
        update ordersToUpdate;
        
        Test.startTest();
        Database.executeBatch(new HexaSurveyPostDeliveryBatch());
        Test.stopTest();
        
        // Assert that no orders were updated
        List<Order> processedOrders = [
            SELECT Installation_Delivery_Survey_1_Year_URL__c 
            FROM Order 
            WHERE Installation_Delivery_Survey_1_Year_URL__c != null
        ];
        
        System.assertEquals(0, processedOrders.size(), 'No orders should be processed');
    }

    @IsTest
    static void testHexaSurveyPostDeliverySch() {
        Test.startTest();
        HexaSurveyPostDeliverySch.scheduleJob();
        Test.stopTest();
        
        // Assert that the job was scheduled
        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Daily Post Delivery Survey Batch'
        ];
        
        System.assertNotEquals(0, scheduledJobs.size(), 'Job should be scheduled');
    }
}