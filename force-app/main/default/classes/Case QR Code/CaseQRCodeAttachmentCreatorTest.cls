@IsTest
private class CaseQRCodeAttachmentCreatorTest {
    @TestSetup
    static void setupTestData() {
        
        Account testAccount = TestDataFactory.createTestAccount();
        insert testAccount;

        Case testCase = TestDataFactory.createTestCase();
        insert testCase;
    }
    
    @IsTest
    static void testCreateQRCodePDF() {
        // Get the test case
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        
        // Create initial PDF
        Test.startTest();
        CaseQRCodeAttachmentCreator.createQRCodePDF(new List<Id>{testCase.Id});
        Test.stopTest();
        
        // Verify PDF was created
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :testCase.Id
        ];
        System.assertEquals(1, links.size(), 'Should have created one ContentDocumentLink');
        
        List<ContentVersion> versions = [
            SELECT Title 
            FROM ContentVersion 
            WHERE ContentDocumentId = :links[0].ContentDocumentId
        ];
        System.assertEquals(1, versions.size(), 'Should have created one ContentVersion');
        System.assertEquals('Appel de service', versions[0].Title, 'ContentVersion title should match');
    }
}