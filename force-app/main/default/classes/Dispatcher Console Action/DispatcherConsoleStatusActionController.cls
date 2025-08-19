/**
 * DispatcherConsoleStatusActionController
 *
 * Controller for updating the status of ServiceAppointments from the Field Service Lightning Console.
 * Handles:
 *   - Extracting console parameters (single/multiple appointments)
 *   - Loading ServiceAppointment records
 *   - Providing available status picklist values
 *   - Updating ServiceAppointment statuses with proper error handling
 *   - Reporting success and failure for each update
 *
 * Author: Malek Brachemi
 * Date: 2025-05-27
 * Notes: Uses Database.update with allOrNone=false to handle partial failures
 */
public class DispatcherConsoleStatusActionController {

    // ----- Properties -----

    /** Comma-separated ServiceAppointment IDs from console parameters */
    public String serviceAppointmentIds { get; set; }
    
    /** Selected status to update ServiceAppointments */
    public String selectedStatus { get; set; }
    
    /** Loaded ServiceAppointment records */
    public List<ServiceAppointment> serviceAppointments { get; set; }
    
    /** List of successful updates for display */
    public List<UpdateResult> successfulUpdates { get; set; }
    
    /** List of failed updates for display */
    public List<UpdateResult> failedUpdates { get; set; }
    
    /** Flag to show results panel on Visualforce page */
    public Boolean showResults { get; set; }
    
    // ----- Nested Wrapper Classes -----

    /**
     * Wrapper class to hold update results per ServiceAppointment
     */
    public class UpdateResult {
        public String appointmentNumber { get; set; }
        public String appointmentId { get; set; }
        public String errorMessage { get; set; }
        
        /** Constructor */
        public UpdateResult(ServiceAppointment sa, String error) {
            this.appointmentNumber = (sa != null) ? sa.AppointmentNumber : '';
            this.appointmentId = (sa != null) ? sa.Id : '';
            this.errorMessage = error;
        }
    }
    
    // ----- Constructor -----
    
    /**
     * Default constructor
     * Initializes console parameters, loads service appointments, and sets default result lists.
     */
    public DispatcherConsoleStatusActionController() {
        getConsoleParameters();
        loadServiceAppointments();
        successfulUpdates = new List<UpdateResult>();
        failedUpdates = new List<UpdateResult>();
        showResults = false;
    }
    
    // ----- Private Helper Methods -----

    /**
     * Extracts parameters passed from the FSL Console.
     * Supports both single ('id') and multiple ('services') ServiceAppointments.
     */
    private void getConsoleParameters() {
        Map<String, String> params = ApexPages.currentPage().getParameters();
        
        if (params.containsKey('id')) {
            serviceAppointmentIds = params.get('id');
        }
        
        if (params.containsKey('services')) {
            serviceAppointmentIds = params.get('services');
        }
        
        selectedStatus = '';
    }
    
    /**
     * Loads ServiceAppointment records based on extracted IDs.
     * Orders results by scheduled start time.
     * Handles errors gracefully with an ApexPages message.
     */
    private void loadServiceAppointments() {
        serviceAppointments = new List<ServiceAppointment>();
        
        if (String.isNotBlank(serviceAppointmentIds)) {
            List<String> saIds = serviceAppointmentIds.split(',');
            
            if (saIds != null && !saIds.isEmpty()) {
                try {
                    serviceAppointments = [
                        SELECT Id, AppointmentNumber, Status, Subject, Order_Sage_ID__c, 
                               SchedStartTime, SchedEndTime, Description,
                               ServiceTerritoryId, ServiceTerritory.Name,
                               WorkTypeId, WorkType.Name
                        FROM ServiceAppointment 
                        WHERE Id IN :saIds
                        ORDER BY SchedStartTime
                    ];
                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(
                        ApexPages.Severity.ERROR, 
                        'Error loading service appointments: ' + e.getMessage()
                    ));
                }
            }
        }
    }
    
    // ----- Public Methods -----

    /**
     * Retrieves active picklist values for ServiceAppointment.Status.
     * Used to populate the status dropdown on the Visualforce page.
     */
    public List<SelectOption> getStatusOptions() {
        List<SelectOption> options = new List<SelectOption>();
        
        try {
            Schema.DescribeFieldResult fieldResult = ServiceAppointment.Status.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
            
            if (picklistValues != null) {
                for (Schema.PicklistEntry entry : picklistValues) {
                    if (entry != null && entry.isActive()) {
                        options.add(new SelectOption(entry.getValue(), entry.getLabel()));
                    }
                }
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'Error loading status options: ' + e.getMessage()
            ));
        }
        
        return options;
    }
    
    /**
     * Updates the status of the loaded ServiceAppointments.
     * Uses Database.update with allOrNone=false to allow partial success.
     * Populates successfulUpdates and failedUpdates lists.
     * Returns null to stay on the same page.
     */
    public PageReference updateServiceAppointmentStatus() {
        
        // Reset previous results
        if (successfulUpdates != null) successfulUpdates.clear();
        if (failedUpdates != null) failedUpdates.clear();
        showResults = false;
        
        // Validation
        if (String.isBlank(selectedStatus)) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'Please select a status before updating.'
            ));
            return null;
        }
        
        if (serviceAppointments == null || serviceAppointments.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'No service appointments found to update.'
            ));
            return null;
        }
        
        List<ServiceAppointment> appointmentsToUpdate = new List<ServiceAppointment>();
        Map<Id, ServiceAppointment> originalAppointmentsMap = new Map<Id, ServiceAppointment>();
        
        try {
            // Prepare appointments for update
            for (ServiceAppointment sa : serviceAppointments) {
                if (sa != null) {
                    originalAppointmentsMap.put(sa.Id, sa);
                    
                    if (sa.Status != selectedStatus) {
                        ServiceAppointment saToUpdate = new ServiceAppointment();
                        saToUpdate.Id = sa.Id;
                        saToUpdate.Status = selectedStatus;
                        appointmentsToUpdate.add(saToUpdate);
                    } else {
                        failedUpdates.add(new UpdateResult(sa, 
                            'Service Appointment is already in ' + selectedStatus + ' status'));
                    }
                }
            }
            
            // Execute updates
            if (!appointmentsToUpdate.isEmpty()) {
                List<Database.SaveResult> results = Database.update(appointmentsToUpdate, false);
                
                if (results != null) {
                    for (Integer i = 0; i < results.size() && i < appointmentsToUpdate.size(); i++) {
                        Database.SaveResult sr = results[i];
                        ServiceAppointment saToUpdate = appointmentsToUpdate[i];
                        ServiceAppointment originalSA = originalAppointmentsMap.get(saToUpdate.Id);
                        
                        if (sr != null && originalSA != null) {
                            if (sr.isSuccess()) {
                                successfulUpdates.add(new UpdateResult(originalSA, null));
                            } else {
                                String errorMsg = '';
                                List<Database.Error> errors = sr.getErrors();
                                
                                if (errors != null) {
                                    for (Database.Error err : errors) {
                                        if (err != null) {
                                            if (String.isNotBlank(errorMsg)) errorMsg += '; ';
                                            errorMsg += err.getMessage();
                                        }
                                    }
                                }
                                
                                failedUpdates.add(new UpdateResult(originalSA, errorMsg));
                            }
                        }
                    }
                }
                
                // Reload updated data
                loadServiceAppointments();
            }
            
            // Show results if there are any updates
            if ((successfulUpdates != null && !successfulUpdates.isEmpty()) || 
                (failedUpdates != null && !failedUpdates.isEmpty())) {
                showResults = true;
            }
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'An unexpected error occurred while updating service appointments: ' + e.getMessage()
            ));
        }
        
        return null;
    }
    
    /**
     * Returns the count of loaded ServiceAppointments as a string for display.
     */
    public String getServiceAppointmentCount() {
        return (serviceAppointments != null) ? String.valueOf(serviceAppointments.size()) : '0';
    }
}