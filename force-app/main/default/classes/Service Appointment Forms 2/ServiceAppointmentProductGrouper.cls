public class ServiceAppointmentProductGrouper {
    
    public class GroupRequest {
        @InvocableVariable(label='Service Appointment ID' required=true)
        public String serviceAppointmentId;
    }
    
    public class GroupResponse {
        @InvocableVariable(label='Grouped Order Items')
        public List<OrderItem> groupedOrderItems;
        
        @InvocableVariable(label='Success')
        public Boolean success;
        
        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }
    
    @InvocableMethod(label='Get Grouped Products for Service Appointment')
    public static List<GroupResponse> getGroupedProducts(List<GroupRequest> requests) {
        List<GroupResponse> responses = new List<GroupResponse>();
        
        for(GroupRequest request : requests) {
            GroupResponse response = new GroupResponse();
            
            try {
                String saId = request.serviceAppointmentId;
                
                // Get Service Appointment details
                ServiceAppointment saDetails = [
                    SELECT Id, ParentRecordId
                    FROM ServiceAppointment
                    WHERE Id = :saId
                    LIMIT 1
                ];
                
                Id woliId = saDetails.ParentRecordId;
                
                // Get Work Order Line Item details
                WorkOrderLineItem woli = [
                    SELECT Id, OrderId 
                    FROM WorkOrderLineItem 
                    WHERE Id = :woliId 
                    LIMIT 1
                ];
                
                Id orderId = woli.OrderId;
                
                // Get grouped order items using aggregate query
                List<AggregateResult> groupedItems = [
                    SELECT Product2Id,
                    MAX(Product2.Name) productName,
                    MAX(Product2.Sage_ID__c) sageProdId,
                    MAX(Sage_ID__c) sageId,
                    MAX(Product2.productCode) productCode,
                    SUM(Quantity) totalQuantity
                    FROM OrderItem
                    WHERE OrderId = :orderId
                    GROUP BY Product2Id
                ];
                
                // Get serial numbers map
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
                
                // Build OrderItem records for datatable
                List<OrderItem> groupedOrderItems = new List<OrderItem>();
                
                for(AggregateResult ar : groupedItems) {
                    Id product2Id = (Id)ar.get('Product2Id');
                    String serialNumbers = '';
                    
                    // Get serial numbers for this product if they exist
                    if(productSerials.containsKey(product2Id)) {
                        serialNumbers = String.join(productSerials.get(product2Id), ', ');
                    }
                    
                    // Create OrderItem record (not inserted, just for datatable display)
                    OrderItem item = new OrderItem();
                    item.Product2Id = product2Id;
                    item.Description = (String)ar.get('productName');
                    item.Return_Location__c = (String)ar.get('productCode');
                    item.Quantity = (Decimal)ar.get('totalQuantity');
                    item.Serial__c = serialNumbers;

                    
                    groupedOrderItems.add(item);
                }
                
                response.groupedOrderItems = groupedOrderItems;
                response.success = true;
                
            } catch(Exception e) {
                response.success = false;
                response.errorMessage = e.getMessage();
            }
            
            responses.add(response);
        }
        
        return responses;
    }
}