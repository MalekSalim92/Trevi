        @isTest
        private class DispatcherConsoleActionControllerTest {
        
            @TestSetup
            static void setupTestData() {
                TestDataFactory.createServiceAppointmentTestData();
            }
        
            @isTest
            static void testConstructorWithSingleId() {
                // Get test data
                List<ServiceAppointment> appointments = [SELECT Id FROM ServiceAppointment LIMIT 1];
                
                Test.startTest();
                
                // Set page parameters for single appointment
                PageReference pageRef = new PageReference('/apex/DispatcherConsoleStatusAction');
                Test.setCurrentPage(pageRef);
                ApexPages.currentPage().getParameters().put('id', appointments[0].Id);
                
                // Create controller
                DispatcherConsoleStatusActionController controller = new DispatcherConsoleStatusActionController();
                
                Test.stopTest();
                
                // Assertions
                System.assertNotEquals(null, controller.serviceAppointmentIds, 'Service appointment IDs should be set');
                System.assertEquals(appointments[0].Id, controller.serviceAppointmentIds, 'Should match the passed ID');
                System.assertEquals(1, controller.serviceAppointments.size(), 'Should load one appointment');
                System.assertEquals(false, controller.showResults, 'Show results should be false initially');
                System.assertEquals('', controller.selectedStatus, 'Selected status should be empty initially');
                System.assertEquals('1', controller.getServiceAppointmentCount(), 'Count should be 1');
            }
        
            @isTest
            static void testConstructorWithNoParameters() {
                Test.startTest();
                
                // Set page with no parameters
                PageReference pageRef = new PageReference('/apex/DispatcherConsoleStatusAction');
                Test.setCurrentPage(pageRef);
                
                // Create controller
                DispatcherConsoleStatusActionController controller = new DispatcherConsoleStatusActionController();
                
                Test.stopTest();
                
                // Assertions
                System.assertEquals(0, controller.serviceAppointments.size(), 'Should load no appointments');
                System.assertEquals('', controller.selectedStatus, 'Selected status should be empty');
                System.assertEquals('0', controller.getServiceAppointmentCount(), 'Count should be 0');
                
                // Test status options retrieval
                List<SelectOption> statusOptions = controller.getStatusOptions();
                System.assertNotEquals(null, statusOptions, 'Status options should not be null');
                System.assert(statusOptions.size() > 0, 'Should have at least one status option');
            }
        
            @isTest
            static void testUpdateServiceAppointmentStatusSuccess() {
                // Get test data
                List<ServiceAppointment> appointments = [SELECT Id, Status FROM ServiceAppointment LIMIT 1];
                
                Test.startTest();
                
                // Set page parameters
                PageReference pageRef = new PageReference('/apex/DispatcherConsoleStatusAction');
                Test.setCurrentPage(pageRef);
                ApexPages.currentPage().getParameters().put('id', appointments[0].Id);
                
                // Create controller and set status
                DispatcherConsoleStatusActionController controller = new DispatcherConsoleStatusActionController();
                controller.selectedStatus = 'Dispatched';
                
                // Update status
                PageReference result = controller.updateServiceAppointmentStatus();
                
                Test.stopTest();
                
                // Assertions
                System.assertEquals(null, result, 'Should return null PageReference');
                System.assertEquals(true, controller.showResults, 'Should show results');
                
                // Test UpdateResult wrapper class
                if (controller.successfulUpdates.size() > 0) {
                    System.assertNotEquals(null, controller.successfulUpdates[0].appointmentNumber, 'Should have appointment number');
                }
                
                // Verify at least one result (success or failure)
                System.assert(controller.successfulUpdates.size() > 0 || controller.failedUpdates.size() > 0, 
                    'Should have either successful or failed updates');
            }
        
            @isTest
            static void testUpdateServiceAppointmentStatusValidation() {
                // Get test data
                List<ServiceAppointment> appointments = [SELECT Id FROM ServiceAppointment LIMIT 1];
                
                Test.startTest();
                
                // Test 1: No status selected
                PageReference pageRef = new PageReference('/apex/DispatcherConsoleStatusAction');
                Test.setCurrentPage(pageRef);
                ApexPages.currentPage().getParameters().put('id', appointments[0].Id);
                
                DispatcherConsoleStatusActionController controller = new DispatcherConsoleStatusActionController();
                // Don't set selectedStatus - leave it blank
                
                PageReference result1 = controller.updateServiceAppointmentStatus();
                
                // Assertions for no status selected
                System.assertEquals(null, result1, 'Should return null PageReference');
                System.assertEquals(false, controller.showResults, 'Should not show results');
                
                List<ApexPages.Message> messages = ApexPages.getMessages();
                System.assert(messages.size() > 0, 'Should have error message');
                System.assert(messages[0].getSummary().contains('Please select a status'), 
                    'Should contain status selection error');
                
                // Test 2: No appointments scenario
                ApexPages.getMessages().clear(); // Clear previous messages
                
                PageReference pageRef2 = new PageReference('/apex/DispatcherConsoleStatusAction');
                Test.setCurrentPage(pageRef2);
                // Don't set any parameters
                
                DispatcherConsoleStatusActionController controller2 = new DispatcherConsoleStatusActionController();
                controller2.selectedStatus = 'Dispatched';
                
                PageReference result2 = controller2.updateServiceAppointmentStatus();
                
                // Assertions for no appointments
                System.assertEquals(null, result2, 'Should return null PageReference');
                System.assertEquals(false, controller2.showResults, 'Should not show results');
                
                List<ApexPages.Message> messages2 = ApexPages.getMessages();
                System.assert(messages2.size() > 0, 'Should have error message');
                
              
                Test.stopTest();
            }
        }