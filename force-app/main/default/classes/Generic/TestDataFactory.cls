public class TestDataFactory {
    public static Account createTestAccount() {
        return new Account(
            Name = 'Test Account',
            BillingStreet = '123 Street',
            BillingCity = 'Ottawa',
            BillingState = 'Ontario',
            BillingPostalCode = 'K1K1K1',
            BillingCountryCode = 'CA',
            Sage_ID__c = 'SAGE123',
            Email__c = 'test@example.com',
            Cellphone__c = '5555555555',
            Phone = '5551234567'
        );
    }
    public static Contact createTestContact(Id accountId) {
        return new Contact(
            firstName = 'firstName',
            lastName = 'Test Contact',
            AccountId = accountId,
            MobilePhone = '1133443322',
            Email = 'test@example.co'
            );
    }

    
    public static User createTestUser(String firstName,String lastName,Id roleId) {
        return new User(
                Alias = 'tadmin',
                Email = 'hellohella@toto.com',
                EmailEncodingKey = 'UTF-8',
                FirstName = firstName,
                LastName = lastName,
                isActive = true,
                UserRoleId = roleId,
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
                TimeZoneSidKey = 'America/New_York',
                Username = 'hellohella@toto.com'
        );
    }
    public static UserRole createTestUserRole() {
        return new UserRole(
                Name = 'devops'
        );
    }

    public static Product2 createTestProduct(String name, String productCode) {
        return new Product2(
            Name = name,
            Sage_ID__c = productCode,
            IsActive = true
        );
    }

    public static Order createTestOrder(Id accountId, Id pricebookId, String contractNumber) {
        return new Order(
            AccountId = accountId,
            EffectiveDate = Date.today(),
            Status = 'Analysis',
            Pricebook2Id = pricebookId,
            ShippingCountryCode = 'CA', 
            ShippingStateCode = 'ON',
            Order_Number__c = contractNumber
        );
    }
    public static Order createTestOrderForDelivery(Id accountId,Id userId) {
        return new Order(

        AccountId = accountId,
        RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Contract').getRecordTypeId(),
        Status = 'Completed',
        EffectiveDate = Date.today(),
        ShippingCountryCode = 'CA', 
        ShippingStateCode = 'ON',
        Pricebook2Id = Test.getStandardPricebookId(),
        Order_Number__c = 'TEST-ORDER-123',
        Location__c = null,
        Contract_Type__c = '115',
        Pick_Up_Date__c = Date.today().addYears(-1),
        Actual_Delivery_Date__c = Date.today().addYears(-1),
        Installation_Date__c = null,
        Financing_Amount__c = 1000,
        Designer__c = accountId,
        Salesperson_1__c = userId,
        Order_Total__c = 5000,
        Family_Name__c = 'Test Family',
        First_Name__c = 'Test First',
        Email__c = 'test@example.com'
        );
    }
 




    public static PricebookEntry createTestPricebookEntry(Id productId, Id pricebookId) {
        return new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = productId,
            UnitPrice = 100,
            IsActive = true
        );
    }

    public static OrderItem createTestOrderItem(Id orderId, Id productId, Id pricebookEntryId) {
        return new OrderItem(
            OrderId = orderId,
            Product2Id = productId,
            Serial__c = '43',
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pricebookEntryId
        );
    }

    public static Shipment createTestShipment(Id orderId) {
        return new Shipment(
            Order__c = orderId,
            ShipToName = 'test'
        );
    }

    public static ShipmentItem createTestShipmentItems(Id shipmentId, Id productId) {
        return new ShipmentItem(
            ShipmentId = shipmentId,
            Product2Id = productId,
            Quantity = 2,
            Quantity_Shipped__c = 2
        );
    }

    

    public static Case createTestCase() {
        return new Case(
            Subject = 'Test Case'
        );
    }

    public static Contractor_Invoice_Settings__c createServiceAppointmentSettings() {
        return new Contractor_Invoice_Settings__c(
            Invoice_Number__c = '1000'
        );
    }
 
    public static Pricebook2 createTestPricebook() {
        return new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
    }

    public static Resource__c createTestResource(Id pricebookId,Id accountId) {
        return new Resource__c(
            Name = 'Test Resource',
            Tariffication_Method__c = 'Fixed Fees',
            Price_Book__c = pricebookId,
            Account__c = accountId,
            Resource_Level__c = '1'
        );
    }

    public static WorkType createTestWorkType(Id productId) {
        return new WorkType(
            Name = 'Livraison AB',
            EstimatedDuration = 30,
            DurationType = 'Hours',
            Product__c = productId,
            Capacity_Type__c = 'Livraison'

        );
    }

    public static WorkOrder createTestWorkOrder(Id accountId) {
        return new WorkOrder(
            Description = 'Test Work Order',
            AccountId = accountId
        );
    }

    public static OperatingHours createTestOperatingHours() {
        return new OperatingHours(
            Name = 'Test OperatingHours'
        );
    }

    public static ServiceTerritory createTestServiceTerritory(Id OperatingHoursId) {
        return new ServiceTerritory(
            Name = 'Test ServiceTerritory',
            IsActive = true,
            OperatingHoursId = operatingHoursId
        );
    }

    public static WorkOrderLineItem createTestWorkOrderLineItem(Id workOrderId, Id orderId, Id workTypeId, Id productId) {
        return new WorkOrderLineItem(
            Description = 'Test WOLI',
            WorkTypeId = workTypeId,
            OrderId = orderId,
            WorkOrderId = workOrderId,
            Region__c = 'Montreal',
            Product__c = productId,
            ContractType__c =  '45'
           );
    }

    public static ServiceAppointment createTestServiceAppointment(Id woliId,Id serviceTerritoryId,Id serviceResourceId) {
        return new ServiceAppointment(
            ActualStartTime = System.now(),
            ParentRecordId = woliId,
            Description = 'Test Appointment',
            Status = 'Waiting for customer confirmation',
            SchedStartTime = System.now(),
            SchedEndTime = System.now(),
            FSSK__FSK_Assigned_Service_Resource__c = serviceResourceId,
            ServiceTerritoryId = serviceTerritoryId
        );
    }

    
    public static ServiceResource createTestServiceResource(Id accountId, Id userId) {
        return new ServiceResource(
            Name = 'test',
            AccountId = accountId,
            RelatedRecordId = userId,
            isActive = true
        );
    }

    public static AssignedResource createTestAssignedResource(Id serviceResourceId,Id serviceAppointmentId) {
        return new AssignedResource(
            ServiceResourceId = serviceResourceId,
            ServiceAppointmentId = serviceAppointmentId
        );
    }

    public static ServiceTerritoryMember createTestServiceTerritoryMember(Id serviceTerritoryId, Id serviceResourceId,Id operatingHoursId) {
        return new ServiceTerritoryMember(
            ServiceTerritoryId = serviceTerritoryId,
            ServiceResourceId = serviceResourceId,
            OperatingHoursId = operatingHoursId,
            EffectiveStartDate = System.now()
        );
    }


    public static List<Appointment_Resource__c> createTestAppointmentResources(Id serviceAppointmentId, Id resourceId, Integer numberOfResources) {
        List<Appointment_Resource__c> testResources = new List<Appointment_Resource__c>();
        for (Integer i = 0; i < numberOfResources; i++) {
            testResources.add(
                new Appointment_Resource__c(
                    Service_Appointment__c = serviceAppointmentId,
                    Resource__c = resourceId,
                    Fixed_Fee__c = 50.00,
                    Special_Tariffication_Fee__c = 25.00,
                    Bonus__c = 10.00,
                    Contractor_Comment__c = 'Test Comment',
                    Description__c = 'Test Description'
                )
            );
        }
        return testResources;
    }

    public static Capacity__c createTestCapacity(String workTypeName,String region) {
        return new Capacity__c(
            Work_Type__c = workTypeName,
            Region__c = region,
            Week_Start__c = Date.today().toStartOfWeek(),
            Week_End__c = Date.today().toStartOfWeek().addDays(6),
            Year__c	= '2024',
            Week__c = 34,
            Contract_Type__c = '112',
            Capacity_Remaining__c = 10
        );
    }

    public static Ouverture_Fermeture_work_types__c createTestCapacityCustomSettings(String name,Integer priority) {
        return new Ouverture_Fermeture_work_types__c(
            Name = name, 
            Name__c = name,
            Product_Conditions__c = '12345 OR 54321 AND ( 32844 OR 328488)',
            Priority__c = priority
        );
    }




    public static Map<String, Object> createRegistrationData() {
        return new Map<String, Object>{
            // Account fields
            'accountName' => 'Test Account',
            'accountDescription' => 'This is a test account created for registration',
            'accountType' => 'Residential',
            'accountLanguage' => 'F',
            'accountSource' => 'Website',
            
            // Billing address
            'billingStreet' => '123 Billing Street',
            'billingCity' => 'Billing City',
            'billingState' => 'ON',
            'billingPostalCode' => '000 000',
            'billingCountry' => 'CA',
            
            // Shipping address
            'shippingStreet' => '456 Shipping Street',
            'shippingCity' => 'Shipping City',
            'shippingState' => 'QC',
            'shippingPostalCode' => '000 000',
            'shippingCountry' => 'CA',
            
            // Contact fields
            'firstName' => 'Test',
            'lastName' => 'User',
            'birthDate' => Date.today().addYears(-30).format(),
            'email' => 'test.user' + Datetime.now().getTime() + '@example.com',
            'mobilePhone' => '5141234567',
            'homePhone' => '5149876543',
            'doNotCall' => false,
            'emailOptOut' => false
        };
    }

    public static Map<String, Object> createFormData() {
        return new Map<String, Object>{
            'isAddressCorrect' => true,
            'addressComment' => 'Confirmed correct address',
            'isContractCorrect' => true,
            'remplacementSelection' => false,
            'meubleSelection' => true,
            'terrainDroitSelection' => true,
            'hlAccessSelection' => false,
            'demonteeSelection' => true,
            'installationSelection' => true,
            'gazonSelection' => true,
            'hlObstacle' => false,
            'contractComment' => 'All terms accepted',
            'hlGradeurComment' => 'Standard height clearance',
            'deniveleComment' => 'Level terrain',
            'spaAreaComment' => 'Perfect location identified',
            'deliveryLocation' => 'Front driveway',
            'spaAreaLocation' => 'Backyard patio area',
            'meubleComment' => 'No furniture to move',
            'endroitInstallation' => 'Deck area',
            'comminicationPreference' => 'phone',
            'accessMeetsRequirements' => true,
            'wantToBeContacted' => false,
            'phoneNumber' => '514-555-9876',
            'acComment' => 'Air conditioning unit nearby',
            'abComment' => 'Above ground installation preferred'
        };
    }

    public static Postal_Code__c createPostalCode(String name) {
        return new Postal_Code__c(
            Name = name
        );
    }


    public static void createServiceAppointmentTestData() {
        // Create Settings
        Contractor_Invoice_Settings__c settings = createServiceAppointmentSettings();
        insert settings;

        User testUser = createTestUser('test','lmeo',null);
        insert testUser;
    
        // Create Product
        Product2 testProduct = createTestProduct('Test Product','TEST-PROD-001');
        insert testProduct;

        // Create Standard Pricebook Entry
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert standardPricebookEntry;

        // Create Test Pricebook
        Pricebook2 testPricebook = createTestPricebook();
        insert testPricebook;

        // Create Test Pricebook Entry
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert testPricebookEntry;

        Account testAccount = createTestAccount();
        insert testAccount;
        System.debug('testAccount ' + testAccount.Id);

        // Create Resource

        // Create Work Type
        WorkType workType = createTestWorkType(testProduct.Id);
        insert workType;

        // Create Work Order
        WorkOrder workOrder = createTestWorkOrder(testAccount.Id);
        insert workOrder;

        // Create Work Order Line Item
        WorkOrderLineItem woli = createTestWorkOrderLineItem(workOrder.Id, null, workType.Id, testProduct.Id);
        insert woli;
        System.debug('woli ' + woli);

        Resource__c testResource = createTestResource(testPricebook.Id,testAccount.Id);
        insert testResource;
        System.debug('testResource ' + testResource);

        OperatingHours testOperatingHours = createTestOperatingHours();
        insert testOperatingHours;
        System.debug('testOperatingHours ' + testOperatingHours);

        ServiceTerritory testServiceTerritory = createTestServiceTerritory(testOperatingHours.Id);
        insert testServiceTerritory;
        System.debug('testServiceTerritory ' + testServiceTerritory);

        ServiceResource testServiceResource = createTestServiceResource(testAccount.Id,testUser.Id);
        insert testServiceResource;
        System.debug('testServiceResource ' + testServiceResource);
        // Create Service Appointment
        ServiceAppointment testServiceAppointment = createTestServiceAppointment(woli.Id,testServiceTerritory.Id,testServiceResource.Id);
        insert testServiceAppointment;

        ServiceTerritoryMember testServiceTerritoryMember = createTestServiceTerritoryMember(testServiceTerritory.Id,testServiceResource.Id,testOperatingHours.Id);
        insert testServiceTerritoryMember;
         
 
        AssignedResource testAssignedResource = createTestAssignedResource(testServiceResource.Id,testServiceAppointment.Id);
 
        insert testAssignedResource;

        // Create Appointment Resources
        List<Appointment_Resource__c> testResources = createTestAppointmentResources(
            testServiceAppointment.Id, 
            testResource.Id, 
            1
        );
        
        insert testResources;

    }

    // Method to create a complete test data set
    public static void createCompleteTestData() {
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Account testAccount = createTestAccount();
        insert testAccount;
        
        Contact testContact = createTestContact(testAccount.Id);
        insert testContact;

        Product2 testProduct = createTestProduct('Test Product','TEST-PROD-001');
        insert testProduct;
        
        Product2 testProduct2 = createTestProduct('Test Produc 2','TEST-PROD-002');
        insert testProduct2;

        PricebookEntry standardPricebookEntry = createTestPricebookEntry(testProduct.Id, standardPricebookId);
        insert standardPricebookEntry;
        
        Order testOrder = createTestOrder(testAccount.Id, standardPricebookId,'CONTRACT-001');
        insert testOrder;
        
        OrderItem testOrderItem = createTestOrderItem(testOrder.Id, testProduct.Id, standardPricebookEntry.Id);
        insert testOrderItem;

        OrderItem testOrderItem2 = createTestOrderItem(testOrder.Id, testProduct.Id, standardPricebookEntry.Id);
        insert testOrderItem2;

        OrderItem testOrderItem3 = createTestOrderItem(testOrder.Id, testProduct2.Id, standardPricebookEntry.Id);
        insert testOrderItem3;


        WorkType workType = createTestWorkType(testProduct.Id);
        insert workType;

        // Create Work Order
        WorkOrder workOrder = createTestWorkOrder(testAccount.Id);
        insert workOrder;

        WorkOrderLineItem woli = createTestWorkOrderLineItem(workOrder.Id, testOrder.Id, workType.Id, testProduct.Id);
        insert woli;

        Shipment testShipment = createTestShipment(testOrder.Id);
        insert testShipment;
        
        ShipmentItem testShipmentItem = createTestShipmentItems(testShipment.Id,testProduct.Id);
        insert testShipmentItem;

        Order testOrder1 = createTestOrder(testAccount.Id, standardPricebookId,'CONTRACT-001');
        insert testOrder1;

        Order testOrder2 = createTestOrder(testAccount.Id, standardPricebookId,'CONTRACT-00-2');
        insert testOrder2;

        User testUser = createTestUser('test','lmeo',null);
        insert testUser;

        Resource__c testResource = createTestResource(standardPricebookId,testAccount.Id);
        insert testResource;
        System.debug('testResource ' + testResource);

        OperatingHours testOperatingHours = createTestOperatingHours();
        insert testOperatingHours;
        System.debug('testOperatingHours ' + testOperatingHours);

        ServiceTerritory testServiceTerritory = createTestServiceTerritory(testOperatingHours.Id);
        insert testServiceTerritory;
        System.debug('testServiceTerritory ' + testServiceTerritory);

        ServiceResource testServiceResource = createTestServiceResource(testAccount.Id,testUser.Id);
        insert testServiceResource;
        System.debug('testServiceResource ' + testServiceResource);
        // Create Service Appointment
        ServiceAppointment testServiceAppointment = createTestServiceAppointment(woli.Id,testServiceTerritory.Id,testServiceResource.Id);
        insert testServiceAppointment;


        
     }



     public static void createDataForCapacities() {
 

        Product2 testProduct = createTestProduct('Test Product','TEST-PROD-001');
        insert testProduct;
  
        WorkType workType = createTestWorkType(testProduct.Id);
        insert workType;
       
        Capacity__c capacity1 = createTestCapacity('Ouverture CR','Montreal');
        insert capacity1;
 
        Capacity__c capacity2 = createTestCapacity('Fermeture Spa','Quebec');
        insert capacity2;
 
        Capacity__c capacity3 = createTestCapacity('Fermeture HT','Gatineau/Ontario');
        insert capacity3;
 
        Ouverture_Fermeture_work_types__c customSetting1 = createTestCapacityCustomSettings('Livraison AB',1);
        insert customSetting1;
 
        Ouverture_Fermeture_work_types__c customSetting2 = createTestCapacityCustomSettings('Complex Work Type',2);
        insert customSetting2;
 
        Ouverture_Fermeture_work_types__c customSetting3 = createTestCapacityCustomSettings('Alternative Work Type',3);
        insert customSetting3;
 
        
     }





}