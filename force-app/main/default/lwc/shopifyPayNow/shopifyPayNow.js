import { LightningElement, api, track } from 'lwc';
 
export default class ShopifyPayNow extends LightningElement {
 
    @api paymentLink;
    
    // Input property for button label
    @api buttonLabel = '';
    @api recordId;
    @api orderId;

    // Input properties for popup window settings
    @api popupWidth = 800;
    @api popupHeight = 600;
    
}