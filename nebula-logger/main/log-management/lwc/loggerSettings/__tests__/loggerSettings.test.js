// UI
import { createElement } from 'lwc';
import LoggerSettings from 'c/loggerSettings';

// LoggerSettings__c metadata
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

// Mock metadata
const mockObjectInfo = require('./data/getObjectInfo.json');
const mockOrganization = require('./data/getOrganization.json');
const mockPicklistOptions = require('./data/getPicklistOptions.json');

// Mock data
const mockRecords = require('./data/getRecords.json');
const mockNewRecord = require('./data/createRecord.json');

jest.mock(
    '@salesforce/apex/LoggerSettingsController.canUserModifyLoggerSettings',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/LoggerSettingsController.createRecord',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/LoggerSettingsController.deleteRecord',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/LoggerSettingsController.getOrganization',
    () => {
        return {
            default: () => mockOrganization
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/LoggerSettingsController.getPicklistOptions',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/LoggerSettingsController.getRecords',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/LoggerSettingsController.saveRecord',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

async function initializeElement(enableModifyAccess) {
    // Assign mock values for resolved Apex promises
    canUserModifyLoggerSettings.mockResolvedValue(enableModifyAccess);
    getPicklistOptions.mockResolvedValue(mockPicklistOptions);
    getRecords.mockResolvedValue(mockRecords);

    // Create the component
    const loggerSettingsElement = createElement('c-logger-settings', { is: LoggerSettings });
    document.body.appendChild(loggerSettingsElement);

    // Emit data from @wire
    await getObjectInfo.emit(mockObjectInfo);
    await Promise.resolve();

    return loggerSettingsElement;
}

describe('Logger Settings lwc tests', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('loads component without modify access', async () => {
        const loggerSettingsElement = await initializeElement(false);

        // Check the component
        expect(document.title).toEqual('Logger Settings');
        // expect(getObjectInfo.getLastConfig()).toEqual(mockObjectInfo);
        const refreshBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="refresh-btn"]');
        expect(refreshBtn).toBeTruthy();
        const newRecordBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="new-btn"]');
        expect(newRecordBtn).toBeFalsy();
        const datatable = loggerSettingsElement.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).toBeTruthy();
        expect(datatable.data).toEqual(mockRecords);
    });

    it('loads component with modify access', async () => {
        const loggerSettingsElement = await initializeElement(true);

        // Verify the expected Apex/framework calls
        expect(canUserModifyLoggerSettings).toHaveBeenCalledTimes(1);
        expect(getPicklistOptions).toHaveBeenCalledTimes(1);
        expect(getRecords).toHaveBeenCalledTimes(1);
        expect(createRecord).toHaveBeenCalledTimes(0);

        // Check the component
        expect(document.title).toEqual('Logger Settings');
        const refreshBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="refresh-btn"]');
        expect(refreshBtn).toBeTruthy();
        const newRecordBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="new-btn"]');
        expect(newRecordBtn).toBeTruthy();
        const datatable = loggerSettingsElement.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).toBeTruthy();
        expect(datatable.data).toEqual(mockRecords);
    });

    it('shows record modal when new button is clicked', async () => {
        const loggerSettingsElement = await initializeElement(true);
        createRecord.mockResolvedValue(mockNewRecord);

        // Clickety click
        const newRecordBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="new-btn"]');
        newRecordBtn.click();
        // Yes, 2 calls for Promise.resolve() are needed... because of... reasons?
        await Promise.resolve();
        await Promise.resolve();

        const datatable = loggerSettingsElement.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).toBeTruthy();
        expect(datatable.data).toEqual(mockRecords);

        // Check the modal
        expect(createRecord).toHaveBeenCalledTimes(1);
        const recordModal = loggerSettingsElement.shadowRoot.querySelector('.slds-modal');
        expect(recordModal).toBeTruthy();

        // Check each of the fields within the modal to ensure the default field values are populated
        // TODO find a way to do this dynamically (using querySelectorAll?) to reduce LOC
        const setupOwnerTypeField = loggerSettingsElement.shadowRoot.querySelector('[data-id="setupOwnerType"]');
        expect(setupOwnerTypeField).toBeTruthy();
        expect(setupOwnerTypeField.options).toEqual(mockPicklistOptions.setupOwnerTypeOptions);
        expect(setupOwnerTypeField.value).toBeFalsy();
        const setupOwnerNameField = loggerSettingsElement.shadowRoot.querySelector('lightning-input[data-id="setupOwnerName"]');
        expect(setupOwnerNameField).toBeFalsy();
        const isEnabledField = loggerSettingsElement.shadowRoot.querySelector('[data-id="IsEnabled__c"]');
        expect(isEnabledField).toBeTruthy();
        expect(isEnabledField.checked).toEqual(mockNewRecord.IsEnabled__c);
        const loggingLevelField = loggerSettingsElement.shadowRoot.querySelector('[data-id="LoggingLevel__c"]');
        expect(loggingLevelField).toBeTruthy();
        expect(loggingLevelField.options).toEqual(mockPicklistOptions.loggingLevelOptions);
        expect(loggingLevelField.value).toEqual(mockNewRecord.LoggingLevel__c);
        const defaultNumberOfDaysToRetainLogsField = loggerSettingsElement.shadowRoot.querySelector('[data-id="DefaultNumberOfDaysToRetainLogs__c"]');
        expect(defaultNumberOfDaysToRetainLogsField).toBeTruthy();
        expect(defaultNumberOfDaysToRetainLogsField.value).toEqual(mockNewRecord.DefaultNumberOfDaysToRetainLogs__c);
        const defaultLogShareAccessLevelField = loggerSettingsElement.shadowRoot.querySelector('[data-id="DefaultLogShareAccessLevel__c"]');
        expect(defaultLogShareAccessLevelField).toBeTruthy();
        expect(defaultLogShareAccessLevelField.options).toEqual(mockPicklistOptions.shareAccessLevelOptions);
        expect(defaultLogShareAccessLevelField.value).toEqual(mockNewRecord.DefaultLogShareAccessLevel__c);
        const defaultSaveMethodField = loggerSettingsElement.shadowRoot.querySelector('[data-id="DefaultSaveMethod__c"]');
        expect(defaultSaveMethodField).toBeTruthy();
        expect(defaultSaveMethodField.options).toEqual(mockPicklistOptions.saveMethodOptions);
        expect(defaultSaveMethodField.value).toEqual(mockNewRecord.DefaultSaveMethod__c);
        const isApexSystemDebugLoggingEnabledField = loggerSettingsElement.shadowRoot.querySelector('[data-id="IsApexSystemDebugLoggingEnabled__c"]');
        expect(isApexSystemDebugLoggingEnabledField).toBeTruthy();
        expect(isApexSystemDebugLoggingEnabledField.checked).toEqual(mockNewRecord.IsApexSystemDebugLoggingEnabled__c);
        const isComponentConsoleLoggingEnabledField = loggerSettingsElement.shadowRoot.querySelector('[data-id="IsComponentConsoleLoggingEnabled__c"]');
        expect(isComponentConsoleLoggingEnabledField).toBeTruthy();
        expect(isComponentConsoleLoggingEnabledField.checked).toEqual(mockNewRecord.IsComponentConsoleLoggingEnabled__c);
        const isDataMaskingEnabledField = loggerSettingsElement.shadowRoot.querySelector('[data-id="IsDataMaskingEnabled__c"]');
        expect(isDataMaskingEnabledField).toBeTruthy();
        expect(isDataMaskingEnabledField.checked).toEqual(mockNewRecord.IsDataMaskingEnabled__c);
        const stripInaccessibleRecordFieldsField = loggerSettingsElement.shadowRoot.querySelector('[data-id="StripInaccessibleRecordFields__c"]');
        expect(stripInaccessibleRecordFieldsField).toBeTruthy();
        expect(stripInaccessibleRecordFieldsField.checked).toEqual(mockNewRecord.StripInaccessibleRecordFields__c);
        const isAnonymousModeEnabled__cField = loggerSettingsElement.shadowRoot.querySelector('[data-id="IsAnonymousModeEnabled__c"]');
        expect(isAnonymousModeEnabled__cField).toBeTruthy();
        expect(isAnonymousModeEnabled__cField.checked).toEqual(mockNewRecord.IsAnonymousModeEnabled__c);
    });

    it('saves new organization record when save button is clicked', async () => {
        const loggerSettingsElement = await initializeElement(true);
        createRecord.mockResolvedValue(mockNewRecord);
        saveRecord.mockResolvedValue(null);

        // Clickety click
        const newRecordBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="new-btn"]');
        newRecordBtn.click();
        // Yes, 2 calls for Promise.resolve() are needed... because of... reasons?
        await Promise.resolve();
        await Promise.resolve();

        const datatable = loggerSettingsElement.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).toBeTruthy();
        expect(datatable.data).toEqual(mockRecords);

        // Check the modal
        expect(createRecord).toHaveBeenCalledTimes(1);
        const recordModal = loggerSettingsElement.shadowRoot.querySelector('.slds-modal');
        expect(recordModal).toBeTruthy();

        // Check each of the fields within the modal to ensure the default field values are populated
        const setupOwnerTypeField = loggerSettingsElement.shadowRoot.querySelector('[data-id="setupOwnerType"]');
        setupOwnerTypeField.value = 'Organization';
        expect(setupOwnerTypeField).toBeTruthy();
        expect(setupOwnerTypeField.options).toEqual(mockPicklistOptions.setupOwnerTypeOptions);

        const loggingLevelField = loggerSettingsElement.shadowRoot.querySelector('[data-id="LoggingLevel__c"]');
        expect(loggingLevelField).toBeTruthy();
        expect(loggingLevelField.options).toEqual(mockPicklistOptions.loggingLevelOptions);
        expect(loggingLevelField.value).toEqual(mockNewRecord.LoggingLevel__c);

        const defaultSaveMethodField = loggerSettingsElement.shadowRoot.querySelector('[data-id="DefaultSaveMethod__c"]');
        expect(defaultSaveMethodField).toBeTruthy();
        expect(defaultSaveMethodField.options).toEqual(mockPicklistOptions.saveMethodOptions);
        expect(defaultSaveMethodField.value).toEqual(mockNewRecord.DefaultSaveMethod__c);

        const expectedNewRecord = { ...mockNewRecord };
        const expectedApexParameter = { settingsRecord: expectedNewRecord };
        const saveRecordBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="save-btn"]');
        saveRecordBtn.click();
        await Promise.resolve();
        expect(saveRecord).toHaveBeenCalledTimes(1);
        expect(saveRecord.mock.calls[0][0]).toEqual(expectedApexParameter);
    });

    it('deletes record when delete row action is clicked', async () => {
        const loggerSettingsElement = await initializeElement(true);
        deleteRecord.mockResolvedValue(null);

        // Verify the expected Apex/framework calls
        expect(deleteRecord).toHaveBeenCalledTimes(0);

        // Check the component
        const datatable = loggerSettingsElement.shadowRoot.querySelector('lightning-datatable');
        const firstRowRecordId = datatable.data[0].record.Id;
        const rowActionEvent = new CustomEvent('rowaction', {
            detail: {
                action: { name: 'delete' },
                row: { Id: firstRowRecordId }
            }
        });
        datatable.dispatchEvent(rowActionEvent);
        await Promise.resolve();

        const recordModal = loggerSettingsElement.shadowRoot.querySelector('.slds-modal');
        expect(recordModal).toBeTruthy();

        // Clickety click
        const expectedApexParameter = { settingsRecord: { Id: firstRowRecordId } };
        const deleteRecordBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="delete-confirmation-btn"]');
        deleteRecordBtn.click();
        expect(deleteRecord).toHaveBeenCalledTimes(1);
        expect(deleteRecord.mock.calls[0][0]).toEqual(expectedApexParameter);
    });
});
