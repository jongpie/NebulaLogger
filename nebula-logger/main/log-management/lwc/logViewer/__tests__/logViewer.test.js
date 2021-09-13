import { createElement } from 'lwc';
import LogViewer from 'c/logViewer';
import getLog from '@salesforce/apex/Logger.getLog';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

// Mock data
const mockGetLog = require('./data/getLog.json');

// Register a test wire adapter
const getLogAdapter = registerApexTestWireAdapter(getLog);

function flushPromises() {
    return new Promise(resolve => setTimeout(resolve, 0));
}

jest.mock(
    '@salesforce/apex/Logger.getLog',
    () => {
        return {
            default: () => mockGetLog
        };
    },
    { virtual: true }
);

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

        // Resolve a promise to wait for a rerender of the new content
        return flushPromises().then(() => {
            expect(logViewerElement.title).toEqual('JSON for ' + mockGetLog.Name);
        });
    });
    it('defaults to brand button variant', async () => {
        const logViewer = createElement('c-log-viewer', { is: LogViewer });
        document.body.appendChild(logViewer);

        getLogAdapter.emit(mockGetLog);

        // Resolve a promise to wait for a rerender of the new content
        return flushPromises().then(() => {
            const inputButton = logViewer.shadowRoot.querySelector('lightning-button-stateful');
            expect(logViewer.title).toEqual('JSON for ' + mockGetLog.Name);
            expect(inputButton.variant).toEqual('brand');
        });
    });
    it('copies the JSON to the clipboard', async () => {
        const logViewer = createElement('c-log-viewer', { is: LogViewer });
        document.body.appendChild(logViewer);

        getLogAdapter.emit(mockGetLog);

        // Resolve a promise to wait for a rerender of the new content
        return flushPromises()
            .then(() => {
                logViewer.shadowRoot.querySelector('lightning-button-stateful').click();
            })
            .then(() => {
                const clipboardContent = JSON.parse(logViewer.shadowRoot.querySelector('pre').textContent);
                expect(clipboardContent).toEqual(mockGetLog);
            });
    });
});
