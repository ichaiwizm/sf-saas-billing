/**
 * @description Apex controller for the Invoice Viewer LWC.
 * Provides data access and sync methods with CRUD/FLS enforcement.
 */
public with sharing class InvoiceController {

    /**
     * @description Retrieves all invoices for a given Subscription.
     * @param subscriptionId The Subscription__c record ID
     * @return List of Invoice__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<Invoice__c> getInvoices(Id subscriptionId) {
        return [
            SELECT Id, Name, Amount__c, Status__c, Invoice_Date__c, External_Id__c
            FROM Invoice__c
            WHERE Subscription__c = :subscriptionId
            WITH SECURITY_ENFORCED
            ORDER BY Invoice_Date__c DESC
        ];
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
