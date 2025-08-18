public class ContractorInvoiceInvocable {

    @InvocableMethod(label='Generate invoices' description='Generate invoices')
    public static void generateAndSavePDF(List<List<Id>> appResourceIds) {
        System.debug('appResourceIds : ' + appResourceIds);
        if (appResourceIds.isEmpty() || appResourceIds[0].isEmpty()) {
            return;
        }
        
        List<Id> appointmentResourceIds = appResourceIds[0];
     
        try {
            // Delegate to manager class for invoice generation
            ContractorInvoiceManager.generateInvoice(appointmentResourceIds);
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.debug('Stack: ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
}