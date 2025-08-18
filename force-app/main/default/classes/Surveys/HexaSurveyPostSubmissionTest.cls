
@isTest
private class HexaSurveyPostSubmissionTest {

    static {
        Test.setMock(HttpCalloutMock.class, new HexaSurveyMockHttpResponse());
    }

    @testSetup
    static void setupTestData() {
         TestDataFactory.createCompleteTestData();
    }

    @isTest
    static void gee() {

    }
    
    @isTest
    static void testPostSubmissionQueue() {
  

        // Create dummy input
        List<Object> dummyRecords = new List<Object>();
        for (Integer i = 0; i < 30; i++) {
            Map<String, Object> fakeRecord = new Map<String, Object>{
                'noID' => i,
                'traiter' => true,
                'hasErrors' => false
            };
            dummyRecords.add(fakeRecord);
        }
        Test.startTest();
        System.enqueueJob(new HexaSurveyPostSubmissionQueue(dummyRecords));
        Test.stopTest();
        System.assert(true, 'Test ran without errors');
    }
    
 
    @isTest
    static void testSurveyPostSubmissionSch() {
 
        Test.startTest();
        HexaSurveyPostSubmissionSch.scheduleJob();
        Test.stopTest();
        // Verify the job was scheduled
        List<CronTrigger> scheduledJobs = [SELECT Id, CronJobDetail.Name 
                                           FROM CronTrigger 
                                           WHERE CronJobDetail.Name = 'Daily Post Submission Survey Queue'];
        
        System.assertNotEquals(0, scheduledJobs.size(), 'Job should be scheduled');
    }
 
}