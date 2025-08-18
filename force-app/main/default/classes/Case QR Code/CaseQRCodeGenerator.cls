public class CaseQRCodeGenerator {
    public String qrCode { get; set; }
    public String barCode { get; set; }
    public Case cas { get; set; }
    public String storeName { get; set; } // Add this

    public CaseQRCodeGenerator(ApexPages.StandardController controller) {
        this.cas = [SELECT Id, CaseNumber,Choice_of_store__c,Choice_of_store__r.Name 
                          FROM Case 
                          WHERE Id = :controller.getId() 
                          LIMIT 1];
    this.storeName = ApexPages.currentPage().getParameters().get('storeName');

    QR_code_urls__mdt urlSettings = [SELECT Id,qrcode_url__c,barcode_url__c FROM QR_code_urls__mdt WHERE DeveloperName ='default' LIMIT 1];

        System.debug('this.cas ' + this.cas);
        String qrcodeUrl = urlSettings.qrcode_url__c;
        String barcodeUrl = urlSettings.barcode_url__c;
        qrCode =  qrcodeUrl + URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/Case/' + cas.Id + '/view';
        barCode =  barcodeUrl + cas.CaseNumber;
        System.debug(barCode);
    }
}