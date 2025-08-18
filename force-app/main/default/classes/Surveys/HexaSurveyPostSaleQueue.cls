
public class HexaSurveyPostSaleQueue implements Queueable, Database.AllowsCallouts {
    private List<HexaSurveyPostSaleInvocable.SurveyInputs> inputs;

    public HexaSurveyPostSaleQueue(List<HexaSurveyPostSaleInvocable.SurveyInputs> inputs) {
        this.inputs = inputs;
    }

    public void execute(QueueableContext context) {
        List<Order> ordersToUpdate = new List<Order>();

        for (HexaSurveyPostSaleInvocable.SurveyInputs input : inputs) {
            try {
                HexaSurveyService surveyService = new HexaSurveyService();
                Order o = surveyService.processSurvey(input.orderId, input.surveyType,null);
                if (o != null) {
                    ordersToUpdate.add(o);
                }
            } catch (Exception e) {
                System.debug('Survey error for Order ' + input.orderId + ': ' + e.getMessage());
            }
        }

        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
    }


}

