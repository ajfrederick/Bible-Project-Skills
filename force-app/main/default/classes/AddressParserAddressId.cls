/**
 * @name AddressParserAddressId
 * @desc parses client side request body for AddressPostService given the situation in with the client app places the the Address' Salesforce record Id 
 * in the request body which will be used to find the address to update.
 * 
 * @author Andrew Frederick
 * @see AddressPostService
 */
public with sharing class AddressParserAddressId extends AddressParser {

/**
 * ABSTRACT/VIRTUAL METHODS
 */

    public override void parseRequest( String requestBody ) {
        deserialize( requestBody );

        addressToUpsert = getExistingAddress();

        setValues();
    }

/**
* QUERY METHODS
*/

    private npsp__Address__c getExistingAddress() {

        if (newAddress.addressId == null) {return null;}

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
            WHERE Id = :newAddress.addressId];
    }
}