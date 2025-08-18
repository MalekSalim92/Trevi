public with sharing class OuvertureFermetureGenSelectorController {
    
    @AuraEnabled(cacheable=true)
    public static List<MetadataOption> getMetadataRecords(
        String objectApiName,
        String labelFieldFr,
        String labelFieldEn,
        String activeField,
        String staticResourceField,
        String valueField,
        String sortOrderField
    ) {
        try {
            System.debug('Getting metadata for object: ' + objectApiName);
            System.debug('Label field: ' + labelFieldFr);
            System.debug('Label field: ' + labelFieldEn);
            System.debug('Active field: ' + activeField);
            System.debug('Static Resource field: ' + staticResourceField);
             System.debug('Value field: ' + valueField);
             System.debug('sortOrderField: ' + sortOrderField);
            
              // Build dynamic SOQL query
            String query = 'SELECT Id, DeveloperName, MasterLabel, ' + 
            activeField + ', ' + 
            labelFieldFr + ', ' + 
            labelFieldEn + ', ' + 
            staticResourceField + ', ' + 
            sortOrderField + 
            ' FROM ' + objectApiName + 
            ' WHERE ' + activeField + ' = true' +
            ' ORDER BY ' + sortOrderField;

            System.debug('Query: ' + query);
            
            String languageUser = getUserLanguage();
            List<SObject> records = Database.query(query);
            List<MetadataOption> options = new List<MetadataOption>();
            
            System.debug('Found ' + records.size() + ' records');
            
            for (SObject record : records) {
                MetadataOption option = new MetadataOption();
  
                    option.value = (String) record.get('DeveloperName');
                    String labelField = languageUser == 'en_us' ? labelFieldEn : labelFieldFr;
                    option.userLanguage = languageUser;
                    option.label = (String) record.get(labelField);
                    option.staticResourceName = (String) record.get(staticResourceField);
                
                
                 
                options.add(option);
                System.debug('Added option: Value=' + option.value + ', Label=' + option.label);
            }
            
            System.debug('Returning ' + options.size() + ' options');
            return options;
            
        } catch (QueryException e) {
            System.debug('Query Exception: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Database query error: ' + e.getMessage());
        } catch (Exception e) {
            System.debug('General Exception: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error retrieving metadata records: ' + e.getMessage());
        }
    }
    

    // Get user language using UserInfo
    private static String getUserLanguage() {
    String language = UserInfo.getLanguage();
    System.debug('User language: ' + language);
    return language != null ? language.toLowerCase() : 'en_us';
}


    // Wrapper class for metadata options
    public class MetadataOption {
        @AuraEnabled
        public String value { get; set; }
        
        @AuraEnabled
        public String label { get; set; }
        
        @AuraEnabled
        public String staticResourceName { get; set; }
        
        @AuraEnabled
        public String imageUrl { get; set; }
        
        @AuraEnabled
        public String userLanguage { get; set; }

    }
}
