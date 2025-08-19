/**
 * Class Name: ServiceAppointmentFormPdfGeneratorTest
 * Description: 
 *   Unit tests for the ServiceAppointmentFormPdfGenerator class.
 *   Validates PDF generation, ContentVersion creation, and linking to records.
 *
 * Author: Malek Brachemi
 * Created Date: 2025-05-19
 * Version: 1.0
 * Notes: 
 *   - Uses a test Account as the target record for linking
 *   - Verifies defaults (e.g., title fallback) and ContentDocumentId creation
 */
@IsTest
public class ServiceAppointmentFormPdfGeneratorTest {

    /**
     * Test Setup: Creates base data required for tests
     * - Inserts a single Account to use as RecordId link target
     */
    @TestSetup
    static void setupTestData() {
        Account a = TestDataFactory.createTestAccount();
        insert a;
    }

    /**
     * Test Method: testCreatePDF
     * Description:
     *   Validates PDF generation when a request is provided:
     *   - Ensures a ContentDocument is created
     *   - Verifies linking to the provided RecordId
     *   - Confirms ContentDocumentId is returned in response
     */
    @IsTest
    static void testCreatePDF() {
        // Get Account Id created in @TestSetup
        Account acc = [SELECT Id FROM Account LIMIT 1];

        // Build PDF request with minimum required fields
        ServiceAppointmentFormPdfGenerator.PDFRequest req = new ServiceAppointmentFormPdfGenerator.PDFRequest();
        req.content = 'Test PDF Content';
        req.status  = 'Completed';   // required field
        req.recordId = acc.Id;       // link document to Account

        List<ServiceAppointmentFormPdfGenerator.PDFRequest> input = new List<ServiceAppointmentFormPdfGenerator.PDFRequest>{ req };

        //  Invoke PDF generation
        Test.startTest();
        List<ServiceAppointmentFormPdfGenerator.PDFResponse> responses =
            ServiceAppointmentFormPdfGenerator.createPDF(input);
        Test.stopTest();

        // Assertions
        System.assertEquals(1, responses.size(), 'Should return 1 response');
        
        ServiceAppointmentFormPdfGenerator.PDFResponse resp = responses[0];
        System.assertNotEquals(null, resp.contentDocumentId, 'ContentDocumentId must not be null');

        // Validate ContentVersion record was created and linked properly
        ContentVersion cv = [
            SELECT Id, Title, ContentDocumentId, FirstPublishLocationId 
            FROM ContentVersion 
            WHERE ContentDocumentId = :resp.contentDocumentId 
            LIMIT 1
        ];
        
        System.assertEquals(acc.Id, cv.FirstPublishLocationId, 'PDF should be linked to the Account');
        System.assert(cv.Title.startsWith('Service_Appointment_') || cv.Title.contains('Test'), 
            'Title should either default or use a provided value');
    }
}