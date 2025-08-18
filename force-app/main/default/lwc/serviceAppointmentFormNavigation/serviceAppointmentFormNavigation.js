import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import CONFIRM_LABEL from '@salesforce/label/c.confirm';
import DECLINE_LABEL from '@salesforce/label/c.decline';

export default class ServiceAppointmentFormNavigation extends LightningElement {
    confirmLabel = CONFIRM_LABEL;
    declineLabel = DECLINE_LABEL;
    @api isButtonDisabled;

    // Output properties to flow  
    @api actionName = '';
    
    handleConfirm() {
        console.log('Confirm button clicked');
        this.setActionAndNavigate('Confirm');
    }
    
    handleDecline() {
        console.log('Decline button clicked');
        this.setActionAndNavigate('Decline');
    }
    
    setActionAndNavigate(action) {
        // Set the action
        this.actionName = action;
        console.log('Setting action to:', action);
        
        // Notify flow that actionName has changed
        const attributeChangeEvent = new FlowAttributeChangeEvent('actionName', action);
        this.dispatchEvent(attributeChangeEvent);
        console.log('Dispatched attribute change event for:', action);
        
        // Navigate to next screen
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
        console.log('Dispatched navigation next event');
    }
}