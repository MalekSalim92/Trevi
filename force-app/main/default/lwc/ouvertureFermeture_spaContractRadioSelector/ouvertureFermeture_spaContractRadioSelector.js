import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';


// Import your static resources
import PISCINE_CR_LABEL from '@salesforce/label/c.ContractType_Piscines_Creusess';
import PISCINE_SEMI_CR_LABEL from '@salesforce/label/c.ContractType_Piscines_SemiCreusees';
import PISCINE_HT_LABEL from '@salesforce/label/c.ContractType_Piscines_HT';
import SPA_LABEL from '@salesforce/label/c.ContractType_SPA';

import TITLE_LABEL from '@salesforce/label/c.Choose_Contract_Type';

import PISCINE_CR_IMAGE from '@salesforce/resourceUrl/piscineCreuse';
import PISCINE_SEMI_CR_IMAGE from '@salesforce/resourceUrl/piscineSemiCreuse';
import PISCINE_HT_IMAGE from '@salesforce/resourceUrl/piscineHorsTerre';
import SPA_IMAGE from '@salesforce/resourceUrl/spa';



export default class OuvertureFermeture_spaContractRadioSelector extends LightningElement {
    @api selectedContract = '';
    
    
    contractSelectionTitle = TITLE_LABEL ;

    
    get options() {
        return [
            {value: 'Contrat Ouverture/Fermeture piscines creusées',  label: PISCINE_CR_LABEL,image: PISCINE_CR_IMAGE,},
            {value: 'Contrat Ouverture/Fermeture piscines semi-creusées',  label: PISCINE_SEMI_CR_LABEL,image: PISCINE_SEMI_CR_IMAGE,},
            {value: 'Contrat Ouverture/Fermeture piscines hors-terre',  label: PISCINE_HT_LABEL,image: PISCINE_HT_IMAGE,},
            {value: 'Contrat Ouverture/Fermeture SPA',  label: SPA_LABEL,image: SPA_IMAGE,},
        ].map(option => ({
            ...option,
            checked: this.selectedContract === option.value,
            value: option.value,
            label: option.label,

        }));
    }
    
 
    handleSelection(event) {
        this.selectedContract = event.target.value;
         // Notify Flow of the change
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedContract', this.selectedContract));
 
        console.log('Selected Spa set to:', this.selectedContract);
 
    }
     
}