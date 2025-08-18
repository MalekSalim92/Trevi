public with sharing class UserRegistrationController {
    @AuraEnabled
    public static void publishUserRegistrationEvent(String registrationData) {
        // Deserialize the registration data
        Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(registrationData);
        
        // Create and publish the platform event
        User_Registration_Event__e event = new User_Registration_Event__e(
            // Account fields
            Account_Name__c = (String)dataMap.get('accountName'),
            Account_Description__c = (String)dataMap.get('accountDescription'),
            Account_Type__c = (String)dataMap.get('accountType'),
            Account_Language__c = (String)dataMap.get('accountLanguage'),
            Account_source__c = (String)dataMap.get('accountSource'),
            Communication_Preference__c = (String)dataMap.get('languagePreference'),

            // Billing address
            Billing_Street__c = (String)dataMap.get('billingStreet'),
            Billing_City__c = (String)dataMap.get('billingCity'),
            Billing_State__c = (String)dataMap.get('billingState'),
            Billing_Postal_Code__c = (String)dataMap.get('billingPostalCode'),
            Billing_Country__c = (String)dataMap.get('billingCountry'), 
            
            // Shipping address
            Shipping_Street__c = (String)dataMap.get('shippingStreet'),
            Shipping_City__c = (String)dataMap.get('shippingCity'),
            Shipping_State__c = (String)dataMap.get('shippingState'),
            Shipping_Postal_Code__c = (String)dataMap.get('shippingPostalCode'),
            Shipping_Country__c = (String)dataMap.get('shippingCountry'),
                   
            // Contact fields
            First_Name__c = (String)dataMap.get('firstName'),
            Middle_Name__c = (String)dataMap.get('middleName'),
            Last_Name__c = (String)dataMap.get('lastName'),
            Birth_Date__c = dataMap.get('birthDate') != null ? Date.valueOf((String)dataMap.get('birthDate')) : null,
            Email__c = (String)dataMap.get('email'),
            Mobile_Phone__c = dataMap.get('mobilePhone') != null ? (String)dataMap.get('mobilePhone') : null,
            Home_Phone__c = dataMap.get('homePhone') != null ? (String)dataMap.get('homePhone') : null,
            Do_not_call__c = Boolean.valueOf(dataMap.get('doNotCall')),
            Email_opt_out__c = Boolean.valueOf(dataMap.get('emailOptOut'))
        );
        
        // Publish the event
        Database.SaveResult result = EventBus.publish(event);
        
        // Check for errors
        if (!result.isSuccess()) {
            for (Database.Error error : result.getErrors()) {
                System.debug('Error publishing event: ' + error.getStatusCode() + ' - ' + error.getMessage());
            }
            throw new AuraHandledException('Failed to publish registration event');
        }
    }


    @AuraEnabled(cacheable=true)
    public static URL_Configuration__mdt getURLConfiguration() {

        URL_Configuration__mdt config = [
            SELECT Id, DeveloperName, Redirect_URL__c
            FROM URL_Configuration__mdt 
            WHERE DeveloperName = 'Trevi_website'
            LIMIT 1
        ];
        
        return config;
    }

}