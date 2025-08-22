public with sharing class ServiceAppointmentFormController {
    @AuraEnabled
    public static Map<String, Object> validateAndProcessService(String saId) {
        return ServiceAppointmentFormDataService.validateAndProcessService(saId);
    }

    @AuraEnabled(continuation=true)
    public static Boolean updateServiceAppointment(String saId, String status) {
        return ServiceAppointmentFormUpdateService.updateStatus(saId, status);
    }

    @AuraEnabled
    public static void postFormToChatter(Id recordId, Map<String, Object> formData) {
        ServiceAppointmentFormUpdateService.postFormData(recordId, formData);
    }

    public class OutputResults {        
         
        @InvocableVariable
        public Boolean isValid;

        @InvocableVariable
        public String formName;
    }

    @InvocableMethod(label='Validate Form Conditions')     

    public static List<OutputResults> validateAndProcessService2(List<String> saId) {

    List<OutputResults> resultsList = new List<OutputResults>();  
    OutputResults results = new OutputResults();
    
    results.isValid = true;
    results.formName = 'Test';
    
    resultsList.add(results); 
    return resultsList;  
    }
}