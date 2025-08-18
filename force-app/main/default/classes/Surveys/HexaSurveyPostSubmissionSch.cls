public class HexaSurveyPostSubmissionSch implements Schedulable {
    public void execute(SchedulableContext sc) {
        Hexa_Surveys_Cron_Schedule__mdt	 config = HexaSurveyUtils.getScheduleDetails('DeliverySurvey');
        Integer numDays = (Integer) config?.numDays__c ?? 1;
        Datetime currentDate = Datetime.now().addDays(-numDays);  
        String formattedDateTime = currentDate.format('yyyy-MM-dd\'T\'HH:mm:ss');
        System.debug(formattedDateTime);
        
        processCallout(formattedDateTime);
    }
    @future(callout=true)
    public static void processCallout(String formattedDateTime){
        try {
            // Obtain login code
            String bearerToken = HexaSurveyService.obtainLoginCode();
            
            // Fetch Sondage records
            List<Object> sondageRecords = HexaSurveyService.getSondageRecords(bearerToken, formattedDateTime);
            System.debug('sondageRecords ' + sondageRecords);

            // Process records if any exist
            if (!sondageRecords.isEmpty()) {
                System.debug('Received ' + sondageRecords.size() + ' Sondage records');
                HexaSurveyPostSubmissionQueue queueableJob = new HexaSurveyPostSubmissionQueue(sondageRecords);
                System.enqueueJob(queueableJob);
            }
        } catch (Exception e) {
            System.debug('Survey Integration Error: ' + e.getMessage());
        }
    }
        
    public static void scheduleJob() {
        try {
            Hexa_Surveys_Cron_Schedule__mdt	 config = HexaSurveyUtils.getScheduleDetails('DeliverySurvey');

        String cronExpression = config?.CronExpression__c ?? '0 0 18 * * ?';
            System.schedule('Daily Post Submission Survey Queue', cronExpression, new HexaSurveyPostSubmissionSch());
        } catch (Exception e) {
            System.debug('Could not schedule job: ' + e.getMessage());
        }
    }

}