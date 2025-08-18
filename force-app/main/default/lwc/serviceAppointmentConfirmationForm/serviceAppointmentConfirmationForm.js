import { LightningElement, api, track } from 'lwc';
import TREVI_LOGO from '@salesforce/resourceUrl/TreviLogo';

export default class ServiceAppointmentConfirmationForm extends LightningElement {
    @api serviceAppExternalId;
    @api formName;
    @api flowApiName = 'Service_Appointment_Confirmation_Form';
     @track flowInputVariables = [];
    @track isFlowStarted = false;
    @track error;
    currentUrl;
    
    // Remove all button logic - let flow handle everything
    
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
    
    
    
    setupUrlParameters() {
        const urlParams = new URLSearchParams(window.location.search);
        this.serviceAppExternalId = urlParams.get('id');
    }
    
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

    detectCurrentLanguage() {
        const urlParams = new URLSearchParams(window.location.search);
        this.currentLanguage = urlParams.get('language') || 'en_US';
    }
    
    get languageButtonLabel() {
        return this.currentLanguage === 'fr' ? 'English' : 'Français';
    }

    handleLanguageToggle() {
        const currentUrl = window.location.href;
        let newUrl;
        
        if (currentUrl.includes('language=fr')) {
            newUrl = currentUrl.replace('language=fr', 'language=en_US');
        } else if (currentUrl.includes('language=en_US')) {
            newUrl = currentUrl.replace('language=en_US', 'language=fr');
        } else {
            // Add language parameter
            const separator = currentUrl.includes('?') ? '&' : '?';
            newUrl = `${currentUrl}${separator}language=fr`;
        }
        
        // Reload page with new language
        window.location.href = newUrl;
    }

    get treviLogoUrl() {
        return TREVI_LOGO;
    }
    
}