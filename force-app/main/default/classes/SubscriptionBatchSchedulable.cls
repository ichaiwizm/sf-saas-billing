/**
 * @description Schedulable and Batchable class that processes subscription
 * status transitions daily.
 *
 * - Activates Draft subscriptions whose Start_Date has arrived
 * - Expires Active subscriptions whose End_Date has passed
 *
 * Schedule example (daily at 1 AM):
 *   System.schedule('Daily Subscription Status Update', '0 0 1 * * ?',
 *       new SubscriptionBatchSchedulable());
 */
public with sharing class SubscriptionBatchSchedulable
    implements Database.Batchable<SObject>, Schedulable {

    private static final String QUERY =
        'SELECT Id, Status__c, Start_Date__c, End_Date__c ' +
        'FROM Subscription__c ' +
        'WHERE (Status__c = \'Draft\' AND Start_Date__c <= TODAY) ' +
        'OR (Status__c = \'Active\' AND End_Date__c < TODAY)';

    // --- Schedulable interface ---

    /**
     * @description Entry point when executed via the Scheduler.
     * Launches the batch process.
     */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, 200);
    }

    // --- Batchable interface ---

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(QUERY);
    }

    public void execute(Database.BatchableContext bc, List<Subscription__c> scope) {
        List<Subscription__c> toUpdate = new List<Subscription__c>();

        for (Subscription__c sub : scope) {
            if (sub.Status__c == 'Draft' && sub.Start_Date__c <= Date.today()) {
                sub.Status__c = 'Active';
                toUpdate.add(sub);
            } else if (sub.Status__c == 'Active' && sub.End_Date__c < Date.today()) {
                sub.Status__c = 'Expired';
                toUpdate.add(sub);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'SubscriptionBatchSchedulable completed.');
    }
}
