import { LightningElement, api, track } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import generatePaymentLinkForRecord from '@salesforce/apex/ShopifyIntegration.generatePaymentLinkForRecord';
import processPaymentDirectly from '@salesforce/apex/ShopifyIntegration.processPaymentDirectly';
import getUrlFromRecord from '@salesforce/apex/ShopifyIntegration.getOrderDetails';
import getRedirectUrl from '@salesforce/apex/ShopifyIntegration.getRedirectUrl';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LANG from "@salesforce/i18n/lang";

export default class ShopifyPayNow extends LightningElement {
 
    @api paymentLink;
    
    // Input property for button label
    @api buttonLabel = '';
    @api recordId;
    @api orderId;

    // Input properties for popup window settings
    @api popupWidth = 800;
    @api popupHeight = 600;
    
    payButtonLabel = LANG == 'fr' ? 'Payer Maintenant': 'Pay Now';
    isFromFlow = false;
    isLoading = false;
    generatedPaymentLink;
    
    // Polling configuration
    maxPollingAttempts = 6;  
    pollingInterval = 2000;  
    currentPollingAttempt = 0;
    pollingTimer;
     
    connectedCallback() {
        console.log('===== COMPONENT INITIALIZATION =====');
        console.log('orderId:', this.orderId);
        console.log('recordId:', this.recordId);
        console.log('Full URL:', window.location.href);
        console.log('LANG', LANG);
        console.log('buttonLabel:', this.payButtonLabel);

        // Check if the component is used in Flow context
        this.isFromFlow = this.paymentLink !== null && this.paymentLink !== undefined || this.orderId;
        console.log('Flow context detected:', this.isFromFlow);
        console.log('paymentLink:', this.paymentLink);
        
        // If in flow context with orderId
        if (this.isFromFlow && this.orderId) {
            // If we have an orderId from flow, check if URL already exists
            this.getPaymentUrlFromRecord();
        }
        // If not in Flow context, either get recordId from URL or use provided recordId
        else if (!this.isFromFlow) {
            if (!this.recordId) {
                this.recordId = this.getRecordIdFromUrl();
            }
            console.log('recordId from URL or parameter:', this.recordId);
            
            if (this.recordId) {
                // For direct button invocation, we'll call the direct processing method
                this.processDirectly();
            }
        }
    }

    // Direct processing method for button invocation
    processDirectly() {
        console.log('Processing directly for recordId:', this.recordId);
        this.isLoading = true;
        
        processPaymentDirectly({ 
            recordId: this.recordId,
            paymentMethod: 'Online' 
        })
        .then(result => {
            this.isLoading = false;
            if (result) {
                this.generatedPaymentLink = result;
                console.log('Generated payment link directly:', this.generatedPaymentLink);
                this.openPopupWindow(this.generatedPaymentLink);
                this.closeQuickAction();
            } else {
                console.error('No payment link was generated');
                this.showToast('Error', 'Could not generate payment link', 'error');
            }
        })
        .catch(error => {
            this.isLoading = false;
            let errorMessage = 'Unknown error occurred';
            
            if (error.body && error.body.message) {
                errorMessage = error.body.message;
            } else if (error.message) {
                errorMessage = error.message;
            }
            
            this.showToast('Error', errorMessage, 'error');
            console.error('Error generating payment link:', error);
        });
    }

    // Modified method to get URL with polling capability
    getPaymentUrlFromRecord() {
        console.log('Checking for payment URL, attempt:', this.currentPollingAttempt + 1);
        this.isLoading = true;
        
        getUrlFromRecord({ recordId: this.orderId || this.recordId })
            .then(result => {
                if (result && result.Shopify_payment_url__c) {
                    // Clear any existing polling timer
                    this.stopPolling();
                    
                    this.generatedPaymentLink = result.Shopify_payment_url__c;
                    console.log('Retrieved payment URL:', this.generatedPaymentLink);
                    
                    if (this.autoOpenPaymentWindow) {
                        this.openPopupWindow(this.generatedPaymentLink);
                        this.autoOpenPaymentWindow = false;
                    }
                } else {
                    console.log('No payment URL found yet');
                    // If we haven't reached max attempts, try again
                    if (this.currentPollingAttempt < this.maxPollingAttempts) {
                        this.currentPollingAttempt++;
                        this.pollingTimer = setTimeout(() => {
                            this.getPaymentUrlFromRecord();
                        }, this.pollingInterval);
                    } else {
                        console.log('Max polling attempts reached, URL not found');
                        this.showToast('Info', 'Payment link not ready yet. Please try again in a moment.', 'info');
                        this.isLoading = false;
                    }
                }
            })
            .catch(error => {
                this.stopPolling();
                console.error('Error retrieving payment URL:', error);
                this.isLoading = false;
            });
    }
    
    // Stop polling if in progress
    stopPolling() {
        if (this.pollingTimer) {
            clearTimeout(this.pollingTimer);
            this.pollingTimer = null;
        }
        this.currentPollingAttempt = 0;
        this.isLoading = false;
    }
    
    // Method to close the Quick Action modal
    closeQuickAction() {
        this.stopPolling(); // Make sure to stop polling when closing
        console.log('Attempting to close Quick Action modal');
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    
    // Method to open the popup window when button is clicked
    handleOpenPopup() {
        console.log('handleOpenPopup called');
        this.manualButtonClick = true;
        
        if (this.generatedPaymentLink) {
            // We already have a URL, open it immediately
            this.openPopupWindow(this.generatedPaymentLink);
                    // Close current window after opening payment
        this.getUrlAndRedirect();
        } else {
            // Need to get or generate a URL
            this.isLoading = true;
            
            if (this.isFromFlow && (this.orderId || this.recordId)) {
                // Flow context: First check if URL exists
                this.currentPollingAttempt = 0; // Reset polling counter
                this.autoOpenPaymentWindow = true; // Flag to auto-open when URL is found
                this.getPaymentUrlFromRecord();
            } else if (this.recordId) {
                // Button context: Just process directly
                this.processDirectly();
            } else {
                console.error('No record ID available');
                this.isLoading = false;
            }
        }
    }
    getUrlAndRedirect() {
        getRedirectUrl()
            .then(result => {
                console.log('Retrieved redirect URL:', result);
                if (result) {
                    // Redirect to the URL from custom metadata
                    window.location.href = result;
                } else {
                    // Fallback URL if none found in metadata
                    console.error('No redirect URL found in custom metadata');
                 }
            })
            .catch(error => {
                console.error('Error retrieving redirect URL:', error);
                // Redirect to fallback URL if there's an error
            });
    }


    closeCurrentWindow() {
        // Small delay to ensure popup opens first
        setTimeout(() => {
            try {
                window.close();
            } catch (error) {
                console.log('Cannot close window programmatically, redirecting...');
                // Fallback: redirect to a thank you page
                window.location.href = '/s/thank-you-payment';
            }
        }, 1000); // 1 second delay
    }
    
    // Helper to open popup window
    openPopupWindow(link) {
        console.log('Opening popup with link:', link);
        const popup = window.open(
            link,
            'popupWindow',
            `width=${this.popupWidth},height=${this.popupHeight},left=100,top=100,resizable=yes,scrollbars=yes`
        );
    }
    
    // Extract record ID from URL
    getRecordIdFromUrl() {
        let url = window.location.href;
        let recordId = null;
        
        console.log('URL to extract recordId from:', url);
        
        try {
            // First approach: standard URL parameter extraction
            const urlParams = new URLSearchParams(window.location.search);
            recordId = urlParams.get('recordId');
            
            if (recordId) {
                console.log('Found recordId in URL parameters:', recordId);
                return recordId;
            }
            
            // Second approach: using regex to find recordId parameter
            const recordIdMatch = url.match(/recordId=([^&]+)/);
            if (recordIdMatch && recordIdMatch.length > 1) {
                recordId = recordIdMatch[1];
                console.log('Found recordId using regex:', recordId);
                return recordId;
            }
            
            // Third approach: try to extract from backgroundContext
            const backgroundContextMatch = url.match(/backgroundContext=%2Flightning%2Fr%2FOrder%2F([^%]+)/);
            if (backgroundContextMatch && backgroundContextMatch.length > 1) {
                recordId = backgroundContextMatch[1];
                console.log('Found recordId in backgroundContext:', recordId);
                return recordId;
            }
            
            // Last approach: look for any 15 or 18 character Salesforce ID in the URL
            const idMatch = url.match(/[a-zA-Z0-9]{15,18}/g);
            if (idMatch && idMatch.length > 0) {
                // Use the first match that looks like a record ID
                recordId = idMatch[0];
                console.log('Found potential recordId using generic ID pattern:', recordId);
                return recordId;
            }
            
            console.log('No recordId found in URL');
            return null;
            
        } catch (error) {
            console.error('Error extracting recordId from URL:', error);
            return null;
        }
    }

    showToast(title, message, variant) {
        const toast = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toast);
    }
    
    disconnectedCallback() {
        // Clean up any polling when component is destroyed
        this.stopPolling();
    }
}