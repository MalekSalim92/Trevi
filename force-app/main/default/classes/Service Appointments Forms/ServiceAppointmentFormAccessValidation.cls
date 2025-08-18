public with sharing class ServiceAppointmentFormAccessValidation {
    public static Boolean hasValidAccess(Id recordId, String wtg) {
        try {
            ServiceAppointment sa = [SELECT Id, Status, SchedStartTime, WorkTypeId, 
                                    WorkType.Name, ParentRecordId
                                    FROM ServiceAppointment 
                                    WHERE Id = :recordId];
            
            WorkOrderLineItem woli = [SELECT Id, ContractType__c, WorkType.Name, Region__c 
                                    FROM WorkOrderLineItem 
                                    WHERE Id = :sa.ParentRecordId LIMIT 1];
    
            System.debug('wtg Label: ' + wtg);
            System.debug('woli.WorkType.Name : ' + woli.WorkType.Name);
            System.debug('woli.Region__c : ' + woli.Region__c);
            System.debug('sa.Status : ' + sa.Status);
            
            List<Form_Access_Rules__mdt> allRules = Form_Access_Rules__mdt.getAll().values();
           
            System.debug('allRules count: ' + allRules.size());
            
            List<Form_Access_Rules__mdt> matchingContractTypeRules = new List<Form_Access_Rules__mdt>();
            
            // Check if the work type name starts with Ouverture or Fermeture (case-insensitive)
            Boolean isOpeningOrClosingWorkType = false;
            String openingClosingType = '';
            if(woli.WorkType.Name != null) {
                String workTypeLower = woli.WorkType.Name.toLowerCase();
                if(workTypeLower.startsWith('ouverture')) {
                    isOpeningOrClosingWorkType = true;
                    openingClosingType = 'Ouverture';
                } else if(workTypeLower.startsWith('fermeture')) {
                    isOpeningOrClosingWorkType = true;
                    openingClosingType = 'Fermeture';
                }
                System.debug('Work type is Ouverture/Fermeture type: ' + isOpeningOrClosingWorkType + (isOpeningOrClosingWorkType ? ' (' + openingClosingType + ')' : ''));
            }
            
            for(Form_Access_Rules__mdt rule : allRules) {
                if(!rule.Active__c) continue;
                
                // Regular case: Check if the rule matches the contract type
                Boolean matchesByContractType = containsValue(rule.Contract_Types__c, wtg);
                System.debug('matchesByContractType : ' + matchesByContractType);

                // Special case: For Ouverture/Fermeture work types, check if the rule includes the specific type
                Boolean matchesByOpeningClosingType = false;
                if(isOpeningOrClosingWorkType && rule.Work_Types__c != null) {
                    matchesByOpeningClosingType = containsValue(rule.Work_Types__c, openingClosingType);
                }
                
                // Include the rule if either condition is met
                if(matchesByContractType || matchesByOpeningClosingType) {
                    matchingContractTypeRules.add(rule);
                    System.debug('rule WT : ' + rule.Work_Types__c);
                    System.debug('rule Status : ' + rule.Status_Values__c);
                    System.debug('rule Region__c : ' + rule.Region__c);
                    
                    if(matchesByContractType) {
                        System.debug('Found matching rule by contract type: ' + rule.DeveloperName);
                    }
                    if(matchesByOpeningClosingType) {
                        System.debug('Found matching rule by Ouverture/Fermeture type: ' + rule.DeveloperName);
                    }
                }
            }
            
            System.debug('Found ' + matchingContractTypeRules.size() + ' rules matching contract type');
            
            for(Form_Access_Rules__mdt rule : matchingContractTypeRules) {
                System.debug('Checking rule: ' + rule.DeveloperName);
                
                if(rule.Work_Types__c != null && !containsValue(rule.Work_Types__c, woli.WorkType.Name)) {
                    System.debug('Failed work type check');
                    continue;
                }
                
                if(!containsValue(rule.Status_Values__c, sa.Status)) {
                    System.debug('Failed status check');
                    continue;
                }
                
                if(rule.Region__c != null && rule.Region__c.trim() != '') {
                    // If region is specified but doesn't match, skip to next rule
                    if(!containsValue(rule.Region__c, woli.Region__c)) {
                        continue;
                    }
                }
                
                System.debug('rule: ' + rule);
                System.debug('rule.Expiration_Days__c : ' + rule.Expiration_Days__c);
                System.debug('rule.Expiration_Hour__c : ' + rule.Expiration_Hour__c);
                
                 // Only proceed with expiration check if Expiration_Days__c is specified
                if(rule.Expiration_Days__c != null) {
                    // Initialize with the current service appointment scheduled start time
                    DateTime expirationDateTime = sa.SchedStartTime;
                    
                    // Subtract the specified number of days
                    expirationDateTime = expirationDateTime.addDays(-Integer.valueOf(rule.Expiration_Days__c));
                    
                    // If expiration hour is also specified, set that specific hour
                    if(rule.Expiration_Hour__c != null) {
                        // Apply the specific hour to the date after days subtraction
                        expirationDateTime = DateTime.newInstance(
                            expirationDateTime.date(), 
                            Time.newInstance(Integer.valueOf(rule.Expiration_Hour__c), 0, 0, 0)
                        );
                    }
                    
                    System.debug('Calculated expiration time: ' + expirationDateTime);
                    
                    // Check if current time is beyond the expiration time
                    if(DateTime.now() > expirationDateTime) {
                        System.debug('Failed expiration check. Current time: ' + DateTime.now() + ', Expiration: ' + expirationDateTime);
                        continue;
                    }
                }

                System.debug('All checks passed for rule: ' + rule.DeveloperName);
                return true;
            }
            
            System.debug('No matching rules or all rules failed criteria');
            return false;
            
        } catch(Exception e) {
            System.debug('Error validating form access: ' + e.getMessage());
            System.debug('Exception stack trace: ' + e.getStackTraceString());
            return false;
        }
    }
    
       // Helper method to check if a comma-separated list contains a value
       private static Boolean containsValue(String commaSeparatedList, String recordValue) {
        System.debug('contains VALUE  : ' + commaSeparatedList + '  -  ' + recordValue);

        if(String.isBlank(commaSeparatedList) || String.isBlank(recordValue)) return false;
        
        // Convert record value to uppercase for case-insensitive comparison
        String upperRecordValue = recordValue.toUpperCase();
        
        // Split the comma-separated metadata values
        List<String> metadataValues = commaSeparatedList.split(',');
        
        for(String metadataValue : metadataValues) {
            metadataValue = metadataValue.trim().toUpperCase();
 
            if (upperRecordValue == metadataValue || 
                upperRecordValue.startsWith(metadataValue + ' ') || 
                upperRecordValue.endsWith(' ' + metadataValue) || 
                upperRecordValue.contains(' ' + metadataValue + ' ') ||

                upperRecordValue.startsWith(metadataValue + '-') || 
                upperRecordValue.contains(' ' + metadataValue + '-')) {
                return true;
            }
        }
        
        return false;
    }
    
}