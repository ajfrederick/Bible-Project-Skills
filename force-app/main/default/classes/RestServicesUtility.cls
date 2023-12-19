/**
 * @name RestServicesUtility
 * @desc REST Utility for Demo for Bible Project
 * 
 * @author Andrew Frederick
 */
public without sharing class RestServicesUtility {
    
/**
 * PROPERTIES
 */ 

    private static Boolean isSuccess {get; set;}
    
    private static Boolean isRejected {
        get {
            if (isRejected == null) {
                isRejected = false;
            }
            return isRejected;
        }
        set;
    }
   
/**
 * ACTION METHODS
 */
    
    public static Boolean getIsSuccess() {
        return isSuccess;
    }
    
    public static Boolean getIsRejected() {
        return isRejected;
    }

/**
 * ACTION METHODS
 */

    public static void respondSuccess( SObject obj ) {
        if (isRejected) {return;}

        respondSuccess( JSON.serialize( obj ) );
    }

    public static void respondSuccess( String message ) {
        if (isRejected) {return;}

        RestContext.response.statusCode = 201;
        RestContext.response.responseBody = Blob.valueOf( message );

        isSuccess = true;
    }

    public static void rejectBadRequest( String message ) {
        RestContext.response.statusCode = 400;
        reject( message );
    }

    public static void rejectServerError( String message ) {
        RestContext.response.statusCode = 500;
        reject( message );
    }

    private static void reject( String message ){
        RestContext.response.responseBody = Blob.valueOf( message );
        isRejected = true;
    }
}