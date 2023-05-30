// UI
import { createElement } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import logBatchPurge from 'c/logBatchPurge';
import { when } from 'jest-when';

//metadata
import getSchemaForName from '@salesforce/apex/LoggerSObjectMetadata.getSchemaForName';
import canUserRunLogBatchPurger from '@salesforce/apex/LogBatchPurgeController.canUserRunLogBatchPurger';
import getPurgeActionOptions from '@salesforce/apex/LogBatchPurgeController.getPurgeActionOptions';

import runBatchPurge from '@salesforce/apex/LogBatchPurgeController.runBatchPurge';
import getBatchPurgeJobRecords from '@salesforce/apex/LogBatchPurgeController.getBatchPurgeJobRecords';
import getMetrics from '@salesforce/apex/LogBatchPurgeController.getMetrics';

jest.useFakeTimers();
jest.spyOn(global, 'setTimeout');
// Mock metadata
const mockLogObjectSchema = require('./data/getSchemaForName.log.json');
const mockLogEntryObjectSchema = require('./data/getSchemaForName.logEntry.json');
const mockLogEntryTagObjectSchema = require('./data/getSchemaForName.logEntryTag.json');

const mockGetLogMetricsForToday = require('./data/getLogMetrics.Today.json');
const mockGetLogMetricsForThisWeek = require('./data/getLogMetrics.ThisWeek.json');
const mockGetLogMetricsForThisMonth = require('./data/getLogMetrics.ThisMonth.json');
const mockGetLogMetricsWhenNoLogRecords = require('./data/getLogMetrics.noLogRecords.json');

const mockgetBatchPurgeJobRecords = require('./data/getBatchPurgeJobRecords.json');
const mockGetPurgeActionOptions = require('./data/getPurgeActionOptions.json');
const mockrunBatchPurge = require('./data/runBatchPurge.json');

const SHOW_TOAST_EVENT_NAME = 'lightning__showtoast';
const SHOW_TOAST_EVENT_HANDLER = jest.fn();

jest.mock('lightning/confirm');

jest.mock(
    '@salesforce/apex/LogBatchPurgeController.getMetrics',
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

jest.mock(
    '@salesforce/apex/LogBatchPurgeController.getPurgeActionOptions',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/LogBatchPurgeController.getBatchPurgeJobRecords',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/LogBatchPurgeController.canUserRunLogBatchPurger',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/LogBatchPurgeController.runBatchPurge',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

async function initializeElement(enablerunBatchPurgeAccess) {
    // Assign mock values for resolved Apex promises
    // getSchemaForName
    //     .mockResolvedValue(mockLogEntryTagObjectSchema)
    //     .mockReturnValueOnce(mockLogObjectSchema)
    //   .mockReturnValueOnce(mockLogEntryObjectSchema);

    when(getSchemaForName).calledWith({ sobjectApiName: 'Log__c' }).mockResolvedValue(mockLogObjectSchema);
    when(getSchemaForName).calledWith({ sobjectApiName: 'LogEntry__c' }).mockResolvedValue(mockLogEntryObjectSchema);
    when(getSchemaForName).calledWith({ sobjectApiName: 'LogEntryTag__c' }).mockResolvedValue(mockLogEntryTagObjectSchema);

    when(getMetrics).calledWith({ dateFilterOption: 'TODAY' }).mockResolvedValue(mockGetLogMetricsForToday);
    when(getMetrics).calledWith({ dateFilterOption: 'THIS_WEEK' }).mockResolvedValue(mockGetLogMetricsForThisWeek);
    when(getMetrics).calledWith({ dateFilterOption: 'THIS_MONTH' }).mockResolvedValue(mockGetLogMetricsForThisMonth);

    getPurgeActionOptions.mockResolvedValue(mockGetPurgeActionOptions);
    getBatchPurgeJobRecords.mockResolvedValue(mockgetBatchPurgeJobRecords);

    canUserRunLogBatchPurger.mockResolvedValue(enablerunBatchPurgeAccess);
    runBatchPurge.mockResolvedValue(mockrunBatchPurge);

    // Create the component
    const logBatchPurgeElement = createElement('c-log-batch-purge', { is: logBatchPurge });
    document.body.appendChild(logBatchPurgeElement);

    await Promise.resolve('resolves getSchemaForName()'); // for log__c
    await Promise.resolve('resolves getSchemaForName()'); // for logEntry__c
    await Promise.resolve('resolves getSchemaForName()'); // for logEntryTag__c
    await Promise.resolve('resolves getPurgeActionOptions()');
    await Promise.resolve('resolves getMetrics()');
    await Promise.resolve('resolves getBatchPurgeJobRecords()');
    await Promise.resolve('resolves canUserRunLogBatchPurger()');
    return logBatchPurgeElement;
}

describe('logBatchPurge lwc tests', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
        jest.clearAllTimers();
    });

    it('load the component sucessfully', async () => {
        const logBatchPurgeElement = await initializeElement(false);
        expect(getPurgeActionOptions).toHaveBeenCalledTimes(1);
        expect(getSchemaForName).toHaveBeenCalledTimes(3);
        expect(canUserRunLogBatchPurger).toHaveBeenCalledTimes(1);
        expect(getMetrics).toHaveBeenCalledTimes(1);
        expect(getBatchPurgeJobRecords).toHaveBeenCalledTimes(1);
        // Check the component
        const metricsTable = logBatchPurgeElement.shadowRoot.querySelector('[data-id="metrics-table"]');
        expect(metricsTable).toBeTruthy();
        const dateFilterRadioGroup = logBatchPurgeElement.shadowRoot.querySelector('lightning-radio-group[data-id="date-filter"]');
        expect(dateFilterRadioGroup).toBeTruthy();
        expect(dateFilterRadioGroup.value).toEqual('TODAY');

        const refreshButton = logBatchPurgeElement.shadowRoot.querySelector('lightning-button-icon[data-id="refresh-button"]');
        expect(refreshButton).toBeTruthy();

        const runBatchPurge = logBatchPurgeElement.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]');
        expect(runBatchPurge).toBeTruthy();

        const purgeBatchJobsDatatable = logBatchPurgeElement.shadowRoot.querySelector('lightning-datatable[data-id="purge-batch-jobs"');
        expect(purgeBatchJobsDatatable).toBeTruthy();
        expect(purgeBatchJobsDatatable.data).toEqual(mockgetBatchPurgeJobRecords);
    });

    it('displays log metrics for today by default', async () => {
        const logBatchPurgeElement = await initializeElement(false);
        const dateFilterRadioGroup = logBatchPurgeElement.shadowRoot.querySelector('lightning-radio-group[data-id="date-filter"]');
        expect(dateFilterRadioGroup.value).toEqual('TODAY');
        const metricsTable = logBatchPurgeElement.shadowRoot.querySelector('[data-id="metrics-table"]');
        expect(metricsTable).toBeTruthy();
        const logObjectTextElement = logBatchPurgeElement.shadowRoot.querySelector('[data-id="Log"]');
        expect(logObjectTextElement.innerHTML).toEqual('Log');
        const logObjectEntryTextElement = logBatchPurgeElement.shadowRoot.querySelector('[data-id="Log Entry"]');
        expect(logObjectEntryTextElement.innerHTML).toEqual('Log Entry');

        const logObjectEntryTagTextElement = logBatchPurgeElement.shadowRoot.querySelector('[data-id="Log Entry Tag"]');
        expect(logObjectEntryTagTextElement.innerHTML).toEqual('Log Entry Tag');
        for (var key in mockGetLogMetricsForToday) {
            const summary = mockGetLogMetricsForToday[key];
            for (let i = 0; i < summary.length; i++) {
                const dataId = key + '-' + summary[i].LogPurgeAction__c;
                const labelElement = logBatchPurgeElement.shadowRoot.querySelector('[data-label="' + dataId + '"]');
                expect(labelElement.innerHTML).toEqual(summary[i].LogPurgeAction__c);
                const dataElement = logBatchPurgeElement.shadowRoot.querySelector('[data-id="' + dataId + '"]');
                expect(dataElement.innerHTML).toEqual(summary[i].expr0 + '');
            }
        }
    });

    it('displays metrics for this week when user select this week date filter', async () => {
        const logBatchPurgeElement = await initializeElement(false);
        const dateFilterRadioGroup = logBatchPurgeElement.shadowRoot.querySelector('lightning-radio-group[data-id="date-filter"]');

        dateFilterRadioGroup.dispatchEvent(new CustomEvent('change', { detail: { value: 'THIS_WEEK' } }));
        await Promise.resolve('resolves getSchemaForName()'); // for log__c
        await Promise.resolve('resolves getSchemaForName()'); // for logEntry__c
        await Promise.resolve('resolves getSchemaForName()'); // for logEntryTag__c
        await Promise.resolve('resolves getPurgeActionOptions()');
        await Promise.resolve('resolves getMetrics()');
        await Promise.resolve('resolves getBatchPurgeJobRecords()');
        await Promise.resolve('resolves canUserRunLogBatchPurger()');

        expect(dateFilterRadioGroup.value).toEqual('THIS_WEEK');

        const metricsTable = logBatchPurgeElement.shadowRoot.querySelector('[data-id="metrics-table"]');

        expect(metricsTable).toBeTruthy();
        const logObjectTextElement = logBatchPurgeElement.shadowRoot.querySelector('[data-id="Log"]');
        expect(logObjectTextElement.innerHTML).toEqual('Log');
        const logObjectEntryTextElement = logBatchPurgeElement.shadowRoot.querySelector('[data-id="Log Entry"]');
        expect(logObjectEntryTextElement.innerHTML).toEqual('Log Entry');

        const logObjectEntryTagTextElement = logBatchPurgeElement.shadowRoot.querySelector('[data-id="Log Entry Tag"]');
        expect(logObjectEntryTagTextElement.innerHTML).toEqual('Log Entry Tag');

        for (var key in mockGetLogMetricsForThisWeek) {
            const summary = mockGetLogMetricsForThisWeek[key];
            for (let i = 0; i < summary.length; i++) {
                const dataId = key + '-' + summary[i].LogPurgeAction__c;
                const labelElement = logBatchPurgeElement.shadowRoot.querySelector('[data-label="' + dataId + '"]');
                expect(labelElement.innerHTML).toEqual(summary[i].LogPurgeAction__c);
                const dataElement = logBatchPurgeElement.shadowRoot.querySelector('[data-id="' + dataId + '"]');
                expect(dataElement.innerHTML).toEqual(summary[i].expr0 + '');
            }
        }
    });

    it('displays metrics for this week when user select "this month" date filter', async () => {
        const logBatchPurgeElement = await initializeElement(false);
        const dateFilterRadioGroup = logBatchPurgeElement.shadowRoot.querySelector('lightning-radio-group[data-id="date-filter"]');

        dateFilterRadioGroup.dispatchEvent(new CustomEvent('change', { detail: { value: 'THIS_MONTH' } }));

        await Promise.resolve('resolves getSchemaForName()'); // for log__c
        await Promise.resolve('resolves getSchemaForName()'); // for logEntry__c
        await Promise.resolve('resolves getSchemaForName()'); // for logEntryTag__c
        await Promise.resolve('resolves getPurgeActionOptions()');
        await Promise.resolve('resolves getMetrics()');
        await Promise.resolve('resolves getBatchPurgeJobRecords()');
        await Promise.resolve('resolves canUserRunLogBatchPurger()');

        expect(dateFilterRadioGroup.value).toEqual('THIS_MONTH');

        const metricsTable = logBatchPurgeElement.shadowRoot.querySelector('[data-id="metrics-table"]');

        expect(metricsTable).toBeTruthy();
        const logObjectTextElement = logBatchPurgeElement.shadowRoot.querySelector('[data-id="Log"]');
        expect(logObjectTextElement.innerHTML).toEqual('Log');
        const logObjectEntryTextElement = logBatchPurgeElement.shadowRoot.querySelector('[data-id="Log Entry"]');
        expect(logObjectEntryTextElement.innerHTML).toEqual('Log Entry');

        const logObjectEntryTagTextElement = logBatchPurgeElement.shadowRoot.querySelector('[data-id="Log Entry Tag"]');
        expect(logObjectEntryTagTextElement.innerHTML).toEqual('Log Entry Tag');

        for (var key in mockGetLogMetricsForThisMonth) {
            const summary = mockGetLogMetricsForThisMonth[key];
            for (let i = 0; i < summary.length; i++) {
                const dataId = key + '-' + summary[i].LogPurgeAction__c;
                const labelElement = logBatchPurgeElement.shadowRoot.querySelector('[data-label="' + dataId + '"]');
                expect(labelElement.innerHTML).toEqual(summary[i].LogPurgeAction__c);
                const dataElement = logBatchPurgeElement.shadowRoot.querySelector('[data-id="' + dataId + '"]');
                expect(dataElement.innerHTML).toEqual(summary[i].expr0 + '');
            }
        }
    });

    it('displays metrics table with zero count when no records found to purge', async () => {
        when(getSchemaForName).calledWith({ sobjectApiName: 'Log__c' }).mockResolvedValue(mockLogObjectSchema);
        when(getSchemaForName).calledWith({ sobjectApiName: 'LogEntry__c' }).mockResolvedValue(mockLogEntryObjectSchema);
        when(getSchemaForName).calledWith({ sobjectApiName: 'LogEntryTag__c' }).mockResolvedValue(mockLogEntryTagObjectSchema);

        getMetrics.mockResolvedValue(mockGetLogMetricsWhenNoLogRecords);

        getPurgeActionOptions.mockResolvedValue(mockGetPurgeActionOptions);
        getBatchPurgeJobRecords.mockResolvedValue(mockgetBatchPurgeJobRecords);

        canUserRunLogBatchPurger.mockResolvedValue(true);
        runBatchPurge.mockResolvedValue(mockrunBatchPurge);

        // Create the component
        const logBatchPurgeElement = createElement('c-log-batch-purge', { is: logBatchPurge });
        document.body.appendChild(logBatchPurgeElement);

        await Promise.resolve('resolves getSchemaForName()'); // for log__c
        await Promise.resolve('resolves getSchemaForName()'); // for logEntry__c
        await Promise.resolve('resolves getSchemaForName()'); // for logEntryTag__c
        await Promise.resolve('resolves getPurgeActionOptions()');
        await Promise.resolve('resolves getMetrics()');
        await Promise.resolve('resolves getBatchPurgeJobRecords()');
        await Promise.resolve('resolves canUserRunLogBatchPurger()');

        const metricsTable = logBatchPurgeElement.shadowRoot.querySelector('[data-id="metrics-table"]');

        expect(metricsTable).toBeTruthy();
        const logObjectTextElement = logBatchPurgeElement.shadowRoot.querySelector('[data-id="Log"]');
        expect(logObjectTextElement.innerHTML).toEqual('Log');
        const logObjectEntryTextElement = logBatchPurgeElement.shadowRoot.querySelector('[data-id="Log Entry"]');
        expect(logObjectEntryTextElement.innerHTML).toEqual('Log Entry');

        const logObjectEntryTagTextElement = logBatchPurgeElement.shadowRoot.querySelector('[data-id="Log Entry Tag"]');
        expect(logObjectEntryTagTextElement.innerHTML).toEqual('Log Entry Tag');
        const logObjects = ['Log__c', 'LogEntry__c', 'LogEntryTag__c'];
        for (const objectAPIName of logObjects) {
            for (const action of mockGetPurgeActionOptions) {
                const key = objectAPIName + '-' + action.value;
                const purgeActionLabelElement = logBatchPurgeElement.shadowRoot.querySelector('[data-label="' + key + '"]');
                expect(purgeActionLabelElement.innerHTML).toEqual(action.value);
                const purgeActionDataElement = logBatchPurgeElement.shadowRoot.querySelector('[data-id="' + key + '"]');
                expect(purgeActionDataElement.innerHTML).toEqual('0');
            }
        }
    });

    it("disable the run purge button when user doesn't have delete permission on log object ", async () => {
        const logBatchPurgeElement = await initializeElement(false);
        const metricsTable = logBatchPurgeElement.shadowRoot.querySelector('[data-id="metrics-table"]');

        const runBatchPurge = logBatchPurgeElement.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]');
        expect(runBatchPurge).toBeTruthy();
        expect(runBatchPurge.disabled).toEqual(true);
    });

    it('enable the run purge button when user has delete permission on log object ', async () => {
        const logBatchPurgeElement = await initializeElement(true);

        const runBatchPurgeBtn = logBatchPurgeElement.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]');
        expect(runBatchPurgeBtn).toBeTruthy();
        expect(runBatchPurgeBtn.disabled).toEqual(false);
    });

    it('displays the purge job records in datatable', async () => {
        const logBatchPurgeElement = await initializeElement(true);

        const purgeBatchJobsDatatable = logBatchPurgeElement.shadowRoot.querySelector('lightning-datatable[data-id="purge-batch-jobs"');
        expect(purgeBatchJobsDatatable).toBeTruthy();
        expect(purgeBatchJobsDatatable.data).toEqual(mockgetBatchPurgeJobRecords);
    });

    it('it show success toast when user confirms running the batch job', async () => {
        LightningConfirm.open = jest.fn().mockResolvedValue(true);
        const logBatchPurgeElement = await initializeElement(true);
        logBatchPurgeElement.addEventListener(SHOW_TOAST_EVENT_NAME, SHOW_TOAST_EVENT_HANDLER);

        const runBatchPurgeBtn = logBatchPurgeElement.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]');
        runBatchPurgeBtn.click();

        await Promise.resolve('Show & confirm LightningConfirm modal');
        await Promise.resolve('Call Apex controller method runBatchPurge()');
        await Promise.resolve('Dispatch Toast event');
        await Promise.resolve('Call Apex controller method loadPurgeBatchJobRecords()');
        expect(SHOW_TOAST_EVENT_HANDLER).toBeCalledTimes(1);
    });

    it('it refresh the purge batch records when user clicks on the refresh button', async () => {
        const logBatchPurgeElement = await initializeElement(true);
        const refreshButton = document.querySelector('c-log-batch-purge').shadowRoot.querySelector('lightning-button-icon');
        refreshButton.click();
        await Promise.resolve('resolves connectedCallback()');
        await Promise.resolve('resolves getPurgeActionOptions()');
        await Promise.resolve('resolves loadMetricRecords()');
        await Promise.resolve('resolves loadpurgeBatchJobRecords()');
        await Promise.resolve('resolves canUserRunLogBatchPurger()');

        const purgeBatchJobsDatatable = logBatchPurgeElement.shadowRoot.querySelector('lightning-datatable[data-id="purge-batch-jobs"');
        expect(purgeBatchJobsDatatable).toBeTruthy();

        expect(purgeBatchJobsDatatable.data).toEqual(mockgetBatchPurgeJobRecords);
    });

    it('it refresh the purge batch records for every 10 sec', async () => {
        const logBatchPurgeElement = await initializeElement(true);
        const callBack = jest.fn();
        expect(setTimeout).toHaveBeenCalledTimes(1);
        expect(setTimeout).toHaveBeenLastCalledWith(expect.any(Function), 10000);
        jest.runOnlyPendingTimers();
        expect(setTimeout).toHaveBeenCalledTimes(2);
        expect(setTimeout).toHaveBeenLastCalledWith(expect.any(Function), 10000);
    });
});
