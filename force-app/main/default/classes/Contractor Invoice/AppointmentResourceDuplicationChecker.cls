/**
 * AppointmentResourceDuplicationChecker
 *
 * Checks for duplications among Appointment_Resource__c records.
 * Highlights duplicates by setting Description__c (Green/Yellow/Red) and 
 * listing duplicate links in TECH_Duplicates__c.
 *
 * Author: Malek Brachemi
 * Date: 2025-05-25
 */
public class AppointmentResourceDuplicationChecker {

    /**
     * Wrapper class for InvocableMethod input
     */
    public class RequestWrapper {
        @InvocableVariable(label='Appointment Resources')
        public List<Appointment_Resource__c> AppointmentResource;
    }

    /**
     * Invocable method to check duplications in appointment resources.
     * @param requests List of RequestWrapper containing Appointment Resources
     * @return A list of lists of Appointment_Resource__c with duplication info
     */
    @InvocableMethod(label='Check Duplications' Description='Check for duplications in Appointment Resources')
    public static List<List<Appointment_Resource__c>> checkDuplications(List<RequestWrapper> requests) {
        List<List<Appointment_Resource__c>> appointmentResourcesCollection = new List<List<Appointment_Resource__c>>();

        // Validate input
        if (requests == null || requests.isEmpty() || requests[0] == null || requests[0].AppointmentResource == null || requests[0].AppointmentResource.isEmpty()) {
            System.debug('No appointment resources provided');
            appointmentResourcesCollection.add(new List<Appointment_Resource__c>());
            return appointmentResourcesCollection;
        }

        List<Appointment_Resource__c> inputResources = requests[0].AppointmentResource;
        Set<Id> appResIds = new Set<Id>();

        // Collect valid IDs
        for (Appointment_Resource__c resource : inputResources) {
            if (resource != null && resource.Id != null) {
                appResIds.add(resource.Id);
            }
        }

        if (appResIds.isEmpty()) {
            System.debug('No valid appointment resource IDs found');
            appointmentResourcesCollection.add(new List<Appointment_Resource__c>());
            return appointmentResourcesCollection;
        }

        // Query all other Appointment Resources
        List<Appointment_Resource__c> allOtherResources = [
            SELECT Id, Name, All_Products__c, Service_Appointment__c, Account_Sage_ID__c, Order__r.Order_Number__c,
                   Description__c, TECH_Duplicates__c, TECH_Resource_Name__c, TECH_Resource_Account_Id__c, TECH_Ressource_Account__c,
                   TECH_Service_Appointment__c, TECH_Work_Type__c, Total__c
            FROM Appointment_Resource__c
        ];

        // Query input resources with all relevant fields
        List<Appointment_Resource__c> resources = [
            SELECT Id, Name, All_Products__c, Service_Appointment__c, Account_Sage_ID__c, Order__r.Order_Number__c,
                   Description__c, TECH_Duplicates__c, TECH_Resource_Name__c, TECH_Resource_Account_Id__c, TECH_Ressource_Account__c,
                   TECH_Service_Appointment__c, TECH_Work_Type__c, Total__c
            FROM Appointment_Resource__c
            WHERE Id IN :appResIds
        ];

        if (resources.isEmpty()) {
            System.debug('No resources found for provided IDs');
            appointmentResourcesCollection.add(new List<Appointment_Resource__c>());
            return appointmentResourcesCollection;
        }

        // Initialize all resources as Green (no duplicates) and clear TECH_Duplicates__c
        for (Appointment_Resource__c resource : resources) {
            if (resource != null) {
                resource.Description__c = 'Green';
                resource.TECH_Duplicates__c = '';
            }
        }

        // Map to hold duplicate links for each resource
        Map<Integer, List<String>> resourceDuplicateLinks = new Map<Integer, List<String>>();

        // Compare each input resource against all others
        for (Integer i = 0; i < resources.size(); i++) {
            resourceDuplicateLinks.put(i, new List<String>());
            Appointment_Resource__c record1 = resources[i];
            if (record1 == null) continue;

            for (Appointment_Resource__c record2 : allOtherResources) {
                if (record2 == null || record1.Id == record2.Id) continue;

                // Normalize product lists and check for overlap
                Set<String> products1 = normalizeProducts(record1.All_Products__c);
                Set<String> products2 = normalizeProducts(record2.All_Products__c);
                Boolean hasCommonProducts = hasProductOverlap(products1, products2);

                // Safe comparisons for duplication criteria
                Boolean sameContractNumber = record1.Order__r?.Order_Number__c != null &&
                                             record2.Order__r?.Order_Number__c != null &&
                                             record1.Order__r.Order_Number__c == record2.Order__r.Order_Number__c;

                Boolean sameAccount = record1.TECH_Resource_Account_Id__c != null &&
                                      record2.TECH_Resource_Account_Id__c != null &&
                                      record1.TECH_Resource_Account_Id__c == record2.TECH_Resource_Account_Id__c;

                Boolean sameAppointment = record1.Service_Appointment__c != null &&
                                          record2.Service_Appointment__c != null &&
                                          record1.Service_Appointment__c == record2.Service_Appointment__c;

                // Base duplication criteria: common products + same contract + same appointment
                Boolean baseDuplication = hasCommonProducts && sameContractNumber && sameAppointment;

                if (baseDuplication) {
                    // Add clickable links for duplicates
                    String recordLink = '<a href="/' + record2.Id + '" target="_blank">' + record2.Name + '</a>' +
                                        ' - <a href="/' + record2.TECH_Resource_Account_Id__c + '" target="_blank">' + record2.TECH_Ressource_Account__c + '</a>';
                    resourceDuplicateLinks.get(i).add(recordLink);

                    // Set color: Red if same account, Yellow otherwise
                    if (sameAccount) {
                        record1.Description__c = 'Red';
                    } else if (record1.Description__c != 'Red') {
                        record1.Description__c = 'Yellow';
                    }
                }
            }
        }

        // Concatenate duplicate links and assign to TECH_Duplicates__c
        for (Integer i = 0; i < resources.size(); i++) {
            List<String> duplicateLinks = resourceDuplicateLinks.get(i);
            if (duplicateLinks != null && !duplicateLinks.isEmpty()) {
                resources[i].TECH_Duplicates__c = String.join(duplicateLinks, ', ');
            }
        }

        appointmentResourcesCollection.add(resources);
        return appointmentResourcesCollection;
    }

    /**
     * Helper method to check if two sets of products overlap
     * @param products1 Set of product strings
     * @param products2 Set of product strings
     * @return True if any product exists in both sets
     */
    private static Boolean hasProductOverlap(Set<String> products1, Set<String> products2) {
        if (products1 == null || products2 == null || products1.isEmpty() || products2.isEmpty()) return false;
        for (String product : products1) {
            if (products2.contains(product)) return true;
        }
        return false;
    }

    /**
     * Helper method to normalize a comma-separated product string
     * Removes blank entries and ProductCode '10'
     * @param allProducts Comma-separated product string
     * @return Set of normalized product strings
     */
    private static Set<String> normalizeProducts(String allProducts) {
        Set<String> normalizedProducts = new Set<String>();
        if (String.isNotBlank(allProducts)) {
            List<String> productList = allProducts.split(',');
            for (String product : productList) {
                if (String.isNotBlank(product)) {
                    String trimmedProduct = product.trim();
                    if (trimmedProduct != '10') normalizedProducts.add(trimmedProduct);
                }
            }
        }
        return normalizedProducts;
    }
}