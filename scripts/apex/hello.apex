// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

//* Ouverture Fermeture Email Sender
List<orderItem> orderItems = [SELECT Id,Description,Travel_Fees_Description__c,product2Id,orderId,listPrice,UnitPrice,Quantity,Order.AccountId FROM OrderItem LIMIT 2];

OuvertureFermetureContractEmailer.RequestWrapper req = new OuvertureFermetureContractEmailer.RequestWrapper();
System.debug('888 AccountId 888 ' + orderItems[0].Order.AccountId);
req.accountId = orderItems[0].Order.AccountId;   
req.orderId = orderItems[0].OrderId;   
req.contractYear = 1;
req.baseServicePricebookEntries = orderItems;
req.optionPricebookEntries = orderItems;
req.openingServiceDate = Date.today();                  
req.closingServiceDate = Date.today();                  
req.clauses = 'G';


List<OuvertureFermetureContractEmailer.RequestWrapper> listReqs = new List<OuvertureFermetureContractEmailer.RequestWrapper>();
listReqs.add(req);

OuvertureFermetureContractEmailer.sendServiceContractEmail(listReqs); 

//* Order Items Service date change 


List<orderItem> orderItems = [SELECT Id,Service_Date__c FROM OrderItem WHERE OrderId IN ('801Sv00000O2m7dIAB','801Sv00000OXMtiIAH','801Sv00000OXZu3IAH')];
System.debug('orderItems Size' + orderItems.size());
for (orderItem item : orderItems){
    item.Service_Date__c = Date.newInstance(2028, 9, 28);

}
update orderItems;

  