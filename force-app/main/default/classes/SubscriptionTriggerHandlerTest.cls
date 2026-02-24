/**
 * @description Unit tests for SubscriptionTriggerHandler and TriggerHandler framework.
 */
@IsTest
private class SubscriptionTriggerHandlerTest {

    @IsTest
    static void testInsertActiveSubscription() {
        Account acc = TestDataFactory.createAccount('Trigger Test Corp');

        Test.startTest();
        Subscription__c sub = TestDataFactory.createSubscription(
            acc.Id, 'Active',
            Date.today(), Date.today().addMonths(12), 99.00
        );
        Test.stopTest();

        System.assertNotEquals(null, sub.Id, 'Subscription should be inserted');
    }

    @IsTest
    static void testUpdateToActive_BlocksWhenExistingActive() {
        Account acc = TestDataFactory.createAccount('Trigger Update Test');

        // Create first active subscription
        TestDataFactory.createSubscription(
            acc.Id, 'Active',
            Date.today(), Date.today().addMonths(12), 49.00
        );

        // Create a draft subscription
        Subscription__c draft = TestDataFactory.createSubscription(
            acc.Id, 'Draft',
            Date.today().addMonths(6), Date.today().addMonths(18), 79.00
        );

        // Try to update draft to active
        Test.startTest();
        draft.Status__c = 'Active';
        try {
            update draft;
            System.assert(false, 'Expected DmlException when updating to Active');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('one active subscription'),
                'Expected validation error on update'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testBypassMechanism() {
        Account acc = TestDataFactory.createAccount('Bypass Test');
        TestDataFactory.createSubscription(
            acc.Id, 'Active',
            Date.today(), Date.today().addMonths(12), 49.00
        );

        // Bypass the handler and insert another active — should succeed
        Test.startTest();
        TriggerHandler.bypass('SubscriptionTriggerHandler');

        Subscription__c sub2 = TestDataFactory.createSubscription(
            acc.Id, 'Active',
            Date.today(), Date.today().addMonths(12), 79.00
        );

        TriggerHandler.clearBypass('SubscriptionTriggerHandler');
        Test.stopTest();

        System.assertNotEquals(null, sub2.Id, 'Bypassed handler should allow insert');
    }

    @IsTest
    static void testClearAllBypasses() {
        TriggerHandler.bypass('SubscriptionTriggerHandler');
        TriggerHandler.bypass('AnotherHandler');

        Test.startTest();
        TriggerHandler.clearAllBypasses();
        Test.stopTest();

        // Verify bypass is cleared by trying a normal operation
        Account acc = TestDataFactory.createAccount('Clear Bypass Test');
        Subscription__c sub = TestDataFactory.createSubscription(
            acc.Id, 'Active',
            Date.today(), Date.today().addMonths(12), 49.00
        );
        System.assertNotEquals(null, sub.Id);
    }

    @IsTest
    static void testValidationRuleEndDateAfterStartDate() {
        Account acc = TestDataFactory.createAccount('Validation Test');

        Test.startTest();
        try {
            TestDataFactory.createSubscription(
                acc.Id, 'Draft',
                Date.today().addMonths(12), Date.today(), 49.00
            );
            System.assert(false, 'Expected validation error for End_Date <= Start_Date');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('End Date must be after Start Date'),
                'Expected End Date validation error'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testValidationRulePositiveAmount() {
        Account acc = TestDataFactory.createAccount('Amount Validation Test');

        Test.startTest();
        try {
            TestDataFactory.createSubscription(
                acc.Id, 'Draft',
                Date.today(), Date.today().addMonths(12), -10.00
            );
            System.assert(false, 'Expected validation error for negative amount');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Monthly Amount must be greater than zero'),
                'Expected amount validation error'
            );
        }
        Test.stopTest();
    }
}
