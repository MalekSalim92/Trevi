/**
 * @description   LWC wrapper for launching the Service Appointment Confirmation Flow. 
 *                Handles URL parameters, favicon setup, and language toggle for bilingual UI.
 *
 * @usage         Used in a public page to host a flow. 
 *                - Reads `id` param from URL as service appointment external Id.
 *                - Reads optional `language` param (default = en_US).
 *                - Passes parameters into Flow via flow-input-variables.
 *                - Provides UI toggle between English and French.
 *
 * @file          serviceAppointmentConfirmationForm.js
 * @author        Malek
 * @date          2025-05-30
 */

import { LightningElement, api, track } from 'lwc';
import TREVI_LOGO from '@salesforce/resourceUrl/TreviLogo';

export default class ServiceAppointmentConfirmationForm extends LightningElement {
    /** Public properties (set by Flow or URL) */
    @api serviceAppExternalId;
    @api formName;
    @api flowApiName = 'Service_Appointment_Confirmation_Form';

    /** Internal state */
    @track flowInputVariables = [];
    @track isFlowStarted = false;
    @track error;
    currentUrl;
    currentLanguage;

    /**
     * Lifecycle: component init
     * - Parse URL params
     * - Detect language
     * - Initialize Flow inputs
     * - Setup favicon
     */
    connectedCallback() {
        try {
            this.setupUrlParameters();
            this.detectCurrentLanguage();

            if (this.serviceAppExternalId) {
                this.initializeFlowVariables();
            } else {
                console.error('No record ID provided in URL');
                this.error = 'Missing record ID';
            }

            this.setupFavicon();
        } catch (error) {
            console.error('Error in connectedCallback:', error);
            this.error = 'An error occurred while initializing the page';
        }
    }

    /**
     * Pass parameters into Flow component
     */
    initializeFlowVariables() {
        const currentUrl = window.location.href;
        console.log('Passing URL to Flow:', currentUrl);

        this.flowInputVariables = [
            {
                name: 'serviceAppExternalId',
                type: 'String',
                value: this.serviceAppExternalId
            }
        ];
    }

    /**
     * Extract service appointment Id from URL (?id=xxx)
     */
    setupUrlParameters() {
        const urlParams = new URLSearchParams(window.location.search);
        this.serviceAppExternalId = urlParams.get('id');
    }

    /**
     * Dynamically replace favicon with Trevi logo
     */
    setupFavicon() {
        try {
            const favicon = document.createElement('link');
            favicon.rel = 'shortcut icon';
            favicon.type = 'image/png';
            favicon.href = TREVI_LOGO;

            const existingFavicon = document.querySelector("link[rel='shortcut icon']");
            if (existingFavicon) existingFavicon.remove();

            document.head.appendChild(favicon);
        } catch (error) {
            console.error('Error setting up favicon:', error);
        }
    }

    /**
     * Detect language from URL (?language=fr or en_US). Defaults to en_US.
     */
    detectCurrentLanguage() {
        const urlParams = new URLSearchParams(window.location.search);
        this.currentLanguage = urlParams.get('language') || 'en_US';
    }

    /**
     * Toggle label on button depending on current language
     */
    get languageButtonLabel() {
        return this.currentLanguage === 'fr' ? 'English' : 'Français';
    }

    /**
     * Reload page with toggled language param
     */
    handleLanguageToggle() {
        const currentUrl = window.location.href;
        let newUrl;

        if (currentUrl.includes('language=fr')) {
            newUrl = currentUrl.replace('language=fr', 'language=en_US');
        } else if (currentUrl.includes('language=en_US')) {
            newUrl = currentUrl.replace('language=en_US', 'language=fr');
        } else {
            // No param yet -> add language=fr
            const separator = currentUrl.includes('?') ? '&' : '?';
            newUrl = `${currentUrl}${separator}language=fr`;
        }

        // Reload page with new language
        window.location.href = newUrl;
    }

    /** Expose logo for template */
    get treviLogoUrl() {
        return TREVI_LOGO;
    }
}