/**
 * Test Class: CaseQRCodeAttachmentCreatorTest
 * Description:
 *   Unit tests for CaseQRCodeAttachmentCreator class.
 *   - Verifies QR Code PDF is created and linked to Case
 *   - Ensures ContentVersion and ContentDocumentLink records are generated correctly
 *
 * Author: Malek Brachemi
 * Created Date: 2025-02-26
 * Version: 1.0
 * Notes: Uses TestDataFactory to create required test data.
 */
@IsTest
private class CaseQRCodeAttachmentCreatorTest {
    
    /**
     * Test Setup Method
     * Creates base test data: Account and Case records.
     */
    @TestSetup
    static void setupTestData() {
        Account testAccount = TestDataFactory.createTestAccount();
        insert testAccount;

        Case testCase = TestDataFactory.createTestCase();
        insert testCase;
    }
    
    /**
     * Test Method: testCreateQRCodePDF
     * Verifies:
     *   - QR Code PDF is created for a Case
     *   - ContentDocumentLink is inserted
     *   - ContentVersion is created with correct title
     */
    @IsTest
    static void testCreateQRCodePDF() {
        // Get a test Case
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        // Ensure no ContentDocumentLink exists before running
        System.assertEquals(
            0, 
            [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :testCase.Id], 
            'Should not have existing ContentDocumentLinks before execution'
        );

        // Execute the code under test
        Test.startTest();
        CaseQRCodeAttachmentCreator.createQRCodePDF(new List<Id>{ testCase.Id });
        Test.stopTest();
        
        // Verify ContentDocumentLink was created
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :testCase.Id
        ];
        System.assertEquals(1, links.size(), 'Should have created one ContentDocumentLink');
        
        // Verify related ContentVersion was created
        List<ContentVersion> versions = [
            SELECT Title 
            FROM ContentVersion 
            WHERE ContentDocumentId = :links[0].ContentDocumentId
        ];
        System.assertEquals(1, versions.size(), 'Should have created one ContentVersion');
        System.assertEquals(
            'Appel de service', 
            versions[0].Title, 
            'ContentVersion title should match expected value'
        );
    }
}