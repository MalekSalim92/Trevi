/**
 * ShopifyPaymentService
 *
 * Responsible for handling Shopify payment requests from Salesforce.
 * Provides invocable methods for Flow/Process Builder and makes async
 * callouts to Shopify API. Updates WorkOrderLineItem/Order records with 
 * payment URLs and pending status.
 *
 * Author: Malek Brachemi
 * Date: 2025-08-18
 */
public without sharing class ShopifyPaymentService {

    /**
     * PaymentRequest
     *
     * Wrapper class to receive inputs from Flow or Process Builder
     */
    public class PaymentRequest {
        @InvocableVariable(label='Order ID' description='ID of the Order')
        public String orderId;

        @InvocableVariable(label='Work Order Line Item ID' description='ID of the Work Order Line Item')
        public String woliId;
        
        @InvocableVariable(label='Contact ID' description='ID of the Contact for billing')
        public String contactId;
    }

    /**
     * PaymentResult
     *
     * Wrapper class to return payment results for synchronous calls
     */
    public class PaymentResult {
        @AuraEnabled public String paymentUrl;
        @AuraEnabled public Boolean hasPaymentPending;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String errorMessage;
        
        public PaymentResult(String url, Boolean pending) {
            this.paymentUrl = url;
            this.hasPaymentPending = pending;
            this.success = true;
            this.errorMessage = null;
        }
        
        public PaymentResult(String error) {
            this.success = false;
            this.errorMessage = error;
            this.paymentUrl = null;
            this.hasPaymentPending = false;
        }
    }

    /**
     * makePayment (Async version)
     *
     * Invocable method callable from Flow or Process Builder
     * @param requests List of PaymentRequest objects
     * @throws AuraHandledException if input is missing or callout fails
     */
    @InvocableMethod(label='Shopify Payment (Async)' description='Method to process Shopify payment asynchronously')
    public static void makePayment(List<PaymentRequest> requests) {
        if (requests == null || requests.isEmpty() || String.isBlank(requests[0].woliId) || String.isBlank(requests[0].contactId)) {
            throw new AuraHandledException('(WOLI ID + Contact ID) must be provided.');
        }

        // Safe null checks for Apex
        String contactId = (requests[0] != null) ? requests[0].contactId : null;
        String woliId = (requests[0] != null) ? requests[0].woliId : null;
 
        try {
            // Call future method for async callout
            makeCalloutAsync(woliId, contactId);
        } catch (Exception e) {
            System.debug('Error initiating payment: ' + e.getMessage());
            throw new AuraHandledException('Failed to initiate payment process: ' + e.getMessage());
        }
    }

    /**
     * makePaymentSync
     *
     * Synchronous method for immediate response (e.g., from LWC or Aura)
     * @param orderId Order Id (optional)
     * @param woliId WorkOrderLineItem Id (optional)
     * @param contactId Contact Id (optional)
     * @return PaymentResult with payment URL and status
     */
    @AuraEnabled
    public static PaymentResult makePaymentSync(String orderId) {
        if (String.isBlank(orderId)) {
            return new PaymentResult('Order ID must be provided.');
        }

        try {
            return processPayment(orderId, null, null);
        } catch (Exception e) {
            System.debug('Sync payment failed. Error: ' + e.getMessage());
            return new PaymentResult('Failed to process payment: ' + e.getMessage());
        }
    }

    /**
     * makeCalloutAsync (Future method)
     *
     * Future method to perform API callout asynchronously
     * @param orderId Order Id (optional)
     * @param woliId WorkOrderLineItem Id (optional)
     * @param contactId Contact Id (optional)
     */
    @future(callout=true)
    private static void makeCalloutAsync(Id woliId, Id contactId) {
        try {
            PaymentResult result = processPayment(null, woliId, contactId);
            
            if (result.success) {
                System.debug('Async payment completed successfully for WOLI: ' + woliId);
            } else {
                System.debug('Async payment failed for WOLI: ' + woliId + '. Error: ' + result.errorMessage);
            }
        } catch (Exception e) {
            System.debug('Async payment failed for WOLI: ' + woliId + '. Error: ' + e.getMessage());
        }
    }

    /**
     * processPayment (Core logic)
     *
     * Shared logic for both sync and async payment processing
     * @param orderId Order Id (optional)
     * @param woliId WorkOrderLineItem Id (optional)  
     * @param contactId Contact Id (optional)
     * @return PaymentResult
     */
    private static PaymentResult processPayment(String orderId, String woliId, String contactId) {
        try {
            // Get required records using helper methods
            WorkOrderLineItem woli = getWorkOrderLineItemRecord(woliId);
            Id orderIdToUse = String.isNotBlank(orderId) ? orderId : woli?.OrderId;

            Order order = getOrderRecord(orderIdToUse);
            Contact con = getContactRecord(contactId);

            // Perform the Shopify API callout
            ShopifyResponseWrapper response = makeCallout(order, woli, con);

            // Update WOLI with URL and pending status
            if (woli != null) {
                woli.Shopify_Payment_url__c = response.url;
                woli.Shopify_Payment_Pending__c = response.has_payment_request_pending == 'true';
                update woli;
            } else {
                order.Shopify_Payment_url__c = response.url;
                update order;
            }

            return new PaymentResult(response.url, response.has_payment_request_pending == 'true');
            
        } catch (Exception e) {
            return new PaymentResult('Payment processing failed: ' + e.getMessage());
        }
    }

    /**
     * Helper method to get Order record
     */
    private static Order getOrderRecord(String orderId) {
        if (String.isBlank(orderId)) return null;
        return [
            SELECT Id, Order_Number__c, AccountId, Status,
                   BillingStreet, BillingCity, BillingPostalCode,
                   BillingStateCode, BillingCountryCode, TotalAmount,
                   Account.Sage_ID__c, Account.Email__c,GST__c,QST__c,HST__c,
                   Account.BillingStreet, Account.BillingCity,
                   Account.BillingPostalCode, Account.BillingStateCode,
                   Account.BillingCountryCode, Account.Phone,Account.Cellphone__c
            FROM Order
            WHERE Id = :orderId
            LIMIT 1
        ];
    }

    /**
     * Helper method to get WorkOrderLineItem record
     */
    private static WorkOrderLineItem getWorkOrderLineItemRecord(String woliId) {
        if (String.isBlank(woliId)) return null;
        
        return [
            SELECT Id, OrderId, Status, Outstanding_Amount_Before_Tax__c,
                   GST__c, QST__c, HST__c, Shopify_Payment_url__c
             FROM WorkOrderLineItem
            WHERE Id = :woliId
            LIMIT 1
        ];
    }

    /**
     * Helper method to get Contact record
     */
    private static Contact getContactRecord(String contactId) {
        if (String.isBlank(contactId)) return null;
        
        return [
            SELECT Id, FirstName, LastName, Email, MobilePhone, HomePhone
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];
    }

    /**
     * makeCallout
     *
     * Synchronous callout to Shopify API
     * @param order Order record
     * @param woli WorkOrderLineItem record
     * @param con Contact record
     * @return ShopifyResponseWrapper
     * @throws AuraHandledException if network or parsing error occurs
     */
    private static ShopifyResponseWrapper makeCallout(Order order, WorkOrderLineItem woli, Contact con) {
        ShopifyApiWrapper requestWrapper = buildWrapper(order, woli, con);
        System.debug('requestWrapper: ' + requestWrapper);

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Shopify_API');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(requestWrapper));

        try {
            HttpResponse res = http.send(req);
            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                return (ShopifyResponseWrapper) JSON.deserialize(res.getBody(), ShopifyResponseWrapper.class);
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

    /**
     * buildWrapper
     *
     * Builds request wrapper object for Shopify API call
     * @param order Order record
     * @param woli WorkOrderLineItem record
     * @param con Contact record
     * @return ShopifyApiWrapper
     */
    private static ShopifyApiWrapper buildWrapper(Order order, WorkOrderLineItem woli, Contact con) {
        
        String phoneNumber;

        if (woli != null) {
            if (!String.isBlank(con?.MobilePhone)) {
                phoneNumber = con.MobilePhone;
            } else {
                phoneNumber = con?.HomePhone;
            }
        } else {
            if (!String.isBlank(order?.Account?.Cellphone__c)) {
                phoneNumber = order?.Account?.Cellphone__c;
            } else {
                phoneNumber = order?.Account?.Phone;
            }
        }
        Decimal totalAmount = woli != null ? woli?.Outstanding_Amount_Before_Tax__c ?? 0 : order?.TotalAmount ?? 0;
        Decimal gst = woli != null ? woli?.GST__c ?? 0 : order?.GST__c ?? 0;
        Decimal qst = woli != null ? woli?.QST__c ?? 0 : order?.QST__c ?? 0;
        Decimal hst = woli != null ? woli?.HST__c ?? 0 : order?.HST__c ?? 0;

        ShopifyApiWrapper wrapper = new ShopifyApiWrapper();
        wrapper.order.transaction_type = 'Payment';
        wrapper.order.payment_type = woli != null ? 'FS' : 'OP';
        wrapper.order.salesforce_id = woli != null ? woli.Id : order.Id;
        wrapper.order.salesforce_object = woli != null ? 'Work Order Line Item' : 'Order';        
        wrapper.order.sage_customer_id = order?.Account?.Sage_ID__c;
        wrapper.order.sage_order_id = order?.Order_Number__c;
        wrapper.order.first_name = woli != null ? con?.FirstName : UserInfo.getFirstName();
        wrapper.order.last_name = woli != null ? con?.LastName : UserInfo.getLastName();
        wrapper.order.customer_email = woli != null ? con?.Email : UserInfo.getUserEmail();
        wrapper.order.billing_street = order?.Account?.BillingStreet ?? '';
        wrapper.order.billing_city =  order?.Account?.BillingCity ?? '';
        wrapper.order.billing_postalcode =  order?.Account?.BillingPostalCode ?? '';
        wrapper.order.billing_state =  order?.Account?.BillingStateCode ?? '';
        wrapper.order.billing_country = order?.Account?.BillingCountryCode ?? '';
        wrapper.order.phone = phoneNumber;
        wrapper.order.success_status = woli != null ? 'Completed and paid' : 'To intervene';
        wrapper.order.total_amount = String.valueOf(totalAmount);
        wrapper.order.GST = String.valueOf(totalAmount * gst);
        wrapper.order.QST = String.valueOf(totalAmount * qst);
        wrapper.order.HST = String.valueOf(totalAmount * hst);
        wrapper.order.products = null;

        return wrapper;
    }

    // Wrapper classes for request and response
    public class ShopifyApiWrapper { 
        public OrderDetails order = new OrderDetails(); 
    }
    
    public class OrderDetails {
        public String transaction_type, payment_type, salesforce_object, salesforce_id, sage_order_id, sage_customer_id;
        public String first_name, last_name, customer_email, billing_street, billing_city, billing_postalcode, billing_state, billing_country;
        public String phone, cancel_at, send_email, success_status, total_amount, GST, QST, HST;
        public Object products;
    }
    
    public class ShopifyResponseWrapper { 
        public String url, has_payment_request_pending, refund_status; 
    }

    /**
     * getOrderDetails
     *
     * Returns Order record with payment URL
     * @param recordId Id of the Order
     * @return Order
     * @throws CustomExceptions.OrderNotFoundException if not found
     */
    @AuraEnabled
    public static Order getOrderDetails(String recordId){
        if (String.isBlank(recordId)) {
            throw new CustomExceptions.OrderNotFoundException('Record ID is required');
        }
        return [SELECT Id, Shopify_payment_url__c FROM Order WHERE Id = :recordId LIMIT 1];
    }

    /**
     * getRedirectUrl
     *
     * Returns external redirect URL from custom metadata
     * @return String URL or null
     */
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
        } catch (Exception e) {
            System.debug('Error retrieving URL from custom metadata: ' + e.getMessage());
            return null;
        }
    }
}