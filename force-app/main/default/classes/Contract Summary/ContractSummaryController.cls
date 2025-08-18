public with sharing class ContractSummaryController {
    
    public Order order { get; private set; }
    public Contact primaryContact { get; private set; }
    public List<SummarizedProduct> summarizedProducts { get; private set; }
    
    // Constructor
    public ContractSummaryController(ApexPages.StandardController stdController) {
        this.order = (Order)stdController.getRecord();
        loadOrderDetails();
        loadPrimaryContact();
        summarizeOrderProducts();
    }
    
    // Load additional Order fields that we need
    private void loadOrderDetails() {
        
        this.order = [SELECT Id, Order_Number__c, CreatedDate, Salesperson_2__c, Salesperson_2__r.Name,
                      ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,
                      Account.Sage_Id__c, Account.BillingStreet, Account.BillingCity, 
                      Account.BillingState, Account.BillingPostalCode, Account.BillingCountry,
                      AccountId
                      FROM Order 
                      WHERE Id = :order.Id];
    }
    
    // Load the primary contact for the Account
    private void loadPrimaryContact() {
        // Query for contacts related to the account
        List<Contact> contacts = [SELECT Id, FirstName, LastName, 
                                 Email, Phone, MobilePhone, MiddleName 
                                 FROM Contact 
                                 WHERE AccountId = :order.AccountId 
                                 AND Primary_Contact__c = true
                                 LIMIT 1];
        
        if (!contacts.isEmpty()) {
            this.primaryContact = contacts[0];
        } else {
            this.primaryContact = new Contact(); // Empty contact if none found
        }
    }
    
    // Summarize the order products - group by product and sum quantities
    private void summarizeOrderProducts() {
        // Get all order products
        List<OrderItem> orderItems = [SELECT Id, Quantity, Product2.Id, Product2.Name, Product2.ProductCode,Product2.Sage_ID__c,
                                     Location__c, OrderItemNumber, Serial__c, Location__r.Sage_ID__c
                                     FROM OrderItem 
                                     WHERE OrderId = :order.Id];
        
        // Get all shipment items for this order
        List<ShipmentItem> shipmentItems = [SELECT Id, Order__c, Product2Id, Quantity, Quantity_Shipped__c 
                                           FROM ShipmentItem 
                                           WHERE Order__c = :order.Id];
        
        // Map to store shipment quantities by Product2Id
        Map<Id, Decimal> shipmentQuantityMap = new Map<Id, Decimal>();
        Map<Id, Decimal> shippedQuantityMap = new Map<Id, Decimal>();
        
        // Process shipment items to aggregate quantities by product
        for (ShipmentItem shipItem : shipmentItems) {
            // Add quantity to the map
            if (shipmentQuantityMap.containsKey(shipItem.Product2Id)) {
                Decimal qty = shipItem.Quantity != null ? shipItem.Quantity : 0;
                shipmentQuantityMap.put(shipItem.Product2Id, 
                                       shipmentQuantityMap.get(shipItem.Product2Id) + qty);
            } else {
                shipmentQuantityMap.put(shipItem.Product2Id, 
                                       shipItem.Quantity != null ? shipItem.Quantity : 0);
            }
            
            // For the shipped quantity
            if (shippedQuantityMap.containsKey(shipItem.Product2Id)) {
                Decimal shippedQty = shipItem.Quantity_Shipped__c != null ? shipItem.Quantity_Shipped__c : 0;
                shippedQuantityMap.put(shipItem.Product2Id, 
                                      shippedQuantityMap.get(shipItem.Product2Id) + shippedQty);
            } else {
                shippedQuantityMap.put(shipItem.Product2Id, 
                                      shipItem.Quantity_Shipped__c != null ? shipItem.Quantity_Shipped__c : 0);
            }
        }
        
        // Map to store summarized products by Product2.Id
        Map<Id, SummarizedProduct> productMap = new Map<Id, SummarizedProduct>();
        
        // Process each order item
        for (OrderItem item : orderItems) {
            // Use Product2.Id as the key
            Id key = item.Product2.Id;
            
            // If product already exists in map, update quantity and append serial number
            if (productMap.containsKey(key)) {
                SummarizedProduct existingProduct = productMap.get(key);
                existingProduct.orderQuantity += item.Quantity;
                
                // Add serial number if not empty and not already included
                if (String.isNotBlank(item.Serial__c) && !existingProduct.serialNumber.contains(item.Serial__c)) {
                    if (String.isNotBlank(existingProduct.serialNumber)) {
                        existingProduct.serialNumber += ', ' + item.Serial__c;
                    } else {
                        existingProduct.serialNumber = item.Serial__c;
                    }
                }
                // Add Location if not empty and not already included
                if (String.isNotBlank(item.Location__r.Sage_ID__c) && !existingProduct.location.contains(item.Location__r.Sage_ID__c)) {
                    if (String.isNotBlank(existingProduct.location)) {
                        existingProduct.location += ', ' + item.Location__r.Sage_ID__c;
                    } else {
                        existingProduct.location = item.Location__r.Sage_ID__c;
                    }
                }
            } else {
                // Create a new summarized product
                SummarizedProduct newProduct = new SummarizedProduct();
                newProduct.productCode = item.Product2.Sage_ID__c;
                newProduct.productName = item.Product2.Name;
                newProduct.orderQuantity = item.Quantity;
                newProduct.location = String.isNotBlank(item.Location__r.Sage_ID__c) ? item.Location__r.Sage_ID__c : '';
                newProduct.serialNumber = String.isNotBlank(item.Serial__c) ? item.Serial__c : '';
                
                // Initialize shipment quantities as zero
                newProduct.shipmentQuantity = 0;
                newProduct.shippedQuantity = 0;
                
                productMap.put(key, newProduct);
            }
        }
        
        // Add shipment quantities to the summarized products
        for (Id productId : productMap.keySet()) {
            SummarizedProduct product = productMap.get(productId);
            
            // Add shipment quantity if present
            if (shipmentQuantityMap.containsKey(productId)) {
                product.shipmentQuantity = shipmentQuantityMap.get(productId);
            }
            
            // Add shipped quantity if present
            if (shippedQuantityMap.containsKey(productId)) {
                product.shippedQuantity = shippedQuantityMap.get(productId);
            }
            
            // Calculate total quantity: OrderItem.Quantity + ShipmentItem.Quantity + ShipmentItem.Quantity_Shipped
            product.quantity = product.orderQuantity + product.shipmentQuantity + product.shippedQuantity;
        }
        
        // Convert map to list and filter out zero quantity items
        this.summarizedProducts = new List<SummarizedProduct>();
        for (SummarizedProduct product : productMap.values()) {
            if (product.quantity != 0) {
                summarizedProducts.add(product);
            }
        }
    }
    
    // Wrapper class for summarized products
    public class SummarizedProduct {
        public String productCode { get; set; }
        public String productName { get; set; }
        public String location { get; set; }
        public Decimal quantity { get; set; }   
        public String serialNumber { get; set; }
        
        // Component quantities
        public Decimal orderQuantity { get; set; }
        public Decimal shipmentQuantity { get; set; }
        public Decimal shippedQuantity { get; set; }
    }
}