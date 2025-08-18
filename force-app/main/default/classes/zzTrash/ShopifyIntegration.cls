public without sharing class ShopifyIntegration {
    
    public class PaymentInputs {
        @InvocableVariable(required=true)
        public String orderId;

        @InvocableVariable(required=true description='Select payment method: "Online" or "In store" or "None')
        public String paymentMethod;
        
        @InvocableVariable
        public String contactId;
        
        @InvocableVariable
        public String woli;
        
        @InvocableVariable
        public String paymentType;
    }

     

    // Updated invocable method with better return type
    @InvocableMethod(label='Generate Shopify Payment URL' 
    description='Generates a Shopify payment URL for the given Order')
    public static List<String> generatePaymentLink(List<PaymentInputs> inputs) {
        if(inputs == null || inputs.isEmpty()) {
            throw new CustomExceptions.PaymentException('Input parameters are required');
        }
        
        List<String> results = new List<String>();
        for (PaymentInputs input : inputs) {
            try {
                // Validate order exists
                Order ord = [SELECT Id, Name FROM Order WHERE Id = :input.orderId LIMIT 1];
                System.debug('Order Id : ' + input.orderId);
                System.debug('Order : ' + ord); 
                
                // Start async processing
                String apiResults = processPaymentAsync(input.orderId, input.paymentMethod, input.contactId, input.woli, input.paymentType);
                
                // Return pending status
                results.add(apiResults);
                
            } catch (QueryException qe) {
             } catch (Exception ex) {
                System.debug('Error in generatePaymentLink: ' + ex.getMessage());
             }
        }
        return results;
    }        
    
    // Async processing method with better error handling
   // @future(callout=true)
    public static String processPaymentAsync(String orderId, String paymentMethod, String contactId, String woliId, String paymentType) {
        String paymentUrl = null;
        try {
            // Query order record
            Order orderRecord = getOrderDetails(orderId);
            System.debug('order Record : ' + orderRecord);
            
            Contact con = null;
            if (String.isNotBlank(contactId)) {
                List<Contact> contacts = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE Id = :contactId LIMIT 1];
                if (!contacts.isEmpty()) {
                    con = contacts[0];
                } 
            }
            System.debug('con : ' + con);
            
            // Get amounts
            PaymentAmounts amounts = getPaymentAmounts(orderRecord, woliId);
            
            System.debug('woli : ' + amounts.woli);
            System.debug('totalAmount : ' + amounts.totalAmount);
            System.debug('paymentType: ' + paymentType);
            System.debug('payment method : ' + paymentMethod);

            // Process the payment and get the response
            ShopifyPaymentService.ShopifyPaymentInput input = ShopifyPaymentService.buildShopifyInput(
                orderRecord, amounts.woli, paymentMethod, con, amounts.totalAmount, 
                amounts.gst, amounts.qst, amounts.hst, paymentType, 'Payment'
            );

            Map<String, Object> result = ShopifyPaymentService.processShopifyPayment(input);
            
            // Extract response data
             paymentUrl = (String)result.get('url');
            String refundStatus = (String)result.get('refund_status');
            String requestPending = (String)result.get('has_payment_request_pending');
               
            // responses.add(requestPending);

          
            
            System.debug('Payment processing completed successfully for Order: ' + orderId);
            
        } catch(Exception e) {
            // Log the error with more context
            System.debug('Error in async payment processing for Order ' + orderId + ': ' + e.getMessage() + '\n' + e.getStackTraceString());
            
            // Consider creating an error log record or sending notification
            // You might want to update the Order with error status
            try {
                Order errorOrder = new Order(Id = orderId);
                // If you have an error field: errorOrder.Payment_Error__c = e.getMessage();
                // update errorOrder;
            } catch(Exception updateEx) {
                System.debug('Failed to update order with error: ' + updateEx.getMessage());
            }
        }
        return paymentUrl;
    }

    // Helper class for payment amounts
    private class PaymentAmounts {
        public Decimal totalAmount;
        public Decimal gst;
        public Decimal qst; 
        public Decimal hst;
        public WorkOrderLineItem woli;
    }

    // Helper method to get payment amounts
    private static PaymentAmounts getPaymentAmounts(Order orderRecord, String woliId) {
        PaymentAmounts amounts = new PaymentAmounts();
        
        if(String.isNotBlank(woliId)) {
            List<WorkOrderLineItem> wolis = [
                SELECT Id, Outstanding_Amount_After_Tax__c, GST__c, QST__c, HST__c 
                FROM WorkOrderLineItem 
                WHERE Id = :woliId 
                LIMIT 1
            ];
            
            if (!wolis.isEmpty()) {
                amounts.woli = wolis[0];
                amounts.totalAmount = math.abs(amounts.woli.Outstanding_Amount_After_Tax__c);
                amounts.gst = amounts.woli.GST__c;
                amounts.qst = amounts.woli.QST__c;
                amounts.hst = amounts.woli.HST__c;
            }
        } else {
            amounts.totalAmount = orderRecord.TotalAmount;
            amounts.gst = orderRecord.GST__c;
            amounts.qst = orderRecord.QST__c;
            amounts.hst = orderRecord.HST__c;
        }
        
        return amounts;
    }

    @AuraEnabled
    public static String processPaymentDirectly(String recordId, String paymentMethod) {
        try {
            if (String.isBlank(recordId)) {
                throw new CustomExceptions.PaymentException('Record ID is required');
            }
            
            Order orderRecord = getOrderDetails(recordId);
            
            // Get payment amounts
            PaymentAmounts amounts = getPaymentAmounts(orderRecord, null);
            
            // Process the payment synchronously
            ShopifyPaymentService.ShopifyPaymentInput input = ShopifyPaymentService.buildShopifyInput(
                orderRecord, null, paymentMethod, null, amounts.totalAmount, 
                amounts.gst, amounts.qst, amounts.hst, null, 'Payment'
            );
            
            Map<String, Object> result = ShopifyPaymentService.processShopifyPayment(input);
            String paymentUrl = (String)result.get('url');
            
            System.debug('paymentUrl: ' + paymentUrl);

            // Update the Order record with the URL
            orderRecord.Shopify_payment_url__c = paymentUrl;
          //  update orderRecord;
            
            return paymentUrl;
            
        } catch(Exception e) {
            System.debug('Error in processPaymentDirectly: ' + e.getMessage());
            throw new CustomExceptions.PaymentException('Error processing payment: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String generatePaymentLinkForRecord(String recordId, String paymentMethod) {
        try {
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Record ID is required');
            }
            
            // For LWC/Aura components, use synchronous processing
            return processPaymentDirectly(recordId, String.isNotBlank(paymentMethod) ? paymentMethod : 'Online');
            
        } catch (Exception e) {
            System.debug('Error in generatePaymentLinkForRecord: ' + e.getMessage());
            throw new AuraHandledException('Error generating payment link: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Order getUrlFromRecord(String recordId) {
        try {
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('Record ID is required');
            }
            
            return [SELECT Id, Shopify_payment_url__c FROM Order WHERE Id = :recordId LIMIT 1];
            
        } catch (QueryException qe) {
            throw new AuraHandledException('Order not found: ' + qe.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getRedirectUrl() {
        try {
            URL_Configuration__mdt urlConfig = [
                SELECT DeveloperName, Redirect_URL__c 
                FROM URL_Configuration__mdt 
                WHERE DeveloperName = 'External_Site_Redirect' 
                LIMIT 1
            ];
            
            return urlConfig.Redirect_URL__c;
            
        } catch (QueryException qe) {
            System.debug('URL configuration not found: ' + qe.getMessage());
            return null;
        } catch (Exception e) {
            System.debug('Error retrieving URL from custom metadata: ' + e.getMessage());
            return null;
        }
    }

    @AuraEnabled
    public static Order getOrderDetails(String recordId){
        if (String.isBlank(recordId)) {
            throw new CustomExceptions.OrderNotFoundException('Record ID is required');
        }
        
        System.debug('recordId ' + recordId);

        try {
            return [
                SELECT Id, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingStateCode,
                       TotalAmount, GST__c, QST__c, HST__c, Account.BillingPostalCode, Account.BillingCountryCode,
                       Account.BillingCountry, Account.Sage_ID__c, Account.Email__c, 
                       Order_Number__c, Sage_ID__c, BillToContact.FirstName, Shopify_payment_url__c, 
                       BillToContact.LastName, Account.Cellphone__c, Account.Phone,
                       BillToContact.Email, BillToContact.Phone
                FROM Order
                WHERE Id = :recordId
                LIMIT 1
            ];
        } catch (QueryException qe) {
            throw new CustomExceptions.OrderNotFoundException('Order not found with Id: ' + recordId + '. Error: ' + qe.getMessage());
        }
    }


    @AuraEnabled(cacheable=false)
    public static Map<String, Object> fetchWeather() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://jsonplaceholder.typicode.com/todos/1');
        req.setMethod('GET');
        Http http = new Http();
        HttpResponse res = http.send(req);
        if(res.getStatusCode() == 200){
            return (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        } else {
            throw new AuraHandledException('Error: ' + res.getBody());
        }
    }

    @AuraEnabled(cacheable=true)
public static List<Contact> getRelatedContacts(Id woliId) {
    WorkOrderLineItem woli = [
        SELECT Id, OrderId, Order.AccountId
        FROM WorkOrderLineItem
        WHERE Id = :woliId
        LIMIT 1
    ];
    System.debug('Woli ' + woli);
    System.debug('contact ' + [SELECT Id, Name, Email FROM Contact WHERE AccountId = :woli.Order.AccountId]);
    return [SELECT Id, Name, Email FROM Contact WHERE AccountId = :woli.Order.AccountId];
}


}