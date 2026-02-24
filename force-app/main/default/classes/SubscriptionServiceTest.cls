/**
 * @description Unit tests for SubscriptionService.
 * Covers: single active validation, draft activation, expiration, and bulk operations.
 */
@IsTest
private class SubscriptionServiceTest {

    @TestSetup
    static void setupTestData() {
        Account acc = TestDataFactory.createAccount('Test Corp');
        // Create a Draft subscription for status transition tests
        TestDataFactory.createSubscription(
            acc.Id, 'Draft',
            Date.today(), Date.today().addMonths(12), 99.00
        );
    }

    @IsTest
    static void testValidateSingleActivePerAccount_BlocksDuplicate() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        // First, create an active subscription
        TestDataFactory.createSubscription(
            acc.Id, 'Active',
            Date.today().addMonths(-1), Date.today().addMonths(11), 49.00
        );

        // Try to create another active subscription for the same Account
        Test.startTest();
        try {
            TestDataFactory.createSubscription(
                acc.Id, 'Active',
                Date.today(), Date.today().addMonths(12), 79.00
            );
            System.assert(false, 'Expected DmlException for duplicate active subscription');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('one active subscription'),
                'Expected active subscription validation error, got: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testValidateSingleActivePerAccount_AllowsDifferentAccounts() {
        Account acc1 = TestDataFactory.createAccount('Company A');
        Account acc2 = TestDataFactory.createAccount('Company B');

        Test.startTest();
        // Each Account gets one active subscription — should work fine
        Subscription__c sub1 = TestDataFactory.createSubscription(
            acc1.Id, 'Active',
            Date.today(), Date.today().addMonths(12), 49.00
        );
        Subscription__c sub2 = TestDataFactory.createSubscription(
            acc2.Id, 'Active',
            Date.today(), Date.today().addMonths(12), 79.00
        );
        Test.stopTest();

        System.assertNotEquals(null, sub1.Id, 'Subscription 1 should be created');
        System.assertNotEquals(null, sub2.Id, 'Subscription 2 should be created');
    }

    @IsTest
    static void testValidateSingleActivePerAccount_AllowsNonActiveStatuses() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        // Create an active subscription
        TestDataFactory.createSubscription(
            acc.Id, 'Active',
            Date.today().addMonths(-1), Date.today().addMonths(11), 49.00
        );

        Test.startTest();
        // Draft subscription for same Account should be allowed
        Subscription__c draft = TestDataFactory.createSubscription(
            acc.Id, 'Draft',
            Date.today().addMonths(6), Date.today().addMonths(18), 99.00
        );
        Test.stopTest();

        System.assertNotEquals(null, draft.Id, 'Draft subscription should be allowed');
    }

    @IsTest
    static void testActivateDraftSubscriptions() {
        // The test setup creates a Draft with Start_Date = today
        Test.startTest();
        Integer count = SubscriptionService.activateDraftSubscriptions();
        Test.stopTest();

        System.assertEquals(1, count, 'Should activate 1 draft subscription');

        Subscription__c updated = [
            SELECT Status__c FROM Subscription__c
            WHERE Account__c IN (SELECT Id FROM Account WHERE Name = 'Test Corp')
            AND Status__c = 'Active'
            LIMIT 1
        ];
        System.assertEquals('Active', updated.Status__c, 'Subscription should be Active');
    }

    @IsTest
    static void testExpireEndedSubscriptions() {
        Account acc = TestDataFactory.createAccount('Expired Corp');
        // Create an active subscription that ended yesterday
        Subscription__c sub = TestDataFactory.buildSubscription(
            acc.Id, 'Active',
            Date.today().addMonths(-12), Date.today().addDays(-1), 49.00
        );
        insert sub;

        Test.startTest();
        Integer count = SubscriptionService.expireEndedSubscriptions();
        Test.stopTest();

        System.assertEquals(1, count, 'Should expire 1 subscription');

        Subscription__c updated = [SELECT Status__c FROM Subscription__c WHERE Id = :sub.Id];
        System.assertEquals('Expired', updated.Status__c, 'Subscription should be Expired');
    }

    @IsTest
    static void testBulkValidation() {
        List<Account> accounts = TestDataFactory.createAccounts(200);

        // Create one active subscription per account — should succeed
        List<Subscription__c> subs = new List<Subscription__c>();
        for (Account acc : accounts) {
            subs.add(TestDataFactory.buildSubscription(
                acc.Id, 'Active',
                Date.today(), Date.today().addMonths(12), 49.00
            ));
        }

        Test.startTest();
        insert subs;
        Test.stopTest();

        System.assertEquals(200, [SELECT COUNT() FROM Subscription__c WHERE Status__c = 'Active' AND Account__c IN :accounts]);
    }

    @IsTest
    static void testBulkDuplicateInSameBatch() {
        Account acc = TestDataFactory.createAccount('Bulk Test');

        // Try to insert 2 active subscriptions for same Account in one batch
        List<Subscription__c> subs = new List<Subscription__c>();
        subs.add(TestDataFactory.buildSubscription(
            acc.Id, 'Active', Date.today(), Date.today().addMonths(12), 49.00
        ));
        subs.add(TestDataFactory.buildSubscription(
            acc.Id, 'Active', Date.today(), Date.today().addMonths(12), 79.00
        ));

        Test.startTest();
        try {
            insert subs;
            System.assert(false, 'Expected DmlException for bulk duplicate');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('one active subscription'),
                'Expected validation error in bulk insert'
            );
        }
        Test.stopTest();
    }
}
