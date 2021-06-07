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

function setElementValue(element, value) {
    element.value = value;
    element.dispatchEvent(new CustomEvent('commit'));
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
            expect(relatedLogEntriesElement.queryResult.records[0].Name).toEqual('/' + mockQueryResult.records[0].Id);
        });
    });

    it('sends form data to apex', async () => {
        const relatedLogEntriesElement = createElement('c-related-log-entries', { is: RelatedLogEntries });
        relatedLogEntriesElement.recordId = mockRecordId;
        document.body.appendChild(relatedLogEntriesElement);

        getQueryResultAdapter.emit(mockQueryResult);

        return flushPromises().then(() => {
            const searchInput = relatedLogEntriesElement.shadowRoot.querySelector('lightning-input[data-id="enter-search"]');
            expect(searchInput).not.toBeNull();

            // Validate that the search input has not been set
            expect(relatedLogEntriesElement.search).toBeFalsy();
            expect(searchInput.value).toBeFalsy();

            // Set the search input
            const searchTerm = 'something';
            setElementValue(searchInput, searchTerm);
            searchInput.dispatchEvent(new CustomEvent('change'));

            // Validate the mock Apex call
            expect(searchInput.value).toEqual(searchTerm);
        }).then(() => {
            expect(getQueryResult.mock.calls[0][0]).toEqual({
                metadata: {
                    RollupFieldOnCalcItem__c: 'FirstName',
                    LookupFieldOnCalcItem__c: 'AccountId',
                    LookupFieldOnLookupObject__c: 'Id',
                    RollupFieldOnLookupObject__c: 'Name',
                    LookupObject__c: 'Account',
                    CalcItem__c: 'Contact',
                    RollupOperation__c: 'CONCAT',
                    CalcItemWhereClause__c: '',
                    OrderByFirstLast__c: '',
                    ConcatDelimiter__c: ''
                }
            });
        });
    });
});
