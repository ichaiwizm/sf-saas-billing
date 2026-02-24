import { LightningElement, api, wire } from "lwc";
import getInvoices from "@salesforce/apex/InvoiceController.getInvoices";
import syncInvoices from "@salesforce/apex/InvoiceController.syncInvoices";
import { refreshApex } from "@salesforce/apex";

const STATUS_CLASSES = {
    Paid: "badge badge-paid",
    Pending: "badge badge-pending",
    Failed: "badge badge-failed",
    Draft: "badge badge-draft"
};

export default class InvoiceViewer extends LightningElement {
    @api subscriptionId;
    @api subscriptionName;

    invoices = [];
    error;
    isLoading = true;
    isSyncing = false;
    syncMessage;
    syncSuccess = true;

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

    get formattedInvoices() {
        return this.invoices.map((inv) => ({
            ...inv,
            statusClass: STATUS_CLASSES[inv.Status__c] || "badge badge-draft"
        }));
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

    get syncAlertClass() {
        return this.syncSuccess
            ? "sync-alert sync-alert-success"
            : "sync-alert sync-alert-error";
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
