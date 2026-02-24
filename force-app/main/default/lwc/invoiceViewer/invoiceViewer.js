import { LightningElement, api, wire } from "lwc";
import getInvoices from "@salesforce/apex/InvoiceController.getInvoices";
import syncInvoices from "@salesforce/apex/InvoiceController.syncInvoices";
import { refreshApex } from "@salesforce/apex";

const COLUMNS = [
    { label: "Invoice #", fieldName: "Name", type: "text" },
    {
        label: "Date",
        fieldName: "Invoice_Date__c",
        type: "date",
        typeAttributes: { day: "2-digit", month: "2-digit", year: "numeric" }
    },
    {
        label: "Amount",
        fieldName: "Amount__c",
        type: "currency",
        typeAttributes: { currencyCode: "EUR" }
    },
    { label: "Status", fieldName: "Status__c", type: "text" }
];

export default class InvoiceViewer extends LightningElement {
    @api subscriptionId;
    @api subscriptionName;

    invoices = [];
    error;
    isLoading = true;
    isSyncing = false;
    syncMessage;
    syncSuccess = true;
    columns = COLUMNS;

    _wiredInvoicesResult;

    @wire(getInvoices, { subscriptionId: "$subscriptionId" })
    wiredInvoices(result) {
        this._wiredInvoicesResult = result;
        this.isLoading = false;
        if (result.data) {
            this.invoices = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error.body?.message || "An error occurred loading invoices.";
            this.invoices = [];
        }
    }

    get totalPaid() {
        return this.invoices
            .filter((inv) => inv.Status__c === "Paid")
            .reduce((sum, inv) => sum + (inv.Amount__c || 0), 0);
    }

    get invoiceCount() {
        return this.invoices.length;
    }

    get hasInvoices() {
        return !this.isLoading && !this.error && this.invoices.length > 0;
    }

    get noInvoices() {
        return !this.isLoading && !this.error && this.invoices.length === 0;
    }

    get syncMessageClass() {
        return this.syncSuccess
            ? "slds-notify slds-notify_alert slds-alert_success slds-var-m-bottom_medium"
            : "slds-notify slds-notify_alert slds-alert_error slds-var-m-bottom_medium";
    }

    async handleSync() {
        this.isSyncing = true;
        this.syncMessage = undefined;

        try {
            const result = await syncInvoices({ subscriptionId: this.subscriptionId });
            if (result.success) {
                this.syncSuccess = true;
                this.syncMessage = `Successfully synced ${result.syncedCount} invoice(s).`;
            } else {
                this.syncSuccess = false;
                this.syncMessage = result.errorMessage || "Sync completed with errors.";
            }
            // Refresh the invoice list
            await refreshApex(this._wiredInvoicesResult);
        } catch (err) {
            this.syncSuccess = false;
            this.syncMessage = err.body?.message || "An error occurred during sync.";
        } finally {
            this.isSyncing = false;
        }
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent("close"));
    }
}
