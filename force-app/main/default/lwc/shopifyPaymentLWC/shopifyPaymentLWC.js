import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOrderDetails from '@salesforce/apex/ShopifyPaymentService.getOrderDetails';
import getRedirectUrl from '@salesforce/apex/ShopifyPaymentService.getRedirectUrl';
import { CloseActionScreenEvent } from 'lightning/actions';

// Import custom labels
import integrationError from '@salesforce/label/c.integration_error';
import customerPays from '@salesforce/label/c.customer_pays';
import paymentProcessed from '@salesforce/label/c.payment_processed';

export default class ShopifyPaymentLWC extends LightningElement {
    
    // ----------------------
    // Properties
    // ----------------------

    @api recordId;    // From Flow or button context
    @api paymentUrl;  // Direct payment URL input
     
    isLoading = false;
    processedPaymentUrl = null;
    hasIntegrationError = false;
    
    // Expose custom labels to template
    labels = {
        integrationError,
        customerPays,
        paymentProcessed
    };

    // ----------------------
    // Getters
    // ----------------------

    get showButton() {
        // Show button if payment URL is directly provided
        return this.paymentUrl && !this.hasIntegrationError;
    }
    
    get showMessage() {
        // Show integration error message or loading message
        return this.hasIntegrationError || this.isLoading;
    }


    // ----------------------
    // Lifecycle hooks
    // ----------------------
    
    connectedCallback() {
        console.log('Component loaded');
        console.log('Inputs - recordId:', this.recordId, 'paymentUrl:', this.paymentUrl);
        
        // Prioritize direct payment URL
        if (this.paymentUrl) {
            this.processedPaymentUrl = this.paymentUrl;
            this.handlePayNowClick();
            return;
        }
        
        // Get the actual Order ID to work with
        const orderIdToUse = this.recordId || this.getRecordIdFromUrl();
        
        if (orderIdToUse) {
            this.fetchOrderPaymentUrl(orderIdToUse);
        } else {
            this.showError('No Order ID found');
        }
    }

    // ----------------------
    // Event handlers
    // ----------------------
    
    handlePayNowClick() {
        // Open popup
        this.openPaymentPopup();
        this.dispatchEvent(new CloseActionScreenEvent());

        // Redirect main window only if direct payment URL is provided
        if (this.paymentUrl) {
            this.redirectMainWindow();
        }
    }

    openPaymentPopup() {
        if (!this.processedPaymentUrl) {
            this.showError('Payment URL is not available');
            return;
        }
        
        console.log('Opening payment popup:', this.processedPaymentUrl);
        
        const popup = window.open(
            this.processedPaymentUrl,
            'paymentWindow',
            'width=800,height=600,left=100,top=100,resizable=yes,scrollbars=yes'
        );
        
        if (!popup) {
            this.showError('Popup blocked. Please allow popups and try again.');
        }
    }

    getRecordIdFromUrl() {
        const urlParams = new URLSearchParams(window.location.search);
        return urlParams.get('recordId') || this.extractIdFromUrl();
    }
    
    extractIdFromUrl() {
        const url = window.location.href;
        const idMatch = url.match(/[a-zA-Z0-9]{15,18}/);
        return idMatch ? idMatch[0] : null;
    }
    
    showError(message) {
        console.error('Error:', message);
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error'
        }));
    }
  
    
    // ----------------------
    // Apex Calls
    // ----------------------

    
    async fetchOrderPaymentUrl(orderIdToUse) {
        this.isLoading = true;
        try{
            let orderRecord = await getOrderDetails({recordId : orderIdToUse})
            if (orderRecord && orderRecord.Shopify_payment_url__c) {
                this.processedPaymentUrl = orderRecord.Shopify_payment_url__c;
                this.isLoading = false;
                this.hasIntegrationError = false;
                
                console.log('Payment URL found:', this.processedPaymentUrl);
                
                // Automatically trigger pay now when URL is fetched
                this.handlePayNowClick();
            } else {
                this.isLoading = false;
                this.hasIntegrationError = true;
                this.showError('No payment URL found for this order');
            }
        } catch (error){
            console.error('Error getting order details:', error);
            this.isLoading = false;
            this.hasIntegrationError = true;
            this.showError('Error checking payment status: ' + (error.body?.message || error.message));

        }
    }
    
   
    
    async redirectMainWindow() {
        console.log('Redirecting main window...');
        try{
            const redirectUrl = await getRedirectUrl();
            console.log('Retrieved redirect URL:', redirectUrl);
                if (redirectUrl) {
                    // Small delay to ensure popup opens first
                    setTimeout(() => {
                        console.log('Redirecting to:', redirectUrl);
                        window.location.href = redirectUrl;
                    }, 1000); // 1 second delay
                } else {
                    console.log('No redirect URL found in custom metadata');
                }
        }
        catch (error){
            console.error('Error retrieving redirect URL:', error);

        }
       
    }
    
}