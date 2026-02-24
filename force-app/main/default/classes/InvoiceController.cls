/**
 * @description Apex controller for the Invoice Viewer LWC.
 * Provides data access and sync methods with CRUD/FLS enforcement
 * via Security.stripInaccessible.
 */
public with sharing class InvoiceController {

    /**
     * @description Retrieves all invoices for a given Subscription.
     * Uses stripInaccessible to enforce FLS gracefully.
     * @param subscriptionId The Subscription__c record ID
     * @return List of Invoice__c records with accessible fields
     */
    @AuraEnabled(cacheable=true)
    public static List<Invoice__c> getInvoices(Id subscriptionId) {
        List<Invoice__c> results = [
            SELECT Id, Name, Amount__c, Status__c, Invoice_Date__c, External_Id__c
            FROM Invoice__c
            WHERE Subscription__c = :subscriptionId
            ORDER BY Invoice_Date__c DESC
        ];
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.READABLE, results
        );
        return (List<Invoice__c>) decision.getRecords();
    }

    /**
     * @description Triggers invoice synchronization from the external billing API.
     * @param subscriptionId The Subscription__c record ID to sync invoices for
     * @return SyncResult with outcome details
     */
    @AuraEnabled
    public static InvoiceSyncService.SyncResult syncInvoices(Id subscriptionId) {
        return InvoiceSyncService.syncInvoices(subscriptionId);
    }
}
