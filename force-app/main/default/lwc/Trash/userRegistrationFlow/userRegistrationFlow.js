import { LightningElement, api } from 'lwc';
import publishUserRegistrationEvent from '@salesforce/apex/UserRegistrationController.publishUserRegistrationEvent';
import getURLConfiguration from '@salesforce/apex/UserRegistrationController.getURLConfiguration';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TREVI_LOGO from '@salesforce/resourceUrl/TreviLogo';
import process from '@salesforce/apex/testHttpReq.process';
export default class UserRegistrationFlow extends LightningElement {


    processButton(){
        console.log('clicked')
        process()
        .then(result => {
            console.log('Registration event published successfully');
            console.log('resut ---- ', result );

        })
        .catch(error => {
            console.error('Error publishing registration event:', error);
        });
}


    @api flowApiName = 'Ouverture_Fermeture_New_User_Portail';
    redirectUrl
    isLoading = false

    flowInputVariables = [];
    tabTitle = 'OPENING - CLOSING'
    connectedCallback() {
        // Get the current URL

        const pageUrl = window.location.href;
        console.log('url : ', pageUrl);

        let language = 'en'; // Default to English
        
        if (pageUrl.includes('language=fr')) {
            language = 'fr';
            this.tabTitle = 'OUVERTURE - FERMETURE'
        }
        
        this.setupFavicon();
        console.log('Detected language: ', language);
        
        // Set up the flow input variables
        this.flowInputVariables = [

            {
                name: 'language',
                type: 'String',
                value: language
            }
        ];
    }

    setupFavicon() {
        try {
            const favicon = document.createElement('link');
            favicon.rel = 'shortcut icon';
            favicon.type = 'image/png';
            favicon.href = TREVI_LOGO;
            this.logoUrl = TREVI_LOGO;
            
            const existingFavicon = document.querySelector("link[rel='shortcut icon']");
            if (existingFavicon) {
                existingFavicon.remove();
            }
            document.title = this.tabTitle;
            document.head.appendChild(favicon);
        } catch (error) {
            console.error('Error setting up favicon:', error);
            // Non-critical error, don't need to show to user
        }
    }



    handleFlowStatusChange(event) {
        console.log('Flow status changed:', event.detail.status);
        
        // Log output variables
        if (event.detail.outputVariables) {
            console.log('Flow variables at this step:');
            event.detail.outputVariables.forEach(variable => {
                console.log(`Variable name: ${variable.name}, value:`, variable.value);
            });
        }
        
        // Handle flow completion
        if (event.detail.locationName === 'Thank_You') {
            console.log('Flow completed!');
            
            // Extract account and contact objects from flow variables
            let accountData = null;
            let contactData = null;
            
            event.detail.outputVariables.forEach(variable => {
                if (variable.name === 'newAccount') {
                    accountData = variable.value;
                } else if (variable.name === 'primaryContact') {
                    contactData = variable.value;
                }
            });
            
            console.log('Account data:', accountData);
            console.log('Contact data:', contactData);
            
            if (accountData && contactData) {
                // Map flow data to platform event fields
                const registrationData = {
                    // Account fields
                    accountName: accountData.Name || '',
                    accountSource: accountData.AccountSource || '',
                    accountType: accountData.Account_Type__c || '',
                    accountLanguage: accountData.Language__c || '',
                    languagePreference: contactData.DoNotCall ? 'Email' : 'SMS',

                    // Billing address
                    billingStreet: accountData.BillingStreet || '',
                    billingCity: accountData.BillingCity || '',
                    billingState: accountData.BillingStateCode || '',
                    billingPostalCode: accountData.BillingPostalCode || '',
                    billingCountry: accountData.BillingCountryCode || '',
                    
                    // Shipping address
                    shippingStreet: accountData.ShippingStreet || '',
                    shippingCity: accountData.ShippingCity || '',
                    shippingState: accountData.ShippingStateCode || '',
                    shippingPostalCode: accountData.ShippingPostalCode || '',
                    shippingCountry: accountData.ShippingCountryCode || '',
                    
                    // Contact fields
                    firstName: contactData.FirstName || '',
                    lastName: contactData.LastName || '',
                    email: contactData.Email || accountData.Email__c || '',
                    mobilePhone: accountData.Cellphone__c || '',
                    homePhone: accountData.Phone || '',
                    doNotCall: contactData.DoNotCall || false,
                    emailOptOut: contactData.HasOptedOutOfEmail || false,
                };
                
                console.log('Publishing registration data:', registrationData);
                
                // Publish the platform event
                publishUserRegistrationEvent({ registrationData: JSON.stringify(registrationData) })
                    .then(result => {
                        console.log('Registration event published successfully');
                        this.showToast(
                             'Success'  ,
                             'Account Created',
                            'success'
                        );

                    })
                    .catch(error => {
                        console.error('Error publishing registration event:', error);
                    });
            } else {
                console.error('Missing required account or contact data');
            }
        } else if (event.detail.status === 'ERROR') {
            console.error('Flow error:', event.detail.errorMessage || 'Unknown error');
        }

        if (event.detail.status === 'FINISHED') {   
            console.log('FINISHED');

            getURLConfiguration().then(result => {
                console.log('URL Configuration:', result);

                this.redirectUrl = result.Redirect_URL__c;
                console.log('this.redirectUrl:', this.redirectUrl);
                this.isLoading = true;
                window.location.href = this.redirectUrl;

             

            }).catch(error => {
                console.error('Error getting URL configuration:', error);
            });
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
}