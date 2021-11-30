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
import canUserModifyLoggerSettings from '@salesforce/apex/LoggerSettingsController.canUserModifyLoggerSettings';
import getLoggingLevelOptions from '@salesforce/apex/LoggerSettingsController.getLoggingLevelOptions';
import getSaveMethodOptions from '@salesforce/apex/LoggerSettingsController.getSaveMethodOptions';
import getSetupOwnerTypeOptions from '@salesforce/apex/LoggerSettingsController.getSetupOwnerTypeOptions';
import getShareAccessLevelOptions from '@salesforce/apex/LoggerSettingsController.getShareAccessLevelOptions';

// LoggerSettings__c data
import getOrganization from '@salesforce/apex/LoggerSettingsController.getOrganization';
import getRecords from '@salesforce/apex/LoggerSettingsController.getRecords';
import createNewRecord from '@salesforce/apex/LoggerSettingsController.createNewRecord';
import saveRecord from '@salesforce/apex/LoggerSettingsController.saveRecord';
import deleteRecord from '@salesforce/apex/LoggerSettingsController.deleteRecord';
import searchForSetupOwner from '@salesforce/apex/LoggerSettingsController.searchForSetupOwner';

export default class LoggerSettings extends LightningElement {
    // UI
    title = 'Logger Settings';
    columns;
    isReadOnlyMode = true;
    showLoadingSpinner = false;
    showModal = false;
    isNewOrganizationRecord = false;
    showSetupOwnerLookup = false;
    showSetupOwnerDropdown = false;
    setupOwnerSearchTerm;
    setupOwnerSearchResults;
    showDropdown = false;
    showPill = false;

    // LoggerSettings__c metadata
    canUserModifyLoggerSettings;
    loggerSettingsFields;
    loggingLevelOptions;
    saveMethodOptions;
    setupOwnerTypeOptions;
    shareAccessLevelOptions;

    // LoggerSettings__c data
    records;
    currentRecord;

    selectedSetupOwner;


    connectedCallback() {
        document.title = this.title;
        this.showLoadingSpinner = true;

        getOrganization().then(result => {
            this.organization = result;
        });

        getLoggingLevelOptions()
            .then(results => {
                this.loggingLevelOptions = results;
            });

        getSaveMethodOptions()
            .then(results => {
                this.saveMethodOptions = results;
            });

        getSetupOwnerTypeOptions()
            .then(results => {
                this.setupOwnerTypeOptions = results;
            });

        getShareAccessLevelOptions()
            .then(results => {
                this.shareAccessLevelOptions = results;
            });

        this.loadSettingsRecords();
        this.showLoadingSpinner = false;
    }

    @wire(getObjectInfo, { objectApiName: LOGGER_SETTINGS_OBJECT })
    getLoggerSettingsObjectInfo({ data, error }) {
        if (data) {
            this.loggerSettingsFields = data.fields;
            canUserModifyLoggerSettings().then(result => {
                this.canUserModifyLoggerSettings = result;
                this._loadTableColumns();
            });
        } else if (error) {
            this._handleError(error);
        }
    }

    loadSettingsRecords() {
        this.showLoadingSpinner = true;
        getRecords()
            .then(settingsRecords => {
                for (let i = 0; i < settingsRecords.length; i++) {
                    const record = settingsRecords[i].record;
                    record.SetupOwnerType = settingsRecords[i].setupOwnerType;
                    record.SetupOwnerName = settingsRecords[i].setupOwnerName;
                    record.CreatedByUsername = record.CreatedBy.Username;
                    record.LastModifiedByUsername = record.LastModifiedBy.Username;

                    settingsRecords[i] = record;
                }
                this.records = settingsRecords;
                this.currentRecord = null;
                this.setupOwnerSearchTerm = null;
                this.showSetupOwnerLookup = false;
                this.setupOwnerSearchResults = null;
                this.selectedSetupOwner = null;
                this.showDropdown = false;
                this.showPill = false;

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

    handleFieldChange(event) {

        let value;
        if (event.target.type === 'checkbox' || event.target.type === 'checkbox-button' || event.target.type === 'toggle') {
            value = event.target.checked;
        } else {
            value = event.target.value;
        }
        this.currentRecord[event.target.dataset.id] = value;

        this._setIsNewOrganizationRecord();
        this._setShowSetupOwnerLookup();
    }

    handleRecordSearch(event) {
        this.setupOwnerSearchTerm = event.target.value;
        if (this.setupOwnerSearchTerm && this.setupOwnerSearchTerm.length >= 2) {
            searchForSetupOwner({
                setupOwnerType: this.currentRecord.SetupOwnerType,
                searchTerm: this.setupOwnerSearchTerm
            })
                .then(results => {
                    this.setupOwnerSearchResults = results;
                    this.showDropdown = true;
                })
                .catch(error => {
                    this._handleError(error);
                });
        } else {
            this.showDropdown = false;
        }
    }

    handleRecordSearchBlur() {
        this.showDropdown = false;
    }

    handleSearchResultSelection(event) {
        if (event.currentTarget.dataset.key) {
            this.currentRecord.SetupOwnerId = event.currentTarget.dataset.key;

            let index = this.setupOwnerSearchResults.findIndex(x => x.recordId === event.currentTarget.dataset.key);
            if (index !== -1) {
                this.selectedSetupOwner = this.setupOwnerSearchResults[index];
                this.showDropdown = false;
                this.showPill = true;
            }
        }
    }

    handleRemoveSetupOwner() {
        this.showPill = false;
        this.selectedSetupOwner = '';
        this.setupOwnerSearchTerm = '';
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

    _setIsNewOrganizationRecord() {
        this.isNewOrganizationRecord = this.isExistingRecord === false && this.currentRecord?.SetupOwnerType === 'Organization';
    }

    _setShowSetupOwnerLookup() {
        this.showSetupOwnerLookup = this.isExistingRecord === false && this.currentRecord?.SetupOwnerType !== 'Organization';
    }

    createNewRecord() {
        createNewRecord()
            .then(result => {
                this.currentRecord = result;
                this.isReadOnlyMode = false;
                this.showModal = true;
            })
            .catch(error => {
                this._handleError(error);
            });
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

    saveCurrentRecord() {
        const inputsAreValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox')].reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);

        if (inputsAreValid === false) {
            return;
        }

        this.showLoadingSpinner = true;

        saveRecord({ settingsRecord: this.currentRecord })
            .then(() => {
                this.loadSettingsRecords();
                const setupOwnerName = this.selectedSetupOwner ? this.selectedSetupOwner.label : this.currentRecord.SetupOwnerName;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.title + ' record for ' + setupOwnerName + ' successfully saved',
                        variant: 'success'
                    })
                );
                this.closeModal();
                this.showLoadingSpinner = false;
            })
            .catch(error => {
                this._handleError(error);
            });
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
        // The columns SetupOwnerType and SetupOwnerName are true fields
        // They're flattened versions of SetupOwner.Type and SetupOwner.Name, so object API info isn't used here
        this.columns = [
            { fieldName: 'SetupOwnerType', label: 'Setup Location', type: 'text' },
            { fieldName: 'SetupOwnerName', label: 'Setup Owner Name', type: 'text' }
        ];

        // For all other fields, use object API info to dynamically get field details
        const tableColumnNames = [
            'IsEnabled__c',
            'LoggingLevel__c',
            'ApplyDataMaskRules__c',
            'DefaultSaveMethod__c',
            'DefaultNumberOfDaysToRetainLogs__c',
            'DefaultLogShareAccessLevel__c'
        ];
        for (let i = 0; i < tableColumnNames.length; i++) {
            const field = this.loggerSettingsFields[tableColumnNames[i]];
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

        // Finally, add the row-level actions
        let tableRowActions = [{ label: 'View', name: 'view' }];
        if (this.canUserModifyLoggerSettings === true) {
            tableRowActions = tableRowActions.concat([
                { label: 'Edit', name: 'edit' },
                { label: 'Delete', name: 'delete' }
            ]);
        }
        this.columns.push({
            type: 'action',
            typeAttributes: {
                rowActions: tableRowActions,
                menuAlignment: 'auto'
            }
        });
    }

    _handleError(error) {
        /* eslint-disable-next-line no-console */
        console.error(error);
        this.dispatchEvent(
            new ShowToastEvent({
                mode: 'sticky',
                title: error.body.message,
                variant: 'error'
            })
        );
        this.showLoadingSpinner = false;
    }
}
