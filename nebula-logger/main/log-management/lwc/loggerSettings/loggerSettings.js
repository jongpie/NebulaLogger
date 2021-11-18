import { LightningElement } from 'lwc';
import getLoggingLevelOptions from '@salesforce/apex/LoggerSettingsController.getLoggingLevelOptions';
import getShareAccessLevelOptions from '@salesforce/apex/LoggerSettingsController.getShareAccessLevelOptions';
import getSettings from '@salesforce/apex/LoggerSettingsController.getSettings';
// import saveSettings from '@salesforce/apex/LoggerSettingsController.saveSettings';

const columns = [
    // { label: 'Id', fieldName: 'Id', type: 'text' },
    // { label: 'SetupOwnerId', fieldName: 'SetupOwnerId', type: 'text' },
    { label: 'Location', fieldName: 'SetupOwnerType', type: 'text' },
    { label: 'Setup Owner', fieldName: 'SetupOwnerName', type: 'text' },
    { label: 'Is Enabled', fieldName: 'IsEnabled__c', type: 'boolean' },
    { label: 'IsApexSystemDebugLoggingEnabled', fieldName: 'IsApexSystemDebugLoggingEnabled__c', type: 'boolean' },
    { label: 'IsComponentConsoleLoggingEnabled', fieldName: 'IsComponentConsoleLoggingEnabled__c', type: 'boolean' },
    { label: 'Logging Level', fieldName: 'LoggingLevel__c', type: 'text' },
    { label: 'ApplyDataMaskRules', fieldName: 'ApplyDataMaskRules__c', type: 'boolean' },
    { label: 'StripInaccessibleRecordFields', fieldName: 'StripInaccessibleRecordFields__c', type: 'boolean' },
    { label: 'AnonymousMode', fieldName: 'AnonymousMode__c', type: 'boolean' },
    // { label: 'Enable System Messages', fieldName: 'EnableSystemMessages__c', type: 'text' },
    { label: 'Save Method', fieldName: 'DefaultSaveMethod__c', type: 'text' },
    { label: 'Log Share Level', fieldName: 'DefaultLogShareAccessLevel__c', type: 'text' }
];

export default class LoggerSettings extends LightningElement {
    title = "Logger Settings";
    records;
    columns = columns;

    _loggingLevelOptions;
    _shareAccessLevelOptions;

    connectedCallback() {
        document.title = this.title;
        getLoggingLevelOptions()
            .then(result => {
                console.log('getLoggingLevelOptions() result==' + JSON.stringify(result));
                this._loggingLevelOptions = result;
            });
            // .catch(error => {
            //     // TODO error handling
            // });

        getShareAccessLevelOptions()
            .then(result => {
                console.log('getShareAccessLevelOptions() result==' + JSON.stringify(result));
                this._shareAccessLevelOptions = result;
            });
            // .catch(error => {
            //     // TODO error handling
            // });

        getSettings()
            .then(result => {
                console.log('getSettings() result==' + JSON.stringify(result));
                this.records = result;
                for (let i = 0; i < this.records.size; i++) {
                    let record = this.records[i];
                    record.SetupOwnerType = 'test';
                    this.records[i] = record;
                }
                console.log('this.records==' + JSON.stringify(this.records));
            });
            // .catch(error => {
            //     // TODO error handling
            // });
    }
}
