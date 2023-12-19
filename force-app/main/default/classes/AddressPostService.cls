/**
 * @name AddressPostService
 * @desc REST API for updating and creating addresses
 * 
 * @author Andrew Frederick
 */
@RestResource(urlMapping='/v1/address')
global with sharing class AddressPostService {

/**
 * PROPERTIES
 */

    private static npsp__Address__c addressToUpsert {get; set;}

    private static AddressParser parser {get; set;}

    private static String requestBody {
        get {
            return RestContext.request.requestBody.toString();
        }
    }

    /**
     * @name scenario
     * @desc just for this exercise you can determine from a client application what 'Scenario' (i.e. differences in data delivered in request,
     * expectations of api functionality, etc.) to use. Again if you haven't read this yet, I would never do this in the 'real world'. Just was
     * a fun why to tackle the ideterminancy of the requirements before Matt clarified for me.
     */
    private static String scenario {
        get {
            return RestContext.request.headers.get('Scenario');
        }
    }

    /**
     * @name parserTypeByName
     * @desc never would do this in the 'real world' but approached building the 3 possible ways before Matt clarified that what he 
     * was looking for was indeed the 'AddressParserSimple' scenario.
     */
    private static Map<String, Type> parserTypeByName = new Map<String, Type>{
        AddressParserSimple.class.getName() => AddressParserSimple.class,
        AddressParserCompare.class.getName() => AddressParserCompare.class,
        AddressParserAddressId.class.getName() => AddressParserAddressId.class
    };

/**
 * API METHODS
 */

    /**
     * @name post
     * @desc actual method that gets called when a request is made
     */
    @HttpPost
    global static void post() {

        parseRequest();

        upsertAddress();

        RestServicesUtility.respondSuccess( addressToUpsert );
    }

/**
 * ACTION METHODS
 */

    /**
     * @name parseRequest
     * @desc utilizes a helper class to deserializes the request's JSON and catches any malformed data error
     */
    private static void parseRequest() {
        if (RestServicesUtility.getIsRejected()) {return;}

        parser = (AddressParser) parserTypeByName.get(scenario).newInstance();

        try {
            
            parser.parseRequest( requestBody );
             
        } catch( Exception e ){

            ErrorResponse error = new ErrorResponse( 'Client request body may be malformed: ' + e.getMessage() );
            error.details = requestBody;

            System.debug(error);

            RestServicesUtility.rejectBadRequest( JSON.serialize( error ) );
        }
    }

    /**
     * @name upsertAddress
     * @desc upserts Address record and catches any DML errors
     */
    private static void upsertAddress() {
        if (RestServicesUtility.getIsRejected()) {return;}

        addressToUpsert = parser.getAddressToUpsert();

        try {
            
            upsert addressToUpsert;

        } catch( Exception e ){

            ErrorResponse error = new ErrorResponse( 'Upsert Operation Failed: ' + e.getMessage() );
            error.details = JSON.serialize( addressToUpsert );

            System.debug(error);

            RestServicesUtility.rejectServerError( JSON.serialize( error ) );
        }
    }

/**
 * CLASSES
 */

    public class ErrorResponse {
        
        public String message {get;set;}
        public String details {get;set;}

        public ErrorResponse( String message ){
            this.message = message;
        }
    }
}