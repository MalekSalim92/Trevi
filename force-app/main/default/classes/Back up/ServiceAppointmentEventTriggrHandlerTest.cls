//@isTest
public class ServiceAppointmentEventTriggrHandlerTest {
    
    // @TestSetup
    // static void createTestData() {
    //     FSL.GlobalAPIS.addStatusTransition('Requested', 'Scheduled');
    //     TestDataFactory.createServiceAppointmentTestData();

    // }
    
    // @isTest
    // static void testHandleServiceUpdateEvent_SingleEvent() {

    //     ServiceAppointment testService = [
    //         SELECT Id, Status 
    //         FROM ServiceAppointment 
    //         LIMIT 1
    //     ];
        
    //     String newStatus = 'Scheduled';
        
    //     // Create the platform event
    //     Service_Appointment_Update_Event__e event = new Service_Appointment_Update_Event__e(
    //         Service_Id__c = testService.Id,
    //         Status__c = newStatus,
    //         Timestamp__c = System.now()
    //     );
        
    //     // Test the handler
    //     Test.startTest();
    //     List<Service_Appointment_Update_Event__e> events = new List<Service_Appointment_Update_Event__e>{ event };
    //     ServiceAppointmentEventTriggerHandler.handleServiceUpdateEvent(events);
    //     Test.stopTest();
        
    //     // Verify the service appointment was updated
    //     ServiceAppointment updatedService = [
    //         SELECT Id, Status 
    //         FROM ServiceAppointment 
    //         WHERE Id = :testService.Id
    //     ];
        
    //     System.assertEquals(newStatus, updatedService.Status, 
    //                       'The service appointment status should have been updated to ' + newStatus);
    // }

}