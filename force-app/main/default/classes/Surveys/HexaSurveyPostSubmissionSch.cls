/**
 * HexaSurveyPostSubmissionSch
 *
 * Schedulable class responsible for daily retrieval and processing of submitted
 * survey records from the Hexa API. Fetches survey submissions from a configurable
 * number of days ago, obtains authentication token, and processes records through
 * queueable jobs for bulk handling.
 *
 * Default Schedule: Daily at 18:00 (6 PM) - '0 0 18 * * ?'
 * Configurable via: Hexa_Surveys_Cron_Schedule__mdt custom metadata
 * Processing: Asynchronous via HexaSurveyPostSubmissionQueue
 *
 * Author: Malek Brachemi
 * Date: 2025-05-09
 */
public class HexaSurveyPostSubmissionSch implements Schedulable {
    
    /**
     * execute
     *
     * Main execution method called by Salesforce scheduler
     * Retrieves configuration, calculates target date, and initiates async callout
     * @param sc SchedulableContext provided by Salesforce platform
     */
    public void execute(SchedulableContext sc) {
        // Retrieve schedule configuration from custom metadata
        Hexa_Surveys_Cron_Schedule__mdt config = HexaSurveyUtils.getScheduleDetails('DeliverySurvey');
        
        // Get number of days to look back (default: 1 day ago)
        Integer numDays = (Integer) config?.numDays__c ?? 1;
        
        // Calculate target date for survey submission retrieval
        Datetime currentDate = Datetime.now().addDays(-numDays);  
        String formattedDateTime = currentDate.format('yyyy-MM-dd\'T\'HH:mm:ss');
        
        System.debug('HexaSurveyPostSubmissionSch: Processing submissions from ' + formattedDateTime);
        
        // Initiate async callout to fetch and process survey records
        processCallout(formattedDateTime);
    }
    
    /**
     * processCallout
     *
     * Future method to perform API authentication and survey record retrieval
     * Handles OAuth token acquisition, fetches survey submissions, and enqueues
     * processing job if records are found
     * @param formattedDateTime Target date/time for survey submission retrieval in ISO format
     */
    @future(callout=true)
    public static void processCallout(String formattedDateTime){
        try {
            System.debug('HexaSurveyPostSubmissionSch: Starting callout process for ' + formattedDateTime);
            
            // Obtain authentication token from Hexa API
            String bearerToken = HexaSurveyService.obtainLoginCode();
            
            if (String.isBlank(bearerToken)) {
                System.debug('HexaSurveyPostSubmissionSch: Failed to obtain bearer token');
                return;
            }
            
            // Fetch survey submission records from Hexa API
            List<Object> sondageRecords = HexaSurveyService.getSondageRecords(bearerToken, formattedDateTime);
            System.debug('HexaSurveyPostSubmissionSch: Retrieved ' + sondageRecords.size() + ' sondage records');

            // Process records if any submissions exist
            if (!sondageRecords.isEmpty()) {
                System.debug('HexaSurveyPostSubmissionSch: Enqueuing ' + sondageRecords.size() + ' records for processing');
                
                // Enqueue queueable job for bulk survey processing
                HexaSurveyPostSubmissionQueue queueableJob = new HexaSurveyPostSubmissionQueue(sondageRecords);
                System.enqueueJob(queueableJob);
            } else {
                System.debug('HexaSurveyPostSubmissionSch: No survey submissions found for ' + formattedDateTime);
            }
            
        } catch (CalloutException ce) {
            // Handle API-specific errors
            System.debug('HexaSurveyPostSubmissionSch: API callout error - ' + ce.getMessage());
            
        } catch (Exception e) {
            // Handle any other unexpected errors during processing
            System.debug('HexaSurveyPostSubmissionSch: Survey Integration Error - ' + e.getMessage());
        }
    }
    
    /**
     * scheduleJob
     *
     * Static method to schedule the daily post-submission survey processing job
     * Retrieves cron expression from custom metadata with fallback to default schedule
     * Includes error handling to prevent scheduling failures during deployment
     */
    public static void scheduleJob() {
        try {
            // Retrieve schedule configuration from custom metadata
            Hexa_Surveys_Cron_Schedule__mdt config = HexaSurveyUtils.getScheduleDetails('DeliverySurvey');

            // Use configured cron expression or default to 6 PM daily
            String cronExpression = config?.CronExpression__c ?? '0 0 18 * * ?';
            
            // Schedule the job with descriptive name
            System.schedule('Daily Post Submission Survey Queue', cronExpression, new HexaSurveyPostSubmissionSch());
            
            System.debug('HexaSurveyPostSubmissionSch: Successfully scheduled with expression - ' + cronExpression);
            
        } catch (Exception e) {
            // Log scheduling errors but don't throw to prevent deployment issues
            System.debug('HexaSurveyPostSubmissionSch: Could not schedule job - ' + e.getMessage());
        }
    }
}