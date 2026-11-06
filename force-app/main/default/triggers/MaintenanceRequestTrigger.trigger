trigger MaintenanceRequestTrigger on Maintenance_request__c (before insert) {
 if (Trigger.isBefore && Trigger.isInsert) {
        MaintenanceRequestTriggerHandler.assignVendors(Trigger.new);
    }
}