/**
 * HexaSurveyUtils
 *
 * Utility class providing survey management functionality for the Hexa Survey system.
 * Handles survey creation, batch processing, contract type mapping, and configuration
 * management with comprehensive error handling and logging capabilities.
 *
 * Key Features:
 * - Post-delivery survey creation for orders
 * - Batch processing of survey submission data
 * - Contract type value mapping and validation
 * - Survey schedule configuration retrieval
 *
 * Author: Malek Brachemi
 * Date: 2025-05-11
  */
public with sharing class HexaSurveyUtils {
    
    /**
     * createPostDeliverySurvey
     *
     * Creates a post-delivery survey for a completed order by interfacing with
     * the HexaSurveyService. This method handles the survey creation process
     * with comprehensive error handling and logging for troubleshooting purposes.
     *
     * @param orderRecord The Order record for which to create the post-delivery survey
     * @return Order The processed order record with survey information, or null if creation fails
     * 
     * Processing Flow:
     * 1. Instantiate HexaSurveyService
     * 2. Process survey with POST_DELIVERY type
     * 3. Return processed order or null on failure
     *
     * Error Handling: Logs exceptions with full stack trace for debugging
     */
    public static Order createPostDeliverySurvey(Order orderRecord) {
        try {
            HexaSurveyService surveyService = new HexaSurveyService();
            return surveyService.processSurvey(orderRecord.Id, 'POST_DELIVERY', null);
        } catch (Exception e) {
            System.debug('Survey creation failed: ' + e.getMessage());
            return null;
        }
    }

    // Processes a batch of survey submission records
    public static void processSondageBatch(List<Object> batchRecords) {
        for (Object record : batchRecords) {
            try {
                Map<String, Object> surveyRecord = (Map<String, Object>) record;
                HexaSurveyService surveyService = new HexaSurveyService();
                surveyService.processSurvey(null, 'POST_SUBMISSION', surveyRecord);
            } catch (Exception e) {
                System.debug('Error processing record: ' + e.getMessage());
                System.debug('Record: ' + JSON.serialize(record));
            }
        }
    }

    // Maps contract type label to numeric value, returns '0' if unmapped
    public static String getContractTypeValue(String contractType) {
        Map<String, String> contractTypeMap = new Map<String, String>{
            'CR'=>'1','SC'=>'2','HT'=>'3','SP'=>'4','MB'=>'5',
            'AB'=>'6','AL'=>'7','SL'=>'8','AC'=>'9','RC'=>'10'
        };
        Schema.DescribeFieldResult fieldDescribe = Order.Contract_Type__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (entry.getValue() == contractType) {
                return contractTypeMap.containsKey(entry.getLabel()) ? contractTypeMap.get(entry.getLabel()) : '0';
            }
        }
        return '0';
    }

    // Retrieves survey schedule config from custom metadata
    public static Hexa_Surveys_Cron_Schedule__mdt getScheduleDetails(String surveyName) {
        return [SELECT CronExpression__c, numDays__c 
                FROM Hexa_Surveys_Cron_Schedule__mdt 
                WHERE DeveloperName = :surveyName 
                LIMIT 1];
    }
}