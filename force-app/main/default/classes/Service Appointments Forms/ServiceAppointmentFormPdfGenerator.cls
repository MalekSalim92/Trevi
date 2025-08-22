/**
 * Class Name: ServiceAppointmentFormPdfGenerator
 * Description: 
 *   Generates PDF documents for Service Appointment records using a Visualforce page. 
 *   The generated PDF is saved as a ContentVersion and optionally linked to a related record.
 *
 * Author: Malek Brachemi
 * Created Date: 2025-05-19
 * Version: 1.0
 * Notes: 
 *   - Invocable from Flows or Processes
 *   - Supports multiple requests in a single execution
 *   - Uses VF page "ServiceAppointmentSummaryResponses" to render PDF content
 */
public class ServiceAppointmentFormPdfGenerator {
    
    /**
     * Inner Class: PDFRequest
     * Description: 
     *   Defines the input structure for PDF generation.
     *   Passed by Flow or Process Builder to specify PDF content and metadata.
     */
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
    
    /**
     * Inner Class: PDFResponse
     * Description: 
     *   Defines the output structure returned after PDF generation.
     */
    public class PDFResponse {
        @InvocableVariable(label='Content Document ID')
        public String contentDocumentId;
    }
    
    /**
     * Invocable Method: createPDF
     * Description: 
     *   Generates PDF documents for the given requests.
     *   - Uses VF page "ServiceAppointmentSummaryResponses"
     *   - Stores PDF as ContentVersion
     *   - Optionally links to a record if RecordId is provided
     *
     * @param requests List<PDFRequest> - Collection of requests with PDF details
     * @return List<PDFResponse> - Collection of responses containing ContentDocument IDs
     */
    @InvocableMethod(label='Create Service Appointment PDF Document')
    public static List<PDFResponse> createPDF(List<PDFRequest> requests) {
        List<PDFResponse> responses = new List<PDFResponse>();
        
        for(PDFRequest request : requests) {
            
            //  Determine final title (fallback if not provided)
            String finalTitle = String.isNotBlank(request.title) 
                ? request.title 
                : 'Service Appointment Summary';
            
            //  Prepare Visualforce page reference
            PageReference pdfPage = Page.ServiceAppointmentSummaryResponses;
            pdfPage.getParameters().put('title', finalTitle);
            pdfPage.getParameters().put('status', request.status);
            pdfPage.getParameters().put('content', request.content);
            
            //  Generate PDF blob
            Blob pdfBlob = Test.isRunningTest() 
                ? Blob.valueOf('Test PDF Content')   // dummy content in test context
                : pdfPage.getContentAsPDF();
            
            //  Determine file name (fallback if not provided)
            String finalFileName = String.isNotBlank(request.fileName) 
                ? request.fileName 
                : 'Service_Appointment_' + DateTime.now().format('yyyy_MM_dd_HH_mm');
            
            //  Create ContentVersion record
            ContentVersion cv = new ContentVersion();
            cv.Title = finalFileName;
            cv.PathOnClient = finalFileName + '.pdf';
            cv.VersionData = pdfBlob;
            
            // Link document to record if provided
            if(String.isNotBlank(request.recordId)) {
                cv.FirstPublishLocationId = request.recordId;
            }
            
            insert cv;
            
            //  Retrieve ContentDocumentId
            ContentVersion insertedCV = [
                SELECT ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :cv.Id
            ];
            
            // Build response
            PDFResponse response = new PDFResponse();
            response.contentDocumentId = insertedCV.ContentDocumentId;
            responses.add(response);
        }
        
        return responses;
    }
}