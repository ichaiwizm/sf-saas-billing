/**
 * @description Service class for calling the external Billing API.
 * Uses Named Credential 'Billing_API' for secure endpoint configuration.
 *
 * External API contract:
 *   GET /invoices?subscriptionExternalId=XXX
 *   Response: [{ "id": "inv-001", "amount": 49, "status": "paid", "date": "2026-01-10" }]
 */
public with sharing class BillingApiService {

    private static final String NAMED_CREDENTIAL = 'callout:Billing_API';
    private static final String INVOICES_PATH = '/invoices';
    private static final Integer TIMEOUT_MS = 30000;

    /**
     * @description Wrapper class to deserialize invoice data from the external API.
     */
    public class InvoiceWrapper {
        public String id;
        public Decimal amount;
        public String status;
        @SuppressWarnings('PMD.FieldNamingConventions')
        public String date_x; // 'date' is reserved in Apex

        // Manual date field since 'date' is a reserved word
        public Date invoiceDate;
    }

    /**
     * @description Calls the external billing API to retrieve invoices
     * for a given subscription external ID.
     * @param subscriptionExternalId The external ID of the subscription
     * @return List of InvoiceWrapper objects
     * @throws BillingApiException on HTTP errors or unexpected responses
     */
    public static List<InvoiceWrapper> getInvoices(String subscriptionExternalId) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            NAMED_CREDENTIAL + INVOICES_PATH +
            '?subscriptionExternalId=' + EncodingUtil.urlEncode(subscriptionExternalId, 'UTF-8')
        );
        req.setMethod('GET');
        req.setTimeout(TIMEOUT_MS);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');

        HttpResponse res;
        try {
            res = new Http().send(req);
        } catch (Exception e) {
            throw new BillingApiException(
                'Failed to connect to Billing API: ' + e.getMessage(), e
            );
        }

        if (res.getStatusCode() != 200) {
            throw new BillingApiException(
                'Billing API returned status ' + res.getStatusCode() +
                ': ' + res.getBody()
            );
        }

        return parseResponse(res.getBody());
    }

    /**
     * @description Parses the JSON response from the billing API.
     * Handles the 'date' reserved word mapping.
     * @param jsonBody Raw JSON string
     * @return List of InvoiceWrapper objects
     */
    @TestVisible
    private static List<InvoiceWrapper> parseResponse(String jsonBody) {
        // Replace "date" key with "date_x" since 'date' is reserved in Apex
        String sanitized = jsonBody.replace('"date"', '"date_x"');
        List<InvoiceWrapper> wrappers =
            (List<InvoiceWrapper>) JSON.deserialize(sanitized, List<InvoiceWrapper>.class);

        // Parse the date strings safely
        for (InvoiceWrapper wrapper : wrappers) {
            if (wrapper.date_x != null) {
                try {
                    wrapper.invoiceDate = Date.valueOf(wrapper.date_x);
                } catch (Exception e) {
                    System.debug(LoggingLevel.WARN,
                        'Invalid date format for invoice ' + wrapper.id + ': ' + wrapper.date_x
                    );
                }
            }
        }

        return wrappers;
    }

    /**
     * @description Custom exception for Billing API errors.
     */
    public class BillingApiException extends Exception {}
}
