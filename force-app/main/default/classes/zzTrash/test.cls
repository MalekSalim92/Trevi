public without sharing class test {
    
    @AuraEnabled
    public static String process() {
        HttpRequest req = new HttpRequest();
        
        // Using the Named Credential (postman-echo)
        req.setEndpoint('callout:test');
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');  // Set if required by the API
        string body = '{"username": "{!$Credential.Username}", "password": "{!$Credential.Password}"}'; 
        req.setBody(body);  // Set if required by the API

        Http http = new Http();
        HttpResponse res;
        res = http.send(req);

        // Return response details for debugging
        System.debug('StatusCode: ' + res.getStatusCode() + ' | Status: ' + res.getStatus() + ' | Body: ' + res.getBody());
        return 'StatusCode: ' + res.getStatusCode() + ' | Status: ' + res.getStatus() + ' | Body: ' + res.getBody();
    }
}