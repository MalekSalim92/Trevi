/**
 * ShopifyPaymentService
 *
 * Responsible for handling Shopify payment requests from Salesforce.
 * Provides invocable methods for Flow/Process Builder and makes async
 * callouts to Shopify API. Updates WorkOrderLineItem records with 
 * payment URLs and pending status.
 *
 * Author: Malek Brachemi
 * Date: 2025-08-18
 */
public with sharing class ShopifyPaymentService {

    /**
     * PaymentRequest
     *
     * Wrapper class to receive inputs from Flow or Process Builder
     */
    public class PaymentRequest {
        @InvocableVariable(label='Work Order Line Item ID' description='ID of the Work Order Line Item' required=true)
        public String woliId;
        
        @InvocableVariable(label='Contact ID' description='ID of the Contact for billing' required=true)
        public String contactId;
    }

    /**
     * makePayment
     *
     * Invocable method callable from Flow or Process Builder
     * @param requests List of PaymentRequest objects
     * @throws AuraHandledException if input is missing or callout fails
     */
    @InvocableMethod(label='Shopify Payment' description='Method to process Shopify payment')
    public static void makePayment(List<PaymentRequest> requests ) {
        if (requests == null || requests.isEmpty() || String.isBlank(requests[0].woliId) || String.isBlank(requests[0].contactId)) {
            throw new AuraHandledException('WOLI Id must be provided.');
        }

        String contactId = requests[0].contactId;
        String woliId = requests[0].woliId;

        try {
            // Call future method for async callout
            makeCalloutAsync(woliId, contactId);
        } catch (Exception e) {
            System.debug('Error updating WOLI: ' + e.getMessage());
            throw new AuraHandledException('Failed to initiate payment process: ' + e.getMessage());
        }
    }

    /**
     * makeCalloutAsync
     *
     * Future method to perform API callout asynchronously
     * @param woliId WorkOrderLineItem Id
     * @param contactId Contact Id
     */
    @future(callout=true)
    private static void makeCalloutAsync(Id woliId, Id contactId) {
        WorkOrderLineItem woli = [
            SELECT Id, OrderId, Order.BillToContactId,
                   Order.Id, Order.Order_Number__c,
                   Order.BillingStreet, Order.BillingCity, Order.BillingPostalCode,
                   Order.BillingStateCode, Order.BillingCountryCode, Order.TotalAmount,
                   GST__c, QST__c, HST__c,
                   Order.AccountId, Status,
                   Order.Account.Sage_ID__c, Order.Account.Email__c,
                   Order.Account.BillingStreet, Order.Account.BillingCity,
                   Order.Account.BillingPostalCode, Order.Account.BillingStateCode,
                   Order.Account.BillingCountryCode, Outstanding_Amount_Before_Tax__c,
                   Order.Account.Phone, Shopify_Payment_Pending__c, Shopify_Payment_url__c
            FROM WorkOrderLineItem
            WHERE Id = :woliId
            LIMIT 1
        ];

        Contact con = [
            SELECT Id, FirstName, LastName, Email, MobilePhone, HomePhone
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];

        try {
            // Perform the Shopify API callout
            ShopifyResponseWrapper response = makeCallout(woli, con);

            // Update WOLI with URL and pending status
            woli.Shopify_Payment_url__c = response.url;
            woli.Shopify_Payment_Pending__c = response.has_payment_request_pending == 'true';
            update woli;

            System.debug('Payment completed successfully for WOLI: ' + woliId);
        } catch (Exception e) {
            System.debug('Payment failed for WOLI: ' + woliId + '. Error: ' + e.getMessage());
        }
    }

    /**
     * makeCallout
     *
     * Synchronous callout to Shopify API
     * @param woli WorkOrderLineItem
     * @param con Contact
     * @return ShopifyResponseWrapper
     * @throws AuraHandledException if network or parsing error occurs
     */
    private static ShopifyResponseWrapper makeCallout(WorkOrderLineItem woli, Contact con) {
        ShopifyApiWrapper requestWrapper = buildWrapper(woli, con);

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
     * @param woli WorkOrderLineItem
     * @param con Contact
     * @return ShopifyApiWrapper
     */
    private static ShopifyApiWrapper buildWrapper(WorkOrderLineItem woli, Contact con) {
        ShopifyApiWrapper wrapper = new ShopifyApiWrapper();
        wrapper.order.transaction_type = 'Payment';
        wrapper.order.payment_type = 'FS';
        wrapper.order.salesforce_id = woli.Id;
        wrapper.order.salesforce_object = 'Work Order Line Item';
        wrapper.order.sage_customer_id = woli.Order.Account.Sage_ID__c ?? '';
        wrapper.order.sage_order_id = woli.Order.Order_Number__c ?? '';
        wrapper.order.first_name = con.FirstName ?? '';
        wrapper.order.last_name = con.LastName ?? '';
        wrapper.order.customer_email = con.Email ?? '';
        wrapper.order.billing_street = woli.Order.Account.BillingStreet ?? '';
        wrapper.order.billing_city = woli.Order.Account.BillingCity ?? '';
        wrapper.order.billing_postalcode = woli.Order.Account.BillingPostalCode ?? '';
        wrapper.order.billing_state = woli.Order.Account.BillingStateCode ?? '';
        wrapper.order.billing_country = woli.Order.Account.BillingCountryCode ?? '';
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

    // COMMENT: Wrapper classes for request and response
    public class ShopifyApiWrapper { public OrderDetails order = new OrderDetails(); }
    public class OrderDetails {
        public String transaction_type, payment_type, salesforce_object, salesforce_id, sage_order_id, sage_customer_id;
        public String first_name, last_name, customer_email, billing_street, billing_city, billing_postalcode, billing_state, billing_country;
        public String phone, cancel_at, send_email, success_status, total_amount, GST, QST, HST;
        public Object products;
    }
    public class ShopifyResponseWrapper { public String url, has_payment_request_pending, refund_status; }

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