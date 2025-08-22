@isTest
public class ShopifyPaymentServiceTest {
    static{
        Test.setMock(HttpCalloutMock.class, new ShopifyMockHttpResponse());
    }

    // Test data setup method
    @TestSetup
    static void setupTestData() {
        TestDataFactory.createCompleteTestData();
    }

    @isTest
    static void testMakePayment() {
         WorkOrderLineItem testWoli = [SELECT Id,orderId FROM WorkOrderLineItem LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        ShopifyPaymentService.PaymentRequest req = new ShopifyPaymentService.PaymentRequest();
        req.woliId = testWoli.Id;
        req.contactId = testContact.Id;
        List<ShopifyPaymentService.PaymentRequest> reqList = new List<ShopifyPaymentService.PaymentRequest>{req};
        Test.setMock(HttpCalloutMock.class, new ShopifyMockHttpResponse());
        Test.startTest();
        ShopifyPaymentService.makePayment(reqList);
        Test.stopTest();
        
    
    }

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