@isTest
private class PropertyTenantTriggerHandlerTest {

    @isTest
    static void assignment_createsTaskAndMarksPropertyOccupied() {
        Property__c prop = TestDataFactory.createProperties(1)[0];
        Tenant__c ten = TestDataFactory.createTenants(1)[0];

        Property_Tenant__c pt = new Property_Tenant__c(Property__c = prop.Id, Tenant__c = ten.Id);

        Test.startTest();
        insert pt;
        Test.stopTest();

        List<Task> tasks = [SELECT Subject, WhatId, OwnerId, Status FROM Task WHERE WhatId = :pt.Id];
        System.assertEquals(1, tasks.size(), 'One lease task per assignment');
        System.assert(tasks[0].Subject.startsWith('Generate lease agreement'), 'Subject should describe the task');
        System.assertEquals('Not Started', tasks[0].Status);

        System.assertEquals('Occupied', [SELECT Status__c FROM Property__c WHERE Id = :prop.Id].Status__c);
    }

    @isTest
    static void bulkAssignment_200Records_noLimitsHit() {
        List<Property__c> props = TestDataFactory.createProperties(200);
        List<Tenant__c> tenants = TestDataFactory.createTenants(200);

        List<Property_Tenant__c> rows = new List<Property_Tenant__c>();
        for (Integer i = 0; i < 200; i++) {
            rows.add(new Property_Tenant__c(Property__c = props[i].Id, Tenant__c = tenants[i].Id));
        }

        Test.startTest();
        insert rows;
        Test.stopTest();

        System.assertEquals(200, [SELECT COUNT() FROM Task WHERE Subject LIKE 'Generate lease agreement%']);
        System.assertEquals(200, [SELECT COUNT() FROM Property__c WHERE Status__c = 'Occupied']);
    }

    @isTest
    static void tenantCanRentMultipleProperties() {
        List<Property__c> props = TestDataFactory.createProperties(3);
        Tenant__c ten = TestDataFactory.createTenants(1)[0];

        List<Property_Tenant__c> rows = new List<Property_Tenant__c>();
        for (Property__c p : props) {
            rows.add(new Property_Tenant__c(Property__c = p.Id, Tenant__c = ten.Id));
        }

        Test.startTest();
        insert rows;
        Test.stopTest();

        System.assertEquals(3, [SELECT COUNT() FROM Property_Tenant__c WHERE Tenant__c = :ten.Id]);
        System.assertEquals(3, [SELECT COUNT() FROM Task WHERE Subject LIKE 'Generate lease agreement%']);
    }

    @isTest
    static void duplicateAssignment_isRejected() {
        Property__c prop = TestDataFactory.createProperties(1)[0];
        Tenant__c ten = TestDataFactory.createTenants(1)[0];
        insert new Property_Tenant__c(Property__c = prop.Id, Tenant__c = ten.Id);

        Test.startTest();
        Database.SaveResult sr = Database.insert(
            new Property_Tenant__c(Property__c = prop.Id, Tenant__c = ten.Id), false
        );
        Test.stopTest();

        System.assert(!sr.isSuccess(), 'Duplicate pair must be rejected');
        System.assertEquals(StatusCode.DUPLICATE_VALUE, sr.getErrors()[0].getStatusCode());
    }

    @isTest
    static void deletingLastAssignment_makesPropertyAvailableAgain() {
        Property__c prop = TestDataFactory.createProperties(1)[0];
        Tenant__c ten = TestDataFactory.createTenants(1)[0];
        Property_Tenant__c pt = new Property_Tenant__c(Property__c = prop.Id, Tenant__c = ten.Id);
        insert pt;

        Test.startTest();
        delete pt;
        Test.stopTest();

        System.assertEquals('Available', [SELECT Status__c FROM Property__c WHERE Id = :prop.Id].Status__c);
    }

    @isTest
    static void deletingOneOfTwoAssignments_keepsPropertyOccupied() {
        Property__c prop = TestDataFactory.createProperties(1)[0];
        List<Tenant__c> tenants = TestDataFactory.createTenants(2);
        List<Property_Tenant__c> rows = new List<Property_Tenant__c>{
            new Property_Tenant__c(Property__c = prop.Id, Tenant__c = tenants[0].Id),
            new Property_Tenant__c(Property__c = prop.Id, Tenant__c = tenants[1].Id)
        };
        insert rows;

        Test.startTest();
        delete rows[0];
        Test.stopTest();

        System.assertEquals('Occupied', [SELECT Status__c FROM Property__c WHERE Id = :prop.Id].Status__c);
    }

    @isTest
    static void deletingProperty_cascadesWithoutError() {
        Property__c prop = TestDataFactory.createProperties(1)[0];
        Tenant__c ten = TestDataFactory.createTenants(1)[0];
        insert new Property_Tenant__c(Property__c = prop.Id, Tenant__c = ten.Id);

        Test.startTest();
        delete prop;
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Property_Tenant__c]);
    }
}