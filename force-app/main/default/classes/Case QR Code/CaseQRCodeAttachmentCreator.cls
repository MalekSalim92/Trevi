/**
 * Class Name: CaseQRCodeAttachmentCreator
 * Description: 
 *   Creates or updates a Case QR Code PDF and attaches it as a ContentDocument. 
 *   Ensures previous versions with the same title ("Appel de service") are removed 
 *   before creating a new PDF.
 *
 * Author: Malek Brachemi
 * Created Date: 2025-02-04
 * Version: 1.0
 * Notes: Invocable from Flows or Processes; Async processing is used due to callouts.
 */
public class CaseQRCodeAttachmentCreator {
    
    /**
     * Invocable Method: createQRCodePDF
     * Description: 
     *   Entry point for creating QR Code PDFs for given Case records. 
     *   This method is synchronous but delegates work to an async @future method.
     *
     * @param caseIds List<Id> - List of Case record IDs to process.
     */
    @InvocableMethod(label='Create Case QR Code PDF' description='Creates or updates QR code PDF attachment')
    public static void createQRCodePDF(List<Id> caseIds) {
        createQRCodePDFAsync(caseIds);
    }

    /**
     * Future Method: createQRCodePDFAsync
     * Description: 
     *   Handles the actual creation of the Case QR Code PDF documents asynchronously.
     *   - Removes existing documents titled "Appel de service"
     *   - Generates new PDF from Visualforce page
     *   - Inserts ContentVersion records and links them to Cases
     *
     * @param caseIds List<Id> - List of Case record IDs to process.
     */
    @Future(callout=true)
    public static void createQRCodePDFAsync(List<Id> caseIds) {
        
        // Ensure unique Case IDs
        Set<Id> uniqueCaseIds = new Set<Id>(caseIds);
       
        // Retrieve existing ContentDocumentLinks for these Cases
        Map<Id, ContentDocumentLink> caseToDocMap = new Map<Id, ContentDocumentLink>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId IN :uniqueCaseIds
        ]) {
            caseToDocMap.put(cdl.LinkedEntityId, cdl);
        }
 
        // Collect documents to delete (with matching title)
        List<ContentDocument> docsToDelete = new List<ContentDocument>();
        for (ContentDocumentLink cdl : caseToDocMap.values()) {
            docsToDelete.addAll([
                SELECT Id 
                FROM ContentDocument 
                WHERE Id = :cdl.ContentDocumentId 
                AND Title = 'Appel de service'
            ]);
        }
        
        if (!docsToDelete.isEmpty()) {
            delete docsToDelete;
        }

        List<ContentVersion> versionsToInsert = new List<ContentVersion>();
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
            
        // Retrieve Cases
        Map<Id, Case> casesMap = new Map<Id, Case>([
            SELECT Id, CaseNumber, Choice_of_store__c, Choice_of_store__r.Name
            FROM Case
            WHERE Id IN :uniqueCaseIds
        ]);

        // Build PDF ContentVersion for each Case
        for (Id caseId : uniqueCaseIds) {
            Case currentCase = casesMap.get(caseId);
            
            PageReference pdfPage = Page.CaseQRCodePage;
            pdfPage.getParameters().put('id', caseId);
            String storeName = (currentCase.Choice_of_store__r != null) 
                ? currentCase.Choice_of_store__r.Name 
                : '';
            pdfPage.getParameters().put('storeName', storeName);

            ContentVersion cv = new ContentVersion();
            cv.Title = 'Appel de service';
            cv.PathOnClient = 'AppelDeService.pdf';
            cv.VersionData = Test.isRunningTest() ? Blob.valueOf('Test PDF Content') : pdfPage.getContentAsPDF();
            cv.IsMajorVersion = true;
            versionsToInsert.add(cv);
        }
        
        insert versionsToInsert;
        
        // Map Version Id to Document Id
        Map<Id, Id> versionToDocIdMap = new Map<Id, Id>();
        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :versionsToInsert
        ]) {
            versionToDocIdMap.put(cv.Id, cv.ContentDocumentId);
        }
        
        // Link each Case to its new ContentDocument
        Integer i = 0;
        for (Id caseId : uniqueCaseIds) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = versionToDocIdMap.get(versionsToInsert[i].Id);
            cdl.LinkedEntityId = caseId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers'; 
            linksToInsert.add(cdl);
            i++;
        }
        
        insert linksToInsert;
    }
}