/**
 * @name AddressPostService_Test
 * @desc Test class for AddressPostService
 * 
 * @author Andrew Frederick
 * @see AddressPostService
 */
@IsTest
public with sharing class AddressPostService_Test {

/**
 * PROPERTIES
 */

    private static npsp__Address__c[] addresses {
        get {
            if (addresses == null) {
                addresses = getAddresses();
            }
            return addresses;
        }
        set;
    }

    private static final String STREET1 = '123 Plane Lane';
    private static final String STREET2 = '8575 Westlane Drive';
    
/**
 * TEST SETUP
 */

    @TestSetup
    static void makeData() {

        Account account = new Account();
        account.Name = 'Andrew Frederick';
        account.npsp__Matching_Gift_Email__c = 'andrew@frederick.com';
        account.RecordTypeId = AccountConstants.HOUSEHOLD_ACCOUNT;

        insert account;

        npsp__Address__c address1 = new npsp__Address__c();
        address1.npsp__Household_Account__c = account.Id;
        address1.npsp__MailingStreet__c = STREET1;
        address1.npsp__MailingStreet2__c = 'Apt 1';
        address1.npsp__MailingCity__c = 'Springfiled';
        address1.npsp__MailingState__c = 'AZ';
        address1.npsp__MailingPostalCode__c = '12345';
        address1.npsp__MailingCountry__c = 'US';
        address1.npsp__Default_Address__c = false;

        insert address1;

        npsp__Address__c address2 = new npsp__Address__c();
        address2.npsp__Household_Account__c = account.Id;
        address2.npsp__MailingStreet__c = STREET2;
        address2.npsp__MailingCity__c = 'Bailville';
        address2.npsp__MailingState__c = 'MA';
        address2.npsp__MailingPostalCode__c = '10487';
        address2.npsp__MailingCountry__c = 'US';
        address2.npsp__Default_Address__c = true;

        insert address2;
    }
    
/**
 * POSITIVE TEST METHODS
 */

    /**
     * @name testCreate
     * @desc tests creating an address explictly using the 'Simple' scenario (the originally expected 'scenario' as per the requirements). 
     * It does test any scenario really as the logic is always the same regardless.
     */
    @IsTest
    public static void testCreate() {

        Assert.areEqual( 2, addresses.size() );

        addresses = null; // null out address to force property to re-query

        AddressParser.ClientSideUser user = getUserWithNewAddress();
        
        String scenario = AddressParserSimple.class.getName(); 

        setRestContext( user, scenario );

        Test.startTest();

            AddressPostService.post();

        Test.stopTest();

        Assert.areEqual( 3, addresses.size() );
    }

    /**
     * @name testUpdateSimple
     * @desc tests updating an address ecplictly using the 'Simple' scenario 
     */
    @IsTest
    public static void testUpdateSimple() {

        npsp__Address__c address1 = findAddressByStreet(STREET1);
        npsp__Address__c address2 = findAddressByStreet(STREET2);

        Assert.isFalse( address1.npsp__Default_Address__c );
        Assert.isTrue( address2.npsp__Default_Address__c );

        addresses = null; // null out address to force property to re-query

        AddressParser.ClientSideUser user = getUserWithExistingAddress();
        
        String scenario = AddressParserSimple.class.getName();
        
        setRestContext( user, scenario );

        Test.startTest();

            AddressPostService.post();

        Test.stopTest();
        
        address1 = findAddressByStreet(STREET1);
        address2 = findAddressByStreet(STREET2);

        Assert.isTrue( address1.npsp__Default_Address__c );
        Assert.isFalse( address2.npsp__Default_Address__c );
    }

    /**
     * @name testUpdateWithCompare
     * @desc tests updating an address ecplictly using the 'Compare' scenario 
     */
    @IsTest
    public static void testUpdateWithCompare() {

        AddressParser.ClientSideUser user = getUserWithExistingAddress();
        user.existingAddress = getExistingClientSideAddress();
        
        // simulate change of address on client
        String newStreet = '223 Plane Lane';
        user.newAddress.street1 = newStreet;
        
        String scenario = AddressParserCompare.class.getName(); 

        setRestContext( user, scenario );

        Test.startTest();

            AddressPostService.post();

        Test.stopTest();

        npsp__Address__c address = findAddressByStreet(newStreet);

        Assert.areEqual( newStreet, address.npsp__MailingStreet__c );
    }

    /**
     * @name testUpdateWithAddressId
     * @desc tests updating an address ecplictly using the 'Address Id' scenario 
     */
    @IsTest
    public static void testUpdateWithAddressId() {

        npsp__Address__c address = findAddressByStreet(STREET1);

        AddressParser.ClientSideUser user = getUserWithExistingAddress();
        user.newAddress.addressId = address.Id;

        addresses = null; // null out address to force property to re-query
        
        // simulate change of address on client
        String newStreet = '333 Plane Lane';
        user.newAddress.street1 = newStreet;
        
        String scenario = AddressParserAddressId.class.getName(); 

        setRestContext( user, scenario );

        Test.startTest();

            AddressPostService.post();

        Test.stopTest();

        address = findAddressByStreet(newStreet);
        
        Assert.areEqual( newStreet, address.npsp__MailingStreet__c );
    }

/**
 * NEGATIVE TEST METHODS
 */

    /**
     * @name testBadEmail
     * @desc tests sending a user with an email that matches no accounts
     */
    @IsTest
    public static void testBadEmail() {
        AddressParser.ClientSideUser user = getUserWithNewAddress();
        user.email = 'me@me.com'; 

        String scenario = AddressParserSimple.class.getName(); 

        setRestContext( user, scenario );

        Test.startTest();

            AddressPostService.post();

        Test.stopTest();
        
        Assert.isTrue( RestServicesUtility.getIsRejected() );
        Assert.areEqual( 400, RestContext.response.statusCode );
    }

    /**
     * @name testBadData
     * @desc tests sending data in a bad format
     */
    @IsTest
    public static void testBadData() {
        String requestBodyJSON = getBadRequestBodyJSON();

        String scenario = AddressParserSimple.class.getName(); 

        setRestContext( requestBodyJSON, scenario );

        Test.startTest();

            AddressPostService.post();

        Test.stopTest();
        
        Assert.isTrue( RestServicesUtility.getIsRejected() );
        Assert.areEqual( 400, RestContext.response.statusCode );
    }

    /**
     * @name testErrorOnUpsert
     * @desc attempts to insert an address without a household account. There is a npsp package validation that requires a household account for an address.
     */
    @IsTest
    public static void testErrorOnUpsert() {

        AddressParser.ClientSideUser user = getUserWithNewAddress();
        user.newAddress.isDefault = null; // this causes errors on insert as the system expects a boolean

        String scenario = AddressParserSimple.class.getName(); 

        setRestContext( user, scenario );

        Test.startTest();

            AddressPostService.post();

        Test.stopTest();
        
        Assert.isTrue( RestServicesUtility.getIsRejected() );
        Assert.areEqual( 500, RestContext.response.statusCode );
    }

/**
 * UTILITY METHODS
 */

    /**
     * @name getAddresses
     * @desc gets addresses that were made in test setup. Lazy loaded into address property.
     * @return all addresses in test context database
     */
    private static npsp__Address__c[] getAddresses() {
        return [
            SELECT
                Id,
                Name,
                npsp__MailingStreet__c,
                npsp__MailingStreet2__c,
                npsp__MailingCity__c,
                npsp__MailingState__c,
                npsp__MailingPostalCode__c,
                npsp__MailingCountry__c,
                npsp__Default_Address__c
            FROM npsp__Address__c];
    }

    /**
     * @name findAddressByStreet
     * @desc sorts through created address and returns one matched by the street address
     * 
     * @param street - alphanumeric street address 
     */
    private static npsp__Address__c findAddressByStreet( String street ) {
        npsp__Address__c match;

        for (npsp__Address__c address : addresses) {

            if (address.npsp__MailingStreet__c == street) {
                match = address;
            }
        }

        return match;
    }

    private static AddressParser.ClientSideUser getUserWithExistingAddress() {

        AddressParser.ClientSideUser user = getClientSideUser();
        user.newAddress = getExistingClientSideAddress();

        return user;
    }

    private static AddressParser.ClientSideUser getUserWithNewAddress() {

        AddressParser.ClientSideUser user = getClientSideUser();
        user.newAddress = getNewClientSideAddress();

        return user;
    }

    private static AddressParser.ClientSideUser getClientSideUser() {
        AddressParser.ClientSideUser user = new AddressParser.ClientSideUser();
        
        user.firstName = 'Andrew';
        user.lastName = 'Frederick';
        user.email = 'andrew@frederick.com';
        
        return user;
    }

    private static AddressParser.ClientSideAddress getExistingClientSideAddress() {
        AddressParser.ClientSideAddress address = new AddressParser.ClientSideAddress();
        
        address.street1 = STREET1;
        address.street2 = 'Apt 1';
        address.city = 'Springfiled';
        address.state = 'AZ';
        address.zip = '12345';
        address.country = 'US';
        address.isDefault = true;

        return address;
    }

    private static AddressParser.ClientSideAddress getNewClientSideAddress() {
        AddressParser.ClientSideAddress address = new AddressParser.ClientSideAddress();
        
        address.street1 = '111 Tulip Street';
        address.city = 'Townsend';
        address.state = 'MN';
        address.zip = '55336';
        address.country = 'US';
        address.isDefault = false;

        return address;
    }

    private static void setRestContext( AddressParser.ClientSideUser user, String scenario ) {
        String requestBody = JSON.serialize( user );

        setRestContext( requestBody, scenario );
    }

    private static void setRestContext( String requestBody, String scenario ) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = 'services/apexrest/creedint/v1/address';
        req.httpMethod = 'POST';
        req.headers.put( 'Scenario', scenario );
        req.requestBody = Blob.valueOf( requestBody );

        RestContext.request = req;
        RestContext.response = res;
    }

    private static String getBadRequestBodyJSON() {
        String requestBodyJSON = '{';
                requestBodyJSON += '"firstName" : "Andrew",';
                requestBodyJSON += '"lastName" : "Frederick",';
                requestBodyJSON += '"email" : "andrewjfrederick@gmail.com",';
                requestBodyJSON += '"address" : {'; // this is a bad prop name
                    requestBodyJSON += '"addressId " : null,';
                    requestBodyJSON += '"street1" : "123 Plane Lane",';
                    requestBodyJSON += '"street2" : null,';
                    requestBodyJSON += '"city" : "Springfiled",';
                    requestBodyJSON += '"state" : "AZ",';
                    requestBodyJSON += '"zip" : "12345",';
                    requestBodyJSON += '"country" : "US",';
                    requestBodyJSON += '"isDefault" : false';
                requestBodyJSON += '}';
            requestBodyJSON += '}';
        
        return requestBodyJSON;
    }
}