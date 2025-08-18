
public without sharing class ShopifyRefund {
        
    public class PaymentInputs {
        @InvocableVariable(required=true)
        public String orderId;
        
        @InvocableVariable(required=true)
        public Decimal amount;
        
    }

    @InvocableMethod(label='Process Shopify Refund' 
    description='Process a Shopify Refund for the given Order')
    public static List<String> generatePaymentRefund(List<PaymentInputs> inputs) {
        if(inputs == null || inputs.isEmpty()) {
            throw new PaymentException('Input parameters are required');
        }
        
        PaymentInputs input = inputs[0];
        Order orderRecord = [SELECT Id, Account.BillingStreet, Account.BillingCity, Account.BillingState,TotalAmount,GST__c,QST__c,HST__c, 
        Account.BillingPostalCode, Account.BillingCountry, Account.Sage_ID__c, Account.Email__c,Account.Language__c,
        Sage_ID__c, BillToContact.FirstName, BillToContact.LastName,Account.Cellphone__c,Account.Phone,
        BillToContact.Email, BillToContact.Phone
        FROM Order WHERE Id = :input.orderId];
        
        System.debug('order : ' + orderRecord );
       
        Decimal refundAmount = input.amount;
 
        String paymentLink = processShopifyRefund(orderRecord, refundAmount);
        return new List<String>{paymentLink};
    }

    public static String processShopifyRefund(Order orderRecord , Decimal refundAmount) {
        try {

             ShopifyWrapper wrapper = new ShopifyWrapper();
            wrapper.order = new ShopifyWrapper.OrderDetails();
            
            wrapper.order.transaction_type = 'Refund';
            wrapper.order.payment_type = null;
            wrapper.order.salesforce_id = orderRecord.Id;
            wrapper.order.salesforce_object = 'Order';
            wrapper.order.sage_customer_id = orderRecord.Account.Sage_ID__c; 
            wrapper.order.sage_order_id = orderRecord.Sage_ID__c; 
            wrapper.order.customer_email =  orderRecord.Account?.Email__c;
            wrapper.order.first_name =  null;
            wrapper.order.last_name =  null;
            wrapper.order.billing_street = null;
            wrapper.order.billing_city = null;
            wrapper.order.billing_postalcode = null;
            wrapper.order.billing_state = null;
            wrapper.order.billing_country = null;
            wrapper.order.phone = null;    
            wrapper.order.cancel_at = null;
            wrapper.order.send_email = 'FALSE';
            wrapper.order.success_status = null;
            wrapper.order.total_amount = String.valueOf(refundAmount)  ;
            wrapper.order.gst = '0';
            wrapper.order.qst = '0';
            wrapper.order.hst = '0';

 
            
            System.debug(' Body : ' +JSON.serialize(wrapper) );
            Shopify_Integration__mdt apiSettings = new Shopify_Integration__mdt();
            Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

            String apiSettingName = isSandbox ? 'Refund_Dev' : 'Refund_Prod';

            apiSettings = [SELECT DeveloperName, API_Key__c, Endpoint__c, Method_Type__c 
                            FROM Shopify_Integration__mdt 
                            WHERE DeveloperName = :apiSettingName
                            LIMIT 1];
          

            String endpoint =  apiSettings.Endpoint__c;
            String methodType =  apiSettings.Method_Type__c;
            String apiKey =  apiSettings.API_Key__c;

            // Make HTTP callout
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod(methodType);
            request.setHeader('Accept', 'application/json');
            request.setHeader('x-api-key', apiKey);
            request.setHeader('Content-Type', 'application/json');
            request.setBody(JSON.serialize(wrapper));
            
            

            HttpResponse response;
            if (Test.isRunningTest()) {
                response = new HttpResponse();
                response.setStatusCode(200);
                response.setBody('{"url": "https://testshop.myshopify.com/payment/12345"}');
            } else {
                response = http.send(request);
            }

            // Handle response
            if (response.getStatusCode() >= 200 && response.getStatusCode() < 300 ) {
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                String paymentUrl = (String)responseMap.get('url');
                String pendingRequest = 'TEST';

                update orderRecord;
 
                    return paymentUrl;
         
                    
            } else {
                return ('Error calling payment service. Status: ' + 
                                           response.getStatusCode() + ' Body: ' + response.getBody());
            }
            
        } catch(Exception e) {
            throw new PaymentException('Error generating payment URL: ' + e.getMessage());
        }

     }

    
    
    public class PaymentException extends Exception {}
}