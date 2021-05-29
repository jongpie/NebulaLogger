import { createElement } from 'lwc';

import LogViewer from 'c/logViewer';
import getLog from '@salesforce/apex/Logger.getLog';
import { registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

// Mock data
const mockGetLog = require('./data/getLog.json');

// Register as an LDS wire adapter
const getLogAdapter = registerLdsTestWireAdapter(getLog);

function assertForTestConditions() {
    const resolvedPromise = Promise.resolve();
    return resolvedPromise.then.apply(resolvedPromise, arguments);
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

describe('Logger JSON Viewer tests', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('sets document title', async () => {
        const element = createElement('c-log-viewer', { is: LogViewer });
        document.body.appendChild(element);
        getLogAdapter.emit(mockGetLog);

        // element.log = mockGetLog;
        expect(element.log).not.toEqual(null);

        // Resolve a promise to wait for a rerender of the new content.
        return assertForTestConditions(() => {
            expect(element.title).toEqual('JSON for ' + mockGetLog.Name);
        });
    });
});
