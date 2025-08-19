/**
 * Test Class: CaseQRCodeGeneratorTest
 * Description:
 *   Unit tests for CaseQRCodeGenerator controller class.
 *   - Verifies Case record is retrieved
 *   - Ensures QR code and Barcode URLs are generated
 *   - Confirms storeName is set from VF page parameter
 *
 * Author: Malek Brachemi
 * Created Date: 2025-02-18
 * Version: 1.0
 * Notes: Uses TestDataFactory to create required Account and Case records.
 */
@IsTest
private class CaseQRCodeGeneratorTest {
    
    /**
     * Test Setup Method
     * Creates an Account and Case record for use in test methods.
     */
    @TestSetup
    static void setupTestData() {
        Account testAccount = TestDataFactory.createTestAccount();
        insert testAccount;

        Case testCase = TestDataFactory.createTestCase();
        insert testCase;
    }
    
    /**
     * Test Method: testQRCodeGenerator
     * Verifies:
     *   - QR Code URL is generated
     *   - Barcode URL is generated
     *   - Case record is loaded
     *   - Store name parameter is respected
     */
    @IsTest
    static void testQRCodeGenerator() {
        // Retrieve test Case
        Case testCase = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        
        // Simulate Visualforce page with parameters
        PageReference pageRef = Page.CaseQRCodePage;
        pageRef.getParameters().put('id', testCase.Id);
        pageRef.getParameters().put('storeName', 'Test Store');
        Test.setCurrentPage(pageRef);
        
        // Instantiate controller
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        CaseQRCodeGenerator controller = new CaseQRCodeGenerator(sc);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, controller.qrCode, 'QR Code URL should not be null');
        System.assertNotEquals(null, controller.barCode, 'Barcode URL should not be null');
        System.assertNotEquals(null, controller.cas, 'Case should not be null');
        System.assertEquals('Test Store', controller.storeName, 'Store name should match');
        System.assert(controller.barCode.contains(testCase.CaseNumber), 'Barcode should contain CaseNumber');
    }
}