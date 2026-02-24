/**
 * @description Unit tests for InvoiceSyncService.
 * Tests the full sync flow: API callout → upsert → result.
 */
@IsTest
private class InvoiceSyncServiceTest {

    @TestSetup
    static void setupTestData() {
        Account acc = TestDataFactory.createAccount('Sync Test Corp');
        TestDataFactory.createSubscriptionWithExternalId(
            acc.Id, 'Active',
            Date.today().addMonths(-1), Date.today().addMonths(11),
            49.99, 'sub-ext-001'
        );
    }

    @IsTest
    static void testSyncInvoices_Success() {
        Test.setMock(HttpCalloutMock.class, BillingApiMock.success());
        Subscription__c sub = [SELECT Id FROM Subscription__c LIMIT 1];

        Test.startTest();
        InvoiceSyncService.SyncResult result = InvoiceSyncService.syncInvoices(sub.Id);
        Test.stopTest();

        System.assert(result.success, 'Sync should succeed');
        System.assertEquals(2, result.syncedCount, 'Should sync 2 invoices');

        List<Invoice__c> invoices = [
            SELECT External_Id__c, Amount__c, Status__c
            FROM Invoice__c
            WHERE Subscription__c = :sub.Id
            ORDER BY External_Id__c
        ];
        System.assertEquals(2, invoices.size(), 'Should have 2 invoice records');
        System.assertEquals('inv-001', invoices[0].External_Id__c);
        System.assertEquals('Paid', invoices[0].Status__c);
    }

    @IsTest
    static void testSyncInvoices_UpsertExisting() {
        Subscription__c sub = [SELECT Id FROM Subscription__c LIMIT 1];

        // Pre-create an invoice with the same external ID
        TestDataFactory.createInvoice(sub.Id, 40.00, 'Pending', Date.today(), 'inv-001');

        Test.setMock(HttpCalloutMock.class, BillingApiMock.success());

        Test.startTest();
        InvoiceSyncService.SyncResult result = InvoiceSyncService.syncInvoices(sub.Id);
        Test.stopTest();

        System.assert(result.success, 'Sync should succeed');

        // Verify the existing invoice was updated (upserted), not duplicated
        List<Invoice__c> invoices = [
            SELECT External_Id__c, Amount__c, Status__c
            FROM Invoice__c
            WHERE Subscription__c = :sub.Id
        ];
        System.assertEquals(2, invoices.size(), 'Should have exactly 2 invoices (1 updated + 1 new)');
    }

    @IsTest
    static void testSyncInvoices_EmptyResponse() {
        Test.setMock(HttpCalloutMock.class, BillingApiMock.emptyResponse());
        Subscription__c sub = [SELECT Id FROM Subscription__c LIMIT 1];

        Test.startTest();
        InvoiceSyncService.SyncResult result = InvoiceSyncService.syncInvoices(sub.Id);
        Test.stopTest();

        System.assert(result.success, 'Sync should succeed with empty response');
        System.assertEquals(0, result.syncedCount, 'Should sync 0 invoices');
    }

    @IsTest
    static void testSyncInvoices_ApiError() {
        Test.setMock(HttpCalloutMock.class, BillingApiMock.serverError());
        Subscription__c sub = [SELECT Id FROM Subscription__c LIMIT 1];

        Test.startTest();
        InvoiceSyncService.SyncResult result = InvoiceSyncService.syncInvoices(sub.Id);
        Test.stopTest();

        System.assert(!result.success, 'Sync should fail on API error');
        System.assert(
            result.errorMessage.contains('API Error'),
            'Error message should indicate API error'
        );
    }

    @IsTest
    static void testSyncInvoices_NoExternalId() {
        Account acc = TestDataFactory.createAccount('No ExtId Corp');
        Subscription__c sub = TestDataFactory.createSubscription(
            acc.Id, 'Active',
            Date.today(), Date.today().addMonths(12), 49.00
        );

        Test.startTest();
        InvoiceSyncService.SyncResult result = InvoiceSyncService.syncInvoices(sub.Id);
        Test.stopTest();

        System.assert(!result.success, 'Sync should fail without external ID');
        System.assert(
            result.errorMessage.contains('External ID'),
            'Error should mention External ID'
        );
    }

    @IsTest
    static void testNormalizeStatus() {
        System.assertEquals('Paid', InvoiceSyncService.normalizeStatus('paid'));
        System.assertEquals('Paid', InvoiceSyncService.normalizeStatus('PAID'));
        System.assertEquals('Pending', InvoiceSyncService.normalizeStatus('pending'));
        System.assertEquals('Failed', InvoiceSyncService.normalizeStatus('failed'));
        System.assertEquals('Pending', InvoiceSyncService.normalizeStatus('unknown'));
        System.assertEquals('Pending', InvoiceSyncService.normalizeStatus(null));
    }
}
