/**
 * @description Unit tests for BillingApiService.
 * Uses HttpCalloutMock to simulate external API responses.
 */
@IsTest
private class BillingApiServiceTest {

    @IsTest
    static void testGetInvoices_Success() {
        Test.setMock(HttpCalloutMock.class, BillingApiMock.success());

        Test.startTest();
        List<BillingApiService.InvoiceWrapper> invoices =
            BillingApiService.getInvoices('sub-ext-001');
        Test.stopTest();

        System.assertEquals(2, invoices.size(), 'Should return 2 invoices');
        System.assertEquals('inv-001', invoices[0].id, 'First invoice ID should match');
        System.assertEquals(49.99, invoices[0].amount, 'First invoice amount should match');
        System.assertEquals('paid', invoices[0].status, 'First invoice status should match');
        System.assertEquals(Date.valueOf('2026-01-10'), invoices[0].invoiceDate, 'Date should be parsed');
    }

    @IsTest
    static void testGetInvoices_EmptyResponse() {
        Test.setMock(HttpCalloutMock.class, BillingApiMock.emptyResponse());

        Test.startTest();
        List<BillingApiService.InvoiceWrapper> invoices =
            BillingApiService.getInvoices('sub-ext-002');
        Test.stopTest();

        System.assertEquals(0, invoices.size(), 'Should return empty list');
    }

    @IsTest
    static void testGetInvoices_ServerError() {
        Test.setMock(HttpCalloutMock.class, BillingApiMock.serverError());

        Test.startTest();
        try {
            BillingApiService.getInvoices('sub-ext-003');
            System.assert(false, 'Expected BillingApiException');
        } catch (BillingApiService.BillingApiException e) {
            System.assert(
                e.getMessage().contains('500'),
                'Error should contain status code'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testParseResponse() {
        String json = '[{"id":"inv-test","amount":100,"status":"pending","date":"2026-03-15"}]';

        Test.startTest();
        List<BillingApiService.InvoiceWrapper> result =
            BillingApiService.parseResponse(json);
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('inv-test', result[0].id);
        System.assertEquals(100, result[0].amount);
        System.assertEquals(Date.valueOf('2026-03-15'), result[0].invoiceDate);
    }
}
