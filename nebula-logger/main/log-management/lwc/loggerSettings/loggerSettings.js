/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/

// UI
import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// LoggerSettings__c metadata
import LOGGER_SETTINGS_OBJECT from '@salesforce/schema/LoggerSettings__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import canManageLoggerSettings from '@salesforce/apex/LoggerSettingsController.canManageLoggerSettings';
import getLoggingLevelOptions from '@salesforce/apex/LoggerSettingsController.getLoggingLevelOptions';
import getSaveMethodOptions from '@salesforce/apex/LoggerSettingsController.getSaveMethodOptions';
import getSetupOwnerTypeOptions from '@salesforce/apex/LoggerSettingsController.getSetupOwnerTypeOptions';
import getShareAccessLevelOptions from '@salesforce/apex/LoggerSettingsController.getShareAccessLevelOptions';

// LoggerSettings__c data
import getSettings from '@salesforce/apex/LoggerSettingsController.getSettings';
import saveRecord from '@salesforce/apex/LoggerSettingsController.saveRecord';
import deleteRecord from '@salesforce/apex/LoggerSettingsController.deleteRecord';

// Datatable config
const TABLE_ROW_ACTIONS = [
    { label: 'View', name: 'view' },
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];
const TABLE_COLUMN_NAMES = [
    'IsEnabled__c',
    'LoggingLevel__c',
    'ApplyDataMaskRules__c',
    'DefaultSaveMethod__c',
    'DefaultLogShareAccessLevel__c',
    'DefaultNumberOfDaysToRetainLogs__c'
];

export default class LoggerSettings extends LightningElement {
    // UI
    title = 'Logger Settings';
    isReadOnlyMode = true;
    showLoadingSpinner = false;
    showModal = false;
    columns;

    // LoggerSettings__c metadata
    canUserManageLoggerSettings;
    loggerSettingsFields;
    loggingLevelOptions;
    saveMethodOptions;
    setupOwnerTypeOptions;
    shareAccessLevelOptions;

    // LoggerSettings__c data
    records;
    currentRecord;

    @wire(getObjectInfo, { objectApiName: LOGGER_SETTINGS_OBJECT })
    getLoggerSettingsObjectInfo({ data, error }) {
        if (data) {
            this.loggerSettingsFields = data.fields;
            this._loadTableColumns();
        } else if (error) {
            this._handleError(error);
        }
    }

    connectedCallback() {
        document.title = this.title;
        this.showLoadingSpinner = true;

        canManageLoggerSettings().then(result => {
            this.canUserManageLoggerSettings = result;
        });

        if (this.canUserManageLoggerSettings === false) {
            return;
        }

        getLoggingLevelOptions()
            .then(results => {
                this.loggingLevelOptions = results;
            })
            .catch(error => {
                this._handleError(error);
            });

        getSaveMethodOptions()
            .then(results => {
                this.saveMethodOptions = results;
            })
            .catch(error => {
                this._handleError(error);
            });

        getSetupOwnerTypeOptions()
            .then(results => {
                this.setupOwnerTypeOptions = results;
            })
            .catch(error => {
                this._handleError(error);
            });

        getShareAccessLevelOptions()
            .then(results => {
                this.shareAccessLevelOptions = results;
            })
            .catch(error => {
                this._handleError(error);
            });

        this.loadSettingsRecords();
        this.showLoadingSpinner = false;
    }

    loadSettingsRecords() {
        this.showLoadingSpinner = true;
        getSettings()
            .then(settingsRecords => {
                for (let i = 0; i < settingsRecords.length; i++) {
                    const record = settingsRecords[i].Record;
                    record.SetupOwnerType = settingsRecords[i].SetupOwnerType;
                    record.SetupOwnerName = settingsRecords[i].SetupOwnerName;

                    settingsRecords[i] = record;
                }
                this.records = settingsRecords;
                this.currentRecord = null;
                this.showLoadingSpinner = false;
            })
            .catch(error => {
                this._handleError(error);
            });
    }

    handleRowActions(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'view':
                this.viewCurrentRecord(row);
                break;
            case 'edit':
                this.editCurrentRecord(row);
                break;
            case 'delete':
                this.deleteCurrentRecord(row);
                break;
            default:
                break;
        }
    }

    handleKeyDown(event) {
        if (event.code === 'Escape') {
            this.closeModal();
        }
    }

    closeModal() {
        this.showModal = false;
    }

    get isExistingRecord() {
        let isExistingRecord = false;
        if (this.currentRecord.Id) {
            isExistingRecord = true;
        }
        return isExistingRecord;
    }

    createNewRecord() {
        // FIXME new isn't working yet
        this.currentRecord = {};
        this.isReadOnlyMode = false;
        this.showModal = true;
    }

    viewCurrentRecord(currentRow) {
        this.currentRecord = currentRow;
        this.isReadOnlyMode = true;
        this.showModal = true;
    }

    editCurrentRecord(currentRow) {
        this.currentRecord = currentRow;
        this.isReadOnlyMode = false;
        this.showModal = true;
    }

    saveCurrentRecord(currentRow) {
        // FIXME save isn't working yet
        this.showLoadingSpinner = true;
        console.log('saveRecord currentRow', currentRow);
        console.log('saveRecord currentRecord', JSON.parse(JSON.stringify(this.currentRecord)));
        saveRecord({ settingsRecord: this.currentRecord }).then(()  => {
            this.loadSettingsRecords();

            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.title + ' record for ' + currentRow.detail.fields.SetupOwnerName + ' successfully saved',
                    variant: 'success'
                })
            );
            this.showLoadingSpinner = false;
        });

        this.closeModal();
    }

    deleteCurrentRecord(currentRow) {
        this.showLoadingSpinner = true;
        deleteRecord({ settingsRecord: currentRow })
            .then(() => {
                this.loadSettingsRecords();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.title + ' record for ' + currentRow.SetupOwnerName + ' successfully deleted',
                        variant: 'success'
                    })
                );
                this.showLoadingSpinner = false;
            })
            .catch(error => {
                this._handleError(error);
            });
    }

    _loadTableColumns() {
        this.columns = [
            { label: 'Setup Location', fieldName: 'SetupOwnerType', type: 'text' },
            { label: 'Setup Owner', fieldName: 'SetupOwnerName', type: 'text' }
        ];
        for (let i = 0; i < TABLE_COLUMN_NAMES.length; i++) {
            const field = this.loggerSettingsFields[TABLE_COLUMN_NAMES[i]];
            const column = {
                fieldName: field.apiName,
                label: field.label,
                type: field.dataType?.toLowerCase()
            };
            if (column.type === 'string') {
                column.type = 'text';
            }
            this.columns.push(column);
        }
        this.columns.push({
            type: 'action',
            typeAttributes: {
                rowActions: TABLE_ROW_ACTIONS,
                menuAlignment: 'auto'
            }
        });
    }

    _handleError(error) {
        this.dispatchEvent(
            new ShowToastEvent({
                message: error.message,
                title: 'Error!',
                variant: 'error'
            })
        );
        this.showLoadingSpinner = false;
    }
}
