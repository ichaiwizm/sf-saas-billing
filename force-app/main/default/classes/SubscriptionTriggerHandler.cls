/**
 * @description Trigger handler for Subscription__c object.
 * Delegates business logic to SubscriptionService.
 */
public with sharing class SubscriptionTriggerHandler extends TriggerHandler {

    /**
     * @description Before insert: validate that no more than one active subscription
     * exists per Account.
     */
    protected override void beforeInsert() {
        SubscriptionService.validateSingleActivePerAccount(
            (List<Subscription__c>) Trigger.new,
            null
        );
    }

    /**
     * @description Before update: validate single active subscription per Account
     * when status changes to Active.
     */
    protected override void beforeUpdate() {
        SubscriptionService.validateSingleActivePerAccount(
            (List<Subscription__c>) Trigger.new,
            (Map<Id, Subscription__c>) Trigger.oldMap
        );
    }
}
