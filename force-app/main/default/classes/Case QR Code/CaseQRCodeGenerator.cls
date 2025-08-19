/**
 * Class Name: CaseQRCodeGenerator
 * Description:
 *   Controller class used for generating QR code and barcode strings
 *   for a given Case record. Intended to be used in a Visualforce page
 *   (CaseQRCodePage) that generates a PDF.
 *
 * Author: Malek Brachemi
 * Created Date: 2025-02-04
 * Version: 1.0
 * Notes:
 *   - Retrieves Case record and related Store
 *   - Retrieves QR/Barcode URL templates from Custom Metadata
 *   - Builds final URLs for rendering
 */
public class CaseQRCodeGenerator {
    
    // ----------------------
    // Properties
    // ----------------------
    public String qrCode { get; set; }
    public String barCode { get; set; }
    public Case cas { get; set; }
    public String storeName { get; set; }

    /**
     * Constructor
     * Initializes Case record, store name, and generates QR/Bar code URLs.
     *
     * @param controller ApexPages.StandardController - StandardController with Case context
     */
    public CaseQRCodeGenerator(ApexPages.StandardController controller) {
        // Retrieve Case by Id from controller
        this.cas = [
            SELECT Id, CaseNumber, Choice_of_store__c, Choice_of_store__r.Name 
            FROM Case 
            WHERE Id = :controller.getId() 
            LIMIT 1
        ];
        
        // Store name passed via page parameter (used in PDF)
        this.storeName = ApexPages.currentPage().getParameters().get('storeName');

        // Retrieve QR/Barcode URL templates from Custom Metadata
        QR_code_urls__mdt urlSettings = [
            SELECT Id, qrcode_url__c, barcode_url__c 
            FROM QR_code_urls__mdt 
            WHERE DeveloperName = 'default' 
            LIMIT 1
        ];

 
        // Build final QR code URL (links to Case record in Lightning)
        String qrcodeUrl = urlSettings.qrcode_url__c;
        qrCode = qrcodeUrl 
            + URL.getOrgDomainUrl().toExternalForm() 
            + '/lightning/r/Case/' + cas.Id + '/view';

        // Build final Barcode URL (based on CaseNumber)
        String barcodeUrl = urlSettings.barcode_url__c;
        barCode = barcodeUrl + cas.CaseNumber;

     }
}