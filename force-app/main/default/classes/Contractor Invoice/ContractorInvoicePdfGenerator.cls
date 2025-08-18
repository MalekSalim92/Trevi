public class ContractorInvoicePdfGenerator {

    
    public static Id generateAndSavePdf(List<Id> appointmentResourceIds, Contractor_Invoice__c invoice, Contractor_Invoice_Settings__c settings) {
        try {
            // Get the resources for the PDF
            List<Appointment_Resource__c> resources = [
                SELECT Id, Resource__r.Account__r.Sage_Id_Number__c, Resource__r.Account__c, Resource__r.Account__r.Id,Order__c,Order__r.Order_Number__c
                FROM Appointment_Resource__c 
                WHERE Id IN :appointmentResourceIds
                LIMIT 1
            ];
            
            if (resources.isEmpty()) {
                throw new AuraHandledException('No resources found for PDF generation');
            }
            
            // Generate PDF
            PageReference pageRef = Page.Contractor_Invoice;
            pageRef.getParameters().put('resources', String.join(appointmentResourceIds, ','));
            
            Blob pdfBlob;
            if (Test.isRunningTest()) {
                // In test context, create a dummy PDF blob
                pdfBlob = Blob.valueOf('Dummy PDF Content');
            } else {
                pdfBlob = pageRef.getContent();
            }
            
            // Save as ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.VersionData = pdfBlob;
            cv.Title = 'Facture ' + resources[0].Resource__r.Account__r.Sage_Id_Number__c + ' - ' + 
                      System.now().format('yyyyMMdd') + ' - ' + (Decimal.valueOf(settings.Invoice_Number__c) - 1);
            cv.PathOnClient = 'Facture_' + System.now().format() + '.pdf';
            insert cv;
            
            // Get ContentDocumentId
            Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
            
            // Create ContentDocumentLinks
            createContentDocumentLinks(contentDocId, appointmentResourceIds, invoice.Id);
            
            return contentDocId;
        } catch (Exception e) {
            System.debug('Error generating PDF: ' + e.getMessage());
            System.debug('Stack: ' + e.getStackTraceString());
            throw new AuraHandledException('Error generating PDF: ' + e.getMessage());
        }
    }
    
    /**
     * Creates ContentDocumentLinks for resources, accounts, and invoice
     */
    private static void createContentDocumentLinks(Id contentDocId, List<Id> resourceIds, Id invoiceId) {
        // Query resources with their account info
        List<Appointment_Resource__c> resources = [
            SELECT Id, Resource__r.Account__c, Resource__r.Account__r.Id,Order__c,Order__r.Order_Number__c
            FROM Appointment_Resource__c
            WHERE Id IN :resourceIds
        ];
        
        Set<Id> processedAccountIds = new Set<Id>();
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        
        // Create links for each resource
        for (Appointment_Resource__c resource : resources) {
            if (resource.Id != null) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = contentDocId,
                    LinkedEntityId = resource.Id,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
                
                // Create link for the account if not already done
                if (resource.Resource__r.Account__r.Id != null && 
                    !processedAccountIds.contains(resource.Resource__r.Account__r.Id)) {
                    links.add(new ContentDocumentLink(
                        ContentDocumentId = contentDocId,
                        LinkedEntityId = resource.Resource__r.Account__r.Id,
                        ShareType = 'V',
                        Visibility = 'AllUsers'
                    ));
                    processedAccountIds.add(resource.Resource__r.Account__r.Id);
                }
            }
        }
        
        // Create link for the invoice
        if (invoiceId != null) {
            links.add(new ContentDocumentLink(
                ContentDocumentId = contentDocId,
                LinkedEntityId = invoiceId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
        }
        
        if (!links.isEmpty()) {
            insert links;
        }
    }
}