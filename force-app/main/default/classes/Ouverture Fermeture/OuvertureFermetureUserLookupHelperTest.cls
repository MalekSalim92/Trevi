/**
 * OuvertureFermetureUserLookupHelperTest
 *
 * Unit tests for the OuvertureFermetureUserLookupHelper class.
 * Ensures that user lookups by name return expected results and 
 * handle edge cases (such as non-existing user names).
 *
 * Author: Malek Brachemi
 * Date: 2025-07-07
 */
@IsTest
public with sharing class OuvertureFermetureUserLookupHelperTest {
   
    @IsTest
    static void testGetUserByName() {
        Test.startTest();
        
        List<User> users = OuvertureFermetureUserLookupHelper.getUserByName(
            new List<String>{'WrongName'}
        );
        
        Test.stopTest();
        
        System.assertEquals(0, users.size(), 'No user should have been returned');
    }
}