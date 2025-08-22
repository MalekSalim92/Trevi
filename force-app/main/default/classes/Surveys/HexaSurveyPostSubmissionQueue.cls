/**
 * HexaSurveyPostSubmissionQueue
 *
 * Queueable class responsible for processing survey submission records retrieved
 * from the Hexa API. Handles bulk processing of survey data in manageable chunks
 * to respect Salesforce governor limits, particularly callout limits during
 * API-intensive operations.
 *
 * Processing Strategy: Batch processing in chunks of 10 records to optimize
 *                     callout usage and prevent governor limit violations
 * Error Handling: Delegates to HexaSurveyUtils.processSondageBatch for individual
 *                record error isolation and processing
 *
 * Author: Malek Brachemi
 * Date: 2025-05-09
 */
public class HexaSurveyPostSubmissionQueue implements Queueable, Database.AllowsCallouts {
    
    // Collection of survey submission records retrieved from Hexa API
    private List<Object> records;
    
    /**
     * Constructor
     *
     * Initializes queueable job with survey submission records for processing
     * @param sondageRecords List of survey submission objects from Hexa API
     */
    public HexaSurveyPostSubmissionQueue(List<Object> sondageRecords) {
        this.records = sondageRecords;
    }
    
    /**
     * execute
     *
     * Main execution method for queueable job processing
     * Processes survey records in batches of 10 to manage callout governor limits
     * and ensure efficient API usage during bulk survey submission handling
     * @param context QueueableContext provided by Salesforce platform
     */
    public void execute(QueueableContext context) {
        // Process records in chunks to manage governor limits
        List<Object> currentBatch = new List<Object>();
        
        for (Object record : records) {
            currentBatch.add(record);
            
            // Process in batches of 10 to manage callout limits
            if (currentBatch.size() >= 10) {
                HexaSurveyUtils.processSondageBatch(currentBatch);
                currentBatch.clear();
            }
        }
        
        // Process any remaining records
        if (!currentBatch.isEmpty()) {
            HexaSurveyUtils.processSondageBatch(currentBatch);
        }
    }

     public class SageSurveyException extends Exception {}
}