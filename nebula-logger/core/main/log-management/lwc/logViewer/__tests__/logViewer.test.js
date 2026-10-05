import { createElement } from 'lwc';
import LogViewer from 'c/logViewer';
import getLog from '@salesforce/apex/LogViewerController.getLog';

const MOCK_GET_LOG = require('./data/LogViewerController.getLog.json');

document.execCommand = jest.fn();

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

describe('Logger JSON Viewer lwc tests', () => {
  const originalCreateObjectURL = URL.createObjectURL;
  const originalRevokeObjectURL = URL.revokeObjectURL;
  let clickedAnchor;

  beforeEach(() => {
    clickedAnchor = undefined;
    URL.createObjectURL = jest.fn(() => 'blob:http://localhost/mock-blob');
    URL.revokeObjectURL = jest.fn();
    jest.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(function mockAnchorClick() {
      clickedAnchor = this;
    });
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    URL.createObjectURL = originalCreateObjectURL;
    URL.revokeObjectURL = originalRevokeObjectURL;
    jest.restoreAllMocks();
    jest.clearAllMocks();
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

  function installBlobCapture() {
    const OriginalBlob = global.Blob;
    const blobCalls = [];
    global.Blob = class extends OriginalBlob {
      constructor(parts, options) {
        super(parts, options);
        blobCalls.push({ parts, options });
      }
    };
    return {
      blobCalls,
      restore() {
        global.Blob = OriginalBlob;
      }
    };
  }

  it('downloads the JSON file as a blob', async () => {
    const blobCapture = installBlobCapture();
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);
    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve('resolves component rerender after loading log record');

    const tab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="json-content"]');
    tab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for tab');
    const expectedContent = logViewer.shadowRoot.querySelector('c-logger-code-viewer').code;
    const downloadBtn = logViewer.shadowRoot.querySelector('lightning-button');

    try {
      downloadBtn.click();

      expect(URL.createObjectURL).toHaveBeenCalledTimes(1);
      const blob = URL.createObjectURL.mock.calls[0][0];
      expect(blob).toBeInstanceOf(Blob);
      expect(blob.type).toEqual('application/octet-stream');
      expect(blobCapture.blobCalls[blobCapture.blobCalls.length - 1]).toEqual({
        parts: [expectedContent],
        options: { type: 'application/octet-stream' }
      });
      expect(clickedAnchor.getAttribute('href')).toEqual('blob:http://localhost/mock-blob');
      expect(clickedAnchor.getAttribute('download')).toEqual('Log-000004_00D1h000000MNKZEA4.json');
      expect(clickedAnchor.getAttribute('rel')).toEqual('noopener noreferrer');
      expect(document.body.querySelector('a[download]')).toBeNull();
      expect(URL.revokeObjectURL).toHaveBeenCalledTimes(1);
      expect(URL.revokeObjectURL).toHaveBeenCalledWith('blob:http://localhost/mock-blob');
    } finally {
      blobCapture.restore();
    }
  });

  it('downloads the log file as a blob', async () => {
    const blobCapture = installBlobCapture();
    const logViewer = createElement('c-log-viewer', { is: LogViewer });
    document.body.appendChild(logViewer);
    getLog.emit({ ...MOCK_GET_LOG });
    await Promise.resolve('resolves component rerender after loading log record');

    const tab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="file-content"]');
    tab.dispatchEvent(new CustomEvent('active'));
    await Promise.resolve('resolves dispatchEvent() for tab');
    const expectedContent = logViewer.shadowRoot.querySelector('c-logger-code-viewer').code;
    const downloadBtn = logViewer.shadowRoot.querySelector('lightning-button');

    try {
      downloadBtn.click();

      expect(URL.createObjectURL).toHaveBeenCalledTimes(1);
      const blob = URL.createObjectURL.mock.calls[0][0];
      expect(blob).toBeInstanceOf(Blob);
      expect(blob.type).toEqual('application/octet-stream');
      expect(blobCapture.blobCalls[blobCapture.blobCalls.length - 1]).toEqual({
        parts: [expectedContent],
        options: { type: 'application/octet-stream' }
      });
      expect(clickedAnchor.getAttribute('href')).toEqual('blob:http://localhost/mock-blob');
      expect(clickedAnchor.getAttribute('download')).toEqual('Log-000004_00D1h000000MNKZEA4.log');
      expect(clickedAnchor.getAttribute('rel')).toEqual('noopener noreferrer');
      expect(document.body.querySelector('a[download]')).toBeNull();
      expect(URL.revokeObjectURL).toHaveBeenCalledTimes(1);
      expect(URL.revokeObjectURL).toHaveBeenCalledWith('blob:http://localhost/mock-blob');
    } finally {
      blobCapture.restore();
    }
  });
});
