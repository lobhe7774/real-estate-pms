public without sharing class PropertyTenantTriggerHandler {

    // ---------- BEFORE INSERT ----------
    public static void setUniqueKey(List<Property_Tenant__c> rows) {
        for (Property_Tenant__c pt : rows) {
            pt.Unique_Key__c = String.valueOf(pt.Property__c) + '_' + String.valueOf(pt.Tenant__c);
        }
    }

    // ---------- AFTER INSERT ----------
    public static void afterInsert(List<Property_Tenant__c> rows) {
        createLeaseTasks(rows);
        markPropertiesOccupied(rows);
    }

    private static void createLeaseTasks(List<Property_Tenant__c> rows) {
        Set<Id> propertyIds = new Set<Id>();
        Set<Id> tenantIds = new Set<Id>();
        for (Property_Tenant__c pt : rows) {
            propertyIds.add(pt.Property__c);
            tenantIds.add(pt.Tenant__c);
        }

        Map<Id, Property__c> properties = new Map<Id, Property__c>(
            [SELECT Id, Name, OwnerId FROM Property__c WHERE Id IN :propertyIds]
        );
        Map<Id, Tenant__c> tenants = new Map<Id, Tenant__c>(
            [SELECT Id, Name FROM Tenant__c WHERE Id IN :tenantIds]
        );

        List<Task> tasks = new List<Task>();
        for (Property_Tenant__c pt : rows) {
            Property__c prop = properties.get(pt.Property__c);
            Tenant__c ten = tenants.get(pt.Tenant__c);
            if (prop == null || ten == null) {
                continue;
            }
            tasks.add(new Task(
                Subject = ('Generate lease agreement: ' + ten.Name + ' / ' + prop.Name).abbreviate(255),
                Description = 'Create the lease agreement for tenant ' + ten.Name +
                              ' on property ' + prop.Name + '.',
                WhatId = pt.Id,
                OwnerId = prop.OwnerId,
                ActivityDate = Date.today().addDays(3),
                Priority = 'High',
                Status = 'Not Started'
            ));
        }
        if (!tasks.isEmpty()) {
            insert tasks;
        }
    }

    private static void markPropertiesOccupied(List<Property_Tenant__c> rows) {
        Set<Id> propertyIds = new Set<Id>();
        for (Property_Tenant__c pt : rows) {
            propertyIds.add(pt.Property__c);
        }

        List<Property__c> toUpdate = new List<Property__c>();
        for (Property__c p : [
            SELECT Id FROM Property__c
            WHERE Id IN :propertyIds AND Status__c != 'Occupied'
        ]) {
            toUpdate.add(new Property__c(Id = p.Id, Status__c = 'Occupied'));
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    // ---------- AFTER DELETE ----------
    public static void afterDelete(List<Property_Tenant__c> deletedRows) {
        Set<Id> propertyIds = new Set<Id>();
        for (Property_Tenant__c pt : deletedRows) {
            propertyIds.add(pt.Property__c);
        }

        // Properties that still have at least one assignment
        Set<Id> stillAssigned = new Set<Id>();
        for (AggregateResult ar : [
            SELECT Property__c p FROM Property_Tenant__c
            WHERE Property__c IN :propertyIds GROUP BY Property__c
        ]) {
            stillAssigned.add((Id) ar.get('p'));
        }

        // Only properties that still exist (a deleted parent cascades its children)
        List<Property__c> toUpdate = new List<Property__c>();
        for (Property__c p : [
            SELECT Id FROM Property__c
            WHERE Id IN :propertyIds AND Status__c = 'Occupied'
        ]) {
            if (!stillAssigned.contains(p.Id)) {
                toUpdate.add(new Property__c(Id = p.Id, Status__c = 'Available'));
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}