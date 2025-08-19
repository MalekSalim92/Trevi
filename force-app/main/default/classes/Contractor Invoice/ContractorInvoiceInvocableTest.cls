/**
 * ContractorInvoiceInvocableTest
 *
 * Unit tests for ContractorInvoiceInvocable
 * - Tests the generateAndSavePDF invocable method
 * - Covers normal scenario with resources and empty input scenario
 *
 * Author: Malek Brachemi
 * Date: 2025-05-18
 */
@isTest
private class ContractorInvoiceInvocableTest {

    /**
     * Test setup method to insert reusable test data
     * Runs once per test class execution
     */
    @TestSetup
    static void createTestData() {
        // Add status transitions needed for FSL Service Appointments
        FSL.GlobalAPIS.addStatusTransition('Requested', 'Scheduled');

        // Insert standard test data including ServiceAppointments and Resources
        TestDataFactory.createServiceAppointmentTestData();
    }

    /**
     * Test scenario: normal invocable method execution
     * Expectation: resources are marked as invoiced and assigned invoice numbers
     */
    @isTest
    static void testInvocableMethod() {
        // Fetch some test resources
        List<Appointment_Resource__c> resources = [SELECT Id FROM Appointment_Resource__c LIMIT 3];
        List<Id> resourceIds = new List<Id>();
        for(Appointment_Resource__c resource : resources) {
            resourceIds.add(resource.Id);
        }

        // Call the invocable method with valid input
        Test.startTest();
        ContractorInvoiceInvocable.generateAndSavePDF(new List<List<Id>>{resourceIds});
        Test.stopTest();

        // Assert that resources were updated as expected
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

    /**
     * Test scenario: empty input list
     * Expectation: method completes without errors
     */
    @isTest
    static void testInvocableMethodWithEmptyInput() {
        // Call the invocable method with empty input
        Test.startTest();
        ContractorInvoiceInvocable.generateAndSavePDF(new List<List<Id>>());
        Test.stopTest();

        // No exceptions should occur, so nothing to assert
    }
}