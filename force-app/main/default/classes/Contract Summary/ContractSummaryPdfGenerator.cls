/**
 * ContractSummaryPdfGenerator
 *
 * Generates a Contract Summary PDF for a given Order and saves it to Salesforce Files.
 * Handles:
 *   - Removing previously generated PDFs with the same Order number
 *   - Generating PDF in different languages (English / default)
 *   - Saving as ContentVersion and linking to the Order
 *
 * Author: Malek Brachemi
 * Date: 2025-02-26
 */
public with sharing class ContractSummaryPdfGenerator {

    /**
     * Generates a PDF for the given Order and saves it to Salesforce Files.
     * If a file with the same title exists, it is deleted before creating the new version.
     *
     * @param recordId The Id of the Order record
     * @param language The language for the PDF ('en' for English, otherwise default)
     * @return ContentDocumentId of the inserted PDF
     * @throws AuraHandledException if PDF generation or file insertion fails
     */
    @AuraEnabled
    public static Id savePDFToFiles(Id recordId, String language) {
        try {
            // Get Order Number for naming
            Order order = [SELECT OrderNumber FROM Order WHERE Id = :recordId LIMIT 1];
            String titlePrefix = 'Contract Summary - ' + order.OrderNumber;

            // Find existing ContentDocumentLinks for this Order with matching title
            List<ContentDocumentLink> contentDocumentLinkList = [
                SELECT Id, ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :recordId 
                AND ContentDocument.Title LIKE :titlePrefix + '%'
            ];

            // Delete existing documents if any
            if (!contentDocumentLinkList.isEmpty()) {
                List<Id> docIdList = new List<Id>();
                for (ContentDocumentLink cdl : contentDocumentLinkList) {
                    docIdList.add(cdl.ContentDocumentId);
                }

                List<ContentDocument> existingDocuments = [
                    SELECT Id 
                    FROM ContentDocument 
                    WHERE Id IN :docIdList
                ];

                if (!existingDocuments.isEmpty()) {
                    delete existingDocuments;
                }
            }

            // Generate PDF content
            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Test PDF Content'); // Mock PDF content for test
            } else {
                PageReference pdfPage = language == 'en' ? Page.ContractSummary_En : Page.ContractSummary;
                pdfPage.getParameters().put('id', recordId);
                pdfBlob = pdfPage.getContent();
            }

            // Prepare ContentVersion for insertion
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = titlePrefix;
            contentVersion.PathOnClient = 'ContractSummary_' + recordId + '.pdf';
            contentVersion.VersionData = pdfBlob;
            contentVersion.FirstPublishLocationId = recordId;

            insert contentVersion;

            // Retrieve the ContentDocumentId from the inserted version
            ContentVersion insertedCV = [
                SELECT ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :contentVersion.Id
            ];

            return insertedCV.ContentDocumentId;

        } catch (Exception e) {
            System.debug('Error saving PDF: ' + e.getMessage());
            throw new AuraHandledException('Failed to save PDF: ' + e.getMessage());
        }
    }
}