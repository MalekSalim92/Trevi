/**
 * Class Name: HexaSurveyPostDeliverySch
 * Description: Schedulable class that runs HexaSurveyPostDeliveryBatch daily.
 *              Defaults to 6:00 PM if no custom metadata configuration is found.
 *
 * Default Schedule: Daily at 18:00 (cron: '0 0 18 * * ?')
 * Configurable via: Hexa_Surveys_Cron_Schedule__mdt
 * 
 * Usage: Call scheduleJob() to configure automated execution.
 *
 * Author: Malek Brachemi
 * Date: 2025-05-09
 */
public class HexaSurveyPostDeliverySch implements Schedulable {
    
    /**
     * Trigger the batch job when the scheduler runs.
     */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new HexaSurveyPostDeliveryBatch());
    }

    /**
     * Schedule the daily job using metadata or fallback to 6 PM.
     */
    public static void scheduleJob() {
        try {
            Hexa_Surveys_Cron_Schedule__mdt config = HexaSurveyUtils.getScheduleDetails('DeliverySurvey');
            String cronExpression = config?.CronExpression__c ?? '0 0 18 * * ?';
            
            System.schedule('Daily Post Delivery Survey Batch', cronExpression, new HexaSurveyPostDeliverySch());
            System.debug('Scheduled Post Delivery Survey Batch with expression: ' + cronExpression);
            
        } catch (Exception e) {
            System.debug('Could not schedule job: ' + e.getMessage());
        }
    }
}