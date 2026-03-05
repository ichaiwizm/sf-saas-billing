trigger ServiceRequestTrigger on Service_Request__c (before insert) {
    ServiceRequestService.assignAgentOnHighPriority(Trigger.new);
}