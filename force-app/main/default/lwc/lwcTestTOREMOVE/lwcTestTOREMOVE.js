import { LightningElement } from 'lwc';
import process from '@salesforce/apex/test.process';

export default class LwcTestTOREMOVE extends LightningElement {


        processButton(){
            console.log('button clicked')
            process()
            .then(result => {
                
                 console.log('resut ---- ', result );
    
            })
            .catch(error => {
                console.error('Error publishing registration event:', error);
            });
    }
    
}