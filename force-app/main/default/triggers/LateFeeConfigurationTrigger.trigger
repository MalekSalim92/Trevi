trigger LateFeeConfigurationTrigger on Late_Fee_Configuration__c (before insert, before update) {
    
    // Get all existing records
    List<Late_Fee_Configuration__c> existingRecords = [
        SELECT Id, Contract_Type__c, Region__c 
        FROM Late_Fee_Configuration__c
    ];
    
    // Build set of existing combinations
    Set<String> existingCombinations = new Set<String>();
    for(Late_Fee_Configuration__c existing : existingRecords) {
        String combination = existing.Contract_Type__c + '|' + existing.Region__c;
        existingCombinations.add(combination);
    }
    
    // Check each new/updated record
    for(Late_Fee_Configuration__c newRecord : Trigger.new) {
        String newCombination = newRecord.Contract_Type__c + '|' + newRecord.Region__c;
        
        // If combination already exists, add error
        if(existingCombinations.contains(newCombination)) {
            newRecord.addError('A configuration with Contract Type "' + newRecord.Contract_Type__c + 
                             '" and Region "' + newRecord.Region__c + '" already exists.');
        }
    }
}