/**
 * OuvertureFermetureUserLookupHelper
 *
 * Helper class to look up Salesforce Users by their name.
 * Designed to be used in flows or processes via @InvocableMethod.
 *
 * Author: Malek Brachemi
 * Date: 2025-07-07
 */
public without sharing class OuvertureFermetureUserLookupHelper {
    
  /**
   * Retrieves a User record by name.
   * - Accepts a list of usernames (String).
   * - Returns a list containing the first matching User record (Id, Name, Email).
   * - If no name is provided, returns an empty list.
   *
   * @param userNames List of user names (only the first element is used).
   * @return List<User> containing the matching user (or empty if none found).
   */
  @InvocableMethod(label='Get User by Name')
  public static List<User> getUserByName(List<String> userNames) {
      // Return empty list if no input is provided
      if (userNames.isEmpty()) return new List<User>();
      
      // Query Salesforce for a User whose Name matches the first item in the list
      return [
          SELECT Id, Name, Email 
          FROM User 
          WHERE Name = :userNames[0] 
          LIMIT 1
      ];
  }
}