global class CapacityFinder {
    
    global class Inputs {
        @InvocableVariable(required=true)
        global String contractType;
        
        @InvocableVariable(required=true)
        global List<String> workType;
        
        @InvocableVariable(required=true)
        global String region;
        
        @InvocableVariable(required=true)
        global Date weekEnd;
    }
    
    global class OutputResults {        
        @InvocableVariable
        global List<Capacity__c> availCapacities;
        
        @InvocableVariable
        global Boolean result;

        @InvocableVariable
        global WorkType workType;
        
        @InvocableVariable
        global Boolean isBundle;  // Added for Flow access
    }
    
    // NEW: Wrapper class to hold both WorkType and isBundle
    public class WorkTypeResult {
        public WorkType workType { get; set; }
        public Boolean isBundle { get; set; }
        
        public WorkTypeResult(WorkType workType, Boolean isBundle) {
            this.workType = workType;
            this.isBundle = isBundle;
        }
    }
    
    @InvocableMethod(label='Get Capacities')     
    global static List<OutputResults> GetCapacities(List<Inputs> requests) {         
        List<OutputResults> results = new List<OutputResults>();          

        // Null check for requests list
        if (requests == null || requests.isEmpty()) {
            System.debug('Requests list is null or empty');
            return results;
        }

        // Null check for first request
        if (requests[0] == null) {
            System.debug('First request is null');
            return results;
        }

        // Null check for contractType
        if (String.isBlank(requests[0].contractType)) {
            System.debug('Contract Type is null or blank');
            return results;
        }

        System.debug('requests[0].contractType **** ' + requests[0].contractType);          

        // Null check for region
        if (String.isBlank(requests[0].region)) {
            System.debug('Region is null or blank');
            return results;
        }

        String capRegion = getRegion(requests[0].region);
        
        // Null check for capRegion result
        if (String.isBlank(capRegion)) {
            System.debug('capRegion is null or blank after getRegion call');
            return results;
        }
        
        System.debug('capRegion **** ' + capRegion);         
        
        // Null check for workType list
        if (requests[0].workType == null || requests[0].workType.isEmpty()) {
            System.debug('WorkType list is null or empty');
            return results;
        }

        set<String> workTypeSet = new set<String>();         
        workTypeSet.addALL(requests[0].workType);            

        // Updated to use WorkTypeResult wrapper
        WorkTypeResult workTypeResult = getWorkType(workTypeSet);
        
        // Null check for workTypeResult
        if (workTypeResult == null || workTypeResult.workType == null) {
            System.debug('WorkType is null after getWorkType call');
            return results;
        }
        
        WorkType workType = workTypeResult.workType;
        Boolean isBundle = workTypeResult.isBundle;
        
        System.debug('NOTHING FOUND');          
        System.debug('isBundle: ' + isBundle);

        // Null check for workType.Name
        String capWorkType = (workType.Name != null) ? workType.Name : '';
        
        // Null check for workType.Capacity_Type__c
        String capWorkTypeGeneral = (workType.Capacity_Type__c != null) ? workType.Capacity_Type__c : '';
        
        if (String.isBlank(capWorkTypeGeneral)) {
            System.debug('capWorkTypeGeneral is null or blank');
            return results;
        }
        
        System.debug('capWorkTypeGeneral **** ' + capWorkTypeGeneral);           

        // Null check for weekEnd
        if (requests[0].weekEnd == null) {
            System.debug('WeekEnd is null');
            return results;
        }

        List<Capacity__c> capList = new List<Capacity__c>([
            Select Id, Name, Capacity_Remaining__c, Week_Start__c 
            from Capacity__c                                                              
            WHERE Contract_Type__c =: requests[0].contractType                                                              
            AND Work_Type__c =: capWorkTypeGeneral 
            AND Region__c =: capRegion                                                              
            AND Week_Start__c >=: Date.valueOf(requests[0].weekEnd)                                                              
            AND Week_End__c >=: Date.valueOf(requests[0].weekEnd)                                                             
            AND Capacity_Remaining__c > 0                                                              
            AND CALENDAR_YEAR(Week_End__c) =: requests[0].weekEnd.year()                                                            
            ORDER BY Week_Start__c ASC LIMIT 3
        ]);    
        
        System.debug('capList.size() **** ' + capList.size());          

        if (capList == null || capList.size() == 0) {
            // Verify Custom Metadata Type "Shared Capacity"             
            List<Shared_Capacity__mdt> sharedCapList = new List<Shared_Capacity__mdt>([
                Select Id, DeveloperName, Contract_Type__c, Region__c, Shared_with_Contract_Type__c,                   
                Share_with_Work_Type__c, Work_Type__c 
                from Shared_Capacity__mdt 
                WHERE Shared_with_Contract_Type__c =: requests[0].contractType                  
                AND Region__c =: capRegion 
                AND Share_with_Work_Type__c =: capWorkTypeGeneral
            ]);                   
            
            System.debug('sharedCapList **** ' + sharedCapList);                      

            if (sharedCapList != null && sharedCapList.size() > 0 && sharedCapList[0] != null) {
                // Additional null checks for shared capacity fields
                String sharedContractType = (sharedCapList[0].Contract_Type__c != null) ? sharedCapList[0].Contract_Type__c : '';
                String sharedWorkType = (sharedCapList[0].Work_Type__c != null) ? sharedCapList[0].Work_Type__c : '';
                String sharedRegion = (sharedCapList[0].Region__c != null) ? sharedCapList[0].Region__c : '';
                
                capList = new List<Capacity__c>([
                    Select Id, Name, Capacity_Remaining__c, Week_Start__c 
                    from Capacity__c 
                    WHERE (Contract_Type__c =: sharedContractType OR Contract_Type__c =: requests[0].contractType)                                                   
                    AND (Work_Type__c =: sharedWorkType OR Work_Type__c =: capWorkTypeGeneral) 
                    AND (Region__c =: sharedRegion OR Region__c =: capRegion)                                                   
                    AND Week_Start__c >=: Date.valueOf(requests[0].weekEnd) 
                    AND Week_End__c >=: Date.valueOf(requests[0].weekEnd) 
                    AND Week_Start__c > TODAY
                    AND Capacity_Remaining__c > 0 
                    AND CALENDAR_YEAR(Week_End__c) =: requests[0].weekEnd.year()                                                  
                    ORDER BY Week_Start__c ASC LIMIT 3
                ]);             
            }         
        }         
        
        if (capList != null && capList.size() > 0) {             
            OutputResults opR = new OutputResults();             
            List<Capacity__c> dts = new List<Capacity__c>();             
            for (Capacity__c cp : capList) {
                if (cp != null) {
                    dts.add(cp);
                }
            }             
            opR.availCapacities = dts;             
            opR.result = TRUE;             
            opR.workType = workType;             
            opR.isBundle = isBundle;  // Set isBundle for Flow access
            results.add(opR);         
        } else {             
            OutputResults opR = new OutputResults();             
            opR.result = FALSE;             
            opR.workType = workType;             
            opR.isBundle = isBundle;  // Set isBundle for Flow access
            results.add(opR);         
        }         
        
        return results;     
    }
    
    // Updated getWorkType method using WorkTypeResult wrapper
    public static WorkTypeResult getWorkType(Set<String> productSageIdSet) {
        // Get WorkTypes from WorkType
        Map<String, WorkType> workTypeMap = new Map<String, WorkType>();
        for(WorkType workTyp : [SELECT Id, Name, Capacity_Type__c FROM WorkType WHERE Capacity_Type__c != NULL]) {
            workTypeMap.put(workTyp.Name.toLowerCase(), workTyp);
        }
         
        // Get all WorkType configurations from custom setting, ordered by priority
        List<Ouverture_Fermeture_work_types__c> workTypeSettings = [
            SELECT Name__c, Product_Conditions__c, Priority__c, isBundle__c    
            FROM Ouverture_Fermeture_work_types__c 
            ORDER BY Priority__c ASC
        ];
 
        // Iterate through each work type configuration
        for(Ouverture_Fermeture_work_types__c setting : workTypeSettings) {
 
            String workTypeName = setting.Name__c;
 
            // Skip if the work type is not in the map
            if(!workTypeMap.containsKey(workTypeName.toLowerCase())) {
                continue;
            }
            
            // Parse the condition string
            String conditionStr = setting.Product_Conditions__c;

            System.debug('conditionStr **** ' + conditionStr);

            // Check if the condition is met
            if(evaluateCondition(conditionStr, productSageIdSet)) {
                WorkType foundWorkType = workTypeMap.get(workTypeName.toLowerCase());
                Boolean isBundle = (setting.isBundle__c != null) ? setting.isBundle__c : false;
                
                // Return WorkTypeResult wrapper with both values
                return new WorkTypeResult(foundWorkType, isBundle);
            }
        }
        
        return null;
    }

    private static Boolean evaluateCondition(String conditionStr, Set<String> productSageIdSet) {
        // Handle empty condition
        if(String.isBlank(conditionStr)) {
            return false;
        }
        
        // First, replace product IDs with true/false based on whether they exist in the set
        Pattern productIdPattern = Pattern.compile('\\b(\\d+)\\b');
        Matcher productIdMatcher = productIdPattern.matcher(conditionStr);
        
        String evaluatableCondition = conditionStr;
        System.debug('evaluatableCondition **** ' + evaluatableCondition);

        while(productIdMatcher.find()) {
            String productId = productIdMatcher.group(1);
            Boolean result = productSageIdSet.contains(productId);
            
            // Replace the product ID with its result
            evaluatableCondition = evaluatableCondition.replace(productId, String.valueOf(result));
        }
        
        // Now replace AND/OR with their evaluation operators
        evaluatableCondition = evaluatableCondition.replace(' AND ', ' AND ').replace(' OR ', ' OR ');
        
        // Split by AND and evaluate
        List<String> andGroups = evaluatableCondition.split(' AND ');
        
        for(String andGroup : andGroups) {
            Boolean andResult = false;
            andGroup = andGroup.trim();
            
            // Remove surrounding parentheses if present
            if(andGroup.startsWith('(') && andGroup.endsWith(')')) {
                andGroup = andGroup.substring(1, andGroup.length() - 1).trim();
            }
            
            // Check if this has OR conditions
            if(andGroup.contains(' OR ')) {
                List<String> orGroups = andGroup.split(' OR ');
                
                // If any OR condition is true, the AND group is true
                for(String orCondition : orGroups) {
                    orCondition = orCondition.trim();
                    
                    // Remove surrounding parentheses if present
                    if(orCondition.startsWith('(') && orCondition.endsWith(')')) {
                        orCondition = orCondition.substring(1, orCondition.length() - 1).trim();
                    }
                    
                    if(orCondition.equalsIgnoreCase('true')) {
                        andResult = true;
                        break;
                    }
                }
            } else {
                // Simple AND condition
                andResult = andGroup.equalsIgnoreCase('true');
            }
            
            // If any AND condition is false, the entire expression is false
            if(!andResult) {
                return false;
            }
        }
        
        // All AND conditions evaluated to true
        return true;
    }
     
    /***********************************************************************************
     * 
     * Get the region supported in Capacities Region field
     * Address has => Montréal  Québec  Gatineau    Ontario Nouveau-Brunswick
     * Capacity has => Montreal Quebec  Gatineau/Ontario
     * **********************************************************************************/
    @TestVisible
    public static string getRegion(string addressRegion){
        if(addressRegion.equalsIgnoreCase('montréal')){
            return 'Montreal';
        }
        else if(addressRegion.equalsIgnoreCase('québec')){
            return 'Quebec';
        }
        else if(addressRegion.equalsIgnoreCase('gatineau') || addressRegion.equalsIgnoreCase('ontario')){
            return 'Gatineau/Ontario';
        }
        else if(addressRegion.equalsIgnoreCase('nouveau-brunswick')){
            return 'Quebec';//TODO
        }
        return 'Quebec';//TODO
    }
}
     