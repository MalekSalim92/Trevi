import { LightningElement, api } from 'lwc'; 
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningModal from 'lightning/modal';
import savePDFToFiles from '@salesforce/apex/ContractSummaryPdfGenerator.savePDFToFiles';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class GenerateContractSummary extends NavigationMixin(LightningModal) {
     // ----------------------
    // Properties
    // ----------------------

    @api recordId;
    vfPageUrl;
    isLoading = false;
    selectedLanguage = 'fr';
    frenchTabClass = 'language-tab active';
    englishTabClass = 'language-tab';
    errorMessage = 'No record ID available. Please ensure you\'re accessing this component from a valid record.';

    // ----------------------
    // Getters
    // ----------------------

    get generateLabel() {
        return this.selectedLanguage === 'en' ? 'Generate PDF' : 'Générer PDF';
    }

    get cancelLabel() {
        return this.selectedLanguage === 'en' ? 'Cancel' : 'Annuler';
    }

    get headerLabel() {
        return this.selectedLanguage === 'en' ? 'Generate Contract Summary' : 'Générer le Sommaire de Contrat';
    }
    
    // ----------------------
    // Lifecycle hook
    // ----------------------

    connectedCallback() {
 
        // Attempt to extract recordId from current URL
        const fullUrl = window.location.href;
        const pathParts = fullUrl.split('/');

        // Try to find 'Order' in the URL path
        const orderIndex = pathParts.indexOf('Order');

        if (orderIndex !== -1 && orderIndex + 1 < pathParts.length) {
            // If found, assign next segment as recordId
            this.recordId = pathParts[orderIndex + 1];
        } else {
            // Otherwise, try to get from URL query parameters
            const urlParams = new URLSearchParams(window.location.search);
            this.recordId = urlParams.get('recordId');
        }

        // If recordId is available, update VF page URL
        if (this.recordId) {
            this.updateVFPageUrl();
        } else {
            // Fallback to query parameter check
            const urlParams = new URLSearchParams(window.location.search);
            this.recordId = urlParams.get('recordId');
            if (this.recordId) {
                this.updateVFPageUrl();
            }
        }
    }

    // ----------------------
    // Event handlers
    // ----------------------

    // === Update Visualforce Page URL depending on selected language ===
    updateVFPageUrl() {
        const baseUrl = window.location.origin;
        this.vfPageUrl = this.selectedLanguage === 'en'
            ? `${baseUrl}/apex/ContractSummary_En?id=${encodeURIComponent(this.recordId)}`
            : `${baseUrl}/apex/ContractSummary?id=${encodeURIComponent(this.recordId)}`;
    }
    
    
    // === Handle language tab clicks ===
    handleTabClick(event) {
        // Update selected language
        this.selectedLanguage = event.target.dataset.language;

        // Update CSS classes for tabs
        this.frenchTabClass = this.selectedLanguage === 'fr' ? 'language-tab active' : 'language-tab';
        this.englishTabClass = this.selectedLanguage === 'en' ? 'language-tab active' : 'language-tab';

        // Update VF page URL to reflect new language
        this.updateVFPageUrl();
    }

    // === Handle Cancel button click ===
    handleCancel() {
        // Close modal
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // ----------------------
    // Apex Calls
    // ----------------------
   async handleGeneratePDF() {
        // Prevent duplicate requests
        if (this.isLoading) return;

        // Validate recordId
        if (!this.recordId) {
            this.showToast(
                this.selectedLanguage === 'en' ? 'Error' : 'Erreur',
                this.selectedLanguage === 'en' ? 'No record ID available' : 'Pas de ID disponible',
                'error'
            );
            return;
        }

        this.isLoading = true;
        try{
        // Call Apex method to generate PDF and save to Files
        const contentDocumentId = await savePDFToFiles({
            recordId: this.recordId,
            language: this.selectedLanguage
        })
        
      
            // Success toast
            this.showToast(
                this.selectedLanguage === 'en' ? 'Success' : 'Succès',
                this.selectedLanguage === 'en' ? 'PDF saved to Files' : 'PDF enregistré dans les fichiers',
                'success'
            );

            // Navigate to the Order record page after success
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view'
                }
            });
        }
        catch(error) {
            // Log error to console and show error toast
            console.error('PDF Generation Error:', error);
            this.showToast(
                this.selectedLanguage === 'en' ? 'Error' : 'Erreur',
                this.selectedLanguage === 'en' ? 'Failed to generate PDF' : 'Échec de la génération du PDF',
                'error'
            );
        }
        finally {
            // Reset loading state
            this.isLoading = false;
        };
    }

    // ----------------------
    // Toast event
    // ----------------------


    // === Helper method to show toast messages ===
    showToast(title, message, variant) {
        const toast = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(toast);
    }
}