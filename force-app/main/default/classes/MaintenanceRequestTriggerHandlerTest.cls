@isTest
private class MaintenanceRequestTriggerHandlerTest {

    @isTest
    static void singleRequest_goesToVendorWithLeastWorkload() {
        Property__c prop = TestDataFactory.createProperty();
        List<Vendor__c> vendors = TestDataFactory.createVendors(2);

        // Vendor 01 has 2 active requests, Vendor 02 has 1
        insert TestDataFactory.buildRequests(prop.Id, 2, 'Open', vendors[0].Id);
        insert TestDataFactory.buildRequests(prop.Id, 1, 'In progress', vendors[1].Id);

        Maintenance_Request__c newReq = TestDataFactory.buildRequests(prop.Id, 1, 'Open', null)[0];

        Test.startTest();
        insert newReq;
        Test.stopTest();

        Maintenance_Request__c saved = [SELECT Vendor__c FROM Maintenance_Request__c WHERE Id = :newReq.Id];
        System.assertEquals(vendors[1].Id, saved.Vendor__c, 'Should pick the vendor with fewer active requests');
    }

    @isTest
    static void bulkInsert_spreadsEvenlyAcrossVendors() {
        Property__c prop = TestDataFactory.createProperty();
        List<Vendor__c> vendors = TestDataFactory.createVendors(4);

        List<Maintenance_Request__c> reqs = TestDataFactory.buildRequests(prop.Id, 200, 'Open', null);

        Test.startTest();
        insert reqs;
        Test.stopTest();

        Map<Id, Integer> counts = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Vendor__c v, COUNT(Id) c FROM Maintenance_Request__c GROUP BY Vendor__c
        ]) {
            counts.put((Id) ar.get('v'), (Integer) ar.get('c'));
        }
        System.assertEquals(4, counts.size(), 'All four vendors should receive work');
        for (Vendor__c v : vendors) {
            System.assertEquals(50, counts.get(v.Id), 'Each vendor should get 50 of 200');
        }
    }

    @isTest
    static void noVendorsExist_insertSucceedsWithBlankVendor() {
        Property__c prop = TestDataFactory.createProperty();
        Maintenance_Request__c req = TestDataFactory.buildRequests(prop.Id, 1, 'Open', null)[0];

        Test.startTest();
        insert req;
        Test.stopTest();

        System.assertEquals(null, [SELECT Vendor__c FROM Maintenance_Request__c WHERE Id = :req.Id].Vendor__c);
    }

    @isTest
    static void manuallyChosenVendor_isPreserved() {
        Property__c prop = TestDataFactory.createProperty();
        List<Vendor__c> vendors = TestDataFactory.createVendors(2);

        Maintenance_Request__c req = TestDataFactory.buildRequests(prop.Id, 1, 'Open', vendors[1].Id)[0];

        Test.startTest();
        insert req;
        Test.stopTest();

        System.assertEquals(vendors[1].Id, [SELECT Vendor__c FROM Maintenance_Request__c WHERE Id = :req.Id].Vendor__c);
    }

    @isTest
    static void completedAndCancelledRequests_doNotCountAsWorkload() {
        Property__c prop = TestDataFactory.createProperty();
        List<Vendor__c> vendors = TestDataFactory.createVendors(2);

        // Vendor 01: 3 finished requests (no real workload). Vendor 02: 1 open request.
        insert TestDataFactory.buildRequests(prop.Id, 2, 'Completed', vendors[0].Id);
        insert TestDataFactory.buildRequests(prop.Id, 1, 'Cancelled', vendors[0].Id);
        insert TestDataFactory.buildRequests(prop.Id, 1, 'Open', vendors[1].Id);

        Maintenance_Request__c req = TestDataFactory.buildRequests(prop.Id, 1, 'Open', null)[0];

        Test.startTest();
        insert req;
        Test.stopTest();

        System.assertEquals(vendors[0].Id, [SELECT Vendor__c FROM Maintenance_Request__c WHERE Id = :req.Id].Vendor__c,
            'Vendor with zero active work should win');
    }

    @isTest
    static void tie_goesToFirstVendorByName() {
        Property__c prop = TestDataFactory.createProperty();
        List<Vendor__c> vendors = TestDataFactory.createVendors(3);

        Maintenance_Request__c req = TestDataFactory.buildRequests(prop.Id, 1, 'Open', null)[0];

        Test.startTest();
        insert req;
        Test.stopTest();

        System.assertEquals(vendors[0].Id, [SELECT Vendor__c FROM Maintenance_Request__c WHERE Id = :req.Id].Vendor__c);
    }
}