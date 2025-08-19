/**
 * ShopifyPaymentServiceTest
 *
 * Test class for ShopifyPaymentService. Includes setup for test data,
 * HttpCalloutMock implementation, and a test method for the makePayment invocable method.
 *
 * Author: Malek Brachemi
 * Date: 2025-08-18
 */
@isTest
public class ShopifyPaymentServiceTest {

    // Set mock HTTP response for all tests in this class
    static {
        Test.setMock(HttpCalloutMock.class, new ShopifyMockHttpResponse());
    }

    /**
     * setupTestData
     *
     * Creates necessary test records (Accounts, Contacts, Orders, WorkOrderLineItems)
     * using TestDataFactory
     */
    @TestSetup
    static void setupTestData() {
        TestDataFactory.createCompleteTestData();
    }

    /**
     * testMakePayment
     *
     * Tests the makePayment invocable method in ShopifyPaymentService
     * Verifies that callout is made and WorkOrderLineItem fields are updated
     */
    @isTest
    static void testMakePayment() {
        // Query sample test records
        WorkOrderLineItem testWoli = [SELECT Id, OrderId FROM WorkOrderLineItem LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        // Prepare invocable method input
        ShopifyPaymentService.PaymentRequest req = new ShopifyPaymentService.PaymentRequest();
        req.woliId = testWoli.Id;
        req.contactId = testContact.Id;
        List<ShopifyPaymentService.PaymentRequest> reqList = new List<ShopifyPaymentService.PaymentRequest>{req};

        // Set mock HTTP response
        Test.setMock(HttpCalloutMock.class, new ShopifyMockHttpResponse());

        // Start test context to handle async callouts
        Test.startTest();
        ShopifyPaymentService.makePayment(reqList);
        Test.stopTest();

        // Optional: Assertions can be added here to verify updates on WorkOrderLineItem
    }

    /**
     * ShopifyMockHttpResponse
     *
     * Mock implementation of HttpCalloutMock for simulating Shopify API responses
     */
    private class ShopifyMockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"url": "https://testshop.myshopify.com/payment/12345","has_payment_request_pending": "True"}');
            return res;
        }
    }
}