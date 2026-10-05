import { createElement } from '@lwc/engine-dom';
import LogViewer from 'c/logViewer';
import getLog from '@salesforce/apex/LogViewerController.getLog';

const MOCK_GET_LOG = require('./data/LogViewerController.getLog.json');

document.execCommand = jest.fn();

const originalCreateObjectURL = URL.createObjectURL;
const originalRevokeObjectURL = URL.revokeObjectURL;

// Mock window.document.createElement for download functionality (only for 'a' elements)
const originalCreateElement = window.document.createElement.bind(window.document);
const mockLink = {
  href: '',
  target: '',
  download: '',
  rel: '',
  click: jest.fn(),
  setAttribute: jest.fn((name, value) => {
    mockLink[name] = value;
  })
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

jest.mock(
  'lightning/platformResourceLoader',
  () => {
    return {
      loadScript() {
        return new Promise((resolve, _) => {
          global.Prism = require('../../../staticresources/LoggerResources/Prism/prism.min.js');
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
    URL.createObjectURL = jest.fn(() => 'blob:http://localhost/mock-blob');
    URL.revokeObjectURL = jest.fn();
    mockLink.href = '';
    mockLink.target = '';
    mockLink.download = '';
    mockLink.rel = '';
    mockLink.click.mockClear();
    mockLink.setAttribute.mockClear();
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    URL.createObjectURL = originalCreateObjectURL;
    URL.revokeObjectURL = originalRevokeObjectURL;
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
    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve('resolves component rerender after loading log record');
    const jsonTab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="json-content"]');
    expect(jsonTab).toBeTruthy();
    jsonTab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for JSON tab');
    const codeViewer = logViewer.shadowRoot.querySelector('c-logger-code-viewer');
    expect(codeViewer).toBeTruthy();
    expect(codeViewer.code).toBeDefined();

    const downloadButton = logViewer.shadowRoot.querySelector('lightning-button[data-id="download-button"]');
    expect(downloadButton.label).toEqual('Download Record JSON');
    downloadButton.click();

    await Promise.resolve('resolves download function');
    expect(mockCreateElement).toHaveBeenCalledWith('a');
    expect(URL.createObjectURL).toHaveBeenCalledTimes(1);
    const blob = URL.createObjectURL.mock.calls[0][0];
    expect(blob).toBeInstanceOf(Blob);
    expect(blob.type).toEqual('application/octet-stream');
    expect(mockLink.setAttribute).toHaveBeenCalledWith('href', 'blob:http://localhost/mock-blob');
    expect(mockLink.setAttribute).toHaveBeenCalledWith(
      'download',
      MOCK_GET_LOG.log.Name + '_' + MOCK_GET_LOG.log.OrganizationId__c + '.json'
    );
    expect(mockLink.setAttribute).toHaveBeenCalledWith('rel', 'noopener noreferrer');
    expect(mockLink.click).toHaveBeenCalled();
    expect(URL.revokeObjectURL).toHaveBeenCalledTimes(1);
    expect(URL.revokeObjectURL).toHaveBeenCalledWith('blob:http://localhost/mock-blob');
  });

  it('downloads log file correctly', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    logViewer.recordId = 'test-log-id';
    document.body.appendChild(logViewer);
    await Promise.resolve();
    await Promise.resolve();
    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve();
    await Promise.resolve('resolves component rerender after loading log record');
    const tab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="file-content"]');
    expect(tab).toBeTruthy();
    tab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for tab');

    const downloadButton = logViewer.shadowRoot.querySelector('lightning-button[data-id="download-button"]');
    expect(downloadButton.label).toEqual('Download Log File');
    downloadButton.click();

    await Promise.resolve('resolves download function');
    expect(mockCreateElement).toHaveBeenCalledWith('a');
    expect(URL.createObjectURL).toHaveBeenCalledTimes(1);
    const blob = URL.createObjectURL.mock.calls[0][0];
    expect(blob).toBeInstanceOf(Blob);
    expect(blob.type).toEqual('application/octet-stream');
    expect(mockLink.setAttribute).toHaveBeenCalledWith('href', 'blob:http://localhost/mock-blob');
    expect(mockLink.setAttribute).toHaveBeenCalledWith(
      'download',
      MOCK_GET_LOG.log.Name + '_' + MOCK_GET_LOG.log.OrganizationId__c + '.log'
    );
    expect(mockLink.setAttribute).toHaveBeenCalledWith('rel', 'noopener noreferrer');
    expect(mockLink.click).toHaveBeenCalled();
    expect(URL.revokeObjectURL).toHaveBeenCalledTimes(1);
    expect(URL.revokeObjectURL).toHaveBeenCalledWith('blob:http://localhost/mock-blob');
  });

  it('handles wire service with no data gracefully', async () => {
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    logViewer.recordId = 'test-log-id';
    document.body.appendChild(logViewer);
    await Promise.resolve();
    await Promise.resolve();

    getLog.emit(undefined);
    await Promise.resolve('resolves component rerender');

    const spinner = logViewer.shadowRoot.querySelector('lightning-spinner');
    expect(spinner).toBeTruthy();
  });
});
