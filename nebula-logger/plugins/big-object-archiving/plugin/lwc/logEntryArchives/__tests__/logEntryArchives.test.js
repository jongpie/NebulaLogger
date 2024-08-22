import { createElement } from 'lwc';
import LogEntryArchives from 'c/logEntryArchives';
import getLogEntryArchives from '@salesforce/apex/LogEntryArchiveController.getLogEntryArchives';
import getSchemaForName from '@salesforce/apex/LoggerSObjectMetadata.getSchemaForName';

const MOCK_DATA = [{ Message__c: 'Some message', TransactionId__c: 'ABC-123', TransactionEntryNumber__c: 1 }];
const MOCK_SCHEMA = require('./data/LoggerSObjectMetadata.getSchemaForName.json');

const SHOW_TOAST_EVENT_NAME = 'lightning__showtoast';
const SHOW_TOAST_EVENT_HANDLER = jest.fn();
jest.mock(
  '@salesforce/apex/LogEntryArchiveController.getLogEntryArchives',
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

async function initializeElement() {
  const element = createElement('c-log-entry-archives', {
    is: LogEntryArchives
  });
  element.addEventListener(SHOW_TOAST_EVENT_NAME, SHOW_TOAST_EVENT_HANDLER);
  document.body.appendChild(element);

  await Promise.resolve('resolves connectedCallback()');
  await Promise.resolve('resolves getSchemaForName()');
  await Promise.resolve('resolves getLogEntryArchives()');
  await Promise.resolve('resolves getLogEntryArchives().then()');
  await Promise.resolve('resolves lightning-datatable re-render');

  return element;
}

describe('c-log-entry-archives', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it('initializes component', async () => {
    getSchemaForName.mockResolvedValue(MOCK_SCHEMA);
    getLogEntryArchives.mockResolvedValue(MOCK_DATA);

    const element = await initializeElement();

    expect(document.title).toEqual('Log Entry Archives');
    const expectedTableData = JSON.parse(JSON.stringify(MOCK_DATA));
    expectedTableData.forEach(record => {
      record.compositeId = record.TransactionId__c + record.TransactionEntryNumber__c;
    });
    const table = element.shadowRoot.querySelector('lightning-datatable');
    expect(table).toBeTruthy();
    expect(table.data).toEqual(expectedTableData);
    expect(getSchemaForName).toHaveBeenCalledTimes(1);
    expect(getLogEntryArchives).toHaveBeenCalledTimes(1);
    const expectedApexParameters = {
      endDate: element.shadowRoot.querySelector('[data-id="endDate"]').value,
      messageSearchTerm: element.shadowRoot.querySelector('[data-id="messageSearch"]').value,
      minimumLoggingLevelOrdinal: Number(element.shadowRoot.querySelector('[data-id="loggingLevelFilter"]').value),
      rowLimit: Number(element.shadowRoot.querySelector('[data-id="rowLimitFilter"]').value),
      startDate: element.shadowRoot.querySelector('[data-id="startDate"]').value
    };
    expect(getLogEntryArchives.mock.calls[0][0]).toBeDefined();
    expect(getLogEntryArchives.mock.calls[0][0]).toEqual(expectedApexParameters);
  });

  it('shows toast message for apex controller error', async () => {
    getSchemaForName.mockResolvedValue(MOCK_SCHEMA);
    const mockApexError = new Error('It broke!');
    getLogEntryArchives.mockRejectedValue(mockApexError);

    const element = await initializeElement();

    const table = element.shadowRoot.querySelector('lightning-datatable');
    expect(table).toBeTruthy();
    expect(table.data.length).toEqual(0);
    expect(getSchemaForName).toHaveBeenCalledTimes(1);
    expect(getLogEntryArchives).toHaveBeenCalledTimes(1);
    const expectedApexParameters = {
      endDate: element.shadowRoot.querySelector('[data-id="endDate"]').value,
      messageSearchTerm: element.shadowRoot.querySelector('[data-id="messageSearch"]').value,
      minimumLoggingLevelOrdinal: Number(element.shadowRoot.querySelector('[data-id="loggingLevelFilter"]').value),
      rowLimit: Number(element.shadowRoot.querySelector('[data-id="rowLimitFilter"]').value),
      startDate: element.shadowRoot.querySelector('[data-id="startDate"]').value
    };
    expect(getLogEntryArchives.mock.calls[0][0]).toBeDefined();
    expect(getLogEntryArchives.mock.calls[0][0]).toEqual(expectedApexParameters);
    expect(SHOW_TOAST_EVENT_HANDLER).toBeCalledTimes(1);
  });

  it('requeries when start date changes', async () => {
    getSchemaForName.mockResolvedValue(MOCK_SCHEMA);
    getLogEntryArchives.mockResolvedValue(MOCK_DATA);
    const element = await initializeElement();
    const threeDaysAgo = new Date(new Date().getTime() + -3 * 24 * 60 * 60 * 1000).toISOString();
    expect(getLogEntryArchives).toHaveBeenCalledTimes(1);
    expect(getLogEntryArchives.mock.calls[0][0]).toBeDefined();
    expect(getLogEntryArchives.mock.calls[0][0].startDate).toBeDefined();
    expect(getLogEntryArchives.mock.calls[0][0].startDate).not.toEqual(threeDaysAgo);

    const startDateInput = element.shadowRoot.querySelector('[data-id="startDate"]');
    startDateInput.dispatchEvent(
      new CustomEvent('change', {
        detail: {
          value: threeDaysAgo
        }
      })
    );

    await Promise.resolve('resolves getLogEntryArchives()');
    await Promise.resolve('resolves getLogEntryArchives().then()');
    await Promise.resolve('resolves lightning-datatable re-render');
    expect(getLogEntryArchives.mock.calls[1][0]).toBeDefined();
    expect(getLogEntryArchives.mock.calls[1][0].startDate).toEqual(threeDaysAgo);
  });

  it('requeries when end date changes', async () => {
    getSchemaForName.mockResolvedValue(MOCK_SCHEMA);
    getLogEntryArchives.mockResolvedValue(MOCK_DATA);
    const element = await initializeElement();
    const threeDaysAgo = new Date(new Date().getTime() + -3 * 24 * 60 * 60 * 1000).toISOString();
    expect(getLogEntryArchives).toHaveBeenCalledTimes(1);
    expect(getLogEntryArchives.mock.calls[0][0]).toBeDefined();
    expect(getLogEntryArchives.mock.calls[0][0].endDate).toBeDefined();
    expect(getLogEntryArchives.mock.calls[0][0].endDate).not.toEqual(threeDaysAgo);

    const endDateInput = element.shadowRoot.querySelector('[data-id="endDate"]');
    endDateInput.dispatchEvent(
      new CustomEvent('change', {
        detail: {
          value: threeDaysAgo
        }
      })
    );

    await Promise.resolve('resolves getLogEntryArchives()');
    await Promise.resolve('resolves getLogEntryArchives().then()');
    await Promise.resolve('resolves lightning-datatable re-render');
    expect(getLogEntryArchives.mock.calls[1][0]).toBeDefined();
    expect(getLogEntryArchives.mock.calls[1][0].endDate).toEqual(threeDaysAgo);
  });

  it('requeries when logging level changes', async () => {
    getSchemaForName.mockResolvedValue(MOCK_SCHEMA);
    getLogEntryArchives.mockResolvedValue(MOCK_DATA);
    const element = await initializeElement();
    const errorLoggingLevelOrdinal = '8';
    expect(getLogEntryArchives).toHaveBeenCalledTimes(1);
    expect(getLogEntryArchives.mock.calls[0][0]).toBeDefined();
    expect(getLogEntryArchives.mock.calls[0][0].minimumLoggingLevelOrdinal).toBeDefined();
    expect(getLogEntryArchives.mock.calls[0][0].minimumLoggingLevelOrdinal).not.toEqual(Number(errorLoggingLevelOrdinal));

    const minimumLoggingLevelOrdinalInput = element.shadowRoot.querySelector('[data-id="loggingLevelFilter"]');
    minimumLoggingLevelOrdinalInput.value = errorLoggingLevelOrdinal;
    minimumLoggingLevelOrdinalInput.dispatchEvent(
      new CustomEvent('change', {
        target: {
          value: errorLoggingLevelOrdinal
        }
      })
    );

    await Promise.resolve('resolves getLogEntryArchives()');
    await Promise.resolve('resolves getLogEntryArchives().then()');
    await Promise.resolve('resolves lightning-datatable re-render');
    expect(getLogEntryArchives.mock.calls[1][0]).toBeDefined();
    expect(getLogEntryArchives.mock.calls[1][0].minimumLoggingLevelOrdinal).toEqual(Number(errorLoggingLevelOrdinal));
  });

  it('requeries when message search term changes', async () => {
    getSchemaForName.mockResolvedValue(MOCK_SCHEMA);
    getLogEntryArchives.mockResolvedValue(MOCK_DATA);
    const element = await initializeElement();
    const newMessageSearchTerm = 'hello, is this thing working??';
    expect(getLogEntryArchives).toHaveBeenCalledTimes(1);
    expect(getLogEntryArchives.mock.calls[0][0]).toBeDefined();
    expect(getLogEntryArchives.mock.calls[0][0].messageSearchTerm).toBeUndefined();
    expect(getLogEntryArchives.mock.calls[0][0].messageSearchTerm).not.toEqual(newMessageSearchTerm);

    const messageSearchTermFilterInput = element.shadowRoot.querySelector('[data-id="messageSearch"]');
    messageSearchTermFilterInput.value = newMessageSearchTerm;
    messageSearchTermFilterInput.dispatchEvent(
      new CustomEvent('change', {
        target: {
          value: newMessageSearchTerm
        }
      })
    );

    await Promise.resolve('resolves getLogEntryArchives()');
    await Promise.resolve('resolves getLogEntryArchives().then()');
    await Promise.resolve('resolves lightning-datatable re-render');
    expect(getLogEntryArchives.mock.calls[1][0]).toBeDefined();
    expect(getLogEntryArchives.mock.calls[1][0].messageSearchTerm).toEqual(newMessageSearchTerm);
  });

  it('requeries when row limit changes', async () => {
    getSchemaForName.mockResolvedValue(MOCK_SCHEMA);
    getLogEntryArchives.mockResolvedValue(MOCK_DATA);
    const element = await initializeElement();
    const newRowLimit = '987654321';
    expect(getLogEntryArchives).toHaveBeenCalledTimes(1);
    expect(getLogEntryArchives.mock.calls[0][0]).toBeDefined();
    expect(getLogEntryArchives.mock.calls[0][0].rowLimit).toBeDefined();
    expect(getLogEntryArchives.mock.calls[0][0].rowLimit).not.toEqual(Number(newRowLimit));

    const rowLimitFilterInput = element.shadowRoot.querySelector('[data-id="rowLimitFilter"]');
    rowLimitFilterInput.value = newRowLimit;
    rowLimitFilterInput.dispatchEvent(
      new CustomEvent('change', {
        target: {
          value: newRowLimit
        }
      })
    );

    await Promise.resolve('resolves getLogEntryArchives()');
    await Promise.resolve('resolves getLogEntryArchives().then()');
    await Promise.resolve('resolves lightning-datatable re-render');
    expect(getLogEntryArchives.mock.calls[1][0]).toBeDefined();
    expect(getLogEntryArchives.mock.calls[1][0].rowLimit).toEqual(Number(newRowLimit));
  });

  it('requeries when refresh button is clicked', async () => {
    getSchemaForName.mockResolvedValue(MOCK_SCHEMA);
    getLogEntryArchives.mockResolvedValue(MOCK_DATA);
    const element = await initializeElement();
    const expectedApexParameters = {
      endDate: element.shadowRoot.querySelector('[data-id="endDate"]').value,
      messageSearchTerm: element.shadowRoot.querySelector('[data-id="messageSearch"]').value,
      minimumLoggingLevelOrdinal: Number(element.shadowRoot.querySelector('[data-id="loggingLevelFilter"]').value),
      rowLimit: Number(element.shadowRoot.querySelector('[data-id="rowLimitFilter"]').value),
      startDate: element.shadowRoot.querySelector('[data-id="startDate"]').value
    };
    expect(getLogEntryArchives.mock.calls[0][0]).toBeDefined();
    expect(getLogEntryArchives.mock.calls[0][0]).toEqual(expectedApexParameters);

    const refreshButton = element.shadowRoot.querySelector('[data-id="refresh-btn"]');
    refreshButton.click();

    await Promise.resolve('resolves getLogEntryArchives()');
    await Promise.resolve('resolves getLogEntryArchives().then()');
    await Promise.resolve('resolves lightning-datatable re-render');
    expect(getLogEntryArchives.mock.calls[1][0]).toBeDefined();
    expect(getLogEntryArchives.mock.calls[1][0]).toEqual(expectedApexParameters);
  });
});
