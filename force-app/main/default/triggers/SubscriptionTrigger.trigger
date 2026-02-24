/**
 * @description Trigger for Subscription__c. Delegates all logic
 * to SubscriptionTriggerHandler via the TriggerHandler framework.
 */
trigger SubscriptionTrigger on Subscription__c (
    before insert,
    before update,
    after insert,
    after update
) {
    new SubscriptionTriggerHandler().run();
}
