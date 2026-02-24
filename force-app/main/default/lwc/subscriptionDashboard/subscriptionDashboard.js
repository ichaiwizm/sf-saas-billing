import { LightningElement, api, wire } from "lwc";
import getSubscriptions from "@salesforce/apex/SubscriptionController.getSubscriptions";

const STATUS_CLASSES = {
    Active: "badge badge-active",
    Draft: "badge badge-draft",
    Suspended: "badge badge-suspended",
    Cancelled: "badge badge-cancelled",
    Expired: "badge badge-expired"
};

export default class SubscriptionDashboard extends LightningElement {
    @api recordId;

    subscriptions = [];
    error;
    isLoading = true;
    selectedSubscriptionId;
    selectedSubscriptionName;

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

    get formattedSubscriptions() {
        return this.subscriptions.map((sub) => ({
            ...sub,
            statusClass: STATUS_CLASSES[sub.Status__c] || "badge badge-draft"
        }));
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

    handleViewInvoices(event) {
        this.selectedSubscriptionId = event.currentTarget.dataset.id;
        this.selectedSubscriptionName = event.currentTarget.dataset.name;
    }

    handleCloseInvoices() {
        this.selectedSubscriptionId = undefined;
        this.selectedSubscriptionName = undefined;
    }
}
