import { createElement } from '@lwc/engine-dom';
import LightningConfirm from 'lightning/confirm';
import LogBatchPurge from 'c/logBatchPurge';

import getSchemaForName from '@salesforce/apex/LoggerSObjectMetadata.getSchemaForName';
import canUserRunLogBatchPurger from '@salesforce/apex/LogBatchPurgeController.canUserRunLogBatchPurger';
import getPurgeActionOptions from '@salesforce/apex/LogBatchPurgeController.getPurgeActionOptions';
import runBatchPurge from '@salesforce/apex/LogBatchPurgeController.runBatchPurge';
import getBatchPurgeJobRecords from '@salesforce/apex/LogBatchPurgeController.getBatchPurgeJobRecords';
import getMetrics from '@salesforce/apex/LogBatchPurgeController.getMetrics';

const mockSchemasByApiName = {
  Log__c: require('./data/getSchemaForName.log.json'),
  LogEntry__c: require('./data/getSchemaForName.logEntry.json'),
  LogEntryTag__c: require('./data/getSchemaForName.logEntryTag.json')
};

const mockMetricsByDateFilter = {
  TODAY: require('./data/getLogMetrics.Today.json'),
  THIS_WEEK: require('./data/getLogMetrics.ThisWeek.json'),
  THIS_MONTH: require('./data/getLogMetrics.ThisMonth.json')
};

const mockGetLogMetricsWhenNoLogRecords = require('./data/getLogMetrics.noLogRecords.json');
const mockBatchPurgeJobRecords = require('./data/getBatchPurgeJobRecords.json');
const mockGetPurgeActionOptions = require('./data/getPurgeActionOptions.json');
const mockRunBatchPurge = require('./data/runBatchPurge.json');

const SHOW_TOAST_EVENT_NAME = 'lightning__showtoast';
const POLLING_FREQUENCY_MS = 10000;

jest.mock('lightning/confirm');

jest.mock('@salesforce/apex/LogBatchPurgeController.getMetrics', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/LoggerSObjectMetadata.getSchemaForName', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/LogBatchPurgeController.getPurgeActionOptions', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/LogBatchPurgeController.getBatchPurgeJobRecords', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/LogBatchPurgeController.canUserRunLogBatchPurger', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/LogBatchPurgeController.runBatchPurge', () => ({ default: jest.fn() }), { virtual: true });

function configureApexMocks({ canRunBatchPurge = false, metricsByDateFilter = mockMetricsByDateFilter } = {}) {
  getSchemaForName.mockImplementation(({ sobjectApiName }) => Promise.resolve(mockSchemasByApiName[sobjectApiName]));
  getMetrics.mockImplementation(({ dateFilterOption }) => Promise.resolve(metricsByDateFilter[dateFilterOption]));
  getPurgeActionOptions.mockResolvedValue(mockGetPurgeActionOptions);
  getBatchPurgeJobRecords.mockResolvedValue(mockBatchPurgeJobRecords);
  canUserRunLogBatchPurger.mockResolvedValue(canRunBatchPurge);
  runBatchPurge.mockResolvedValue(mockRunBatchPurge);
}

async function flushPromises() {
  // Pump several microtask ticks so chained promise.then handlers in
  // connectedCallback settle; LWC reflects state updates between awaits.
  await Promise.resolve()
    .then(() => Promise.resolve())
    .then(() => Promise.resolve())
    .then(() => Promise.resolve())
    .then(() => Promise.resolve())
    .then(() => Promise.resolve())
    .then(() => Promise.resolve())
    .then(() => Promise.resolve())
    .then(() => Promise.resolve())
    .then(() => Promise.resolve());
}

async function createComponent({ canRunBatchPurge = false, metricsByDateFilter = mockMetricsByDateFilter } = {}) {
  configureApexMocks({ canRunBatchPurge, metricsByDateFilter });
  const element = createElement('c-log-batch-purge', { is: LogBatchPurge });
  document.body.appendChild(element);
  await flushPromises();
  return element;
}

function getMetricCount(element, sObjectApiName, purgeActionValue) {
  return element.shadowRoot.querySelector(`[data-id="${sObjectApiName}-${purgeActionValue}"]`).textContent;
}

function assertMetricsRendered(element, expectedMetrics) {
  const renderedCounts = [];
  const expectedCounts = [];
  for (const sObjectApiName of Object.keys(expectedMetrics)) {
    for (const summary of expectedMetrics[sObjectApiName]) {
      renderedCounts.push([sObjectApiName, summary.LogPurgeAction__c, getMetricCount(element, sObjectApiName, summary.LogPurgeAction__c)]);
      expectedCounts.push([sObjectApiName, summary.LogPurgeAction__c, String(summary.recordCount)]);
    }
  }
  expect(renderedCounts).toEqual(expectedCounts);
}

describe('c-log-batch-purge', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it('loads the component and renders all primary controls', async () => {
    const element = await createComponent();

    expect(getPurgeActionOptions).toHaveBeenCalledTimes(1);
    expect(getSchemaForName).toHaveBeenCalledTimes(3);
    expect(canUserRunLogBatchPurger).toHaveBeenCalledTimes(1);
    expect(getMetrics).toHaveBeenCalledTimes(1);
    expect(getBatchPurgeJobRecords).toHaveBeenCalledTimes(1);

    expect(element.shadowRoot.querySelector('[data-id="metrics-table"]')).toBeTruthy();
    expect(element.shadowRoot.querySelector('lightning-button-icon[data-id="refresh-button"]')).toBeTruthy();
    expect(element.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]')).toBeTruthy();
    const dateFilter = element.shadowRoot.querySelector('lightning-radio-group[data-id="date-filter"]');
    expect(dateFilter.value).toEqual('TODAY');
    const purgeBatchJobsDatatable = element.shadowRoot.querySelector('lightning-datatable[data-id="purge-batch-jobs"]');
    expect(purgeBatchJobsDatatable.data).toHaveLength(mockBatchPurgeJobRecords.length);
    purgeBatchJobsDatatable.data.forEach((row, index) => {
      expect(row).toMatchObject(mockBatchPurgeJobRecords[index]);
      expect(row.CreatedByName).toEqual(mockBatchPurgeJobRecords[index].CreatedBy.Name);
    });
  });

  it('displays metrics for the default TODAY filter on initial render', async () => {
    const element = await createComponent();

    assertMetricsRendered(element, mockMetricsByDateFilter.TODAY);
  });

  it.each([
    ['THIS_WEEK', 'this week'],
    ['THIS_MONTH', 'this month']
  ])('displays metrics keyed by %s when filter is changed to %s', async dateFilterValue => {
    const element = await createComponent();
    const dateFilter = element.shadowRoot.querySelector('lightning-radio-group[data-id="date-filter"]');

    dateFilter.dispatchEvent(new CustomEvent('change', { detail: { value: dateFilterValue } }));
    await flushPromises();

    expect(dateFilter.value).toEqual(dateFilterValue);
    assertMetricsRendered(element, mockMetricsByDateFilter[dateFilterValue]);
  });

  it('renders zeros for every purge action when no records are eligible to purge', async () => {
    const metricsByDateFilter = { ...mockMetricsByDateFilter, TODAY: mockGetLogMetricsWhenNoLogRecords };
    const element = await createComponent({ metricsByDateFilter });

    for (const objectApiName of ['Log__c', 'LogEntry__c', 'LogEntryTag__c']) {
      for (const action of mockGetPurgeActionOptions) {
        expect(getMetricCount(element, objectApiName, action.value)).toEqual('0');
      }
    }
  });

  it('disables the run purge button when the user lacks delete permission', async () => {
    const element = await createComponent({ canRunBatchPurge: false });

    const runBatchPurgeBtn = element.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]');
    expect(runBatchPurgeBtn.disabled).toBe(true);
  });

  it('enables the run purge button when the user has delete permission', async () => {
    const element = await createComponent({ canRunBatchPurge: true });

    const runBatchPurgeBtn = element.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]');
    expect(runBatchPurgeBtn.disabled).toBe(false);
  });

  it('keeps the run purge button disabled until the permission check resolves', async () => {
    let resolveCanRun;
    canUserRunLogBatchPurger.mockReturnValue(
      new Promise(resolve => {
        resolveCanRun = resolve;
      })
    );
    getSchemaForName.mockImplementation(({ sobjectApiName }) => Promise.resolve(mockSchemasByApiName[sobjectApiName]));
    getMetrics.mockResolvedValue(mockMetricsByDateFilter.TODAY);
    getPurgeActionOptions.mockResolvedValue(mockGetPurgeActionOptions);
    getBatchPurgeJobRecords.mockResolvedValue(mockBatchPurgeJobRecords);

    const element = createElement('c-log-batch-purge', { is: LogBatchPurge });
    document.body.appendChild(element);
    await flushPromises();

    // Permission check has not yet resolved — destructive button must remain disabled.
    expect(element.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]').disabled).toBe(true);

    resolveCanRun(true);
    await flushPromises();
    expect(element.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]').disabled).toBe(false);
  });

  it('only fetches object schemas once across multiple metric reloads', async () => {
    const element = await createComponent({ canRunBatchPurge: true });

    expect(getSchemaForName).toHaveBeenCalledTimes(3);

    const dateFilter = element.shadowRoot.querySelector('lightning-radio-group[data-id="date-filter"]');
    dateFilter.dispatchEvent(new CustomEvent('change', { detail: { value: 'THIS_WEEK' } }));
    await flushPromises();
    dateFilter.dispatchEvent(new CustomEvent('change', { detail: { value: 'THIS_MONTH' } }));
    await flushPromises();

    expect(getSchemaForName).toHaveBeenCalledTimes(3);
    expect(getMetrics).toHaveBeenCalledTimes(3);
  });

  it('shows a success toast when the user confirms running the batch job', async () => {
    LightningConfirm.open = jest.fn().mockResolvedValue(true);
    const element = await createComponent({ canRunBatchPurge: true });
    const toastHandler = jest.fn();
    element.addEventListener(SHOW_TOAST_EVENT_NAME, toastHandler);

    element.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]').click();
    await flushPromises();

    expect(runBatchPurge).toHaveBeenCalledTimes(1);
    expect(toastHandler).toHaveBeenCalledTimes(1);
    expect(toastHandler.mock.calls[0][0].detail.variant).toEqual('success');
  });

  it('does not run the batch job when the user cancels the confirmation prompt', async () => {
    LightningConfirm.open = jest.fn().mockResolvedValue(false);
    const element = await createComponent({ canRunBatchPurge: true });

    element.shadowRoot.querySelector('lightning-button[data-id="run-purge-button"]').click();
    await flushPromises();

    expect(runBatchPurge).not.toHaveBeenCalled();
  });

  it('reloads the purge batch records when the refresh button is clicked', async () => {
    const element = await createComponent({ canRunBatchPurge: true });
    expect(getBatchPurgeJobRecords).toHaveBeenCalledTimes(1);

    element.shadowRoot.querySelector('lightning-button-icon[data-id="refresh-button"]').click();
    await flushPromises();

    expect(getBatchPurgeJobRecords).toHaveBeenCalledTimes(2);
  });

  it('polls for purge batch records every 10 seconds', async () => {
    jest.useFakeTimers();
    const setTimeoutSpy = jest.spyOn(global, 'setTimeout');
    try {
      configureApexMocks({ canRunBatchPurge: true });
      const element = createElement('c-log-batch-purge', { is: LogBatchPurge });
      document.body.appendChild(element);
      await flushPromises();

      expect(setTimeoutSpy).toHaveBeenLastCalledWith(expect.any(Function), POLLING_FREQUENCY_MS);
      const initialJobLoadCount = getBatchPurgeJobRecords.mock.calls.length;

      jest.runOnlyPendingTimers();
      await flushPromises();

      expect(getBatchPurgeJobRecords.mock.calls.length).toBeGreaterThan(initialJobLoadCount);
      expect(setTimeoutSpy).toHaveBeenLastCalledWith(expect.any(Function), POLLING_FREQUENCY_MS);
    } finally {
      setTimeoutSpy.mockRestore();
      jest.useRealTimers();
    }
  });
});
