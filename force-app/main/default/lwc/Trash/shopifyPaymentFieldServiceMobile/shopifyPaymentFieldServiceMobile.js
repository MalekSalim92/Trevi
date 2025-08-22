import { LightningElement, api, track } from 'lwc';
import makePayment from '@salesforce/apex/ShopifyPaymentService.makePayment';
import getRelatedContacts from '@salesforce/apex/ShopifyPaymentService.getRelatedContacts';
// Import Custom Labels
import payment_Processed from '@salesforce/label/c.payment_Processed';
import customer_pays from '@salesforce/label/c.customer_pays';
import integration_error from '@salesforce/label/c.integration_error';
import Shopify_Next from '@salesforce/label/c.Shopify_Next';
import Shopify_Payment_Status from '@salesforce/label/c.Shopify_Payment_Status';
import Shopify_Select_a_Contact from '@salesforce/label/c.Shopify_Select_a_Contact';
import Shopify_Payment_URL from '@salesforce/label/c.Shopify_Payment_URL';
import Shopify_Unable_Retrieve_Payment from '@salesforce/label/c.Shopify_Unable_Retrieve_Payment';
import Shopify_No_Contacts_Found from '@salesforce/label/c.Shopify_No_Contacts_Found';
import Shopify_Payment_Details from '@salesforce/label/c.Shopify_Payment_Details';
import Shopify_View_Payment_Page from '@salesforce/label/c.Shopify_View_Payment_Page';
import Shopify_Pending from '@salesforce/label/c.Shopify_Pending';
import Shopify_Not_Pending from '@salesforce/label/c.Shopify_Not_Pending';
import Shopify_Payment_Pending_Label from '@salesforce/label/c.Shopify_Payment_Pending_Label';

export default class ShopifyPaymentFieldServiceMobile extends LightningElement {
    @api recordId; // WOLI Id
    
    @track _recordId = null;
    @track contacts = [];
    @track selectedContactId = '';
    @track stepIndex = 0;
    @track error = '';
    @track showSpinner = false;
    @track apiResponseData = null;

    // Expose custom labels to template - only the ones you have
    labels = {
        payment_Processed,
        customer_pays,
        integration_error,
        Shopify_Next,
        Shopify_Payment_Status,
        Shopify_Select_a_Contact,
        Shopify_Payment_URL,
        Shopify_Unable_Retrieve_Payment,
        Shopify_No_Contacts_Found,
        Shopify_Payment_Details,
        Shopify_View_Payment_Page,
        Shopify_Pending,
        Shopify_Not_Pending,
        Shopify_Payment_Pending_Label
        };

    // Computed property to transform contacts into radio group options
    get contactOptions() {
        return this.contacts.map(contact => ({
            label: `${contact.Name} (${contact.Email})`,
            value: contact.Id
        }));
    }

    // Computed property for JSON string display
    get apiResponseString() {
        return this.apiResponseData 
            ? JSON.stringify(this.apiResponseData, null, 2)
            : '';
    }

    // Computed properties for step conditions
    get isStepZero() {
        return this.stepIndex === 0;
    }

    get isStepOne() {
        return this.stepIndex === 1;
    }

    // Button disabled condition
    get isNextButtonDisabled() {
        return this.selectedContactId === '' || this.showSpinner;
    }

    // Setter and getter for recordId
    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.loadRelatedContacts();
        }
    }

    get recordId() {
        return this._recordId;
    }

    // Contact selection change handler
    handleContactChange(event) {
        this.selectedContactId = event.detail.value;
        this.error = ''; // Clear any previous errors
    }

    // Load related contacts
    loadRelatedContacts() {
        this.showSpinner = true;
        console.log(' --- APEX --- ');
        console.log(' --- recordId --- ', this.recordId);
        
        getRelatedContacts({ woliId: this.recordId })
            .then(data => {
                console.log('Contacts : ', JSON.stringify(data));
                this.contacts = data;
                this.showSpinner = false;
                
                // Automatically select if only one contact
                if (this.contacts.length === 1) {
                    this.selectedContactId = this.contacts[0].Id;
                }
            })
            .catch(error => {
                this.error = error.body ? error.body.message : error.message;
                this.showSpinner = false;
            });
    }

    // Handle next step - Call Shopify Payment API
    handleNext() {
        // Validate contact selection
        if (!this.selectedContactId) {
            this.error = 'Please select a contact.';
            return;
        }

        this.showSpinner = true;
        this.error = '';

        console.log('Calling Shopify Payment API...');
        console.log('WOLI ID:', this.recordId);
        console.log('Contact ID:', this.selectedContactId);

        // Call Shopify Payment API
        makePayment({ 
            woliId: this.recordId, 
            contactId: this.selectedContactId 
        })
            .then(data => {
                console.log('Shopify Payment Response:', JSON.stringify(data));
                this.apiResponseData = data;
                this.stepIndex++; // Move to next step
                this.showSpinner = false;
                
                // Log specific response fields
                if (data) {
                    console.log('Payment URL:', data.url);
                    console.log('Payment Pending:', data.has_payment_request_pending);
                    console.log('Refund Status:', data.refund_status);
                }
            })
            .catch(error => {
                console.error('Shopify Payment Error:', error);
                this.error = error.body ? error.body.message : error.message;
                this.showSpinner = false;
            });
    }

    // Optional: Add a method to handle payment URL redirection
    handleOpenPaymentUrl() {
        if (this.apiResponseData && this.apiResponseData.url) {
            window.open(this.apiResponseData.url, '_blank');
        }
    }

    // Optional: Add a method to go back to previous step
    handleBack() {
        if (this.stepIndex > 0) {
            this.stepIndex--;
        }
    }

    // Optional: Add a method to reset the flow
    handleReset() {
        this.stepIndex = 0;
        this.selectedContactId = '';
        this.apiResponseData = null;
        this.error = '';
    }

    // New computed properties for payment status
    get isPaymentPending() {
        return this.apiResponseData && 
               this.apiResponseData.has_payment_request_pending && 
               this.apiResponseData.has_payment_request_pending.toLowerCase() === 'true';
    }

    get paymentPendingLabel() {
        return this.isPaymentPending ? this.labels.Shopify_Pending : this.labels.Shopify_Not_Pending;
    }
    
    get paymentPendingVariant() {
        return this.isPaymentPending ? 'warning' : 'success';
    }

    get refundStatusDisplay() {
        return this.apiResponseData && this.apiResponseData.refund_status 
            ? this.apiResponseData.refund_status 
            : 'No refunds';
    }

    // New method to copy payment URL to clipboard
    async handleCopyPaymentUrl() {
        if (this.apiResponseData && this.apiResponseData.url) {
            try {
                await navigator.clipboard.writeText(this.apiResponseData.url);
                // You could show a toast message here
                console.log('Payment URL copied to clipboard');
            } catch (error) {
                console.error('Failed to copy URL:', error);
            }
        }
    }
}