public with sharing class HexaSurveyUtils {
 
    //! POST DELIVERY 


    public static Order createPostDeliverySurvey(Order orderRecord) {
        try {
            HexaSurveyService surveyService = new HexaSurveyService();
            Order o = surveyService.processSurvey(orderRecord.Id, 'POST_DELIVERY',null);
            return o;
        } catch (Exception e) {
            // Log any exceptions
            System.debug('Survey Creation Exception: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            return null;
        }
    }

    //todo POST SUBMISSION 
    
        public static void processSondageBatch(List<Object> batchRecords) {
            for (Object record : batchRecords) {
                try {
                    Map<String, Object> surveyRecord = (Map<String, Object>) record;
                    HexaSurveyService surveyService = new HexaSurveyService();
                    Order o = surveyService.processSurvey(null, 'POST_SUBMISSION' ,surveyRecord);
    
                } catch (Exception e) {
                    System.debug('Error processing record: ' + e.getMessage());
                    System.debug('Record details: ' + JSON.serialize(record));
                }
            }
        }
    
        //* General 

        public static String getContractTypeValue(String contractType) {

            Map<String, String> contractTypeMap = new Map<String, String>{
                'CR' => '1',
                'SC' => '2',
                'HT' => '3',
                'SP' => '4',
                'MB' => '5',
                'AB' => '6',
                'AL' => '7',
                'SL' => '8',
                'AC' => '9',
                'RC' => '10'
            };
        
            // Get the picklist label
            Schema.DescribeFieldResult fieldDescribe = Order.Contract_Type__c.getDescribe();
            
            for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                if (entry.getValue() == contractType) {
                    // Use containsKey and get with a default value
                    return contractTypeMap.containsKey(entry.getLabel()) 
                        ? contractTypeMap.get(entry.getLabel()) 
                        : '0';
                }
            }
            
            return '0';
        }


        public static Hexa_Surveys_Cron_Schedule__mdt getScheduleDetails(String surveyName){
            return [SELECT CronExpression__c,numDays__c FROM Hexa_Surveys_Cron_Schedule__mdt WHERE DeveloperName = :surveyName LIMIT 1];
            }
                
    public class SageSurveyException extends Exception {}
    

    
    
    
}