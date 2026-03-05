import { LightningElement, wire, track } from 'lwc';
import getOpenRequests from '@salesforce/apex/ServiceRequestController.getOpenRequests';
import closeRequest from '@salesforce/apex/ServiceRequestController.closeRequest';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

const COLUMNS = [
    { label: 'Request Number', fieldName: 'recordUrl', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_self' } },
    { label: 'Subject', fieldName: 'Subject__c' },
    { label: 'Priority', fieldName: 'Priority__c' },
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Assigned Agent', fieldName: 'AgentName' },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [{ label: 'Mark as Closed', name: 'close' }]
        }
    }
];

export default class ServiceRequestDashboard extends NavigationMixin(LightningElement) {

    @track requests = [];
    columns = COLUMNS;
    @track selectedPriority = '';
    showModal = false;
    resolutionNotes = '';
    selectedRequestId = null;
    wiredResult;

    priorityOptions = [
        { label: 'All', value: '' },
        { label: 'Low', value: 'Low' },
        { label: 'Medium', value: 'Medium' },
        { label: 'High', value: 'High' }
    ];

    @wire(getOpenRequests)
    wiredRequests(result) {
        this.wiredResult = result;
        if (result.data) {
            this.requests = result.data.map(sr => ({
                ...sr,
                AgentName: sr.Assigned_Agent__r ? sr.Assigned_Agent__r.Name : '',
                recordUrl: '/' + sr.Id
            }));
        }
    }

    get filteredRequests() {
        if (!this.selectedPriority) {
            return this.requests;
        }
        return this.requests.filter(sr => sr.Priority__c === this.selectedPriority);
    }

    handlePriorityChange(event) {
        this.selectedPriority = event.detail.value;
    }

    handleRowAction(event) {
        this.selectedRequestId = event.detail.row.Id;
        this.resolutionNotes = '';
        this.showModal = true;
    }

    handleNotesChange(event) {
        this.resolutionNotes = event.target.value;
    }

    closeModal() {
        this.showModal = false;
    }

    confirmClose() {
        if (!this.resolutionNotes) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Resolution notes are required.',
                variant: 'error'
            }));
            return;
        }

        closeRequest({ requestId: this.selectedRequestId, resolutionNotes: this.resolutionNotes })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Request closed successfully.',
                    variant: 'success'
                }));
                this.showModal = false;
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                }));
            });
    }
}