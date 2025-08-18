@isTest
private class ContractorInvoiceInvocableTest {
    
    @TestSetup
    static void createTestData() {
        FSL.GlobalAPIS.addStatusTransition('Requested', 'Scheduled');
        TestDataFactory.createServiceAppointmentTestData();
    }
    
    @isTest
    static void testInvocableMethod() {
        // Set up test data
        List<Appointment_Resource__c> resources = [SELECT Id FROM Appointment_Resource__c LIMIT 3];
        List<Id> resourceIds = new List<Id>();
        for(Appointment_Resource__c resource : resources) {
            resourceIds.add(resource.Id);
        }
        
        // Call the invocable method
        Test.startTest();
        ContractorInvoiceInvocable.generateAndSavePDF(new List<List<Id>>{resourceIds});
        Test.stopTest();
        
        // Check that resources were updated
        List<Appointment_Resource__c> updatedResources = [
            SELECT Is_Invoiced__c, Invoice_Number__c 
            FROM Appointment_Resource__c 
            WHERE Id IN :resourceIds
        ];
        
        for(Appointment_Resource__c resource : updatedResources) {
            System.assertEquals(true, resource.Is_Invoiced__c, 'Resource should be marked as invoiced');
            System.assertNotEquals(null, resource.Invoice_Number__c, 'Resource should have an invoice number');
        }
        
     }
    
    @isTest
    static void testInvocableMethodWithEmptyInput() {
        // Test with empty input
        Test.startTest();
        ContractorInvoiceInvocable.generateAndSavePDF(new List<List<Id>>());
        Test.stopTest();
        
     }
}