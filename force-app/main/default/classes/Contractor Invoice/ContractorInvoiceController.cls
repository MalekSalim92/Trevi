public class ContractorInvoiceController {
    public Map<Id, List<Appointment_Resource__c>> resourcesByAppointment { get; private set; }
    public Map<Id, Decimal> subtotalsByAppointment { get; private set; }
    public Map<Id, Decimal> tpsByAppointment { get; private set; }
    public Map<Id, Decimal> tvqByAppointment { get; private set; }
    public Map<Id, Decimal> totalWithTaxByAppointment { get; private set; }
    public List<Id> serviceAppointmentIds { get; private set; }
    public Contractor_Invoice_Settings__c billingSettings { get; private set; }
    
    // Constructor for VF page
    public ContractorInvoiceController(ApexPages.StandardController stdController) {
        billingSettings = Contractor_Invoice_Settings__c.getOrgDefaults();
        String resourcesParam = ApexPages.currentPage().getParameters().get('resources');
        if(String.isNotBlank(resourcesParam)) {
            List<Id> resourceIds = resourcesParam.split(',');
            List<Appointment_Resource__c> resources = [
                SELECT Id, Service_Appointment__c, All_Products__c,
                Service_Appointment__r.ActualStartTime, Service_Appointment__r.Description, TECH_Resource_Account_Id__c,
                Resource__r.Account__r.Sage_Id_Number__c, Resource__r.Account__c,
                Resource__r.Account__r.Name,Order__r.Order_Number__c,
                Resource__r.Account__r.BillingStreet,
                Resource__r.Account__r.BillingCity,
                Resource__r.Account__r.BillingState,
                Resource__r.Account__r.BillingPostalCode,
                Resource__r.Account__r.BillingCountry,
                Resource__r.Account__r.Phone,Order__c,
                Fee_Amount__c, Fixed_Fee__c, Special_Tariffication_Fee__c, Total__c, Contractor_Comment__c, Description__c,
                Tariffication_Method__c, Bonus__c, Resource__r.Name, Order_Sage_ID__c, Account_Sage_ID__c
                FROM Appointment_Resource__c
                WHERE Id IN :resourceIds
            ];
            initializeData(resources);
        } else {
            initializeData(new List<Appointment_Resource__c>());
        }
    }
    
    private void initializeData(List<Appointment_Resource__c> resources) {
        System.debug('Starting initializeData');

        resourcesByAppointment = new Map<Id, List<Appointment_Resource__c>>();
        subtotalsByAppointment = new Map<Id, Decimal>();
        tpsByAppointment = new Map<Id, Decimal>();
        tvqByAppointment = new Map<Id, Decimal>();
        totalWithTaxByAppointment = new Map<Id, Decimal>();
        serviceAppointmentIds = new List<Id>();
        
        if(!resources.isEmpty()) {
            initializeWithResources(resources);
        }
    }
    
    public Map<String, Integer> resourceCounts {
        get {
            Map<String, Integer> counts = new Map<String, Integer>();
            for(Id saId : resourcesByAppointment.keySet()) {
                counts.put(saId, resourcesByAppointment.get(saId).size());
            }
            return counts;
        }
    }
    
    public Integer getResourceCountForSA(String saIdString) {
        try {
            Id saId = Id.valueOf(saIdString);
            if(resourcesByAppointment != null && resourcesByAppointment.containsKey(saId)) {
                List<Appointment_Resource__c> resources = resourcesByAppointment.get(saId);
                return resources != null ? resources.size() : 1;
            }
        } catch(Exception e) {
            System.debug('Error in getResourceCountForSA: ' + e.getMessage());
        }
        return 1;
    }
    
    public void initializeWithResources(List<Appointment_Resource__c> appointmentResources) {
        for(Appointment_Resource__c resource : appointmentResources) {
            if(resource.Service_Appointment__c != null) {
                if(!resourcesByAppointment.containsKey(resource.Service_Appointment__c)) {
                    resourcesByAppointment.put(resource.Service_Appointment__c, new List<Appointment_Resource__c>());
                    serviceAppointmentIds.add(resource.Service_Appointment__c);
                }
                resourcesByAppointment.get(resource.Service_Appointment__c).add(resource);
            }
        }
        
        calculateTotalsByAppointment();
    }
    
    private void calculateTotalsByAppointment() {
        for(Id saId : resourcesByAppointment.keySet()) {
            Decimal totalFeeAmount = 0;
            Decimal totalFixedFee = 0;
            Decimal totalSpecialFee = 0;
            Decimal totalBonus = 0;
            Decimal realTotal = 0;
            
            for(Appointment_Resource__c resource : resourcesByAppointment.get(saId)) {
                totalFeeAmount += resource.Fee_Amount__c != null ? resource.Fee_Amount__c : 0;
                totalFixedFee += resource.Fixed_Fee__c != null ? resource.Fixed_Fee__c : 0;
                totalSpecialFee += resource.Special_Tariffication_Fee__c != null ? resource.Special_Tariffication_Fee__c : 0;
                totalBonus += resource.Bonus__c != null ? resource.Bonus__c : 0;
                realTotal += resource.Total__c != null ? resource.Total__c : 0;
            }
            
            Decimal subtotal = realTotal;
            Decimal tvq = subtotal * 0.09975;
            Decimal tps = subtotal * 0.05;
            Decimal totalWithTax = subtotal + tps + tvq;
            
            subtotalsByAppointment.put(saId, subtotal);
            tpsByAppointment.put(saId, tps);
            tvqByAppointment.put(saId, tvq);
            totalWithTaxByAppointment.put(saId, totalWithTax);
        }
    }
    
    // Calculation properties for the VF page


private Decimal calculateTotal(Map<Id, Decimal> totals) { 
    Decimal total = 0;
    if (totals != null) {
        for (Decimal subtotal : totals.values()) {
            if (subtotal != null) {
                total += subtotal;
            }
        }
    }
    return total;
}

 public Decimal totalSubtotal {
    get {
        return calculateTotal(subtotalsByAppointment);
    }
}

public Decimal totalTPS {
    get {
        return calculateTotal(tpsByAppointment);
    }
}

public Decimal totalTVQ {
    get {
        return calculateTotal(tvqByAppointment);
    }
}

public Decimal finalTotalWithTax {
    get {
        return calculateTotal(totalWithTaxByAppointment);
    }
}
}