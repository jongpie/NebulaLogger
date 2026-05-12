import { createElement } from '@lwc/engine-dom';
import LogViewer from 'c/logViewer';
import getLog from '@salesforce/apex/LogViewerController.getLog';

const MOCK_GET_LOG = require('./data/LogViewerController.getLog.json');

document.execCommand = jest.fn();

// Mock window.document.createElement for download functionality (only for 'a' elements)
const originalCreateElement = window.document.createElement.bind(window.document);
const mockLink = {
  href: '',
  target: '',
  download: '',
  click: jest.fn()
};
const mockCreateElement = jest.fn(tagName => {
  if (tagName === 'a') {
    return mockLink;
  }
  // Let other elements (like 'style') use the real createElement
  return originalCreateElement(tagName);
});
Object.defineProperty(window.document, 'createElement', {
  value: mockCreateElement,
  writable: true,
  configurable: true
});

// Mock encodeURIComponent
global.encodeURIComponent = jest.fn(str => `encoded_${str}`);

jest.mock(
  'lightning/platformResourceLoader',
  () => {
    return {
      loadScript() {
        return new Promise((resolve, _) => {
          global.Prism = require('../../../staticresources/LoggerResources/prism.min.js');
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

describe('Log Viewer LWC tests', () => {
  beforeEach(() => {
    // Reset mock link properties between tests
    mockLink.href = '';
    mockLink.target = '';
    mockLink.download = '';
    mockLink.click.mockClear();
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    jest.clearAllTimers();
  });

  it('renders with expected initial state', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);
    expect(logViewer.shadowRoot.querySelector('lightning-spinner')).toBeTruthy();

    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve('resolves component rerender after loading log record');

    expect(logViewer.title).toEqual(MOCK_GET_LOG.log.Name);
    const tabSet = logViewer.shadowRoot.querySelector('lightning-tabset');
    expect(tabSet).toBeTruthy();
    const tabs = logViewer.shadowRoot.querySelectorAll('lightning-tab');
    expect(tabs.length).toBe(2);
    const jsonTab = tabs[0];
    expect(jsonTab.label).toBe('Record JSON');
    expect(jsonTab.value).toBe('json');
    const fileTab = tabs[1];
    expect(fileTab.label).toBe('Log File');
    expect(fileTab.value).toBe('file');
    const copyButton = logViewer.shadowRoot.querySelector('lightning-button-stateful[data-id="copy-button"]');
    expect(copyButton.variant).toEqual('brand');
    const downloadButton = logViewer.shadowRoot.querySelector('lightning-button[data-id="download-button"]');
    expect(downloadButton.variant).toBeUndefined();
  });

  it('copies JSON content to the clipboard', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    logViewer.recordId = 'test-log-id';
    document.body.appendChild(logViewer);
    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve('resolves component rerender after loading log record');
    // Activate JSON tab
    const jsonTab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="json-content"]');
    expect(jsonTab).toBeTruthy();
    jsonTab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for JSON tab');
    const codeViewer = logViewer.shadowRoot.querySelector('c-logger-code-viewer');
    expect(codeViewer).toBeTruthy();
    expect(codeViewer.code).toBeDefined();

    const copyButton = logViewer.shadowRoot.querySelector('lightning-button-stateful[data-id="copy-button"]');
    expect(copyButton.variant).toEqual('brand');
    copyButton.click();

    await Promise.resolve('resolves copy-to-clipboard function');
    expect(copyButton.variant).toEqual('success');
    const clipboardContent = JSON.parse(logViewer.shadowRoot.querySelector('c-logger-code-viewer').code);
    const reconstructedLog = { ...MOCK_GET_LOG.log };
    reconstructedLog[MOCK_GET_LOG.logEntriesRelationshipName] = [...MOCK_GET_LOG.logEntries];
    expect(clipboardContent).toEqual(reconstructedLog);
    expect(document.execCommand).toHaveBeenCalledWith('copy');
    // Fast-forward time to trigger the timeout
    jest.advanceTimersByTime(5000);
    await Promise.resolve('resolves timeout callback for setting button variant');
    // Check that the button's variant has reverted to 'brand' after a delay
    expect(copyButton.variant).toEqual('brand');
  });

  it('copies log file content to the clipboard', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);
    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve('resolves component rerender after loading log record');
    // Activate file tab
    const fileTab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="file-content"]');
    expect(fileTab).toBeTruthy();
    fileTab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for file tab');
    const codeViewer = logViewer.shadowRoot.querySelector('c-logger-code-viewer');
    expect(codeViewer).toBeTruthy();
    expect(codeViewer.code).toBeDefined();

    const copyButton = logViewer.shadowRoot.querySelector('lightning-button-stateful[data-id="copy-button"]');
    expect(copyButton.variant).toEqual('brand');
    copyButton.click();

    await Promise.resolve('resolves copy-to-clipboard function');
    expect(copyButton.variant).toEqual('success');
    await Promise.resolve('resolves dispatchEvent() for tab');
    const expectedContentLines = [];
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
    // Fast-forward time to trigger the timeout
    jest.advanceTimersByTime(5000);
    await Promise.resolve('resolves timeout callback for setting button variant');
    // Check that the button's variant has reverted to 'brand' after a delay
    expect(copyButton.variant).toEqual('brand');
  });

  it('downloads JSON file correctly', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    logViewer.recordId = 'test-log-id';
    document.body.appendChild(logViewer);
    // await Promise.resolve(); // Wait for component to connect
    // await Promise.resolve(); // Wait for wire service to initialize
    getLog.emit({ ...MOCK_GET_LOG });
    // await Promise.resolve(); // Wait for wire service callback
    await Promise.resolve('resolves component rerender after loading log record');
    // Activate JSON tab
    const jsonTab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="json-content"]');
    expect(jsonTab).toBeTruthy();
    jsonTab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for JSON tab');
    const codeViewer = logViewer.shadowRoot.querySelector('c-logger-code-viewer');
    expect(codeViewer).toBeTruthy();
    expect(codeViewer.code).toBeDefined();

    // Click download button
    const downloadButton = logViewer.shadowRoot.querySelector('lightning-button[data-id="download-button"]');
    expect(downloadButton.label).toEqual('Download Record JSON');
    downloadButton.click();

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
    logViewer.recordId = 'test-log-id';
    document.body.appendChild(logViewer);
    await Promise.resolve(); // Wait for component to connect
    await Promise.resolve(); // Wait for wire service to initialize
    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve(); // Wait for wire service callback
    await Promise.resolve('resolves component rerender after loading log record');
    // Activate file tab
    const tab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="file-content"]');
    expect(tab).toBeTruthy();
    tab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for tab');

    // Click download button
    const downloadButton = logViewer.shadowRoot.querySelector('lightning-button[data-id="download-button"]');
    expect(downloadButton.label).toEqual('Download Log File');
    downloadButton.click();

    await Promise.resolve('resolves download function');
    expect(mockCreateElement).toHaveBeenCalledWith('a');
    expect(mockLink.href).toContain('data:text;charset=utf-8,encoded_');
    expect(mockLink.target).toEqual('_blank');
    expect(mockLink.download).toContain(MOCK_GET_LOG.log.Name);
    expect(mockLink.download).toContain(MOCK_GET_LOG.log.OrganizationId__c);
    expect(mockLink.download).toContain('.log');
    expect(mockLink.click).toHaveBeenCalled();
  });

  it('handles wire service with no data gracefully', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    logViewer.recordId = 'test-log-id';
    document.body.appendChild(logViewer);
    await Promise.resolve(); // Wait for component to connect
    await Promise.resolve(); // Wait for wire service to initialize

    // Emit undefined data
    getLog.emit(undefined);
    await Promise.resolve('resolves component rerender');

    // Test isLoaded indirectly through DOM (isLoaded is not @api)
    const spinner = logViewer.shadowRoot.querySelector('lightning-spinner');
    expect(spinner).toBeTruthy(); // Spinner should be visible when not loaded
  });
});
