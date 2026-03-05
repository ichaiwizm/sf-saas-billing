public with sharing class ServiceRequestService {

    public static void assignAgentOnHighPriority(List<Service_Request__c> requests) {
        Id currentUserId = UserInfo.getUserId();

        for (Service_Request__c sr : requests) {
            if (sr.Priority__c == 'High' && sr.Assigned_Agent__c == null) {
                sr.Assigned_Agent__c = currentUserId;
            }
        }
    }
}