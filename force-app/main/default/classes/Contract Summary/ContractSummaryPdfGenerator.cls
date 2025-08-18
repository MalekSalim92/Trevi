public with sharing class ContractSummaryPdfGenerator {
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
               WHERE 
                   LinkedEntityId = :recordId 
                   AND ContentDocument.Title LIKE :titlePrefix + '%'
           ];
   
           // If there are existing links
           if (!contentDocumentLinkList.isEmpty()) {
               // Collect the ContentDocument IDs
               List<Id> docIdList = new List<Id>();
               for (ContentDocumentLink cdl : contentDocumentLinkList) {
                   docIdList.add(cdl.ContentDocumentId);
               }
   
               // Find the actual ContentDocuments
               List<ContentDocument> existingDocuments = [
                   SELECT Id 
                   FROM ContentDocument 
                   WHERE Id IN :docIdList
               ];
   
               // Delete existing documents
               if (!existingDocuments.isEmpty()) {
                   delete existingDocuments;
               }
           }
                        
            Blob pdfBlob;
            if (Test.isRunningTest()) {
                // Use a mock blob for test context
                pdfBlob = Blob.valueOf('Test PDF Content');
            } else {
                // Normal PDF generation
                PageReference pdfPage = language == 'en' ? Page.ContractSummary_En : Page.ContractSummary;
                pdfPage.getParameters().put('id', recordId);
                pdfBlob = pdfPage.getContent();
            }

            // Prepare the ContentVersion
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = titlePrefix;
            contentVersion.PathOnClient = 'ContractSummary_' + recordId + '.pdf';
            contentVersion.VersionData = pdfBlob;
            
            // Link the file to the Order
            contentVersion.FirstPublishLocationId = recordId;
            
            // Insert the ContentVersion
            insert contentVersion;
            
            // Retrieve the ContentDocumentId
            ContentVersion insertedCV = [
                SELECT ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :contentVersion.Id
            ];
            
            return insertedCV.ContentDocumentId;
        } catch (Exception e) {
            // Log the error
            System.debug('Error saving PDF: ' + e.getMessage());
            
            // Throw a more user-friendly error
            throw new AuraHandledException('Failed to save PDF: ' + e.getMessage());
        }
    }
}