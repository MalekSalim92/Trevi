/**
 * Class Name: HexaSurveyPostDeliveryBatch
 * Description: Batch job to send post-delivery surveys exactly one year after 
 *              installation or delivery. Runs daily at 6 PM and generates survey 
 *              URLs via HexaSurveyUtils.
 *
 * Schedule: Daily at 18:00
 * Criteria: Orders with Status = 'Completed' and Installation_Date__c or 
 *           Actual_Delivery_Date__c = today - 1 year
 *
 * Author: Malek Brachemi
 * Created: 2025-05-09
 */
public class HexaSurveyPostDeliveryBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    
    private Integer successCount = 0;
    private Integer errorCount = 0;
    private List<String> errorMessages = new List<String>();
    
    /**
     * Identify eligible orders (1-year-old completed contracts).
     */
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
        
        System.debug('Batch query executing for date: ' + oneYearAgo);
        return Database.getQueryLocator(query);
    }
    
    /**
     * Generate surveys and update orders. Errors on one record 
     * don’t stop others from processing.
     */
    public void execute(Database.BatchableContext BC, List<Order> scope) {
        List<Order> ordersToUpdate = new List<Order>();
        System.debug('Processing ' + scope.size() + ' orders');
        
        for (Order ord : scope) {
            try {
                Order processedOrder = HexaSurveyUtils.createPostDeliverySurvey(ord);
                
                if (processedOrder != null && 
                    processedOrder.Installation_Delivery_Survey_1_Year_URL__c != null) {
                    
                    ordersToUpdate.add(processedOrder);
                    successCount++;
                    System.debug('Survey created for Order: ' + ord.OrderNumber);
                } else {
                    String errorMsg = 'Survey creation failed for Order: ' + 
                                      ord.OrderNumber + ' (ID: ' + ord.Id + ')';
                    errorMessages.add(errorMsg);
                    errorCount++;
                }
                
            } catch (Exception e) {
                String errorMsg = 'Unexpected error for Order: ' + ord.OrderNumber + 
                                  ' (ID: ' + ord.Id + ') - ' + e.getMessage();
                errorMessages.add(errorMsg);
                errorCount++;
            }
        }
        
        if (!ordersToUpdate.isEmpty()) {
            try {
                Database.SaveResult[] saveResults = Database.update(ordersToUpdate, false);
                
                for (Integer i = 0; i < saveResults.size(); i++) {
                    if (!saveResults[i].isSuccess()) {
                        Order failedOrder = ordersToUpdate[i];
                        String errorMsg = 'Update failed for Order: ' + failedOrder.OrderNumber + 
                                          ' (ID: ' + failedOrder.Id + ') - ';
                        
                        for (Database.Error err : saveResults[i].getErrors()) {
                            errorMsg += err.getMessage() + '; ';
                        }
                        
                        errorMessages.add(errorMsg);
                        successCount--; 
                        errorCount++;
                    }
                }
                
                System.debug('Successfully updated ' + ordersToUpdate.size() + ' orders');
                           
            } catch (Exception e) {
                String errorMsg = 'Bulk update failed for ' + ordersToUpdate.size() + 
                                  ' orders - ' + e.getMessage();
                errorMessages.add(errorMsg);
                errorCount += ordersToUpdate.size();
                successCount -= ordersToUpdate.size();
            }
        }
    }
    
    /**
     * Log summary after batch completion.
     */
    public void finish(Database.BatchableContext BC) {
        System.debug('=== HexaSurveyPostDeliveryBatch Completed ===');
        System.debug('Processed: ' + successCount + ' successful, ' + errorCount + ' failed');
        
        if (!errorMessages.isEmpty()) {
            for (String error : errorMessages) {
                System.debug('- ' + error);
            }
        }
        
        if (errorCount > 0) {
            System.debug('WARNING: Errors occurred during survey batch processing');
            // Optional: notify admins via email
        }
    }
}