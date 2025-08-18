@isTest
public with sharing class ContractSummaryControllerTest {
    static {
        Test.setMock(HttpCalloutMock.class, new HexaSurveyMockHttpResponse());
    }

    @TestSetup
    static void setupTestData() {
        TestDataFactory.createCompleteTestData();
    }
   
    @isTest 
    static void testContractSummary() {
        // Create test data
         
        // Get the test order
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        
        // Create a standard controller for the test order
        ApexPages.StandardController stdController = new ApexPages.StandardController(testOrder);
        
        // Instantiate the ContractSummaryController with the standard controller
        ContractSummaryController controller = new ContractSummaryController(stdController);
        
        // Verify the order is loaded correctly
        System.assertNotEquals(null, controller.order);
        System.assertEquals(testOrder.Id, controller.order.Id);
        
        // Verify the primary contact is loaded
        System.assertNotEquals(null, controller.primaryContact);
        
        // Verify the summarized products are generated
        System.assertNotEquals(null, controller.summarizedProducts);
        System.assert(!controller.summarizedProducts.isEmpty());
        System.debug('controller.summarizedProducts'+ controller.summarizedProducts);

        // Check the values of the first summarized product
        ContractSummaryController.SummarizedProduct firstProduct = controller.summarizedProducts[0];
        System.debug('firstProduct ' + firstProduct);

        System.assertEquals('TEST-PROD-001', firstProduct.productCode);
        System.assertEquals('Test Product', firstProduct.productName);
        System.assertEquals(6, firstProduct.quantity);
    }
}