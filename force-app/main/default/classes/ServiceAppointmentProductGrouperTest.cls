@isTest
public class ServiceAppointmentProductGrouperTest {
    
    
    @testSetup
    static void setupTestData() {
        TestDataFactory.createCompleteTestData();
    }
    
    @isTest
    static void testGetGroupedProducts_Success() {
        Id serviceAppointmentId = [SELECT Id FROM ServiceAppointment LIMIT 1].Id;
        
        ServiceAppointmentProductGrouper.GroupRequest req = new ServiceAppointmentProductGrouper.GroupRequest();
        req.serviceAppointmentId = serviceAppointmentId;
        List<ServiceAppointmentProductGrouper.GroupRequest> requests = new List<ServiceAppointmentProductGrouper.GroupRequest>{ req };
        
        // Act
        Test.startTest();
        List<ServiceAppointmentProductGrouper.GroupResponse> responses = ServiceAppointmentProductGrouper.getGroupedProducts(requests);
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, responses.size(), 'Should return one response');
     }
    
 
}
