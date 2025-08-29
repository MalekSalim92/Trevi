    @isTest
private class ShopifyPaymentServiceTest {
    
    // Test data setup method
    @TestSetup
    static void setupTestData() {
        TestDataFactory.createCompleteTestData();
    }
    

    // Test async payment processing
    @isTest
    static void testMakePaymentAsync() {
        // Arrange
        Contact con = [SELECT Id FROM Contact  LIMIT 1];
        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
        
        ShopifyPaymentService.PaymentRequest request = new ShopifyPaymentService.PaymentRequest();
        request.orderId = null;
        request.woliId = woli.Id;
        request.contactId = con.Id;

        // Mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new ShopifyPaymentServiceMock());

        // Act
        Test.startTest();
        ShopifyPaymentService.makePayment(new List<ShopifyPaymentService.PaymentRequest>{request});
        Test.stopTest();

        // Assert
        woli = [SELECT Shopify_Payment_url__c, Shopify_Payment_Pending__c FROM WorkOrderLineItem WHERE Id = :woli.Id];
        System.assertEquals('https://shopify.com/payment/123', woli.Shopify_Payment_url__c, 'Payment URL should be set');
        System.assertEquals('true', woli.Shopify_Payment_Pending__c, 'Payment pending status should be set');
    }

    // Test sync payment processing
    @isTest
    static void testMakePaymentSync() {
        // Arrange
        Order ord = [SELECT Id FROM Order LIMIT 1];

        // Mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new ShopifyPaymentServiceMock());

        // Act
        Test.startTest();
        List<ShopifyPaymentService.PaymentResult> results = ShopifyPaymentService.makePaymentSync(new List<String>{ord.Id});
        Test.stopTest();

        // Assert
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'Payment should be successful');
        System.assertEquals('https://shopify.com/payment/123', results[0].paymentUrl, 'Payment URL should match');
        System.assertEquals('true', results[0].hasPaymentPending, 'Payment pending status should match');
        System.assertEquals(ord.Id, results[0].recordId, 'Record ID should match');
    }

 
    // Test sync payment with invalid order ID
    @isTest
    static void testMakePaymentSyncInvalidOrder() {
        // Arrange
        String invalidOrderId = '001000000000000';

        // Mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new ShopifyPaymentServiceMock());

        // Act
        Test.startTest();
        List<ShopifyPaymentService.PaymentResult> results = ShopifyPaymentService.makePaymentSync(new List<String>{invalidOrderId});
        Test.stopTest();

        // Assert
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].success, 'Payment should fail');
        System.assertEquals('Missing required record data for ID: ' + invalidOrderId, results[0].errorMessage, 'Error message should match');
    }

    // Test getOrderDetails
    @isTest
    static void testGetOrderDetails() {
        // Arrange
        Order ord = [SELECT Id, Shopify_payment_url__c FROM Order LIMIT 1];

        // Act
        Test.startTest();
        Order result = ShopifyPaymentService.getOrderDetails(ord.Id);
        Test.stopTest();

        // Assert
        System.assertEquals(ord.Id, result.Id, 'Order ID should match');
    }

    // Test getOrderDetails with invalid ID
    @isTest
    static void testGetOrderDetailsInvalidId() {
        // Arrange
        String invalidId = null;

        // Act & Assert
        try {
            Test.startTest();
            ShopifyPaymentService.getOrderDetails(invalidId);
            Test.stopTest();
            System.assert(false, 'Should have thrown an exception');
        } catch (CustomExceptions.OrderNotFoundException e) {
            System.assertEquals('Record ID is required', e.getMessage(), 'Expected error message for invalid ID');
        }
    }

    // Test getRedirectUrl
    @isTest
    static void testGetRedirectUrl() {
        // Arrange
        String urlName = 'TestRedirect';

        // Mock custom metadata (since it can't be inserted in tests)
        // Assume metadata exists for this test
        Test.startTest();
        String result = ShopifyPaymentService.getRedirectUrl(urlName);
        Test.stopTest();

        // Assert
        // Since we can't insert custom metadata, we expect null in this case
        System.assertEquals(null, result, 'Should return null when metadata is not found');
    }

    // Mock HTTP callout class
    private class ShopifyPaymentServiceMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"url":"https://shopify.com/payment/123","has_payment_request_pending":"true","refund_status":"none"}');
            res.setStatusCode(200);
            return res;
        }
    }
 
}