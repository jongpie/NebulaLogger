// UI
import { createElement } from 'lwc';
import LoggerSettings from 'c/loggerSettings';

// LoggerSettings__c metadata
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import canUserModifyLoggerSettings from '@salesforce/apex/LoggerSettingsController.canUserModifyLoggerSettings';
import getPicklistOptions from '@salesforce/apex/LoggerSettingsController.getPicklistOptions';

// LoggerSettings__c data
import getRecords from '@salesforce/apex/LoggerSettingsController.getRecords';
import createRecord from '@salesforce/apex/LoggerSettingsController.createRecord';

// Mock metadata
const mockObjectInfo = require('./data/getObjectInfo.json');
const mockPicklistOptions = require('./data/getPicklistOptions.json');

// Mock data
const mockRecords = require('./data/getRecords.json');
const mockNewRecord = require('./data/createRecord.json');

// async function flushPromises() {
//     return new Promise(resolve => setTimeout(resolve, 0));
// }

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
    '@salesforce/apex/LoggerSettingsController.createRecord',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

describe('Logger Settings lwc tests', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('loads component without modify access', async () => {
        // Assign mock values for resolved Apex promises
        canUserModifyLoggerSettings.mockResolvedValue(false);
        getPicklistOptions.mockResolvedValue(mockPicklistOptions);
        getRecords.mockResolvedValue(mockRecords);

        // Create the component
        const loggerSettingsElement = createElement('c-logger-settings', { is: LoggerSettings });
        document.body.appendChild(loggerSettingsElement);

        // Emit data from @wire
        await getObjectInfo.emit(mockObjectInfo);
        await Promise.resolve();

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
        // Assign mock values for resolved Apex promises
        canUserModifyLoggerSettings.mockResolvedValue(true);
        getPicklistOptions.mockResolvedValue(mockPicklistOptions);
        getRecords.mockResolvedValue(mockRecords);

        // Create the component
        const loggerSettingsElement = createElement('c-logger-settings', { is: LoggerSettings });
        document.body.appendChild(loggerSettingsElement);

        // Emit data from @wire
        await getObjectInfo.emit(mockObjectInfo);
        await Promise.resolve();

        // Verify the expected Apex/framework calls
        expect(canUserModifyLoggerSettings).toHaveBeenCalledTimes(1);
        // expect(getObjectInfo).toHaveBeenCalledTimes(1);
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
        // Assign mock values for resolved Apex promises
        canUserModifyLoggerSettings.mockResolvedValue(true);
        getPicklistOptions.mockResolvedValue(mockPicklistOptions);
        getRecords.mockResolvedValue(mockRecords);
        createRecord.mockResolvedValue(mockNewRecord);

        // Create the component
        const loggerSettingsElement = createElement('c-logger-settings', { is: LoggerSettings });
        document.body.appendChild(loggerSettingsElement);

        // Emit data from @wire
        await getObjectInfo.emit(mockObjectInfo);
        await Promise.resolve();
        createRecord.mockResolvedValue(mockNewRecord);

        // Clickety click
        const newRecordBtn = loggerSettingsElement.shadowRoot.querySelector('lightning-button[data-id="new-btn"]');
        newRecordBtn.click();
        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();


        const datatable = loggerSettingsElement.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).toBeTruthy();
        expect(datatable.data).toEqual(mockRecords);


        // Check the component
        expect(createRecord).toHaveBeenCalledTimes(1);
        // expect(createRecord.mock.calls.length).toBe(1);
        // expect(createRecord.mock.results).toEqual(mockNewRecord);
        // expect(createRecord.mock.calls[0][0]).toEqual(mockNewRecord);

        // expect(createRecord.mock.results.length).toEqual(1);
        // expect(createRecord.mock.results[0].type).toEqual('return');
        // expect(createRecord.mock.results[0].value).toEqual(mockNewRecord);
        // expect(createRecord.mock.calls[0][0]).toEqual(mockNewRecord);
        // expect(getObjectInfo.getLastConfig()).toEqual(mockObjectInfo);
        // expect(createRecord.mock.calls[0][0]).toEqual(mockNewRecord);
        return flushPromises().then(() => {

            const newRecordModalContainer = loggerSettingsElement.shadowRoot.querySelector('.slds-modal');
            expect(loggerSettingsElement.showRecordModal).toBeTruthy();
            expect(newRecordModalContainer).toBeTruthy();
        });

    });
});
