/**
 * @name AccountConstants
 * @desc Constants for the Account Object
 * 
 * @author Andrew Frederick
 */
public without sharing class AccountConstants {

    public static final Id HOUSEHOLD_ACCOUNT = Schema.Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('HH_Account').getRecordTypeId();

}