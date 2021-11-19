import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import canManageLoggerSettings from '@salesforce/customPermission/CanManageLoggerSettings';
import getLoggingLevelOptions from '@salesforce/apex/LoggerSettingsController.getLoggingLevelOptions';
import getShareAccessLevelOptions from '@salesforce/apex/LoggerSettingsController.getShareAccessLevelOptions';
import getSaveMethodOptions from '@salesforce/apex/LoggerSettingsController.getSaveMethodOptions';
import getSettings from '@salesforce/apex/LoggerSettingsController.getSettings';
import saveRecord from '@salesforce/apex/LoggerSettingsController.saveRecord';
import deleteRecord from '@salesforce/apex/LoggerSettingsController.deleteRecord';

// row actions
const actions = [
    { label: 'Record Details', name: 'record_details' },
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];

const columns = [
    // { label: 'Id', fieldName: 'Id', type: 'text' },
    { label: 'SetupOwnerId', fieldName: 'SetupOwnerId', type: 'text' },
    { label: 'Location', fieldName: 'SetupOwnerType', type: 'text' },
    { label: 'Setup Owner', fieldName: 'SetupOwnerName', type: 'text' },
    { label: 'Is Enabled', fieldName: 'IsEnabled__c', type: 'boolean' },
    // { label: 'IsApexSystemDebugLoggingEnabled', fieldName: 'IsApexSystemDebugLoggingEnabled__c', type: 'boolean' },
    // { label: 'IsComponentConsoleLoggingEnabled', fieldName: 'IsComponentConsoleLoggingEnabled__c', type: 'boolean' },
    { label: 'Logging Level', fieldName: 'LoggingLevel__c', type: 'text' },
    { label: 'Apply Data Mask Rules', fieldName: 'ApplyDataMaskRules__c', type: 'boolean' },
    // { label: 'StripInaccessibleRecordFields', fieldName: 'StripInaccessibleRecordFields__c', type: 'boolean' },
    // { label: 'AnonymousMode', fieldName: 'AnonymousMode__c', type: 'boolean' },
    // { label: 'Enable System Messages', fieldName: 'EnableSystemMessages__c', type: 'text' },
    { label: 'Save Method', fieldName: 'DefaultSaveMethod__c', type: 'text' },
    { label: 'Log Share Level', fieldName: 'DefaultLogShareAccessLevel__c', type: 'text' },
    {
        type: 'action',
        typeAttributes: {
            rowActions: actions,
            menuAlignment: 'right'
        }
    }
];

export default class LoggerSettings extends LightningElement {
    title = 'Logger Settings';
    records;
    columns = columns;

    // TODO cleanup
    data;
    // columns = columns;
    record = [];
    showModal = false;
    currentRecordId;
    currentRecord;
    isReadOnlyMode = true;
    showLoadingSpinner = false;
    // END TODO cleanup

    loggingLevelOptions;
    saveMethodOptions;
    shareAccessLevelOptions;

    connectedCallback() {
        document.title = this.title;
        getLoggingLevelOptions().then(result => {
            console.log('getLoggingLevelOptions() result==' + JSON.stringify(result));
            this.loggingLevelOptions = result;
        });
        // .catch(error => {
        //     // TODO error handling
        // });

        getSaveMethodOptions().then(result => {
            console.log('getSaveMethodOptions() result==' + JSON.stringify(result));
            this.saveMethodOptions = result;
        });
        // .catch(error => {
        //     // TODO error handling
        // });

        getShareAccessLevelOptions().then(result => {
            console.log('getShareAccessLevelOptions() result==' + JSON.stringify(result));
            this.shareAccessLevelOptions = result;
        });
        // .catch(error => {
        //     // TODO error handling
        // });

        getSettings().then(result => {
            console.log('getSettings() result==' + JSON.stringify(result));
            this.records = result;
            for (let i = 0; i < this.records.size; i++) {
                let record = this.records[i];
                record.SetupOwnerType = 'test';
                // this.records[i] = record;
            }
            console.log('this.records==' + JSON.stringify(this.records));
        });
        // .catch(error => {
        //     // TODO error handling
        // });
    }

    handleRowActions(event) {
        let actionName = event.detail.action.name;

        window.console.log('actionName ====> ' + actionName);

        let row = event.detail.row;

        window.console.log('row ====> ' + row);
        // eslint-disable-next-line default-case
        switch (actionName) {
            case 'record_details':
                this.viewCurrentRecord(row);
                break;
            case 'edit':
                this.editCurrentRecord(row);
                break;
            case 'delete':
                this.deleteSettingsRecord(row);
                break;
        }
    }

    handleModalKeyDown(event) {
        console.log('event.code==' + event.code);
        if (event.code === 'Escape') {
            // this.openModal = false;
            // event.preventDefault();
            // event.stopImmediatePropagation();
            this.closeModal();
        }
    }

    // TODO cleanup
    // closing modal box
    closeModal() {
        this.showModal = false;
    }

    viewCurrentRecord(currentRow) {
        this.showModal = true;
        this.isReadOnlyMode = true;
        this.record = currentRow;
    }

    editCurrentRecord(currentRow) {
        this.showModal = true;
        this.isReadOnlyMode = false;
        this.currentRecordId = currentRow.Id;
        this.currentRecord = currentRow;
    }

    saveRecord(event) {
        console.log('saveRecord event', event);
        console.log('saveRecord currentRecordId', this.currentRecordId);
        // prevending default type sumbit of record edit form
        // event.preventDefault();

        // // querying the record edit form and submiting fields to form
        // this.template.querySelector('lightning-record-edit-form').submit(event.detail.fields);
        saveRecord({ settingsRecord: this.currentRecord })
        .then(result => {
            console.log('result ====> ', result);
            this.records = result;
            this.showLoadingSpinner = false;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Logger Settings record deleted',
                    variant: 'success'
                })
            );

        });

        this.closeModal();

        // showing success message
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success!!',
                message: event.detail.fields.FirstName + ' ' + event.detail.fields.LastName + ' Contact updated Successfully!!.',
                variant: 'success'
            })
        );
    }

    deleteSettingsRecord(currentRow) {
        console.log('currentRow==', JSON.parse(JSON.stringify(currentRow)));
        deleteRecord({ settingsRecord: currentRow })
            .then(result => {
                console.log('result ====> ', result);
                this.records = result;
                this.showLoadingSpinner = false;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Logger Settings record deleted',
                        variant: 'success'
                    })
                );

            })
            .catch(error => {
                console.log('Error ====> ' + error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!!',
                        message: error.message,
                        variant: 'error'
                    })
                );
            });
    }
    // END TODO cleanup
}
