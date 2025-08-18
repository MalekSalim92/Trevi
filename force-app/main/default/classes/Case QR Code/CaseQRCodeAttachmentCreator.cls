public class CaseQRCodeAttachmentCreator {
    @InvocableMethod(label='Create Case QR Code PDF' description='Creates or updates QR code PDF attachment')
    public static void createQRCodePDF(List<Id> caseIds) {
        createQRCodePDFAsync(caseIds);

        }
        @Future(callout=true)
        public static void createQRCodePDFAsync(List<Id> caseIds) {

        Set<Id> uniqueCaseIds = new Set<Id>(caseIds);
        system.debug('uniqueCaseIds ' + uniqueCaseIds);
      
        Map<Id, ContentDocumentLink> caseToDocMap = new Map<Id, ContentDocumentLink>();
        for(ContentDocumentLink cdl : [SELECT ContentDocumentId, LinkedEntityId 
                                     FROM ContentDocumentLink 
                                     WHERE LinkedEntityId IN :uniqueCaseIds]) {
            caseToDocMap.put(cdl.LinkedEntityId, cdl);
        }
        system.debug('caseToDocMap ' + caseToDocMap);

        List<ContentDocument> docsToDelete = new List<ContentDocument>();
        for(ContentDocumentLink cdl : caseToDocMap.values()) {
            docsToDelete.addAll([SELECT Id FROM ContentDocument 
                               WHERE Id = :cdl.ContentDocumentId AND Title = 'Appel de service']);
        }
        
        if(!docsToDelete.isEmpty()) {
            delete docsToDelete;
        }
        List<ContentVersion> versionsToInsert = new List<ContentVersion>();
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        
            
        Map<Id, Case> casesMap = new Map<Id, Case>([
            SELECT Id, CaseNumber, Choice_of_store__c, Choice_of_store__r.Name
            FROM Case
            WHERE Id IN :uniqueCaseIds
        ]);

        for(Id caseId : uniqueCaseIds) {

            Case currentCase = casesMap.get(caseId);
            
            PageReference pdfPage = Page.CaseQRCodePage;
            pdfPage.getParameters().put('id', caseId);
            String storeName = (currentCase.Choice_of_store__r != null) ? currentCase.Choice_of_store__r.Name : '';
            pdfPage.getParameters().put('storeName', storeName);

            ContentVersion cv = new ContentVersion();
            cv.Title = 'Appel de service';
            cv.PathOnClient = 'AppelDeService.pdf';
            if(Test.isRunningTest()) {
                cv.VersionData = Blob.valueOf('Test PDF Content');
            } else {
                cv.VersionData = pdfPage.getContentAsPDF();
            }
            cv.IsMajorVersion = true;
            versionsToInsert.add(cv);
        }
        
        insert versionsToInsert;
        
        Map<Id, Id> versionToDocIdMap = new Map<Id, Id>();
        for(ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :versionsToInsert]) {
            versionToDocIdMap.put(cv.Id, cv.ContentDocumentId);
        }
        
        Integer i = 0;
        for(Id caseId : uniqueCaseIds) {
           

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

