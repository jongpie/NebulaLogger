import { createElement } from 'lwc';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import RelatedLogEntries from 'c/relatedLogEntries';
import getQueryResult from '@salesforce/apex/RelatedLogEntriesController.getQueryResult';

const MOCK_RECORD_ID = '0015400000gY3OuAAK';
const MOCK_QUERY_RESULT = require('./data/getQueryResult.json');

jest.mock(
    '@salesforce/apex/RelatedLogEntriesController.getQueryResult',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

describe('Related Log Entries lwc tests', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('sets query result', async () => {
        const relatedLogEntriesElement = createElement('c-related-log-entries', { is: RelatedLogEntries });
        relatedLogEntriesElement.recordId = MOCK_RECORD_ID;
        document.body.appendChild(relatedLogEntriesElement);

        getQueryResult.emit({ ...MOCK_QUERY_RESULT });

        await Promise.resolve();
        expect(relatedLogEntriesElement.queryResult).toBeTruthy();
        expect(relatedLogEntriesElement.queryResult.records[0].Id).toEqual(MOCK_QUERY_RESULT.records[0].Id);
        // expect(relatedLogEntriesElement.fieldSetName).not.toBe(undefined);
    });
});
