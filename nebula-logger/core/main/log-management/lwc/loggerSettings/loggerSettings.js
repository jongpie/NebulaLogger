/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

// UI
import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// LoggerSettings__c metadata
import { generatePageLayout } from './loggerSettingsPageLayout';
import canUserModifyLoggerSettings from '@salesforce/apex/LoggerSettingsController.canUserModifyLoggerSettings';
import getSchemaForName from '@salesforce/apex/LoggerSObjectMetadata.getSchemaForName';
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
    loggerSettingsPicklistOptions;
    _loggerSettingsSchema;

    // LoggerSettings__c data
    records;
    selectedSetupOwner;
    _currentRecord;

    connectedCallback() {
        this.showLoadingSpinner = true;
        Promise.all([getOrganization(), getSchemaForName({ sobjectApiName: 'LoggerSettings__c' }), getPicklistOptions(), canUserModifyLoggerSettings()])
            .then(([organizationRecordResult, loggerSettingsSchemaResult, apexPicklistOptionsResult, canUserModifyLoggerSettingsResult]) => {
                this.organization = organizationRecordResult;
                this._loggerSettingsSchema = loggerSettingsSchemaResult;
                this.loggerSettingsPicklistOptions = apexPicklistOptionsResult;
                this.canUserModifyLoggerSettings = canUserModifyLoggerSettingsResult;

                this._loadTableColumns();
                this.loadSettingsRecords();
                this.showLoadingSpinner = false;
            })
            .catch(this._handleError);
    }

    loadSettingsRecords() {
        this.showLoadingSpinner = true;
        getRecords()
            .then(settingsRecords => {
                for (let i = 0; i < settingsRecords.length; i++) {
                    const record = { ...settingsRecords[i], ...settingsRecords[i].record };
                    settingsRecords[i] = this._removeFieldNamespace(record);
                }
                this.records = settingsRecords;
                this._currentRecord = null;
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
        const fieldApiName = event.target.dataset.id;
        const fieldValue =
            event.target.type === 'checkbox' || event.target.type === 'checkbox-button' || event.target.type === 'toggle'
                ? event.target.checked
                : event.target.value;
        this._currentRecord[fieldApiName] = fieldValue;
        this._setIsNewOrganizationRecord();
        this._setShowSetupOwnerLookup();
    }

    handleRecordSearch(event) {
        this.showDropdown = false;
        this.setupOwnerSearchTerm = event.detail.value;
        if (this.setupOwnerSearchTerm && this.setupOwnerSearchTerm.length >= 2) {
            searchForSetupOwner({
                setupOwnerType: this._currentRecord.setupOwnerType,
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
            this._currentRecord.SetupOwnerId = event.currentTarget.dataset.key;
            this._currentRecord.setupOwnerName = event.currentTarget.dataset.label;

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
        if (this._currentRecord.Id) {
            isExistingRecord = true;
        }
        return isExistingRecord;
    }

    // Getters for each LoggerSettings__c field describes & data - these handle dealing with using a namespace for the package
    // TODO - this is a legacy approach where separate getters were used for each field - the audit fields & "general info" fields still use this approach
    // but should be updated to leverage the new approach, loggerSettingsPageLayout.js
    get layoutData() {
        return generatePageLayout(this._loggerSettingsSchema, this.loggerSettingsPicklistOptions, this.isReadOnlyMode, this._currentRecord);
    }

    get createdByIdField() {
        return this._loadField(this._loggerSettingsSchema.fields.CreatedById.localApiName, 'createdByUsername');
    }

    get createdDateField() {
        return this._loadField(this._loggerSettingsSchema.fields.CreatedDate.localApiName);
    }

    get lastModifiedByIdField() {
        return this._loadField(this._loggerSettingsSchema.fields.LastModifiedById.localApiName, 'lastModifiedByUsername');
    }

    get lastModifiedDateField() {
        return this._loadField(this._loggerSettingsSchema.fields.LastModifiedDate.localApiName);
    }

    get setupOwnerNameField() {
        return this._loadField('setupOwnerName', 'setupOwnerName', 'Setup Owner');
    }

    get setupOwnerTypeField() {
        return this._loadField('setupOwnerType', 'setupOwnerType', 'Setup Location');
    }

    createNewRecord() {
        createRecord()
            .then(result => {
                this._currentRecord = this._removeFieldNamespace({ ...result });
                this.selectedSetupOwner = null;
                this.isNewOrganizationRecord = false;
                this.isReadOnlyMode = false;
                this.showPill = false;
                this.showRecordModal = true;
                this.showSetupOwnerLookup = false;
            })
            .catch(this._handleError);
    }

    viewCurrentRecord(currentRow) {
        this._currentRecord = currentRow;
        this.isReadOnlyMode = true;
        this.showRecordModal = true;
    }

    editCurrentRecord(currentRow) {
        this._currentRecord = currentRow;
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

        const recordWithNamespace = this._addFieldNamespace(this._currentRecord);
        saveRecord({ settingsRecord: recordWithNamespace })
            .then(() => {
                this.loadSettingsRecords();
                const setupOwnerName = this.selectedSetupOwner ? this.selectedSetupOwner.label : this._currentRecord.setupOwnerName;
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
        this._currentRecord = currentRow;
    }

    confirmDeleteCurrentRecord() {
        this.showLoadingSpinner = true;
        const setupOwnerName = this._currentRecord.setupOwnerName;
        deleteRecord({ settingsRecord: this._currentRecord })
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

    // Private functions
    _loadTableColumns() {
        // The columns setupOwnerType and setupOwnerName are not true fields
        // They're flattened versions of SetupOwner.Type and SetupOwner.Name, so object API info isn't used here
        this.columns = [
            { fieldName: 'setupOwnerType', label: 'Setup Location', type: 'text' },
            { fieldName: 'setupOwnerName', label: 'Setup Owner', type: 'text' }
        ];

        // For all other fields, use object API info to dynamically get field details
        // TODO - make this array configurable by storing in LoggerParameter__mdt
        const tableColumnNames = [
            'StartTime__c',
            'EndTime__c',
            'IsEnabled__c',
            'LoggingLevel__c',
            'IsSavingEnabled__c',
            'DefaultScenario__c',
            'DefaultLogOwner__c',
            'DefaultNumberOfDaysToRetainLogs__c'
        ];
        for (let i = 0; i < tableColumnNames.length; i++) {
            const field = this._loggerSettingsSchema.fields[tableColumnNames[i]];
            const column = {
                fieldName: field.localApiName,
                label: field.label,
                type: field.type.toLowerCase()
            };
            if (column.type === 'datetime') {
                column.type = 'date';
                // FIXME and make dynamic based on user prefences for datetimes
                column.typeAttributes = {
                    month: '2-digit',
                    day: '2-digit',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                };
            }
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

    // This function is a legacy approach for getting field metadata & data - the new approach is to use
    // loggerSettingsPageLayout.js,  but it does not fully handle some fields like CreatedyBy.Username, SetupOwner.Type, etc.
    // TODO - in a future release, eliminate this function + improve loggerSettingsPageLayout.js to handle this logic
    _loadField(fieldApiName, recordFieldApiName, recordFieldLabel) {
        if (!recordFieldApiName) {
            recordFieldApiName = fieldApiName;
        }

        let fieldDescribe;
        if (fieldApiName && this._loggerSettingsSchema.fields[fieldApiName]) {
            fieldDescribe = { ...this._loggerSettingsSchema.fields[fieldApiName] };
        } else {
            fieldDescribe = { apiName: fieldApiName };
        }

        if (this._currentRecord) {
            fieldDescribe.value = this._currentRecord[recordFieldApiName];
        }

        if (recordFieldLabel) {
            fieldDescribe.label = recordFieldLabel;
        }

        return fieldDescribe;
    }

    _setIsNewOrganizationRecord() {
        this.isNewOrganizationRecord = this.isExistingRecord === false && this._currentRecord?.setupOwnerType === 'Organization';
        if (this.isNewOrganizationRecord === true) {
            this._currentRecord.SetupOwnerId = this.organization.Id;
            this._currentRecord.setupOwnerName = this.organization.Name;
        }
    }

    _setShowSetupOwnerLookup() {
        this.showSetupOwnerLookup =
            this.isExistingRecord === false && this._currentRecord?.setupOwnerType && this._currentRecord?.setupOwnerType !== 'Organization';
    }

    _addFieldNamespace(record) {
        const cleanedRecord = {};
        const namespacePrefix = this._loggerSettingsSchema.namespacePrefix;
        if (!namespacePrefix) {
            return record;
        }

        Object.keys(record).forEach(key => {
            const fullApiName = this._loggerSettingsSchema.fields[key] ? this._loggerSettingsSchema.fields[key].apiName : key;
            cleanedRecord[fullApiName] = record[key];
        });
        return cleanedRecord;
    }

    _removeFieldNamespace(record) {
        const cleanedRecord = {};
        const namespacePrefix = this._loggerSettingsSchema.namespacePrefix;
        if (!namespacePrefix) {
            return record;
        }

        Object.keys(record).forEach(key => {
            const localApiName = key.replace(namespacePrefix, '');
            cleanedRecord[localApiName] = record[key];
        });
        return cleanedRecord;
    }

    _handleError = error => {
        const errorMessage = error.body ? error.body.message : error.message;
        /* eslint-disable-next-line no-console */
        console.error(errorMessage, error);
        this.dispatchEvent(
            new ShowToastEvent({
                mode: 'sticky',
                title: errorMessage,
                variant: 'error'
            })
        );
        this.showLoadingSpinner = false;
    };
}
