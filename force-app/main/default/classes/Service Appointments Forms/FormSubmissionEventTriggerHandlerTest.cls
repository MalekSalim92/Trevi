
@isTest
private class FormSubmissionEventTriggerHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test record that will be the parent for our feed item
        Account testAccount = TestDataFactory.createTestAccount();
        insert testAccount;
    }
    
    @isTest
    static void testHandleAfterInsert_SimpleFormData() {
        // Get the test account
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact d = [SELECT AccountId, FirstName, lastname
        FROM Contact
        WHERE lastname LIKE : 'appl%'];
        
        // Create a simple form data map with different data types
        Map<String, Object> formData = new Map<String, Object>{
            'isAddressCorrect' => true,
            'addressComment' => 'The address is correct',
            'isContractCorrect' => false,
            'contractComment' => 'The contract needs updating',
            'phoneNumber' => '5551234567'
        };
        
        // Convert to JSON string
        String formDataJson = JSON.serialize(formData);
        
        // Create the platform event
        Form_Submission_Event__e event = new Form_Submission_Event__e(
            recordId__c = testAccount.Id,
            formData__c = formDataJson
        );
        
        // Call the method directly for testing
        Test.startTest();
        Database.SaveResult result = EventBus.publish(event);
        System.assert(result.isSuccess(), 'Platform event should publish successfully');
        
        // Process the platform event synchronously in the test
        List<Form_Submission_Event__e> events = new List<Form_Submission_Event__e>{ event };
        FormSubmissionEventTriggerHandler.handleAfterInsert(events);
        Test.stopTest();
        
        // Verify feed item was created
        List<FeedItem> feedItems = [
            SELECT Id, ParentId, Body 
            FROM FeedItem 
            WHERE ParentId = :testAccount.Id
        ];
        
        System.assertEquals(2, feedItems.size(), 'A feed item should have been created');
        
        FeedItem post = feedItems[0];
        System.assertEquals(testAccount.Id, post.ParentId, 'Feed item should be posted to the account');
        
        // Verify feed item content contains our form data values
        System.assert(post.Body.contains('Address Confirmation: Yes'), 'Feed should contain address confirmation');
        System.assert(post.Body.contains('Address Comment: The address is correct'), 'Feed should contain address comment');
        System.assert(post.Body.contains('Contract Confirmation: No'), 'Feed should contain contract confirmation');
        System.assert(post.Body.contains('Contract Comment: The contract needs updating'), 'Feed should contain contract comment');
        System.assert(post.Body.contains('Phone Number: 5551234567'), 'Feed should contain phone number');
    }
    
}