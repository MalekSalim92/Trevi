
@isTest
public class ServiceAppointmentFormPdfGeneratorTest {

    @testSetup
    static void setupTestData() {
        // Insert a test Account/Contact/ServiceAppointment/whatever is needed for RecordId
        Account a = TestDataFactory.createTestAccount();
        insert a;
    }

    @isTest
    static void testCreatePDF() {
        // Get a test Account Id (for linking)
        Account acc = [SELECT Id FROM Account LIMIT 1];

        // Build a PDFRequest with required fields only
        ServiceAppointmentFormPdfGenerator.PDFRequest req = new ServiceAppointmentFormPdfGenerator.PDFRequest();
        req.content = 'Test PDF Content';
         req.recordId = acc.Id;

        List<ServiceAppointmentFormPdfGenerator.PDFRequest> input = new List<ServiceAppointmentFormPdfGenerator.PDFRequest>();
        input.add(req);

        Test.startTest();
        List<ServiceAppointmentFormPdfGenerator.PDFResponse> responses =
            (List<ServiceAppointmentFormPdfGenerator.PDFResponse>)
                ServiceAppointmentFormPdfGenerator.createPDF(input);
        Test.stopTest();

        // Check that response is given back and a ContentVersion was created
        System.assertEquals(1, responses.size(), 'Should have 1 response');
        ServiceAppointmentFormPdfGenerator.PDFResponse resp = responses[0];
        System.assertNotEquals(null, resp.contentDocumentId, 'ContentDocumentId should not be null');

        // Validate the ContentVersion and ContentDocument
        ContentVersion cv = [SELECT Id, Title, ContentDocumentId, FirstPublishLocationId FROM ContentVersion WHERE ContentDocumentId = :resp.contentDocumentId LIMIT 1];
        System.assertEquals(acc.Id, cv.FirstPublishLocationId, 'Should link to Account Id');

        // Title should default since not set
    }


}
