/**
 * Class Name: HexaSurveyPostSaleQueue
 * Description: Queueable job for asynchronous processing of post-sale and 
 *              post-installation surveys. Calls HexaSurveyService and updates 
 *              Order records with survey URLs.
 *
 * Processing: Handles each survey input individually and bulk updates Orders.
 * Error Handling: Individual record isolation to prevent failures from affecting others.
 *
 * Author: Malek Brachemi
 * Date: 2025-05-10
 */
public class HexaSurveyPostSaleQueue implements Queueable, Database.AllowsCallouts {
    
    // Survey inputs from HexaSurveyPostSaleInvocable
    private List<HexaSurveyPostSaleInvocable.SurveyInputs> inputs;

    /**
     * Constructor to initialize queueable job with survey inputs.
     */
    public HexaSurveyPostSaleQueue(List<HexaSurveyPostSaleInvocable.SurveyInputs> inputs) {
        this.inputs = inputs;
    }

    /**
     * Executes the queueable job: calls survey service and updates Orders.
     */
    public void execute(QueueableContext context) {
        List<Order> ordersToUpdate = new List<Order>();
        System.debug('Processing ' + inputs.size() + ' survey requests');

        for (HexaSurveyPostSaleInvocable.SurveyInputs input : inputs) {
            try {
                // Process individual survey request
                HexaSurveyService surveyService = new HexaSurveyService();
                Order processedOrder = surveyService.processSurvey(input.orderId, input.surveyType, null);
                
                if (processedOrder != null) {
                    ordersToUpdate.add(processedOrder);
                    System.debug('Survey processed for Order ID: ' + input.orderId + ', Type: ' + input.surveyType);
                } else {
                    System.debug('Survey processing returned null for Order ID: ' + input.orderId);
                }
                
            } catch (CalloutException ce) {
                System.debug('Callout error for Order ' + input.orderId + ': ' + ce.getMessage());
            } catch (Exception e) {
                System.debug('Survey error for Order ' + input.orderId + ': ' + e.getMessage());
            }
        }

        // Bulk update successfully processed orders
        if (!ordersToUpdate.isEmpty()) {
            try {
                update ordersToUpdate;
                System.debug('Successfully updated ' + ordersToUpdate.size() + ' orders');
            } catch (Exception e) {
                System.debug('Bulk update error: ' + e.getMessage());
            }
        } else {
            System.debug('No orders to update');
        }
    }
}