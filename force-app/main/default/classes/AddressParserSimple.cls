/**
 * @name AddressParserSimple
 * @desc parses client side request body for AddressPostService. 
 * Possibly the correct way to interpret that requirements?
 * 
 * @author Andrew Frederick
 * @see AddressPostService
 */
public with sharing class AddressParserSimple extends AddressParser {

/**
 * ABSTRACT/VIRTUAL METHODS
 */

    public override void parseRequest( String requestBody ) {
        deserialize( requestBody );

        addressToUpsert = findExistingAddress( newAddress );

        setValues();
    }

    protected override void setValues() {

        if (addressToUpsert.Id != null) {
            addressToUpsert.npsp__Default_Address__c = true; // update existing address as new default
        } else {
            super.setValues(); // create new address
        }
    }
}