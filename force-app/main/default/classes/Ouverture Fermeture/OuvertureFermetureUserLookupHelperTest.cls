@IsTest
public with sharing class OuvertureFermetureUserLookupHelperTest {
   
@IsTest
    static void testGetUserByName() {
             Test.startTest();
            
            List<User> users = OuvertureFermetureUserLookupHelper.getUserByName(new List<String>{'WrongName'});
            
            Test.stopTest();
            
            System.assertEquals(0, users.size(), 'No user should have been returned');
        }
    }
