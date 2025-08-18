@isTest
public class ShopifyIntegrationTest {
    static{
        Test.setMock(HttpCalloutMock.class, new ShopifyMockHttpResponse());
    }

    // Test data setup method
    @TestSetup
    static void setupTestData() {
        TestDataFactory.createCompleteTestData();
    }

    @isTest
    static void testGenerateOnlinePaymentLinkWithWoliAndContact() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        WorkOrderLineItem testWoli = [SELECT Id,orderId FROM WorkOrderLineItem LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        system.debug('testOrder $$$ : ' +testOrder);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ShopifyMockHttpResponse());
        ShopifyIntegration.PaymentInputs input = new ShopifyIntegration.PaymentInputs();
        input.orderId = testOrder.Id;
        input.paymentMethod = 'Online';
        input.woli = testWoli.Id;
        input.contactId = testContact.Id;
        system.debug('input $$$ : ' +input);
        
        List<String> result = ShopifyIntegration.generatePaymentLink(new List<ShopifyIntegration.PaymentInputs>{input});
        system.debug('resutl $$$ : ' +result);
        Test.stopTest();
        
        System.assertEquals('Payment processing started asynchronously.', result[0], 'The payment URL should match the mock response');
        
        Order updatedOrder = [SELECT Shopify_payment_url__c FROM Order WHERE Id = :testOrder.Id];
        System.assertEquals('True', updatedOrder.Shopify_payment_url__c, 'The Order should be updated with the payment URL');
    }

    @isTest
    static void testGenerateOnlinePaymentLink() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
 
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ShopifyMockHttpResponse());

        ShopifyIntegration.PaymentInputs input = new ShopifyIntegration.PaymentInputs();
        input.orderId = testOrder.Id;
        input.paymentMethod = 'Online';
         system.debug('input $$$ : ' +input);
        
        List<String> result = ShopifyIntegration.generatePaymentLink(new List<ShopifyIntegration.PaymentInputs>{input});
        system.debug('resutl $$$ : ' +result);
        Test.stopTest();
        
        System.assertEquals('Payment processing started asynchronously.', result[0], 'The payment URL should match the mock response');
        
        Order updatedOrder = [SELECT Shopify_payment_url__c FROM Order WHERE Id = :testOrder.Id];
        System.assertEquals('https://testshop.myshopify.com/payment/12345', updatedOrder.Shopify_payment_url__c, 'The Order should be updated with the payment URL');
    }
    
    @isTest
    static void testGenerateOnlinePaymentLinkForRecord() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        system.debug('testOrder $$$ : ' +testOrder);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ShopifyMockHttpResponse());

        ShopifyIntegration.PaymentInputs input = new ShopifyIntegration.PaymentInputs();
         system.debug('input $$$ : ' +input);
        
        String result = ShopifyIntegration.generatePaymentLinkForRecord(testOrder.Id,'Online');
        system.debug('resutl $$$ : ' +result);
        Test.stopTest();
        
        System.assertEquals('Payment processing started asynchronously.', result ,'The payment URL should match the mock response');
        
        Order updatedOrder = [SELECT Shopify_payment_url__c FROM Order WHERE Id = :testOrder.Id];
        System.assertEquals('https://testshop.myshopify.com/payment/12345', updatedOrder.Shopify_payment_url__c, 'The Order should be updated with the payment URL');
    }

    @isTest
    static void testProcessPaymentDirectly() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
 

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ShopifyMockHttpResponse());

        String result = ShopifyIntegration.processPaymentDirectly(testOrder.Id,'Online');
        system.debug('resutl $$$ : ' +result);
        Test.stopTest();
        
        System.assertEquals('https://testshop.myshopify.com/payment/12345', result ,'The payment URL should match the mock response');
        
        Order updatedOrder = [SELECT Shopify_payment_url__c FROM Order WHERE Id = :testOrder.Id];
        System.assertEquals('https://testshop.myshopify.com/payment/12345', updatedOrder.Shopify_payment_url__c, 'The Order should be updated with the payment URL');
    }

    @isTest
    static void testGetUrlFromRecord() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
 
        Test.startTest();
         
        Order result = ShopifyIntegration.getUrlFromRecord(testOrder.Id);
         Test.stopTest();
        System.assertEquals(testOrder.Id, result.Id ,'The ids should be the same');
        
    }

    @isTest
    static void testGetRedirectUrl() {
        Test.startTest();
         
        String result = ShopifyIntegration.getRedirectUrl();
         Test.stopTest();
         Assert.isNotNull(result ,'The URL should not be null');
        

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