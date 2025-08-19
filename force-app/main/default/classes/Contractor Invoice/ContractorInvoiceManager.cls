/**
 * ContractorInvoiceManager
 *
 * Manager class responsible for generating contractor invoices.
 * - Calculates totals and taxes for appointment resources
 * - Creates invoice and invoice lines
 * - Updates invoice numbering in settings
 * - Generates and saves PDF invoices
 *
 * Author: Malek Brachemi
 * Date: 2025-05-08
 */
public class ContractorInvoiceManager {

    /**
     * Main method to generate an invoice for a list of appointment resources
     * @param appointmentResourceIds List of Appointment_Resource__c IDs
     * @return Id of the created Contractor_Invoice__c record
     */
    public static Id generateInvoice(List<Id> appointmentResourceIds) {

        // Lock invoice settings to prevent concurrency issues
        Contractor_Invoice_Settings__c settings = [
            SELECT Invoice_Number__c 
            FROM Contractor_Invoice_Settings__c 
            LIMIT 1 
            FOR UPDATE
        ];
        
        // Fetch appointment resources
        List<Appointment_Resource__c> resources = [
            SELECT Id, Invoice_Number__c, Is_Invoiced__c,
                   Resource__c,
                   Resource__r.Account__r.Sage_Id_Number__c,
                   Resource__r.Account__c, Order__c, Order__r.Order_Number__c,
                   Fee_Amount__c, Fixed_Fee__c, Special_Tariffication_Fee__c, Total__c
            FROM Appointment_Resource__c 
            WHERE Id IN :appointmentResourceIds
        ];        
        
        if (resources.isEmpty()) {
            throw new AuraHandledException('No resources found');
        }
       
        // Calculate totals and update appointment resources
        Map<String, Decimal> totals = calculateTotals(resources, settings);
        
        // Create the main invoice record
        Contractor_Invoice__c invoice = createInvoiceRecord(resources, totals, settings);
        
        // Create associated invoice lines
        createInvoiceLines(resources, invoice.Id);
        
        // Increment and update invoice number in settings
        updateInvoiceNumberSetting(settings);

        // Generate and save PDF
        ContractorInvoicePdfGenerator.generateAndSavePdf(appointmentResourceIds, invoice, settings);
        
        return invoice.Id;
    }
    
    /**
     * Calculates totals and marks resources as invoiced
     * @param resources List of Appointment_Resource__c
     * @param settings Invoice settings containing current invoice number
     * @return Map with totalAmount, totalTPS, and totalTVQ
     */
    private static Map<String, Decimal> calculateTotals(
        List<Appointment_Resource__c> resources, 
        Contractor_Invoice_Settings__c settings
    ) {
        Decimal totalAmount = 0;
        Decimal totalTPS = 0;
        Decimal totalTVQ = 0;
        
        for (Appointment_Resource__c resource : resources) {
            resource.Is_Invoiced__c = true;
            resource.Invoice_Number__c = settings.Invoice_Number__c;
            
            Decimal subtotal = resource.Total__c != null ? resource.Total__c : 0;
            Decimal tps = subtotal * 0.13;
            Decimal tvq = subtotal * 0.05;
            
            totalAmount += subtotal + tps + tvq;
            totalTPS += tps;
            totalTVQ += tvq;
        }
        
        // Update resources in Salesforce
        update resources;
        
        return new Map<String, Decimal>{
            'totalAmount' => totalAmount,
            'totalTPS' => totalTPS,
            'totalTVQ' => totalTVQ
        };
    }
   
    /**
     * Creates the main invoice record
     * @param resources List of appointment resources
     * @param totals Map of calculated totals
     * @param settings Invoice settings
     * @return Inserted Contractor_Invoice__c record
     */
    private static Contractor_Invoice__c createInvoiceRecord(
        List<Appointment_Resource__c> resources,
        Map<String, Decimal> totals,
        Contractor_Invoice_Settings__c settings
    ) {
        Contractor_Invoice__c invoice = new Contractor_Invoice__c(
            Name = settings.Invoice_Number__c,
            Contractor__c = resources[0].Resource__r.Account__c,
            Integration_Status__c = 'Ready', 
            Total_Amount__c = totals.get('totalAmount'),
            Tax_1__c = 'TPS',
            Tax_2__c = 'TVQ',
            Tax_Amount_1__c = totals.get('totalTPS'),
            Tax_Amount_2__c = totals.get('totalTVQ')
        );
        insert invoice;
        return invoice;
    }
    
    /**
     * Creates invoice lines for each appointment resource
     * @param resources List of Appointment_Resource__c
     * @param invoiceId Id of the related invoice
     */
    private static void createInvoiceLines(List<Appointment_Resource__c> resources, Id invoiceId) {
        List<Contractor_Invoice_Line__c> invoiceLines = new List<Contractor_Invoice_Line__c>();
        
        for (Appointment_Resource__c resource : resources) {
            invoiceLines.add(new Contractor_Invoice_Line__c(
                Contractor_Invoice__c = invoiceId,
                Order__c = resource.Order__c,
                Appointment_Resource__c = resource.Id
            ));
        }

        insert invoiceLines;
    }
    
    /**
     * Increments and updates the invoice number in settings
     * @param settings Contractor_Invoice_Settings__c record
     */
    private static void updateInvoiceNumberSetting(Contractor_Invoice_Settings__c settings) {
        Decimal currentNumber = Decimal.valueOf(settings.Invoice_Number__c);
        settings.Invoice_Number__c = String.valueOf(currentNumber + 1);
        update settings;
    }
}