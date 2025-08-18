
    @isTest
    public class AppointmentResourceDuplicationTest {
        
        static {
            Test.setMock(HttpCalloutMock.class, new HexaSurveyMockHttpResponse());
        }

        @testSetup
        static void setupTestData() {
            TestDataFactory.createServiceAppointmentTestData();
        }
        
        @isTest
        static void testCheckDuplicationsWithOverlap() {
            // Get test data
            Resource__c testResource = [SELECT Id FROM Resource__c LIMIT 1];
            ServiceAppointment sa1 = [SELECT Id FROM ServiceAppointment LIMIT 1];
            
            // Create second WOLI and ServiceAppointment
            WorkOrder workOrder = [SELECT Id FROM WorkOrder LIMIT 1];
            WorkType workType = [SELECT Id FROM WorkType LIMIT 1];
            Product2 product = [SELECT Id FROM Product2 LIMIT 1];
            
            // Create second WOLI
            WorkOrderLineItem woli2 = TestDataFactory.createTestWorkOrderLineItem(
                workOrder.Id, null, workType.Id, product.Id
            );
            insert woli2;
            
            // Create second service appointment with new WOLI
            ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
            ServiceResource serviceResource = [SELECT Id FROM ServiceResource LIMIT 1];
            
            ServiceAppointment sa2 = TestDataFactory.createTestServiceAppointment(
                woli2.Id, territory.Id, serviceResource.Id
            );
            insert sa2;
            
            
            // Create appointment resources with overlapping products
            Appointment_Resource__c resource1 = new Appointment_Resource__c(
                Service_Appointment__c = sa1.Id,
                Resource__c = testResource.Id,
                All_Products__c = '12345,Test Product'
            );
            
            Appointment_Resource__c resource2 = new Appointment_Resource__c(
                Service_Appointment__c = sa2.Id,
                Resource__c = testResource.Id,
                All_Products__c = '12345,99999' 
            );
            
            insert new List<Appointment_Resource__c>{resource1, resource2};
            
            AppointmentResourceDuplicationChecker.RequestWrapper request = new AppointmentResourceDuplicationChecker.RequestWrapper();
            request.AppointmentResource = new List<Appointment_Resource__c>{resource1};
            
            Test.startTest();
            List<List<Appointment_Resource__c>> result = AppointmentResourceDuplicationChecker.checkDuplications(
                new List<AppointmentResourceDuplicationChecker.RequestWrapper>{request}
            );
            Test.stopTest();
            
            // Assertions
            System.assertNotEquals(null, result);
            System.assertEquals(1, result.size());
        }
        
        @isTest
        static void testCheckDuplicationsNoOverlap() {
            // Get test data
            Account testAccount = [SELECT Id FROM Account LIMIT 1];
            Resource__c testResource = [SELECT Id FROM Resource__c LIMIT 1];
            ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
            
            // Create order
            Order testOrder = TestDataFactory.createTestOrder(testAccount.Id, Test.getStandardPricebookId(), 'TEST-CONTRACT-002');
            insert testOrder;
            
            // Create appointment resource with no duplicates
            Appointment_Resource__c resource = new Appointment_Resource__c(
                Service_Appointment__c = sa.Id,
                Resource__c = testResource.Id,
                All_Products__c = '99999',
                Order__c = testOrder.Id
                
            );
            insert resource;
            
            // Prepare request
            AppointmentResourceDuplicationChecker.RequestWrapper request = new AppointmentResourceDuplicationChecker.RequestWrapper();
            request.AppointmentResource = new List<Appointment_Resource__c>{resource};
            
            Test.startTest();
            List<List<Appointment_Resource__c>> result = AppointmentResourceDuplicationChecker.checkDuplications(
                new List<AppointmentResourceDuplicationChecker.RequestWrapper>{request}
            );
            Test.stopTest();
            
            // Assertions
            System.assertEquals('Green', result[0][0].Description__c);
            System.assertEquals('', result[0][0].TECH_Duplicates__c);
        }
    }