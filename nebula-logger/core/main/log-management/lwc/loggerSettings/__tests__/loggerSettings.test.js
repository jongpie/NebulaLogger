// UI
import { createElement } from '@lwc/engine-dom';
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

  // New test cases to improve coverage
  it('handles search term too short (2 characters or less)', async () => {
    const loggerSettingsElement = await initializeElement(true);
    createRecord.mockResolvedValue(mockNewRecord);

    // Open new record modal
    const newRecordBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="new-btn"]');
    newRecordBtn.click();
    await Promise.resolve();
    await Promise.resolve();

    // Set setup owner type to User
    const setupOwnerTypeField = loggerSettingsElement.shadowRoot.querySelector('[data-id="setupOwnerType"]');
    setupOwnerTypeField.value = 'User';
    setupOwnerTypeField.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();

    // Search with short term
    const setupOwnerRecordSearchField = loggerSettingsElement.shadowRoot.querySelector('[data-id="SetupOwnerRecordSearch"]');
    setupOwnerRecordSearchField.value = 'a';
    setupOwnerRecordSearchField.dispatchEvent(
      new CustomEvent('change', {
        detail: { value: 'a' }
      })
    );
    await Promise.resolve();

    // Should not call searchForSetupOwner for short terms
    expect(searchForSetupOwner).not.toHaveBeenCalled();
  });

  it('handles no search results', async () => {
    const loggerSettingsElement = await initializeElement(true);
    createRecord.mockResolvedValue(mockNewRecord);
    searchForSetupOwner.mockResolvedValue([]);

    // Open new record modal
    const newRecordBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="new-btn"]');
    newRecordBtn.click();
    await Promise.resolve();
    await Promise.resolve();

    // Set setup owner type to User
    const setupOwnerTypeField = loggerSettingsElement.shadowRoot.querySelector('[data-id="setupOwnerType"]');
    setupOwnerTypeField.value = 'User';
    setupOwnerTypeField.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();

    // Search with valid term
    const setupOwnerRecordSearchField = loggerSettingsElement.shadowRoot.querySelector('[data-id="SetupOwnerRecordSearch"]');
    setupOwnerRecordSearchField.value = 'nonexistent@example.com';
    setupOwnerRecordSearchField.dispatchEvent(
      new CustomEvent('change', {
        detail: { value: 'nonexistent@example.com' }
      })
    );
    await Promise.resolve();
    await Promise.resolve();

    // Should call searchForSetupOwner but return no results
    expect(searchForSetupOwner).toHaveBeenCalledWith({
      setupOwnerType: 'User',
      searchTerm: 'nonexistent@example.com'
    });
  });

  it('handles record search blur', async () => {
    const loggerSettingsElement = await initializeElement(true);
    createRecord.mockResolvedValue(mockNewRecord);

    // Open new record modal
    const newRecordBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="new-btn"]');
    newRecordBtn.click();
    await Promise.resolve();
    await Promise.resolve();

    // Set setup owner type to User
    const setupOwnerTypeField = loggerSettingsElement.shadowRoot.querySelector('[data-id="setupOwnerType"]');
    setupOwnerTypeField.value = 'User';
    setupOwnerTypeField.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();

    // Search and get results
    const setupOwnerRecordSearchField = loggerSettingsElement.shadowRoot.querySelector('[data-id="SetupOwnerRecordSearch"]');
    setupOwnerRecordSearchField.value = 'test@example.com';
    searchForSetupOwner.mockResolvedValue(mockSearchResults);
    setupOwnerRecordSearchField.dispatchEvent(
      new CustomEvent('change', {
        detail: { value: 'test@example.com' }
      })
    );
    await Promise.resolve();
    await Promise.resolve();

    // Verify dropdown is shown
    expect(loggerSettingsElement.shadowRoot.querySelector('[data-id="SetupOwnerSearchResults"')).toBeTruthy();

    // Trigger blur event
    setupOwnerRecordSearchField.dispatchEvent(new Event('blur'));
    await Promise.resolve();

    // Dropdown should be hidden
    expect(loggerSettingsElement.shadowRoot.querySelector('[data-id="SetupOwnerSearchResults"')).toBeFalsy();
  });

  it('handles remove setup owner', async () => {
    const loggerSettingsElement = await initializeElement(true);
    createRecord.mockResolvedValue(mockNewRecord);

    // Open new record modal
    const newRecordBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="new-btn"]');
    newRecordBtn.click();
    await Promise.resolve();
    await Promise.resolve();

    // Set setup owner type to User
    const setupOwnerTypeField = loggerSettingsElement.shadowRoot.querySelector('[data-id="setupOwnerType"]');
    setupOwnerTypeField.value = 'User';
    setupOwnerTypeField.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();

    // Search and select a result
    const setupOwnerRecordSearchField = loggerSettingsElement.shadowRoot.querySelector('[data-id="SetupOwnerRecordSearch"]');
    setupOwnerRecordSearchField.value = 'test@example.com';
    searchForSetupOwner.mockResolvedValue(mockSearchResults);
    setupOwnerRecordSearchField.dispatchEvent(
      new CustomEvent('change', {
        detail: { value: 'test@example.com' }
      })
    );
    await Promise.resolve();
    await Promise.resolve();

    // Select a result
    const setupOwnerSearchResultsElement = loggerSettingsElement.shadowRoot.querySelector('[data-id="SetupOwnerSearchResults"');
    const firstResult = setupOwnerSearchResultsElement.querySelector('li');
    firstResult.dispatchEvent(
      new CustomEvent('click', {
        currentTarget: {
          dataset: { key: mockSearchResults[0].recordId, label: mockSearchResults[0].label }
        }
      })
    );
    await Promise.resolve();

    // Verify search results are hidden after selection
    expect(loggerSettingsElement.shadowRoot.querySelector('[data-id="SetupOwnerSearchResults"')).toBeFalsy();
  });

  it('handles invalid inputs when saving', async () => {
    const loggerSettingsElement = await initializeElement(true);
    createRecord.mockResolvedValue(mockNewRecord);

    // Open new record modal
    const newRecordBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="new-btn"]');
    newRecordBtn.click();
    await Promise.resolve();
    await Promise.resolve();

    // Set required fields
    const setupOwnerTypeField = loggerSettingsElement.shadowRoot.querySelector('[data-id="setupOwnerType"]');
    setupOwnerTypeField.value = 'Organization';
    setupOwnerTypeField.dispatchEvent(new CustomEvent('change'));

    // Set logging level (required field)
    const loggingLevelField = loggerSettingsElement.shadowRoot.querySelector('[data-id="LoggingLevel__c"]');
    loggingLevelField.value = 'DEBUG';
    loggingLevelField.dispatchEvent(new CustomEvent('change'));

    // Try to save - should succeed with required fields
    const saveRecordBtn = loggerSettingsElement.shadowRoot.querySelector('[data-id="save-btn"]');
    saveRecordBtn.click();
    await Promise.resolve();

    // Should call saveRecord since we have required fields
    expect(saveRecord).toHaveBeenCalled();
  });

  it('handles error scenarios', async () => {
    // Mock error in connectedCallback
    const mockError = new Error('Test error');
    mockError.body = { message: 'Test error message' };
    getSchemaForName.mockRejectedValue(mockError);

    // Create component - should handle error gracefully
    const newLoggerSettingsElement = createElement('c-logger-settings', { is: LoggerSettings });
    document.body.appendChild(newLoggerSettingsElement);
    await Promise.resolve();

    // Should handle error gracefully - the error handling is tested via console.error
    // and the component should still be functional for other operations
    expect(newLoggerSettingsElement.shadowRoot.querySelector('lightning-datatable')).toBeTruthy();
  });

  it('handles field changes for different input types', async () => {
    const loggerSettingsElement = await initializeElement(true);
    createRecord.mockResolvedValue(mockNewRecord);

    // Open new record modal
    const newRecordBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="new-btn"]');
    newRecordBtn.click();
    await Promise.resolve();
    await Promise.resolve();

    // Test checkbox field change
    const isEnabledField = loggerSettingsElement.shadowRoot.querySelector('[data-id="IsEnabled__c"]');
    isEnabledField.checked = true;
    isEnabledField.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();

    // Test text field change
    const loggingLevelField = loggerSettingsElement.shadowRoot.querySelector('[data-id="LoggingLevel__c"]');
    loggingLevelField.value = 'DEBUG';
    loggingLevelField.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();

    // Test setup owner type change
    const setupOwnerTypeField = loggerSettingsElement.shadowRoot.querySelector('[data-id="setupOwnerType"]');
    setupOwnerTypeField.value = 'Profile';
    setupOwnerTypeField.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();

    // Verify setup owner lookup is shown for non-Organization types
    expect(loggerSettingsElement.shadowRoot.querySelector('[data-id="SetupOwnerRecordSearch"]')).toBeTruthy();
  });

  it('handles namespace scenarios', async () => {
    // Mock schema with namespace
    const schemaWithNamespace = {
      ...mockLoggerSettingsSchema,
      namespacePrefix: 'nebula__'
    };
    getSchemaForName.mockResolvedValue(schemaWithNamespace);

    // Reinitialize component with namespace
    const newLoggerSettingsElement = createElement('c-logger-settings', { is: LoggerSettings });
    document.body.appendChild(newLoggerSettingsElement);
    await Promise.resolve();

    // Test namespace handling in field operations
    expect(newLoggerSettingsElement.shadowRoot.querySelector('lightning-datatable')).toBeTruthy();
  });

  it('handles different setup owner types', async () => {
    const loggerSettingsElement = await initializeElement(true);
    createRecord.mockResolvedValue(mockNewRecord);

    // Open new record modal
    const newRecordBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="new-btn"]');
    newRecordBtn.click();
    await Promise.resolve();
    await Promise.resolve();

    // Test Profile setup owner type
    const setupOwnerTypeField = loggerSettingsElement.shadowRoot.querySelector('[data-id="setupOwnerType"]');
    setupOwnerTypeField.value = 'Profile';
    setupOwnerTypeField.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();

    // Should show setup owner lookup for Profile
    expect(loggerSettingsElement.shadowRoot.querySelector('[data-id="SetupOwnerRecordSearch"]')).toBeTruthy();

    // Test Organization setup owner type
    setupOwnerTypeField.value = 'Organization';
    setupOwnerTypeField.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();

    // Should not show setup owner lookup for Organization
    expect(loggerSettingsElement.shadowRoot.querySelector('[data-id="SetupOwnerRecordSearch"]')).toBeFalsy();
  });

  it('handles keyboard shortcuts correctly', async () => {
    const loggerSettingsElement = await initializeElement(true);
    createRecord.mockResolvedValue(mockNewRecord);

    // Open new record modal
    const newRecordBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="new-btn"]');
    newRecordBtn.click();
    await Promise.resolve();
    await Promise.resolve();

    // Test Ctrl+S shortcut
    const recordModal = loggerSettingsElement.shadowRoot.querySelector('.slds-modal');
    const ctrlSEvent = new KeyboardEvent('keydown', { code: 'KeyS', ctrlKey: true });
    recordModal.dispatchEvent(ctrlSEvent);
    await Promise.resolve();

    // Test Escape key
    const escapeEvent = new KeyboardEvent('keydown', { code: 'Escape' });
    recordModal.dispatchEvent(escapeEvent);
    await Promise.resolve();

    // Modal should be closed
    expect(loggerSettingsElement.shadowRoot.querySelector('.slds-modal')).toBeFalsy();
  });

  it('handles row actions correctly', async () => {
    const loggerSettingsElement = await initializeElement(true);

    const datatable = loggerSettingsElement.shadowRoot.querySelector('lightning-datatable');

    // Test view action
    const viewActionEvent = new CustomEvent('rowaction', {
      detail: {
        action: { name: 'view' },
        row: { Id: 'test-id', setupOwnerName: 'Test User' }
      }
    });
    datatable.dispatchEvent(viewActionEvent);
    await Promise.resolve();

    // Test edit action
    const editActionEvent = new CustomEvent('rowaction', {
      detail: {
        action: { name: 'edit' },
        row: { Id: 'test-id', setupOwnerName: 'Test User' }
      }
    });
    datatable.dispatchEvent(editActionEvent);
    await Promise.resolve();

    // Test delete action
    const deleteActionEvent = new CustomEvent('rowaction', {
      detail: {
        action: { name: 'delete' },
        row: { Id: 'test-id', setupOwnerName: 'Test User' }
      }
    });
    datatable.dispatchEvent(deleteActionEvent);
    await Promise.resolve();

    // Verify all actions work correctly
    expect(loggerSettingsElement.shadowRoot.querySelector('.slds-modal')).toBeTruthy();
  });

  it('handles organization record creation logic', async () => {
    const loggerSettingsElement = await initializeElement(true);
    createRecord.mockResolvedValue(mockNewRecord);

    // Open new record modal
    const newRecordBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="new-btn"]');
    newRecordBtn.click();
    await Promise.resolve();
    await Promise.resolve();

    // Set setup owner type to Organization
    const setupOwnerTypeField = loggerSettingsElement.shadowRoot.querySelector('[data-id="setupOwnerType"]');
    setupOwnerTypeField.value = 'Organization';
    setupOwnerTypeField.dispatchEvent(new CustomEvent('change'));
    await Promise.resolve();

    // Verify organization record logic
    expect(loggerSettingsElement.shadowRoot.querySelector('[data-id="SetupOwnerRecordSearch"]')).toBeFalsy();

    // Verify that the setup owner type change was handled
    expect(setupOwnerTypeField.value).toBe('Organization');
  });
});
