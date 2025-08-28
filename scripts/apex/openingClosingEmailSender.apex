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
