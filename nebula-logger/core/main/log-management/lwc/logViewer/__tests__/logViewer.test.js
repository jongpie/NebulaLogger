import { createElement } from 'lwc';
import LogViewer from 'c/logViewer';
import getLog from '@salesforce/apex/LogViewerController.getLog';

const MOCK_GET_LOG = require('./data/LogViewerController.getLog.json');

document.execCommand = jest.fn();

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

test.todo('test for downloading JSON file');
test.todo('test for downloading log file');

describe('Logger JSON Viewer lwc tests', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
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
        const clipboardContent = JSON.parse(logViewer.shadowRoot.querySelector('pre').textContent);
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
        const clipboardContent = logViewer.shadowRoot.querySelector('pre').textContent;
        expect(clipboardContent).toEqual(expectedContentLines.join('\n\n' + '-'.repeat(36) + '\n\n'));
        expect(document.execCommand).toHaveBeenCalledWith('copy');
    });
});
