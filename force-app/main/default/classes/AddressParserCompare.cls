/**
 * @name AddressParserCompare
 * @desc parses client side request body for AddressPostService given the situation in with the client app places the the original address values 
 * in the request body which will be used to find the address to update.
 * 
 * @author Andrew Frederick
 * @see AddressPostService
 */
public with sharing class AddressParserCompare extends AddressParser {

/**
 * ABSTRACT/VIRTUAL METHODS
 */

    public override void parseRequest( String requestBody ) {
        deserialize( requestBody );

        addressToUpsert = findExistingAddress( user.existingAddress );

        setValues();
    }
}