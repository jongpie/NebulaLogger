import { createElement } from 'lwc';
import LogViewer from 'c/logViewer';
import getLog from '@salesforce/apex/LogViewerController.getLog';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

// Mock data
const mockGetLog = require('./data/LogViewerController.getLog.json');

// Register a test wire adapter
const getLogAdapter = registerApexTestWireAdapter(getLog);

document.execCommand = jest.fn();

jest.mock(
    '@salesforce/apex/LogViewerController.getLog',
    () => {
        return {
            default: () => mockGetLog
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
        getLogAdapter.emit(mockGetLog);

        await Promise.resolve();
        expect(logViewerElement.title).toEqual(mockGetLog.Name);
    });

    it('defaults to brand button variant', async () => {
        const logViewer = createElement('c-log-viewer', { is: LogViewer });
        document.body.appendChild(logViewer);

        getLogAdapter.emit(mockGetLog);

        await Promise.resolve();
        const inputButton = logViewer.shadowRoot.querySelector('lightning-button-stateful');
        expect(logViewer.title).toEqual(mockGetLog.Name);
        expect(inputButton.variant).toEqual('brand');
    });

    it('copies the JSON to the clipboard', async () => {
        const logViewer = createElement('c-log-viewer', { is: LogViewer });
        document.body.appendChild(logViewer);

        getLogAdapter.emit(mockGetLog);

        return Promise.resolve()
            .then(() => {
                let copyBtn = logViewer.shadowRoot.querySelector('lightning-button-stateful[data-id="copy-btn"]');
                copyBtn.click();
            })
            .then(() => {
                const tab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="json-content"]');
                expect(tab.value).toEqual('json');
                tab.dispatchEvent(new CustomEvent('active'));
            })
            .then(() => {
                const clipboardContent = JSON.parse(logViewer.shadowRoot.querySelector('pre').textContent);
                expect(clipboardContent).toEqual(mockGetLog);
                expect(document.execCommand).toHaveBeenCalledWith('copy');
            });
    });

    it('copies the log file to the clipboard', async () => {
        const logViewer = createElement('c-log-viewer', { is: LogViewer });
        document.body.appendChild(logViewer);

        getLogAdapter.emit(mockGetLog);

        return Promise.resolve()
            .then(() => {
                let copyBtn = logViewer.shadowRoot.querySelector('lightning-button-stateful[data-id="copy-btn"]');
                copyBtn.click();
            })
            .then(() => {
                const tab = logViewer.shadowRoot.querySelector('lightning-tab[data-id="file-content"]');
                expect(tab.value).toEqual('file');
                tab.dispatchEvent(new CustomEvent('active'));
            })
            .then(() => {
                let expectedContentLines = [];
                mockGetLog.LogEntries__r.forEach(logEntry => {
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
});
