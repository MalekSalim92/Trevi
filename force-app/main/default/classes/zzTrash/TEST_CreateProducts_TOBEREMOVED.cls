public with sharing class TEST_CreateProducts_TOBEREMOVED {
    public static void createProductWithPricebookEntries(String productName, String sageId, Decimal price) {
        try {
            // 1. Create the Product
            Product2 newProduct = new Product2();
            newProduct.Name = productName;
            newProduct.Sage_ID__c = sageId;
            newProduct.IsActive = true;
            insert newProduct;
            
            // 2. Get the Standard Pricebook ID
            Id standardPricebookId = Test.isRunningTest() ? 
                Test.getStandardPricebookId() : 
                [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
            
            // 3. Get the Custom "DETCAD" Pricebook ID
            Id customPricebookId = [SELECT Id FROM Pricebook2 WHERE Sage_ID__c = 'DETCAD' LIMIT 1].Id;
            
            // 4. Create Standard Pricebook Entry with $0 price
            PricebookEntry standardEntry = new PricebookEntry();
            standardEntry.Product2Id = newProduct.Id;
            standardEntry.Pricebook2Id = standardPricebookId;
            standardEntry.UnitPrice = 0;
            standardEntry.IsActive = true;
            insert standardEntry;
            
            // 5. Create Custom Pricebook Entry with the provided price
            PricebookEntry customEntry = new PricebookEntry();
            customEntry.Product2Id = newProduct.Id;
            customEntry.Pricebook2Id = customPricebookId;
            customEntry.UnitPrice = price;
            customEntry.IsActive = true;
            insert customEntry;
            
            System.debug('Successfully created product: ' + productName + 
                        ' with Standard PBE ($0) and Custom PBE ($' + price + ')');
            
        } catch (Exception e) {
            System.debug('Error creating product: ' + e.getMessage());
            throw e;
        }
    }
}