import { createElement } from '@lwc/engine-dom';
import LightningConfirm from 'lightning/confirm';
import logBatchPurge from 'c/logBatchPurge';

import canUserRunLogBatchPurger from '@salesforce/apex/LogBatchPurgeController.canUserRunLogBatchPurger';
import getBatchPurgeJobRecords from '@salesforce/apex/LogBatchPurgeController.getBatchPurgeJobRecords';
import getMetrics from '@salesforce/apex/LogBatchPurgeController.getMetrics';
import getPurgeActionOptions from '@salesforce/apex/LogBatchPurgeController.getPurgeActionOptions';
import getRegisteredPurgeableSObjectTypes from '@salesforce/apex/LogBatchPurgeController.getRegisteredPurgeableSObjectTypes';
import runBatchPurge from '@salesforce/apex/LogBatchPurgeController.runBatchPurge';

const mockGetLogMetricsForToday = require('./data/getLogMetrics.Today.json');
const mockGetLogMetricsForThisWeek = require('./data/getLogMetrics.ThisWeek.json');
const mockGetLogMetricsForThisMonth = require('./data/getLogMetrics.ThisMonth.json');
const mockGetLogMetricsWhenNoLogRecords = require('./data/getLogMetrics.noLogRecords.json');

const mockGetBatchPurgeJobRecords = require('./data/getBatchPurgeJobRecords.json');
const mockGetPurgeActionOptions = require('./data/getPurgeActionOptions.json');
const mockRunBatchPurge = require('./data/runBatchPurge.json');

const SHOW_TOAST_EVENT_NAME = 'lightning__showtoast';

jest.useFakeTimers();
jest.spyOn(global, 'setInterval');
jest.spyOn(global, 'clearInterval');

jest.mock('lightning/confirm');

jest.mock('@salesforce/apex/LogBatchPurgeController.getMetrics', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/LogBatchPurgeController.getPurgeActionOptions', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/LogBatchPurgeController.getBatchPurgeJobRecords', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/LogBatchPurgeController.canUserRunLogBatchPurger', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/LogBatchPurgeController.runBatchPurge', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/LogBatchPurgeController.getRegisteredPurgeableSObjectTypes', () => ({ default: jest.fn() }), { virtual: true });

const METRICS_MOCKS_BY_DATE_FILTER = {
  TODAY: mockGetLogMetricsForToday,
  THIS_WEEK: mockGetLogMetricsForThisWeek,
  THIS_MONTH: mockGetLogMetricsForThisMonth
};

function configureMocks({ canRunPurger = false, registeredTypes = [], metricsOverride } = {}) {
  getMetrics.mockImplementation(({ dateFilterOption }) => Promise.resolve(metricsOverride ?? METRICS_MOCKS_BY_DATE_FILTER[dateFilterOption]));
  getPurgeActionOptions.mockResolvedValue(mockGetPurgeActionOptions);
  getRegisteredPurgeableSObjectTypes.mockResolvedValue(registeredTypes);
  getBatchPurgeJobRecords.mockResolvedValue(mockGetBatchPurgeJobRecords);
  canUserRunLogBatchPurger.mockResolvedValue(canRunPurger);
  runBatchPurge.mockResolvedValue(mockRunBatchPurge);
}

async function flushMicrotasks(cycles = 12) {
  for (let index = 0; index < cycles; index++) {
    // eslint-disable-next-line
    await Promise.resolve();
  }
}

async function initializeElement(options = {}) {
  configureMocks(options);
  const element = createElement('c-log-batch-purge', { is: logBatchPurge });
  document.body.appendChild(element);
  await flushMicrotasks();
  return element;
}

describe('logBatchPurge lwc tests', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    jest.clearAllTimers();
    window.localStorage.clear();
  });

  it('sets the document title on connectedCallback', async () => {
    await initializeElement();

    expect(document.title).toEqual('Log Batch Purge | Salesforce');
  });

  it('loads the component successfully', async () => {
    const element = await initializeElement();

    expect(getPurgeActionOptions).toHaveBeenCalledTimes(1);
    expect(canUserRunLogBatchPurger).toHaveBeenCalledTimes(1);
    expect(getMetrics).toHaveBeenCalledTimes(1);
    expect(getMetrics).toHaveBeenCalledWith({ dateFilterOption: 'TODAY' });
    expect(getBatchPurgeJobRecords).toHaveBeenCalledTimes(1);
    expect(getRegisteredPurgeableSObjectTypes).toHaveBeenCalledTimes(1);

    const metricsTable = element.shadowRoot.querySelector('[data-id="metrics-table"]');
    expect(metricsTable).toBeTruthy();
    const dateFilterRadioGroup = element.shadowRoot.querySelector('lightning-radio-group[data-id="date-filter"]');
    expect(dateFilterRadioGroup).toBeTruthy();
    expect(dateFilterRadioGroup.value).toEqual('TODAY');

    const refreshButton = element.shadowRoot.querySelector('lightning-button-icon[data-id="refresh-button"]');
    expect(refreshButton).toBeTruthy();
    const runPurgeButton = element.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]');
    expect(runPurgeButton).toBeTruthy();

    const jobsDatatable = element.shadowRoot.querySelector('lightning-datatable[data-id="purge-batch-jobs"]');
    expect(jobsDatatable).toBeTruthy();
    expect(jobsDatatable.data).toEqual(mockGetBatchPurgeJobRecords.map(record => ({ ...record, CreatedByName: record.CreatedBy.Name })));
  });

  it('offers all four retention-date filter options including All Time', async () => {
    const element = await initializeElement();
    const dateFilterRadioGroup = element.shadowRoot.querySelector('lightning-radio-group[data-id="date-filter"]');

    const values = dateFilterRadioGroup.options.map(option => option.value);

    expect(values).toEqual(['TODAY', 'THIS_WEEK', 'THIS_MONTH', 'ALL_TIME']);
  });

  it('labels the four purge-date buttons as Today / This Week / This Month / All Time', async () => {
    const element = await initializeElement();
    const dateFilterRadioGroup = element.shadowRoot.querySelector('lightning-radio-group[data-id="date-filter"]');

    const labels = dateFilterRadioGroup.options.map(option => option.label);

    expect(labels).toEqual(['Purge Date: Today', 'Purge Date: This Week', 'Purge Date: This Month', 'Purge Date: All Time']);
  });

  it('renders the retention subtitle explaining what the current filter shows', async () => {
    const element = await initializeElement();

    const subtitle = element.shadowRoot.querySelector('[data-id="retention-subtitle"]');
    expect(subtitle.textContent).toContain('Purge Date: Today');
    expect(subtitle.textContent).toContain('retention date');
  });

  it('updates the retention subtitle text when the user changes the filter', async () => {
    const element = await initializeElement();
    const dateFilterRadioGroup = element.shadowRoot.querySelector('lightning-radio-group[data-id="date-filter"]');

    dateFilterRadioGroup.dispatchEvent(new CustomEvent('change', { detail: { value: 'ALL_TIME' } }));
    await flushMicrotasks();

    const subtitle = element.shadowRoot.querySelector('[data-id="retention-subtitle"]');
    expect(subtitle.textContent).toContain('Purge Date: All Time');
  });

  it('renames the first column header to SObject Type', async () => {
    const element = await initializeElement();

    const headerCells = element.shadowRoot.querySelectorAll('[data-id="metrics-table"] thead th div');
    expect(headerCells[0].textContent).toEqual('SObject Type');
    expect(headerCells[0].title).toEqual('SObject Type');
  });

  it('displays log metrics for today by default', async () => {
    const element = await initializeElement();

    for (const [key, aggregateResults] of Object.entries(mockGetLogMetricsForToday)) {
      for (const summary of aggregateResults) {
        const dataId = `${key}-${summary.LogPurgeAction__c}`;
        const labelElement = element.shadowRoot.querySelector(`[data-label="${dataId}"]`);
        expect(labelElement.textContent).toEqual(summary.LogPurgeAction__c);
        const dataElement = element.shadowRoot.querySelector(`[data-id="${dataId}"]`);
        expect(dataElement.textContent).toEqual(String(summary.expr0));
      }
    }
  });

  it('reloads metrics with THIS_WEEK when the user picks the This Week button', async () => {
    const element = await initializeElement();
    const dateFilterRadioGroup = element.shadowRoot.querySelector('lightning-radio-group[data-id="date-filter"]');

    dateFilterRadioGroup.dispatchEvent(new CustomEvent('change', { detail: { value: 'THIS_WEEK' } }));
    await flushMicrotasks();

    expect(dateFilterRadioGroup.value).toEqual('THIS_WEEK');
    expect(getMetrics).toHaveBeenLastCalledWith({ dateFilterOption: 'THIS_WEEK' });
    for (const [key, aggregateResults] of Object.entries(mockGetLogMetricsForThisWeek)) {
      for (const summary of aggregateResults) {
        const dataId = `${key}-${summary.LogPurgeAction__c}`;
        const dataElement = element.shadowRoot.querySelector(`[data-id="${dataId}"]`);
        expect(dataElement.textContent).toEqual(String(summary.expr0));
      }
    }
  });

  it('reloads metrics with THIS_MONTH when the user picks the This Month button', async () => {
    const element = await initializeElement();
    const dateFilterRadioGroup = element.shadowRoot.querySelector('lightning-radio-group[data-id="date-filter"]');

    dateFilterRadioGroup.dispatchEvent(new CustomEvent('change', { detail: { value: 'THIS_MONTH' } }));
    await flushMicrotasks();

    expect(dateFilterRadioGroup.value).toEqual('THIS_MONTH');
    expect(getMetrics).toHaveBeenLastCalledWith({ dateFilterOption: 'THIS_MONTH' });
    for (const [key, aggregateResults] of Object.entries(mockGetLogMetricsForThisMonth)) {
      for (const summary of aggregateResults) {
        const dataId = `${key}-${summary.LogPurgeAction__c}`;
        const dataElement = element.shadowRoot.querySelector(`[data-id="${dataId}"]`);
        expect(dataElement.textContent).toEqual(String(summary.expr0));
      }
    }
  });

  it('reloads metrics with ALL_TIME when the user picks the All Time button', async () => {
    const element = await initializeElement();
    const dateFilterRadioGroup = element.shadowRoot.querySelector('lightning-radio-group[data-id="date-filter"]');
    getMetrics.mockImplementationOnce(() => Promise.resolve(mockGetLogMetricsForToday));

    dateFilterRadioGroup.dispatchEvent(new CustomEvent('change', { detail: { value: 'ALL_TIME' } }));
    await flushMicrotasks();

    expect(dateFilterRadioGroup.value).toEqual('ALL_TIME');
    expect(getMetrics).toHaveBeenLastCalledWith({ dateFilterOption: 'ALL_TIME' });
  });

  it('displays zero counts when no records qualify for purging', async () => {
    const element = await initializeElement({ metricsOverride: mockGetLogMetricsWhenNoLogRecords });

    for (const objectApiName of ['Log__c', 'LogEntry__c', 'LogEntryTag__c']) {
      for (const action of mockGetPurgeActionOptions) {
        const dataId = `${objectApiName}-${action.value}`;
        const dataElement = element.shadowRoot.querySelector(`[data-id="${dataId}"]`);
        expect(dataElement.textContent).toEqual('0');
      }
    }
  });

  it('appends plugin-registered SObject rows to the metrics table with a caption naming the registering plugin', async () => {
    const registeredType = {
      apiName: 'LoggerTestPurgeable__c',
      localApiName: 'LoggerTestPurgeable__c',
      label: 'Logger Test Purgeable',
      labelPlural: 'Logger Test Purgeables',
      registeredQuery:
        'SELECT Id FROM LoggerTestPurgeable__c WHERE RetentionDate__c <= :RETENTION_END_DATE AND RetentionDate__c != NULL ORDER BY RetentionDate__c',
      registeringPluginDeveloperName: 'Big_Object_Archiving'
    };
    const metricsWithPlugin = {
      ...mockGetLogMetricsForToday,
      LoggerTestPurgeable__c: [{ LogPurgeAction__c: 'Delete', expr0: 7 }]
    };

    const element = await initializeElement({ registeredTypes: [registeredType], metricsOverride: metricsWithPlugin });

    const captionElements = element.shadowRoot.querySelectorAll('[data-id="plugin-caption"]');
    expect(captionElements).toHaveLength(1);
    expect(captionElements[0].textContent).toEqual('Registered by plugin Big_Object_Archiving');
    const deleteCountElement = element.shadowRoot.querySelector('[data-id="LoggerTestPurgeable__c-Delete"]');
    expect(deleteCountElement.textContent).toEqual('7');
  });

  it('falls back to a generic plugin caption when the registering plugin developer name is not set', async () => {
    const registeredType = {
      apiName: 'LoggerTestPurgeable__c',
      localApiName: 'LoggerTestPurgeable__c',
      label: 'Logger Test Purgeable',
      labelPlural: 'Logger Test Purgeables',
      registeredQuery:
        'SELECT Id FROM LoggerTestPurgeable__c WHERE RetentionDate__c <= :RETENTION_END_DATE AND RetentionDate__c != NULL ORDER BY RetentionDate__c',
      registeringPluginDeveloperName: null
    };

    const element = await initializeElement({
      registeredTypes: [registeredType],
      metricsOverride: { ...mockGetLogMetricsForToday, LoggerTestPurgeable__c: [] }
    });

    const captionElement = element.shadowRoot.querySelector('[data-id="plugin-caption"]');
    expect(captionElement.textContent).toEqual('Registered by a plugin');
  });

  it('does NOT render a plugin caption on core SObject rows', async () => {
    const element = await initializeElement();

    const captions = element.shadowRoot.querySelectorAll('[data-id="plugin-caption"]');
    expect(captions).toHaveLength(0);
  });

  it('renders one row per plugin-registered SObject type, preserving registration order', async () => {
    const first = {
      apiName: 'LoggerAlphaChild__c',
      localApiName: 'LoggerAlphaChild__c',
      label: 'Logger Alpha Child',
      labelPlural: 'Logger Alpha Children',
      registeredQuery:
        'SELECT Id FROM LoggerAlphaChild__c WHERE RetentionDate__c <= :RETENTION_END_DATE AND RetentionDate__c != NULL ORDER BY RetentionDate__c',
      registeringPluginDeveloperName: 'Alpha_Plugin'
    };
    const second = {
      apiName: 'LoggerBetaParent__c',
      localApiName: 'LoggerBetaParent__c',
      label: 'Logger Beta Parent',
      labelPlural: 'Logger Beta Parents',
      registeredQuery:
        'SELECT Id FROM LoggerBetaParent__c WHERE RetentionDate__c <= :RETENTION_END_DATE AND RetentionDate__c != NULL ORDER BY RetentionDate__c',
      registeringPluginDeveloperName: 'Beta_Plugin'
    };
    const metricsWithPlugins = {
      ...mockGetLogMetricsForToday,
      LoggerAlphaChild__c: [{ LogPurgeAction__c: 'Delete', expr0: 3 }],
      LoggerBetaParent__c: [{ LogPurgeAction__c: 'Delete', expr0: 11 }]
    };

    const element = await initializeElement({ registeredTypes: [first, second], metricsOverride: metricsWithPlugins });

    const captions = Array.from(element.shadowRoot.querySelectorAll('[data-id="plugin-caption"]'));
    expect(captions).toHaveLength(2);
    expect(captions[0].textContent).toEqual('Registered by plugin Alpha_Plugin');
    expect(captions[1].textContent).toEqual('Registered by plugin Beta_Plugin');
    expect(element.shadowRoot.querySelector('[data-id="LoggerAlphaChild__c-Delete"]').textContent).toEqual('3');
    expect(element.shadowRoot.querySelector('[data-id="LoggerBetaParent__c-Delete"]').textContent).toEqual('11');
  });

  it('disables the run-purge button when the user cannot delete logs', async () => {
    const element = await initializeElement({ canRunPurger: false });

    const runPurgeButton = element.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]');
    expect(runPurgeButton.disabled).toEqual(true);
  });

  it('enables the run-purge button when the user has delete permission on Log__c', async () => {
    const element = await initializeElement({ canRunPurger: true });

    const runPurgeButton = element.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]');
    expect(runPurgeButton.disabled).toEqual(false);
  });

  it('shows a success toast when the user confirms running the batch job', async () => {
    LightningConfirm.open = jest.fn().mockResolvedValue(true);
    const element = await initializeElement({ canRunPurger: true });
    const toastHandler = jest.fn();
    element.addEventListener(SHOW_TOAST_EVENT_NAME, toastHandler);

    const runPurgeButton = element.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]');
    runPurgeButton.click();
    await flushMicrotasks();

    expect(toastHandler).toHaveBeenCalledTimes(1);
  });

  it('shows the row-count breakdown in the confirm dialog', async () => {
    LightningConfirm.open = jest.fn().mockResolvedValue(false);
    const element = await initializeElement({ canRunPurger: true });

    const runPurgeButton = element.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]');
    runPurgeButton.click();
    await flushMicrotasks();

    const confirmArgs = LightningConfirm.open.mock.calls[0][0];
    expect(confirmArgs.label).toEqual('Confirm Job Execution');
    expect(confirmArgs.theme).toEqual('warning');
    expect(confirmArgs.message).toContain('This will delete approximately');
    expect(confirmArgs.message).toContain('Log__c:');
    expect(confirmArgs.message).toContain('LogEntry__c:');
    expect(confirmArgs.message).toContain('LogEntryTag__c:');
  });

  it('does not call runBatchPurge when the user declines the confirm dialog', async () => {
    LightningConfirm.open = jest.fn().mockResolvedValue(false);
    const element = await initializeElement({ canRunPurger: true });
    const toastHandler = jest.fn();
    element.addEventListener(SHOW_TOAST_EVENT_NAME, toastHandler);

    const runPurgeButton = element.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]');
    runPurgeButton.click();
    await flushMicrotasks();

    expect(runBatchPurge).not.toHaveBeenCalled();
    expect(toastHandler).not.toHaveBeenCalled();
  });

  it('falls back to a generic warning in the confirm dialog when there are no rows to purge', async () => {
    LightningConfirm.open = jest.fn().mockResolvedValue(false);
    const element = await initializeElement({ canRunPurger: true, metricsOverride: mockGetLogMetricsWhenNoLogRecords });

    const runPurgeButton = element.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]');
    runPurgeButton.click();
    await flushMicrotasks();

    const confirmArgs = LightningConfirm.open.mock.calls[0][0];
    expect(confirmArgs.message).toContain('This will delete data!');
    expect(confirmArgs.message).not.toContain('This will delete approximately');
  });

  it('refreshes the datatable when the user clicks the refresh button', async () => {
    const element = await initializeElement({ canRunPurger: true });
    getBatchPurgeJobRecords.mockClear();

    const refreshButton = element.shadowRoot.querySelector('lightning-button-icon[data-id="refresh-button"]');
    refreshButton.click();
    await flushMicrotasks();

    expect(getBatchPurgeJobRecords).toHaveBeenCalledTimes(1);
  });

  it('refreshes the datatable after a successful purge run', async () => {
    LightningConfirm.open = jest.fn().mockResolvedValue(true);
    const element = await initializeElement({ canRunPurger: true });
    getBatchPurgeJobRecords.mockClear();

    const runPurgeButton = element.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]');
    runPurgeButton.click();
    await flushMicrotasks();

    expect(getBatchPurgeJobRecords).toHaveBeenCalledTimes(1);
  });

  it('does NOT poll automatically when auto-refresh is off by default', async () => {
    await initializeElement();

    expect(setInterval).not.toHaveBeenCalled();
  });

  it('starts polling when the user turns auto-refresh on', async () => {
    const element = await initializeElement();
    const toggle = element.shadowRoot.querySelector('lightning-input[data-id="auto-refresh-toggle"]');

    toggle.dispatchEvent(new CustomEvent('change', { detail: { checked: true } }));

    expect(setInterval).toHaveBeenCalledTimes(1);
    expect(setInterval).toHaveBeenLastCalledWith(expect.any(Function), 10000);
  });

  it('stops polling when the user turns auto-refresh off', async () => {
    const element = await initializeElement();
    const toggle = element.shadowRoot.querySelector('lightning-input[data-id="auto-refresh-toggle"]');

    toggle.dispatchEvent(new CustomEvent('change', { detail: { checked: true } }));
    toggle.dispatchEvent(new CustomEvent('change', { detail: { checked: false } }));

    expect(clearInterval).toHaveBeenCalled();
  });

  it('restarts polling with the new interval when the interval combobox changes', async () => {
    const element = await initializeElement();
    const toggle = element.shadowRoot.querySelector('lightning-input[data-id="auto-refresh-toggle"]');
    toggle.dispatchEvent(new CustomEvent('change', { detail: { checked: true } }));
    setInterval.mockClear();

    const intervalCombobox = element.shadowRoot.querySelector('lightning-combobox[data-id="auto-refresh-interval"]');
    intervalCombobox.dispatchEvent(new CustomEvent('change', { detail: { value: '30000' } }));

    expect(setInterval).toHaveBeenLastCalledWith(expect.any(Function), 30000);
  });

  it('reloads metrics + jobs when the auto-refresh timer fires', async () => {
    const element = await initializeElement();
    const toggle = element.shadowRoot.querySelector('lightning-input[data-id="auto-refresh-toggle"]');
    toggle.dispatchEvent(new CustomEvent('change', { detail: { checked: true } }));
    getMetrics.mockClear();
    getBatchPurgeJobRecords.mockClear();

    jest.advanceTimersByTime(10000);
    await flushMicrotasks();

    expect(getMetrics).toHaveBeenCalledTimes(1);
    expect(getBatchPurgeJobRecords).toHaveBeenCalledTimes(1);
  });

  it('restores the persisted auto-refresh preference from localStorage on load', async () => {
    window.localStorage.setItem('nebula-logger.logBatchPurge.autoRefresh', 'true');
    window.localStorage.setItem('nebula-logger.logBatchPurge.autoRefreshIntervalMs', '30000');

    const element = await initializeElement();

    const toggle = element.shadowRoot.querySelector('lightning-input[data-id="auto-refresh-toggle"]');
    expect(toggle.checked).toEqual(true);
    expect(setInterval).toHaveBeenLastCalledWith(expect.any(Function), 30000);
  });

  it('persists the auto-refresh toggle state to localStorage', async () => {
    const element = await initializeElement();
    const toggle = element.shadowRoot.querySelector('lightning-input[data-id="auto-refresh-toggle"]');

    toggle.dispatchEvent(new CustomEvent('change', { detail: { checked: true } }));

    expect(window.localStorage.getItem('nebula-logger.logBatchPurge.autoRefresh')).toEqual('true');
  });

  it('persists the auto-refresh interval selection to localStorage', async () => {
    const element = await initializeElement();
    const toggle = element.shadowRoot.querySelector('lightning-input[data-id="auto-refresh-toggle"]');
    toggle.dispatchEvent(new CustomEvent('change', { detail: { checked: true } }));

    const intervalCombobox = element.shadowRoot.querySelector('lightning-combobox[data-id="auto-refresh-interval"]');
    intervalCombobox.dispatchEvent(new CustomEvent('change', { detail: { value: '60000' } }));

    expect(window.localStorage.getItem('nebula-logger.logBatchPurge.autoRefreshIntervalMs')).toEqual('60000');
  });

  it('disables the interval combobox when auto-refresh is off', async () => {
    const element = await initializeElement();

    const combobox = element.shadowRoot.querySelector('lightning-combobox[data-id="auto-refresh-interval"]');
    expect(combobox.disabled).toEqual(true);
  });

  it('enables the interval combobox when auto-refresh is on', async () => {
    const element = await initializeElement();
    const toggle = element.shadowRoot.querySelector('lightning-input[data-id="auto-refresh-toggle"]');
    toggle.dispatchEvent(new CustomEvent('change', { detail: { checked: true } }));
    await flushMicrotasks();

    const combobox = element.shadowRoot.querySelector('lightning-combobox[data-id="auto-refresh-interval"]');
    expect(combobox.disabled).toEqual(false);
  });

  it('exposes 5s / 10s / 30s / 60s interval options on the combobox', async () => {
    const element = await initializeElement();

    const combobox = element.shadowRoot.querySelector('lightning-combobox[data-id="auto-refresh-interval"]');
    const values = combobox.options.map(option => option.value);
    expect(values).toEqual(['5000', '10000', '30000', '60000']);
  });

  it('clears the auto-refresh timer when the component is removed from the DOM', async () => {
    const element = await initializeElement();
    const toggle = element.shadowRoot.querySelector('lightning-input[data-id="auto-refresh-toggle"]');
    toggle.dispatchEvent(new CustomEvent('change', { detail: { checked: true } }));
    clearInterval.mockClear();

    document.body.removeChild(element);

    expect(clearInterval).toHaveBeenCalled();
  });

  it('dispatches a sticky error toast when a controller call rejects', async () => {
    const originalConsoleError = console.error;
    console.error = jest.fn();
    configureMocks();
    getMetrics.mockRejectedValueOnce({ body: { message: 'Something exploded' } });
    const toastHandler = jest.fn();
    const element = createElement('c-log-batch-purge', { is: logBatchPurge });
    element.addEventListener(SHOW_TOAST_EVENT_NAME, toastHandler);
    document.body.appendChild(element);
    await flushMicrotasks();

    expect(toastHandler).toHaveBeenCalled();
    const toastDetail = toastHandler.mock.calls[0][0].detail;
    expect(toastDetail.mode).toEqual('sticky');
    expect(toastDetail.variant).toEqual('error');
    expect(toastDetail.title).toEqual('Something exploded');
    console.error = originalConsoleError;
  });

  it('wires the expected column fields onto the jobs datatable', async () => {
    const element = await initializeElement();

    const jobsDatatable = element.shadowRoot.querySelector('lightning-datatable[data-id="purge-batch-jobs"]');
    const columnFieldNames = jobsDatatable.columns.map(column => column.fieldName);
    expect(columnFieldNames).toEqual(['Id', 'JobType', 'JobItemsProcessed', 'NumberOfErrors', 'CreatedDate', 'CreatedByName', 'Status']);
  });
});
