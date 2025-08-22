global with sharing class ServiceAppointmentFormProductSummary {
    
    global class ProductSummary {
        @InvocableVariable
        public String productCode;
        @InvocableVariable
        public String productName;
        @InvocableVariable
        public String serialNumber;
        @InvocableVariable
        public Decimal quantity;
    }
    
    @InvocableMethod(label = 'Get Service Appointment Product Summary')
    public static List<ProductSummary> getProductSummary(List<Id> ServiceAppIds) {
        
        Id ServiceAppId = ServiceAppIds[0]; // Get first ID from list
        
        // Get Service Appointment details
        ServiceAppointment saDetails = [
            SELECT ParentRecordId
            FROM ServiceAppointment 
            WHERE Id = :ServiceAppId 
            LIMIT 1
        ];
        
        // Get Work Order Line Item
        WorkOrderLineItem woli = [
            SELECT OrderId 
            FROM WorkOrderLineItem 
            WHERE Id = :saDetails.ParentRecordId 
            LIMIT 1
        ];
        
        // Group products by Product2Id
        List<AggregateResult> groupedItems = [
            SELECT Product2Id,
                   MAX(Product_Name__c) productName,
                   MAX(Product2.Sage_ID__c) sageProdId,
                   SUM(Quantity) totalQuantity
            FROM OrderItem 
            WHERE OrderId = :woli.OrderId
            GROUP BY Product2Id
        ];
        
        // Get serial numbers for products
        Map<Id, List<String>> productSerials = new Map<Id, List<String>>();
        for(OrderItem oi : [SELECT Product2Id, Serial__c
                           FROM OrderItem 
                           WHERE OrderId = :woli.OrderId 
                           AND Serial__c != null]) {
            if(!productSerials.containsKey(oi.Product2Id)) {
                productSerials.put(oi.Product2Id, new List<String>());
            }
            productSerials.get(oi.Product2Id).add(oi.Serial__c);
        }
        
        // Build result list
        List<ProductSummary> ProductSummary = new List<ProductSummary>();
        
        for(AggregateResult ar : groupedItems) {
            Id product2Id = (Id)ar.get('Product2Id');
            String serialNumbers = '';
            
            if(productSerials.containsKey(product2Id)) {
                serialNumbers = String.join(productSerials.get(product2Id), ', ');
            }
            
            ProductSummary item = new ProductSummary();
            item.productCode = (String)ar.get('sageProdId');
            item.productName = (String)ar.get('productName');
            item.serialNumber = serialNumbers;
            item.quantity = (Decimal)ar.get('totalQuantity');
            
            ProductSummary.add(item);
        }
        
        return ProductSummary;
    }
}