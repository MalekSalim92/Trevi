import { LightningElement, api, wire, track } from 'lwc'; 
import getUserInfo from '@salesforce/apex/UserProfileController.getUserInfo'; 
import saveUserInfo from '@salesforce/apex/UserProfileController.saveUserInfo'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 
import FirstName from '@salesforce/schema/Contact.FirstName';

export default class UserProfile extends LightningElement {
    @track user; 
    @track Contact = {};
    @track Account = {};
    @track originalUser;
    @track originalAccount;
    @track originalContact;
    @track isEditMode = false; 
    @track NoEditMode = true; 
    @api recordId; 
    @track languageOptions = [
        { label: 'English', value: 'en_US' },
        { label: 'French', value: 'fr' }
    ];

    @wire(getUserInfo, { userId: '$recordId' }) 
    wiredUser({ error, data }) { 
        if (data) { 
           
            this.user = data; 
            this.Account=this.user.Account; 
            this.Contact=this.user.Contact; 
           
            this.originalUser = JSON.parse(JSON.stringify(data)); 
            this.originalAccount = JSON.parse(JSON.stringify(this.user.Account)); 
            this.originalContact = JSON.parse(JSON.stringify(this.user.Contact)); 
        } else if (error) { 
            this.showToast('Error', error.body.message, 'error'); 
        } 
    } 

    handleEdit() { 
        this.isEditMode = true; 
        this.NoEditMode = false; 
    } 

    handleSave() { 

        if (this.Contact.HasOptedOutOfEmail && this.Contact.DoNotCall) {
            this.showToast('Error', 'You cannot select both Do Not Call and Do Not Email.', 'error');
            return; // Prevent further execution
        }
        saveUserInfo({ user: this.user , Account: this.Account, Contact: this.Contact})
            .then(() => { 
                this.showToast('Success', 'User information updated successfully', 'success'); 
                this.isEditMode = false; 
                this.NoEditMode = true; 
                this.originalUser = JSON.parse(JSON.stringify(this.user)); 
                this.originalAccount = JSON.parse(JSON.stringify(this.Account)); 
                this.originalContact = JSON.parse(JSON.stringify(this.Contact)); 
            })
            .catch(error => { 
                this.showToast('Error', error.body.message, 'error'); 
            }); 
    } 

    handleCancel() { 
        this.user = JSON.parse(JSON.stringify(this.originalUser)); 
        this.Account = JSON.parse(JSON.stringify(this.originalAccount)); 
        this.Contact = JSON.parse(JSON.stringify(this.originalContact)); 
        console.log(JSON.stringify(this.user)); 
        this.isEditMode = false; 
        this.NoEditMode = true; 
    }

  
    handleChange(event) { 
      console.log(event.target.checked);
        const field = event.target.name; 
        const fieldName = field.split('.')[1];
        
        if (field.startsWith('Contact.')) { 
            if(event.target.type === 'checkbox') 
                this.Contact = { ...this.Contact, [fieldName]: event.target.checked };
           else  this.Contact = { ...this.Contact, [fieldName]: event.target.value };
        } else if (field.startsWith('user.')) {
           
           this.user = { ...this.user, [fieldName]: event.target.value };
        }
         else if (field.startsWith('Account.')) {
        this.Account = { ...this.Account, [fieldName]: event.target.value };
    
        }
       
        
    } 
    
    showToast(title, message, variant) { 
        const event = new ShowToastEvent({ 
            title, 
            message, 
            variant 
        }); 
        this.dispatchEvent(event); 
    }
}