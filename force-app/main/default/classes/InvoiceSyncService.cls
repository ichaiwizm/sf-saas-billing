/**
 * @description Service class that orchestrates invoice synchronization
 * from the external billing API into Salesforce.
 *
 * Retrieves invoices via BillingApiService and upserts them
 * as Invoice__c records using External_Id__c.
 */
public with sharing class InvoiceSyncService {

    /**
     * @description Result wrapper for sync operations.
     */
    public class SyncResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Integer syncedCount;
        @AuraEnabled public String errorMessage;

        public SyncResult() {
            this.success = true;
            this.syncedCount = 0;
        }
    }

    /**
     * @description Synchronizes invoices for a single subscription.
     * @param subscriptionId The Salesforce ID of the Subscription__c record
     * @return SyncResult with outcome details
     */
    public static SyncResult syncInvoices(Id subscriptionId) {
        SyncResult result = new SyncResult();

        try {
            // 1. Get the subscription's External ID
            // CRUD/FLS enforced at controller layer; sharing rules via 'with sharing'
            List<Subscription__c> subs = [
                SELECT Id, External_Id__c
                FROM Subscription__c
                WHERE Id = :subscriptionId
                LIMIT 1
            ];

            if (subs.isEmpty()) {
                result.success = false;
                result.errorMessage = 'Subscription not found.';
                return result;
            }

            Subscription__c sub = subs[0];

            if (String.isBlank(sub.External_Id__c)) {
                result.success = false;
                result.errorMessage = 'Subscription has no External ID configured.';
                return result;
            }

            // 2. Call the external API
            List<BillingApiService.InvoiceWrapper> apiInvoices =
                BillingApiService.getInvoices(sub.External_Id__c);

            if (apiInvoices == null || apiInvoices.isEmpty()) {
                result.syncedCount = 0;
                return result;
            }

            // 3. Map API response to Invoice__c records
            List<Invoice__c> invoicesToUpsert = new List<Invoice__c>();

            for (BillingApiService.InvoiceWrapper wrapper : apiInvoices) {
                Invoice__c inv = new Invoice__c();
                inv.External_Id__c = wrapper.id;
                inv.Subscription__c = subscriptionId;
                inv.Amount__c = wrapper.amount;
                inv.Status__c = normalizeStatus(wrapper.status);
                inv.Invoice_Date__c = wrapper.invoiceDate;
                inv.Raw_Response__c = JSON.serialize(wrapper);
                invoicesToUpsert.add(inv);
            }

            // 4. Upsert using External_Id__c as the key
            Schema.SObjectField externalIdField = Invoice__c.Fields.External_Id__c;
            List<Database.UpsertResult> upsertResults =
                Database.upsert(invoicesToUpsert, externalIdField, false);

            // 5. Process results
            Integer successCount = 0;
            List<String> errors = new List<String>();

            for (Integer i = 0; i < upsertResults.size(); i++) {
                if (upsertResults[i].isSuccess()) {
                    successCount++;
                } else {
                    for (Database.Error err : upsertResults[i].getErrors()) {
                        errors.add(
                            'Invoice ' + invoicesToUpsert[i].External_Id__c +
                            ': ' + err.getMessage()
                        );
                    }
                }
            }

            result.syncedCount = successCount;
            if (!errors.isEmpty()) {
                result.success = false;
                result.errorMessage = String.join(errors, '; ');
            }

        } catch (BillingApiService.BillingApiException e) {
            result.success = false;
            result.errorMessage = 'API Error: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, 'Invoice sync API error: ' + e.getMessage());
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Unexpected error: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, 'Invoice sync error: ' + e.getMessage());
        }

        return result;
    }

    /**
     * @description Normalizes the status string from the API to match
     * the Invoice__c Status__c picklist values.
     * @param apiStatus Status from the API (lowercase)
     * @return Normalized status matching picklist values
     */
    @TestVisible
    private static String normalizeStatus(String apiStatus) {
        if (String.isBlank(apiStatus)) {
            return 'Pending';
        }
        switch on apiStatus.toLowerCase() {
            when 'paid' { return 'Paid'; }
            when 'pending' { return 'Pending'; }
            when 'failed' { return 'Failed'; }
            when else { return 'Pending'; }
        }
    }
}
