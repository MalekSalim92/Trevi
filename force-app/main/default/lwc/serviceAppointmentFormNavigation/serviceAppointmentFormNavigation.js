/**
 * @description  LWC component for Flow navigation within a Service Appointment form.
 * Provides Confirm / Decline buttons and outputs the selected action back to Flow.
 * 
 * Usage: 
 * - Exposed in Flow with "isButtonDisabled" and "actionName" API properties
 * - Dispatches Flow events (FlowAttributeChangeEvent & FlowNavigationNextEvent)
 *
 * @file        serviceAppointmentFormNavigation.js
 * @author      Malek brachemi
 * @date        2025-07-19
 */

import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import CONFIRM_LABEL from '@salesforce/label/c.confirm';
import DECLINE_LABEL from '@salesforce/label/c.decline';

export default class ServiceAppointmentFormNavigation extends LightningElement {
    // Button labels (from custom labels for localization)
    confirmLabel = CONFIRM_LABEL;
    declineLabel = DECLINE_LABEL;

    /** @description Controls whether Confirm button is disabled */
    @api isButtonDisabled;

    /** @description Output property passed to Flow to indicate action taken */
    @api actionName = '';
    
    /** Handle Confirm button click */
    handleConfirm() {
        this.setActionAndNavigate('Confirm');
    }
    
    /** Handle Decline button click */
    handleDecline() {
        this.setActionAndNavigate('Decline');
    }
    
    /**
     * Set the action output property and navigate Flow to the next screen
     * @param {String} action - Action name ("Confirm" or "Decline")
     */
    setActionAndNavigate(action) {
        // Update API property
        this.actionName = action;
        
        // Notify Flow that actionName has changed
        this.dispatchEvent(new FlowAttributeChangeEvent('actionName', action));
        
        // Navigate Flow to the next screen
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
}