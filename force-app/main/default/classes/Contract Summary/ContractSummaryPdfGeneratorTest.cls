@isTest
private class ContractSummaryControllerTest {

    static {
        Test.setMock(HttpCalloutMock.class, new HexaSurveyMockHttpResponse());
    }

    @TestSetup
    static void setupTestData() {
        TestDataFactory.createCompleteTestData();
    }

    @isTest
    static void testSavePDFToFiles_Success() {
        // Retrieve the test order
        Order testOrder = [SELECT Id, OrderNumber FROM Order LIMIT 1];

        // Start test
        Test.startTest();
        
        // Prepare a page reference for testing
        PageReference pdfPage = Page.ContractSummary;
        pdfPage.getParameters().put('id', testOrder.Id);
        Test.setCurrentPage(pdfPage);

        // Call the method
        Id contentDocumentId = ContractSummaryPdfGenerator.savePDFToFiles(testOrder.Id,'en');

        // End test
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, contentDocumentId, 'Content Document ID should not be null');
        
        // Verify Content Version was created
        ContentVersion contentVersion = [
            SELECT Id, Title, ContentDocumentId 
            FROM ContentVersion 
            WHERE ContentDocumentId = :contentDocumentId 
            LIMIT 1
        ];
        System.assertNotEquals(null, contentVersion, 'Content Version should be created');
        
        // Verify Content Document Link
        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT Id, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE ContentDocumentId = :contentDocumentId
        ];
     }
 
     @isTest
static void testSavePDFToFiles_MultipleDocuments() {
    // Retrieve the test order
    Order testOrder = [SELECT Id, OrderNumber FROM Order LIMIT 1];

 

    // Create an existing document directly as a ContentVersion
    ContentVersion existingVersion = new ContentVersion(
        Title = 'Contract Summary - ' + testOrder.OrderNumber,
        PathOnClient = 'ContractSummary_' + testOrder.Id + '.pdf',
        VersionData = Blob.valueOf('Existing PDF Content'),
        FirstPublishLocationId = testOrder.Id
    );
    insert existingVersion;
    // Start test
    Test.startTest();
    
    // Call the method to generate a new PDF and delete existing ones
    Id newContentDocumentId = ContractSummaryPdfGenerator.savePDFToFiles(testOrder.Id,'en');

    // End test
    Test.stopTest();
    String prefix = 'Contract Summary - ' + testOrder.OrderNumber;
    // Verify existing documents were deleted
    List<ContentDocument> remainingDocuments = [
        SELECT Id 
        FROM ContentDocument 
        WHERE Title LIKE :prefix
    ];
    System.assertEquals(1, remainingDocuments.size(), 'Only one document should remain');
}
}