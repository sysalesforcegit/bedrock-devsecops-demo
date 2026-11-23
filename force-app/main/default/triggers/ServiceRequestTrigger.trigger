trigger ServiceRequestTrigger on Service_Request__c (before insert, before update) {
    ServiceRequestHandler.handleBeforeInsertUpdate(Trigger.new);
}
