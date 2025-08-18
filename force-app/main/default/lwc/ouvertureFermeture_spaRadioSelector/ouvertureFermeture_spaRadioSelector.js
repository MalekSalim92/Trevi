import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

// Import your static resources
import SPA_REGULAR from '@salesforce/resourceUrl/spa_regulier';
import SPA_SWIM from '@salesforce/resourceUrl/spa_de_nage';
import SPA_NATURE from '@salesforce/resourceUrl/spa_nature';

export default class OuvertureFermeture_spaRadioSelector extends LightningElement {
    @api selectedSpa = '';
    @api selectedSize = '';
    
    // Input properties from Flow
    @api acrylicSpaLabel;
    @api swimSpaLabel;
    @api natureSpaLabel;
    
    // Size labels as inputs
    @api thirteenSizeLabel;
    @api sixteenSizeLabel;
    @api seventeenSizeLabel;
    @api eighteenSizeLabel;
    @api nineteenSizeLabel;
    
    // Optional: section title
    @api sizeSelectionTitle;
    @api spaSelectionTitle;
    
    get sizeOptions() {
        return [
            { value: 'size13', label: this.thirteenSizeLabel },
            { value: 'size16', label: this.sixteenSizeLabel },
            { value: 'size17', label: this.seventeenSizeLabel },
            { value: 'size18', label: this.eighteenSizeLabel },
            { value: 'size19', label: this.nineteenSizeLabel }
        ].map(option => ({
            ...option,
            checked: this.selectedSize === option.value,
            value: option.value,
            label: option.label,

            
        }));
    }
    
    get options() {
        return [
            {value: 'Acrylic SPA',  label: this.acrylicSpaLabel,image: SPA_REGULAR,},
            {value: 'Swim SPA',  label: this.swimSpaLabel,image: SPA_SWIM,},
            {value: 'Nature SPA',  label: this.natureSpaLabel,image: SPA_NATURE,},
        ].map(option => ({
            ...option,
            checked: this.selectedSpa === option.value,
            value: option.value,
            label: option.label,

        }));
    }
    
    get showSizeOptions() {
        return this.selectedSpa === 'Swim SPA';
    }
    
    handleSelection(event) {
        this.selectedSpa = event.target.value;
        
        // Reset size if changing from swim to another option
        if (this.selectedSpa !== 'Swim SPA') {
            this.selectedSize = '';
        }
        
        // Notify Flow of the change
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedSpa', this.selectedSpa));
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedSize', this.selectedSize));

        console.log('Selected Spa set to:', this.selectedSpa);
        console.log('Selected Size set to:', this.selectedSize);

    }
    
    handleSizeSelection(event) {
        this.selectedSize = event.target.value;
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedSize', this.selectedSize));

        console.log('Selected Size set to:', this.selectedSize);

    }
}