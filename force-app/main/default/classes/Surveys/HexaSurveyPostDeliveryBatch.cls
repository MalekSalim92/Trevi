public class HexaSurveyPostDeliveryBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext BC) {
        Date oneYearAgo = Date.today().addYears(-1);
        
        String query = 'SELECT Id, OrderNumber, RecordType.DeveloperName, Status, ' +
               'Order_Number__c, Location__c, Location__r.Sage_ID__c, ' +
               'Contract_Type__c, Pick_Up_Date__c, Actual_Delivery_Date__c, ' +
               'Installation_Date__c, Financing_Amount__c, Designer__c, ' +
               'Salesperson_1__c, CreatedDate, Order_Total__c, ' +
               'Account_Sage_ID__c, Family_Name__c, First_Name__c, Email__c, ' +
               'AccountId, Account.Cellphone__c, Account.Language__c, Account.Phone ' +
               'FROM Order ' +
               'WHERE RecordType.DeveloperName = \'Contract\' ' +
               'AND Status = \'Completed\' ' +
               'AND (' +
               '(Installation_Date__c != NULL AND Installation_Date__c = :oneYearAgo) ' +
               'OR (Actual_Delivery_Date__c != NULL AND Actual_Delivery_Date__c = :oneYearAgo)' +
               ')';
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Order> scope) {
        List<Order> ordersToUpdate = new List<Order>();
    
        for (Order ord : scope) {
            Order  o = HexaSurveyUtils.createPostDeliverySurvey(ord);
            if (o != null && o.Installation_Delivery_Survey_1_Year_URL__c != null) {
                ordersToUpdate.add(o);
            }
        }
    
        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
    }

    
    public void finish(Database.BatchableContext BC) {
        System.debug('Delivery Survey Batch Completed');
 
    }

}
