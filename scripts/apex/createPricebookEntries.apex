// Get target Pricebook
Pricebook2 targetPb = [
    SELECT Id, Name 
    FROM Pricebook2 
    WHERE Name = 'Liste de prix détail - $CAD' 
    LIMIT 1
];

// Get Standard Price Book
Pricebook2 standardPb = [
    SELECT Id, Name 
    FROM Pricebook2 
    WHERE IsStandard = true
    LIMIT 1
];

// Get products with Opening_Closing_Product__c = true
List<Product2> products = [
    SELECT Id, Name 
    FROM Product2 
    WHERE Opening_Closing_Product__c = true
];

List<PricebookEntry> newEntries = new List<PricebookEntry>();

for (Product2 p : products) {

    // Check if Standard Price exists
    Boolean standardExists = [
        SELECT COUNT() 
        FROM PricebookEntry 
        WHERE Product2Id = :p.Id 
        AND Pricebook2Id = :standardPb.Id
    ] > 0;

    if (!standardExists) {
        // Create Standard Price first (mandatory)
        insert new PricebookEntry(
            Pricebook2Id = standardPb.Id,
            Product2Id   = p.Id,
            UnitPrice    = 1, // or any default standard price
            IsActive     = true
        );
    }

    // Check if the product already has a PricebookEntry in target pricebook
    Boolean exists = [
        SELECT COUNT() 
        FROM PricebookEntry 
        WHERE Product2Id = :p.Id 
        AND Pricebook2Id = :targetPb.Id
    ] > 0;

    if (!exists) {
        // Create custom pricebook entry
        newEntries.add(new PricebookEntry(
            Pricebook2Id = targetPb.Id,
            Product2Id   = p.Id,
            UnitPrice    = 5,
            IsActive     = true
        ));
    }
}

if (!newEntries.isEmpty()) {
    insert newEntries;
    System.debug('Created ' + newEntries.size() + ' new PricebookEntries in custom pricebook.');
} else {
    System.debug('No new entries needed, all already exist.');
}