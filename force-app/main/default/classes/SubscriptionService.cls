/**
 * @description Service class for Subscription business logic.
 * Contains all subscription-related operations following the Service Layer pattern.
 * All methods are bulk-safe (no SOQL/DML inside loops).
 */
public with sharing class SubscriptionService {

    private static final String STATUS_ACTIVE = 'Active';
    private static final String STATUS_DRAFT = 'Draft';
    private static final String STATUS_EXPIRED = 'Expired';

    /**
     * @description Validates that only one Active subscription exists per Account.
     * Called from the trigger handler on before insert/update.
     * @param newSubscriptions List of subscriptions being inserted or updated
     * @param oldMap Map of old subscription values (null on insert)
     */
    public static void validateSingleActivePerAccount(
        List<Subscription__c> newSubscriptions,
        Map<Id, Subscription__c> oldMap
    ) {
        // Collect Account IDs for subscriptions being set to Active
        Set<Id> accountIdsToCheck = new Set<Id>();
        Map<Id, List<Subscription__c>> accountToNewActiveSubs = new Map<Id, List<Subscription__c>>();

        for (Subscription__c sub : newSubscriptions) {
            Boolean isBecomingActive = sub.Status__c == STATUS_ACTIVE;
            Boolean wasNotActive = (oldMap == null || oldMap.get(sub.Id)?.Status__c != STATUS_ACTIVE);

            if (isBecomingActive && wasNotActive) {
                accountIdsToCheck.add(sub.Account__c);
                if (!accountToNewActiveSubs.containsKey(sub.Account__c)) {
                    accountToNewActiveSubs.put(sub.Account__c, new List<Subscription__c>());
                }
                accountToNewActiveSubs.get(sub.Account__c).add(sub);
            }
        }

        if (accountIdsToCheck.isEmpty()) {
            return;
        }

        // Check for multiple active subs in the same batch
        for (Id accountId : accountToNewActiveSubs.keySet()) {
            List<Subscription__c> activeSubs = accountToNewActiveSubs.get(accountId);
            if (activeSubs.size() > 1) {
                for (Integer i = 1; i < activeSubs.size(); i++) {
                    activeSubs[i].addError(
                        'An Account can only have one active subscription at a time.'
                    );
                }
            }
        }

        // Query existing active subscriptions for these Accounts
        // Exclude current records being updated (they may be changing FROM active)
        Set<Id> currentSubIds = new Set<Id>();
        if (oldMap != null) {
            currentSubIds = oldMap.keySet();
        }

        List<Subscription__c> existingActiveSubs = [
            SELECT Id, Account__c
            FROM Subscription__c
            WHERE Account__c IN :accountIdsToCheck
                AND Status__c = :STATUS_ACTIVE
                AND Id NOT IN :currentSubIds
            WITH SECURITY_ENFORCED
        ];

        Set<Id> accountsWithActiveSub = new Set<Id>();
        for (Subscription__c existing : existingActiveSubs) {
            accountsWithActiveSub.add(existing.Account__c);
        }

        // Add error to subscriptions trying to become active when one already exists
        for (Id accountId : accountToNewActiveSubs.keySet()) {
            if (accountsWithActiveSub.contains(accountId)) {
                for (Subscription__c sub : accountToNewActiveSubs.get(accountId)) {
                    sub.addError(
                        'An Account can only have one active subscription at a time.'
                    );
                }
            }
        }
    }

    /**
     * @description Activates Draft subscriptions whose Start_Date is today or in the past.
     * Intended to be called from a scheduled batch job.
     * @return Number of records updated
     */
    public static Integer activateDraftSubscriptions() {
        List<Subscription__c> draftsToActivate = [
            SELECT Id, Status__c
            FROM Subscription__c
            WHERE Status__c = :STATUS_DRAFT
                AND Start_Date__c <= TODAY
            WITH SECURITY_ENFORCED
        ];

        for (Subscription__c sub : draftsToActivate) {
            sub.Status__c = STATUS_ACTIVE;
        }

        if (!draftsToActivate.isEmpty()) {
            update draftsToActivate;
        }

        return draftsToActivate.size();
    }

    /**
     * @description Expires Active subscriptions whose End_Date has passed.
     * Intended to be called from a scheduled batch job.
     * @return Number of records updated
     */
    public static Integer expireEndedSubscriptions() {
        List<Subscription__c> subsToExpire = [
            SELECT Id, Status__c
            FROM Subscription__c
            WHERE Status__c = :STATUS_ACTIVE
                AND End_Date__c < TODAY
            WITH SECURITY_ENFORCED
        ];

        for (Subscription__c sub : subsToExpire) {
            sub.Status__c = STATUS_EXPIRED;
        }

        if (!subsToExpire.isEmpty()) {
            update subsToExpire;
        }

        return subsToExpire.size();
    }
}
