import { LightningElement } from 'lwc';
import canEditLoggerParameters from '@salesforce/customPermission/CanEditLoggerParameters';
import canEditLoggerSettings from '@salesforce/customPermission/CanEditLoggerSettings';
import getLoggingLevelOptions from '@salesforce/apex/LoggerConfiguratorController.getLoggingLevelOptions';
import getShareAccessLevelOptions from '@salesforce/apex/LoggerConfiguratorController.getShareAccessLevelOptions';
import getSettings from '@salesforce/apex/LoggerConfiguratorController.getSettings';
import getParameters from '@salesforce/apex/LoggerConfiguratorController.getParameters';
import getDataMaskRules from '@salesforce/apex/LoggerConfiguratorController.getDataMaskRules';
import getPlugins from '@salesforce/apex/LoggerConfiguratorController.getPlugins';
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
    pluginRecords;
    dataMaskRules;

    parametersLoaded = false;
    pluginsLoaded = false;
    dataMaskRulesLoaded = false;

    _loggingLevelOptions;
    _shareAccessLevelOptions;

    get title() {
        return 'Logger Configurator';
    }

    get settingsTitle() {
        return 'Logger Settings';
    }

    get parametersTitle() {
        return 'Logger Parameters';
    }

    get dataMaskRulesTitle() {
        return 'Logger Data Mask Rules';
    }
    
    get pluginsTitle() {
        return 'Logger Plugins';
    }

    get canEditLoggerSettings() {
        return canEditLoggerSettings;
    }

    get canEditLoggerParameters() {
        return canEditLoggerParameters;
    }

    get canEditLogEntryDataMaskRules() {
        return true; // TODO add custom permission
    }

    get canEditLoggerPlugins() {
        return true; // TODO add custom permission
    }

    connectedCallback() {
        document.title = this.title;

        getSettings().then(result => {
            console.log('getSettings() result==' + JSON.stringify(result));
            console.log('getSettings() result.length==' + result.length);
            // TODO move logic to a private helper function
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

        getParameters().then(result => {
            console.log('getParameters() result==' + JSON.stringify(result));
            this.parameterRecords = result;
            this.parametersLoaded = true;
        });

        getDataMaskRules().then(result => {
            console.log('getDataMaskRules() result==' + JSON.stringify(result));
            this.dataMaskRules = result;
            this.dataMaskRulesLoaded = true;
        });

        getPlugins().then(result => {
            console.log('getPlugins() result==' + JSON.stringify(result));
            this.pluginRecords = result;
            this.pluginsLoaded = true;
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
    }
}
