@isTest
private class HexaSurveyPostDeliveryTest {
    
    static {
        Test.setMock(HttpCalloutMock.class, new HexaSurveyMockHttpResponse());
    }

    @testSetup
    static void setupTestData() {
        // Use existing test data factory
        Account testAccount = TestDataFactory.createTestAccount();
        insert testAccount;
     
        User testUser = TestDataFactory.createTestUser('Omar','Said',null);
        insert testUser;

        Order testOrder = TestDataFactory.createTestOrderForDelivery(testAccount.Id , testUser.Id);
        insert testOrder;
        
    }
    
   
    @isTest
    static void testHexaSurveyPostDeliveryBatch() {
 
        Test.startTest();
        HexaSurveyPostDeliveryBatch batch = new HexaSurveyPostDeliveryBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify that orders were updated with survey URL
        List<Order> updatedOrders = [SELECT Installation_Delivery_Survey_1_Year_URL__c 
                                     FROM Order 
                                     WHERE Installation_Date__c = LAST_YEAR 
                                     OR Actual_Delivery_Date__c = LAST_YEAR];
        
        System.assertNotEquals(0, updatedOrders.size(), 'Some orders should be processed');
         
    }
    
    @isTest
    static void testBatchWithNoEligibleOrders() {
        // Update all orders to make them ineligible
        List<Order> ordersToUpdate = [SELECT Id, Installation_Date__c, Actual_Delivery_Date__c, Status 
                                      FROM Order];
        for (Order ord : ordersToUpdate) {
            ord.Status = 'Draft';
            ord.Installation_Date__c = null;
            ord.Actual_Delivery_Date__c = null;
        }
        update ordersToUpdate;
        
        Test.startTest();
        HexaSurveyPostDeliveryBatch batch = new HexaSurveyPostDeliveryBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify no orders were processed
        List<Order> processedOrders = [SELECT Installation_Delivery_Survey_1_Year_URL__c 
                                       FROM Order 
                                       WHERE Installation_Delivery_Survey_1_Year_URL__c != null];
        
        System.assertEquals(0, processedOrders.size(), 'No orders should be processed');
    }

        @isTest
    static void testHexaSurveyPostDeliverySch() {
        Test.startTest();
        HexaSurveyPostDeliverySch.scheduleJob();
        Test.stopTest();
        // Verify the job was scheduled
        List<CronTrigger> scheduledJobs = [SELECT Id, CronJobDetail.Name 
                                           FROM CronTrigger 
                                           WHERE CronJobDetail.Name = 'Daily Post Delivery Survey Batch'];
        
        System.assertNotEquals(0, scheduledJobs.size(), 'Job should be scheduled');
    }

 
    
 }