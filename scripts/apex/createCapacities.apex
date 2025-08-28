List<String> regions = new List<String>{'Montreal', 'Quebec'};

// All work types
List<String> workTypes = new List<String>{
    'Fermeture CR', 'Fermeture HT', 'Fermeture Spa', 'Ouverture CR', 'Ouverture Deluxe',
    'Ouverture HT', 'Ouverture Spa', 'Ouverture Val-Mar', 'Vider laver Val-Mar', 'Fermeture Val-Mar'
};

List<Capacity__c> capacitiesToInsert = new List<Capacity__c>();

Date today = Date.today();
Date startOfWeek = today.toStartOfWeek();

// Calculate current week number (1-52)
Integer currentWeek = (startOfWeek.dayOfYear() - 1) / 7 + 1;

List<Integer> weekOffsets = new List<Integer>{4, 5, 6}; // weeks to add

for(String region : regions){
    for(String workType : workTypes){
        for(Integer offset : weekOffsets){
            Capacity__c cap = new Capacity__c(
                Contract_Type__c = 'Opening/Closing',
                Work_Type__c = workType,
                Region__c = region,
                Capacity_Remaining__c = 50,
                Week__c = currentWeek + offset,
                Year__c = String.valueOf(Date.today().year())
            );
            capacitiesToInsert.add(cap);
        }
    }
}

if(!capacitiesToInsert.isEmpty()){
    insert capacitiesToInsert;
    System.debug('Created ' + capacitiesToInsert.size() + ' Capacity records.');
} else {
    System.debug('No capacities created.');
}