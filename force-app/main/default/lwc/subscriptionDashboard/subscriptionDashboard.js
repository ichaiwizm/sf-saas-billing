import { LightningElement, api, wire } from "lwc";
import getSubscriptions from "@salesforce/apex/SubscriptionController.getSubscriptions";

const COLUMNS = [
    { label: "Number", fieldName: "Name", type: "text" },
    { label: "Status", fieldName: "Status__c", type: "text" },
    {
        label: "Start Date",
        fieldName: "Start_Date__c",
        type: "date",
        typeAttributes: { day: "2-digit", month: "2-digit", year: "numeric" }
    },
    {
        label: "End Date",
        fieldName: "End_Date__c",
        type: "date",
        typeAttributes: { day: "2-digit", month: "2-digit", year: "numeric" }
    },
    {
        label: "Monthly Amount",
        fieldName: "Monthly_Amount__c",
        type: "currency",
        typeAttributes: { currencyCode: "EUR" }
    },
    {
        type: "action",
        typeAttributes: {
            rowActions: [{ label: "View Invoices", name: "view_invoices" }]
        }
    }
];

export default class SubscriptionDashboard extends LightningElement {
    @api recordId;

    subscriptions = [];
    error;
    isLoading = true;
    selectedSubscriptionId;
    selectedSubscriptionName;

    columns = COLUMNS;

    @wire(getSubscriptions, { accountId: "$recordId" })
    wiredSubscriptions({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.subscriptions = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body?.message || "An error occurred loading subscriptions.";
            this.subscriptions = [];
        }
    }

    get totalMrr() {
        return this.subscriptions
            .filter((sub) => sub.Status__c === "Active")
            .reduce((sum, sub) => sum + (sub.Monthly_Amount__c || 0), 0);
    }

    get activeCount() {
        return this.subscriptions.filter((sub) => sub.Status__c === "Active").length;
    }

    get totalCount() {
        return this.subscriptions.length;
    }

    get hasSubscriptions() {
        return !this.isLoading && !this.error && this.subscriptions.length > 0;
    }

    get isEmpty() {
        return !this.isLoading && !this.error && this.subscriptions.length === 0;
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        if (action.name === "view_invoices") {
            this.selectedSubscriptionId = row.Id;
            this.selectedSubscriptionName = row.Name;
        }
    }

    handleCloseInvoices() {
        this.selectedSubscriptionId = undefined;
        this.selectedSubscriptionName = undefined;
    }
}
