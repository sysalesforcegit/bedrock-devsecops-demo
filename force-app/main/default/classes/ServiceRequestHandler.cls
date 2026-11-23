public with sharing class ServiceRequestHandler {

    public static void handleBeforeInsertUpdate(List<Service_Request__c> records) {
        for (Service_Request__c sr : records) {
            setDefaultPriority(sr);
            setDefaultStatus(sr);
        }
    }

    private static void setDefaultPriority(Service_Request__c sr) {
        if (String.isBlank(sr.Priority__c)) {
            if (sr.Category__c == 'IT Support') {
                sr.Priority__c = 'High';
            } else if (sr.Category__c == 'HR') {
                sr.Priority__c = 'Medium';
            } else {
                sr.Priority__c = 'Low';
            }
        }
    }
    private static void setDefaultStatus(Service_Request__c sr) {
        if (String.isBlank(sr.Status__c)) {
            sr.Status__c = 'New';
        }
    }
}
