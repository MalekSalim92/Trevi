public class OuvertureFermetureContractEmailer {
    @InvocableMethod(label='Send Service Contract Email' description='Send Service Contract Email with Products and Clauses')
    public static void sendServiceContractEmail(List<RequestWrapper> requestList) {
        if (requestList.isEmpty()) {
            return;
        }
        
        RequestWrapper request = requestList[0];
        
        // Serialize the request data to pass to future method
        String requestJson = JSON.serialize(request);
        
        // Call the future method
        sendServiceContractEmailAsync(requestJson);
    }
    
    @future
    public static void sendServiceContractEmailAsync(String requestJson) {
        try {
            // Deserialize the request data
            RequestWrapper request = (RequestWrapper) JSON.deserialize(requestJson, RequestWrapper.class);
            
            System.debug('baseServicePricebookEntries: ' + request.baseServicePricebookEntries);
            System.debug('baseServiceOrderItems: ' + request.baseServiceOrderItems);
            System.debug('optionPricebookEntries ' + request.optionPricebookEntries);

            List<String> productIds = new List<String>();
            for (OrderItem item : request.baseServiceOrderItems) {
                productIds.add(item.Product2Id);
            }
            
            List<Product2> products = [SELECT Id, Work_Type__r.Name FROM Product2 WHERE Id IN: productIds];
            
            List<String> workTypeNames = new List<String>();
            for (Product2 product : products) {
                if (product.Work_Type__r?.Name != null) {
                    workTypeNames.add(product.Work_Type__r.Name);
                }
            }
            
            String worktypeNameConcatenation = String.join(workTypeNames, ' / ');
            
            // Get account  
            Account acc = [SELECT Id, Name, Email__c FROM Account WHERE Id = :request.accountId];
            Order ord = [SELECT Id,Order_Number__c  FROM Order WHERE Id = :request.orderId];
            // Get the email template by name
			String emailTemplate = UserInfo.getLanguage() == 'fr' ? 'Ouverture_Fermeture_Contract_de_service_Fr' : 'Ouverture_Fermeture_Contract_de_service_En';

            // Get the email template by name
            EmailTemplate template = [SELECT Id, Subject, HtmlValue, Body 
                                     FROM EmailTemplate 
                                     WHERE DeveloperName = :emailTemplate LIMIT 1];
            
            // Get the HTML content of the template
            String htmlBody = template.HtmlValue;
            String orderNumber = ord.Order_Number__c ?? '';
            
            // Replace basic placeholders
            htmlBody = htmlBody.replace('{ACCOUNT_NAME}', acc.Name);
            htmlBody = htmlBody.replace('{ACCOUNT_SAGEID}', orderNumber);
            htmlBody = htmlBody.replace('{BASE_SERVICE_DESCRIPTION}', worktypeNameConcatenation);
            
            // Check if discount applies
            Boolean hasDiscount = request.contractYear == 2 || request.contractYear == 3;
            String discountText = (request.contractYear == 2) ? '5%' : '10%';
            
            // Add discount header column if needed
            String discountHeader = hasDiscount ? 
           '<tr style="border-bottom: 1px solid #ddd; background-color: #f2f2f2;">' +
            '<th style="width: 50%;padding: 8px; text-align: left; border: 1px solid #ddd;"><strong>Description</strong></th>' +
            '<th style="width: 15%;padding: 8px; text-align: center; border: 1px solid #ddd;"><strong>Qté</strong></th>'+
            '<th style="width: 15%;padding: 8px; text-align: right; border: 1px solid #ddd;"><strong>Prix régulier</strong></th>'+
            '<th style="width: 20%;padding: 8px; text-align: right; border: 1px solid #ddd;"><strong>Prix après rabais (' + discountText + ')</strong></th>'+
            '</tr>' 
      
              : 
              '<tr style="border-bottom: 1px solid #ddd; background-color: #f2f2f2;">' +
              '<th style="width: 60%;padding: 8px; text-align: left; border: 1px solid #ddd;"><strong>Description</strong></th>' +
              '<th style="width: 15%;padding: 8px; text-align: center; border: 1px solid #ddd;"><strong>Qté</strong></th>'+
              '<th style="width: 15%;padding: 8px; text-align: right; border: 1px solid #ddd;"><strong>Prix</strong></th>'+
              '</tr>' ;
            htmlBody = htmlBody.replace('{HEADER}', discountHeader);
            
            // Build the base products table rows
            String baseProductsHtml = '';
            Decimal baseSubtotal = 0;
            Decimal baseDiscountedSubtotal = 0;
            
            for (orderItem pbe : request.baseServicePricebookEntries) {
                Decimal quantity = pbe.Quantity != null ? pbe.Quantity : 1;
                Decimal listPrice = pbe.ListPrice;
                Decimal unitPrice = pbe.UnitPrice != null ? pbe.UnitPrice : listPrice; // Get UnitPrice from the PBE
                
                baseSubtotal += listPrice * quantity;
                baseDiscountedSubtotal += unitPrice * quantity;
                
                baseProductsHtml += '<tr style="border-bottom: 1px solid #ddd;">';
                baseProductsHtml += '<td style="width: 60%;padding: 8px; text-align: left; border: 1px solid #ddd;">' + pbe.Travel_Fees_Description__c + '</td>';
                baseProductsHtml += '<td style="width: 15%;padding: 8px; text-align: center; border: 1px solid #ddd;">' + quantity + '</td>';
                baseProductsHtml += '<td style="width: 15%;padding: 8px; text-align: right; border: 1px solid #ddd;">' + formatCurrency(listPrice) + ' $</td>';
                
                if (hasDiscount) {
                    baseProductsHtml += '<td style="width: 15%;padding: 8px; text-align: right; border: 1px solid #ddd;">' + formatCurrency(unitPrice) + ' $</td>';
                }
                
                baseProductsHtml += '</tr>';
            }
            
            htmlBody = htmlBody.replace('{BASE_SERVICE_PRODUCTS}', baseProductsHtml);
            
            // Build the options table rows
            String optionsHtml = '';
            Decimal optionsSubtotal = 0;
            Decimal optionsDiscountedSubtotal = 0;

            for (orderItem pbe : request.optionPricebookEntries) {
                if (String.isNotBlank(pbe.Description) && pbe.ListPrice > 0 ) {
                    Decimal quantity = pbe.Quantity != null ? pbe.Quantity : 1;
                    Decimal listPrice = pbe.ListPrice;
                    Decimal unitPrice = pbe.UnitPrice != null ? pbe.UnitPrice : listPrice; // Get UnitPrice from the PBE
                    
                    optionsSubtotal += listPrice * quantity;
                    optionsDiscountedSubtotal += unitPrice * quantity;
                    
                    optionsHtml += '<tr style="border-bottom: 1px solid #ddd;">';
                    optionsHtml += '<td style="padding: 8px; text-align: left; border: 1px solid #ddd;">' + pbe.Description + '</td>';
                    optionsHtml += '<td style="padding: 8px; text-align: center; border: 1px solid #ddd;">' + quantity + '</td>';
                    optionsHtml += '<td style="padding: 8px; text-align: right; border: 1px solid #ddd;">' + formatCurrency(listPrice) + ' $</td>';
                    
                    if (hasDiscount) {
                        optionsHtml += '<td style="padding: 8px; text-align: right; border: 1px solid #ddd;">' + formatCurrency(unitPrice) + ' $</td>';
                    }
                    
                    optionsHtml += '</tr>';
                }
            }
            htmlBody = htmlBody.replace('{OPTION_HEADER}', discountHeader);
            htmlBody = htmlBody.replace('{OPTION_PRODUCTS}', optionsHtml);
            
            // Add discount message if applicable
            String discountHtml = '';
            if (hasDiscount) {
                discountHtml = '<div style="margin: 15px 0; padding: 10px; text-align: center; background-color: #f9f9f9; border: 1px solid #ddd;">' +
                               '<em>Rabais de ' + discountText + ' pour contrat multi-années ' + request.contractYear + ' ans (appliqué sur chaque ligne)</em>' +
                               '</div>';
            }
            htmlBody = htmlBody.replace('{DISCOUNT_MESSAGE}', discountHtml);
            
            // Calculate totals - use discounted subtotal if discount applies
            Decimal subtotal = hasDiscount ? 
                baseDiscountedSubtotal + optionsDiscountedSubtotal : 
                baseSubtotal + optionsSubtotal;
            
            Decimal gst = subtotal * 0.05; // 5% GST
            Decimal qst = subtotal * 0.09975; // 9.975% QST
            Decimal grandTotal = subtotal + gst + qst;
            
            // Replace summary values
            htmlBody = htmlBody.replace('{SUBTOTAL}', formatCurrency(subtotal));
            htmlBody = htmlBody.replace('{GST}', formatCurrency(gst));
            htmlBody = htmlBody.replace('{QST}', formatCurrency(qst));
            htmlBody = htmlBody.replace('{GRAND_TOTAL}', formatCurrency(grandTotal));
            
            // Build date section HTML
            String datesHtml = '';
            Boolean hasOpeningDate = request.openingServiceDate != null;
            Boolean hasClosingDate = request.closingServiceDate != null;
            
            if (hasOpeningDate && !hasClosingDate) {
                datesHtml = '<p>Dans la semaine du ' + formatDate(request.openingServiceDate) + '</p>';
            } else if (!hasOpeningDate && hasClosingDate) {
                datesHtml = '<p>Dans la semaine du ' + formatDate(request.closingServiceDate) + '</p>';
            } else if (hasOpeningDate && hasClosingDate) {
                datesHtml = '<p>Dans la semaine du</p>' +
                            '<p>Pour ouverture: ' + formatDate(request.openingServiceDate) + '</p>' +
                            '<p>Pour fermeture: ' + formatDate(request.closingServiceDate) + '</p>';
            }
            htmlBody = htmlBody.replace('{DATE_SECTION}', datesHtml);
            
            // Add clauses
            htmlBody = htmlBody.replace('{CLAUSES}', request.clauses);
            
            // Create and send the email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject(template.Subject);
            mail.setToAddresses(new String[] { acc.Email__c });
            mail.setHtmlBody(htmlBody);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            System.debug('Email sent successfully to ' + acc.Email__c);
            
        } catch (Exception e) {
            System.debug('Error processing email in future method: ' + e.getMessage());
        }
    }
    
    // Helper method to format currency values
    private static String formatCurrency(Decimal value) {
        return String.valueOf(value.setScale(2));
    }
    
    // Helper method to format dates
    private static String formatDate(Date inputDate) {
        if (inputDate == null) return '';
        
        Datetime dt = Datetime.newInstance(inputDate.year(), inputDate.month(), inputDate.day());
        return dt.format('d MMMM yyyy', 'fr_FR');
    }
    
    // Wrapper class remains the same
    public class RequestWrapper {
        @InvocableVariable(label='Account Id')
        public Id accountId;

        @InvocableVariable(label='Contract Year')
        public Integer contractYear;

        @InvocableVariable(label='Base Service Pricebook Entries')
        public List<orderItem> baseServicePricebookEntries;

        @InvocableVariable(label='Base Service Order Items')
        public List<orderItem> baseServiceOrderItems;

        @InvocableVariable(label='Option Pricebook Entries')
        public List<orderItem> optionPricebookEntries;
        
        @InvocableVariable(label='Opening Service Date')
        public Date openingServiceDate;
    
        @InvocableVariable(label='Closing Service Date')
        public Date closingServiceDate;

        @InvocableVariable(label='Clauses')
        public String clauses;

        @InvocableVariable(label='Order Id')
        public String orderId;
    }
}