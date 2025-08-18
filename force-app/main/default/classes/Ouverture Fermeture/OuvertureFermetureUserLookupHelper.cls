public without sharing class OuvertureFermetureUserLookupHelper {
  @InvocableMethod(label='Get User by Name')
    public static List<User> getUserByName(List<String> userNames) {
        if (userNames.isEmpty()) return new List<User>();
        
        return [SELECT Id, Name, Email FROM User 
                WHERE Name = :userNames[0] LIMIT 1];
    }

}