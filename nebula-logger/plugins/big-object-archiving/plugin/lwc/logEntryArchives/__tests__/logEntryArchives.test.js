import { createElement } from 'lwc';
import LogEntryArchives from 'c/logEntryArchives';
import getLogEntryArchives from '@salesforce/apex/LogEntryArchiveController.getLogEntryArchives';
import getSchemaForName from '@salesforce/apex/LoggerSObjectMetadata.getSchemaForName';

const MOCK_DATA = [{ Message__c: 'Some message' }];
const MOCK_SCHEMA = require('./data/LoggerSObjectMetadata.getSchemaForName.json');

jest.mock(
    '@salesforce/apex/LogEntryArchiveController.getLogEntryArchives',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/LoggerSObjectMetadata.getSchemaForName',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

describe('c-log-entry-archives', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('initializes component', async () => {
        getLogEntryArchives.mockResolvedValue(MOCK_DATA);
        getSchemaForName.mockResolvedValue(MOCK_SCHEMA);
        const element = createElement('c-log-entry-archives', {
            is: LogEntryArchives
        });
        document.body.appendChild(element);
        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();
        expect(document.title).toBe('Log Entry Archives');
        const table = element.shadowRoot.querySelector('lightning-datatable');
        expect(table).toBeTruthy();
        expect(getLogEntryArchives).toHaveBeenCalledTimes(1);
        expect(getSchemaForName).toHaveBeenCalledTimes(1);
        // TODO Fix these expects
        // expect(getLogEntryArchives.mock.calls[0][0]).toBeDefined();
        // expect(getLogEntryArchives.mock.calls[0][0]).toBe(MOCK_DATA);
    });
});
