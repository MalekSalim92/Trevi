import { LightningElement, api } from 'lwc'; 
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningModal from 'lightning/modal';
import savePDFToFiles from '@salesforce/apex/ContractSummaryPdfGenerator.savePDFToFiles';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class GenerateContractSummary extends NavigationMixin(LightningModal) {
    @api recordId;
    vfPageUrl;
    isLoading = false;
    selectedLanguage = 'fr';
    frenchTabClass = 'language-tab active';
    englishTabClass = 'language-tab';
    errorMessage = 'No record ID available. Please ensure you\'re accessing this component from a valid record.';

    get generateLabel() {
        return this.selectedLanguage === 'en' ? 'Generate PDF' : 'Générer PDF';
    }

    get cancelLabel() {
        return this.selectedLanguage === 'en' ? 'Cancel' : 'Annuler';
    }

    get headerLabel() {
        return this.selectedLanguage === 'en' ? 'Generate Contract Summary' : 'Générer le Sommaire de Contrat';
    }

    connectedCallback() {

        console.log('START')
        const fullUrl = window.location.href;
 
        const pathParts = fullUrl.split('/');
 
        // Find the index of 'Order' in the path parts
        const orderIndex = pathParts.indexOf('Order');
 
        // If 'Order' is found and there is an ID after it
        if (orderIndex !== -1 && orderIndex + 1 < pathParts.length) {
            // Extract the ID
            this.recordId = pathParts[orderIndex + 1];
        }
        else{
            const urlParams = new URLSearchParams(window.location.search);
             this.recordId = urlParams.get('recordId');
        }

        if (this.recordId) {
 
            this.updateVFPageUrl();
        } else {
 
            const urlParams = new URLSearchParams(window.location.search);
            this.recordId = urlParams.get('recordId');
            if (this.recordId) {
                this.updateVFPageUrl();
            }
        }
    }



    updateVFPageUrl() {
        const baseUrl = window.location.origin;
        this.vfPageUrl = this.selectedLanguage === 'en'
            ? `${baseUrl}/apex/ContractSummary_En?id=${encodeURIComponent(this.recordId)}`
            : `${baseUrl}/apex/ContractSummary?id=${encodeURIComponent(this.recordId)}`;
    }

    handleTabClick(event) {
        this.selectedLanguage = event.target.dataset.language;
        this.frenchTabClass = this.selectedLanguage === 'fr' ? 'language-tab active' : 'language-tab';
        this.englishTabClass = this.selectedLanguage === 'en' ? 'language-tab active' : 'language-tab';
        this.updateVFPageUrl();
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

 
    handleGeneratePDF() {
        if (this.isLoading) return;
    
        if (!this.recordId) {
            this.showToast(
                this.selectedLanguage === 'en' ? 'Error' : 'Erreur',
                this.selectedLanguage === 'en' ? 'No record ID available' : 'Pas de ID disponible',
                'error'
            );
            return;
        }
    
        this.isLoading = true;
    
        savePDFToFiles({
            recordId: this.recordId,
            language: this.selectedLanguage
        })
        .then(contentDocumentId => {
            this.showToast(
                this.selectedLanguage === 'en' ? 'Success' : 'Succès',
                this.selectedLanguage === 'en' ? 'PDF saved to Files' : 'PDF enregistré dans les fichiers',
                'success'
            );
    
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view'
                }
            });
        })
        .catch(error => {
            console.error('PDF Generation Error:', error);
            this.showToast(
                this.selectedLanguage === 'en' ? 'Error' : 'Erreur',
                this.selectedLanguage === 'en' ? 'Failed to generate PDF' : 'Échec de la génération du PDF',
                'error'
            );
        })
        .finally(() => {
            this.isLoading = false;
        });
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