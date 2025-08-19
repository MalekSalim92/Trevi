/**
 * ContractorInvoiceControllerTest
 *
 * Unit tests for ContractorInvoiceController
 * - Tests controller initialization with VF page parameters
 * - Verifies resource count methods
 * - Verifies total calculations (subtotal, TPS, TVQ, total with taxes)
 *
 * Author: Malek Brachemi
 * Date: 2025-05-08
 */
@isTest
private class ContractorInvoiceControllerTest {

    /**
     * Test setup method to insert reusable test data
     * Runs once per test class execution
     */
    @TestSetup
    static void createTestData() {
        FSL.GlobalAPIS.addStatusTransition('Requested', 'Scheduled');
        TestDataFactory.createServiceAppointmentTestData();
    }

    /**
     * Test scenario: controller initialization from VF page parameters
     * Expectation: maps and lists are correctly initialized
     */
    @isTest
    static void testControllerInitialization() {
        // Arrange: get a sample Appointment Resource
        List<Appointment_Resource__c> testResources = [
            SELECT Id FROM Appointment_Resource__c LIMIT 1
        ];

        // Simulate VF page parameters
        PageReference testPage = Page.Contractor_Invoice;
        Test.setCurrentPage(testPage);
        ApexPages.currentPage().getParameters().put('resources', testResources[0].Id);

        ApexPages.StandardController stdController = new ApexPages.StandardController(testResources[0]);

        // Act: instantiate controller
        Test.startTest();
        ContractorInvoiceController controller = new ContractorInvoiceController(stdController);
        Test.stopTest();

        // Assert: controller properties are initialized
        System.assertNotEquals(null, controller.resourcesByAppointment, 'Resources by appointment should be initialized');
        System.assertNotEquals(null, controller.subtotalsByAppointment, 'Subtotals by appointment should be initialized');
        System.assertNotEquals(0, controller.serviceAppointmentIds.size(), 'Service appointment IDs should be populated');
    }

    /**
     * Test scenario: resource count methods
     * Expectation: resourceCounts map and getResourceCountForSA method return correct values
     */
    @isTest
    static void testResourceCountMethods() {
        // Arrange
        List<Appointment_Resource__c> testResources = [
            SELECT Id, Service_Appointment__c FROM Appointment_Resource__c LIMIT 1
        ];

        PageReference testPage = Page.Contractor_Invoice;
        Test.setCurrentPage(testPage);
        ApexPages.currentPage().getParameters().put('resources', testResources[0].Id);

        ApexPages.StandardController stdController = new ApexPages.StandardController(testResources[0]);

        // Act
        Test.startTest();
        ContractorInvoiceController controller = new ContractorInvoiceController(stdController);
        Map<String, Integer> resourceCounts = controller.resourceCounts;
        Integer resourceCountForSA = controller.getResourceCountForSA(String.valueOf(testResources[0].Service_Appointment__c));
        Test.stopTest();

        // Assert: counts map is not null and contains correct values
        System.assertNotEquals(null, resourceCounts, 'Resource counts map should not be null');
        System.assertEquals(resourceCountForSA, resourceCounts.get(String.valueOf(testResources[0].Service_Appointment__c)), 'Resource count should match expected value');
    }

    /**
     * Test scenario: total calculations (subtotal, TPS, TVQ, total with taxes)
     * Expectation: calculation properties return correct sums based on resources
     */
    @isTest
    static void testTotalCalculations() {
        // Arrange: fetch a test Appointment Resource
        List<Appointment_Resource__c> testResources = [
            SELECT Id, Service_Appointment__c, Fee_Amount__c, Fixed_Fee__c, Special_Tariffication_Fee__c, Bonus__c, Total__c 
            FROM Appointment_Resource__c LIMIT 1
        ];

        PageReference testPage = Page.Contractor_Invoice;
        Test.setCurrentPage(testPage);
        ApexPages.currentPage().getParameters().put('resources', testResources[0].Id);

        ApexPages.StandardController stdController = new ApexPages.StandardController(testResources[0]);

        // Act
        Test.startTest();
        ContractorInvoiceController controller = new ContractorInvoiceController(stdController);
        Test.stopTest();

        // Dynamically calculate expected totals based on the inserted record
        Decimal expectedSubtotal = testResources[0].Total__c != null ? testResources[0].Total__c : 0;
        Decimal expectedTPS = expectedSubtotal * 0.05;
        Decimal expectedTVQ = expectedSubtotal * 0.09975;
        Decimal expectedTotalWithTax = expectedSubtotal + expectedTPS + expectedTVQ;

        // Assert: verify controller totals
        System.assertEquals(expectedSubtotal, controller.totalSubtotal, 'Subtotal should match expected value');
        System.assertEquals(expectedTPS, controller.totalTPS, 'TPS should match expected value');
        System.assertEquals(expectedTVQ, controller.totalTVQ, 'TVQ should match expected value');
        System.assertEquals(expectedTotalWithTax, controller.finalTotalWithTax, 'Total with tax should match expected value');
    }
}