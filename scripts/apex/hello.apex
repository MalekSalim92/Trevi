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

  































//todo >>>>>>>>>>>>>>>>>>>>>>>>>>>>

WORK TYPE GROUP MEMBER

//todo >>>>>>>>>>>>>>>>>>>>>>>>>>>> CR SC Harmony

 List<String> vals = new List<String>();
for (Integer i = 1; i <= 34; i++) {
    vals.add(String.valueOf(i));
}

 List<WorkTypeGroupMember> results = [
    SELECT Id, WorkType.Name, ContractType__c
    FROM WorkTypeGroupMember
    WHERE (ContractType__c IN :vals OR ContractType__c ='CR' OR ContractType__c ='36')
    AND (WorkType.Name = 'Livraison CR' OR WorkType.Name = 'Livraison HA')
];

for (WorkTypeGroupMember rec : results) {
    rec.Form_Name__c = ‘CR_HA’;
}

 update results;
System.debug('Updated ' + results.size() + ' WorkTypeGroupMember records.');


//todo >>>>>>>>>>>>>>>>>>>>>>>>>>>> HT HL SC

 List<WorkTypeGroupMember> results = [
    SELECT Id, WorkType.Name, ContractType__c
    FROM WorkTypeGroupMember
    WHERE (ContractType__c ='41' OR ContractType__c ='37' OR ContractType__c ='40')
    AND (WorkType.Name = 'Livraison HT' OR WorkType.Name = 'Livraison HL')
];
System.debug('results >  ' + results.size() + ' WorkTypeGroupMember records.');


for (WorkTypeGroupMember rec : results) {
    rec.Form_Name__c  = 'HT_HL_SC';
}

 update results;
System.debug('Updated ' + results.size() + ' WorkTypeGroupMember records.');

//todo >>>>>>>>>>>>>>>>>>>>>>>>>>>> SC Industria

 List<WorkTypeGroupMember> results = [
    SELECT Id, WorkType.Name, ContractType__c
    FROM WorkTypeGroupMember
    WHERE ( ContractType__c ='38')
    AND (WorkType.Name = 'Livraison SC')
];
System.debug('result ' + results.size() + ' WorkTypeGroupMember records.');

for (WorkTypeGroupMember rec : results) {
    rec.Form_Name__c = 'SC_Industria';
}

 update results;
System.debug('Updated ' + results.size() + ' WorkTypeGroupMember records.');

//todo >>>>>>>>>>>>>>>>>>>>>>>>>>>> AC ou RB

 List<WorkTypeGroupMember> results = [
    SELECT Id, WorkType.Name, ContractType__c
    FROM WorkTypeGroupMember
    WHERE ( ContractType__c ='39'  OR ContractType__c ='48' )
    AND (WorkType.Name = 'Livraison AC' OR WorkType.Name = 'Livraison Ac B/O')
];
System.debug('result ' + results.size() + ' WorkTypeGroupMember records.');

for (WorkTypeGroupMember rec : results) {
    rec.Form_Name__c = 'AC_RB';
}

 update results;
System.debug('Updated ' + results.size() + ' WorkTypeGroupMember records.');

//todo >>>>>>>>>>>>>>>>>>>>>>>>>>>>   RC  

List<WorkTypeGroupMember> results = [
    SELECT Id, WorkType.Name, ContractType__c
    FROM WorkTypeGroupMember
    WHERE  ContractType__c ='47'  
    AND (WorkType.Name = 'Livraison AC' OR WorkType.Name = 'Livraison Ac B/O')
];
System.debug('result ' + results.size() + ' WorkTypeGroupMember records.');

for (WorkTypeGroupMember rec : results) {
    rec.Form_Name__c = 'RC';
}

 update results;
System.debug('Updated ' + results.size() + ' WorkTypeGroupMember records.');


//todo >>>>>>>>>>>>>>>>>>>>>>>>>>>> AC ou RB prise de mesure

 List<WorkTypeGroupMember> results = [
    SELECT Id, WorkType.Name, ContractType__c
    FROM WorkTypeGroupMember
    WHERE ( ContractType__c ='39' OR ContractType__c ='48' )
    AND (WorkType.Name = 'Prise de mesure HT AC' OR WorkType.Name = 'Prise de mesure RC' OR WorkType.Name = 'Prise de mesure')
];
System.debug('result ' + results.size() + ' WorkTypeGroupMember records.');

for (WorkTypeGroupMember rec : results) {
    rec.Form_Name__c = 'AC_RB_PriseDeMesure';
}

 update results;
System.debug('Updated ' + results + ' WorkTypeGroupMember records.');

//todo >>>>>>>>>>>>>>>>>>>>>>>>>>>>  RC prise de mesure

List<WorkTypeGroupMember> results = [
    SELECT Id, WorkType.Name, ContractType__c
    FROM WorkTypeGroupMember
    WHERE  ContractType__c ='47'
    AND (WorkType.Name = 'Prise de mesure HT AC' OR WorkType.Name = 'Prise de mesure RC' OR WorkType.Name = 'Prise de mesure')
];
System.debug('result ' + results.size() + ' WorkTypeGroupMember records.');

for (WorkTypeGroupMember rec : results) {
    rec.Form_Name__c = 'RC_PriseDeMesure';
}

 update results;
System.debug('Updated ' + results + ' WorkTypeGroupMember records.');

//todo >>>>>>>>>>>>>>>>>>>>>>>>>>>> AC ou RB Autre

List<WorkTypeGroupMember> results = [
    SELECT Id, WorkType.Name, ContractType__c, Form_Name__c
    FROM WorkTypeGroupMember
    WHERE ContractType__c IN ('39','48')
];

List<WorkTypeGroupMember> filteredResults = new List<WorkTypeGroupMember>();

// Filter in Apex based on WorkType.Name
for (WorkTypeGroupMember rec : results) {
    String name = rec.WorkType.Name;

    if (!(name.contains('Cueillette') ||
          name.contains('Livraison') ||
          name.contains('Prise de mesure') ||
          name.contains('Visite d\'accès') ||
          name.contains('Visite de conformité'))) {
        filteredResults.add(rec);
    }
}

System.debug('Filtered size: ' + filteredResults.size() + ' WorkTypeGroupMember records.');

// Update the Form_Name__c field for filtered records
for (WorkTypeGroupMember rec : filteredResults) {
    rec.Form_Name__c = 'AC_RB_Autre';
}

update filteredResults;
System.debug('Updated ' + filteredResults.size() + ' WorkTypeGroupMember records.');
//todo >>>>>>>>>>>>>>>>>>>>>>>>>>>> RC Autre

List<WorkTypeGroupMember> results = [
    SELECT Id, WorkType.Name, ContractType__c, Form_Name__c
    FROM WorkTypeGroupMember
    WHERE ContractType__c = '47'
];

List<WorkTypeGroupMember> filteredResults = new List<WorkTypeGroupMember>();

// Filter in Apex based on WorkType.Name
for (WorkTypeGroupMember rec : results) {
    String name = rec.WorkType.Name;

    if (!(name.contains('Cueillette') ||
          name.contains('Livraison') ||
          name.contains('Prise de mesure') ||
          name.contains('Visite d\'accès') ||
          name.contains('Visite de conformité'))) {
        filteredResults.add(rec);
    }
}

System.debug('Filtered size: ' + filteredResults.size() + ' WorkTypeGroupMember records.');

// Update the Form_Name__c field for filtered records
for (WorkTypeGroupMember rec : filteredResults) {
    rec.Form_Name__c = 'RC_Autre';
}

update filteredResults;
System.debug('Updated ' + filteredResults.size() + ' WorkTypeGroupMember records.');
//todo >>>>>>>>>>>>>>>>>>>>>>>>>>>> Livraison Abri

 List<WorkTypeGroupMember> results = [
    SELECT Id, WorkType.Name, ContractType__c
    FROM WorkTypeGroupMember
    WHERE ( ContractType__c ='45')
    AND (WorkType.Name = 'Livraison AB')
];
System.debug('result ' + results.size() + ' WorkTypeGroupMember records.');

for (WorkTypeGroupMember rec : results) {
    rec.Form_Name__c = 'Livraison_Abris';
}

 update results;
System.debug('Updated ' + results + ' WorkTypeGroupMember records.');

//todo >>>>>>>>>>>>>>>>>>>>>>>>>>>> Installation Abris 

 List<WorkTypeGroupMember> results = [
    SELECT Id, WorkType.Name, ContractType__c
    FROM WorkTypeGroupMember
    WHERE ( ContractType__c ='45')
    AND (WorkType.Name LIKE '%Installation abri auto%')
];
System.debug('result ' + results.size() + ' WorkTypeGroupMember records.');

for (WorkTypeGroupMember rec : results) {
    rec.Form_Name__c = 'Installation_Abri';
}

 update results;
System.debug('Updated ' + results + ' WorkTypeGroupMember records.');

//todo >>>>>>>>>>>>>>>>>>>>>>>>>>>> Installation HT HL 

 List<WorkTypeGroupMember> results = [
    SELECT Id, WorkType.Name, ContractType__c
    FROM WorkTypeGroupMember
    WHERE ( ContractType__c ='40')
    AND (WorkType.Name LIKE '%Installation HL%')
];
System.debug('result ' + results.size() + ' WorkTypeGroupMember records.');

for (WorkTypeGroupMember rec : results) {
    rec.Form_Name__c = 'Installation_HT_HL';
}

 update results;
System.debug('Updated ' + results + ' WorkTypeGroupMember records.');

//todo >>>>>>>>>>>>>>>>>>>>>>>>>>>> Meuble MB

 List<WorkTypeGroupMember> results = [
    SELECT Id, WorkType.Name, ContractType__c
    FROM WorkTypeGroupMember
    WHERE ( ContractType__c ='44')
    AND (
        WorkType.Name = 'Livraison Castel' OR
        WorkType.Name = 'Livraison de Casetta' OR
        WorkType.Name = 'Livraison MB' OR
        WorkType.Name LIKE '%Service de Livraison de meuble% ' OR
        WorkType.Name = 'Livraison Zen' OR
        WorkType.Name = 'Livraison Innovaqua' OR
        WorkType.Name = 'Livraison Innovaqua Cèdre' OR
        WorkType.Name LIKE '%Livraison de meubles VIP%' OR
        WorkType.Name LIKE '%Livraison cuisine extérieure%' )
];
System.debug('result ' + results.size() + ' WorkTypeGroupMember records.');

for (WorkTypeGroupMember rec : results) {
    rec.Form_Name__c = 'Meuble_MB';
}
 update results;
System.debug('Updated ' + results + ' WorkTypeGroupMember records.');

