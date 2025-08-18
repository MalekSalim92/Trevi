
public class HexaSurveyPostDeliverySch implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new HexaSurveyPostDeliveryBatch());
    }

    public static void scheduleJob() {
        try {
        
        Hexa_Surveys_Cron_Schedule__mdt	 config = HexaSurveyUtils.getScheduleDetails('DeliverySurvey');
        String cronExpression = config?.CronExpression__c ?? '0 0 18 * * ?';
            System.schedule('Daily Post Delivery Survey Batch', cronExpression, new HexaSurveyPostDeliverySch());
        } catch (Exception e) {
            System.debug('Could not schedule job: ' + e.getMessage());
        }
    }
}