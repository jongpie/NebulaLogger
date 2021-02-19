import { LightningElement, api, track, wire } from 'lwc';
import getFieldSetMetadata from '@salesforce/apex/RelatedLogEntriesController.getFieldSetMetadata';
import getRelatedLogEntries from '@salesforce/apex/RelatedLogEntriesController.getRelatedLogEntries';
import timestampField from '@salesforce/schema/LogEntry__c.Timestamp__c';
export default class RelatedLogEntries extends LightningElement {
    @api recordId;
    @api fieldSetName;
    @api sortBy = timestampField;
    @api sortDirection = 'DESC';
    @api rowLimit;

    @track tableData = [];
    @track tableColumns;

    @api
    handleSort(event) {
        let fieldName = event.detail.fieldName;
        let sortDirection = event.detail.sortDirection;
        //assign the values
        this.sortBy = fieldName;
        this.sortDirection = sortDirection;
        //call the custom sort method.
        //this.sortData(fieldName, sortDirection);
    }

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

    @wire(getRelatedLogEntries, { recordId: '$recordId', fieldSetName: '$fieldSetName', sortByFieldName: '$sortBy', sortDirection: '$sortDirection', rowLimit: '$rowLimit'})
    wiredLogEntries(result) {
        if (result.data) {
            this.tableData = result.data;
        } else if (result.error) {
            this.tableData = undefined;
            console.log(result.error);
        }
    }
}
