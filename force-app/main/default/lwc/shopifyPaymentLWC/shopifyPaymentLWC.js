import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOrderDetails from '@salesforce/apex/ShopifyPaymentService.getOrderDetails';
import makePaymentSync from '@salesforce/apex/ShopifyPaymentService.makePaymentSync';
import getRedirectUrl from '@salesforce/apex/ShopifyPaymentService.getRedirectUrl';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ShopifyPaymentLWC extends LightningElement {
    
    @api recordId;    // From Flow or button context
    @api paymentUrl;  // Direct payment URL input from Flow
     
    isLoading = false;

    // ----------------------
    // Lifecycle hooks
    // ----------------------
    
    connectedCallback() {
        console.log('Component loaded - recordId:', this.recordId, 'paymentUrl:', this.paymentUrl);
        
        // Case 1: Payment URL provided - open popup and redirect
        if (this.paymentUrl) {
            console.log('Payment URL provided - opening popup and redirecting');
            this.openPaymentPopup(this.paymentUrl);
            this.redirectMainWindow();
            this.closeAction();
            return;
        }
        
        // Case 2: No payment URL - get Order ID and process
        const orderIdToUse = this.recordId || this.getRecordIdFromUrl();
        
        if (orderIdToUse) {
            this.processOrderPayment(orderIdToUse);
        } else {
            this.showError('No Order ID found');
        }
    }

    // ----------------------
    // Core Logic
    // ----------------------
    
    async processOrderPayment(orderIdToUse) {
        this.isLoading = true;
        
        try {
            // Check if Order already has payment URL
            const orderRecord = await getOrderDetails({ recordId: orderIdToUse });
            
            if (orderRecord && orderRecord.Shopify_payment_url__c) {
                console.log('Existing payment URL found:', orderRecord.Shopify_payment_url__c);
                this.openPaymentPopup(orderRecord.Shopify_payment_url__c);
            } else {
                console.log('No existing URL - making API call');
                // Make API call to get new payment URL
 
                if (result.success && result.paymentUrl) {
                    console.log('New payment URL received:', result.paymentUrl);
                    this.openPaymentPopup(result.paymentUrl);
                } else {
                    this.showError(result.errorMessage || 'Failed to get payment URL');
                }
            }
        } catch (error) {
            console.error('Error processing payment:', error);
            this.showError('Error processing payment: ' + (error.body?.message || error.message));
        } finally {
            this.isLoading = false;
            this.closeAction();
        }
    }

    // ----------------------
    // Helper Methods
    // ----------------------

    openPaymentPopup(url) {
        if (!url) {
            this.showError('Payment URL is not available');
            return;
        }
        
        console.log('Opening payment popup:', url);
        
        const popup = window.open(
            url,
            'paymentWindow',
            'width=800,height=600,left=100,top=100,resizable=yes,scrollbars=yes'
        );
        
        if (!popup) {
            this.showError('Popup blocked. Please allow popups and try again.');
        }
    }

    async redirectMainWindow() {
        console.log('Redirecting main window...');
        try {
            const redirectUrl = await getRedirectUrl();
            console.log('Retrieved redirect URL:', redirectUrl);
            
            if (redirectUrl) {
                // Small delay to ensure popup opens first
                setTimeout(() => {
                    console.log('Redirecting to:', redirectUrl);
                    window.location.href = redirectUrl;
                }, 1000);
            } else {
                console.log('No redirect URL found in custom metadata');
            }
        } catch (error) {
            console.error('Error retrieving redirect URL:', error);
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

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}