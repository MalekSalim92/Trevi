/**
 * Class Name: HexaSurveyMockHttpResponse
 * Description: Mock HTTP callout for Hexa Survey API.
 *              Supports authentication, survey retrieval, and survey creation.
 *
 * Author: Malek Brachemi
 * Created: 2025-05-09
 */
public class HexaSurveyMockHttpResponse implements HttpCalloutMock {
    
    /**
     * Return a mock response based on request type:
     * - Auth requests (username in body) → mocked bearer token
     * - GET requests → sample survey data
     * - Other requests (POST/PUT) → survey creation response
     */
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        
        if (req.getBody().contains('"username"')) {
            // Mock login response
            res.setBody('mocked_bearer_token');
            
        } else if (req.getMethod() == 'GET') {
            // Mock survey data response
            res.setBody('[{"noID":665,"contrat_Trevi":"HT-70895060-02","succursale":"03"}]');
            
        } else {
            // Mock survey creation response
            res.setBody('{"details": [{"url": "https://test.survey.com/12345"}]}');
        }
        
        return res;
    }
}