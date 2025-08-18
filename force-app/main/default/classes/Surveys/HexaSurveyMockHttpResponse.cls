
public class HexaSurveyMockHttpResponse implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        if (req.getBody().contains('"username"')) {
            // Login call
            res.setBody('mocked_bearer_token');
        } else if (req.getMethod() == 'GET') {
            // Sondage data call
            res.setBody('[{"noID":665,"contrat_Trevi":"HT-70895060-02","succursale":"03"}]');
        }
        else{
            res.setBody('{"details": [{"url": "https://test.survey.com/12345"}]}');

        }
        return res;
    }
}