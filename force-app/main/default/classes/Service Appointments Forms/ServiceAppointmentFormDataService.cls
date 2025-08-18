
public with sharing class ServiceAppointmentFormDataService {
    
    @AuraEnabled
    public static ServiceAppointment testGet(String saId) {
         
        return  [
                SELECT Id,City,Street,PostalCode,Country,State,DueDate,
                ParentRecordId,Is_Expired__c,SchedStartTime,WorkType.Name,AppointmentNumber,
                Account.Phone
                FROM ServiceAppointment
                WHERE Id = :saId
                LIMIT 1
            ];
        }
    @AuraEnabled
    public static Account testGetAcc() {
         
        return  [
                SELECT Id,Name
                FROM Account
                LIMIT 1
            ];
        }

    @AuraEnabled

    public static Map<String, Object> validateAndProcessService(String saId) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            ServiceAppointment saDetails = [
                SELECT Id,City,Street,PostalCode,Country,State,DueDate,
                ParentRecordId,Is_Expired__c,SchedStartTime,WorkType.Name,AppointmentNumber,
                Account.Phone
                FROM ServiceAppointment
                WHERE Id = :saId
                LIMIT 1
            ];
            
            Id woliId = saDetails.ParentRecordId;
            WorkOrderLineItem woli = [SELECT Id,OrderId,ContractType__c FROM WorkOrderLineItem WHERE Id =:woliId LIMIT 1];
            Id orderId = woli.OrderId;
             
            String wtg = getPicklistLabel('WorkOrderLineItem','ContractType__c',woli.ContractType__c);
            wtg = convertLabel(wtg);
 
            List<AggregateResult> groupedItems = [
            SELECT Product2Id,
            MAX(Product_Name__c) productName, 
            MAX(Product2.Sage_ID__c) sageProdId,
            MAX(Order.Installation_Date__c) installationDate,
            MAX(Order.Expected_Ship_Date__c) deliveryDate,
            MAX(Sage_ID__c) sageId,
            MAX(Order.ContractType__c) wtg,
            SUM(Quantity) totalQuantity
            FROM OrderItem 
            WHERE OrderId = :orderId
            GROUP BY Product2Id
        ];

        Map<Id, List<String>> productSerials = new Map<Id, List<String>>();
        for(OrderItem oi : [SELECT Product2Id, Serial__c 
                            FROM OrderItem 
                            WHERE OrderId = :orderId 
                            AND Serial__c != null]) {
            if(!productSerials.containsKey(oi.Product2Id)) {
                productSerials.put(oi.Product2Id, new List<String>());
            }
            productSerials.get(oi.Product2Id).add(oi.Serial__c);
        }

        List<Map<String, Object>> orderItems = new List<Map<String, Object>>();

        for(AggregateResult ar : groupedItems) {
            Id product2Id = (Id)ar.get('Product2Id');
            String serialNumbers = '';
            
            // Get serial numbers for this product if they exist
            if(productSerials.containsKey(product2Id)) {
                serialNumbers = String.join(productSerials.get(product2Id), ', ');
            }
            
            Map<String, Object> item = new Map<String, Object>{
                'productCode' => ar.get('sageProdId'),
                'productName' => ar.get('productName'),
                'serialNumber' => serialNumbers,
                'quantity' => ar.get('totalQuantity'),
                'installationDate' => ar.get('installationDate'),
                'deliveryDate' => ar.get('deliveryDate')
            };
            orderItems.add(item);
        }

            // Use AccessValidationService for validation
            Boolean isUrlValid = ServiceAppointmentFormAccessValidation.hasValidAccess(saId, wtg);
            
            result.put('isValid', isUrlValid);
            result.put('saDetails', saDetails);
            result.put('orderItems', orderItems);
            result.put('wtg', wtg);
 
            return result;
        } catch (Exception e) {
            result.put('isValid', false);
            result.put('errorMessage', e.getMessage());
            return result;
        }
    }
    public static Map<String, Object> validateAndProcessService2(String saId) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            ServiceAppointment saDetails = [
                SELECT Id,City,Street,PostalCode,Country,State,DueDate,
                ParentRecordId,Is_Expired__c,SchedStartTime,WorkType.Name,AppointmentNumber,
                Account.Phone
                FROM ServiceAppointment
                WHERE Id = :saId
                LIMIT 1
            ];
            
            Id woliId = saDetails.ParentRecordId;
            WorkOrderLineItem woli = [SELECT Id,OrderId,ContractType__c FROM WorkOrderLineItem WHERE Id =:woliId LIMIT 1];
            Id orderId = woli.OrderId;
             
            String wtg = getPicklistLabel('WorkOrderLineItem','ContractType__c',woli.ContractType__c);
            wtg = convertLabel(wtg);
 
            List<AggregateResult> groupedItems = [
            SELECT Product2Id,
            MAX(Product_Name__c) productName, 
            MAX(Product2.Sage_ID__c) sageProdId,
            MAX(Order.Installation_Date__c) installationDate,
            MAX(Order.Expected_Ship_Date__c) deliveryDate,
            MAX(Sage_ID__c) sageId,
            MAX(Order.ContractType__c) wtg,
            SUM(Quantity) totalQuantity
            FROM OrderItem 
            WHERE OrderId = :orderId
            GROUP BY Product2Id
        ];

        Map<Id, List<String>> productSerials = new Map<Id, List<String>>();
        for(OrderItem oi : [SELECT Product2Id, Serial__c 
                            FROM OrderItem 
                            WHERE OrderId = :orderId 
                            AND Serial__c != null]) {
            if(!productSerials.containsKey(oi.Product2Id)) {
                productSerials.put(oi.Product2Id, new List<String>());
            }
            productSerials.get(oi.Product2Id).add(oi.Serial__c);
        }

        List<Map<String, Object>> orderItems = new List<Map<String, Object>>();

        for(AggregateResult ar : groupedItems) {
            Id product2Id = (Id)ar.get('Product2Id');
            String serialNumbers = '';
            
            // Get serial numbers for this product if they exist
            if(productSerials.containsKey(product2Id)) {
                serialNumbers = String.join(productSerials.get(product2Id), ', ');
            }
            
            Map<String, Object> item = new Map<String, Object>{
                'productCode' => ar.get('sageProdId'),
                'productName' => ar.get('productName'),
                'serialNumber' => serialNumbers,
                'quantity' => ar.get('totalQuantity'),
                'installationDate' => ar.get('installationDate'),
                'deliveryDate' => ar.get('deliveryDate')
            };
            orderItems.add(item);
        }

            // Use AccessValidationService for validation
            Boolean isUrlValid = ServiceAppointmentFormAccessValidation.hasValidAccess(saId, wtg);
            
            result.put('isValid', isUrlValid);
            result.put('saDetails', saDetails);
            result.put('orderItems', orderItems);
            result.put('wtg', wtg);
 
            return result;
        } catch (Exception e) {
            result.put('isValid', false);
            result.put('errorMessage', e.getMessage());
            return result;
        }
    }
    
    // Move utility methods here
    private static String getPicklistLabel(String objectName, String fieldName, String value) {
        String label = value;
        
        try {
             Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
            
             Schema.DescribeFieldResult fieldDescribe = objectType.getDescribe().fields.getMap().get(fieldName).getDescribe();
            
             List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
            
             for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.getValue() == value) {
                    label = entry.getLabel();
                    break;
                }
            }
        } catch (Exception e) {
            System.debug('Error getting picklist label: ' + e.getMessage());
        }
        
        return label;
    }
    
    private static String convertLabel(String originalLabel) {
        if (originalLabel == null || originalLabel.trim() == '') {
            return originalLabel;
        }
        
        
         if (originalLabel.contains('Service')) {
            return 'Service';
        }
        
         if (originalLabel == 'HT Industria') {
            return 'HT';
        }
        
         if (originalLabel == 'Meuble MB') {
            return 'MB AUTRE';
        }
        

         if (originalLabel.contains(' ') || originalLabel.contains('-')) {
             Integer spaceIndex = originalLabel.indexOf(' ');
            Integer dashIndex = originalLabel.indexOf('-');
            
             if (spaceIndex == -1) {
                if (dashIndex != -1) {
                    return originalLabel.substring(0, dashIndex).trim();
                }
            } else if (dashIndex == -1) {
                return originalLabel.substring(0, spaceIndex).trim();
            } else {
                 Integer firstSeparator = Math.min(spaceIndex, dashIndex);
                return originalLabel.substring(0, firstSeparator).trim();
            }
        }
        
         return originalLabel;
    }
}