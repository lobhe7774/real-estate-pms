trigger PropertyTenantTrigger on Property_Tenant__c (before insert, after insert, after delete) {

    if (Trigger.isBefore && Trigger.isInsert) {
        PropertyTenantTriggerHandler.setUniqueKey(Trigger.new);
    } else if (Trigger.isAfter && Trigger.isInsert) {
        PropertyTenantTriggerHandler.afterInsert(Trigger.new);
    } else if (Trigger.isAfter && Trigger.isDelete) {
        PropertyTenantTriggerHandler.afterDelete(Trigger.old);
    }

}