/**
 * @description Apex controller for the Subscription Dashboard LWC.
 * Provides data access methods with CRUD/FLS enforcement
 * via Security.stripInaccessible.
 */
public with sharing class SubscriptionController {

    /**
     * @description Retrieves all subscriptions for a given Account.
     * Uses stripInaccessible to enforce FLS and gracefully handle
     * fields the current user cannot access.
     * @param accountId The Account record ID
     * @return List of Subscription__c records with accessible fields
     */
    @AuraEnabled(cacheable=true)
    public static List<Subscription__c> getSubscriptions(Id accountId) {
        List<Subscription__c> results = [
            SELECT Id, Name, Status__c, Start_Date__c, End_Date__c,
                   Monthly_Amount__c, External_Id__c
            FROM Subscription__c
            WHERE Account__c = :accountId
            ORDER BY Start_Date__c DESC
        ];
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.READABLE, results
        );
        return (List<Subscription__c>) decision.getRecords();
    }
}
