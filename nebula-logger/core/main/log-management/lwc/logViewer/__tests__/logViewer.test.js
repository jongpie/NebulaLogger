import { createElement } from '@lwc/engine-dom';
import LogViewer from 'c/logViewer';
import getLog from '@salesforce/apex/LogViewerController.getLog';

const MOCK_GET_LOG = require('./data/LogViewerController.getLog.json');

document.execCommand = jest.fn();

// Mock window.document.createElement for download functionality
const mockCreateElement = jest.fn();
const mockLink = {
  href: '',
  target: '',
  download: '',
  click: jest.fn()
};
mockCreateElement.mockReturnValue(mockLink);
Object.defineProperty(window.document, 'createElement', {
  value: mockCreateElement,
  writable: true
});

// Mock encodeURIComponent
global.encodeURIComponent = jest.fn(str => `encoded_${str}`);

jest.mock(
  'lightning/platformResourceLoader',
  () => {
    return {
      loadScript() {
        return new Promise((resolve, _) => {
          global.Prism = require('../../../staticresources/LoggerResources/prism.js');
          resolve();
        });
      },
      loadStyle() {
        // No-op for now
        return Promise.resolve();
      }
    };
  },
  { virtual: true }
);
jest.mock(
  '@salesforce/apex/LogViewerController.getLog',
  () => {
    const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

// Mock setTimeout for testing the dataCopied reset
jest.useFakeTimers();

describe('Logger JSON Viewer lwc tests', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    jest.clearAllTimers();
  });

  it('sets document title', async () => {
    const logViewerElement = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewerElement);
    getLog.emit({ ...MOCK_GET_LOG });

    expect(logViewerElement.title).toEqual(MOCK_GET_LOG.log.Name);
  });

  it('defaults to brand button variant', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);
    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve('resolves component rerender after loading log record');

    const inputButton = logViewer.shadowRoot.querySelector('lightning-button-stateful');

    expect(logViewer.title).toEqual(MOCK_GET_LOG.log.Name);
    expect(inputButton.variant).toEqual('brand');
  });

  it('copies the JSON to the clipboard', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);
    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve('resolves component rerender after loading log record');

    let copyBtn = logViewer.shadowRoot.querySelector('lightning-button-stateful[data-id="copy-btn"]');
    copyBtn.click();

    await Promise.resolve('resolves copy-to-clipboard function');
    const tab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="json-content"]');
    expect(tab.value).toEqual('json');
    tab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for tab');
    const clipboardContent = JSON.parse(logViewer.shadowRoot.querySelector('c-logger-code-viewer').code);
    const reconstructedLog = { ...MOCK_GET_LOG.log };
    reconstructedLog[MOCK_GET_LOG.logEntriesRelationshipName] = [...MOCK_GET_LOG.logEntries];
    expect(clipboardContent).toEqual(reconstructedLog);
    expect(document.execCommand).toHaveBeenCalledWith('copy');
  });

  it('copies the log file to the clipboard', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);
    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve('resolves component rerender after loading log record');

    let copyBtn = logViewer.shadowRoot.querySelector('lightning-button-stateful[data-id="copy-btn"]');
    copyBtn.click();

    await Promise.resolve('resolves copy-to-clipboard function');
    const tab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="file-content"]');
    expect(tab.value).toEqual('file');
    tab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for tab');
    let expectedContentLines = [];
    MOCK_GET_LOG.logEntries.forEach(logEntry => {
      const columns = [];
      columns.push('[' + new Date(logEntry.EpochTimestamp__c).toISOString() + ' - ' + logEntry.LoggingLevel__c + ']');
      columns.push('[Message]\n' + logEntry.Message__c);
      columns.push('\n[Stack Trace]\n' + logEntry.StackTrace__c);

      expectedContentLines.push(columns.join('\n'));
    });
    const clipboardContent = logViewer.shadowRoot.querySelector('c-logger-code-viewer').code;
    expect(clipboardContent).toEqual(expectedContentLines.join('\n\n' + '-'.repeat(36) + '\n\n'));
    expect(document.execCommand).toHaveBeenCalledWith('copy');
  });

  it('handles tab activation for JSON content', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);
    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve('resolves component rerender after loading log record');

    const tab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="json-content"]');
    tab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for tab');

    expect(logViewer.currentMode.label).toEqual('Record JSON');
    expect(logViewer.currentMode.value).toEqual('json');
    expect(logViewer.currentMode.extension).toEqual('json');
    expect(logViewer.currentMode.data).toBeDefined();
  });

  it('handles tab activation for file content', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);
    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve('resolves component rerender after loading log record');

    const tab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="file-content"]');
    tab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for tab');

    expect(logViewer.currentMode.label).toEqual('Log File');
    expect(logViewer.currentMode.value).toEqual('file');
    expect(logViewer.currentMode.extension).toEqual('log');
    expect(logViewer.currentMode.data).toBeDefined();
  });

  it('downloads JSON file correctly', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);
    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve('resolves component rerender after loading log record');

    // Activate JSON tab first
    const tab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="json-content"]');
    tab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for tab');

    // Click download button
    const downloadBtn = logViewer.shadowRoot.querySelector('lightning-button');
    downloadBtn.click();
    await Promise.resolve('resolves download function');

    expect(mockCreateElement).toHaveBeenCalledWith('a');
    expect(mockLink.href).toContain('data:text;charset=utf-8,encoded_');
    expect(mockLink.target).toEqual('_blank');
    expect(mockLink.download).toContain(MOCK_GET_LOG.log.Name);
    expect(mockLink.download).toContain(MOCK_GET_LOG.log.OrganizationId__c);
    expect(mockLink.download).toContain('.json');
    expect(mockLink.click).toHaveBeenCalled();
  });

  it('downloads log file correctly', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);
    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve('resolves component rerender after loading log record');

    // Activate file tab first
    const tab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="file-content"]');
    tab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for tab');

    // Click download button
    const downloadBtn = logViewer.shadowRoot.querySelector('lightning-button');
    downloadBtn.click();
    await Promise.resolve('resolves download function');

    expect(mockCreateElement).toHaveBeenCalledWith('a');
    expect(mockLink.href).toContain('data:text;charset=utf-8,encoded_');
    expect(mockLink.target).toEqual('_blank');
    expect(mockLink.download).toContain(MOCK_GET_LOG.log.Name);
    expect(mockLink.download).toContain(MOCK_GET_LOG.log.OrganizationId__c);
    expect(mockLink.download).toContain('.log');
    expect(mockLink.click).toHaveBeenCalled();
  });

  it('handles copy to clipboard with success state and timeout reset', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);
    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve('resolves component rerender after loading log record');

    // Activate JSON tab first
    const tab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="json-content"]');
    tab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for tab');

    // Click copy button
    const copyBtn = logViewer.shadowRoot.querySelector('lightning-button-stateful[data-id="copy-btn"]');
    copyBtn.click();
    await Promise.resolve('resolves copy-to-clipboard function');

    // Check that dataCopied is set to true
    expect(logViewer.dataCopied).toBe(true);
    expect(logViewer.variant).toEqual('success');

    // Fast-forward time to trigger the timeout
    jest.advanceTimersByTime(5000);

    // Check that dataCopied is reset to false
    expect(logViewer.dataCopied).toBe(false);
    expect(logViewer.variant).toEqual('brand');
  });

  it('handles wire service with no data gracefully', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);

    // Emit undefined data
    getLog.emit(undefined);
    await Promise.resolve('resolves component rerender');

    expect(logViewer.isLoaded).toBe(false);
    expect(logViewer.log).toEqual({});
  });

  it('handles wire service with empty data gracefully', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);

    // Emit empty data
    getLog.emit({});
    await Promise.resolve('resolves component rerender');

    expect(logViewer.isLoaded).toBe(false);
    expect(logViewer.log).toEqual({});
  });

  it('handles wire service with partial data gracefully', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);

    // Emit partial data (missing log or logEntries)
    getLog.emit({ log: MOCK_GET_LOG.log });
    await Promise.resolve('resolves component rerender');

    expect(logViewer.isLoaded).toBe(false);
    expect(logViewer.log).toEqual({});
  });

  it('handles log entries with missing fields gracefully', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);

    // Create mock data with missing fields
    const mockDataWithMissingFields = {
      log: { ...MOCK_GET_LOG.log },
      logEntries: [
        {
          EpochTimestamp__c: null,
          LoggingLevel__c: null,
          Message__c: null,
          StackTrace__c: null
        }
      ],
      logEntriesRelationshipName: MOCK_GET_LOG.logEntriesRelationshipName
    };

    getLog.emit(mockDataWithMissingFields);
    await Promise.resolve('resolves component rerender');

    expect(logViewer.isLoaded).toBe(true);

    // Activate file tab to test _loadLogFileContent with missing fields
    const tab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="file-content"]');
    tab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for tab');

    // Should handle null/undefined values gracefully
    expect(logViewer.currentMode.data).toBeDefined();
  });

  it('handles empty log entries array', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);

    // Create mock data with empty log entries
    const mockDataWithEmptyEntries = {
      log: { ...MOCK_GET_LOG.log },
      logEntries: [],
      logEntriesRelationshipName: MOCK_GET_LOG.logEntriesRelationshipName
    };

    getLog.emit(mockDataWithEmptyEntries);
    await Promise.resolve('resolves component rerender');

    expect(logViewer.isLoaded).toBe(true);

    // Activate file tab to test _loadLogFileContent with empty array
    const tab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="file-content"]');
    tab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for tab');

    // Should handle empty array gracefully
    expect(logViewer.currentMode.data).toBeDefined();
  });

  it('handles deprecated logId property', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    logViewer.logId = 'deprecated-id';
    document.body.appendChild(logViewer);

    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve('resolves component rerender');

    expect(logViewer.isLoaded).toBe(true);
    expect(logViewer.logId).toBe('deprecated-id');
  });

  it('updates download button label based on current mode', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);
    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve('resolves component rerender');

    // Initially no mode set
    expect(logViewer.downloadButtonLabel).toEqual('Download undefined');

    // Activate JSON tab
    const jsonTab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="json-content"]');
    jsonTab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for tab');

    expect(logViewer.downloadButtonLabel).toEqual('Download Record JSON');

    // Activate file tab
    const fileTab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="file-content"]');
    fileTab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for tab');

    expect(logViewer.downloadButtonLabel).toEqual('Download Log File');
  });

  it('handles copy to clipboard when no mode is selected', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);
    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve('resolves component rerender');

    // Click copy button without selecting a tab first
    const copyBtn = logViewer.shadowRoot.querySelector('lightning-button-stateful[data-id="copy-btn"]');
    copyBtn.click();
    await Promise.resolve('resolves copy-to-clipboard function');

    // Should handle undefined currentMode.data gracefully
    expect(document.execCommand).toHaveBeenCalledWith('copy');
  });

  it('handles download when no mode is selected', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);
    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve('resolves component rerender');

    // Click download button without selecting a tab first
    const downloadBtn = logViewer.shadowRoot.querySelector('lightning-button');
    downloadBtn.click();
    await Promise.resolve('resolves download function');

    // Should handle undefined currentMode.data gracefully
    expect(mockCreateElement).toHaveBeenCalledWith('a');
    expect(mockLink.click).toHaveBeenCalled();
  });
});
