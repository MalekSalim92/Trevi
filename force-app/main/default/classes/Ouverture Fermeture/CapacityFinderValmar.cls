global class CapacityFinderValmar {
    
    global class Inputs {
        @InvocableVariable(required=true)
        global String contractType;
        
        @InvocableVariable(required=true)
        global List<String> workType;
        
        @InvocableVariable(required=true)
        global String region;
        
        @InvocableVariable(required=true)
        global Date weekEnd;
        
		@InvocableVariable(required=true)
        global Integer timeOuverture;
        
		@InvocableVariable(required=true)
        global Integer timeViderLaver;
        
		@InvocableVariable(required=true)
        global Integer timeFermeture;
    }
    
    global class OutputResults {        
        @InvocableVariable
        global List<Capacity__c> availCapacities;
        
        @InvocableVariable
        global String workType;
        
        @InvocableVariable
        global String capRegion;
        
        @InvocableVariable
        global Boolean result;
    }
    
    @InvocableMethod(label='Get Capacities Valmar')
    global static List<OutputResults> GetCapacities(List<Inputs> requests) {
        List<OutputResults> results = new List<OutputResults>();
        System.debug('requests **** ' + requests);
        String capRegion = getRegion(requests[0].region);
        System.debug('capRegion **** ' + capRegion);
        set<String> workTypeSet = new set<String>();
        workTypeSet.addALL(requests[0].workType);
        List<String> workTypeResult = getWorkType(workTypeSet,requests[0].timeOuverture,requests[0].timeViderLaver,requests[0].timeFermeture);
        String capWorkType = workTypeResult[0];
        String workType = workTypeResult[1];
        System.debug('capWorkType **** ' + capWorkType);
        List<Capacity__c> capList = new  List<Capacity__c>([Select Id, Name, Capacity_Remaining__c, Week_Start__c from Capacity__c 
                                                            WHERE Contract_Type__c =: requests[0].contractType 
                                                            AND Work_Type__c =: capWorkType AND Region__c =: capRegion 
                                                            AND Week_Start__c >=: Date.valueOf(requests[0].weekEnd) 
                                                            AND Week_End__c >=: Date.valueOf(requests[0].weekEnd)
                                                            AND Capacity_Remaining__c > 0 
                                                            AND CALENDAR_YEAR(Week_End__c) =: requests[0].weekEnd.year()
                                                           ORDER BY Week_Start__c ASC LIMIT 3]);
        if(capList.size() == 0){//Verify Custom Metadata Type "Shared Capacity"
            List<Shared_Capacity__mdt> sharedCapList = new List<Shared_Capacity__mdt>(
                [Select Id, DeveloperName, Contract_Type__c, Region__c, Shared_with_Contract_Type__c, 
                 Share_with_Work_Type__c, Work_Type__c from Shared_Capacity__mdt WHERE Shared_with_Contract_Type__c =: requests[0].contractType
                 AND Region__c =: capRegion AND Share_with_Work_Type__c =: capWorkType]);
            if(sharedCapList.size() > 0){
                capList = new  List<Capacity__c>([Select Id, Name, Capacity_Remaining__c, Week_Start__c from Capacity__c WHERE (Contract_Type__c =: sharedCapList[0].Contract_Type__c OR Contract_Type__c =: requests[0].contractType)
                                                  AND (Work_Type__c =: sharedCapList[0].Work_Type__c OR Work_Type__c =: capWorkType) AND (Region__c =: sharedCapList[0].Region__c OR Region__c =: capRegion)
                                                  AND Week_Start__c >=: Date.valueOf(requests[0].weekEnd) AND Week_End__c >=: Date.valueOf(requests[0].weekEnd) AND Capacity_Remaining__c > 0 AND CALENDAR_YEAR(Week_End__c) =: requests[0].weekEnd.year()
                                                 ORDER BY Week_Start__c ASC LIMIT 3]);
            }
        }
        if(capList.size() > 0){
            OutputResults opR = new OutputResults();
            List<Capacity__c> dts = new List<Capacity__c>();
            for(Capacity__c cp : capList){
                dts.add(cp);
            }
            opR.availCapacities = dts;
            opR.workType = workType;
            opR.capRegion = capRegion;
            opR.result = TRUE;
            results.add(opR);
        }else{
            OutputResults opR = new OutputResults();
            opR.workType = workType;
            opR.capRegion = capRegion;
            opR.result = FALSE;
            results.add(opR);
        }
        return results;
    }
    
	/***********************************************************************************
	 * 
	 * Get the region supported in Capacities Region field
	 * Address has => Montréal	Québec	Gatineau	Ontario	Nouveau-Brunswick
	 * Capacity has => Montreal	Quebec	Gatineau/Ontario
	 * **********************************************************************************/
	@TestVisible
    static string getRegion(string addressRegion){
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
    
    @TestVisible
    static List<String> getWorkType(set<string> productSageIdSet,Integer timeOuverture,Integer timeViderLaver,Integer timeFermeture){
        List<String> resReturn = new List<string>();
        //Get WorkTypes from WorkType
        Map<String, WorkType> workTypeMap = new Map<String, WorkType>();
        List<WorkType> listWorkType = new List<WorkType>();
        if(timeViderLaver > 0 ) {
            if(timeViderLaver <=1)
            	listWorkType = [Select Id, Name, Capacity_Type__c from WorkType where Capacity_Type__c != NULL AND Name = 'Vider Laver Val-Mar 1h'];
            if(timeViderLaver > 1 && timeViderLaver <=2)
            	listWorkType = [Select Id, Name, Capacity_Type__c from WorkType where Capacity_Type__c != NULL AND Name = 'Vider Laver Val-Mar 2h'];
            if(timeViderLaver > 2 && timeViderLaver <=3)
            	listWorkType = [Select Id, Name, Capacity_Type__c from WorkType where Capacity_Type__c != NULL AND Name = 'Vider Laver Val-Mar 3h'];
            if(timeViderLaver > 3 && timeViderLaver <=4)
            	listWorkType = [Select Id, Name, Capacity_Type__c from WorkType where Capacity_Type__c != NULL AND Name = 'Vider Laver Val-Mar 4h'];
            if(timeViderLaver > 4)
            	listWorkType = [Select Id, Name, Capacity_Type__c from WorkType where Capacity_Type__c != NULL AND Name = 'Vider Laver Val-Mar 5h et plus'];
        } else if(timeOuverture > 0 ) {
            	listWorkType = [Select Id, Name, Capacity_Type__c from WorkType where Capacity_Type__c != NULL AND Name = 'Ouverture Val-Mar'];
        } else if(timeFermeture > 0 ) {
            if(timeFermeture <=1)
            	listWorkType = [Select Id, Name, Capacity_Type__c from WorkType where Capacity_Type__c != NULL AND Name = 'Fermeture Val-Mar 1h'];
            if(timeFermeture > 1 && timeFermeture <=2)
            	listWorkType = [Select Id, Name, Capacity_Type__c from WorkType where Capacity_Type__c != NULL AND Name = 'Fermeture Val-Mar 2h'];
            if(timeFermeture > 2 && timeFermeture <=3)
            	listWorkType = [Select Id, Name, Capacity_Type__c from WorkType where Capacity_Type__c != NULL AND Name = 'Fermeture Val-Mar 3h'];
            if(timeFermeture > 3 && timeFermeture <=4)
            	listWorkType = [Select Id, Name, Capacity_Type__c from WorkType where Capacity_Type__c != NULL AND Name = 'Fermeture Val-Mar 4h'];
            if(timeFermeture > 4)
            	listWorkType = [Select Id, Name, Capacity_Type__c from WorkType where Capacity_Type__c != NULL AND Name = 'Fermeture Val-Mar 5h et plus'];
        }
        resReturn.add(listWorkType[0].Capacity_Type__c);
        resReturn.add(listWorkType[0].Id);
        return resReturn;
    }
}