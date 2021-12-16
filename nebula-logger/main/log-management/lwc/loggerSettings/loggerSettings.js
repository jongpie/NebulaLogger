/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

// UI
import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// LoggerSettings__c metadata
import LOGGER_SETTINGS_OBJECT from '@salesforce/schema/LoggerSettings__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import canUserModifyLoggerSettings from '@salesforce/apex/LoggerSettingsController.canUserModifyLoggerSettings';
import getPicklistOptions from '@salesforce/apex/LoggerSettingsController.getPicklistOptions';
import getOrganization from '@salesforce/apex/LoggerSettingsController.getOrganization';
import searchForSetupOwner from '@salesforce/apex/LoggerSettingsController.searchForSetupOwner';

// LoggerSettings__c data
import getRecords from '@salesforce/apex/LoggerSettingsController.getRecords';
import createRecord from '@salesforce/apex/LoggerSettingsController.createRecord';
import saveRecord from '@salesforce/apex/LoggerSettingsController.saveRecord';
import deleteRecord from '@salesforce/apex/LoggerSettingsController.deleteRecord';

export default class LoggerSettings extends LightningElement {
    // UI
    title = 'Logger Settings';
    columns;
    isReadOnlyMode = true;
    showLoadingSpinner = false;
    showRecordModal = false;
    showDeleteModal = false;
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
    loggerSettingsPicklistOptions;

    // LoggerSettings__c data
    records;
    currentRecord;
    selectedSetupOwner;

    connectedCallback() {
        document.title = this.title;
        this.showLoadingSpinner = true;

        Promise.all([getOrganization(), getPicklistOptions()])
            .then(([organization, loggerSettingsPicklistOptions]) => {
                this.organization = organization;
                this.loggerSettingsPicklistOptions = loggerSettingsPicklistOptions;
            })
            .catch(this._handleError);

        this.loadSettingsRecords();
        this.showLoadingSpinner = false;
    }

    @wire(getObjectInfo, { objectApiName: LOGGER_SETTINGS_OBJECT })
    getLoggerSettingsObjectInfo({ data }) {
        if (data) {
            this.loggerSettingsFields = data.fields;
            canUserModifyLoggerSettings().then(result => {
                this.canUserModifyLoggerSettings = result;
                this._loadTableColumns();
            });
        }
    }

    loadSettingsRecords() {
        this.showLoadingSpinner = true;
        getRecords()
            .then(settingsRecords => {
                for (let i = 0; i < settingsRecords.length; i++) {
                    const record = { ...settingsRecords[i], ...settingsRecords[i].record };
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

                this.closeRecordModal();
                this.closeDeleteModal();
                this.showLoadingSpinner = false;
            })
            .catch(this._handleError);
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        /* eslint-disable-next-line default-case */
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
        }
    }

    handleSetupOwnerTypeFieldChange(event) {
        this.selectedSetupOwner = null;
        this.showPill = false;
        this.handleFieldChange(event);
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
        this.showDropdown = false;
        this.setupOwnerSearchTerm = event.detail.value;
        if (this.setupOwnerSearchTerm && this.setupOwnerSearchTerm.length >= 2) {
            searchForSetupOwner({
                setupOwnerType: this.currentRecord.setupOwnerType,
                searchTerm: this.setupOwnerSearchTerm
            })
                .then(results => {
                    this.setupOwnerSearchResults = results;
                    this.showDropdown = true;
                })
                .catch(this._handleError);
        }
    }

    handleRecordSearchBlur() {
        this.showDropdown = false;
    }

    handleSearchResultSelection(event) {
        if (event.currentTarget.dataset.key) {
            this.currentRecord.SetupOwnerId = event.currentTarget.dataset.key;
            this.currentRecord.setupOwnerName = event.currentTarget.dataset.label;

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
            this.closeRecordModal();
            this.closeDeleteModal();
        } else if (event.ctrlKey === true && event.code === 'KeyS') {
            this.saveCurrentRecord();
        }
    }

    closeRecordModal() {
        this.showRecordModal = false;
    }

    closeDeleteModal() {
        this.showDeleteModal = false;
    }

    get isExistingRecord() {
        let isExistingRecord = false;
        if (this.currentRecord.Id) {
            isExistingRecord = true;
        }
        return isExistingRecord;
    }

    _setIsNewOrganizationRecord() {
        this.isNewOrganizationRecord = this.isExistingRecord === false && this.currentRecord?.setupOwnerType === 'Organization';
        this.currentRecord.SetupOwnerId = this.organization.Id;
        this.currentRecord.setupOwnerName = this.organization.Name;
    }

    _setShowSetupOwnerLookup() {
        this.showSetupOwnerLookup = this.isExistingRecord === false && this.currentRecord?.setupOwnerType !== 'Organization';
    }

    createNewRecord() {
        createRecord()
            .then(result => {
                this.currentRecord = result;
                this.isReadOnlyMode = false;
                this.showRecordModal = true;
            })
            .catch(this._handleError);
    }

    viewCurrentRecord(currentRow) {
        this.currentRecord = currentRow;
        this.isReadOnlyMode = true;
        this.showRecordModal = true;
    }

    editCurrentRecord(currentRow) {
        this.currentRecord = currentRow;
        this.isReadOnlyMode = false;
        this.showRecordModal = true;
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
                const setupOwnerName = this.selectedSetupOwner ? this.selectedSetupOwner.label : this.currentRecord.setupOwnerName;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.title + ' record for ' + setupOwnerName + ' successfully saved',
                        variant: 'success'
                    })
                );
                this.closeRecordModal();
                this.showLoadingSpinner = false;
            })
            .catch(this._handleError);
    }

    deleteCurrentRecord(currentRow) {
        this.showDeleteModal = true;
        this.currentRecord = currentRow;
    }

    confirmDeleteCurrentRecord() {
        this.showLoadingSpinner = true;
        const setupOwnerName = this.currentRecord.setupOwnerName;
        deleteRecord({ settingsRecord: this.currentRecord })
            .then(() => {
                this.loadSettingsRecords();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.title + ' record for ' + setupOwnerName + ' successfully deleted',
                        variant: 'success'
                    })
                );
                this.showLoadingSpinner = false;
            })
            .catch(this._handleError);
    }

    _loadTableColumns() {
        // The columns setupOwnerType and setupOwnerName are not true fields
        // They're flattened versions of SetupOwner.Type and SetupOwner.Name, so object API info isn't used here
        this.columns = [
            { fieldName: 'setupOwnerType', label: 'Setup Location', type: 'text' },
            { fieldName: 'setupOwnerName', label: 'Setup Owner Name', type: 'text' }
        ];

        // For all other fields, use object API info to dynamically get field details
        const tableColumnNames = [
            'IsEnabled__c',
            'LoggingLevel__c',
            'IsDataMaskingEnabled__c',
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
