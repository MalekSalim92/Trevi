import { LightningElement, api, wire } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

import getMetadataRecords from '@salesforce/apex/OuvertureFermetureGenSelectorController.getMetadataRecords';

export default class OuvertureFermeture_GenericRadioSelector extends LightningElement {
    @api selectedValue = '';
    @api selectedSize = ''; 
    @api metadataObjectApiName = 'Opening_Closing_Contract_Selector__mdt'; 
    labelFieldEnApiName = 'Label_En__c'; 
    labelFieldFrApiName = 'Label_Fr__c';  
    activeFieldApiName = 'Active__c';  
    staticResourceFieldApiName = 'Static_Resource_Name__c'; 
    valueFieldToUse = 'DeveloperName'; 
    orderFieldApiName = 'Order__c'; 
    showSizesForValue = 'swimSpa'; 
    @api sizesMetadataObjectApiName = 'Opening_Closing_Spa_Size_Selector__mdt'; 
    
    metadataOptions = [];
    sizeOptions = [];
    isLoading = true;
    isSizeLoading = false;
    error;
    sizeError;

    // Wire to get main Custom Metadata records via Apex
    @wire(getMetadataRecords, {
        objectApiName: '$metadataObjectApiName',
        labelFieldFr: '$labelFieldFrApiName',
        labelFieldEn: '$labelFieldEnApiName',
        activeField: '$activeFieldApiName',
        staticResourceField: '$staticResourceFieldApiName',
        valueField: '$valueFieldToUse',
        sortOrderField: '$orderFieldApiName'
    })
    wiredMetadata({ error, data }) {
        console.log('Main Wire method called');
        console.log('metadataObjectApiName in wire:', this.metadataObjectApiName);
        console.log('data from Apex:', data);
        console.log('error:', error);
        
        if (data) {
            console.log('Processing main Apex data, records count:', data.length);
            try {
                this.metadataOptions = data.map(record => {
                    console.log('Language :', record.userLanguage);

                    const option = {
                        value: record.value,
                        label: record.label,
                        image: record.staticResourceName ? 
                               this.getStaticResourceUrl(record.staticResourceName) : null,
                        sortOrder: record.sortOrder || 999
                    };
                    console.log('Created main option:', option);
                    return option;
                });
                
                console.log('Final metadataOptions:', this.metadataOptions);
                this.isLoading = false;
                this.error = undefined;
                
            } catch (e) {
                console.error('Error processing main metadata:', e);
                this.error = { message: 'Error processing metadata: ' + e.message };
                this.isLoading = false;
                this.metadataOptions = [];
            }
        } else if (error) {
            console.error('Main Apex error:', error);
            this.error = error;
            this.isLoading = false;
            this.metadataOptions = [];
        } else {
            console.log('No main data received yet');
        }
    }

    // Wire to get size options when needed
    @wire(getMetadataRecords, {
        objectApiName: '$sizesMetadataObjectApiName',
        labelFieldEn: '$labelFieldEnApiName',
        labelFieldFr: '$labelFieldFrApiName',
        activeField: '$activeFieldApiName',
        staticResourceField: '$staticResourceFieldApiName',
        valueField: '$valueFieldToUse',
        sortOrderField: '$orderFieldApiName'
    })
    wiredSizeMetadata({ error, data }) {
        console.log('Size Wire method called');
        console.log('sizesMetadataObjectApiName:', this.sizesMetadataObjectApiName);
        console.log('size data from Apex:', data);
        console.log('size error:', error);
        
        if (data) {
            console.log('Processing size Apex data, records count:', data.length);
            try {
                this.sizeOptions = data.map(record => {
                    const option = {
                        value: record.value,
                        label: record.label,
                    };
                    console.log('Created size option:', option);
                    return option;
                });
                
                console.log('Final sizeOptions:', this.sizeOptions);
                this.isSizeLoading = false;
                this.sizeError = undefined;
                
            } catch (e) {
                console.error('Error processing size metadata:', e);
                this.sizeError = { message: 'Error processing size metadata: ' + e.message };
                this.isSizeLoading = false;
                this.sizeOptions = [];
            }
        } else if (error) {
            console.error('Size Apex error:', error);
            this.sizeError = error;
            this.isSizeLoading = false;
            this.sizeOptions = [];
        } else {
            console.log('No size data received yet');
        }
    }

    get options() {
        const optionsWithChecked = this.metadataOptions.map(option => ({
            ...option,
            checked: this.selectedValue === option.value
        }));
        console.log('get options() returning:', optionsWithChecked);
        return optionsWithChecked;
    }

    get sizeOptionsWithChecked() {
        const optionsWithChecked = this.sizeOptions.map(option => ({
            ...option,
            checked: this.selectedSize === option.value
        }));
        console.log('get sizeOptionsWithChecked() returning:', optionsWithChecked);
        return optionsWithChecked;
    }

    // Helper method to construct static resource URL
    getStaticResourceUrl(resourceName) {
        if (!resourceName) return '';
        return `/resource/${resourceName}`;
    }

    handleSelection(event) {
        console.log('handleSelection called with:', event.target.value);
        this.selectedValue = event.target.value;
        
        // Reset size selection when main selection changes
        if (this.selectedSize) {
            this.selectedSize = '';
            this.dispatchEvent(new FlowAttributeChangeEvent('selectedSize', this.selectedSize));
        }
        
        // Notify Flow of the main selection change
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedValue', this.selectedValue));
        
        console.log('Selected Value set to:', this.selectedValue);
    }

    handleSizeSelection(event) {
        console.log('handleSizeSelection called with:', event.target.value);
        this.selectedSize = event.target.value;
        
        // Notify Flow of the size selection change
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedSize', this.selectedSize));
        
        console.log('Selected Size set to:', this.selectedSize);
    }

    get hasError() {
        return this.error && !this.isLoading;
    }

    get hasSizeError() {
        return this.sizeError && !this.isSizeLoading;
    }

    get showOptions() {
        const shouldShow = !this.isLoading && !this.error && this.metadataOptions.length > 0;
        console.log('showOptions:', {
            isLoading: this.isLoading,
            hasError: !!this.error,
            optionsLength: this.metadataOptions.length,
            shouldShow: shouldShow
        });
        return shouldShow;
    }

    get showSizeOptions() {
        const shouldShow = this.selectedValue === this.showSizesForValue && 
                          !this.isSizeLoading && 
                          !this.sizeError && 
                          this.sizeOptions.length > 0;
        console.log('showSizeOptions:', {
            selectedValue: this.selectedValue,
            showSizesForValue: this.showSizesForValue,
            isSizeLoading: this.isSizeLoading,
            hasSizeError: !!this.sizeError,
            sizeOptionsLength: this.sizeOptions.length,
            shouldShow: shouldShow
        });
        return shouldShow;
    }

    get showNoOptionsMessage() {
        return !this.isLoading && !this.error && this.metadataOptions.length === 0 && this.metadataObjectApiName;
    }

    get errorMessage() {
        return this.error?.message || this.error?.body?.message || 'An unknown error occurred';
    }

    get sizeErrorMessage() {
        return this.sizeError?.message || this.sizeError?.body?.message || 'An unknown error occurred loading sizes';
    }

    // Handle image loading errors
    handleImageError(event) {
        console.warn('Failed to load image:', event.target.src);
        event.target.style.display = 'none';
    }
}