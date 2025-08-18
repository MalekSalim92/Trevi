public  class HexaSurveyPostSubmissionQueue implements Queueable, Database.AllowsCallouts {
    private List<Object> records;
        
        public HexaSurveyPostSubmissionQueue(List<Object> sondageRecords) {
            this.records = sondageRecords;
        }
        
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
 
        
    // Custom exception class
    public class SageSurveyException extends Exception {}
}
