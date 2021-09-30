import { createElement } from 'lwc';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import RelatedLogEntries from 'c/relatedLogEntries';
import getQueryResult from '@salesforce/apex/RelatedLogEntriesController.getQueryResult';

// Mock data
const mockRecordId = '0015400000gY3OuAAK';
const mockQueryResult = require('./data/getQueryResult.json');

// Register a test wire adapter
const getQueryResultAdapter = registerApexTestWireAdapter(getQueryResult);

function flushPromises() {
    return new Promise(resolve => setTimeout(resolve, 0));
}

jest.mock(
    '@salesforce/apex/RelatedLogEntriesController.getQueryResult',
    () => {
        return {
            default: () => jest.fn()
        };
    },
    { virtual: true }
);

describe('Related Log Entries lwc tests', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('sets query result', async () => {
        const relatedLogEntriesElement = createElement('c-related-log-entries', { is: RelatedLogEntries });
        relatedLogEntriesElement.recordId = mockRecordId;
        document.body.appendChild(relatedLogEntriesElement);

        getQueryResultAdapter.emit(mockQueryResult);

        // Resolve a promise to wait for a rerender of the new content
        return flushPromises().then(() => {
            expect(relatedLogEntriesElement.queryResult).toBeTruthy();
            expect(relatedLogEntriesElement.queryResult.records[0].Id).toEqual(mockQueryResult.records[0].Id);
            // expect(relatedLogEntriesElement.fieldSetName).not.toBe(undefined);
        });
    });
});
