/**
 * ContractorInvoiceInvocable
 *
 * Invocable Apex class for generating contractor invoices
 * - Accepts lists of Appointment_Resource__c Ids from Flow or Process Builder
 * - Delegates invoice generation to ContractorInvoiceManager
 * - Handles errors and logs debug information
 *
 * Author: Malek Brachemi
 * Date: 2025-05-08
 */
public class ContractorInvoiceInvocable {

    /**
     * Invocable method to generate and save invoices as PDFs
     *
     * @param appResourceIds List of lists of Appointment_Resource__c Ids
     *                       (Flow/Process Builder passes list of Ids)
     * @throws AuraHandledException if invoice generation fails
     */
    @InvocableMethod(label='Generate invoices' description='Generate invoices')
    public static void generateAndSavePDF(List<List<Id>> appResourceIds) {
        System.debug('Received appResourceIds: ' + appResourceIds);

        // Exit if input list is empty or the first inner list is empty
        if (appResourceIds.isEmpty() || appResourceIds[0].isEmpty()) {
            return;
        }

        List<Id> appointmentResourceIds = appResourceIds[0];

        try {
            // Delegate to the manager class for actual invoice generation
            ContractorInvoiceManager.generateInvoice(appointmentResourceIds);

        } catch (Exception e) {
            // Log errors and re-throw as AuraHandledException for Flow/UI handling
            System.debug('Error generating invoices: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
}