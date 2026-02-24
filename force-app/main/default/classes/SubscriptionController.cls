/**
 * @description Apex controller for the Subscription Dashboard LWC.
 * Provides data access methods with CRUD/FLS enforcement.
 */
public with sharing class SubscriptionController {

    /**
     * @description Retrieves all subscriptions for a given Account.
     * @param accountId The Account record ID
     * @return List of Subscription__c records with relevant fields
     */
    @AuraEnabled(cacheable=true)
    public static List<Subscription__c> getSubscriptions(Id accountId) {
        return [
            SELECT Id, Name, Status__c, Start_Date__c, End_Date__c,
                   Monthly_Amount__c, External_Id__c
            FROM Subscription__c
            WHERE Account__c = :accountId
            WITH SECURITY_ENFORCED
            ORDER BY Start_Date__c DESC
        ];
    }
}
