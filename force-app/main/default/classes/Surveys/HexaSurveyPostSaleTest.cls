/**
 * HexaSurveyPostSaleTest
 *
 * Test class for HexaSurveyPostSaleInvocable and HexaSurveyPostSaleQueue.
 * Validates survey creation for POST_SALE and POST_INSTALLATION types,
 * error handling, input validation, and queueable job execution.
 *
 * Author: Malek Brachemi
 * Date: 2025-05-09
 */
@isTest
private class HexaSurveyPostSaleTest {

    // Set up HTTP callout mock for all tests
    static {
        Test.setMock(HttpCalloutMock.class, new HexaSurveyMockHttpResponse());
    }

    /**
     * Creates standard test data (Accounts, Users, Orders) for all tests
     */
    @testSetup
    static void setupTestData() {
        TestDataFactory.createCompleteTestData();
    }

    /**
     * Validates POST_SALE survey creation via invocable method and queueable job
     */
    @isTest
    static void testCreateHexaSurveyFromOrder_PostSale() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        List<HexaSurveyPostSaleInvocable.SurveyInputs> inputs = new List<HexaSurveyPostSaleInvocable.SurveyInputs>{
            new HexaSurveyPostSaleInvocable.SurveyInputs(orderId=testOrder.Id, surveyType='POST_SALE')
        };

        Test.startTest();
        HexaSurveyPostSaleInvocable.createHexaSurveyFromOrder(inputs);
        Test.stopTest();

        Order updatedOrder = [SELECT Post_sale_Survey_URL__c FROM Order WHERE Id = :testOrder.Id];
        System.assertNotEquals(null, updatedOrder.Post_sale_Survey_URL__c, 'Post-sale survey URL should be populated');
    }

    /**
     * Validates POST_INSTALLATION survey creation via invocable method
     */
    @isTest
    static void testCreateHexaSurveyFromOrder_PostInstallation() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        List<HexaSurveyPostSaleInvocable.SurveyInputs> inputs = new List<HexaSurveyPostSaleInvocable.SurveyInputs>{
            new HexaSurveyPostSaleInvocable.SurveyInputs(orderId=testOrder.Id, surveyType='POST_INSTALLATION')
        };

        Test.startTest();
        HexaSurveyPostSaleInvocable.createHexaSurveyFromOrder(inputs);
        Test.stopTest();

        Order updatedOrder = [SELECT Installation_Delivery_Survey_URL__c FROM Order WHERE Id = :testOrder.Id];
        System.assertNotEquals(null, updatedOrder.Installation_Delivery_Survey_URL__c, 'Installation survey URL should be populated');
    }

    /**
     * Validates that null input throws SurveyException
     */
    @isTest
    static void testCreateHexaSurveyFromOrder_NullInputs() {
        try {
            HexaSurveyPostSaleInvocable.createHexaSurveyFromOrder(null);
            System.assert(false, 'Should throw SurveyException for null inputs');
        } catch (HexaSurveyPostSaleInvocable.SurveyException e) {
            System.assertEquals(
                'Input parameters are required and survey type must be POST_SALE or POST_INSTALLATION',
                e.getMessage()
            );
        }
    }

    /**
     * Validates that empty input list throws SurveyException
     */
    @isTest
    static void testCreateHexaSurveyFromOrder_EmptyInputs() {
        try {
            HexaSurveyPostSaleInvocable.createHexaSurveyFromOrder(new List<HexaSurveyPostSaleInvocable.SurveyInputs>());
            System.assert(false, 'Should throw SurveyException for empty inputs');
        } catch (HexaSurveyPostSaleInvocable.SurveyException e) {
            System.assertEquals(
                'Input parameters are required and survey type must be POST_SALE or POST_INSTALLATION',
                e.getMessage()
            );
        }
    }

    /**
     * Validates that invalid survey type throws SurveyException
     */
    @isTest
    static void testCreateHexaSurveyFromOrder_InvalidSurveyType() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        List<HexaSurveyPostSaleInvocable.SurveyInputs> inputs = new List<HexaSurveyPostSaleInvocable.SurveyInputs>{
            new HexaSurveyPostSaleInvocable.SurveyInputs(orderId=testOrder.Id, surveyType='INVALID_TYPE')
        };

        try {
            HexaSurveyPostSaleInvocable.createHexaSurveyFromOrder(inputs);
            System.assert(false, 'Should throw SurveyException for invalid survey type');
        } catch (HexaSurveyPostSaleInvocable.SurveyException e) {
            System.assertEquals(
                'Input parameters are required and survey type must be POST_SALE or POST_INSTALLATION',
                e.getMessage()
            );
        }
    }

    /**
     * Validates that queueable job processes survey inputs correctly
     */
    @isTest
    static void testQueueableJobExecution() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        List<HexaSurveyPostSaleInvocable.SurveyInputs> inputs = new List<HexaSurveyPostSaleInvocable.SurveyInputs>{
            new HexaSurveyPostSaleInvocable.SurveyInputs(orderId=testOrder.Id, surveyType='POST_SALE')
        };

        Test.startTest();
        System.enqueueJob(new HexaSurveyPostSaleQueue(inputs));
        Test.stopTest();

        Order updatedOrder = [SELECT Post_sale_Survey_URL__c FROM Order WHERE Id = :testOrder.Id];
        System.assertNotEquals(null, updatedOrder.Post_sale_Survey_URL__c, 'Survey URL should be populated by queueable job');
    }

    /**
     * Validates bulk processing of multiple survey requests
     */
    @isTest
    static void testMultipleSurveyInputs() {
        List<Order> testOrders = [SELECT Id FROM Order];
        List<HexaSurveyPostSaleInvocable.SurveyInputs> inputs = new List<HexaSurveyPostSaleInvocable.SurveyInputs>();

        for (Order ord : testOrders) {
            inputs.add(new HexaSurveyPostSaleInvocable.SurveyInputs(orderId=ord.Id, surveyType='POST_SALE'));
        }

        Test.startTest();
        HexaSurveyPostSaleInvocable.createHexaSurveyFromOrder(inputs);
        Test.stopTest();

        List<Order> updatedOrders = [SELECT Post_sale_Survey_URL__c FROM Order WHERE Post_sale_Survey_URL__c != null];
        System.assertEquals(testOrders.size(), updatedOrders.size(), 'All orders should be processed');
    }
}