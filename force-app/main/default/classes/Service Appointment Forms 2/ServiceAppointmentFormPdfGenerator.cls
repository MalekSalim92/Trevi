public class ServiceAppointmentFormPdfGenerator {
    
    public class PDFRequest {
        @InvocableVariable(label='PDF Content' required=true)
        public String content;
        
        @InvocableVariable(label='Status' required=true)
        public String status;
        
        @InvocableVariable(label='Title')
        public String title;
        
        @InvocableVariable(label='File Name')
        public String fileName;

        @InvocableVariable(label='Record ID to Link')
        public String recordId;
    }
    
    public class PDFResponse {
        @InvocableVariable(label='Content Document ID')
        public String contentDocumentId;
    }
    
    @InvocableMethod(label='Create Service Appointment PDF Document')
    public static List<PDFResponse> createPDF(List<PDFRequest> requests) {
        List<PDFResponse> responses = new List<PDFResponse>();
        
        for(PDFRequest request : requests) {
            // Create final title
            String finalTitle = String.isNotBlank(request.title) ? request.title : 'Service Appointment Summary';
            
            // Use Visualforce page to generate PDF
            PageReference pdfPage = Page.ServiceAppointmentSummaryResponses;
            
            // Pass parameters to the VF page
            pdfPage.getParameters().put('title', finalTitle);
            pdfPage.getParameters().put('status', request.status);
            pdfPage.getParameters().put('content', request.content);
            
            // Generate PDF from Visualforce page
            Blob pdfBlob;
            if(Test.isRunningTest()) {
                // For test context, create a dummy PDF
                pdfBlob = Blob.valueOf('Test PDF Content');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }
            
            // Create file name
            String finalFileName = String.isNotBlank(request.fileName) ? 
                request.fileName : 
                'Service_Appointment_' + DateTime.now().format('yyyy_MM_dd_HH_mm');
            
            // Create ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.Title = finalFileName;
            cv.PathOnClient = finalFileName + '.pdf';
            cv.VersionData = pdfBlob;
            if(String.isNotBlank(request.recordId)) {
                cv.FirstPublishLocationId = request.recordId;
            }
            
            insert cv;
            
            // Get ContentDocument ID
            ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
            
            PDFResponse response = new PDFResponse();
            response.contentDocumentId = insertedCV.ContentDocumentId;
            responses.add(response);
        }
        
        return responses;
    }
}