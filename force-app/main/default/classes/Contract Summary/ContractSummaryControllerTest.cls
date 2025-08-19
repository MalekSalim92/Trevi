/**
 * ContractSummaryControllerTest
 *
 * Test class for ContractSummaryController
 * Ensures:
 *   - Order and primary contact are loaded correctly
 *   - Order products are summarized correctly
 *   - Aggregation of quantities and shipment data works as expected
 *
 * Author: Malek Brachemi
 * Date: 2025-03-25
 */
@IsTest
public with sharing class ContractSummaryControllerTest {

    // ----- Test Setup -----
    
    /**
     * Static block to set up HTTP mocks if any callouts are required
     */
    static {
        Test.setMock(HttpCalloutMock.class, new HexaSurveyMockHttpResponse());
    }

    /**
     * Creates test data for Orders, Contacts, Products, OrderItems, and ShipmentItems
     * This ensures the controller can run with meaningful data
     */
    @TestSetup
    static void setupTestData() {
        TestDataFactory.createCompleteTestData();
    }
   
    // ----- Test Methods -----
    
    /**
     * Tests the ContractSummaryController functionality
     */
    @IsTest
    static void testContractSummary() {
        // Query a test order from setup data
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        
        // Create a standard controller using the test order
        ApexPages.StandardController stdController = new ApexPages.StandardController(testOrder);
        
        // Instantiate the ContractSummaryController with the standard controller
        ContractSummaryController controller = new ContractSummaryController(stdController);
        
        // ----- Assertions -----
        
        // Verify the order is loaded correctly
        System.assertNotEquals(null, controller.order, 'Order should be loaded');
        System.assertEquals(testOrder.Id, controller.order.Id, 'Loaded Order Id should match test order');
        
        // Verify the primary contact is loaded
        System.assertNotEquals(null, controller.primaryContact, 'Primary contact should be loaded');
        
        // Verify summarized products are generated
        System.assertNotEquals(null, controller.summarizedProducts, 'Summarized products should not be null');
        System.assert(!controller.summarizedProducts.isEmpty(), 'Summarized products list should not be empty');
        System.debug('Summarized Products: ' + controller.summarizedProducts);

        // Validate the first summarized product values
        ContractSummaryController.SummarizedProduct firstProduct = controller.summarizedProducts[0];
        System.debug('First Product: ' + firstProduct);

        System.assertEquals('TEST-PROD-001', firstProduct.productCode, 'Product code should match');
        System.assertEquals('Test Product', firstProduct.productName, 'Product name should match');
        System.assertEquals(7, firstProduct.quantity, 'Total quantity should match the aggregated value');
    }
}