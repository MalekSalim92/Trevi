<<<<<<< HEAD
import { LightningElement} from 'lwc';
import getRedirectUrl from '@salesforce/apex/ShopifyPaymentService.getRedirectUrl';

export default class FlowRedirectingComponent extends LightningElement {
       
    
    async connectedCallback() {
        console.log('Redirecting main window...');
        try {
            const redirectUrl = await getRedirectUrl();
=======
import { LightningElement,api} from 'lwc';
import getRedirectUrl from '@salesforce/apex/ShopifyPaymentService.getRedirectUrl';

export default class FlowRedirectingComponent extends LightningElement {
    @api urlRedirection

    
    async connectedCallback() {
        console.log('.......Redirecting main window.......');
        try {
            console.log('urlRedirection...',this.urlRedirection);

            const redirectUrl = await getRedirectUrl({ urlRedirectionName: this.urlRedirection });
>>>>>>> shopify
            console.log('Retrieved redirect URL:', redirectUrl);
            
            if (redirectUrl) {
                // Redirect immediately
                window.location.href = redirectUrl;
            } else {
                console.log('No redirect URL found in custom metadata');
            }
        } catch (error) {
            console.error('Error retrieving redirect URL:', error);
        }
    }
}