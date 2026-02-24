/**
 * @description Mock HTTP callout class for testing BillingApiService.
 * Implements HttpCalloutMock to simulate external API responses.
 */
@IsTest
public class BillingApiMock implements HttpCalloutMock {

    private Integer statusCode;
    private String responseBody;

    /**
     * @description Constructor with custom status code and response body.
     */
    public BillingApiMock(Integer statusCode, String responseBody) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }

    /**
     * @description Creates a mock that returns a successful response with sample invoices.
     */
    public static BillingApiMock success() {
        String body = '[' +
            '{"id":"inv-001","amount":49.99,"status":"paid","date":"2026-01-10"},' +
            '{"id":"inv-002","amount":49.99,"status":"pending","date":"2026-02-10"}' +
        ']';
        return new BillingApiMock(200, body);
    }

    /**
     * @description Creates a mock that returns an empty invoice list.
     */
    public static BillingApiMock emptyResponse() {
        return new BillingApiMock(200, '[]');
    }

    /**
     * @description Creates a mock that returns a server error.
     */
    public static BillingApiMock serverError() {
        return new BillingApiMock(500, '{"error":"Internal Server Error"}');
    }

    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(this.statusCode);
        res.setBody(this.responseBody);
        res.setHeader('Content-Type', 'application/json');
        return res;
    }
}
