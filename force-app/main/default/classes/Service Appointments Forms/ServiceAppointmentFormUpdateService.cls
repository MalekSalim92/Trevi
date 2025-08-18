public with sharing class ServiceAppointmentFormUpdateService {
    public static Boolean updateStatus(String saId, String status) {
        try {
            Service_Appointment_Update_Event__e updateEvent = new Service_Appointment_Update_Event__e(
                Status__c = status,
                Service_Id__c = saId,
                Timestamp__c = System.now()
            );
                        
            Database.SaveResult result = EventBus.publish(updateEvent);
                            
            return result.isSuccess();
        } catch (Exception e) {
            System.debug('Error publishing Service Appointment update event: ' + e.getMessage());
            return false;
        }
    }
    
    public static void postFormData(Id recordId, Map<String, Object> formData) {
        try {
            Form_Submission_Event__e event = new Form_Submission_Event__e(
                recordId__c = recordId,
                formData__c = JSON.serialize(formData)
            );
    
            EventBus.publish(event);
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}