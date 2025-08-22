/**
 * Class Name: HexaSurveyPostSaleInvocable
 * Description: Invocable class for Flow and Process Builder to create 
 *              post-sale and post-installation surveys via Hexa API. 
 *              Uses asynchronous queueable jobs for callout processing.
 *
 * Supported Survey Types: POST_SALE, POST_INSTALLATION
 * Integration: Flow, Process Builder, Apex
 *
 * Author: Malek Brachemi
 * Date: 2025-05-09
 */
public with sharing class HexaSurveyPostSaleInvocable {
    
    /**
     * SurveyInputs
     * Wrapper class to receive survey parameters from Flow or Process Builder
      */
    public class SurveyInputs {
        @InvocableVariable(
            label='Survey Type' 
            description='Allowed values: POST_SALE, POST_INSTALLATION'
            required=true
        )
        public String surveyType;

        @InvocableVariable(label='Order ID' required=true)
        public String orderId;
    }

    /**
     * createHexaSurveyFromOrder
     *
     * Invocable method callable from Flow or Process Builder to initiate survey creation
     * Validates input parameters and enqueues asynchronous job for API processing
     * @param inputs List of SurveyInputs containing survey type and order information
     * @throws SurveyException if required parameters are missing or survey type is invalid
     */
    @InvocableMethod(label='Create Post Sales/Installation Hexa Survey' description='Creates surveys via Hexa API from Orders')
    public static void createHexaSurveyFromOrder(List<SurveyInputs> inputs) {
        // Validate input parameters and survey type
        if (inputs == null || inputs.isEmpty() || 
           (inputs[0].surveyType != 'POST_SALE' && inputs[0].surveyType != 'POST_INSTALLATION')) {
            throw new SurveyException('Input parameters are required and survey type must be POST_SALE or POST_INSTALLATION');
        }
        
        // Enqueue asynchronous job for API callout processing
        HexaSurveyPostSaleQueue surveyQueue = new HexaSurveyPostSaleQueue(inputs); 
        System.enqueueJob(surveyQueue);
    }
    
    /**
     * Custom exception class for survey-specific error handling
      */
    public class SurveyException extends Exception {}
}