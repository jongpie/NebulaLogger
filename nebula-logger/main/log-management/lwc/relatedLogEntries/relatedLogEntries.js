import { LightningElement, api, track, wire } from 'lwc';
import getRelatedLogEntries from '@salesforce/apex/RelatedLogEntriesController.getRelatedLogEntries';
export default class RelatedLogEntries extends LightningElement {
    @api recordId;
    @api fieldSetName;
    @api sortBy = 'Timestamp__c';
    @api sortDirection = 'DESC';
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
            this.title = logEntryResult.labelPlural + ' (' + logEntryResult.totalEntries + ' Total for This Record)'
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

        logEntryResult = Object.assign({}, logEntryResult); // clone fieldSet

        //var updatedFields = [];
        let fieldSet = Object.assign({}, logEntryResult.fieldSet); // clone fieldSet
        let fields = [];
        let records = [];//Object.assign({}, logEntryResult.records); // clone records
        //let records = Object.assign({}, logEntryResult.records); // clone records
        for(let i = 0; i < logEntryResult.fieldSet.fields.length; i++) {
            let field = Object.assign({}, logEntryResult.fieldSet.fields[i]); // clone field

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
                // TODO implement typeAttributes for lookup fields
                // let originalFieldName = field.fieldName;

                // field.fieldName = field.fieldName + 'Link';
                // field.type = 'url';
                // // TODO make sure this works
                // var updatedRecords = [];
                // for (var j = 0; j < logEntryResult.records.length; j++) {
                //     let tempRecord = Object.assign({}, logEntryResult.records[j]); //cloning object
                //     tempRecord[field.fieldName] = "/" + tempRecord[originalFieldName];

                //     updatedRecords.push(tempRecord);
                // }
                // console.log('updatedRecords');
                // console.log(updatedRecords);
                // // FIXME multiple loops on records loses previous loop's changes
                // //records = updatedRecords;

                // let typeAttributes = {};

                // let labelAttributes = {fieldName: field.displayFieldName};
                // typeAttributes.label = labelAttributes;

                // let nameAttributes = {fieldName: field.fieldName};
                // typeAttributes.name = nameAttributes;

                // //this.typeAttributes.put('label', 'Name');
                // typeAttributes.target = '_self';

                // field.typeAttributes = typeAttributes;
            }


            // FIXME convert apex to js
            if(field.isNameField) {
                //this.fieldName = 'Id';
                field.fieldName = 'recordLink';
                field.type = 'url';
                // TODO make sure this works
                var updatedRecords = [];
                for (var j = 0; j < logEntryResult.records.length; j++) {
                    let tempRecord = Object.assign({}, logEntryResult.records[j]); //cloning object
                    tempRecord.recordLink = "/" + tempRecord.Id;

                    updatedRecords.push(tempRecord);
                }
                console.log('updatedRecords');
                console.log(updatedRecords);
                records = updatedRecords;

                let typeAttributes = {};

                let labelAttributes = {fieldName: 'Name'};
                typeAttributes.label = labelAttributes;

                let nameAttributes = {fieldName: 'Id'};
                typeAttributes.name = nameAttributes;

                //this.typeAttributes.put('label', 'Name');
                typeAttributes.target = '_self';

                field.typeAttributes = typeAttributes;


            }

            fields.push(field);
        }

        fieldSet.fields = fields;

        console.info('final version of fieldSetMetadata');
        console.info(fieldSet);

        logEntryResult.fieldSet = fieldSet;
        logEntryResult.records = records;

        console.info('final version of logEntryResult');
        console.info(logEntryResult);

        return logEntryResult;
    }
}
