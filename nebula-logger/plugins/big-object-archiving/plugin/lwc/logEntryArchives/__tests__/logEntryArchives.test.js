import { createElement } from 'lwc';
import LogEntryArchives from 'c/logEntryArchives';
import getLogEntryArchives from '@salesforce/apex/LogEntryArchiveController.getLogEntryArchives';

const MOCK_DATA = [{ Message__c: 'Some message' }];
jest.mock(
    '@salesforce/apex/LogEntryArchiveController.getLogEntryArchives',
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
        // TODO Fix these expects
        // expect(getLogEntryArchives.mock.calls[0][0]).toBeDefined();
        // expect(getLogEntryArchives.mock.calls[0][0]).toBe(MOCK_DATA);
    });
});
