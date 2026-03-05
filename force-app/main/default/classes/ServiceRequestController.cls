public with sharing class ServiceRequestController {

    @AuraEnabled(cacheable=true)
    public static List<Service_Request__c> getOpenRequests() {
        return [
            SELECT Name, Subject__c, Priority__c, Status__c, Assigned_Agent__r.Name
            FROM Service_Request__c
            WHERE Status__c != 'Closed'
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled
    public static void closeRequest(Id requestId, String resolutionNotes) {
        Service_Request__c sr = [
            SELECT Id FROM Service_Request__c WHERE Id = :requestId
        ];
        sr.Status__c = 'Closed';
        sr.Resolution_Notes__c = resolutionNotes;
        update sr;
    }
}