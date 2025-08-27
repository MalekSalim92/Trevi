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
			AND Week_Start__c > TODAY
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
     
    
    // @TestVisible
    // public static WorkType getWorkType2(set<string> productSageIdSet){
    //     //Get WorkTypes from WorkType
    //             System.debug('productSageIdSet **** ' + productSageIdSet);

    //     Map<String, WorkType> workTypeMap = new Map<String, WorkType>();
    //     for(WorkType workTyp : [Select Id, Name, Capacity_Type__c from WorkType where Capacity_Type__c != NULL]){
    //         workTypeMap.put(workTyp.Name.toLowerCase(), workTyp);
    //     }
    //                     System.debug('workTypeMap **** ' + workTypeMap);


    //     //Ouverture SC toile avec marche Sel, Sable => 77548 AND 92327 AND 85842 AND 77498 AND 77554 OR 77555
    //     if(workTypeMap.containsKey(('Ouverture SC toile avec marche Sel, Sable').toLowerCase()) && (productSageIdSet.contains('77548') && productSageIdSet.contains('92327') && productSageIdSet.contains('85842') && productSageIdSet.contains('77498') && (productSageIdSet.contains('77554') || productSageIdSet.contains('77555'))))
    //         return workTypeMap.get(('Ouverture SC toile avec marche Sel, Sable').toLowerCase());//'Ouverture SC toile avec marche Sel, Sable';
    //     //Ouverture HT Marche, Toile, Sel, Sable => 77202 AND 92327 AND 85842 AND 77498 AND 77554 OR 77555
    //     else if(workTypeMap.containsKey(('Ouverture HT Marche, Toile, Sel, Sable').toLowerCase()) && (productSageIdSet.contains('77202') && productSageIdSet.contains('92327') && productSageIdSet.contains('85842') && productSageIdSet.contains('77498') && (productSageIdSet.contains('77554') || productSageIdSet.contains('77555'))))
    //         return workTypeMap.get(('Ouverture HT Marche, Toile, Sel, Sable').toLowerCase());//'Ouverture HT Marche, Toile, Sel, Sable';
    //     //Ouverture CR avec toile Sel, Sable => 77204 AND 92327 AND 85842 AND 77467 OR 77477
    //     else if(workTypeMap.containsKey(('Ouverture CR avec toile Sel, Sable').toLowerCase()) && (productSageIdSet.contains('77204') && productSageIdSet.contains('92327') && productSageIdSet.contains('85842') && (productSageIdSet.contains('77467') || productSageIdSet.contains('77477'))))
    //         return workTypeMap.get(('Ouverture CR avec toile Sel, Sable').toLowerCase());//'Ouverture CR avec toile Sel, Sable';
    //     //Ouverture HT avec toile Sel, Sable    =>  77202 AND 92327 AND 85842 AND 77554 OR 77555
    //     else if(workTypeMap.containsKey(('Ouverture HT avec toile Sel, Sable').toLowerCase()) && (productSageIdSet.contains('77202') && productSageIdSet.contains('92327') && productSageIdSet.contains('85842') && (productSageIdSet.contains('77554') || productSageIdSet.contains('77555'))))
    //         return workTypeMap.get(('Ouverture HT avec toile Sel, Sable').toLowerCase());//'Ouverture HT avec toile Sel, Sable';
    //     //Ouverture HT Marche, Toile, Sable =>  77202 AND 85842 AND 77498 AND 77554 OR 77555
    //     else if(workTypeMap.containsKey(('Ouverture HT Marche, Toile, Sable').toLowerCase()) && (productSageIdSet.contains('77202') && productSageIdSet.contains('77498') && productSageIdSet.contains('85842') && (productSageIdSet.contains('77554') || productSageIdSet.contains('77555'))))
    //         return workTypeMap.get(('Ouverture HT Marche, Toile, Sable').toLowerCase());//'Ouverture HT Marche, Toile, Sable';
    //     //Ouverture HT toile avec marche Sel    =>  77202 AND 92327 AND 77498 AND 77554 OR 77555
    //     else if(workTypeMap.containsKey(('Ouverture HT toile avec marche Sel').toLowerCase()) && (productSageIdSet.contains('77202') && productSageIdSet.contains('77498') && productSageIdSet.contains('92327') && (productSageIdSet.contains('77554') || productSageIdSet.contains('77555'))))
    //         return workTypeMap.get(('Ouverture HT toile avec marche Sel').toLowerCase());//'Ouverture HT toile avec marche Sel';
    //     //Ouverture SC avec toile Sel, Sable    =>  77548 AND 92327 AND  85842 AND 77554 OR 77555
    //     else if(workTypeMap.containsKey(('Ouverture SC avec toile Sel, Sable').toLowerCase()) && (productSageIdSet.contains('77548') && productSageIdSet.contains('85842') && productSageIdSet.contains('92327') && (productSageIdSet.contains('77554') || productSageIdSet.contains('77555'))))
    //         return workTypeMap.get(('Ouverture SC avec toile Sel, Sable').toLowerCase());//'Ouverture SC avec toile Sel, Sable';
    //     //Ouverture SC toile avec marche Sel    =>  77548 AND 92327 AND 77498 AND 77554 OR 77555
    //     else if(workTypeMap.containsKey(('Ouverture SC toile avec marche Sel').toLowerCase()) && (productSageIdSet.contains('77548') && productSageIdSet.contains('77498') && productSageIdSet.contains('92327') && (productSageIdSet.contains('77554') || productSageIdSet.contains('77555'))))
    //         return workTypeMap.get(('Ouverture SC toile avec marche Sel').toLowerCase());//'Ouverture SC toile avec marche Sel';
    //     //Ouverture SC toile avec marche, Sable =>  77548 AND  85842 AND 77498 AND 77554 OR 77555
    //     else if(workTypeMap.containsKey(('Ouverture SC toile avec marche, Sable').toLowerCase()) && (productSageIdSet.contains('77548') && productSageIdSet.contains('77498') && productSageIdSet.contains('85842') && (productSageIdSet.contains('77554') || productSageIdSet.contains('77555'))))
    //         return workTypeMap.get(('Ouverture SC toile avec marche, Sable').toLowerCase());//'Ouverture SC toile avec marche, Sable';
    //     //Ouverture CR avec toile Sel   =>  77204 AND 92327 AND 77467 OR 77477
    //     else if(workTypeMap.containsKey(('Ouverture CR avec toile Sel').toLowerCase()) && (productSageIdSet.contains('77204') && productSageIdSet.contains('92327') && (productSageIdSet.contains('77467') || productSageIdSet.contains('77477'))))
    //         return workTypeMap.get(('Ouverture CR avec toile Sel').toLowerCase());//'Ouverture CR avec toile Sel';
    //     //Ouverture CR avec toile, Sable    =>  77204 AND 85842 AND 77467 OR 77477
    //     else if(workTypeMap.containsKey(('Ouverture CR avec toile, Sable').toLowerCase()) && (productSageIdSet.contains('77204') && productSageIdSet.contains('85842') && (productSageIdSet.contains('77467') || productSageIdSet.contains('77477'))))
    //         return workTypeMap.get(('Ouverture CR avec toile, Sable').toLowerCase());//'Ouverture CR avec toile, Sable';
    //     //Ouverture CR Deluxe Sel, Sable    =>  77532 OR 77500 AND 92327 AND 85842
    //     else if(workTypeMap.containsKey(('Ouverture CR Deluxe Sel, Sable').toLowerCase()) && (productSageIdSet.contains('92327') && productSageIdSet.contains('85842') && (productSageIdSet.contains('77532') || productSageIdSet.contains('77500'))))
    //         return workTypeMap.get(('Ouverture CR Deluxe Sel, Sable').toLowerCase());//'Ouverture CR Deluxe Sel, Sable';
    //     //Ouverture HT avec toile Sel   =>  77202 AND 92327 AND 77554 OR 77555
    //     else if(workTypeMap.containsKey(('Ouverture HT avec toile Sel').toLowerCase()) && (productSageIdSet.contains('77202') && productSageIdSet.contains('92327') && (productSageIdSet.contains('77554') || productSageIdSet.contains('77555'))))
    //         return workTypeMap.get(('Ouverture HT avec toile Sel').toLowerCase());//'Ouverture HT avec toile Sel';
    //     //Ouverture HT avec toile, Sable    =>  77202 AND 85842 AND 77554 OR 77555
    //     else if(workTypeMap.containsKey(('Ouverture HT avec toile, Sable').toLowerCase()) && (productSageIdSet.contains('77202') && productSageIdSet.contains('85842') && (productSageIdSet.contains('77554') || productSageIdSet.contains('77555'))))
    //         return workTypeMap.get(('Ouverture HT avec toile, Sable').toLowerCase());//'Ouverture HT avec toile, Sable';
    //     //Ouverture HT Marche, Sel, Sable   =>  77202 AND 92937 AND 85842 AND 77498
    //     else if(workTypeMap.containsKey(('Ouverture HT Marche, Sel, Sable').toLowerCase()) && (productSageIdSet.contains('77202') && productSageIdSet.contains('92937') && productSageIdSet.contains('85842') && productSageIdSet.contains('77498')))
    //         return workTypeMap.get(('Ouverture HT Marche, Sel, Sable').toLowerCase());//'Ouverture HT Marche, Sel, Sable';
    //     //Ouverture HT toile avec marche    =>  77202 AND 77554 OR 77555 AND 77498
    //     else if(workTypeMap.containsKey(('Ouverture HT toile avec marche').toLowerCase()) && (productSageIdSet.contains('77202') && productSageIdSet.contains('77498') && (productSageIdSet.contains('77554') || productSageIdSet.contains('77555'))))
    //         return workTypeMap.get(('Ouverture HT toile avec marche').toLowerCase());//'Ouverture HT toile avec marche';
    //     //Ouverture SC avec marche Sel, Sable   =>  77548 AND 92327 AND 85842 AND 77498
    //     else if(workTypeMap.containsKey(('Ouverture SC avec marche Sel, Sable').toLowerCase()) && (productSageIdSet.contains('77548') && productSageIdSet.contains('92327') && productSageIdSet.contains('85842') && productSageIdSet.contains('77498')))
    //         return workTypeMap.get(('Ouverture SC avec marche Sel, Sable').toLowerCase());//'Ouverture SC avec marche Sel, Sable';
    //     //Ouverture SC avec toile Sel   =>  77548 AND 92327 AND 77554 OR 77555
    //     else if(workTypeMap.containsKey(('Ouverture SC avec toile Sel').toLowerCase()) && (productSageIdSet.contains('77548') && productSageIdSet.contains('92327') && (productSageIdSet.contains('77554') || productSageIdSet.contains('77555'))))
    //         return workTypeMap.get(('Ouverture SC avec toile Sel').toLowerCase());//'Ouverture SC avec toile Sel';
    //     //Ouverture SC avec toile, Sable    =>  77548 AND  85842 AND 77554 OR 77555
    //     else if(workTypeMap.containsKey(('Ouverture SC avec toile, Sable').toLowerCase()) && (productSageIdSet.contains('77548') && productSageIdSet.contains('85842') && (productSageIdSet.contains('77554') || productSageIdSet.contains('77555'))))
    //         return workTypeMap.get(('Ouverture SC avec toile, Sable').toLowerCase());//'Ouverture SC avec toile, Sable';
    //     //Ouverture SC toile avec marche    =>  77548 AND 77554 OR 77555 AND 77498
    //     else if(workTypeMap.containsKey(('Ouverture SC toile avec marche').toLowerCase()) && (productSageIdSet.contains('77548') && productSageIdSet.contains('77498') && (productSageIdSet.contains('77554') || productSageIdSet.contains('77555'))))
    //         return workTypeMap.get(('Ouverture SC toile avec marche').toLowerCase());//'Ouverture SC toile avec marche';
    //     //Fermeture HT avec toile filet marche  =>  77203 AND 77553 AND 77556 AND 77438
    //     else if(workTypeMap.containsKey(('Fermeture HT avec toile filet marche').toLowerCase()) && (productSageIdSet.contains('77203') && productSageIdSet.contains('77438') && productSageIdSet.contains('77553') && productSageIdSet.contains('77556')))
    //         return workTypeMap.get(('Fermeture HT avec toile filet marche').toLowerCase());//'Fermeture HT avec toile filet marche';
    //     //Fermeture HT avec toile et marche =>  77203 AND 77553 OR 77556 AND 77438
    //     else if(workTypeMap.containsKey(('Fermeture HT avec toile et marche').toLowerCase()) && (productSageIdSet.contains('77203') && productSageIdSet.contains('77438') && (productSageIdSet.contains('77553') || productSageIdSet.contains('77556'))))
    //         return workTypeMap.get(('Fermeture HT avec toile et marche').toLowerCase());//'Fermeture HT avec toile et marche';
    //     //Fermeture SC avec toile et marche =>  77539 AND 77551 OR 77553 AND 77438
    //     else if(workTypeMap.containsKey(('Fermeture SC avec toile et marche').toLowerCase()) && (productSageIdSet.contains('77539') && productSageIdSet.contains('77438') && (productSageIdSet.contains('77551') || productSageIdSet.contains('77553'))))
    //         return workTypeMap.get(('Fermeture SC avec toile et marche').toLowerCase());//'Fermeture SC avec toile et marche';
    //     //Fermeture SC avec toile filet et marche   =>  77539 AND 77551 AND 77553 AND 77438
    //     else if(workTypeMap.containsKey(('Fermeture SC avec toile filet et marche').toLowerCase()) && (productSageIdSet.contains('77539') && productSageIdSet.contains('77438') && productSageIdSet.contains('77551') && productSageIdSet.contains('77553')))
    //         return workTypeMap.get(('Fermeture SC avec toile filet et marche').toLowerCase());//'Fermeture SC avec toile filet et marche';
    //     //Fermeture CR avec toile et marche 77289 AND 77370 OR 77385 AND 77438
    //     //Fermeture CR avec toile, filet et marche  77289 AND 77370 OR 77385 AND 77438
    //     //Fermeture de CR avec toile et marche  77289 AND 77370 OR 77385 AND 77438 //TODO
    //     else if(workTypeMap.containsKey(('Fermeture CR avec toile et marche').toLowerCase()) && (productSageIdSet.contains('77289') && productSageIdSet.contains('77438') && (productSageIdSet.contains('77370') || productSageIdSet.contains('77385'))))
    //         return workTypeMap.get(('Fermeture CR avec toile et marche').toLowerCase());//'Fermeture CR avec toile et marche';
    //     //Ouverture CR avec toile   =>  77204 AND 77467 OR 77477
    //     else if(workTypeMap.containsKey(('Ouverture CR avec toile').toLowerCase()) && (productSageIdSet.contains('77204') && (productSageIdSet.contains('77467') || productSageIdSet.contains('77477'))))
    //         return workTypeMap.get(('Ouverture CR avec toile').toLowerCase());//'Ouverture CR avec toile';
    //     //Ouverture CR Deluxe Sel   =>  77532 OR 77500 AND 92327
    //     else if(workTypeMap.containsKey(('Ouverture CR Deluxe Sel').toLowerCase()) && (productSageIdSet.contains('92327') && (productSageIdSet.contains('77532') || productSageIdSet.contains('77500'))))
    //         return workTypeMap.get(('Ouverture CR Deluxe Sel').toLowerCase());//'Ouverture CR Deluxe Sel';
    //     //Ouverture CR Deluxe, Sable    =>  77532 OR 77500 AND 85842
    //     else if(workTypeMap.containsKey(('Ouverture CR Deluxe, Sable').toLowerCase()) && (productSageIdSet.contains('85842') && (productSageIdSet.contains('77532') || productSageIdSet.contains('77500'))))
    //         return workTypeMap.get(('Ouverture CR Deluxe, Sable').toLowerCase());//'Ouverture CR Deluxe, Sable';
    //     //Ouverture CR Sel, Sable   =>  77204 AND 92327 AND 85842
    //     else if(workTypeMap.containsKey(('Ouverture CR Sel, Sable').toLowerCase()) && (productSageIdSet.contains('85842') && productSageIdSet.contains('77204') && productSageIdSet.contains('92327')))
    //         return workTypeMap.get(('Ouverture CR Sel, Sable').toLowerCase());//'Ouverture CR Sel, Sable';
    //     //Ouverture HT avec toile   =>  77202 AND 77554 OR 77555
    //     else if(workTypeMap.containsKey(('Ouverture HT avec toile').toLowerCase()) && (productSageIdSet.contains('77202') && (productSageIdSet.contains('77554') || productSageIdSet.contains('77555'))))
    //         return workTypeMap.get(('Ouverture HT avec toile').toLowerCase());//'Ouverture HT avec toile';
    //     //Ouverture HT marche Sel   =>  77202 AND 92327 AND 77498
    //     else if(workTypeMap.containsKey(('Ouverture HT marche Sel').toLowerCase()) && (productSageIdSet.contains('77202') && productSageIdSet.contains('92327') && productSageIdSet.contains('77498')))
    //         return workTypeMap.get(('Ouverture HT marche Sel').toLowerCase());//'Ouverture HT marche Sel';
    //     //Ouverture HT marche, Sable    =>  77202 AND 85842 AND 77498
    //     else if(workTypeMap.containsKey(('Ouverture HT marche, Sable').toLowerCase()) && (productSageIdSet.contains('77202') && productSageIdSet.contains('85842') && productSageIdSet.contains('77498')))
    //         return workTypeMap.get(('Ouverture HT marche, Sable').toLowerCase());//'Ouverture HT marche, Sable';
    //     //Ouverture HT Sel, Sable   =>  77202 AND 92327 AND 85842
    //     else if(workTypeMap.containsKey(('Ouverture HT Sel, Sable').toLowerCase()) && (productSageIdSet.contains('77202') && productSageIdSet.contains('92327') && productSageIdSet.contains('85842')))
    //         return workTypeMap.get(('Ouverture HT Sel, Sable').toLowerCase());//'Ouverture HT Sel, Sable';
    //     //Ouverture SC avec marche Sel  =>  77548 AND 92327 AND 77498
    //     else if(workTypeMap.containsKey(('Ouverture SC avec marche Sel').toLowerCase()) && (productSageIdSet.contains('77548') && productSageIdSet.contains('92327') && productSageIdSet.contains('77498')))
    //         return workTypeMap.get(('Ouverture SC avec marche Sel').toLowerCase());//'Ouverture SC avec marche Sel';
    //     //Ouverture SC avec marche, Sable   =>  77548 AND  85842 AND 77498
    //     else if(workTypeMap.containsKey(('Ouverture SC avec marche, Sable').toLowerCase()) && (productSageIdSet.contains('77548') && productSageIdSet.contains('85842') && productSageIdSet.contains('77498')))
    //         return workTypeMap.get(('Ouverture SC avec marche, Sable').toLowerCase());//'Ouverture SC avec marche, Sable';
    //     //Ouverture SC avec toile   =>  77548 AND 77554 OR 77555
    //     else if(workTypeMap.containsKey(('Ouverture SC avec toile').toLowerCase()) && (productSageIdSet.contains('77548') && (productSageIdSet.contains('77554') || productSageIdSet.contains('77555'))))
    //         return workTypeMap.get(('Ouverture SC avec toile').toLowerCase());//'Ouverture SC avec toile';
    //     //Ouverture SC Sel, Sable   =>  77548 AND 92327 AND  85842 
    //     else if(workTypeMap.containsKey(('Ouverture SC Sel, Sable').toLowerCase()) && (productSageIdSet.contains('77548') && productSageIdSet.contains('92327') && productSageIdSet.contains('85842')))
    //         return workTypeMap.get(('Ouverture SC Sel, Sable').toLowerCase());//'Ouverture SC Sel, Sable';
    //     //Fermeture CR avec Sécurapool et marche    =>  77289 OR 77398 AND 77438
    //     else if(workTypeMap.containsKey(('Fermeture CR avec Sécurapool et marche').toLowerCase()) && (productSageIdSet.contains('77438') && (productSageIdSet.contains('77289') || productSageIdSet.contains('77398'))))
    //         return workTypeMap.get(('Fermeture CR avec Sécurapool et marche').toLowerCase());//'Fermeture CR avec Sécurapool et marche';
    //     //Fermeture CR avec toile et filet  =>  77289 AND 77370 AND 77385
    //     else if(workTypeMap.containsKey(('Fermeture CR avec toile et filet').toLowerCase()) && (productSageIdSet.contains('77289') && productSageIdSet.contains('77370') && productSageIdSet.contains('77385')))
    //         return workTypeMap.get(('Fermeture CR avec toile et filet').toLowerCase());//'Fermeture CR avec toile et filet';
    //     //Fermeture CR spa déversoir avec marche    =>  77289 AND 77438 AND 77359
    //     else if(workTypeMap.containsKey(('Fermeture CR spa déversoir avec marche').toLowerCase()) && (productSageIdSet.contains('77289') && productSageIdSet.contains('77438') && productSageIdSet.contains('77359')))
    //         return workTypeMap.get(('Fermeture CR spa déversoir avec marche').toLowerCase());//'Fermeture CR spa déversoir avec marche';
    //     //Fermeture HT avec filet et marche =>  77203 AND 77556 AND 77438
    //     else if(workTypeMap.containsKey(('Fermeture HT avec filet et marche').toLowerCase()) && (productSageIdSet.contains('77203') && productSageIdSet.contains('77556') && productSageIdSet.contains('77438')))
    //         return workTypeMap.get(('Fermeture HT avec filet et marche').toLowerCase());//'Fermeture HT avec filet et marche';
    //     //Fermeture HT avec toile et filet  =>  77203 AND 77553 AND 77556
    //     else if(workTypeMap.containsKey(('Fermeture HT avec toile et filet').toLowerCase()) && (productSageIdSet.contains('77203') && productSageIdSet.contains('77553') && productSageIdSet.contains('77556')))
    //         return workTypeMap.get(('Fermeture HT avec toile et filet').toLowerCase());//'Fermeture HT avec toile et filet';
    //     //Fermeture HT toile    =>  77203 AND 77553 OR 77556
    //     else if(workTypeMap.containsKey(('Fermeture HT toile').toLowerCase()) && (productSageIdSet.contains('77203') && (productSageIdSet.contains('77553') || productSageIdSet.contains('77556'))))
    //         return workTypeMap.get(('Fermeture HT toile').toLowerCase());//'Fermeture HT toile';
    //     //Fermeture SC avec toile et filet  =>  77539 AND 77551 AND 77553
    //     else if(workTypeMap.containsKey(('Fermeture SC avec toile et filet').toLowerCase()) && (productSageIdSet.contains('77539') && productSageIdSet.contains('77551') && productSageIdSet.contains('77553')))
    //         return workTypeMap.get(('Fermeture SC avec toile et filet').toLowerCase());//'Fermeture SC avec toile et filet';
    //     //Fermeture SC avec toile   =>  77539 AND 77551 OR 77553
    //     else if(workTypeMap.containsKey(('Fermeture SC avec toile').toLowerCase()) && (productSageIdSet.contains('77539') && (productSageIdSet.contains('77551') || productSageIdSet.contains('77553'))))
    //         return workTypeMap.get(('Fermeture SC avec toile').toLowerCase());//'Fermeture SC avec toile';
    //     //Fermeture SC filet et marche  =>  77539 AND 77551 AND 77438
    //     else if(workTypeMap.containsKey(('Fermeture SC filet et marche').toLowerCase()) && (productSageIdSet.contains('77539') && productSageIdSet.contains('77551') && productSageIdSet.contains('77438')))
    //         return workTypeMap.get(('Fermeture SC filet et marche').toLowerCase());//'Fermeture SC filet et marche';
    //     //Fermeture CR avec toile   =>  77289 AND 77370 OR 77385
    //     //Fermeture de CR avec toile    =>  77289 AND 77370 OR 77385 //TODO
    //     else if(workTypeMap.containsKey(('Fermeture CR avec toile').toLowerCase()) && (productSageIdSet.contains('77289') && (productSageIdSet.contains('77370') || productSageIdSet.contains('77385'))))
    //         return workTypeMap.get(('Fermeture CR avec toile').toLowerCase());//'Fermeture CR avec toile';//Fermeture de CR avec toile
    //     //Ouverture CR Sable    =>  77204 AND 85842
    //     else if(workTypeMap.containsKey(('Ouverture CR Sable').toLowerCase()) && (productSageIdSet.contains('77204') && productSageIdSet.contains('85842')))
    //         return workTypeMap.get(('Ouverture CR Sable').toLowerCase());//'Ouverture CR Sable';
    //     //Ouverture CR Sel  =>  77204 AND 92327
    //     else if(workTypeMap.containsKey(('Ouverture CR Sel').toLowerCase()) && (productSageIdSet.contains('77204') && productSageIdSet.contains('92327')))
    //         return workTypeMap.get(('Ouverture CR Sel').toLowerCase());//'Ouverture CR Sel';
    //     //Ouverture HT marche   =>  77202 AND 77498
    //     else if(workTypeMap.containsKey(('Ouverture HT marche').toLowerCase()) && (productSageIdSet.contains('77202') && productSageIdSet.contains('77498')))
    //         return workTypeMap.get(('Ouverture HT marche').toLowerCase());//'Ouverture HT marche';
    //     //Ouverture HT Sel  =>  77202 AND 92327
    //     else if(workTypeMap.containsKey(('Ouverture HT Sel').toLowerCase()) && (productSageIdSet.contains('77202') && productSageIdSet.contains('92327')))
    //         return workTypeMap.get(('Ouverture HT Sel').toLowerCase());//'Ouverture HT Sel';
    //     //Ouverture HT, Sable   =>  77202 AND 85842
    //     else if(workTypeMap.containsKey(('Ouverture HT, Sable').toLowerCase()) && (productSageIdSet.contains('77202') && productSageIdSet.contains('85842')))
    //         return workTypeMap.get(('Ouverture HT, Sable').toLowerCase());//'Ouverture HT, Sable';
    //     //Ouverture SC avec marche  =>  77548 AND 77498
    //     else if(workTypeMap.containsKey(('Ouverture SC avec marche').toLowerCase()) && (productSageIdSet.contains('77548') && productSageIdSet.contains('77498')))
    //         return workTypeMap.get(('Ouverture SC avec marche').toLowerCase());//'Ouverture SC avec marche';
    //     //Ouverture SC Sel  =>  77548 AND 92327
    //     else if(workTypeMap.containsKey(('Ouverture SC Sel').toLowerCase()) && (productSageIdSet.contains('77548') && productSageIdSet.contains('92327')))
    //         return workTypeMap.get(('Ouverture SC Sel').toLowerCase());//'Ouverture SC Sel';
    //     //Ouverture SC, Sable   =>  77548 AND  85842
    //     else if(workTypeMap.containsKey(('Ouverture SC, Sable').toLowerCase()) && (productSageIdSet.contains('77548') && productSageIdSet.contains('85842')))
    //         return workTypeMap.get(('Ouverture SC, Sable').toLowerCase());//'Ouverture SC, Sable';
    //     //Fermeture CR avec filet   =>  77289 AND 77370
    //     //Fermeture CR avec filet et marche =>  77289 AND 77370 //TODO
    //     else if(workTypeMap.containsKey(('Fermeture CR avec filet').toLowerCase()) && (productSageIdSet.contains('77289') && productSageIdSet.contains('77370')))
    //         return workTypeMap.get(('Fermeture CR avec filet').toLowerCase());//'Fermeture CR avec filet';
    //     //Fermeture CR avec marche  =>  77289 AND 77438
    //     else if(workTypeMap.containsKey(('Fermeture CR avec marche').toLowerCase()) && (productSageIdSet.contains('77289') && productSageIdSet.contains('77438')))
    //         return workTypeMap.get(('Fermeture CR avec marche').toLowerCase());//'Fermeture CR avec marche';
    //     //Fermeture CR spa déversoir    =>  77289 AND 77359
    //     else if(workTypeMap.containsKey(('Fermeture CR spa déversoir').toLowerCase()) && (productSageIdSet.contains('77289') && productSageIdSet.contains('77359')))
    //         return workTypeMap.get(('Fermeture CR spa déversoir').toLowerCase());//'Fermeture CR spa déversoir';
    //     //Fermeture HT filet    =>  77203 AND 77556
    //     else if(workTypeMap.containsKey(('Fermeture HT filet').toLowerCase()) && (productSageIdSet.contains('77203') && productSageIdSet.contains('77556')))
    //         return workTypeMap.get(('Fermeture HT filet').toLowerCase());//'Fermeture HT filet';
    //     //Fermeture HT marche   =>  77203 AND 77438
    //     else if(workTypeMap.containsKey(('Fermeture HT marche').toLowerCase()) && (productSageIdSet.contains('77203') && productSageIdSet.contains('77438')))
    //         return workTypeMap.get(('Fermeture HT marche').toLowerCase());//'Fermeture HT marche';
    //     //Fermeture SC avec filet   =>  77539 AND 77551
    //     else if(workTypeMap.containsKey(('Fermeture SC avec filet').toLowerCase()) && (productSageIdSet.contains('77539') && productSageIdSet.contains('77551')))
    //         return workTypeMap.get(('Fermeture SC avec filet').toLowerCase());//'Fermeture SC avec filet';
    //     //Fermeture SC marche   =>  77539 AND 77438
    //     else if(workTypeMap.containsKey(('Fermeture SC marche').toLowerCase()) && (productSageIdSet.contains('77539') && productSageIdSet.contains('77438')))
    //         return workTypeMap.get(('Fermeture SC marche').toLowerCase());//'Fermeture SC marche';
    //     //Ouverture CR Deluxe   =>  77532 OR 77500
    //     else if(workTypeMap.containsKey(('Ouverture CR Deluxe').toLowerCase()) && (productSageIdSet.contains('77532') || productSageIdSet.contains('77500')))
    //         return workTypeMap.get(('Ouverture CR Deluxe').toLowerCase());//'Ouverture CR Deluxe';
    //     //Fermeture CR avec Sécurapool  =>  77289 OR 77398
    //     else if(workTypeMap.containsKey(('Fermeture CR avec Sécurapool').toLowerCase()) && (productSageIdSet.contains('77289') || productSageIdSet.contains('77398')))
    //         return workTypeMap.get(('Fermeture CR avec Sécurapool').toLowerCase());//'Fermeture CR avec Sécurapool';
    //     //Vider laver CR 32' et plus    =>  77532
    //     else if(workTypeMap.containsKey(('Vider laver CR 32\' et plus').toLowerCase()) && (productSageIdSet.contains('77532')))
    //         return workTypeMap.get(('Vider laver CR 32\' et plus').toLowerCase());//'Vider laver CR 32\' et plus';
    //     //Vider laver CR moins de 32'   =>  77500
    //     else if(workTypeMap.containsKey(('Vider laver CR moins de 32\'').toLowerCase()) && (productSageIdSet.contains('77500')))
    //         return workTypeMap.get(('Vider laver CR moins de 32\'').toLowerCase());//'Vider laver CR moins de 32\'';
    //     //Ouverture CR  =>  77204
    //     else if(workTypeMap.containsKey(('Ouverture CR').toLowerCase()) && (productSageIdSet.contains('77204')))
    //         return workTypeMap.get(('Ouverture CR').toLowerCase());//'Ouverture CR';
    //     //Ouverture HT  =>  77202
    //     else if(workTypeMap.containsKey(('Ouverture HT').toLowerCase()) && (productSageIdSet.contains('77202')))
    //         return workTypeMap.get(('Ouverture HT').toLowerCase());//'Ouverture HT';
    //     //Ouverture SC  =>  77548
    //     else if(workTypeMap.containsKey(('Ouverture SC').toLowerCase()) && (productSageIdSet.contains('77548')))
    //         return workTypeMap.get(('Ouverture SC').toLowerCase());//'Ouverture SC';
    //     //Ouverture SPA nature  =>  77567
    //     else if(workTypeMap.containsKey(('Ouverture SPA nature').toLowerCase()) && (productSageIdSet.contains('77567')))
    //         return workTypeMap.get(('Ouverture SPA nature').toLowerCase());//'Ouverture SPA nature';
    //     //Ouverture Val-Mar =>  35539
    //     else if(workTypeMap.containsKey(('Ouverture Val-Mar').toLowerCase()) && (productSageIdSet.contains('35539')))
    //         return workTypeMap.get(('Ouverture Val-Mar').toLowerCase());//'Ouverture Val-Mar';
    //     //Fermeture CR  =>  77289
    //     //Fermeture CR neuve    =>  77289   //TODO
    //     else if(workTypeMap.containsKey(('Fermeture CR').toLowerCase()) && (productSageIdSet.contains('77289')))
    //         return workTypeMap.get(('Fermeture CR').toLowerCase());//'Fermeture CR';
    //     //Fermeture HT  =>  77203
    //     else if(workTypeMap.containsKey(('Fermeture HT').toLowerCase()) && (productSageIdSet.contains('77203')))
    //         return workTypeMap.get(('Fermeture HT').toLowerCase());//'Fermeture HT';
    //     //Fermeture SC  =>  77539
    //     else if(workTypeMap.containsKey(('Fermeture SC').toLowerCase()) && (productSageIdSet.contains('77539')))
    //         return workTypeMap.get(('Fermeture SC').toLowerCase());//'Fermeture SC';
    //     //Fermeture SPA nature  =>  77564
    //     else if(workTypeMap.containsKey(('Fermeture SPA nature').toLowerCase()) && (productSageIdSet.contains('77539')))
    //         return workTypeMap.get(('Fermeture SPA nature').toLowerCase());//'Fermeture SPA nature';
    //     //Fermeture Spa =>  77207
    //     else if(workTypeMap.containsKey(('Fermeture Spa').toLowerCase()) && (productSageIdSet.contains('77207')))
    //         return workTypeMap.get(('Fermeture Spa').toLowerCase());//'Fermeture Spa';
    //     //Ouverture Spa =>  77206
    //     else if(workTypeMap.containsKey(('Ouverture Spa').toLowerCase()) && (productSageIdSet.contains('77206')))
    //         return workTypeMap.get(('Ouverture Spa').toLowerCase());//'Ouverture Spa';
    //     //Ouverture Spa nage    =>  77560
    //     else if(workTypeMap.containsKey(('Ouverture Spa nage').toLowerCase()) && (productSageIdSet.contains('77560')))
    //         return workTypeMap.get(('Ouverture Spa nage').toLowerCase());//'Ouverture Spa nage';
    //     return null;
    // }