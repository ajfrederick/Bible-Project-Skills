/**
 * @name AddressParser
 * @desc abstract service layer class that parses client side request body for AddressPostService. 
 * At first blush there seemed to be too many unkowns in the requirements so I came up with 3 possiblities 
 * given certain circumstances, all of which extend this class.
 * 
 * @author Andrew Frederick
 * @see AddressPostService
 */
public abstract class AddressParser {
    
/**
 * PROPERTIES
 */

    /**
     * @name user
     * @desc the deserailized user from client application which is formatted below
     */
    protected ClientSideUser user {get; set;}

    /**
     * @name newAddress
     * @desc the deserailized changed address info from client application which is formatted below
     */
    protected ClientSideAddress newAddress {get; set;}

    /**
     * @name addressToUpsert
     * @desc formatted SF SObject to be upserted in ApexRestService.cls
     */
    protected npsp__Address__c addressToUpsert {
        get {
            if (addressToUpsert == null) {
                addressToUpsert = new npsp__Address__c();
            }
            return addressToUpsert;
        } 
        set;
    }

    /**
     * @name accounts
     * @desc list of accounts found with user's email address
     */
    protected Account[] accounts {
        get {
            if (accounts == null) {
                accounts = getAccounts();
            }
            return accounts;
        }
        set;
    }

    /**
     * @name existingAddresses
     * @desc all addresses that are currently in SF's database associated with the user's account
     */
    private npsp__Address__c[] existingAddresses {
        get {
            if (existingAddresses == null) {
                existingAddresses = getAddresses();
            }
            return existingAddresses;
        }
        set;
    }


/**
 * GETTERS
 */ 

    public npsp__Address__c getAddressToUpsert() {
        return addressToUpsert;
    }

/**
 * ABSTRACT/VIRTUAL METHODS
 */

    /**
     * @name parseRequest
     * @desc all addresses that are currently in SF's database associated with the user's account. Implemented by extended class
     * which each represent a 'Scenario'.
     * 
     * @param requestBody - the body of the Http request which contains the user and address data to be deserialzed and parsed into and address SObject
     */
    public abstract void parseRequest( String requestBody );

    /**
     * @name setValues
     * @desc sets the deserialized values on the Address SObject. Called in parserRequest().
     */
    protected virtual void setValues() {
        addressToUpsert.npsp__Household_Account__c = accounts[0].Id;
        addressToUpsert.npsp__MailingStreet__c = newAddress.street1;
        addressToUpsert.npsp__MailingStreet2__c = newAddress.street2;
        addressToUpsert.npsp__MailingCity__c = newAddress.city;
        addressToUpsert.npsp__MailingState__c = newAddress.state;
        addressToUpsert.npsp__MailingPostalCode__c = newAddress.zip;
        addressToUpsert.npsp__MailingCountry__c = newAddress.country;
        addressToUpsert.npsp__Default_Address__c = newAddress.isDefault;
    } 

/**
 * UTILITY METHODS
 */

    /**
     * @name deserialize
     * @desc deserialized values from client deliver JSON. Called in parserRequest().
     * 
     * @param requestBody - the body of the Http request which contains the user and address data to be deserialzed and parsed into and address SObject
     */
    protected void deserialize( String requestBody ) {
        user = (ClientSideUser) JSON.deserialize( requestBody, ClientSideUser.class );

        newAddress = user.newAddress;
    }
    
    /**
     * @name findExistingAddress
     * @desc helps to find the existing address to update it if it exists.
     * 
     * @param addressToCompare - this the address that is given to use from the client app to match an exisitng address
     */
    protected npsp__Address__c findExistingAddress( ClientSideAddress addressToCompare ) {
        if (addressToCompare == null) {return null;}

        npsp__Address__c match;

        for (npsp__Address__c exsitingAddress : existingAddresses) {
            
            if (isSameAddress(exsitingAddress, addressToCompare)) {
                match = exsitingAddress;
                break;
            }
        }

        return match;
    }

    /**
     * @name isSameAddress
     * @desc matches all reasonable values to see if the two address are the same
     * 
     * @param exsitingAddress - address in SF database
     * @param addressToCompare - this the address that is given to use from the client app to match an exisitng address
     */
    protected Boolean isSameAddress( npsp__Address__c exsitingAddress, ClientSideAddress addressToCompare ) {
        Boolean isSameAddress = true;

        isSameAddress = isSameAddress && exsitingAddress.npsp__MailingStreet__c == addressToCompare.street1;
        isSameAddress = isSameAddress && exsitingAddress.npsp__MailingStreet2__c == addressToCompare.street2;
        isSameAddress = isSameAddress && exsitingAddress.npsp__MailingCity__c == addressToCompare.city;
        isSameAddress = isSameAddress && exsitingAddress.npsp__MailingState__c == addressToCompare.state;
        isSameAddress = isSameAddress && exsitingAddress.npsp__MailingPostalCode__c == addressToCompare.zip;
        isSameAddress = isSameAddress && exsitingAddress.npsp__MailingCountry__c == addressToCompare.country;
        
        return isSameAddress;
    }

/**
 * QUERY METHODS
 */

    /**
     * @name getAccounts
     * @desc gets household acccount based off users email
     * @return list of accounts
     */
    protected Account[] getAccounts() {
        accounts = new Account[]{};

        accounts.addAll([
            SELECT
                Id
            FROM Account
            WHERE npsp__Matching_Gift_Email__c = :user.email
            AND RecordTypeId = :AccountConstants.HOUSEHOLD_ACCOUNT]);
        
        return accounts;
    }

    /**
     * @name getAddresses
     * @desc gets all addresses for the account representing the user by the users email.
     * @return address belonging to the users household account if there is only one account
     */
    protected npsp__Address__c[] getAddresses() {

        if (accounts.size() != 1) {
            throw new AccountException('Either No Accounts found for user\'s email or more than one account found. Please contact Bible Project for assistance.');
        }

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
            FROM npsp__Address__c
            WHERE npsp__Household_Account__c = :accounts[0].Id];
    }

/**
 * DATA FORMAT CLASSES
 */

    public class ClientSideUser {
        public String firstName {get; set;}
        public String lastName {get; set;}
        public String email {get; set;}
        public ClientSideAddress existingAddress {get; set;}
        public ClientSideAddress newAddress {get; set;}
    }

    public class ClientSideAddress {
        public Id addressId {get; set;}
        public String street1 {get; set;}
        public String street2 {get; set;}
        public String city {get; set;}
        public String state {get; set;}
        public String zip {get; set;}
        public String country {get; set;}
        public Boolean isDefault {get; set;}
    }

    public class AccountException extends Exception {}
}