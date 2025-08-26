/**
 * ContractSummaryController
 *
 * Controller to display a summarized view of an Order and its related products for a Visualforce page.
 * Handles:
 *   - Loading Order details and related Account fields
 *   - Loading the primary contact for the Account
 *   - Summarizing Order Products with quantities, shipment info, and serial numbers
 *
 * Author: Malek Brachemi
 * Date: 2025-02-25
 * Notes: Aggregates quantities across OrderItems and ShipmentItems and provides a clean wrapper class for display
 */
public class ContractSummaryController {

    // ----- Properties -----
    
    /** The Order record being summarized */
    public Order order { get; private set; }
    
    /** The primary Contact for the Order's Account */
    public Contact primaryContact { get; private set; }
    
    /** List of summarized products for display on the page */
    public List<SummarizedProduct> summarizedProducts { get; private set; }

    // ----- Constructor -----
    
    /**
     * Standard controller constructor
     * Loads Order, primary contact, and summarized products for display
     */
    public ContractSummaryController(ApexPages.StandardController stdController) {
        this.order = (Order)stdController.getRecord();
        loadOrderDetails();
        loadPrimaryContact();
        summarizeOrderProducts();
    }

    // ----- Private Helper Methods -----
    
    /**
     * Loads additional fields on the Order and related Account
     */
    private void loadOrderDetails() {
        this.order = [SELECT Id, Order_Number__c, CreatedDate, Salesperson_2__c, Salesperson_2__r.Name,
                      ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,
                      Account.Sage_Id__c, Account.BillingStreet, Account.BillingCity, 
                      Account.BillingState, Account.BillingPostalCode, Account.BillingCountry,
                      AccountId
                      FROM Order 
                      WHERE Id = :order.Id];
    }
    
    /**
     * Loads the primary Contact for the Order's Account
     * If none exists, initializes an empty Contact
     */
    private void loadPrimaryContact() {
        List<Contact> contacts = [SELECT Id, FirstName, LastName, 
                                  Email, Phone, MobilePhone 
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
    
    /**
     * Summarizes Order Products
     * Aggregates quantities across OrderItems and ShipmentItems
     * Combines serial numbers and locations for display
     */
    private void summarizeOrderProducts() {
        // Query all OrderItems for this Order
        List<OrderItem> orderItems = [SELECT Id, Quantity, Product2.Id, Product2.Name, Product2.ProductCode, Product2.Sage_ID__c,
                                     Location__c, OrderItemNumber, Serial__c, Location__r.Sage_ID__c
                                     FROM OrderItem 
                                     WHERE OrderId = :order.Id];

        // Query ShipmentItems for this Order
        List<ShipmentItem> shipmentItems = [SELECT Id, Order__c, Product2Id, Quantity, Quantity_Shipped__c 
                                           FROM ShipmentItem 
                                           WHERE Order__c = :order.Id];
        
        // Maps to track quantities by Product2.Id
        Map<Id, Decimal> shipmentQuantityMap = new Map<Id, Decimal>();
        Map<Id, Decimal> shippedQuantityMap = new Map<Id, Decimal>();
        
        // Aggregate shipment quantities
        for (ShipmentItem shipItem : shipmentItems) {
            Decimal qty = (shipItem.Quantity != null) ? shipItem.Quantity : 0;
            Decimal shippedQty = (shipItem.Quantity_Shipped__c != null) ? shipItem.Quantity_Shipped__c : 0;
            
            shipmentQuantityMap.put(shipItem.Product2Id, (shipmentQuantityMap.get(shipItem.Product2Id) != null ? shipmentQuantityMap.get(shipItem.Product2Id) : 0) + qty);
            shippedQuantityMap.put(shipItem.Product2Id, (shippedQuantityMap.get(shipItem.Product2Id) != null ? shippedQuantityMap.get(shipItem.Product2Id) : 0) + shippedQty);
        }
        
        // Map to store summarized products
        Map<Id, SummarizedProduct> productMap = new Map<Id, SummarizedProduct>();
        
        // Process OrderItems to summarize
        for (OrderItem item : orderItems) {
            Id key = item.Product2.Id;
            
            if (productMap.containsKey(key)) {
                SummarizedProduct existingProduct = productMap.get(key);
                existingProduct.orderQuantity += item.Quantity;
                
                if (String.isNotBlank(item.Serial__c) && !existingProduct.serialNumber.contains(item.Serial__c)) {
                    existingProduct.serialNumber = String.isNotBlank(existingProduct.serialNumber) ? existingProduct.serialNumber + ', ' + item.Serial__c : item.Serial__c;
                }
                
                if (String.isNotBlank(item.Location__r.Sage_ID__c) && !existingProduct.location.contains(item.Location__r.Sage_ID__c)) {
                    existingProduct.location = String.isNotBlank(existingProduct.location) ? existingProduct.location + ', ' + item.Location__r.Sage_ID__c : item.Location__r.Sage_ID__c;
                }
            } else {
                SummarizedProduct newProduct = new SummarizedProduct();
                newProduct.productCode = item.Product2.Sage_ID__c;
                newProduct.productName = item.Product2.Name;
                newProduct.orderQuantity = item.Quantity;
                newProduct.location = String.isNotBlank(item.Location__r.Sage_ID__c) ? item.Location__r.Sage_ID__c : '';
                newProduct.serialNumber = String.isNotBlank(item.Serial__c) ? item.Serial__c : '';
                newProduct.shipmentQuantity = 0;
                newProduct.shippedQuantity = 0;
                productMap.put(key, newProduct);
            }
        }
        
        // Add shipment quantities and calculate total quantity
        for (Id productId : productMap.keySet()) {
            SummarizedProduct product = productMap.get(productId);
            product.shipmentQuantity = shipmentQuantityMap.containsKey(productId) ? shipmentQuantityMap.get(productId) : 0;
            product.shippedQuantity = shippedQuantityMap.containsKey(productId) ? shippedQuantityMap.get(productId) : 0;
            product.quantity = product.orderQuantity + product.shipmentQuantity + product.shippedQuantity;
        }
        
        // Convert map to list, filtering out products with zero total quantity
        this.summarizedProducts = new List<SummarizedProduct>();
        for (SummarizedProduct product : productMap.values()) {
            if (product.quantity != 0) {
                summarizedProducts.add(product);
            }
        }
    }
    
    // ----- Public Wrapper Class -----
    
    /**
     * Wrapper class representing a summarized product for display
     */
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