import { LightningElement, api, track, wire } from 'lwc';
import getRelatedLogEntries from '@salesforce/apex/RelatedLogEntriesController.getRelatedLogEntries';
export default class RelatedLogEntries extends LightningElement {
    @api recordId;
    @api fieldSetName;
    @api sortBy = '';
    @api sortDirection = '';
    @api rowLimit;
    @api search = '';

    @track showComponent = false;
    @track title;
    @track logEntryResult;

    @api
    handleSort(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
    }

    @api
    handleSearchChange(event) {
        this.search = event.target.value;
    }

    @wire(getRelatedLogEntries, { recordId: '$recordId', fieldSetName: '$fieldSetName', rowLimit: '$rowLimit', sortByFieldName: '$sortBy', sortDirection: '$sortDirection', search: '$search'})
    wiredLogEntries(result) {
        console.info('result of getRelatedLogEntries');
        console.info(result);

        if (result.data) {
            let logEntryResult = this.processResult(result.data);

            this.logEntryResult = logEntryResult;
            this.showComponent = logEntryResult.isAccessible;
            this.title = logEntryResult.labelPlural + ' (' + logEntryResult.totalLogEntriesCount + ' Total)'
        } else if (result.error) {
            this.logEntryData = undefined;
            this.logEntryColumns = undefined;
            console.log(result.error);
        }
    }

    processResult(logEntryResult) {
        if(logEntryResult.fieldSet == undefined) {
            return;
        }

        logEntryResult = Object.assign({}, logEntryResult); // clone logEntryResult

        let fieldSet = Object.assign({}, logEntryResult.fieldSet); // clone fieldSet
        let fields = [].concat(logEntryResult.fieldSet.fields); // clone fields
        let records = [].concat(logEntryResult.records); // clone records
        console.info('cloned records');
        console.info(records);

        for(let i = 0; i < fieldSet.fields.length; i++) {
            let field = Object.assign({}, fieldSet.fields[i]); // clone field

            if(field.type == 'datetime') {
                field.type = 'date';
                // FIXME and make dynamic based on user prefences for datetimes
                let typeAttributes = {
                    month: '2-digit',
                    day: '2-digit',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                }
            } else if(field.type == 'reference') {
                let originalFieldName = field.fieldName;
                let displayFieldName = field.lookupDisplayFieldName.replace('.', '');
console.info('originalFieldName==' + originalFieldName);
console.info('displayFieldName==' + displayFieldName);
                // Add URL formatting to the field
                field.fieldName = field.fieldName + 'Link';
                field.type = 'url';
                field.typeAttributes = {
                    label: {fieldName: displayFieldName},
                    name: {fieldName: originalFieldName},
                    target: '_self'
                };

                // Add the link to each log entry record
                for (var j = 0; j < records.length; j++) {
                    let record = Object.assign({}, records[j]); //cloning object
                    record[field.fieldName] = '/' + record[originalFieldName];

                    let parentObject = record[field.relationshipName];
                    console.info('parentObject');
                    console.info(parentObject);
                    record[displayFieldName] = parentObject[field.lookupDisplayFieldName.split('.').splice(1)];

                    records[j] = record;
                }
            } else if(field.isNameField) {
                let originalFieldName = field.fieldName;

                // Add URL formatting to the field
                field.fieldName = field.fieldName + 'Link';
                field.type = 'url';
                field.typeAttributes = {
                    label: {fieldName: originalFieldName},
                    name: {fieldName: 'Id'},
                    target: '_self'
                };

                // Add the link to each log entry record
                for (var j = 0; j < records.length; j++) {
                    let record = Object.assign({}, records[j]); //cloning object
                    record[field.fieldName] = '/' + record.Id;

                    records[j] = record;
                }
            }

            fields[i] = field;
        }

        fieldSet.fields = fields;

        logEntryResult.fieldSet = fieldSet;
        logEntryResult.records = records;

        console.info('final version of logEntryResult');
        console.info(logEntryResult);

        return logEntryResult;
    }
}
