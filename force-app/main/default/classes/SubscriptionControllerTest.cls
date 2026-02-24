/**
 * @description Unit tests for SubscriptionController.
 */
@IsTest
private class SubscriptionControllerTest {

    @TestSetup
    static void setupTestData() {
        Account acc = TestDataFactory.createAccount('Controller Test Corp');
        TestDataFactory.createSubscription(
            acc.Id, 'Active',
            Date.today(), Date.today().addMonths(12), 99.00
        );
        TestDataFactory.createSubscription(
            acc.Id, 'Draft',
            Date.today().addMonths(6), Date.today().addMonths(18), 49.00
        );
    }

    @IsTest
    static void testGetSubscriptions() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Subscription__c> subs = SubscriptionController.getSubscriptions(acc.Id);
        Test.stopTest();

        System.assertEquals(2, subs.size(), 'Should return 2 subscriptions');
    }

    @IsTest
    static void testGetSubscriptions_NoResults() {
        Account acc = TestDataFactory.createAccount('Empty Account');

        Test.startTest();
        List<Subscription__c> subs = SubscriptionController.getSubscriptions(acc.Id);
        Test.stopTest();

        System.assertEquals(0, subs.size(), 'Should return empty list');
    }
}
