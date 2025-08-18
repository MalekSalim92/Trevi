@IsTest
private class CaseQRCodeGeneratorTest {
    @TestSetup
    static void setupTestData() {
              
        Account testAccount = TestDataFactory.createTestAccount();
        insert testAccount;

        Case testCase = TestDataFactory.createTestCase();
        insert testCase;

    }
    
    @IsTest
    static void testQRCodeGenerator() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        Test.startTest();
        PageReference pageRef = Page.CaseQRCodePage;
        pageRef.getParameters().put('id', testCase.Id);
        pageRef.getParameters().put('storeName', 'Test Store');
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testCase);
        CaseQRCodeGenerator controller = new CaseQRCodeGenerator(sc);
        
        // Verify qrCode URL is generated
        System.assertNotEquals(null, controller.qrCode, 'QR Code URL should not be null');
        System.assertNotEquals(null, controller.cas, 'Case should not be null');
        System.assertEquals('Test Store', controller.storeName, 'Store name should match');
        Test.stopTest();
    }
}