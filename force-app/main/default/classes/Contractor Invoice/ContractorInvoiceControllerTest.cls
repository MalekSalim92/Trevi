@isTest
private class ContractorInvoiceControllerTest {
    
    @TestSetup
    static void createTestData() {
        FSL.GlobalAPIS.addStatusTransition('Requested', 'Scheduled');
        TestDataFactory.createServiceAppointmentTestData();
    }
    
     @isTest
    static void testControllerInitialization() {
        List<Appointment_Resource__c> testResources = [
            SELECT Id FROM Appointment_Resource__c LIMIT 1
        ];
        
        PageReference testPage = Page.Contractor_Invoice;
        Test.setCurrentPage(testPage);
        ApexPages.currentPage().getParameters().put('resources', testResources[0].Id);
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testResources[0]);
        
        Test.startTest();
        ContractorInvoiceController controller = new ContractorInvoiceController(stdController);
        Test.stopTest();
        system.debug('controller 1 ' + controller);
       
        System.assertNotEquals(null, controller.resourcesByAppointment, 'Resources by appointment should be initialized');
        System.assertNotEquals(null, controller.subtotalsByAppointment, 'Subtotals by appointment should be initialized');
        System.assertNotEquals(0, controller.serviceAppointmentIds.size(), 'Service appointment IDs should be populated');
    }
    
     @isTest
    static void testResourceCountMethods() {
        List<Appointment_Resource__c> testResources = [
            SELECT Id, Service_Appointment__c FROM Appointment_Resource__c LIMIT 1
        ];
        
        PageReference testPage = Page.Contractor_Invoice;
        Test.setCurrentPage(testPage);
        ApexPages.currentPage().getParameters().put('resources', testResources[0].Id);
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testResources[0]);
        
        Test.startTest();
        ContractorInvoiceController controller = new ContractorInvoiceController(stdController);
        Map<String, Integer> resourceCounts = controller.resourceCounts;
        Integer resourceCountForSA = controller.getResourceCountForSA(String.valueOf(testResources[0].Service_Appointment__c));
        Test.stopTest();
        system.debug('resourceCounts ' + resourceCounts);

    }
    
     @isTest
    static void testTotalCalculations() {
        List<Appointment_Resource__c> testResources = [
            SELECT Id, Service_Appointment__c FROM Appointment_Resource__c LIMIT 1
        ];
        
        PageReference testPage = Page.Contractor_Invoice;
        Test.setCurrentPage(testPage);
        ApexPages.currentPage().getParameters().put('resources', testResources[0].Id);
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testResources[0]);
        
        Test.startTest();
        ContractorInvoiceController controller = new ContractorInvoiceController(stdController);
        system.debug('controller 3 ' + controller);

        Decimal expectedSubtotal = 3 * 185.00;
        Decimal expectedTPS = expectedSubtotal * 0.13;
        Decimal expectedTVQ = expectedSubtotal * 0.05;
        Decimal expectedTotalWithTax = expectedSubtotal + expectedTPS + expectedTVQ;
        
        Decimal totalSubtotal = controller.totalSubtotal;
        Decimal totalTPS = controller.totalTPS;
        Decimal totalTVQ = controller.totalTVQ;
        Decimal finalTotalWithTax = controller.finalTotalWithTax;
        Test.stopTest();
    }
    
    
}