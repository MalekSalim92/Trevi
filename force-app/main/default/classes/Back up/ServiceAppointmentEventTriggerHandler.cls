public without sharing class ServiceAppointmentEventTriggerHandler {
    public static void handleServiceUpdateEvent(List<Service_Appointment_Update_Event__e> events) {
        List<ServiceAppointment> servicesToUpdate = new List<ServiceAppointment>();
        
        for (Service_Appointment_Update_Event__e event : events) {
 
            if (String.isNotBlank(event.Service_Id__c)) {
                ServiceAppointment serviceToUpdate = new ServiceAppointment(
                    Id = event.Service_Id__c,
                    Status = event.Status__c
                    );
                servicesToUpdate.add(serviceToUpdate);
            }
        }
        

        if (!servicesToUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(servicesToUpdate, false);
            
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error updating ServiceAppointment: ' + 
                                     'StatusCode: ' + error.getStatusCode() + 
                                     ', Message: ' + error.getMessage() + 
                                     ', Fields: ' + error.getFields());
                    }
                }
            }
        }
    }
}