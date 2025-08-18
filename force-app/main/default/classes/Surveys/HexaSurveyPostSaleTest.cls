
@isTest
private class HexaSurveyPostSaleTest {

    static {
        Test.setMock(HttpCalloutMock.class, new HexaSurveyMockHttpResponse());
    }

    @testSetup
    static void setupTestData() {
         TestDataFactory.createCompleteTestData();
    }
    
    @isTest
    static void testCreateHexaSurveyFromOrder_PostSale() {
         Order testOrder = [SELECT Id FROM Order LIMIT 1];
        
         List<HexaSurveyPostSaleInvocable.SurveyInputs> inputs = new List<HexaSurveyPostSaleInvocable.SurveyInputs>();
        HexaSurveyPostSaleInvocable.SurveyInputs input = new HexaSurveyPostSaleInvocable.SurveyInputs();
        input.orderId = testOrder.Id;
        input.surveyType = 'POST_SALE';
        inputs.add(input);
                
         Test.startTest();
        HexaSurveyPostSaleInvocable.createHexaSurveyFromOrder(inputs);
        Test.stopTest();
        
         Order updatedOrder = [SELECT Post_sale_Survey_URL__c FROM Order WHERE Id = :testOrder.Id];
        System.assertNotEquals(null, updatedOrder.Post_sale_Survey_URL__c, 'Survey URL should be updated');
    }
    
    @isTest
    static void testCreateHexaSurveyFromOrder_PostInstallation() {
        // Arrange
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        
         List<HexaSurveyPostSaleInvocable.SurveyInputs> inputs = new List<HexaSurveyPostSaleInvocable.SurveyInputs>();
        HexaSurveyPostSaleInvocable.SurveyInputs input = new HexaSurveyPostSaleInvocable.SurveyInputs();
        input.orderId = testOrder.Id;
        input.surveyType = 'POST_INSTALLATION';
        inputs.add(input);
        
        
        // Act
        Test.startTest();
        HexaSurveyPostSaleInvocable.createHexaSurveyFromOrder(inputs);
        Test.stopTest();
        
         Order updatedOrder = [SELECT Installation_Delivery_Survey_URL__c FROM Order WHERE Id = :testOrder.Id];
        System.assertNotEquals(null, updatedOrder.Installation_Delivery_Survey_URL__c, 'Survey URL should be updated');
    }
    
    @isTest
    static void testCreateHexaSurveyFromOrder_NullInputs() {
         List<HexaSurveyPostSaleInvocable.SurveyInputs> inputs = null;
        
         try {
            HexaSurveyPostSaleInvocable.createHexaSurveyFromOrder(inputs);
            System.assert(false, 'Should have thrown an exception');
        } catch (HexaSurveyPostSaleInvocable.SurveyException e) {
            System.assertEquals('Input parameters are required', e.getMessage(), 'Incorrect error message');
        }
    }
    
     
}