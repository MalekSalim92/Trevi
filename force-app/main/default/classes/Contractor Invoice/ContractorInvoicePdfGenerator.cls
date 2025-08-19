/**
 * ContractorInvoicePdfGenerator
 *
 * Responsible for generating PDF invoices for appointment resources,
 * saving them as ContentVersion, and linking them to relevant records.
 *
 * Author: Malek Brachemi
 * Date: 2025-05-18
 */
public class ContractorInvoicePdfGenerator {

    /**
     * Generates a PDF for the given appointment resources and invoice
     * @param appointmentResourceIds List of Appointment_Resource__c Ids
     * @param invoice Related Contractor_Invoice__c
     * @param settings Contractor_Invoice_Settings__c
     * @return Id of the created ContentDocument
     */
    public static Id generateAndSavePdf(
        List<Id> appointmentResourceIds, 
        Contractor_Invoice__c invoice, 
        Contractor_Invoice_Settings__c settings
    ) {
        try {
            // Fetch at least one resource for metadata (Sage ID)
            List<Appointment_Resource__c> resources = [
                SELECT Id, Resource__r.Account__r.Sage_Id_Number__c, Resource__r.Account__c
                FROM Appointment_Resource__c 
                WHERE Id IN :appointmentResourceIds
                LIMIT 1
            ];
            
            if (resources.isEmpty()) {
                throw new AuraHandledException('No resources found for PDF generation');
            }
            
            // Prepare VF page reference for PDF generation
            PageReference pageRef = Page.Contractor_Invoice;
            pageRef.getParameters().put('resources', String.join(appointmentResourceIds, ','));
            
            Blob pdfBlob;
            if (Test.isRunningTest()) {
                // Dummy PDF content in test context
                pdfBlob = Blob.valueOf('Dummy PDF Content');
            } else {
                pdfBlob = pageRef.getContent();
            }
            
            // Save PDF as ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.VersionData = pdfBlob;
            cv.Title = 'Facture ' + resources[0].Resource__r.Account__r.Sage_Id_Number__c + ' - ' + 
                       System.now().format('yyyyMMdd') + ' - ' + (Decimal.valueOf(settings.Invoice_Number__c) - 1);
            cv.PathOnClient = 'Facture_' + System.now().format() + '.pdf';
            insert cv;
            
            // Get the ContentDocumentId
            Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
            
            // Create links to resources, accounts, and invoice
            createContentDocumentLinks(contentDocId, appointmentResourceIds, invoice.Id);
            
            return contentDocId;
        } catch (Exception e) {
            System.debug('Error generating PDF: ' + e.getMessage());
            System.debug('Stack: ' + e.getStackTraceString());
            throw new AuraHandledException('Error generating PDF: ' + e.getMessage());
        }
    }
    
    /**
     * Creates ContentDocumentLink records for appointment resources, related accounts, and invoice
     * @param contentDocId Id of the ContentDocument
     * @param resourceIds List of Appointment_Resource__c Ids
     * @param invoiceId Id of the related Contractor_Invoice__c
     */
    private static void createContentDocumentLinks(
        Id contentDocId, 
        List<Id> resourceIds, 
        Id invoiceId
    ) {
        List<Appointment_Resource__c> resources = [
            SELECT Id, Resource__r.Account__c, Resource__r.Account__r.Id
            FROM Appointment_Resource__c
            WHERE Id IN :resourceIds
        ];
        
        Set<Id> processedAccountIds = new Set<Id>();
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        
        // Link PDF to each appointment resource and account
        for (Appointment_Resource__c resource : resources) {
            if (resource.Id != null) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = contentDocId,
                    LinkedEntityId = resource.Id,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
                
                // Link PDF to the account only once
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
        
        // Link PDF to the invoice record
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