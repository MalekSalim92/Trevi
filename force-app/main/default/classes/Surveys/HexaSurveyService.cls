public with sharing class HexaSurveyService {

    public Order processSurvey(String orderId, String surveyType,Map<String, Object> surveyRecord) {
        try {

            system.debug('orderId = ' + orderId);
            system.debug('surveyType = ' + surveyType);
            system.debug('surveyRecord = ' + surveyRecord);

            Order orderRecord = orderId != null ? [SELECT Id, OrderNumber, RecordType.DeveloperName, Status,
                                        Order_Number__c, Location__c, Location__r.Sage_ID__c,  
                                        Contract_Type__c, Pick_Up_Date__c, Actual_Delivery_Date__c,  
                                        Installation_Date__c, Financing_Amount__c, Designer__c,  
                                        Salesperson_1__c, CreatedDate, Order_Total__c,  
                                        Account_Sage_ID__c, Family_Name__c, First_Name__c, Email__c,  
                                        AccountId, Account.Cellphone__c, Account.Language__c, Account.Phone
                                 FROM Order 
                                 WHERE Id = :orderId
                                 LIMIT 1] : null;

            Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

            String credentialName; 
            Map<String, Object> requestBody;

            switch on surveyType {
                when 'POST_SALE' {
                    credentialName = isSandbox ? 'Hexa_Survey_Post_Sale_Dev' : 'Hexa_Survey_Post_Sale_Prod';
                    requestBody = buildPostSaleBody(orderRecord);
                }
                when 'POST_INSTALLATION' {
                    credentialName = isSandbox ? 'Hexa_Survey_Post_Installation_Dev' : 'Hexa_Survey_Post_Installation_Prod';
                    requestBody = buildPostSaleBody(orderRecord);

                }
                when 'POST_DELIVERY' {
                    credentialName = isSandbox ? 'Hexa_Survey_Post_Delivery_Dev' : 'Hexa_Survey_Post_Delivery_Prod';
                    requestBody = buildPostDeliveryBody(orderRecord);

                }
                when 'POST_SUBMISSION' {
                    credentialName = isSandbox ? 'Hexa_Survey_Post_Submission_Dev' : 'Hexa_Survey_Post_Submission_Prod';
                    requestBody = buildPostSubmissionBody(surveyRecord);

                }

                when else {
                    throw new SurveyException('Invalid survey type: ' + surveyType);
                }
            }

            String testBody = '{"details": [{"url": "https://test.com/12345"}]}';
            HttpResponse res =  buildHttpResponse(credentialName,null,null,'POST',JSON.serialize(requestBody));
   
            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                if (responseMap.containsKey('details')) {
                    List<Object> details = (List<Object>) responseMap.get('details');

                    if (!details.isEmpty()) {
                        Map<String, Object> firstDetail = (Map<String, Object>) details[0];

                        if (firstDetail.containsKey('url')) {
                            String surveyUrl = (String) firstDetail.get('url');

                            switch on surveyType {
                                when 'POST_SALE' {
                                    orderRecord.Post_sale_Survey_URL__c = surveyUrl;
                                }
                                when 'POST_INSTALLATION' {
                                    orderRecord.Installation_Delivery_Survey_URL__c = surveyUrl;
                                }
                                when 'POST_DELIVERY' {
                                    orderRecord.Installation_Delivery_Survey_1_Year_URL__c = surveyUrl;
                                }
                        
                            }

                        }
                    }
                }
                return orderRecord;

            } else {
                throw new SurveyException('HTTP Error: ' + res.getStatusCode() + ' - ' + res.getStatus());
            }
        } catch (Exception e) {
            System.debug('Hexa Survey Error vv: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw new SurveyException('Error processing survey: ' + e.getMessage());
        }
    }



    private Map<String, Object> buildPostSaleBody(Order orderRecord){
        Map<String, Object> requestBody = new Map<String, Object>{
            'contrat_trevi' => orderRecord.Order_Number__c != null ? orderRecord.Order_Number__c : '',
            'succursale' => orderRecord.Location__r?.Sage_ID__c != null ? orderRecord.Location__r.Sage_ID__c : '00',
            'produit_achete' => HexaSurveyUtils.getContractTypeValue(orderRecord.Contract_Type__c),
            'cueillette_en_entrepot' => orderRecord.Pick_Up_Date__c != null,
            'livraison' => orderRecord.Actual_Delivery_Date__c != null,
            'date_de_livraison' => orderRecord.Actual_Delivery_Date__c != null ? String.valueOf(orderRecord.Actual_Delivery_Date__c)  : '',
            'installation' => orderRecord.Installation_Date__c != null,
            'date_installation' => orderRecord.Installation_Date__c != null ? String.valueOf(orderRecord.Installation_Date__c)  : '',
            'financement' => orderRecord.Financing_Amount__c > 0,
            'implication_dessinateur' => orderRecord.Designer__c != null,
            'nom_representant_vente' => orderRecord.Salesperson_1__c != null ? String.valueOf(orderRecord.Salesperson_1__c) : '',
            'date_achat' => orderRecord.CreatedDate,
            'date' => Date.today(),
            'heure' => orderRecord.CreatedDate.format('HH:mm:ss'),
            'montant_total_achat' => String.valueOf(orderRecord.Order_Total__c),
            'id_client' => orderRecord.Account_Sage_ID__c != null ? orderRecord.Account_Sage_ID__c : '',
            'nom_de_famille' => orderRecord.Family_Name__c != null ? orderRecord.Family_Name__c : '',
            'prenom' => orderRecord.First_Name__c != null ? orderRecord.First_Name__c : '',
            'courriel' => orderRecord.Email__c != null ? orderRecord.Email__c : '',
            'telephone' => orderRecord.Account.Cellphone__c != null ? orderRecord.Account.Cellphone__c : 
                          (orderRecord.Account.Phone != null ? orderRecord.Account.Phone : ''),
            'langue' => orderRecord.Account.Language__c == 'F' ? 'fr' : 
                       (orderRecord.Account.Language__c == 'A' ? 'en' : 'fr'),
            'equipe_installation' => ''
        };
        return requestBody;
    }


    private Map<String, Object> buildPostDeliveryBody(Order orderRecord){
 
        Map<String, Object> requestBody = new Map<String, Object>{
            'contrat_trevi' => orderRecord.Order_Number__c != null ? orderRecord.Order_Number__c : '',
            'succursale' => orderRecord.Location__r?.Sage_ID__c != null ? orderRecord.Location__r.Sage_ID__c : '00',
            'produit_achete' => HexaSurveyUtils.getContractTypeValue(orderRecord.Contract_Type__c),
            'cueillette_en_entrepot' => orderRecord.Pick_Up_Date__c != null,
            'livraison' => orderRecord.Actual_Delivery_Date__c != null,
            'date_de_livraison' => orderRecord.Actual_Delivery_Date__c != null ? String.valueOf(orderRecord.Actual_Delivery_Date__c)  : '',
            'installation' => orderRecord.Installation_Date__c != null,
            'date_installation' => orderRecord.Installation_Date__c != null ? String.valueOf(orderRecord.Installation_Date__c)  : '',
            'financement' => orderRecord.Financing_Amount__c > 0,
            'implication_dessinateur' => orderRecord.Designer__c != null,
            'nom_representant_vente' => orderRecord.Salesperson_1__c != null ? String.valueOf(orderRecord.Salesperson_1__c) : '',
            'date_achat' => orderRecord.CreatedDate != null ? orderRecord.CreatedDate : null,
            'date' => Date.today(),
            'heure' => orderRecord.CreatedDate != null ? orderRecord.CreatedDate.format('HH:mm:ss') : '',
            'montant_total_achat' => orderRecord.Order_Total__c != null ? String.valueOf(orderRecord.Order_Total__c) : '0',
            'id_client' => orderRecord.Account_Sage_ID__c != null ? orderRecord.Account_Sage_ID__c : '',
            'nom_de_famille' => orderRecord.Family_Name__c != null ? orderRecord.Family_Name__c : '',
            'prenom' => orderRecord.First_Name__c != null ? orderRecord.First_Name__c : '',
            'courriel' => orderRecord.Email__c != null ? orderRecord.Email__c : '',
            'telephone' => orderRecord.Account.Cellphone__c != null ? orderRecord.Account.Cellphone__c :(orderRecord.Account.Phone != null ? orderRecord.Account.Phone : ''),
            'langue' => orderRecord.Account.Language__c == 'F' ? 'fr' :(orderRecord.Account.Language__c == 'A' ? 'en' : 'fr'),
            'equipe_installation' => ''
            
        };
        return requestBody;
    }

    private Map<String, Object> buildPostSubmissionBody(Map<String, Object> surveyRecord){
        Map<String, Object> requestBody = new Map<String, Object>{
            'contrat_trevi' => surveyRecord.get('contrat_Trevi'),
            'succursale' => surveyRecord.get('succursale'),
            'produit_achete' => surveyRecord.get('produit_Achete'), 
            'cueillette_en_entrepot' => surveyRecord.get('cueillette_en_entrepot'),
            'livraison' => surveyRecord.get('livraison'),
            'date_de_livraison' => surveyRecord.get('date_de_Livraison') != '' ? surveyRecord.get('date_de_Livraison') : surveyRecord.get('date_installation'),
            'installation' => surveyRecord.get('installation'),
            'date_installation' => surveyRecord.get('date_installation'),
            'financement' => surveyRecord.get('financement'),
            'implication_dessinateur' => surveyRecord.get('implication_dessinateur'),
            'nom_representant_vente' => surveyRecord.get('nom_representant_vente'),
            'date_achat' => surveyRecord.get('date_achat'),
            'date' => surveyRecord.get('date'),
            'montant_total_achat' => surveyRecord.get('montant_total_achat'),
            'id_client' => surveyRecord.get('id_client'),
            'nom_de_famille' => surveyRecord.get('nom_de_famille'),
            'prenom' => surveyRecord.get('prenom') != '' ? surveyRecord.get('prenom') : 'N/A',
            'courriel' => surveyRecord.get('courriel'),
            'telephone' => surveyRecord.get('telephone'),
            'langue' => surveyRecord.get('langue'),
            'equipe_installation' => surveyRecord.get('equipe_installation') != null ? surveyRecord.get('equipe_installation') : ''
        };

        return requestBody;
    }

            // Login method to obtain bearer token
            public static String obtainLoginCode() {
                try {
                    // Prepare login request body
                  
                    Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
                    String credentialName = isSandbox ? 'Trevi_Custom_API_Dev' : 'Trevi_Custom_API_Prod';
                    
                    
                   String body = '{"username": "{!$Credential.Username}", "password": "{!$Credential.Password}"}'; 
                   HttpResponse res = buildHttpResponse(credentialName,null,null,'POST',body);
                   
                    // Check the response
                    if (res.getStatusCode() >= 200 && res.getStatusCode() < 300 ) {
                        // Assuming the response is a simple string with the token
                        return res.getBody().trim();
                    } else {
                        // Log and throw error
                        System.debug('Login Error: ' + res.getBody());
                        throw new SurveyException('Login Failed: ' + res.getStatusCode());
                    }
                } catch (Exception e) {
                    System.debug('Login Exception: ' + e.getMessage());
                    throw new SurveyException('Login Error: ' + e.getMessage());
                }
            }
            
                
                // Method to get Sondage records
         public static List<Object> getSondageRecords(String bearerToken, String mdfDateTime) {
                    try {
                        
                        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
                        String credentialName = isSandbox ? 'TS_Survey_Dev' : 'TS_Survey_Prod';   
                       HttpResponse res = buildHttpResponse(credentialName,mdfDateTime,bearerToken, 'GET', null);
                       System.debug('res: ' + res);
                       System.debug('res.getBody: ' + res.getBody());

                        // Check the response
                        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300 ) {
                            // Parse the JSON response
                            List<Object> sondageRecords = (List<Object>) JSON.deserializeUntyped(res.getBody());
                            return sondageRecords;
                        } else {
                            // Log and throw error
                            System.debug('Sondage Fetch Error: ' + res.getBody());
                            throw new SurveyException('Sondage Fetch Failed: ' + res.getStatusCode());
                        }
                    } catch (Exception e) {
                        System.debug('Sondage Fetch Exception: ' + e.getMessage());
                        throw new SurveyException('Sondage Fetch Error: ' + e.getMessage());
                    }
                }

         private static HttpResponse buildHttpResponse(String credentialName,String mdfDateTime,String token, String methodType, String body )
                {
                    HttpRequest req = new HttpRequest();
                    String endpoint = 'callout:' + credentialName;
            
                    if (String.isNotBlank(mdfDateTime)) {
                        if (!endpoint.endsWith('/')) endpoint += '/';
                        endpoint += mdfDateTime;
                    }
                    req.setEndpoint(endpoint);
                    req.setMethod(methodType);
                    req.setHeader('Content-Type', 'application/json');
            
                    if (String.isNotBlank(token)) {
                        req.setHeader('Authorization', 'Bearer ' + token);
                    }
                    if (String.isNotBlank(body)) {
                        req.setBody(body);
                    }
                
                    Http http = new Http();
                    HttpResponse res;
                    res = http.send(req);
                    return res;
            
                    
                } 


    public class SurveyException extends Exception {}
 
}
