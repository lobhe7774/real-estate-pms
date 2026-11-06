public without sharing class MaintenanceRequestTriggerHandler {

    private static final Set<String> ACTIVE_STATUSES = new Set<String>{ 'Open', 'In progress' };

    public static void assignVendors(List<Maintenance_Request__c> newRequests) {

        // 1. Find the requests that need a vendor
        List<Maintenance_Request__c> needsVendor = new List<Maintenance_Request__c>();
        for (Maintenance_Request__c mr : newRequests) {
            if (mr.Vendor__c == null) {
                needsVendor.add(mr);
            }
        }
        if (needsVendor.isEmpty()) {
            return;
        }

        // 2. Load all vendors in a stable order (ties go to the first by name)
        List<Id> vendorIds = new List<Id>();
        for (Vendor__c v : [SELECT Id FROM Vendor__c ORDER BY Name, Id]) {
            vendorIds.add(v.Id);
        }
        if (vendorIds.isEmpty()) {
            return; // No vendors exist: leave Vendor__c blank, do not fail the insert
        }

        // 3. Start everyone at zero, then fill in real counts with ONE aggregate query
        Map<Id, Integer> workload = new Map<Id, Integer>();
        for (Id vId : vendorIds) {
            workload.put(vId, 0);
        }
        for (AggregateResult ar : [
            SELECT Vendor__c vendorId, COUNT(Id) cnt
            FROM Maintenance_Request__c
            WHERE Vendor__c IN :vendorIds
              AND Status__c IN :ACTIVE_STATUSES
            GROUP BY Vendor__c
        ]) {
            workload.put((Id) ar.get('vendorId'), (Integer) ar.get('cnt'));
        }

        // 4. Count active requests in this batch that already have a vendor
        for (Maintenance_Request__c mr : newRequests) {
            if (mr.Vendor__c != null && isActive(mr) && workload.containsKey(mr.Vendor__c)) {
                workload.put(mr.Vendor__c, workload.get(mr.Vendor__c) + 1);
            }
        }

        // 5. Assign each unassigned request to the least-loaded vendor
        for (Maintenance_Request__c mr : needsVendor) {
            Id chosen = leastLoadedVendor(vendorIds, workload);
            mr.Vendor__c = chosen;
            if (isActive(mr)) {
                workload.put(chosen, workload.get(chosen) + 1);
            }
        }
    }

    private static Id leastLoadedVendor(List<Id> vendorIds, Map<Id, Integer> workload) {
        Id best = vendorIds[0];
        Integer bestCount = workload.get(best);
        for (Id vId : vendorIds) {
            Integer c = workload.get(vId);
            if (c < bestCount) { // strict < keeps the earlier vendor on ties
                best = vId;
                bestCount = c;
            }
        }
        return best;
    }

    private static Boolean isActive(Maintenance_Request__c mr) {
        // Status__c defaults to 'Open' in the picklist, so a null status counts as Open
        return mr.Status__c == null || ACTIVE_STATUSES.contains(mr.Status__c);
    }
}