import { LightningElement, api, track, wire } from 'lwc';
import getFieldSetMetadata from '@salesforce/apex/RelatedLogEntriesController.getFieldSetMetadata';
import getRelatedLogEntries from '@salesforce/apex/RelatedLogEntriesController.getRelatedLogEntries';

export default class RelatedLogEntries extends LightningElement {
    @api recordId;
    @api fieldSetName;
    @api rowLimit;

    @track tableData = [];
    @track tableColumns;

    @wire(getFieldSetMetadata, { fieldSetName: '$fieldSetName' })
    wiredFieldSetMetadata(result) {
        //alert('result of getFieldSetMetadata');
        console.info('result of getFieldSetMetadata');
        console.info(result);

        if (result.data) {
            this.tableColumns = result.data.fields;
        } else if (result.error) {
            this.tableColumns = undefined;
            console.log(result.error);
        }
    }

    @wire(getRelatedLogEntries, { recordId: '$recordId', fieldSetName: '$fieldSetName', rowLimit: '$rowLimit'})
    wiredLogEntries(result) {
        if (result.data) {
            this.tableData = result.data;
        } else if (result.error) {
            this.tableData = undefined;
            console.log(result.error);
        }
    }
}
