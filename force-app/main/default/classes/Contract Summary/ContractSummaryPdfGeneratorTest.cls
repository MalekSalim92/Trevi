/**
 * ContractSummaryPdfGeneratorTest
 *
 * Test class for ContractSummaryPdfGenerator.
 * Covers:
 *   - Successful PDF generation
 *   - Deletion of existing PDFs before creating new ones
 *
 * Author: Malek Brachemi
 * Date: 2025-03-10
 */
@isTest
private class ContractSummaryPdfGeneratorTest {

    /**
     * Test setup: Creates required test data using TestDataFactory
     */
    @TestSetup
    static void setupTestData() {
        TestDataFactory.createCompleteTestData();
    }

    /**
     * Test successful PDF generation and ContentVersion creation
     */
    @isTest
    static void testSavePDFToFiles_Success() {
        // Retrieve the test order
        Order testOrder = [SELECT Id, OrderNumber FROM Order LIMIT 1];

        // Start test context
        Test.startTest();
        
        // Prepare a PageReference to simulate Visualforce PDF page
        PageReference pdfPage = Page.ContractSummary;
        pdfPage.getParameters().put('id', testOrder.Id);
        Test.setCurrentPage(pdfPage);

        // Call the PDF generator method
        Id contentDocumentId = ContractSummaryPdfGenerator.savePDFToFiles(testOrder.Id, 'en');

        // End test context
        Test.stopTest();

        // Verify ContentDocument ID is returned
        System.assertNotEquals(null, contentDocumentId, 'Content Document ID should not be null');
        
        // Verify ContentVersion was created
        ContentVersion contentVersion = [
            SELECT Id, Title, ContentDocumentId 
            FROM ContentVersion 
            WHERE ContentDocumentId = :contentDocumentId 
            LIMIT 1
        ];
        System.assertNotEquals(null, contentVersion, 'Content Version should be created');
        System.assertEquals(
            'Contract Summary - ' + testOrder.OrderNumber,
            contentVersion.Title,
            'ContentVersion title should match the expected format'
        );
        
        // Verify ContentDocumentLink exists
        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT Id, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE ContentDocumentId = :contentDocumentId
        ];
        System.assert(!contentDocumentLinks.isEmpty(), 'ContentDocumentLink should be created');
    }

    /**
     * Test scenario where existing PDFs exist: method should delete previous PDFs
     * and create a new one
     */
    @isTest
    static void testSavePDFToFiles_MultipleDocuments() {
        // Retrieve the test order
        Order testOrder = [SELECT Id, OrderNumber FROM Order LIMIT 1];

        // Create an existing ContentVersion for the same Order
        ContentVersion existingVersion = new ContentVersion(
            Title = 'Contract Summary - ' + testOrder.OrderNumber,
            PathOnClient = 'ContractSummary_' + testOrder.Id + '.pdf',
            VersionData = Blob.valueOf('Existing PDF Content'),
            FirstPublishLocationId = testOrder.Id
        );
        insert existingVersion;

        // Start test context
        Test.startTest();
        
        // Call the method to generate a new PDF, which should delete existing ones
        Id newContentDocumentId = ContractSummaryPdfGenerator.savePDFToFiles(testOrder.Id, 'en');

        // End test context
        Test.stopTest();

        // Verify only one document remains for this order
        String prefix = 'Contract Summary - ' + testOrder.OrderNumber;
        List<ContentDocument> remainingDocuments = [
            SELECT Id 
            FROM ContentDocument 
            WHERE Title LIKE :prefix
        ];
        System.assertEquals(1, remainingDocuments.size(), 'Only one document should remain');
        System.assertEquals(newContentDocumentId, remainingDocuments[0].Id, 'Remaining document should be the newly created one');
    }
}