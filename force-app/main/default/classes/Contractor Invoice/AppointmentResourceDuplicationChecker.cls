public class AppointmentResourceDuplicationChecker {
    
    public class RequestWrapper {
        @InvocableVariable(label='Appointment Resources')
        public List<Appointment_Resource__c> AppointmentResource;
    }
    
    @InvocableMethod(label='Check Duplications' Description='Check for duplications in Appointment Resources')
    public static List<List<Appointment_Resource__c>> checkDuplications(List<RequestWrapper> requests) {
        List<List<Appointment_Resource__c>> appointmentResourcesCollection = new List<List<Appointment_Resource__c>>();
        
        // Null check for requests
        if(requests == null || requests.isEmpty() || requests[0] == null || requests[0].AppointmentResource == null || requests[0].AppointmentResource.isEmpty()) {
            System.debug('No appointment resources provided');
            appointmentResourcesCollection.add(new List<Appointment_Resource__c>());
            return appointmentResourcesCollection;
        }
        
        Set<Id> appResIds = new Set<Id>();
        List<Appointment_Resource__c> inputResources = requests[0].AppointmentResource;
        
        // Collect IDs and check for nulls
        for(Appointment_Resource__c resource : inputResources) {
            if(resource != null && resource.Id != null) {
                appResIds.add(resource.Id);
            }
        }
        
        // If no valid IDs, return empty result
        if(appResIds.isEmpty()) {
            System.debug('No valid appointment resource IDs found');
            appointmentResourcesCollection.add(new List<Appointment_Resource__c>());
            return appointmentResourcesCollection;
        }
        
        // Query all other resources
        List<Appointment_Resource__c> allOtherResources = [
            SELECT Id, Name, All_Products__c, Service_Appointment__c, Account_Sage_ID__c, Order__r.Order_Number__c,
            Description__c, TECH_Duplicates__c, TECH_Resource_Name__c, TECH_Resource_Account_Id__c, TECH_Ressource_Account__c,
            TECH_Service_Appointment__c, TECH_Work_Type__c, Total__c
            FROM Appointment_Resource__c
        ];
        
        // Query input resources with all fields
        List<Appointment_Resource__c> resources = [
            SELECT Id, Name, All_Products__c, Service_Appointment__c, Account_Sage_ID__c, Order__r.Order_Number__c,
            Description__c, TECH_Duplicates__c, TECH_Resource_Name__c, TECH_Resource_Account_Id__c, TECH_Ressource_Account__c,
            TECH_Service_Appointment__c, TECH_Work_Type__c, Total__c
            FROM Appointment_Resource__c
            WHERE Id IN :appResIds
        ];
        
        // Check if we got any resources back
        if(resources.isEmpty()) {
            System.debug('No resources found for provided IDs');
            appointmentResourcesCollection.add(new List<Appointment_Resource__c>());
            return appointmentResourcesCollection;
        }
        
        // Initialize all as Green and clear duplicate IDs
        for(Appointment_Resource__c resource : resources) {
            if(resource != null) {
                resource.Description__c = 'Green';
                resource.TECH_Duplicates__c = '';
            }
        }
        
        // Map to collect duplicate links for each resource
        Map<Integer, List<String>> resourceDuplicateLinks = new Map<Integer, List<String>>();
        
        // Compare each input resource against ALL other resources in database
        for(Integer i = 0; i < resources.size(); i++) {
            resourceDuplicateLinks.put(i, new List<String>());
            
            Appointment_Resource__c record1 = resources[i];
            if(record1 == null) continue; // Skip null records
            
            for(Integer j = 0; j < allOtherResources.size(); j++) {
                Appointment_Resource__c record2 = allOtherResources[j];
                
                // Skip if either record is null or if comparing same record
                if(record2 == null || record1.Id == record2.Id) {
                    continue;
                }
                
                // Normalize and compare products
                Set<String> products1 = normalizeProducts(record1.All_Products__c);
                Set<String> products2 = normalizeProducts(record2.All_Products__c);
                
                // Check if there's ANY overlap in products (not exact match)
                Boolean hasCommonProducts = hasProductOverlap(products1, products2);
                
                // Safe comparison with null checks
                Boolean sameContractNumber = (record1.Order__r?.Order_Number__c != null && 
                                            record2.Order__r?.Order_Number__c != null && 
                                            record1.Order__r.Order_Number__c == record2.Order__r.Order_Number__c);
                
                Boolean sameAccount = (record1.TECH_Resource_Account_Id__c != null && 
                                     record2.TECH_Resource_Account_Id__c != null && 
                                     record1.TECH_Resource_Account_Id__c == record2.TECH_Resource_Account_Id__c);
                
                Boolean sameAppointment = (record1.Service_Appointment__c != null && 
                                         record2.Service_Appointment__c != null && 
                                         record1.Service_Appointment__c == record2.Service_Appointment__c);
                
                // Base duplication criteria: common products + same contract + different appointments
                Boolean baseDuplication = hasCommonProducts && sameContractNumber && sameAppointment;
                
                if(baseDuplication) {
                    // Create clickable link with record name
                    String recordLink = '<a href="/' + record2.Id + '" target="_blank">' + record2.Name + '</a>' + ' - ' + '<a href="/' + record2.TECH_Resource_Account_Id__c + '" target="_blank">' + record2.TECH_Ressource_Account__c + '</a>';
                    resourceDuplicateLinks.get(i).add(recordLink);
                    
                    if(sameAccount) {
                        record1.Description__c = 'Red';
                    } else {
                        if(record1.Description__c != 'Red') {
                            record1.Description__c = 'Yellow';
                        }
                    }
                }
            }
        }
        
        // Set the concatenated duplicate links in TECH_Duplicates__c field
        for(Integer i = 0; i < resources.size(); i++) {
            List<String> duplicateLinks = resourceDuplicateLinks.get(i);
            if(duplicateLinks != null && !duplicateLinks.isEmpty()) {
                resources[i].TECH_Duplicates__c = String.join(duplicateLinks, ', ');
            }
        }
        
        appointmentResourcesCollection.add(resources);
        return appointmentResourcesCollection;
    }
    
    // Helper method to check if two product sets have any overlap
    private static Boolean hasProductOverlap(Set<String> products1, Set<String> products2) {
        // If either set is null or empty, no overlap
        if(products1 == null || products2 == null || products1.isEmpty() || products2.isEmpty()) {
            return false;
        }
        
        // Check if there's any common product
        for(String product : products1) {
            if(products2.contains(product)) {
                return true;
            }
        }
        
        return false;
    }
    
    // Helper method to normalize products for comparison
    private static Set<String> normalizeProducts(String allProducts) {
        Set<String> normalizedProducts = new Set<String>();
        
        if(String.isNotBlank(allProducts)) {
            List<String> productList = allProducts.split(',');
            
            for(String product : productList) {
                if(String.isNotBlank(product)) {
                    String trimmedProduct = product.trim();
                    
                    // Skip ProductCode 10
                    if(trimmedProduct != '10') {
                        normalizedProducts.add(trimmedProduct);
                    }
                }
            }
        }
        
        return normalizedProducts;
    }
}