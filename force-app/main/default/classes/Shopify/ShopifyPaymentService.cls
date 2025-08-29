/**
 * ShopifyPaymentService
 *
 * Responsible for handling Shopify payment requests from Salesforce.
 * Provides invocable methods for Flow  and makes async
 * callouts to Shopify API. Updates WorkOrderLineItem/Order records with 
 * payment URLs and pending status in bulk.
 *
 * Author: Malek Brachemi
 * Date: 2025-08-18
 * Modified for Bulkification: 2025-08-28
 */
public without sharing class ShopifyPaymentService {

    /**
     * PaymentRequest
     *
     * Wrapper class to receive inputs from Flow  
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
        @AuraEnabled public String hasPaymentPending;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String recordId; // Added to track record ID
        
        public PaymentResult(String url, String pending, String recordId) {
            this.paymentUrl = url;
            this.hasPaymentPending = pending;
            this.success = true;
            this.errorMessage = null;
            this.recordId = recordId;
        }
        
        public PaymentResult(String error, String recordId) {
            this.success = false;
            this.errorMessage = error;
            this.paymentUrl = null;
            this.hasPaymentPending = '';
            this.recordId = recordId;
        }
    }

    /**
     * makePayment (Async version)
     *
     * Invocable method callable from Flow
     * @param requests List of PaymentRequest objects
     * @throws AuraHandledException if input is missing
     */
    @InvocableMethod(label='Shopify Payment (Async)' description='Method to process Shopify payments asynchronously in bulk')
    public static void makePayment(List<PaymentRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            throw new AuraHandledException('At least one PaymentRequest must be provided.');
        }

        // Validate inputs
        List<PaymentRequest> validRequests = new List<PaymentRequest>();
        for (PaymentRequest req : requests) {
            if (String.isBlank(req.woliId) || String.isBlank(req.contactId)) {
                System.debug('Invalid request: WOLI ID or Contact ID missing for ' + req);
                continue; // Skip invalid requests
            }
            validRequests.add(req);
        }

        if (validRequests.isEmpty()) {
            throw new AuraHandledException('No valid PaymentRequests provided.');
        }

        // Enqueue Queueable job for async processing
        System.enqueueJob(new ShopifyPaymentQueueable(validRequests));
    }

    /**
     * makePaymentSync
     *
     * Synchronous method for immediate response from LWC (flow and button click payments)
     * @param orderIds List of Order IDs
     * @return List of PaymentResult
     */
    @AuraEnabled
    public static List<PaymentResult> makePaymentSync(List<String> orderIds) {
        if (orderIds == null || orderIds.isEmpty()) {
            return new List<PaymentResult>{ new PaymentResult('Order IDs must be provided.', null) };
        }

        try {
            return processPayments(orderIds, null, null);
        } catch (Exception e) {
            System.debug('Sync payment failed. Error: ' + e.getMessage());
            return new List<PaymentResult>{ new PaymentResult('Failed to process payments: ' + e.getMessage(), null) };
        }
    }

    /**
     * Queueable class for async processing
     */
    public class ShopifyPaymentQueueable implements Queueable, Database.AllowsCallouts {
        private List<PaymentRequest> requests;

        public ShopifyPaymentQueueable(List<PaymentRequest> requests) {
            this.requests = requests;
        }

        public void execute(QueueableContext context) {
            List<String> woliIds = new List<String>();
            List<String> contactIds = new List<String>();
            for (PaymentRequest req : requests) {
                woliIds.add(req.woliId);
                contactIds.add(req.contactId);
            }
            processPayments(null, woliIds, contactIds);
        }
    }

    /**
     * processPayments (Core logic)
     *
     * Shared logic for both sync and async payment processing
     * @param orderIds List of Order IDs (optional)
     * @param woliIds List of WorkOrderLineItem IDs (optional)  
     * @param contactIds List of Contact IDs (optional)
     * @return List<PaymentResult>
     */
    private static List<PaymentResult> processPayments(List<String> orderIds, List<String> woliIds, List<String> contactIds) {
        List<PaymentResult> results = new List<PaymentResult>();
        Map<Id, WorkOrderLineItem> wolisToUpdate = new Map<Id, WorkOrderLineItem>();
        Map<Id, Order> ordersToUpdate = new Map<Id, Order>();

        try {
            // Fetch records in bulk
            Map<Id, WorkOrderLineItem> woliMap = getWorkOrderLineItems(woliIds);
            Map<Id, Order> orderMap = getOrders(orderIds, woliMap);
            Map<Id, Contact> contactMap = getContacts(contactIds);

            // Process each request
            for (Integer i = 0; i < (woliIds != null ? woliIds.size() : orderIds.size()); i++) {
                String recordId = woliIds != null ? woliIds[i] : orderIds[i];
                String contactId = woliIds != null ? contactIds[i] : null;

                WorkOrderLineItem woli = woliIds != null ? woliMap.get(recordId) : null;
                Id orderIdToUse = woliIds != null ? woli?.OrderId : recordId;
                Order order = orderMap.get(orderIdToUse);
                Contact con = contactId != null ? contactMap.get(contactId) : null;

                if ((woliIds != null && woli == null) || order == null || (contactId != null && con == null)) {
                    results.add(new PaymentResult('Missing required record data for ID: ' + recordId, recordId));
                    continue;
                }

                // Perform Shopify API callout
                ShopifyResponseWrapper response;
                try {
                    response = makeCallout(order, woli, con);
                } catch (Exception e) {
                    results.add(new PaymentResult('Payment processing failed for ID ' + recordId + ': ' + e.getMessage(), recordId));
                    if (woli != null) {
                        woli.Payment_Launched__c = false;
                        wolisToUpdate.put(woli.Id, woli);
                    }
                    continue;
                }

                // Update records
                if (woli != null) {
                    woli.Shopify_Payment_url__c = response.url;
                    woli.Shopify_Payment_Pending__c = response.has_payment_request_pending;
                    wolisToUpdate.put(woli.Id, woli);
                } else {
                    order.Shopify_Payment_url__c = response.url;
                    ordersToUpdate.put(order.Id, order);
                }

                results.add(new PaymentResult(response.url, response.has_payment_request_pending, recordId));
            }

            // Perform bulk DML updates
            if (!wolisToUpdate.isEmpty()) {
                update wolisToUpdate.values();
            }
            if (!ordersToUpdate.isEmpty()) {
                update ordersToUpdate.values();
            }

        } catch (Exception e) {
            System.debug('Bulk payment processing failed: ' + e.getMessage());
            results.add(new PaymentResult('Bulk payment processing failed: ' + e.getMessage(), null));
        }

        return results;
    }

    /**
     * Helper method to get Order records in bulk
     */
    private static Map<Id, Order> getOrders(List<String> orderIds, Map<Id, WorkOrderLineItem> woliMap) {
        Set<Id> orderIdSet = new Set<Id>();
        if (orderIds != null) {
            orderIdSet.addAll((List<Id>)orderIds);
        }
        if (woliMap != null) {
            for (WorkOrderLineItem woli : woliMap.values()) {
                if (woli.OrderId != null) {
                    orderIdSet.add(woli.OrderId);
                }
            }
        }
        if (orderIdSet.isEmpty()) {
            return new Map<Id, Order>();
        }

        return new Map<Id, Order>([
            SELECT Id, Order_Number__c, AccountId, Status,
                   BillingStreet, BillingCity, BillingPostalCode,
                   BillingStateCode, BillingCountryCode, TotalAmount,
                   Account.Sage_ID__c, Account.Email__c, GST__c, QST__c, HST__c,
                   Account.BillingStreet, Account.BillingCity,
                   Account.BillingPostalCode, Account.BillingStateCode,
                   Account.BillingCountryCode, Account.Phone, Account.Cellphone__c
            FROM Order
            WHERE Id IN :orderIdSet
        ]);
    }

    /**
     * Helper method to get WorkOrderLineItem records in bulk
     */
    private static Map<Id, WorkOrderLineItem> getWorkOrderLineItems(List<String> woliIds) {
        if (woliIds == null || woliIds.isEmpty()) {
            return new Map<Id, WorkOrderLineItem>();
        }

        return new Map<Id, WorkOrderLineItem>([
            SELECT Id, OrderId, Status, Outstanding_Amount_Before_Tax__c,
                   GST__c, QST__c, HST__c, Shopify_Payment_url__c
            FROM WorkOrderLineItem
            WHERE Id IN :woliIds
        ]);
    }

    /**
     * Helper method to get Contact records in bulk
     */
    private static Map<Id, Contact> getContacts(List<String> contactIds) {
        if (contactIds == null || contactIds.isEmpty()) {
            return new Map<Id, Contact>();
        }

        return new Map<Id, Contact>([
            SELECT Id, FirstName, LastName, Email, MobilePhone, HomePhone
            FROM Contact
            WHERE Id IN :contactIds
        ]);
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
    public static Order getOrderDetails(String recordId) {
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
    public static String getRedirectUrl(String urlRedirectionName) {
        try {
            URL_Configuration__mdt urlConfig = [
                SELECT DeveloperName, Redirect_URL__c
                FROM URL_Configuration__mdt 
                WHERE DeveloperName = :urlRedirectionName 
                LIMIT 1
            ];
            return urlConfig.Redirect_URL__c;
        } catch (Exception e) {
            System.debug('Error retrieving URL from custom metadata: ' + e.getMessage());
            return null;
        }
    }
}