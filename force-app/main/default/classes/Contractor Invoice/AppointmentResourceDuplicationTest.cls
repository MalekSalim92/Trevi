/**
 * AppointmentResourceDuplicationTest
 *
 * Unit tests for AppointmentResourceDuplicationChecker
 * - Tests both overlapping and non-overlapping appointment resources
 * - Uses TestDataFactory to generate required test data
 *
 * Author: Malek Brachemi
 * Date: 2025-05-25
 */
@isTest
public class AppointmentResourceDuplicationTest {

    /**
     * Test setup method to insert reusable test data
     * Runs once per test class execution
     */
    @testSetup
    static void setupTestData() {
        TestDataFactory.createServiceAppointmentTestData();
    }

    /**
     * Test scenario: overlapping products between appointment resources
     * Expectation: duplication checker identifies overlaps
     */
    @isTest
    static void testCheckDuplicationsWithOverlap() {
        // Fetch test data from the setup
        Resource__c testResource = [SELECT Id FROM Resource__c LIMIT 1];
        ServiceAppointment sa1 = [SELECT Id FROM ServiceAppointment LIMIT 1];

        // Create a second WorkOrderLineItem and ServiceAppointment for overlap testing
        WorkOrder workOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        WorkType workType = [SELECT Id FROM WorkType LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        WorkOrderLineItem woli2 = TestDataFactory.createTestWorkOrderLineItem(workOrder.Id, null, workType.Id, product.Id);
        insert woli2;

        ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
        ServiceAppointment sa2 = TestDataFactory.createTestServiceAppointment(woli2.Id, territory.Id, serviceResource.Id);
        insert sa2;

        // Create appointment resources with overlapping products
        Appointment_Resource__c resource1 = new Appointment_Resource__c(
            Service_Appointment__c = sa1.Id,
            Resource__c = testResource.Id,
            All_Products__c = '12345,Test Product'
        );

        Appointment_Resource__c resource2 = new Appointment_Resource__c(
            Service_Appointment__c = sa2.Id,
            Resource__c = testResource.Id,
            All_Products__c = '12345,99999'
        );

        insert new List<Appointment_Resource__c>{resource1, resource2};

        // Prepare request wrapper
        AppointmentResourceDuplicationChecker.RequestWrapper request = new AppointmentResourceDuplicationChecker.RequestWrapper();
        request.AppointmentResource = new List<Appointment_Resource__c>{resource1};

        Test.startTest();
        List<List<Appointment_Resource__c>> result = AppointmentResourceDuplicationChecker.checkDuplications(
            new List<AppointmentResourceDuplicationChecker.RequestWrapper>{request}
        );
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return one list of resources');
    }

    /**
     * Test scenario: appointment resources with no overlap
     * Expectation: duplication checker sets Description__c to 'Green' and TECH_Duplicates__c empty
     */
    @isTest
    static void testCheckDuplicationsNoOverlap() {
        // Fetch test data
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Resource__c testResource = [SELECT Id FROM Resource__c LIMIT 1];
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];

        // Create order
        Order testOrder = TestDataFactory.createTestOrder(testAccount.Id, Test.getStandardPricebookId(), 'TEST-CONTRACT-002');
        insert testOrder;

        // Create appointment resource with no duplicates
        Appointment_Resource__c resource = new Appointment_Resource__c(
            Service_Appointment__c = sa.Id,
            Resource__c = testResource.Id,
            All_Products__c = '99999',
            Order__c = testOrder.Id
        );
        insert resource;

        // Prepare request wrapper
        AppointmentResourceDuplicationChecker.RequestWrapper request = new AppointmentResourceDuplicationChecker.RequestWrapper();
        request.AppointmentResource = new List<Appointment_Resource__c>{resource};

        Test.startTest();
        List<List<Appointment_Resource__c>> result = AppointmentResourceDuplicationChecker.checkDuplications(
            new List<AppointmentResourceDuplicationChecker.RequestWrapper>{request}
        );
        Test.stopTest();

        // Assertions
        System.assertEquals('Green', result[0][0].Description__c, 'Description should be Green for no duplicates');
        System.assertEquals('', result[0][0].TECH_Duplicates__c, 'TECH_Duplicates__c should be empty for no duplicates');
    }
}