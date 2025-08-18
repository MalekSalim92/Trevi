public class ContractorInvoiceManager {

    public static Id generateInvoice(List<Id> appointmentResourceIds) {

        Contractor_Invoice_Settings__c settings = [SELECT Invoice_Number__c FROM Contractor_Invoice_Settings__c LIMIT 1 FOR UPDATE ];
        
        // Get the resources
        List<Appointment_Resource__c> resources = [
            SELECT Id, Invoice_Number__c, Is_Invoiced__c,
                   Resource__c,
                   Resource__r.Account__r.Sage_Id_Number__c,
                   Resource__r.Account__c, Order__c,Order__r.Order_Number__c,
                   Fee_Amount__c, Fixed_Fee__c, Special_Tariffication_Fee__c, Total__c
            FROM Appointment_Resource__c 
            WHERE Id IN :appointmentResourceIds
        ];        
        if (resources.isEmpty()) {
            throw new AuraHandledException('No resources found');
        }
       
        // Calculate totals and update resources
        Map<String, Decimal> totals = calculateTotals(resources, settings);
        
        // Create new Invoice record
        Contractor_Invoice__c invoice = createInvoiceRecord(resources, totals, settings);
        
        // Create invoice lines
        createInvoiceLines(resources, invoice.Id);
        
        // Update invoice number setting
        updateInvoiceNumberSetting(settings);

        // Generate and save PDF
        ContractorInvoicePdfGenerator.generateAndSavePdf(appointmentResourceIds, invoice, settings);
        
        return invoice.Id;
    }
    
    
 
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
        
        // Update resources
        update resources;
        
        Map<String, Decimal> totals = new Map<String, Decimal>{
            'totalAmount' => totalAmount,
            'totalTPS' => totalTPS,
            'totalTVQ' => totalTVQ
        };
        
        return totals;
    }
   
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
    
  
    private static void updateInvoiceNumberSetting(Contractor_Invoice_Settings__c settings) {
        Decimal currentNumber = Decimal.valueOf(settings.Invoice_Number__c);
        settings.Invoice_Number__c = String.valueOf(currentNumber + 1);
        update settings;
    }
    
}