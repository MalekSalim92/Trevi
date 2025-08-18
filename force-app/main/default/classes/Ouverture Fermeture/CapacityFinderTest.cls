@isTest
private class CapacityFinderTest {
    
    @testSetup
    static void setupTestData() {


        TestDataFactory.createDataForCapacities();
    }
    
    @isTest
    static void testGetCapacitiesSuccess() {
        // Mock the getWorkType method using our custom mocking approach
        TestWorkTypeMock mockWorkType = new TestWorkTypeMock();
        mockWorkType.Name = 'Livraison AB';
         
        Test.startTest();
        
        CapacityFinder.Inputs request = new CapacityFinder.Inputs();
        request.contractType = '110';
        request.workType = new List<String>{'12345','54321','32844','328488'};  // Sage ID that would match with our custom setting
        request.region = 'Montréal';
        request.weekEnd = Date.today();
        
        // Mock the response from getWorkType
        CapacityFinderTest.setMockWorkType(mockWorkType);
        
        List<CapacityFinder.OutputResults> results = CapacityFinder.GetCapacities(new List<CapacityFinder.Inputs>{request});
        
        Test.stopTest();
        System.debug('testGetCapacitiesSuccess()');

 
        // Assert results
         System.assertEquals(1, results.size(), 'Should return one result');
         System.assertEquals('Livraison AB', results[0].WorkType.Name, 'Should return the correct work type');
     }
    
    @isTest
    static void testGetCapacitiesNoAvailability() {
        // Mock the getWorkType method
        TestWorkTypeMock mockWorkType = new TestWorkTypeMock();
        mockWorkType.Name = 'Livraison AB';
         
        Test.startTest();
        
        CapacityFinder.Inputs request = new CapacityFinder.Inputs();
        request.contractType = '110';
        request.workType = new List<String>{'12345','54321','32844','328488'};  // Sage ID that would match with our custom setting
        request.region = 'Québec';
        request.weekEnd = Date.today().addYears(1);  // Future date with no capacity
        
        CapacityFinderTest.setMockWorkType(mockWorkType);
        
        List<CapacityFinder.OutputResults> results = CapacityFinder.GetCapacities(new List<CapacityFinder.Inputs>{request});
        System.debug('testGetCapacitiesNoAvailability()');

        Test.stopTest();

        
        // Assert results
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].result, 'Should not find available capacity');
        System.assertEquals('Livraison AB', results[0].WorkType.Name, 'Should return the correct work type');
        System.assertEquals(null, results[0].availCapacities, 'Should not return any capacities');
    }
    
    @isTest
    static void testSharedCapacity() {
        // Mock the getWorkType method
        TestWorkTypeMock mockWorkType = new TestWorkTypeMock();
        mockWorkType.Name = 'Livraison AB';
         
        // Create a mock for the Shared_Capacity__mdt
        Test.startTest();
        
        // Create test data for shared capacity scenario
        CapacityFinder.Inputs request = new CapacityFinder.Inputs();
        request.contractType = '110';
        request.workType = new List<String>{'12345','54321','32844','328488'};  // Sage ID that would match with our custom setting
        request.region = 'Ontario';
        request.weekEnd = Date.today();
        
        CapacityFinderTest.setMockWorkType(mockWorkType);
        
         List<CapacityFinder.OutputResults> results = CapacityFinder.GetCapacities(new List<CapacityFinder.Inputs>{request});
        
        Test.stopTest();
        
     }
    
    @isTest
    static void testGetRegionMapping() {
        System.debug('testGetRegionMapping()');


        // Test region mapping method
        System.assertEquals('Montreal', CapacityFinder.getRegion('montréal'), 'Should map to Montreal');
        System.assertEquals('Gatineau/Ontario', CapacityFinder.getRegion('ontario'), 'Should map to Gatineau/Ontario');
     }
    
    @isTest
    static void testEvaluateCondition() {
         Test.startTest();
        
        // Create a set of product Sage IDs for testing
        Set<String> productSet1 = new Set<String>{'12345'};  // Matches first condition
        Set<String> productSet2 = new Set<String>{'67890'};  // Matches second condition
        Set<String> productSet3 = new Set<String>{'12345', '67890'};  // Matches complex AND condition
        Set<String> productSet4 = new Set<String>{'12345', '54321'};  // Matches OR condition
         
        Test.stopTest();
    }
    
    // Helper class to mock WorkType for testing
    public class TestWorkTypeMock {
        public String Name;
     }
    
    // Static variables and methods to handle mocking
    private static TestWorkTypeMock mockWorkType;
    
    public static void setMockWorkType(TestWorkTypeMock mock) {
        mockWorkType = mock;
    }
     public static WorkType getWorkType(Set<String> productSageIdSet) {
        // This method would need to be called by the main class through dependency injection
        if (mockWorkType != null) {
            WorkType wt = new WorkType();
            wt.Name = mockWorkType.Name;
             return wt;
        }
        return null;
    }
}