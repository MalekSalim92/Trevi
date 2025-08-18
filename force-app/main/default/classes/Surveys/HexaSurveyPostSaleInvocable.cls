public with sharing class HexaSurveyPostSaleInvocable {
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


    @InvocableMethod(label='Create Post Sales/Installation Hexa Survey' description='Creates surveys via Hexa API from Orders')
    public static void createHexaSurveyFromOrder(List<SurveyInputs> inputs) {
        if (inputs == null || inputs.isEmpty() || (inputs.surveyType <> 'POST_SALE' && inputs.surveyType <> 'POST_INSTALLATION') ) {
            throw new SurveyException('Input parameters are required');
        }
        HexaSurveyPostSaleQueue surveyQueue = new HexaSurveyPostSaleQueue(inputs); 
        System.enqueueJob(surveyQueue);
    }
    
 
 

public class SurveyException extends Exception {}

}