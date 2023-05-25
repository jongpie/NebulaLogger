// UI
import { createElement } from 'lwc';
import LoggerSettings from 'c/loggerSettings';

// LoggerSettings__c metadata
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

// Mock metadata
const mockLoggerSettingsSchema = require('./data/getSchemaForName.json');
const mockOrganization = require('./data/getOrganization.json');
const mockPicklistOptions = require('./data/getPicklistOptions.json');

// Mock data
const mockRecords = require('./data/getRecords.json');
const mockNewRecord = require('./data/createRecord.json');
const mockSearchResults = require('./data/searchForSetupOwner.json');

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

jest.mock(
    '@salesforce/apex/LoggerSettingsController.searchForSetupOwner',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/LoggerSObjectMetadata.getSchemaForName',
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
    getSchemaForName.mockResolvedValue(mockLoggerSettingsSchema);
    getPicklistOptions.mockResolvedValue(mockPicklistOptions);
    getRecords.mockResolvedValue(mockRecords);

    // Create the component
    const loggerSettingsElement = createElement('c-logger-settings', { is: LoggerSettings });
    document.body.appendChild(loggerSettingsElement);

    await new Promise(resolve => setTimeout(resolve, 0));

    return loggerSettingsElement;
}

test.todo('test for search term too short (2 characters or less)');
test.todo('test for no search results');
test.todo('test for handleRecordSearchBlur()');
test.todo('test for handleRemoveSetupOwner()');
test.todo('test for invalid inputs when saving');
test.todo('test for error handling via toast messages');

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
        expect(getSchemaForName).toHaveBeenCalledTimes(1);
        expect(getPicklistOptions).toHaveBeenCalledTimes(1);
        expect(getRecords).toHaveBeenCalledTimes(1);
        expect(createRecord).toHaveBeenCalledTimes(0);

        // Check the component
        const refreshBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="refresh-btn"]');
        expect(refreshBtn).toBeTruthy();
        const newRecordBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="new-btn"]');
        expect(newRecordBtn).toBeTruthy();
        const datatable = loggerSettingsElement.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).toBeTruthy();
        expect(datatable.data).toEqual(mockRecords);
    });

    it("shows record modal when 'new' button is clicked", async () => {
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

        // Check the picklist fields to ensure the correct options are mapped
        const setupOwnerTypeField = loggerSettingsElement.shadowRoot.querySelector('[data-id="setupOwnerType"]');
        expect(setupOwnerTypeField.options).toEqual(mockPicklistOptions.setupOwnerTypeOptions);
        const loggingLevelField = loggerSettingsElement.shadowRoot.querySelector('[data-id="LoggingLevel__c"]');
        expect(loggingLevelField.options).toEqual(mockPicklistOptions.loggingLevelOptions);
        const defaultLogShareAccessLevelField = loggerSettingsElement.shadowRoot.querySelector('[data-id="DefaultLogShareAccessLevel__c"]');
        expect(defaultLogShareAccessLevelField.options).toEqual(mockPicklistOptions.shareAccessLevelOptions);
        const defaultSaveMethodField = loggerSettingsElement.shadowRoot.querySelector('[data-id="DefaultSaveMethod__c"]');
        expect(defaultSaveMethodField.options).toEqual(mockPicklistOptions.saveMethodOptions);

        // Check each of the fields within the modal to ensure the default field values are populated
        const expectedFieldNames = [
            'DefaultLogShareAccessLevel__c',
            'DefaultNumberOfDaysToRetainLogs__c',
            'DefaultSaveMethod__c',
            'IsAnonymousModeEnabled__c',
            'IsApexSystemDebugLoggingEnabled__c',
            'IsJavaScriptConsoleLoggingEnabled__c',
            'IsDataMaskingEnabled__c',
            'IsEnabled__c',
            'IsRecordFieldStrippingEnabled__c',
            'LoggingLevel__c'
        ];
        expectedFieldNames.forEach(fieldName => {
            const inputField = loggerSettingsElement.shadowRoot.querySelector('[data-id="' + fieldName + '"]');
            expect(inputField).toBeTruthy();
            if (inputField.checked !== undefined) {
                expect(inputField.checked).toBe(mockNewRecord[fieldName]);
            } else {
                expect(inputField.value).toBe(mockNewRecord[fieldName]);
            }
        });
    });

    it("closes record modal when 'cancel' button is clicked", async () => {
        const loggerSettingsElement = await initializeElement(true);
        createRecord.mockResolvedValue(mockNewRecord);

        // Clickety click
        const newRecordBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="new-btn"]');
        newRecordBtn.click();
        // Yes, 2 calls for Promise.resolve() are needed... because of... reasons?
        await Promise.resolve();
        await Promise.resolve();

        // Check the modal
        expect(createRecord).toHaveBeenCalledTimes(1);
        let recordModal = loggerSettingsElement.shadowRoot.querySelector('.slds-modal');
        expect(recordModal).toBeTruthy();

        const cancelBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="cancel-btn"]');
        cancelBtn.click();
        await Promise.resolve();
        recordModal = loggerSettingsElement.shadowRoot.querySelector('.slds-modal');
        expect(recordModal).toBeFalsy();
    });

    it("closes record modal when 'Escape' key is pressed", async () => {
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
        let recordModal = loggerSettingsElement.shadowRoot.querySelector('.slds-modal');
        expect(recordModal).toBeTruthy();

        const escapeKeyboardShortcutEvent = new KeyboardEvent('keydown', { code: 'Escape' });
        recordModal.dispatchEvent(escapeKeyboardShortcutEvent);
        await Promise.resolve();
        recordModal = loggerSettingsElement.shadowRoot.querySelector('.slds-modal');
        expect(recordModal).toBeFalsy();
    });

    it("saves new organization record when 'save' button is clicked", async () => {
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

        // Set the values of the required fields
        const setupOwnerTypeField = loggerSettingsElement.shadowRoot.querySelector('[data-id="setupOwnerType"]');
        setupOwnerTypeField.value = 'Organization';
        setupOwnerTypeField.dispatchEvent(new CustomEvent('change'));

        const specifiedLoggingLevel = 'FINEST';
        const loggingLevelField = loggerSettingsElement.shadowRoot.querySelector('[data-id="LoggingLevel__c"]');
        loggingLevelField.value = specifiedLoggingLevel;
        loggingLevelField.dispatchEvent(new CustomEvent('change'));

        const specifiedSaveMethod = 'QUEUEABLE';
        const defaultSaveMethodField = loggerSettingsElement.shadowRoot.querySelector('[data-id="DefaultSaveMethod__c"]');
        defaultSaveMethodField.value = specifiedSaveMethod;
        defaultSaveMethodField.dispatchEvent(new CustomEvent('change'));

        // Save the record & verify the call to the Apex controller
        const expectedNewRecord = { ...mockNewRecord };
        expectedNewRecord.SetupOwnerId = mockOrganization.Id;
        expectedNewRecord.LoggingLevel__c = specifiedLoggingLevel;
        expectedNewRecord.DefaultSaveMethod__c = specifiedSaveMethod;
        expectedNewRecord.setupOwnerName = mockOrganization.Name;
        expectedNewRecord.setupOwnerType = setupOwnerTypeField.value;
        const expectedApexParameter = { settingsRecord: expectedNewRecord };
        const saveRecordBtn = loggerSettingsElement.shadowRoot.querySelector('[data-id="save-btn"]');
        saveRecordBtn.click();
        await Promise.resolve();
        expect(saveRecord).toHaveBeenCalledTimes(1);
        expect(saveRecord.mock.calls[0][0]).toEqual(expectedApexParameter);
    });

    it("saves new organization record when 'ctrl + s' shortcut is pressed", async () => {
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

        // Set the values of the required fields
        const setupOwnerTypeField = loggerSettingsElement.shadowRoot.querySelector('[data-id="setupOwnerType"]');
        setupOwnerTypeField.value = 'Organization';
        setupOwnerTypeField.dispatchEvent(new CustomEvent('change'));

        const specifiedLoggingLevel = 'FINEST';
        const loggingLevelField = loggerSettingsElement.shadowRoot.querySelector('[data-id="LoggingLevel__c"]');
        loggingLevelField.value = specifiedLoggingLevel;
        loggingLevelField.dispatchEvent(new CustomEvent('change'));

        const isDataMaskingEnabled = false;
        const isDataMaskingEnabledField = loggerSettingsElement.shadowRoot.querySelector('[data-id="IsDataMaskingEnabled__c"]');
        isDataMaskingEnabledField.checked = isDataMaskingEnabled;
        isDataMaskingEnabledField.dispatchEvent(new CustomEvent('change'));

        // Save the record & verify the call to the Apex controller
        const expectedNewRecord = { ...mockNewRecord };
        expectedNewRecord.SetupOwnerId = mockOrganization.Id;
        expectedNewRecord.LoggingLevel__c = specifiedLoggingLevel;
        expectedNewRecord.IsDataMaskingEnabled__c = isDataMaskingEnabled;
        expectedNewRecord.setupOwnerName = mockOrganization.Name;
        expectedNewRecord.setupOwnerType = setupOwnerTypeField.value;
        const expectedApexParameter = { settingsRecord: expectedNewRecord };

        const saveKeyboardShortcutEvent = new KeyboardEvent('keydown', { code: 'KeyS', ctrlKey: true });
        let recordModal = loggerSettingsElement.shadowRoot.querySelector('.slds-modal');
        recordModal.dispatchEvent(saveKeyboardShortcutEvent);
        await Promise.resolve();
        await Promise.resolve();
        recordModal = loggerSettingsElement.shadowRoot.querySelector('.slds-modal');
        expect(recordModal).toBeFalsy();
        expect(saveRecord).toHaveBeenCalledTimes(1);
        expect(saveRecord.mock.calls[0][0]).toEqual(expectedApexParameter);
    });

    it("saves new user record when 'save' button is clicked", async () => {
        const loggerSettingsElement = await initializeElement(true);
        createRecord.mockResolvedValue(mockNewRecord);
        searchForSetupOwner.mockResolvedValue(mockSearchResults);
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

        // Set the values of the required fields
        const setupOwnerTypeField = loggerSettingsElement.shadowRoot.querySelector('[data-id="setupOwnerType"]');
        setupOwnerTypeField.value = 'User';
        setupOwnerTypeField.dispatchEvent(new CustomEvent('change'));
        await Promise.resolve();

        // Simulate a record search
        const specifieUserSearchTerm = 'some.user@fakesearch.com';
        const setupOwnerRecordSearchField = loggerSettingsElement.shadowRoot.querySelector('[data-id="SetupOwnerRecordSearch"]');
        expect(setupOwnerRecordSearchField).toBeTruthy();
        setupOwnerRecordSearchField.value = specifieUserSearchTerm;
        setupOwnerRecordSearchField.dispatchEvent(
            new CustomEvent('change', {
                detail: {
                    value: specifieUserSearchTerm
                }
            })
        );
        await Promise.resolve();
        await Promise.resolve();
        const expectedApexSearchParameter = { setupOwnerType: 'User', searchTerm: specifieUserSearchTerm };
        expect(searchForSetupOwner.mock.calls[0][0]).toEqual(expectedApexSearchParameter);

        // Verify that the search results are displayed
        const setupOwnerSearchResultsElement = loggerSettingsElement.shadowRoot.querySelector('[data-id="SetupOwnerSearchResults"');
        expect(setupOwnerSearchResultsElement).toBeTruthy();
        const renderedSearchResults = Object.values(setupOwnerSearchResultsElement.querySelectorAll('li'));
        expect(renderedSearchResults.length).toBe(mockSearchResults.length);

        // Select a search result
        const expectedResult = mockSearchResults[0];
        const selectedResult = renderedSearchResults[0];
        expect(selectedResult.dataset.key).toBe(expectedResult.recordId);
        selectedResult.dispatchEvent(
            new CustomEvent('click', {
                currentTarget: {
                    dataset: { key: expectedResult.recordId }
                }
            })
        );
        await Promise.resolve();
        await Promise.resolve();

        // Save the record & verify the call to the Apex controller
        const expectedNewRecord = { ...mockNewRecord };
        expectedNewRecord.SetupOwnerId = expectedResult.recordId;
        expectedNewRecord.setupOwnerName = expectedResult.label;
        expectedNewRecord.setupOwnerType = 'User';
        const expectedApexSaveParameter = { settingsRecord: expectedNewRecord };
        const saveRecordBtn = loggerSettingsElement.shadowRoot.querySelector('[data-id="save-btn"]');
        saveRecordBtn.click();
        await Promise.resolve();
        expect(saveRecord).toHaveBeenCalledTimes(1);
        expect(saveRecord.mock.calls[0][0]).toEqual(expectedApexSaveParameter);
    });

    it("shows existing record as read-only when 'view' row action is clicked", async () => {
        const loggerSettingsElement = await initializeElement(true);
        deleteRecord.mockResolvedValue(null);

        // Verify the expected Apex/framework calls
        expect(deleteRecord).toHaveBeenCalledTimes(0);

        // Check the component
        const datatable = loggerSettingsElement.shadowRoot.querySelector('lightning-datatable');
        const firstRowRecordId = datatable.data[0].record.Id;
        const rowActionEvent = new CustomEvent('rowaction', {
            detail: {
                action: { name: 'view' },
                row: { Id: firstRowRecordId }
            }
        });
        datatable.dispatchEvent(rowActionEvent);
        await Promise.resolve();

        const recordModal = loggerSettingsElement.shadowRoot.querySelector('.slds-modal');
        expect(recordModal).toBeTruthy();
        const saveBtn = loggerSettingsElement.shadowRoot.querySelector('[data-id="save-btn"]');
        expect(saveBtn).toBeFalsy();
        const cancelBtn = loggerSettingsElement.shadowRoot.querySelector('[data-id="cancel-btn"]');
        expect(cancelBtn).toBeFalsy();

        const inputFields = loggerSettingsElement.shadowRoot.querySelectorAll('lightning-input, lightning-combobox');
        expect(inputFields.length).toBeGreaterThanOrEqual(1);
        inputFields.forEach(inputField => {
            expect(inputField.readOnly).toBe(true);
        });
    });

    it("shows existing record as editable when 'edit' row action is clicked", async () => {
        const loggerSettingsElement = await initializeElement(true);
        deleteRecord.mockResolvedValue(null);

        // Verify the expected Apex/framework calls
        expect(deleteRecord).toHaveBeenCalledTimes(0);

        // Check the component
        const datatable = loggerSettingsElement.shadowRoot.querySelector('lightning-datatable');
        const firstRowRecordId = datatable.data[0].record.Id;
        const rowActionEvent = new CustomEvent('rowaction', {
            detail: {
                action: { name: 'edit' },
                row: { Id: firstRowRecordId }
            }
        });
        datatable.dispatchEvent(rowActionEvent);
        await Promise.resolve();

        const recordModal = loggerSettingsElement.shadowRoot.querySelector('.slds-modal');
        expect(recordModal).toBeTruthy();
        const saveBtn = loggerSettingsElement.shadowRoot.querySelector('[data-id="save-btn"]');
        expect(saveBtn).toBeTruthy();
        const cancelBtn = loggerSettingsElement.shadowRoot.querySelector('[data-id="cancel-btn"]');
        expect(cancelBtn).toBeTruthy();

        const expectedEditableFields = [
            'IsEnabled__c',
            'LoggingLevel__c',
            'DefaultNumberOfDaysToRetainLogs__c',
            'DefaultLogShareAccessLevel__c',
            'DefaultSaveMethod__c',
            'IsApexSystemDebugLoggingEnabled__c',
            'IsJavaScriptConsoleLoggingEnabled__c',
            'IsDataMaskingEnabled__c',
            'IsRecordFieldStrippingEnabled__c',
            'IsAnonymousModeEnabled__c'
        ];
        expectedEditableFields.forEach(fieldDataId => {
            const inputField = loggerSettingsElement.shadowRoot.querySelector('[data-id="' + fieldDataId + '"]');
            expect(inputField.readOnly).toBe(false);
        });
    });

    it("deletes record when 'delete' row action is clicked", async () => {
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
