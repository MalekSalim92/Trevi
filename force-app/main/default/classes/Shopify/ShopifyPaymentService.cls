public with sharing class ShopifyPaymentService {

    public class PaymentRequest {
        @InvocableVariable(label='Work Order Line Item ID' description='ID of the Work Order Line Item' required=true)
        public String woliId;
        
        @InvocableVariable(label='Contact ID' description='ID of the Contact for billing' required=true)
        public String contactId;
    }

    @InvocableMethod(label='Shopify Payment' description='Method to process Shopify payment')
    public static void makePayment(List<PaymentRequest> requests ) {
        if (requests == null || requests.isEmpty() || String.isBlank(requests[0].woliId) || String.isBlank(requests[0].contactId)) {
            throw new AuraHandledException('WOLI Id must be provided.');
        }
        String contactId = requests[0].contactId;
        String woliId = requests[0].woliId;
        
        try {
             
            // Call the future method to handle API callout
            makeCalloutAsync(woliId, contactId);
            
        } catch (Exception e) {
            System.debug('Error updating WOLI: ' + e.getMessage());
            throw new AuraHandledException('Failed to initiate payment process: ' + e.getMessage());
        }
    }

    @future(callout=true)
    private static void makeCalloutAsync(Id woliId, Id contactId) {

        WorkOrderLineItem woli = [
            SELECT Id, OrderId, Order.BillToContactId,
                   Order.Id, Order.Order_Number__c,
                   Order.BillingStreet, Order.BillingCity, Order.BillingPostalCode,
                   Order.BillingStateCode, Order.BillingCountryCode,
                   Order.TotalAmount,GST__c, QST__c, HST__c,
                   Order.AccountId,Status,
                   Order.Account.Sage_ID__c, Order.Account.Email__c,
                   Order.Account.BillingStreet, Order.Account.BillingCity,
                   Order.Account.BillingPostalCode, Order.Account.BillingStateCode,
                   Order.Account.BillingCountryCode,Outstanding_Amount_Before_Tax__c,
                   Order.Account.Phone,Shopify_Payment_Pending__c,Shopify_Payment_url__c
            FROM WorkOrderLineItem
            WHERE Id = :woliId
            LIMIT 1
        ];
        
        Contact con = [
            SELECT Id, FirstName, LastName, Email,MobilePhone,HomePhone
            FROM Contact
            WHERE Id = :contactId 
            LIMIT 1
        ];
        
        try {
            // Make the API callout
            ShopifyResponseWrapper response = makeCallout(woli, con);
            String url = response.url;
            boolean pending = response.has_payment_request_pending == 'true';
            woli.Shopify_Payment_url__c = url;
            woli.Shopify_Payment_Pending__c = pending;
            update woli;
            System.debug('Payment completed successfully for WOLI: ' + woliId);
            
        } catch (Exception e) {
            System.debug('Payment failed for WOLI: ' + woliId + '. Error: ' + e.getMessage());
            
        }
    }

    private static ShopifyResponseWrapper makeCallout(WorkOrderLineItem woli, Contact con) {
        // Build request body wrapper
        ShopifyApiWrapper requestWrapper = buildWrapper(woli, con);

        // Call Shopify API
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Shopify_API');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(requestWrapper));
        
        HttpResponse res;
        try {
            res = http.send(req);
            System.debug('Shopify API Response Status: ' + res.getStatusCode());
            System.debug('Shopify API Response Body: ' + res.getBody());

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                ShopifyResponseWrapper responseWrapper = (ShopifyResponseWrapper) JSON.deserialize(res.getBody(), ShopifyResponseWrapper.class);

                return responseWrapper;
            } else {
                throw new AuraHandledException('Shopify API returned status ' + res.getStatusCode() + ': ' + res.getBody());
            }

        } catch (CalloutException e) {
            throw new AuraHandledException('Network error calling Shopify API: ' + e.getMessage());
        } catch (JSONException e) {
            throw new AuraHandledException('Failed to parse Shopify API response: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Unexpected error during Shopify API call: ' + e.getMessage());
        }
    }

    private static ShopifyApiWrapper buildWrapper(WorkOrderLineItem woli, Contact con) {
        ShopifyApiWrapper wrapper = new ShopifyApiWrapper();
        
        // Set fields on the wrapper.order object
        wrapper.order.transaction_type = 'Payment';
        wrapper.order.payment_type = 'FS';
        wrapper.order.salesforce_id = woli.Id;
        wrapper.order.salesforce_object = 'Work Order Line Item';
        wrapper.order.sage_customer_id = woli.Order.Account.Sage_ID__c ?? '';
        wrapper.order.sage_order_id = woli.Order.Order_Number__c ?? '';
        wrapper.order.first_name = con.FirstName ?? '';
        wrapper.order.last_name = con.LastName ?? '';
        wrapper.order.customer_email = con.Email ?? '';
        wrapper.order.billing_street =  woli.Order.Account.BillingStreet ?? '';
        wrapper.order.billing_city =   woli.Order.Account.BillingCity ?? '';
        wrapper.order.billing_postalcode = woli.Order.Account.BillingPostalCode ?? '';
        wrapper.order.billing_state =  woli.Order.Account.BillingStateCode ?? '';
        wrapper.order.billing_country =  woli.Order.Account.BillingCountryCode ?? '';
        wrapper.order.phone = String.isNotEmpty(con.MobilePhone) ? con.MobilePhone : con.HomePhone;
        wrapper.order.success_status = 'Completed and paid';
        
        Decimal totalAmount = woli.Outstanding_Amount_Before_Tax__c ?? 0;
        wrapper.order.total_amount = String.valueOf(totalAmount);
        wrapper.order.GST = String.valueOf(totalAmount * woli.GST__c);
        wrapper.order.QST = String.valueOf(totalAmount * woli.QST__c);
        wrapper.order.HST = String.valueOf(totalAmount * woli.HST__c);

        wrapper.order.products = null;
        
        return wrapper;
    }

    // Wrapper classes for request and response
    public class ShopifyApiWrapper {
        public OrderDetails order;
        
        public ShopifyApiWrapper() {
            this.order = new OrderDetails();
        }
    }

    public class OrderDetails {
        public String transaction_type;
        public String payment_type;
        public String salesforce_object;
        public String salesforce_id;
        public String sage_order_id;
        public String sage_customer_id;
        public String first_name;
        public String last_name;
        public String customer_email;
        public String billing_street;
        public String billing_city;
        public String billing_postalcode;
        public String billing_state;
        public String billing_country;
        public String phone;
        public String cancel_at;
        public String send_email;
        public String success_status;
        public String total_amount;
        public String GST;
        public String QST;
        public String HST;
        public Object products;
    }

    public class ShopifyResponseWrapper {
        public String url;
        public String has_payment_request_pending;
        public String refund_status;
    }
    


    @AuraEnabled
    public static Order getOrderDetails(String recordId){
        if (String.isBlank(recordId)) {
            throw new CustomExceptions.OrderNotFoundException('Record ID is required');
        }
        
        System.debug('recordId ' + recordId);

        try {
            return [
                SELECT Id, Shopify_payment_url__c
                FROM Order
                WHERE Id = :recordId
                LIMIT 1
            ];
        } catch (QueryException qe) {
            throw new CustomExceptions.OrderNotFoundException('Order not found with Id: ' + recordId + '. Error: ' + qe.getMessage());
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
}