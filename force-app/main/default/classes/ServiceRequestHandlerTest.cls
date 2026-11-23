@isTest
private class ServiceRequestHandlerTest {

    @isTest
    static void testITSupportGetsHighPriority() {
        Service_Request__c sr = new Service_Request__c(
            Subject__c = 'Laptop not working',
            Category__c = 'IT Support'
        );
        insert sr;

        Service_Request__c result = [
            SELECT Priority__c, Status__c
            FROM Service_Request__c
            WHERE Id = :sr.Id
        ];
        System.assertEquals('High', result.Priority__c,
            'IT Support should auto-assign High priority');
        System.assertEquals('New', result.Status__c,
            'Status should default to New when not provided');
    }

    @isTest
    static void testHRGetsMediumPriority() {
        Service_Request__c sr = new Service_Request__c(
            Subject__c = 'Payroll query',
            Category__c = 'HR'
        );
        insert sr;

        Service_Request__c result = [SELECT Priority__c FROM Service_Request__c WHERE Id = :sr.Id];
        System.assertEquals('Medium', result.Priority__c,
            'HR category should auto-assign Medium priority');
    }

    @isTest
    static void testOtherCategoryGetsLowPriority() {
        Service_Request__c sr = new Service_Request__c(
            Subject__c = 'Need a new chair',
            Category__c = 'Facilities'
        );
        insert sr;

        Service_Request__c result = [SELECT Priority__c FROM Service_Request__c WHERE Id = :sr.Id];
        System.assertEquals('Low', result.Priority__c,
            'Facilities category should auto-assign Low priority');
    }

    @isTest
    static void testExplicitPriorityNotOverridden() {
        Service_Request__c sr = new Service_Request__c(
            Subject__c = 'Critical IT issue',
            Category__c = 'IT Support',
            Priority__c = 'Low'
        );
        insert sr;

        Service_Request__c result = [SELECT Priority__c FROM Service_Request__c WHERE Id = :sr.Id];
        System.assertEquals('Low', result.Priority__c,
            'An explicitly set priority must not be overridden by the handler');
    }

    @isTest
    static void testUpdateDoesNotResetExistingPriority() {
        Service_Request__c sr = new Service_Request__c(
            Subject__c = 'Initial request',
            Category__c = 'IT Support'
        );
        insert sr;

        // Confirm auto-assigned
        Service_Request__c inserted = [SELECT Priority__c FROM Service_Request__c WHERE Id = :sr.Id];
        System.assertEquals('High', inserted.Priority__c, 'Priority should be High after insert');

        // Update the subject only — priority should stay High
        inserted.Subject__c = 'Updated subject';
        update inserted;

        Service_Request__c updated = [SELECT Priority__c FROM Service_Request__c WHERE Id = :sr.Id];
        System.assertEquals('High', updated.Priority__c,
            'Priority should not change on update when already set');
    }
}