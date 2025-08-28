/**
 * Class Name: ServiceAppointmentProductGrouper
 * Description: 
 *   Invocable class that groups OrderItems related to a Service Appointment.
 *   - Resolves the Service Appointment to its Work Order Line Item (WOLI)
 *   - Retrieves the related Order and groups its OrderItems by Product2
 *   - Summarizes quantity and concatenates serial numbers for each product
 *   - Returns grouped results for display in datatables
 *
 * Author: Malek Brachemi
 * Created Date: 2025-05-19
 * Version: 1.0
 * Notes: Designed to be invoked from Flows
 */
public class ServiceAppointmentProductGrouper {
    
    /**
     * Request Wrapper: GroupRequest
     * Input for invocable method
     */
    public class GroupRequest {
        @InvocableVariable(label='Service Appointment ID' required=true)
        public String serviceAppointmentId;
    }
    
    /**
     * Response Wrapper: GroupResponse
     * Output from invocable method
     */
    public class GroupResponse {
        @InvocableVariable(label='Grouped Order Items')
        public List<OrderItem> groupedOrderItems;
        
        @InvocableVariable(label='Success')
        public Boolean success;
        
        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }
    
    /**
     * Invocable Method: getGroupedProducts
     * Description:
     *   Given Service Appointment IDs, retrieves and groups related OrderItems
     *   by Product2. Provides a summarized list of items with:
     *   - Product details
     *   - Total quantities
     *   - Concatenated serial numbers
     *
     * @param requests List<GroupRequest> - List of Service Appointment IDs
     * @return List<GroupResponse> - Grouped product data for each request
     */
    @InvocableMethod(label='Get Grouped Products for Service Appointment')
    public static List<GroupResponse> getGroupedProducts(List<GroupRequest> requests) {
        List<GroupResponse> responses = new List<GroupResponse>();
        
        for (GroupRequest request : requests) {
            GroupResponse response = new GroupResponse();
            
            try {
                // Step 1: Get Service Appointment details
                ServiceAppointment saDetails = [
                    SELECT Id, ParentRecordId
                    FROM ServiceAppointment
                    WHERE Id = :request.serviceAppointmentId
                    LIMIT 1
                ];
                
                Id woliId = saDetails.ParentRecordId;
                
                // Step 2: Get Work Order Line Item (to resolve OrderId)
                WorkOrderLineItem woli = [
                    SELECT Id, OrderId 
                    FROM WorkOrderLineItem 
                    WHERE Id = :woliId 
                    LIMIT 1
                ];
                
                Id orderId = woli.OrderId;
                
                // Step 3: Group OrderItems by Product2 (aggregate query)
                List<AggregateResult> groupedItems = [
                    SELECT Product2Id,
                           MAX(Product2.Name) productName,
                           MAX(Product2.Sage_ID__c) sageProdId,
                           MAX(Sage_ID__c) sageId,
                           MAX(Product2.ProductCode) productCode,
                           SUM(Quantity) totalQuantity
                    FROM OrderItem
                    WHERE OrderId = :orderId
                    GROUP BY Product2Id
                ];
                
                // Step 4: Collect serial numbers per product
                Map<Id, List<String>> productSerials = new Map<Id, List<String>>();
                for (OrderItem oi : [
                    SELECT Product2Id, Serial__c
                    FROM OrderItem
                    WHERE OrderId = :orderId
                    AND Serial__c != null
                ]) {
                    if (!productSerials.containsKey(oi.Product2Id)) {
                        productSerials.put(oi.Product2Id, new List<String>());
                    }
                    productSerials.get(oi.Product2Id).add(oi.Serial__c);
                }
                
                // Step 5: Build summarized OrderItem "records" (not inserted)
                List<OrderItem> groupedOrderItems = new List<OrderItem>();
                for (AggregateResult ar : groupedItems) {
                    Id product2Id = (Id) ar.get('Product2Id');
                    
                    // Collect serials if available
                    String serialNumbers = productSerials.containsKey(product2Id) 
                        ? String.join(productSerials.get(product2Id), ', ') 
                        : '';
                    
                    // Build OrderItem instance for datatable display
                    OrderItem item = new OrderItem();
                    item.Product2Id       = product2Id;
                    item.Description      = (String) ar.get('productName');
                    item.Return_Location__c = (String) ar.get('sageProdId');
                    item.Quantity         = (Decimal) ar.get('totalQuantity');
                    item.Serial__c        = serialNumbers;
                    
                    groupedOrderItems.add(item);
                }
                
                response.groupedOrderItems = groupedOrderItems;
                response.success = true;
                
            } catch (Exception e) {
                // Capture and return failure
                response.success = false;
                response.errorMessage = e.getMessage();
            }
            
            responses.add(response);
        }
        
        return responses;
    }
}