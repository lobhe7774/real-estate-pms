@isTest
public class TestDataFactory {

    public static List<Property__c> createProperties(Integer count) {
    List<Property__c> props = new List<Property__c>();
    for (Integer i = 0; i < count; i++) {
        props.add(new Property__c(
            Name = 'Test Property ' + i,
            Address__c = i + ' Main St',
            City__c = 'Pune',
            State__c = 'Maharashtra',
            Postal_Code__c = '411001',
            Country__c = 'India',
            Type__c = 'Residential',
            Status__c = 'Available',
            Rent__c = 25000,
            Description__c = 'Test description'
        ));
    }
    insert props;
    return props;
}

public static List<Tenant__c> createTenants(Integer count) {
    List<Tenant__c> tenants = new List<Tenant__c>();
    for (Integer i = 0; i < count; i++) {
        tenants.add(new Tenant__c(
            Name = 'Tenant ' + i,
            Email__c = 'tenant' + i + '@example.com',
            Phone__c = '9999999999'
        ));
    }
    insert tenants;
    return tenants;
}

    public static Property__c createProperty() {
        Property__c p = new Property__c(
            Name = 'Test Property',
            Address__c = '1 Main St',
            City__c = 'Pune',
            State__c = 'Maharashtra',
            Postal_Code__c = '411001',
            Country__c = 'India',
            Type__c = 'Residential',
            Status__c = 'Available',
            Rent__c = 25000,
            Description__c = 'Test description'
        );
        insert p;
        return p;
    }

    public static List<Vendor__c> createVendors(Integer count) {
        List<Vendor__c> vendors = new List<Vendor__c>();
        for (Integer i = 0; i < count; i++) {
            vendors.add(new Vendor__c(
                Name = 'Vendor ' + String.valueOf(i + 1).leftPad(2, '0'),
                Email__c = 'vendor' + i + '@example.com'
            ));
        }
        insert vendors;
        return vendors;
    }

    public static List<Maintenance_Request__c> buildRequests(
        Id propertyId, Integer count, String status, Id vendorId
    ) {
        List<Maintenance_Request__c> reqs = new List<Maintenance_Request__c>();
        for (Integer i = 0; i < count; i++) {
            reqs.add(new Maintenance_Request__c(
                Property__c = propertyId,
                Status__c = status,
                Vendor__c = vendorId,
                Description__c = 'Test request'
            ));
        }
        return reqs;
    }
}