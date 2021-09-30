import { LightningElement } from 'lwc';
import getLoggingLevelOptions from '@salesforce/apex/LoggerConfiguratorController.getLoggingLevelOptions';
import getShareAccessLevelOptions from '@salesforce/apex/LoggerConfiguratorController.getShareAccessLevelOptions';
import getSettings from '@salesforce/apex/LoggerConfiguratorController.getSettings';
import getParameters from '@salesforce/apex/LoggerConfiguratorController.getParameters';
// import saveSettings from '@salesforce/apex/LoggerConfiguratorController.saveSettings';

const columns = [
    // { label: 'Id', fieldName: 'Id', type: 'text' },
    { label: 'SetupOwnerId', fieldName: 'SetupOwnerId', type: 'text' },
    // { label: 'SetupOwner.Name', fieldName: 'SetupOwner.Name', type: 'text' },
    // { label: 'SetupOwner.Type', fieldName: 'SetupOwner.Type', type: 'text' },
    { label: 'Location', fieldName: 'SetupOwnerType', type: 'text' },
    { label: 'Setup Owner', fieldName: 'SetupOwnerName', type: 'text' },
    { label: 'Is Enabled', fieldName: 'IsEnabled__c', type: 'text' },
    { label: 'Logging Level', fieldName: 'LoggingLevel__c', type: 'text' },
    { label: 'Enable System Messages', fieldName: 'EnableSystemMessages__c', type: 'text' },
    { label: 'Save Method', fieldName: 'DefaultSaveMethod__c', type: 'text' },
    { label: 'Log Share Level', fieldName: 'DefaultLogShareAccessLevel__c', type: 'text' }
];

export default class LoggerConfigurator extends LightningElement {
    records;
    columns = columns;

    parameterRecords;

    _loggingLevelOptions;
    _shareAccessLevelOptions;

    get title() {
        return 'Logger Configurator';
    }

    get settingsTitle() {
        return 'Logger Settings';
    }

    connectedCallback() {
        document.title = this.title;

        getParameters().then(result => {
            console.log('getParameters() result==' + JSON.stringify(result));
            this.parameterRecords = result;
            this.parametersLoaded = true;
        });

        getLoggingLevelOptions().then(result => {
            console.log('getLoggingLevelOptions() result==' + JSON.stringify(result));
            this._loggingLevelOptions = result;
        });
        // .catch(error => {
        //     // TODO error handling
        // });

        getShareAccessLevelOptions().then(result => {
            console.log('getShareAccessLevelOptions() result==' + JSON.stringify(result));
            this._shareAccessLevelOptions = result;
        });
        // .catch(error => {
        //     // TODO error handling
        // });

        getSettings().then(result => {
            console.log('getSettings() result==' + JSON.stringify(result));
            console.log('getSettings() result.length==' + result.length);
            for (let i = 0; i < result.length; i++) {
                let record = result[i];
                record.SetupOwnerName = record.SetupOwner.Name;

                let setupOwnerType;
                switch (record.SetupOwner.Type) {
                    case '00D':
                        setupOwnerType = 'Organization';
                        break;
                    case '00e':
                        setupOwnerType = 'Profile';
                        break;
                    default:
                        setupOwnerType = record.SetupOwner.Type;
                }
                record.SetupOwnerType = setupOwnerType;
                console.log(record);
                result[i] = record;
            }
            this.records = result;
            console.log('this.records==' + JSON.stringify(this.records));
        });
        // .catch(error => {
        //     // TODO error handling
        // });
    }
}
