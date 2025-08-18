import { LightningElement, wire } from 'lwc';
 import getRedirectUrl from '@salesforce/apex/ShopifyIntegration.getRedirectUrl';

export default class FlowRedirectingComponent extends LightningElement {
    isLoading = true;
    
    connectedCallback() {
        // Get the redirect URL from Custom Metadata
        this.getUrlAndRedirect();
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
}