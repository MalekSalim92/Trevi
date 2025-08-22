import { LightningElement,track } from 'lwc';
import updateServiceStatus from '@salesforce/apexContinuation/ServiceAppointmentFormController.updateServiceAppointment';
import TREVI_LOGO from '@salesforce/resourceUrl/TreviLogo';
import validateAndProcessService from '@salesforce/apex/ServiceAppointmentFormController.validateAndProcessService';
import postToChatter from '@salesforce/apex/ServiceAppointmentFormController.postFormToChatter';

export default class FormulaireExample extends LightningElement {
   
    @track deliveryAddress = {}    
    @track contractItems = [];
    @track isFrench = true;
    @track isLoading = true;
    @track showBackyardSection = false;
    @track showAccessNote = false;
    @track showHlAccessNote = false;
    @track showCommentBox = false;
    @track showAddressNegativeMsg = false;
    @track showSummaryNegativeMsg = false;
    @track showFermetureCommentBox = false;
    @track showPhoneBox = false;
    @track showMeubleCommentBox = false;
    @track showContractCommentBox = false;
    @track showRemplacementInput = false;
    @track showDeniveleInput = false;
    @track wantToBeContacted = false;
    @track isModalOpen = false;
    @track deliveryLocation = '';
    @track spaAreaLocation = '';
    @track accessMeetsRequirements = '';
    @track comminicationPreference = '';
    @track adressSelectedOption = '';
    @track adressComment = '';
    @track contractSelection = '';
    @track contractComment = '';
    @track spaAreaComment = '';
    @track acComment = '';
    @track abComment = '';
    @track phoneNumber = '';
    @track addressConfirmation = 'no';   
    @track addressFermetureConfirmation = 'non';   
    @track contractConfirmation = ''; 
    @track accessConfirmation = ''; 
    @track modalType = '';
    
    htForm = false
    crForm = false
    showThankYouMessage = false;
    showDeclineMessage = false;
    showInvalidUrlMessage = false;
    
    errorMessage = '';
    
    recordId;
    woli;
    workType;
    appointmentNumber;
    saData;
    appointmentDate
    installationDate
    deliveryDate
    currentForm
    logoUrl

    connectedCallback() {
        try {
            this.setupUrlParameters();
            console.log(this.recordId)
             if (this.recordId) {
                this.loadServiceAppointment();
 
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
    
    setupUrlParameters() {
        const urlParams = new URLSearchParams(window.location.search);
        this.recordId = urlParams.get('id');

        const currentUrl = window.location.pathname;
        console.log('currentUrl : dededede ', currentUrl)
        this.isFrench = currentUrl.includes('fr') ? true : false;
        this.languageKey = this.isFrench ? 'fr' : 'en';  
 
    }

     handleLanguageRedirect() {
        const currentUrl = window.location.pathname;
        console.log('currentUrl:', currentUrl);

        const newUrl = this.isFrench ? 
            currentUrl.replace('s/fr', 's/en') : 
            currentUrl.replace('s/en', 's/fr');
        
        // Preserve the query parameters
        const queryString = window.location.search;
        window.location.href = newUrl + queryString;
    }

    setupFavicon() {
        try {
            const favicon = document.createElement('link');
            favicon.rel = 'shortcut icon';
            favicon.type = 'image/png';
            favicon.href = TREVI_LOGO;
            this.logoUrl = TREVI_LOGO;
            
            const existingFavicon = document.querySelector("link[rel='shortcut icon']");
            if (existingFavicon) {
                existingFavicon.remove();
            }
            
            document.head.appendChild(favicon);
        } catch (error) {
            console.error('Error setting up favicon:', error);
            // Non-critical error, don't need to show to user
        }
    }


    loadServiceAppointment() {
        this.isLoading = true;
        console.log('recordId ',this.recordId)

        validateAndProcessService({ saId: this.recordId })

            .then(result => {
                this.hideAllSections();
                console.log('result ',JSON.stringify(result))
               // if(!result.isValid){
                 if(false){
                    
                    this.showInvalidUrlMessage = true
                    return;
                }
                else {

                    const saDetails = result.saDetails;
                    console.log('saDetails ',JSON.stringify(saDetails))

                    this.deliveryAddress = {
                        street: saDetails.Street,
                        city: saDetails.City,
                        province: saDetails.State,
                        postalCode: saDetails.PostalCode
                    };
                    console.log('orderItems ',JSON.stringify(result.orderItems))
                    console.log('WTG ', result.wtg)
 
                    switch (result.wtg) {
                    // switch ('Ouverture') {
                        case 'CR':
                            this.crForm = true;
                            this.currentForm = 'cr';
                            break;
                        case 'HT':
                            this.htForm = true;
                            this.currentForm = 'ht';
                            break;
                        case 'SP':
                            this.spaForm = true;
                            this.currentForm = 'spa';
                            break;
                        case 'AB':
                            this.abForm = true;
                            this.currentForm = 'ab';
                            break;
                        case 'MB':
                            this.meubleForm = true;
                            this.currentForm = 'meuble';
                            break;
                        case 'MB AUTRE':
                            this.this.meubleAutreForm = true;
                            this.currentForm = 'meubleAutre';
                            break;
                        case 'HL':
                            this.hlForm = true;
                            this.currentForm = 'hl';
                            break;
                        case 'AC':
                            this.acForm = true;
                            this.currentForm = 'ac';
                            break;
                        case 'Service':
                            this.crMarche = true;
                            this.currentForm = 'crmarche';
                            break;
                        case 'CR Marche':
                            this.crMarche = true;
                            this.currentForm = 'crmarche';
                            break;
                         case 'Fermeture':
                            this.fermeture = true;
                            this.currentForm = 'fermeture';
                            break;
                         case 'Ouverture':
                            this.ouverture = true;
                            this.currentForm = 'ouverture';
                            break;
                        default:
                            this.currentForm = 'default';
                            console.log('No specific form found for: ' + result.wtg);
                            break;
                    }
                    
                    this.workType = saDetails.WorkType.Name;
                    this.appointmentNumber = saDetails.AppointmentNumber;
                    this.woli = saDetails.ParentRecordId;
                    console.log('woli -->  ',this.woli)
                    this.customerPhone = saDetails.Account.Phone;
                    console.log('this.customerPhone ',this.customerPhone)
                    this.appointmentDate = saDetails && saDetails.SchedStartTime ? new Date(saDetails.SchedStartTime).toISOString().split('T')[0].replace(/-/g, '/') : '';                    
                    console.log('this.appointmentDate ',this.appointmentDate)

                    // Map order items to contract items
                    if (result.orderItems) {
                         this.contractItems = result.orderItems
                         .filter(item => item.quantity !== 0)
                         .map(item => ({
                            productCode: item.productCode || '',
                            productName: item.productName,
                            serialNumber: item.serialNumber || '',
                            quantity: item.quantity
                        }));
                        this.installationDate = result.orderItems[0].installationDate
                        console.log('this.installationDate ',this.installationDate)

                        this.deliveryDate = result.orderItems[0].deliveryDate
                        console.log('this.deliveryDate ',this.deliveryDate)
        
                        console.log('this.contractItems ',JSON.stringify(this.contractItems))

                    }
                }
            })
            .catch(error => {
                this.error = error.message || 'An error occurred while loading the appointment details';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }


    handleAcceptAppointment() {
        this.modalType = 'confirm';
        this.isModalOpen = true;
    }
    
    handleRefuseAppointment() {
        this.modalType = 'refuse';
        this.isModalOpen = true;
    }
    
    get modalLabels() {
        
        return this.modalType === 'confirm' ? {
            title: this.labels.modal.confirm.title[this.languageKey],
            message: this.labels.modal.confirm.message[this.languageKey],
            confirmButton: this.labels.modal.confirm.button[this.languageKey]
        } : {
            title: this.labels.modal.refuse.title[this.languageKey],
            message: this.labels.modal.refuse.message[this.languageKey],
            confirmButton: this.labels.modal.refuse.button[this.languageKey]
        };
    }
    
    closeModal() {
        this.isModalOpen = false;
        this.modalType = '';
    }
    
    confirmAndExecute() {
        let status = '';
        let accepted = true
        if(this.modalType === 'confirm') {
            status = 'Confirmed'
         } else if(this.modalType === 'refuse') {
             status = 'Refused by costumer'
             accepted = false
            }
        this.handleSubmitForm()
        this.handleUpdateServiceStatus(status,accepted)
        this.closeModal();
    }   

    handleUpdateServiceStatus(status,accepted) {
         console.log('-handleUpdateServiceStatus Clicked ')
         console.log('-accepted :' , accepted)
         console.log('-status :' , status)
         console.log('-this.recordId :' , this.recordId)

        updateServiceStatus({ saId: this.recordId, status :status })
             .then(result => {
                    console.log('--> mmm: ',JSON.stringify(result))
                if (result) {
                     this.errorMessage = 'Service Appointment updated successfully';
                     if(accepted){
                        this.showThankYouMessage = true;
                        
                     }
                     else{
                        this.showDeclineMessage = true
                     }
                     this.hideAllSections()
 
                    } else {
                    this.errorMessage = 'Failed to update Service Appointment';
                }
            })
            .catch(error => {
                this.errorMessage = 'Error updating Service Appointment: ' + error;
                console.error('Error:', error);
            });
    }

    hideAllSections() {
        // Hide all form sections
        this.htForm = false;
        this.crForm = false;
        this.spaForm = false;
        this.acForm = false;
        this.abForm = false;
        this.hlForm = false;
        this.meubleForm = false;
        this.meubleAutreForm = false;
        this.acMesureForm = false;
        this.acAutreForm = false;
        this.acAutreForm = false;
        this.ouverture = false;
        this.fermeture = false;
    
    }
    
    getFormData() {
        return {
            isAddressCorrect: this.adressSelectedOption == '' || this.adressSelectedOption == null ? null : this.adressSelectedOption === 'oui',
            addressComment: this.adressComment == '' || this.adressComment == null ? null : this.adressComment,
            isContractCorrect: this.contractSelection == '' || this.contractSelection == null ? null : this.contractSelection === 'oui',
            remplacementSelection: this.remplacementSelection == '' || this.remplacementSelection == null ? null : this.remplacementSelection === 'oui',
            meubleSelection: this.meubleSelection == '' || this.meubleSelection == null ? null : this.meubleSelection === 'oui',
            terrainDroitSelection: this.terrainDroitSelection == '' || this.terrainDroitSelection == null ? null : this.terrainDroitSelection === 'oui',
            hlAccessSelection: this.hlAccessSelection == '' || this.hlAccessSelection == null ? null : this.hlAccessSelection === 'oui',
            demonteeSelection: this.demonteeSelection == '' || this.demonteeSelection == null ? null : this.demonteeSelection === 'oui',
            installationSelection: this.installationSelection == '' || this.installationSelection == null ? null : this.installationSelection === 'oui',
            gazonSelection: this.gazonSelection == '' || this.gazonSelection == null ? null : this.gazonSelection === 'oui',
            hlObstacle: this.hlObstacle == '' || this.hlObstacle == null ? null : this.hlObstacle === 'oui',
            contractComment: this.contractComment == '' || this.contractComment == null ? null : this.contractComment,
            hlGradeurComment: this.hlGradeurComment == '' || this.hlGradeurComment == null ? null : this.hlGradeurComment,
            deniveleComment: this.deniveleComment == '' || this.deniveleComment == null ? null : this.deniveleComment,
            spaAreaComment: this.spaAreaComment == '' || this.spaAreaComment == null ? null : this.spaAreaComment,
            deliveryLocation: this.deliveryLocation == '' || this.deliveryLocation == null ? null : this.deliveryLocation,
            spaAreaLocation: this.spaAreaLocation == '' || this.spaAreaLocation == null ? null : this.spaAreaLocation,
            meubleComment: this.meubleComment == '' || this.meubleComment == null ? null : this.meubleComment,
            endroitInstallation: this.endroitInstallation == '' || this.endroitInstallation == null ? null : this.endroitInstallation,
            comminicationPreference: this.comminicationPreference == '' || this.comminicationPreference == null ? null : this.comminicationPreference,
            accessMeetsRequirements: this.accessMeetsRequirements == '' || this.accessMeetsRequirements == null ? null : this.accessMeetsRequirements === 'oui',
            wantToBeContacted: this.wantToBeContacted == '' || this.wantToBeContacted == null ? null : this.wantToBeContacted,
            phoneNumber: this.phoneNumber == '' || this.phoneNumber == null ? null : this.phoneNumber,
            acComment: this.acComment == '' || this.acComment == null ? null : this.acComment,
            abComment: this.abComment == '' || this.abComment == null ? null : this.abComment,
        };
    }    
 
         showConfirmationModal() {
            this.isModalOpen = true;
        }
    
         closeConfirmationModal() {
            this.isModalOpen = false;
        }
 
        handleSubmitForm() {
            
            const formData = this.getFormData();
            console.log('formData -->  ',JSON.stringify(formData))
            console.log('woli -->  ',this.woli)
            postToChatter({ 
                recordId: this.woli, 
                formData: formData 
            })
            .then(result => {
                console.log(JSON.stringify(result))
             })
            .catch(error => {
                console.log(JSON.stringify(error))
            });
        }
        vv(){
            const formData = this.getFormData();
             console.log('formData -->  ',JSON.stringify(formData))

        }
 

//todo    -------------------------------------------------------------------------   Handlers   ---------------------------------------------------------------------------------------------------
 

 
    // Handler for Spa Area radio buttons
    handleSpaAreaChange(event) {
        console.log('Delivery location changed to:', event.target.value);
        this.spaAreaLocation = event.target.value;
     }

// Handler for address confirmation radio buttons
    handleAddressRadioChange(event) {
        this.adressSelectedOption = event.target.value;
        this.addressConfirmation = event.target.value;  
        this.showCommentBox = this.adressSelectedOption === 'non';
        this.showAddressNegativeMsg = this.adressSelectedOption === 'non';
    }
    handleAddressFermetureRadioChange(event) {
        this.adressSelectedOption = event.target.value;
        this.addressFermetureConfirmation = event.target.value;  
        this.showFermetureCommentBox = this.addressFermetureConfirmation === 'non';
    }
    handlePhoneRadioChange(event) {
        this.phoneSelectedOption = event.target.value;
        this.showPhoneBox = this.phoneSelectedOption === 'non';
    }
    handleMeubleRadioChange(event) {
        this.meubleSelection = event.target.value;   
        this.showMeubleCommentBox = this.meubleSelection === 'non';
    }
    handleDemonteeRadioChange(event) {
        this.demonteeSelection = event.target.value;  
     }
     handleHlObstacleRadioChange(event) {
        this.hlObstacle = event.target.value;  
     }
    
  
    
    handleInstallationRadioChange(event) {
        this.installationSelection = event.target.value;  
     }

    // Handler for contract confirmation radio buttons
    handleContractRadioChange(event) {
        this.contractSelection = event.target.value;
        this.contractConfirmation = event.target.value;  
        this.showContractCommentBox = this.contractSelection === 'non';
        this.showSummaryNegativeMsg = this.contractSelection === 'non';
    }
 
    handleRemplacementRadioChange(event) {
        this.remplacementSelection = event.target.value;
        this.showRemplacementInput = this.remplacementSelection === 'oui';
    }
    handleTerrainDroitRadioChange(event) {
        console.log(event)
 

        this.terrainDroitSelection = event.target.value;
         this.showDeniveleInput = this.terrainDroitSelection === 'non';
    }

    handleDeliveryLocationChange(event) {
        console.log('Delivery location changed to:', event.target.value);
        this.deliveryLocation = event.target.value;
        this.showBackyardSection = event.target.value === 'cour';
        console.log('showBackyardSection:', this.showBackyardSection);
        
        // Reset access selection when changing delivery location
        this.accessMeetsRequirements = '';
        this.showAccessNote = false;
    }

    handleAccessRadioChange(event) {
        this.accessMeetsRequirements = event.target.value;
        this.accessConfirmation = event.target.value;  
        this.showAccessNote = this.accessMeetsRequirements === 'non';
    }
    handleHlAccessRadioChange(event) {
        this.hlAccessSelection = event.target.value;
        this.hlAccessConfirmation = event.target.value;  
        this.showHlAccessNote = this.hlAccessSelection === 'non';
    }

    handleCommunicationPreferenceChange(event) {
        this.comminicationPreference = event.target.value;
     }        

    handleAdressCommentChange(event) {
        this.adressComment = event.target.value;
    }
    handlePhoneFermetureChange(event) {
        this.phoneFermeture = event.target.value;
    }
    handleMeubleCommentChange(event) {
        this.meubleComment = event.target.value;
    }
    handleGazonRadioChange(event) {
        this.gazonSelection = event.target.value;
    }
    handleEndroitInstallationChange(event) {
        this.endroitInstallation = event.target.value;
    }
    handleSpaAreaCommentChange(event) {
        this.spaAreaComment = event.target.value;
    }


    handleContractCommentChange(event) {
        this.contractComment = event.target.value;
    }
    handleHlGrandeurCommentChange(event) {
        this.hlGradeurComment = event.target.value;
    }
    handleDeniveleChange(event) {
        this.deniveleComment = event.target.value;
    }

    handleContactPreferenceChange(event) {
        this.wantToBeContacted = event.target.checked;
    }

    handleAcCommentChange(event) {
        this.acComment = event.target.value;
    }
    handleAbCommentChange(event) {
        this.abComment = event.target.value;
    }

    handlePhoneNumberChange(event) {
 
        const input = event.target.value.replace(/\D/g, '');
        
        if (input.length <= 10) {
            this.phoneNumber = input;
        }
    }
    
  
 

//! ------------------------------------------------------------------------------------------------------ GETTERS ------------------------------------------------------------------------------------------------------------------------

        // Labels
        get headerLabels() {
            return {
                title : this.labels.header.title[this.languageKey],
                subtitle : this.labels.header.subtitle[this.languageKey](this.currentForm),
            
            }
        } 
        get contractLabels() {

             return {
                title : this.labels.contract.title[this.languageKey] ,
                question : this.labels.contract.confirmQuestion[this.languageKey],
                commentPlaceholder : this.labels.contract.commentPlaceholder[this.languageKey],
        }
    }

        get addressLabels() {

             return {
                title : this.labels.address.title[this.languageKey] ,
                subtitle : this.labels.address.subtitle[this.languageKey],                
                question : this.labels.address.question[this.languageKey],
                commentPlaceholder : this.labels.address.commentPlaceholder[this.languageKey],
        }}

        get locationLabels() {
            
            return {
                title: this.labels.modelSection.title[this.languageKey],
                question: this.labels.modelSection.question[this.languageKey],
                garage: this.labels.modelSection.locations.garage[this.languageKey],
                parking: this.labels.modelSection.locations.parking[this.languageKey],
                backyard: this.labels.modelSection.locations.backyard[this.languageKey],
                accessDescription: this.labels.modelSection.access.description[this.languageKey],
                accessQuestion: this.labels.modelSection.access.question[this.languageKey],
                accessNote: this.labels.modelSection.access.note[this.languageKey]

            };
        }
        get hlLabels() {
            
            return {
                title: this.labels.hlSection.title[this.languageKey],
                accessDescription: this.labels.hlSection.access.description[this.languageKey],
                accessQuestion: this.labels.hlSection.access.question[this.languageKey],
                accessNote: this.labels.hlSection.access.note[this.languageKey],
                statementOne: this.labels.hlSection.statements.statementOne[this.languageKey],
                statementTwo: this.labels.hlSection.statements.statementTwo[this.languageKey],
                statementThree: this.labels.hlSection.statements.statementThree[this.languageKey],
                statementFour: this.labels.hlSection.statements.statementFour[this.languageKey],
                statementFive: this.labels.hlSection.statements.statementFive[this.languageKey],

                endroit: this.labels.hlSection.endroit[this.languageKey],
                grandeur: this.labels.hlSection.grandeur[this.languageKey],
                gazon: this.labels.hlSection.gazon[this.languageKey],
                remplacement: this.labels.hlSection.remplacement[this.languageKey],
                demontee: this.labels.hlSection.demontee[this.languageKey],
                installation: this.labels.hlSection.installation[this.languageKey],
                terrainDroit: this.labels.hlSection.terrainDroit[this.languageKey],
                denivele: this.labels.hlSection.denivele[this.languageKey],
                obstacle: this.labels.hlSection.obstacle[this.languageKey],
                
            };
        }
          
         get spaAreaLabels() {
            
            return {
                title: this.labels.spaAreaSection.title[this.languageKey],
                subtitle: this.labels.spaAreaSection.subtitle[this.languageKey],
                question: this.labels.spaAreaSection.question[this.languageKey],
                commentPlaceholder: this.labels.spaAreaSection.commentPlaceholder[this.languageKey],
                dust: this.labels.spaAreaSection.area.dust[this.languageKey],
                cement: this.labels.spaAreaSection.area.cement[this.languageKey],
                wood: this.labels.spaAreaSection.area.wood[this.languageKey],
                patio: this.labels.spaAreaSection.area.patio[this.languageKey],
                paving: this.labels.spaAreaSection.area.paving[this.languageKey],
                other: this.labels.spaAreaSection.area.other[this.languageKey],
 
            };
        }
        
         
        get tableLabels() {
            
            return {
                productCode: this.labels.table.productCode[this.languageKey],
                productName: this.labels.table.productName[this.languageKey],
                serialNumber: this.labels.table.serialNumber[this.languageKey],
                quantity: this.labels.table.quantity[this.languageKey]
            };
        }
    
        get yesNoLabels() {
            
            return {
                yes: this.labels.buttons.yes[this.languageKey],
                no: this.labels.buttons.no[this.languageKey]
            };
        }
        get deliveryInfoLabels() {
            
            return {
                title: this.labels.deliveryInfo.title[this.languageKey](this.currentForm),
                noIndoor: this.labels.deliveryInfo.noIndoorDelivery[this.languageKey](this.currentForm),
                appointmentPrefix: this.labels.deliveryInfo.appointmentPrefix[this.languageKey](this.currentForm),
                confirmInstructions: this.labels.deliveryInfo.confirmInstructions[this.languageKey](this.currentForm),
                presenceInfo: this.labels.deliveryInfo.presenceInfo[this.languageKey](this.currentForm),
                contactCheckbox: this.labels.deliveryInfo.contactCheckbox[this.languageKey],
                phoneNumberCurrent: this.labels.deliveryInfo.phoneNumber.current[this.languageKey],
                phoneNumberChange: this.labels.deliveryInfo.phoneNumber.change[this.languageKey],
                phoneNumberPlaceholder: this.labels.deliveryInfo.phoneNumber.placeholder[this.languageKey],
                psStatement: this.labels.deliveryInfo.psStatement[this.languageKey](this.currentForm),
            };
        }  
        get importantInformationLabels() {
            
            return {
                titleLabel: this.labels.information.titleLabel[this.languageKey],
                deliveryDate: this.labels.information.deliveryDate[this.languageKey],
                installationDate: this.labels.information.installationDate[this.languageKey],
                extraDetailsDescription: this.labels.information.extraDetailsDescription[this.languageKey],
                requirementsListLabel: this.labels.information.requirementsListLabel[this.languageKey],
                requirement1: this.labels.information.requirement1[this.languageKey],
                requirement2: this.labels.information.requirement2[this.languageKey],
                requirement3: this.labels.information.requirement3[this.languageKey],
                requirement4: this.labels.information.requirement4[this.languageKey],
                requirement5: this.labels.information.requirement5[this.languageKey],
                requirement6: this.labels.information.requirement6[this.languageKey],
                requirement7: this.labels.information.requirement7[this.languageKey],         
                importantNoteLabel: this.labels.information.importantNoteLabel[this.languageKey],         
                importantNoteDescription: this.labels.information.importantNoteDescription[this.languageKey],         
                nextStepDescription: this.labels.information.nextStepDescription[this.languageKey],         
                    }
                }

        get communicationLabels() {
            
            return {
                 titleLabel: this.labels.communication.titleLabel[this.languageKey],
                 question: this.labels.communication.question[this.languageKey],
                 selectOption: this.labels.communication.selectOption[this.languageKey],
                 emailOptionLabel: this.labels.communication.emailOptionLabel[this.languageKey],
                 phoneOptionLabel: this.labels.communication.phoneOptionLabel[this.languageKey],
  
            };
         }

        get fermetureLabels() {
            
            return {
                 address: this.labels.fermeture.address[this.languageKey],
                 question: this.labels.fermeture.question[this.languageKey],
                 acceptButton: this.labels.fermeture.acceptButton[this.languageKey],
                 refuseButton: this.labels.fermeture.refuseButton[this.languageKey],
                 refuseStatement: this.labels.fermeture.refuseStatement[this.languageKey],
                 refusePlaceholder: this.labels.fermeture.refusePlaceholder[this.languageKey],
                 statementOne: this.labels.fermeture.statementOne[this.languageKey],
                 statementTwo: this.labels.fermeture.statementTwo[this.languageKey](this.currentForm),
                 statementThree: this.labels.fermeture.statementThree[this.languageKey](this.currentForm),
  
            };
         }

        get telephoneLabels() {
            
            return {
                  question: this.labels.telephone.question[this.languageKey],
   
            };
         }

        get rdvLabels() {
            
            return {
                 acceptTitle: this.labels.rdv.acceptTitle[this.languageKey],
                 refuseTitle: this.labels.rdv.refuseTitle[this.languageKey],
                 acceptrdv: this.labels.rdv.acceptrdv[this.languageKey],
                 acceptDate: this.labels.rdv.acceptDate[this.languageKey],
                 acceptButton: this.labels.rdv.acceptButton[this.languageKey],
                 refuseStatement: this.labels.rdv.refuseStatement[this.languageKey],
                 refusePlaceholder: this.labels.rdv.refusePlaceholder[this.languageKey],
                 refuseButton: this.labels.rdv.refuseButton[this.languageKey],
  
            };
         }
        get acSectionLabels() {
            
            return {
                subtitle: this.labels.acSection.subtitle[this.languageKey](this.currentForm),
                commentPlaceholder: this.labels.acSection.commentPlaceholder[this.languageKey],
                informationTitle: this.labels.acSection.informationTitle[this.languageKey],
                firstInfo: this.labels.acSection.firstInfo[this.languageKey](this.currentForm),
                secondInfo: this.labels.acSection.secondInfo[this.languageKey](this.currentForm),
                thirdInfo: this.labels.acSection.thirdInfo[this.languageKey](this.currentForm),
                note: this.labels.acSection.note[this.languageKey],
                question: this.labels.acSection.question[this.languageKey],
            };
         }
   
 
        get versementLabels() {
            
            return {
                title: this.labels.versement.title[this.languageKey],
                subtitle: this.labels.versement.subtitle[this.languageKey],
                details: this.labels.versement.details[this.languageKey],
                steps: this.labels.versement.steps[this.languageKey],
                delivery: this.labels.versement.delivery[this.languageKey],
                liner: this.labels.versement.liner[this.languageKey],
                sidewalk: this.labels.versement.sidewalk[this.languageKey],
                orientation: this.labels.versement.orientation[this.languageKey],
                description: this.labels.versement.description[this.languageKey],
                amount: this.labels.versement.amount[this.languageKey],
   
            };
         }

        get footerLabels() {
            
            return {
                acceptButton: this.labels.footer.buttons.accept[this.languageKey],
                refuseButton: this.labels.footer.buttons.refuse[this.languageKey],
                popupTitle: this.modalType === 'confirm' 
                ? this.labels.footer.buttons.confirmationTitle[this.languageKey] 
                : this.labels.footer.buttons.refuseTitle[this.languageKey],
                popupMessage: this.modalType === 'confirm'
                ? this.labels.footer.buttons.confirmationMessage[this.languageKey]
                : this.labels.footer.buttons.refuseMessage[this.languageKey],
                    confirmButton: this.labels.footer.buttons.confirm[this.languageKey],
                cancelButton: this.labels.footer.buttons.cancel[this.languageKey],
                contactIntro: this.labels.footer.contact.intro[this.languageKey],
                or: this.labels.footer.contact.or[this.languageKey],
                helpCenter: this.labels.footer.contact.helpCenter[this.languageKey]
            };
         }
    
         get endingPageLabels() {
            
            return {
                thankyouTitle: this.labels.endingPage.thankyouTitle[this.languageKey],
                thankyouMessage: this.labels.endingPage.thankyouMessage[this.languageKey],
                declineTitle: this.labels.endingPage.declineTitle[this.languageKey],
                declineMessage: this.labels.endingPage.declineMessage[this.languageKey],
                declineSubtitle: this.labels.endingPage.declineSubtitle[this.languageKey],
                invalidTitle: this.labels.endingPage.invalidTitle[this.languageKey],
                invalidMessage: this.labels.endingPage.invalidMessage[this.languageKey],
            };
         }
            
    
         get otherLanguageLabel() {
            return this.isFrench ? 'En' : 'Fr';
        }
  
        get negativeChoiceMsg() {
            return this.isFrench ? 'Prenez toutefois note que si vous répondez par la négative à une de ces questions, cela implique que vous refusez automatiquement le rendez-vous qui vous est offert.' : 'Please note that if you answer “no” to any of these questions, you automatically decline the appointment.';
        }

        get isAcceptButtonFermetureDisabled() {

             if (this.addressFermetureConfirmation === 'non' ) {
                return true;
            }

            return false;
        }

        get isAcceptButtonDisabled () {
            // If any answer is 'non', button should be disabled
            if (this.addressConfirmation === 'non' || this.contractConfirmation === 'non') {
                return true;
            }
        
            // If any required answer is missing (empty), button should be disabled
            if (!this.addressConfirmation || !this.contractConfirmation) {
                return true;
            }
             return false;
        }
        
        get showHeader() {
            return this.htForm || this.crForm || this.spaForm || this.acForm || this.acMesureForm || this.acAutreForm || this.abForm || this.hlForm || this.meubleForm || this.meubleAutreForm || this.crMarche || this.fermeture;
        }
        get showAddressSection() {
            return this.htForm || this.crForm || this.spaForm || this.acForm || this.acMesureForm || this.acAutreForm || this.abForm || this.hlForm || this.meubleForm ;
        }
         get showCommunicationSection() {
            return this.crForm;   
        }
         get showImportantInformationSection() {
            return this.crForm;   
        }
         get showVersementSection() {
            return this.crForm;   
        }
    
         get showAcAccessSection() {
            return this.acForm;   
        }
    
         get showAbAccessSection() {
            return this.abForm;   
        }
    
        get showContractSection() {
            return this.htForm|| this.crForm || this.spaForm || this.acForm || this.acMesureForm || this.acAutreForm || this.abForm || this.hlForm || this.meubleForm;
        }
    
        get showModeleSection() {
            return this.htForm || this.meubleForm; 
        }
        get showMeubleInformationSection() {
            return this.meubleForm 
        }
        get showSpaAreaSection() {
            return this.spaForm ;
        }
        get showHlSection() {
            return this.hlForm ;
        }
        get showFermeture() {
            return this.fermeture  || this.ouverture;
        }
        get showConfirmationRDV() {
            return this.crMarche ;
        }
        get showAnnulationRDV() {
            return this.crMarche ;
        }
        get showAcInformationSection() {
            return this.acAutreForm || this.meubleAutreForm ;
        }
    
        get showDeliverySection() {
            return this.htForm || this.crForm || this.spaForm || this.acForm || this.acMesureForm || this.acAutreForm || this.abForm   || this.meubleForm || this.meubleAutreForm;
        }
        get showFooterSection() {
            return this.htForm || this.crForm || this.spaForm || this.acForm || this.acMesureForm || this.acAutreForm || this.abForm || this.hlForm || this.meubleForm || this.meubleAutreForm;
        }
 
        

//!  --------------------------------------------------------  LABELS ----------------------------------------------------------------------


labels = {  

    header: {
        title: {
            fr:'Confirmation des détails de votre rendez-vous',
            en: 'Confirmation of the appointment'
        },
        subtitle:{         
        fr: (currentForm) => {
            switch(currentForm) {
                case 'ht':
                case 'meuble':
                    return 'Veuillez valider vos coordonnées ainsi que le modèle de votre piscine. En cas d\'incertitude, sélectionner \'non\' et nous inscrire la raison.';
                case 'cr':
                case 'spa':
                case 'ac':
                case 'acmesure':
                case 'acautre':
                case 'ab':
                    return 'Veuillez valider vos coordonnées ainsi que les items à votre contrat. En cas d\'incertitude, sélectionner "non" et nous inscrire la raison.';
                case 'hl':
                    return 'Veuillez vous assurer d\'avoir choisi l\'emplacement de la piscine, bien indiqué avec un piquet au centre. Vous devez vous être procuré 2 dalles de 18’’X18’’ pour l\'installation de la filtration ou 2 dalles de 24’’X24’’ si vous avez une thermopompe';
                default:
                    return '';
            }
        },
        en: (currentForm) => {
            switch(currentForm) {
                case 'ht':
                case 'meuble':
                    return 'Please verify the items listed on your contract. If unsure, select "no" and provide the details.';
                case 'cr':
                case 'spa':
                case 'ac':
                case 'acmesure':
                case 'acautre':
                case 'ab':
                    return 'Please verify the items listed on your contract. If unsure, select "no" and provide the details.';
                case 'hl':
                    return 'Please ensure that the installers have access to all the materials. You will need to purchase two 18’’ X 18’’ patio slabs for the installation of the filter and pump. If you have also purchased a heater or heat pump you will need two additional 24’’ X 24’’ patio slabs.';
                default:
                    return '';
       
            }
        }
    },
   },
    contract: {
         title: {
            fr: 'CONFIRMATION DU CONTRAT SOMMAIRE',
            en: 'CONTRACT SUMMARY CONFIRMATION'
        },
        confirmQuestion: {
            fr: 'Est-ce que vous confirmez le contrat sommaire?',
            en: 'Do you confirm the summary contract?'
        },
        commentPlaceholder: {
            fr: 'Veuillez expliquer pourquoi...',
            en: 'Please explain why...'
        },
       
    },
    address: {
         title: {
            fr: 'CONFIRMATION DE L\'ADRESSE DE LIVRAISON',
            en: 'CONFIRMATION OF THE DELIVERY ADDRESS'
        },
        subtitle: {
            fr: 'Voici l\'adresse de livraison que nous avons au contrat',
            en: 'Here is the delivery address that we have in our records'
        },
 
        question: {
            fr: 'Est-ce la bonne adresse?',
            en: 'Is this the correct address?'
        },
        commentPlaceholder: {
            fr: 'Veuillez expliquer pourquoi...',
            en: 'Please explain why...'
        }
    },
    table: {
        productCode: {
            fr: 'Code de produit',
            en: 'Product Code'
        },
        productName: {
            fr: 'Nom du produit',
            en: 'Product Name'
        },
        serialNumber: {
            fr: 'Numéro de série',
            en: 'Serial Number'
        },
        quantity: {
            fr: 'Quantité',
            en: 'Quantity'
        }
    },
    buttons: {
        yes: {
            fr: 'Oui',
            en: 'Yes'
        },
        no: {
            fr: 'Non',
            en: 'No'
        }
    },
 

    versement: {
        title: {
            fr: 'VERSEMENTS À EFFECTUER PAR LE CLIENT',
            en: 'CLIENT PAYMENT REQUIRED'
        },
        subtitle: {
            fr: 'Voici à jour, le détail des versements que vous devez effectuer. Ces montants pourront varier si des modifications sont faites suite à ce courriel.',
            en: 'Please refer to the schedule of upcoming payments. These amounts may vary if changes are made following this email.'
        },
        details: {
            fr: 'Le paiement peut être effectué en ligne sur le site internet de votre institution financière. Vous pouvez faire un paiement de facture en nous ajoutant comme fournisseur (Trevi) et inscrire votre numéro de client. Vous pouvez également faire le paiement par argent comptant ou traite bancaire à l\'ordre de Magasins Trévi Inc. en succursale. Le paiement pour la livraison doit être effectués 15 jours avant la semaine prévue au contrat. Le ou les autres paiements devront être effectués 24 à 48 heures avant le rendez-vous. Une preuve de paiement devra être montré au technicien.',
            en: 'The payment can be made online via your financial institution\'s website. You can add Trevi as a payee and enter your customer number as the account number. You can also pay in a Trevi store in cash or bank draft, payable to Magasins Trévi Inc.. The payment for the delivery must be made 15 days before the week stipulated on the contract. The other(s) payment(s) must be made 24 to 48 hours before the appointment. The technician will ask to see a proof of payment.'
        },
        steps: {
            fr: 'Voici les montants à remettre lors des différentes étapes:',
            en: 'Here are the payments due at the various phases:'
        },
        delivery: {
            fr: 'Livraison',
            en: 'Delivery',
        },
        liner: {
            fr: 'Toile',
            en: 'Liner',
        },
        sidewalk: {
            fr: 'Trottoir / Pavé uni',
            en: 'Sidewalk / Paving Stones',
        },
        orientation: {
            fr: 'Explications / Balayeuse',
            en: 'Orientation / Vacuuming',
        },
        description: {
            fr: 'DESCRIPTION',
            en: 'DESCRIPTION',
        },
        amount: {
            fr: 'MONTANT',
            en: 'AMOUNT',
        },
        
    },

    information: {
        titleLabel: {
            fr: 'INFORMATIONS IMPORTANTES',
            en: 'IMPORTANT INFORMATIONS'
        },
        deliveryDate: {
            fr: 'La semaine prévue de livraison est la suivante',
            en: 'Delivery is scheduled for the week of'
        },
        installationDate: {
            fr: 'La semaine prévue d\'installation est la suivante',
            en: 'Installation is scheduled for the week of'
        },
        extraDetailsDescription: {
            fr: 'Si vous avez sur votre plan du trottoir/pavé un de dessiné en extra et que vous désirez ajouter cet extra à votre contrat, il est important que l\'ajout se fasse le plus rapidement possible avec votre représentant afin de ne pas retarder l\'excavation de votre piscine.',
            en: 'If you already have your sidewalk or pavement (surplus not included in your pool contract) implementation plan drawn and you want to add that extra to your contract, it is important that the addition is done as quickly as possible with your representative in order prevent any delays with the excavation of your pool.'
        },
        requirementsListLabel: {
            fr: 'Voici la liste de ce dont notre département de construction a besoin pour pouvoir débuter votre installation:',
            en: 'Here is the list of what our construction department requires to begin your installation:'
        },
        requirement1: {
            fr: 'Un accès d\'une largeur minimale de 6 pieds pour la livraison des matériaux;',
            en: 'Access with a minimum width of 6 feet for the delivery of materials;'
        },
        requirement2: {
            fr: 'Votre numéro d\'autorisation d\'Info-Excavation;',
            en: 'Your Info-Excavation authorization number;'
        },
        requirement3: {
            fr: 'Votre clôture temporaire avec suffisamment de piquets;',
            en: 'Your temporary fence with sufficient stakes;'
        },
        requirement4: {
            fr: 'Accès à une relonge électrique;',
            en: 'Access to an extension cord;'
        },
        requirement5: {
            fr: 'Accès à votre boyau d\'arrosage;',
            en: 'Access to your garden hose;'
        },
        requirement6: {
            fr: 'La livraison est effectuée à l\'aide d\'un transpalette manuel. Il est seulement possible de transporter les palettes sur une surface dure, lisse, de niveau et dégagée de tout obstacle pouvant nuire aux livreurs, incluant de la neige ou glace. Le matériel pourra seulement être déposé dans la cour si le sol le permet et qu\'il y a une largeur minimale de 6 pieds. Sinon, les palettes seront déposées dans l\'entrée et/ou le garage;',
            en: 'The delivery team is equipped with a manual palette jack. Depending on the ground conditions, it may not be possible to deliver the material in the back yard. If the ground conditions are not adequate, the palettes will be placed in the driveway or the garage;'
        },
        requirement7: {
            fr: 'Vous devez prévoir un espace d\'une superficie de 12 pieds par 12 pieds pour recevoir le matériel. L\'emplacement choisi ne doit pas entraver l\'accès qui sera utilisé par la machinerie et la zone que l\'excavateur aura de besoin pour effectuer les travaux.',
            en: 'You must provide a space of 12 feet by 12 feet to receive the material. The location the material is stored cannot be in the access for the excavation equipment in the work area where the excavation will take place.'
        },
        importantNoteLabel:{
            fr:'IMPORTANT',
            en:'IMPORTANT'
        },
        importantNoteDescription:{
            fr:'Nous vous recommandons de lire attentivement le devis de construction ci-joint afin de connaître toutes les étapes du processus de construction.',
            en:'We strongly recommend that you read « Work Description and Requirements» in order to be aware of all construction steps that will follow.'
        },
        nextStepDescription:{
            fr:'La prochaine étape sera la visite d\'un chargé de projet qui vous contactera afin de prendre un rendez-vous dès que la température le permettra. Par la suite, vous serez contacté par un excavateur qui confirmera un rendez-vous dès que la température le permettra.',
            en:'You will be contacted by a project manager for an appointment to inspect the access and the property. Following this visit, you will be contacted by the excavator for an appointment as soon as weather permit’s it.'
        },
    },

    communication: {
        titleLabel: {
            fr: 'PRÉFÉRENCES DE COMMUNICATION',
            en: 'PREFERRED COMMUNICATION METHOD'
        },
        question: {
            fr: 'Lors de la construction de votre piscine de quelle façon préférez-vous être contacté pour les prises de rendez-vous?',
            en: 'During the construction of your pool, how would you prefer to be contacted for scheduling appointments?'
        },
        selectOption: {
            fr: 'Sélectionner une option',
            en: 'Select an option'
        },
        emailOptionLabel: {
            fr: 'Courriel et/ou SMS',
            en: 'Email and/or test message'
        },
        phoneOptionLabel: {
            fr: 'Appel téléphonique',
            en: 'Phone cal'
        },
    },

    modelSection: {
        title: {
            fr: 'MODÈLE ET GRANDEUR',
            en: 'MODEL AND SIZE'
        },
        question: {
            fr: 'Où désirez-vous que nous déposions le matériel?',
            en: 'Where would you like us to place the materials?'
        },
        locations: {
            garage: {
                fr: 'Dans le garage',
                en: 'In the garage'
            },
            parking: {
                fr: 'Dans le stationnement',
                en: 'In the driveway'
            },
            backyard: {
                fr: 'Dans la cour arrière',
                en: 'In the back yard'
            }
        },
        access: {
            description: {
                fr: 'Nous avons besoin d\'un accès direct de la rue à l\'emplacement que vous aurez déterminé, de 52 pouces de large sans obstacles ni marches pour la livraison.',
                en: 'In order to complete the delivery, we need 52 inches wide direct access to and from the street to the location you have determined. Direct access must not have any obstacle or steps.'
            },
            question: {
                fr: 'Est-ce que l\'accès correspond à cette description :',
                en: 'Does your direct access fit that description:'
            },
            note: {
                fr: 'Si non, nous vous contacterons pour les détails.',
                en: 'If the answer is no, we will contact you for more details.'
            }
        }
    },
    hlSection: {
        title: {
            fr: 'MODÈLE ET GRANDEUR',
            en: 'MODEL AND SIZE'
        },
        
        access: {
            description: {
                fr: 'Nous avons besoin d\'un accès direct de la rue à la cour pour le déplacement des matériaux qui se fera en brouette.',
                en: 'We need direct access from the street to the yard for the carting of materials by using a wheelbarrow. This access must not include staircases, multiple levels, landings or any other obstacle.'
            },
            question: {
                fr: 'Est-ce que l\'accès correspond à cette description?',
                en: 'Does the access to your yard fits this description?'
            },
            note: {
                fr: 'Si non, nous vous contacterons pour les détails.',
                en: 'If not, we will contact you for details.'
            }
        },
        statements: {
            statementOne: {
                fr: 'Pour l\'installation, un minimum d\'un boyau d\'arrosage est requis. Vous pourrez aussi utiliser une citerne d\'eau pour remplir la piscine mais le boyau est utile pour placer la toile lors de l\'installation.',
                en: 'A garden hose is required for the installation even if you have chosen to use a water tank to fill the pool. The installers will require the hose for the installation and placement of your liner.'
            },
            statementTwo: {
                fr: 'Nous vous suggérons de communiquer avec votre municipalité pour connaitre les dernières règlementations concernant votre installation de piscine. Certaines municipalités exigent l\'obtention d\'un permis.',
                en: 'We suggest you contact your municipality to find out the bi-law regulations regarding the installation of an above ground pool. Some municipalities require a permit.'
            },
            statementThree: {
                fr: '*Veuillez prendre note que si un patio est déjà existant avant l\'installation, nous vous demandons de vous assurer qu\'il y ait un dégagement de 18’’ tout le tour de la future installation. Suite à l\'installation de la piscine, vous pourrez faire les ajustements nécessaires sur votre patio.',
                en: '*If you have a patio that will be adjacent to the pool, please ensure that there is a clearance of 18 inches between the patio and the edge of the pool. Following the installation of the pool, you can make the necessary adjustments to your patio.'
            },
            statementFour: {
                fr: 'Assurez-vous que les branchements électriques soient faits selon les recommandations indiqués dans chacun des manuels d\'instructions. Le branchement de la pompe doit s\'effectuer sur une prise extérieure directe, sans extension.',
                en: 'Please make sure that the electrical connections are made according to the recommendations given in each of the instruction manuals. The connection of the pump must be on a direct outside socket without an extension cord.'
            },
            statementFive: {
                fr: 'Date du rendez-vous ',
                en: 'We confirm that the installation will be on '
            },
           
        },
        endroit:{
                fr: 'L’endroit où vous avez décidé d’installer votre piscine',
                en: 'Please make sure you have selected the location of the pool by placing a stake in the center of the chosen location.',
        },
        gazon:{
                fr: 'Est-ce un terrain gazonné?',
                en: 'Is it a grass covered area?',
        },
        remplacement:{
                fr: 'Est-ce un remplacement de piscine?',
                en: 'Are you are replacing an existing pool?',
        },
        grandeur:{
                fr: 'quelle grandeur',
                en: 'what size',
        },
        demontee:{
                fr: 'Est-ce que l’ancienne piscine est démontée?',
                en: 'Has the original pool been taken down?',
        },
        installation:{
                fr: 'Est-ce que l’installation sera faite au même endroit?',
                en: 'Is the new pool being installed in the same place?',
        },
        terrainDroit:{
            fr: 'Est-ce que le terrain est droit (de niveau)?',
            en: 'Is the ground levelled?',
        },
        denivele:{
            fr: 'combien de dénivelé (pouce)',
            en: 'how many inches is it unlevelled',
        },
        obstacle:{
            fr: 'À l’emplacement de la piscine, est-ce qu’il y a des roches, des souches, des racines, des arbres ou des fils électrique?',
            en: 'Are there any rocks, stumps, roots, trees, or electrical wire?',
        },
    },
 
    rdv:{
        acceptTitle: {
            fr: 'CONFIRMATION DE VOTRE RENDEZ-VOUS',
            en: 'APPOINTMENT CONFIRMATION'
        },
        refuseTitle: {
            fr: 'ANNULATION DE VOTRE RENDEZ-VOUS',
            en: 'APPOINTMENT CANCELLATION'
        },
        acceptrdv: {
            fr: 'Rendez-vous: ',
            en: 'Appointment: '
        },
        acceptDate: {
            fr: 'Date: ',
            en: 'Date: '
        },
    
        acceptButton: {
            fr: 'Confirmer le rendez-vous',
            en: 'Confirm appointment'
        },
        refuseStatement: {
            fr: 'Si vous devez annuler votre rendez-vous, s\'il vous plaît, inscrivez le motif de l\'annulation et il nous fera plaisir de vous céduler un autre rendez-vous!',
            en: 'If you need to cancel your appointment, please provide the reason for cancellation and we will be happy to schedule another appointment for you!'
        },
        refusePlaceholder: {
            fr: 'Raison de l\'annulation',
            en: 'Reason for cancellation'
        },
        refuseButton: {
            fr: 'Annuler le rendez-vous',
            en: 'Cancel appointment'
        },
    },

    spaAreaSection: {
        title: {
            fr: 'MODÈLE ET GRANDEUR',
            en: 'MODEL AND SIZE'
        },
        subtitle: {
            fr: 'Dans le cas où il y a des escaliers, étages, accès restreint, pentes, paliers, livraison à l\'intérieur du domicile ou tous autres obstacles, nous inscrire plus de détails. Il est possible qu’une visite de conformité soit nécessaire.',
            en: 'To deliver your spa, we need direct access having 40 inches wide and 100 inches tall clearance. If there are stairs, levels, restricted access, slopes, landings or any other obstacles, or if the spa is to be placed inside your home, please list all the details below. It is possible that a compliance visit will be necessary.'
        },
        question: {
            fr: 'Sur quelle surface le spa sera déposé ?',
            en: 'On what surface will the spa be placed?'
        },
        commentPlaceholder: {
            fr: 'Inscrire plus de détails',
            en: 'List details'
        },
        area: {
            dust: {
                fr: 'Poussière de pierre',
                en: 'Stone dust'
            },
            cement: {
                fr: 'Ciment',
                en: 'Cement'
            },
            wood: {
                fr: 'Bois',
                en: 'Wood'
            },
            patio: {
                fr: 'Poussière de pierre',
                en: 'Patio slabs'
            },
            paving: {
                fr: 'Ciment',
                en: 'Paving stones'
            },
            other: {
                fr: 'Bois',
                en: 'Other'
            },
        },
       
    },

    fermeture: {
       
        address: {
            fr: 'L\'adresse d\'intervention est-elle correcte ?',
            en: 'Is the intervention address correct ?'
        },
        question: {
            fr: 'Le numéro de téléphone principal est-il exact ?',
            en: 'Is the main phone number correct ?'
        },
        acceptButton: {
            fr: 'J\'ai lu et accepté le rendez-vous',
            en: 'I have read and accepted the appointment'
        },

        refuseButton: {
            fr: 'Je refuse le rendez-vous',
            en: 'I decline the appointment'
        },
        refusePlaceholder: {
            fr: 'Raison de l\'annulation',
            en: 'Refusal reason'
        },

        refuseStatement: {
            fr: 'Si ce rendez-vous ne vous convient pas, vous pouvez le refuser et notre département de répartition replanifiera un rendez-vous pour vous.',
            en: 'If this appointment does not suit you, you can decline it, and our scheduling department will reschedule an appointment for you.'
        },

        statementOne: {
            fr: '• Assurez-vous que notre technicien aura accès au matériel ainsi qu\'à votre cour à cette date, sinon des frais de déplacement seront facturés.',
            en: '• Make sure our technician will have access to the equipment as well as your yard on that date; otherwise, travel fees will be charged.'
        },

        statementTwo:{
            fr: (currentForm) => {
                switch(currentForm) {
                    case 'fermeture':
                        return '• Votre toile/housse hivernale devra être accessible afin d\'en faire l\'installation (sauf si sélectionnée en supplément au contrat). Si la toile n\'est pas sur place, nous devrons remettre le rendez-vous et des frais de déplacement seront facturés.';
                    default:
                        return '';
                }
            },
            en: (currentForm) => {
                switch(currentForm) {
                    case 'fermeture':
                        return '• Your winter cover must be accessible for installation (unless selected as an additional option in the contract). If the cover is not on-site, we will have to reschedule the appointment, and travel fees will be charged.';
                     default:
                        return '';
                }
            },
        },

        statementThree:{
            fr: (currentForm) => {
                switch(currentForm) {
                    case 'fermeture':
                        return '• Assurez-vous de laisser la filtration en fonction jusqu\'au rendez-vous. La température de l\'eau doit être maintenue à 80°F ou plus, et l\'eau du spa doit être équilibrée.';
                     default:
                        return '';
                }
            },
            en: (currentForm) => {
                switch(currentForm) {
                    case 'fermeture':
                        return '• Make sure to keep the filtration running until the appointment. The water temperature must be maintained at 80°F or higher, and the spa water must be balanced.';
                     default:
                        return '';
                }
            },
        },
       
    },
    acSection: {
 
        subtitle:{
            fr: (currentForm) => {
                switch(currentForm) {
                    case 'ac':
                        return 'Pour pouvoir faire la livraison, nous avons besoin d\'un accès direct ayant une largeur de 36 pouces. S\'il y a des escaliers, des étages, un accès restreint, une pente, des paliers ou tout autre obstacle, prière d\'inscrire les détails ci-dessous.';
                    case 'ab':
                        return 'Pour la livraison, les modèles Ultra et Supra peuvent être déposés dans la cour, par contrat il ne doit pas y avoir d\'escaliers, des étages, un accès restreint, une pente, des paliers ou tout autre obstacle. Pour tous autres modèles, la livraison se fera dans le stationnement.';
                    default:
                        return '';
                }
            },
            en: (currentForm) => {
                switch(currentForm) {
                    case 'ac':
                        return 'In order to complete the delivery, we need a direct, 36 inches wide, access. If there are stairs, levels, restricted accesses, slopes, landings or other obstacle, please list all the details below.';
                    case 'ab':
                        return 'For delivery, the Ultra and Supra models can be dropped off in the yard. As per the contract, there must be no stairs, floors, restricted access, slopes, landings, or any other obstacles. For all other models, delivery will be made in the parking lot.';
                    default:
                        return '';
                }
            },
        },
        commentPlaceholder: {
            fr: 'Inscrire plus de détails.',
            en: 'List details.'
        },
        informationTitle: {
            fr: 'INFORMATION',
            en: 'INFORMATION'
        },
 
        firstInfo:{
            fr: (currentForm) => {
                switch(currentForm) {
                    case 'acautre':
                        return 'Pour les matériaux déjà livrés ou reçus, veuillez vous assurer que tous les matériaux sont accessibles. Si nous installons une pompe à chaleur ou un chauffage, assurez-vous de positionner l\'équipement à l\'endroit exact où vous souhaitez qu’il soit installé.';
                    case 'meubleautre':
                        return 'Prière de vous assurer que tous les matériaux soient accessibles et disposés près de l\'endroit ou l\'installation se fera.';
                    default:
                        return '';
                }
            },
            en: (currentForm) => {
                switch(currentForm) {
                    case 'acautre':
                        return 'For materials already delivered or received, please make sure that all materials are accessible. If we are installing a heat pump or heater, be sure to position the equipment at the exact location where you would like it installed.';
                    case 'meubleautre':
                        return 'Please ensure that all materials are accessible and placed near the location of the installation.';
                    default:
                        return '';
                }
            },
        },
        secondInfo:{
            fr: (currentForm) => {
                switch(currentForm) {
                    case 'acautre':
                        return 'Si l\'installation concerne un liner de piscine creusée, veuillez noter que l\'installation se fera sur deux jours. Assurez-vous de laisser l\'accès à la piscine pendant les 48 heures suivant l\'installation du liner afin que le technicien puisse revenir pour terminer le travail.';
                    case 'meubleautre':
                        return 'La base du gazébo doit être de niveau et prête pour l\'installation.';
                    default:
                        return '';
                }
            },
            en: (currentForm) => {
                switch(currentForm) {
                    case 'acautre':
                        return 'If this is an in-ground pool liner installation, please note that the installation will be done over two days. Please make sure to leave access to the pool during the 48 hours following the installation of the liner so that the technician can return to complete the work.';
                    case 'meubleautre':
                        return 'The base of the gazebo should be level and ready for installation.';
                    default:
                        return '';
                }
            },
        },
        thirdInfo:{
            fr: (currentForm) => {
                switch(currentForm) {
                    case 'meubleautre':
                        return 'Prière d\'identifier le lieu précis de l\'installation à l\'aide de piquets fixés au sol aux 4 extrémités.';
                    default:
                        return '';
                }
            },
            en: (currentForm) => {
                switch(currentForm) {
                    case 'meubleautre':
                        return 'Please identify the specific location of the installation by placing stakes at the 4 extremities.';
                    default:
                        return '';
                }
            },
        },
        note: {
            fr: 'Veuillez prendre note qu\'aucune livraison ne s\'effectuera à l\'intérieur de la maison. Pour pouvoir faire la livraison, nous avons besoin d\'un accès direct, à l\'endroit où nous allons déposer le matériel.',
            en: 'Please note that we do not deliver product inside your home. In order to complete the delivery, we need direct access to the area where the product will be placed.',
        },
        question: {
            fr: 'Est-ce que l’accès correspond à cette description?',
            en: 'Does your direct access fits this description?'
        },
    },
    deliveryInfo: {

        title: {
            fr: (currentForm) => {
                switch(currentForm) {
                    case 'spa':
                    case 'ac':
                    case 'ab':
                    case 'acautre':
                    case 'acmesure':
                    case 'meuble':
                    case 'meubleautre':
                        return 'CONTACT 1 HEURE AVANT LE RENDEZ-VOUS';
                    case 'cr':
                        return 'CONFIRMATION DE LA DATE DE LIVRAISON';
                    default:
                        return 'CONFIRMATION DE LA DATE DE LIVRAISON';
                }
            },
            en: (currentForm) => {
                switch(currentForm) {
                    case 'spa':
                    case 'ac':
                    case 'ab':
                    case 'acautre':
                    case 'acmesure':
                    case 'meuble':
                    case 'meubleautre':
                        return 'CONTACT 1 HOUR BEFORE THE APPOINTMENT';
                    case 'cr':
                        return 'DELIVERY DATE CONFIRMATION';
                    default:
                        return 'DELIVERY DATE CONFIRMATION';
                }
            },
       },
        noIndoorDelivery: {
            fr: (currentForm) => {
                switch(currentForm) {
                    case 'ht':
                        return 'Veuillez prendre note qu\'aucune livraison ne s\'effectuera à l\'intérieur de la maison.';
                    case 'spa':
                        return 'Votre présence sera requise lors de la livraison. Les livraisons se font de 7 heures à 21 heures. Nous pouvons vous contacter environ 1 heure avant le rendez-vous si vous le désirez.';
                    case 'ac':
                    case 'acautre':
                        return 'Votre présence n\'est pas requise pour ce rendez-vous. Par contre, s\il y a un montant dû vous devez être présent. Nous pouvons vous contacter environ 1 heure avant le rendez-vous si vous le désirez.';
                    case 'acmesure':
                        return 'Votre présence n\'est pas requise pour lors de la prise de mesure. Le technicien se déplace entre 7 heures et 21 heures. Cependant, nous pouvons vous contacter environ 1 heure avant le rendez-vous si vous désirez être présent.';
                    case 'ab':
                        return 'Votre présence n\'est pas requise pour lors de la livraison. Les livraisons se font entre 7 heures et 21 heures. Cependant, nous pouvons vous contacter environ 1 heure avant le rendez-vous si vous désirez être présent.';
                    case 'meuble':
                        return 'Votre présence n\'est pas requise. Les livraisons se font de 7 heures à 21 heures. Dans le cas où vous désirez être présent, nous pouvons vous contacter environ 1 heure avant le rendez-vous.'
                    case 'meubleautre':
                        return 'Votre présence est requise pour déterminer l\'endroit exact ou le gazébo doit être installé. Nous pouvons vous contacter environ 1 heure avant le rendez-vous si vous le désirez.'
                    default : 
                        return ''
                    }
            },
            en: (currentForm) => {
                switch(currentForm) {

                    case 'ht':
                        return 'Please note that we will not deliver inside your home.';
                    case 'spa':
                        return 'Your presence is required during the delivery. The technician will arrive between 7am and 9pm. However, we can contact you approximately 1 hour before the appointment if you wish to be present.';
                    case 'ac':
                    case 'acautre':
                        return 'Your presence is not required during the measuring. However if there is an amount due you must be present. We can contact you approximately 1 hour before the appointment if you wish to be present.';
                    case 'acmesure':
                        return 'Your presence is not required during the measuring. The technician will arrive between 7am and 9pm. However, we can contact you approximately 1 hour before the appointment if you wish to be present.';
                    case 'ab':
                        return 'Your presence is not required during the delivery. Deliveries are made between 7 a.m. and 9 p.m. However, we can contact you approximately 1 hour before the appointment if you wish to be present.';
                    case 'meuble':
                        return 'Your presence is not required during the delivery. The deliveries are made between 7am and 9pm. However, we can contact you approximately 1 hour before the appointment if you wish to be present.'
                    case 'meubleautre':
                        return 'Your presence is required to determine the exact location of the installed gazebo. We can contact you approximately 1 hour before the appointment if you wish.'
                    default : 
                        return ''
                }
            },
         },
        appointmentPrefix: {

            fr: (currentForm) => {
                switch(currentForm) {
                    case 'ht':
                    case 'ab':
                    case 'meuble':
                        return `Votre rendez-vous de livraison est cédulé pour le ${this.appointmentDate} .`;
                    case 'spa':
                    case 'ac':
                        return `Votre rendez-vous de livraison et d\'installation est cédulé pour le ${this.appointmentDate} .`;
                    case 'cr':
                        return `Nous sommes disponible pour livrer les matériaux de la piscine le ${this.appointmentDate} .`;
                    case 'meubleautre':
                        return `Veuillez s.v.p confimer le rendez-vous de l'installation cédulé pour le ${this.appointmentDate} .`;
                     default:
                        return '';
                }
            },
            en: (currentForm) => {
                switch(currentForm) {
                    case 'ht':
                    case 'ab':
                    case 'meuble':
                        return `Your delivery appointment is scheduled for ${this.appointmentDate} .`;
                    case 'spa':
                    case 'ac':
                        return `Your delivery and installation appointment is scheduled for ${this.appointmentDate} .`;
                    case 'cr':
                        return `We are available to deliver the pool materials on ${this.appointmentDate} .`;
                    case 'meubleautre':
                        return `Please confirm your installation appointment is scheduled for ${this.appointmentDate} .`;
                    default:
                        return '';
                }
            },

          
        },
        confirmInstructions: {
            fr: (currentForm) => {
                switch(currentForm) {
                    case 'ht':
                       return 'Veuillez confirmer les informations ci-dessous et accepter le rendez-vous afin que ce dernier soit honoré (8 jours) avant la date en question.';
                    case 'cr':
                       return 'Un rappel pour la livraison sera effectué 2 jours avant la date confirmée. Il nous est impossible de vous donner une plage horaire (en raison de la circulation qui est imprévisible et du temps de chacune des livraison).';
                    default:
                        return '';
                }
            },
            en: (currentForm) => {
                switch(currentForm) {
                    case 'ht':
                        return 'Please confirm ( 8 days ) minimum prior to the date in order for us to honor this appointment.';    
                    case 'cr':
                        return 'A reminder for delivery will be made 2 days before the confirmed date. It is impossible for us to give you a time slot (due to unpredictable traffic and the time of each delivery).';    
                    default:
                         return '';
                }
            },

      },
        presenceInfo: {
            fr: (currentForm) => {
                switch(currentForm) {
                    case 'ht':
                        return 'Votre présence n\'est pas requise. Les livraisons se font de 7h00 à 20h00. Nous pouvons vous contacter environ 1 heure avant le rendez-vous.';
                    case 'cr':
                        return 'Le Livreur vous avisera lorsqu’il sera en route vers votre domicile.';
                    default:
                       return '';
                    }
            },
            en: (currentForm) => {
                switch(currentForm) {
                    case 'ht':
                        return 'Your presence is not required during the delivery. The deliveries are made between 7am and 8pm. However, we can contact you approximately 1 hour before the appointment if you wish to be present.';
                    case 'cr':
                        return 'The delivery person will notify you when he will be on his way to your home.';
                    default:
                        return '';
                        
                }
            },
      },
        contactCheckbox: {
            fr: 'Oui je désire être contacté',
            en: 'Yes, I want to be contacted'
        },
        phoneNumber: {
            current: {
                fr: 'Le numéro de téléphone que nous avons dans nos dossiers est le suivant:',
                en: 'The phone number we have on file is:'
            },
            change: {
                fr: 'Changer le numéro de téléphone auquel vous voulez être joint:',
                en: 'The telephone number that we have in our records is the following:'
            },
            placeholder: {
                fr: 'numéro de téléphone',
                en: 'telephone number'
            }
        },

        psStatement: {
            fr: (currentForm) => {
                switch(currentForm) {
                    case 'spa':
                        return 'P.S: Si vous n\'utilisez pas votre spa rapidement suite à sa livraison, il est important que vous le protégiez avec une toile hydrofuge. En hiver, vous devez vous assurer de retirer la neige qui s\'accumule sur le spa.';
                     default:
                        return '';
                }
            },
            en: (currentForm) => {
                switch(currentForm) {
                    case 'spa':
                        return 'P.S: If you do not use your spa soon after delivery, it is important that you protect it with a waterproof tarp or spa cover cap. In the winter you should make sure to remove the snow that accumulates on the spa.';
                     default:
                        return '';
                }
            },
    }},
    footer: {
        buttons: {
            accept: {
                fr: 'J\'accepte le rendez-vous',
                en: 'I accept this appointment'
            },
            refuse: {
                fr: 'Je refuse le rendez-vous',
                en: 'I decline this appointment'
            },
            confirmationTitle: {
                fr: 'Confirmation Requise',
                en: 'Confirmation Required'
            },
            confirmationMessage: {
                fr: 'Êtes-vous sûr de vouloir continuer avec ce rendez-vous ?',
                en: 'Are you sure you want to proceed with this appointment?'
            },
            refuseTitle: {
                fr: 'Refus de Rendez-vous',
                en: 'Appointment Refusal'
            },
            refuseMessage: {
                fr: 'Êtes-vous sûr de vouloir refuser ce rendez-vous ?',
                en: 'Are you sure you want to decline this appointment?'
            },
            confirm: {
                fr: 'Confirmer',
                en: 'Confirm'
            },
            cancel: {
                fr: 'Annuler',
                en: 'Cancel'
            }
             
        },
        contact: {
            intro: {
                fr: 'Pour toutes questions ou commentaires, vous pouvez nous rejoindre à',
                en: 'You can reach us by email at'
            },
            or: {
                fr: 'ou à partir du',
                en: 'or through our'
            },
            helpCenter: {
                fr: 'Centre d\'aide',
                en: 'Help Center'
            }
        }
    },

     endingPage:{
        thankyouTitle:{
            fr:'Merci',
            en:'Thank you',
        },
        thankyouMessage:{
            fr:'Votre rendez-vous a été confirmé avec succès.',
            en:'Your appointment has been successfully confirmed.',
        },

        declineTitle:{
            fr:'Merci pour votre mise à jour',
            en:'Thank you for providing the updates.',
        },
        declineSubtitle:{
            fr:'Votre rendez-vous doit être replanifier.',
            en:'Your appointment requires rescheduling.',
        },
        declineMessage:{
            fr:'L\'équipe Trevi vous contactera pour planifier un nouveau rendez-vous.',
            en:'Trevi Team will contact you to arrange a new appointment.',
        },
        invalidTitle:{
            fr:'Lien non valide',
            en:'Invalid link',
        },
        invalidMessage:{
            fr:'Le lien n\'est plus valide ou a expiré.',
            en:'The link is no longer valid or has expired.',
        },
    },

}
   
}