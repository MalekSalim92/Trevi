
@isTest
public with sharing class ServiceAppointmentFormControllerTest {
    @TestSetup
    static void setupTestData() {
        FSL.GlobalAPIS.addStatusTransition('Requested', 'Scheduled');
        TestDataFactory.createServiceAppointmentTestData();
    }
    
    @isTest
    public static void testValidateAndProcessService() {

        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        Map<String, Object> resutl = ServiceAppointmentFormController.validateAndProcessService(sa.Id);

    }
    @isTest
    public static void testValidateAndProcessServiceOuverture() {

        WorkType workType = [SELECT Id,Name FROM WorkType LIMIT 1];
        workType.Name = 'Ouverture';
        update workType;
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        
        Map<String, Object> resutl = ServiceAppointmentFormController.validateAndProcessService(sa.Id);

    }
    @isTest
    public static void testValidateAndProcessServiceFermeture() {

        WorkType workType = [SELECT Id,Name FROM WorkType LIMIT 1];
        workType.Name = 'Fermeture';
        update workType;
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        
        Map<String, Object> resutl = ServiceAppointmentFormController.validateAndProcessService(sa.Id);

    }
    @isTest
    public static void testUpdateServiceAppointment() {

        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
        
        Boolean resutl = ServiceAppointmentFormController.updateServiceAppointment(sa.Id,'Confirmed');

    }

    @isTest
    public static void testPostFormToChatter() {

        WorkOrderLineItem woli = [SELECT Id FROM WorkOrderLineItem LIMIT 1];
        Map<String, Object> formData = TestDataFactory.createFormData();

        ServiceAppointmentFormController.postFormToChatter(woli.Id,formData);

    }


}


