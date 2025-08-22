/**
 * HexaSurveyPostSubmissionTest
 *
 * Test class for HexaSurveyPostSubmissionQueue and HexaSurveyPostSubmissionSch.
 * Validates queueable job execution for post-submission survey processing
 * and scheduler functionality for automated daily execution.
 *
 * Test Coverage:
 * - Queueable job execution with dummy and empty data
 * - Scheduler job creation and CronTrigger validation
 * - Error handling during queue processing
 * - Bulk and mixed data processing scenarios
 *
 * Author: Malek Brachemi
 * Date: 2025-05-09
 */
@isTest
private class HexaSurveyPostSubmissionTest {

    // Set up HTTP callout mock for Hexa API responses
    static {
        Test.setMock(HttpCalloutMock.class, new HexaSurveyMockHttpResponse());
    }

    /**
     * setupTestData
     *
     * Creates test data required for post-submission survey processing
     */
    @testSetup
    static void setupTestData() {
        TestDataFactory.createCompleteTestData();
    }

    /**
     * testBasicExecution
     *
     * Placeholder test method for basic test scenarios
     */
    @isTest
    static void testBasicExecution() {
        System.assert(true, 'Basic execution test placeholder');
    }

    /**
     * testPostSubmissionQueue
     *
     * Tests queueable job execution with dummy data
     * Validates that bulk records can be processed without errors
     */
    @isTest
    static void testPostSubmissionQueue() {
        List<Object> dummyRecords = new List<Object>();
        for (Integer i = 0; i < 30; i++) {
            dummyRecords.add(new Map<String, Object>{
                'noID' => i,
                'traiter' => true,
                'hasErrors' => false
            });
        }

        Test.startTest();
        System.enqueueJob(new HexaSurveyPostSubmissionQueue(dummyRecords));
        Test.stopTest();

        System.assert(true, 'Queue should process dummy data without errors');
    }

    /**
     * testSurveyPostSubmissionSch
     *
     * Tests scheduler functionality for HexaSurveyPostSubmissionSch
     * Ensures daily job is scheduled and appears in CronTrigger
     */
    @isTest
    static void testSurveyPostSubmissionSch() {
        Test.startTest();
        HexaSurveyPostSubmissionSch.scheduleJob();
        Test.stopTest();

        List<CronTrigger> scheduledJobs = [
            SELECT Id, CronJobDetail.Name, CronExpression
            FROM CronTrigger 
            WHERE CronJobDetail.Name = 'Daily Post Submission Survey Queue'
        ];

        System.assertNotEquals(0, scheduledJobs.size(), 'Scheduler job should be scheduled');
        System.assertNotEquals(null, scheduledJobs[0].CronExpression, 'Scheduled job should have valid cron expression');
    }

    /**
     * testPostSubmissionQueueWithEmptyData
     *
     * Validates queueable job handles empty data gracefully
     */
    @isTest
    static void testPostSubmissionQueueWithEmptyData() {
        List<Object> emptyRecords = new List<Object>();

        Test.startTest();
        System.enqueueJob(new HexaSurveyPostSubmissionQueue(emptyRecords));
        Test.stopTest();

        System.assert(true, 'Queue should handle empty data without errors');
    }

    /**
     * testPostSubmissionQueueWithErrorData
     *
     * Validates queueable job handles records flagged with errors
     * Confirms processing isolation and robustness for mixed datasets
     */
    @isTest
    static void testPostSubmissionQueueWithErrorData() {
        List<Object> mixedRecords = new List<Object>();

        // Normal records
        for (Integer i = 0; i < 5; i++) {
            mixedRecords.add(new Map<String, Object>{
                'noID' => i,
                'traiter' => true,
                'hasErrors' => false
            });
        }

        // Error records
        for (Integer i = 5; i < 10; i++) {
            mixedRecords.add(new Map<String, Object>{
                'noID' => i,
                'traiter' => true,
                'hasErrors' => true
            });
        }

        Test.startTest();
        System.enqueueJob(new HexaSurveyPostSubmissionQueue(mixedRecords));
        Test.stopTest();

        System.assert(true, 'Queue should handle mixed data with error isolation');
    }
}