/**
 * ServiceAppointmentProductGrouperTest
 *
 * Unit tests for ServiceAppointmentProductGrouper invocable.
 * Verifies grouped products retrieval for a Service Appointment.
 *
 * Author: Malek Brachemi
 * Created Date: 2025-05-19
 * Version: 1.0
 */

 @IsTest
 public class ServiceAppointmentProductGrouperTest {
     
     /**
      * Test setup: creates all required test data using the factory.
      */
     @TestSetup
     static void setupTestData() {
         TestDataFactory.createCompleteTestData();
     }
     
     /**
      * Verifies that grouped products are returned successfully 
      * for a Service Appointment.
      */
     @IsTest
     static void testGetGroupedProducts_Success() {
         // Arrange
         Id serviceAppointmentId = [
             SELECT Id 
             FROM ServiceAppointment 
             LIMIT 1
         ].Id;
         
         ServiceAppointmentProductGrouper.GroupRequest req = 
             new ServiceAppointmentProductGrouper.GroupRequest();
         req.serviceAppointmentId = serviceAppointmentId;
         
         List<ServiceAppointmentProductGrouper.GroupRequest> requests = 
             new List<ServiceAppointmentProductGrouper.GroupRequest>{ req };
         
         // Act
         Test.startTest();
         List<ServiceAppointmentProductGrouper.GroupResponse> responses = 
             ServiceAppointmentProductGrouper.getGroupedProducts(requests);
         Test.stopTest();
         
         // Assert
         System.assertEquals(
             1, 
             responses.size(), 
             'Should return one response'
         );
     }
 }