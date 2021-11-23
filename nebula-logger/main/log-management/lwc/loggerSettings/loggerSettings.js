// UI
import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Security access
import canManageLoggerSettings from '@salesforce/customPermission/CanManageLoggerSettings';

// LoggerSettings__c metadata
import LOGGER_SETTINGS_OBJECT from '@salesforce/schema/LoggerSettings__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

// Apex controller actions
import getLoggingLevelOptions from '@salesforce/apex/LoggerSettingsController.getLoggingLevelOptions';
import getShareAccessLevelOptions from '@salesforce/apex/LoggerSettingsController.getShareAccessLevelOptions';
import getSaveMethodOptions from '@salesforce/apex/LoggerSettingsController.getSaveMethodOptions';
import getSettings from '@salesforce/apex/LoggerSettingsController.getSettings';
import saveRecord from '@salesforce/apex/LoggerSettingsController.saveRecord';
import deleteRecord from '@salesforce/apex/LoggerSettingsController.deleteRecord';

const TABLE_ROW_ACTIONS = [
    { label: 'View', name: 'view' },
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];

// TODO move columns to a function, use getObjectInfo to retrieve labels & field type
const TABLE_COLUMNS = [
    // { label: 'Id', fieldName: 'Id', type: 'text' },
    // { label: 'SetupOwnerId', fieldName: 'SetupOwnerId', type: 'text' },
    { label: 'Setup Location', fieldName: 'SetupOwnerType', type: 'text' },
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
    { label: 'Days to Retain Logs', fieldName: 'DefaultNumberOfDaysToRetainLogs__c', type: 'number' },
    {
        type: 'action',
        typeAttributes: {
            rowActions: TABLE_ROW_ACTIONS,
            menuAlignment: 'right'
        }
    }
];

export default class LoggerSettings extends LightningElement {
    title = 'Logger Settings';
    records;
    columns = TABLE_COLUMNS;

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

    // Picklist options
    loggingLevelOptions;
    saveMethodOptions;
    shareAccessLevelOptions;

    // Object & field metadata
    _fields;

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

        this.loadSettingsRecords();
        // .catch(error => {
        //     // TODO error handling
        // });
    }

    @wire(getObjectInfo, { objectApiName: LOGGER_SETTINGS_OBJECT })
    oppInfo({ data, error }) {
        if (data) {
            this._fields = data.fields;
        }
    }

    // Access control getters
    get canManageLoggerSettings() {
        return canManageLoggerSettings;
    }

    get noAccessError() {
        return 'You do not have access to manage ' + this.title;
    }

    // Field metadata getters
    get defaultNumberOfDaysToRetainLogsFieldHelpText() {
        return this._fields.DefaultNumberOfDaysToRetainLogs__c.inlineHelpText;
    }

    get defaultNumberOfDaysToRetainLogsFieldLabel() {
        return this._fields.DefaultNumberOfDaysToRetainLogs__c.label;
    }

    get isEnabledFieldHelpText() {
        return this._fields.IsEnabled__c.inlineHelpText;
    }

    get isEnabledFieldLabel() {
        return this._fields.IsEnabled__c.label;
    }

    get loggingLevelFieldHelpText() {
        return this._fields.LoggingLevel__c.inlineHelpText;
    }

    get loggingLevelFieldLabel() {
        return this._fields.LoggingLevel__c.label;
    }

    loadSettingsRecords() {
        this.showLoadingSpinner = true;
        getSettings().then(results => {
            console.log('getSettings() results==' + JSON.stringify(results));
            let settingsRecordInfos = [].concat(results);
            console.log('getSettings() results length==' + settingsRecordInfos.length);
            console.log('settingsRecordInfos==', settingsRecordInfos);
            const settingsRecords = [];
            for (let i = 0; i < results.length; i++) {
                let record = results[i].Record;
                record.SetupOwnerType = results[i].SetupOwnerType;
                record.SetupOwnerName = results[i].SetupOwnerName;
                // this.records[i] = record;

                settingsRecords.push(record);
            }
            console.log('final settings records==', settingsRecords);
            this.records = settingsRecords;
            // this.records = result;
            // for (let i = 0; i < this.records.size; i++) {
            //     let record = this.records[i];
            //     record.SetupOwnerType = 'test';
            //     // this.records[i] = record;
            // }
            console.log('this.records==' + JSON.stringify(this.records));
            this.showLoadingSpinner = false;
        });
    }

    handleRowActions(event) {
        let actionName = event.detail.action.name;
        console.log('actionName ====> ' + actionName);

        let row = event.detail.row;
        console.log('row ====> ' + row);
        switch (actionName) {
            case 'view':
                this.viewCurrentRecord(row);
                break;
            case 'edit':
                this.editCurrentRecord(row);
                break;
            case 'delete':
                this.deleteSettingsRecord(row);
                break;
            default:
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

    createNewRecord() {
        alert('TODO');
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
        saveRecord({ settingsRecord: this.currentRecord }).then(result => {
            console.log('result ====> ', result);
            this.records = result;
            this.showLoadingSpinner = false;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Logger Settings record for zeee' + event.detail.fields.SetupOwnerName + ' successfully saved',
                    variant: 'success'
                })
            );
        });

        this.closeModal();
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
                        title: 'Logger Settings record for ' + currentRow.SetupOwnerName + ' successfully deleted',
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
