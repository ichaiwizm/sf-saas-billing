/**
 * @description Unit tests for InvoiceController.
 */
@IsTest
private class InvoiceControllerTest {

    @TestSetup
    static void setupTestData() {
        Account acc = TestDataFactory.createAccount('Invoice Controller Test');
        Subscription__c sub = TestDataFactory.createSubscriptionWithExternalId(
            acc.Id, 'Active',
            Date.today(), Date.today().addMonths(12), 99.00, 'ctrl-ext-001'
        );
        TestDataFactory.createInvoice(sub.Id, 99.00, 'Paid', Date.today(), 'inv-ctrl-001');
        TestDataFactory.createInvoice(sub.Id, 99.00, 'Pending', Date.today().addMonths(1), 'inv-ctrl-002');
    }

    @IsTest
    static void testGetInvoices() {
        Subscription__c sub = [SELECT Id FROM Subscription__c LIMIT 1];

        Test.startTest();
        List<Invoice__c> invoices = InvoiceController.getInvoices(sub.Id);
        Test.stopTest();

        System.assertEquals(2, invoices.size(), 'Should return 2 invoices');
    }

    @IsTest
    static void testGetInvoices_NoResults() {
        Account acc = TestDataFactory.createAccount('No Invoice Corp');
        Subscription__c sub = TestDataFactory.createSubscription(
            acc.Id, 'Active',
            Date.today(), Date.today().addMonths(12), 49.00
        );

        Test.startTest();
        List<Invoice__c> invoices = InvoiceController.getInvoices(sub.Id);
        Test.stopTest();

        System.assertEquals(0, invoices.size(), 'Should return empty list');
    }

    @IsTest
    static void testSyncInvoices() {
        Test.setMock(HttpCalloutMock.class, BillingApiMock.success());
        Subscription__c sub = [SELECT Id FROM Subscription__c LIMIT 1];

        Test.startTest();
        InvoiceSyncService.SyncResult result = InvoiceController.syncInvoices(sub.Id);
        Test.stopTest();

        System.assert(result.success, 'Sync should succeed');
    }
}
