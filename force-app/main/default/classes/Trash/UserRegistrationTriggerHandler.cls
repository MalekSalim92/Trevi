public class UserRegistrationTriggerHandler {
    public static void handleAfterInsert(List<User_Registration_Event__e> events) {

        List<Account> accountsToInsert = new List<Account>();
        List<Contact> contactsToInsert = new List<Contact>();
        List<Address__c> addressesToInsert = new List<Address__c>();

        User_Registration_Settings__mdt registrationSettings = [SELECT Id,ownerName__c,accountType__c,recordTypeName__c,addressNickname__c FROM User_Registration_Settings__mdt WHERE¥ DeveloperName ='default' LIMIT 1];

        String ownerName = registrationSettings.ownerName__c; 
        String recordTypeName = registrationSettings.recordTypeName__c; 
        String accountType = registrationSettings.accountType__c; 
        String addressNickname = registrationSettings.addressNickname__c; 

        System.debug('addressNickname ' + addressNickname);

        Id ownerId = [SELECT Id,UserRoleId,Name FROM User WHERE Name = :ownerName AND UserRoleId != null AND isActive = true LIMIT 1].Id; 
        Id recordTypeId = [SELECT Id,DeveloperName,SobjectType FROM RecordType WHERE SobjectType ='Account' AND DeveloperName = :recordTypeName].Id; 
    
        System.debug('recordTypeId ' + recordTypeId);

        for (User_Registration_Event__e event : events) {
            // Create Account
            Account acc = new Account(
     
                Name = event.Account_Name__c,
                Description = event.Account_Description__c,
                Cellphone__c = event.Mobile_Phone__c,
                recordTypeId = recordTypeId,
                Type = accountType,
                OwnerId = ownerId,
                Phone = event.Home_Phone__c,
                Email__c = event.Email__c,
                AccountSource = event.Account_Source__c,
                Language__c = event.Account_Language__c,
                Account_Type__c = event.Account_Type__c,
                Active__c = true,
                BillingStreet = event.Billing_Street__c,
                BillingCity = event.Billing_City__c,
                BillingStateCode = event.Billing_State__c,
                BillingPostalCode = event.Billing_Postal_Code__c,
                BillingCountryCode = event.Billing_Country__c,
                ShippingStreet =  event.Shipping_Street__c,
                ShippingCity =  event.Shipping_City__c,
                ShippingStateCode = event.Shipping_State__c,
                ShippingPostalCode =  event.Shipping_Postal_Code__c,
                ShippingCountryCode =  event.Shipping_Country__c,
                createdById = ownerId
            );
            
             
            accountsToInsert.add(acc);
        }
        System.debug('accountsToInsert ' + accountsToInsert);
        
        // Insert accounts first
        if (!accountsToInsert.isEmpty()) {
            insert accountsToInsert;
            System.debug('accountsToInsert after ' + accountsToInsert);

            // Now create contacts associated with these accounts
            for (Integer i = 0; i < events.size(); i++) {
                User_Registration_Event__e event = events[i];
                Account acc = accountsToInsert[i];
                
                // Create Address
                Address__c address = new Address__c(
                    Account__c = acc.Id,
                    Address__City__s = acc.ShippingCity,
                    Address__CountryCode__s = acc.ShippingCountryCode,
                    Address__PostalCode__s = events[i].Shipping_Postal_Code__c,
                    Address__StateCode__s = acc.ShippingStateCode,
                    Address__Street__s = acc.ShippingStreet,
                    Is_Active__c = true,
                    Nickname__c = addressNickname
                   
                );
                
                addressesToInsert.add(address);
    

                // Create Contact
                Contact con = new Contact(
                    AccountId = acc.Id,
                    FirstName = event.First_Name__c,
                    MiddleName = event.Middle_Name__c,
                    LastName = event.Last_Name__c,
                    Email = event.Email__c,
                    MobilePhone = event.Mobile_Phone__c,
                    HomePhone = event.Home_Phone__c,
                    Birthdate = event.Birth_Date__c,
                    DoNotCall = event.Do_not_call__c,
                    HasOptedOutOfEmail = event.Email_opt_out__c,
                    Primary_Contact__c = true
                );
                
                contactsToInsert.add(con);
            }
            
            System.debug('addressesToInsert ' + addressesToInsert);
            System.debug('contactsToInsert ' + contactsToInsert);

            // Insert contacts
            if (!contactsToInsert.isEmpty()) {
                insert contactsToInsert;
                System.debug('contactsToInsert  aftger ' + contactsToInsert);

            }
          
              // Insert addresses
              if (!addressesToInsert.isEmpty()) {
                System.debug('addressesToInsert before ' + addressesToInsert);

                insert addressesToInsert;
                System.debug('addressesToInsert after ' + addressesToInsert);

                // Prepare accounts for update with primary address
                List<Account> accountsToUpdate = new List<Account>();
                
                for (Integer i = 0; i < accountsToInsert.size(); i++) {
                    Account accToUpdate = new Account(
                        Id = accountsToInsert[i].Id,
                        Primary_Shipping_Address__c = addressesToInsert[i].Id
                    );
                    accountsToUpdate.add(accToUpdate);
                }
                
                // Update accounts with primary address reference
                if (!accountsToUpdate.isEmpty()) {
                    update accountsToUpdate;
                }
            }
        }
    }}