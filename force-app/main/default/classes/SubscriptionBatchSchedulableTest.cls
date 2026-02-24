/**
 * @description Unit tests for SubscriptionBatchSchedulable.
 * Tests both batch execution and schedulable interface.
 */
@IsTest
private class SubscriptionBatchSchedulableTest {

    @TestSetup
    static void setupTestData() {
        Account acc1 = TestDataFactory.createAccount('Batch Test Draft');
        Account acc2 = TestDataFactory.createAccount('Batch Test Expired');

        // Draft subscription with Start_Date = today → should be activated
        TestDataFactory.createSubscription(
            acc1.Id, 'Draft',
            Date.today(), Date.today().addMonths(12), 49.00
        );

        // Active subscription with End_Date = yesterday → should be expired
        Subscription__c expiredSub = TestDataFactory.buildSubscription(
            acc2.Id, 'Active',
            Date.today().addMonths(-12), Date.today().addDays(-1), 79.00
        );
        insert expiredSub;
    }

    @IsTest
    static void testBatchExecution() {
        Test.startTest();
        Database.executeBatch(new SubscriptionBatchSchedulable(), 200);
        Test.stopTest();

        // Verify draft was activated
        Subscription__c activated = [
            SELECT Status__c FROM Subscription__c
            WHERE Account__c IN (SELECT Id FROM Account WHERE Name = 'Batch Test Draft')
            LIMIT 1
        ];
        System.assertEquals('Active', activated.Status__c, 'Draft should be activated');

        // Verify active was expired
        Subscription__c expired = [
            SELECT Status__c FROM Subscription__c
            WHERE Account__c IN (SELECT Id FROM Account WHERE Name = 'Batch Test Expired')
            LIMIT 1
        ];
        System.assertEquals('Expired', expired.Status__c, 'Active should be expired');
    }

    @IsTest
    static void testSchedulableExecution() {
        String cronExp = '0 0 1 * * ?';

        Test.startTest();
        String jobId = System.schedule(
            'Test Subscription Batch',
            cronExp,
            new SubscriptionBatchSchedulable()
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job should be scheduled');

        CronTrigger ct = [SELECT Id, State FROM CronTrigger WHERE Id = :jobId];
        System.assertNotEquals(null, ct, 'CronTrigger should exist');
    }
}
