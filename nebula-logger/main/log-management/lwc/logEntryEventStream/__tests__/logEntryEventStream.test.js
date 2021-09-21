import { createElement } from 'lwc';
import LogEntryEventStream from 'c/logEntryEventStream';
import { jestMockPublish } from 'lightning/empApi';

const loggingLevels = {
    FINEST: 2,
    FINER: 3,
    FINE: 4,
    DEBUG: 5,
    INFO: 6,
    WARN: 7,
    ERROR: 8
};

const mockLogEntryEventTemplate = {
    LoggedByUsername__c: 'some.person@test.com',
    LoggingLevel__c: 'INFO',
    LoggingLevelOrdinal__c: 6,
    Message__c: 'My important log entry message',
    OriginType__c: 'Apex',
    OriginLocation__c: 'SomeClass.someMethod',
    Timestamp__c: new Date().toISOString(),
    TransactionId__c: 'ABC-1234',
    TransactionEntryNumber__c: 1
};

function getPlatformEventText(mockLogEntryEvent) {
    return (
        mockLogEntryEvent.Timestamp__c +
        mockLogEntryEvent.LoggedByUsername__c +
        ' - ' +
        mockLogEntryEvent.TransactionId__c +
        '__' +
        mockLogEntryEvent.TransactionEntryNumber__c +
        mockLogEntryEvent.OriginType__c +
        '.' +
        mockLogEntryEvent.OriginLocation__c +
        ' ' +
        mockLogEntryEvent.LoggingLevel__c +
        mockLogEntryEvent.Message__c
    );
}

describe('LogEntryEventStream tests', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });
    it('streams a single log entry event', async () => {
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await Promise.resolve();

        const mockLogEntryEvent = { ...mockLogEntryEventTemplate };
        await jestMockPublish('/event/LogEntryEvent__e', {
            data: {
                payload: mockLogEntryEvent
            }
        });

        const expectedStreamText = getPlatformEventText(mockLogEntryEvent);
        const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
        expect(eventStreamDiv.textContent).toBe(expectedStreamText);
    });
    it('toggles streaming when button clicked', async () => {
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await Promise.resolve();
        const toggleButton = element.shadowRoot.querySelector('lightning-button-stateful[data-id="toggle-stream"]');

        return Promise.resolve()
            .then(() => {
                expect(toggleButton.variant).toBe('success');
                toggleButton.click();
            })
            .then(() => {
                expect(toggleButton.variant).toBe('brand');
            });
    });
    it('clears stream when clear button clicked', async () => {
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await Promise.resolve();
        const mockLogEntryEvent = { ...mockLogEntryEventTemplate };
        await jestMockPublish('/event/LogEntryEvent__e', {
            data: {
                payload: mockLogEntryEvent
            }
        });
        const expectedStreamText = getPlatformEventText(mockLogEntryEvent);
        let eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
        expect(eventStreamDiv.textContent).toBe(expectedStreamText);

        const clearButton = element.shadowRoot.querySelector('lightning-button[data-id="clear"]');
        clearButton.click();

        return Promise.resolve().then(() => {
            eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
            expect(eventStreamDiv.textContent).toBeFalsy();
        });
    });
    it('includes matching log entry event for logging level filter', async () => {
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await Promise.resolve();
        const loggingLevelFilterDropdown = element.shadowRoot.querySelector('lightning-combobox[data-id="logging-level-filter"]');
        loggingLevelFilterDropdown.value = loggingLevels.DEBUG;
        loggingLevelFilterDropdown.dispatchEvent(new CustomEvent('change'));

        const matchingLogEntryEvent = { ...mockLogEntryEventTemplate };
        matchingLogEntryEvent.LoggingLevel__c = 'INFO';
        matchingLogEntryEvent.LoggingLevelOrdinal__c = loggingLevels.INFO;
        expect(matchingLogEntryEvent.LoggingLevelOrdinal__c).toBeGreaterThan(Number(loggingLevelFilterDropdown.value));
        await jestMockPublish('/event/LogEntryEvent__e', {
            data: {
                payload: matchingLogEntryEvent
            }
        });

        const expectedStreamText = getPlatformEventText(matchingLogEntryEvent);
        const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
        expect(eventStreamDiv.textContent).toBe(expectedStreamText);
    });
    it('excludes non-matching log entry event for logging level filter', async () => {
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await Promise.resolve();
        const loggingLevelFilterDropdown = element.shadowRoot.querySelector('lightning-combobox[data-id="logging-level-filter"]');
        loggingLevelFilterDropdown.value = loggingLevels.DEBUG;
        loggingLevelFilterDropdown.dispatchEvent(new CustomEvent('change'));

        const nonMatchingLogEntryEvent = { ...mockLogEntryEventTemplate };
        nonMatchingLogEntryEvent.LoggingLevel__c = 'FINEST';
        nonMatchingLogEntryEvent.LoggingLevelOrdinal__c = loggingLevels.FINEST;
        expect(nonMatchingLogEntryEvent.LoggingLevelOrdinal__c).toBeLessThan(Number(loggingLevelFilterDropdown.value));
        await jestMockPublish('/event/LogEntryEvent__e', {
            data: {
                payload: nonMatchingLogEntryEvent
            }
        });

        const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
        expect(eventStreamDiv.textContent).toBeFalsy();
    });
    it('includes matching log entry event for origin type filter', async () => {
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await Promise.resolve();
        const originTypeFilterDropdown = element.shadowRoot.querySelector('lightning-combobox[data-id="origin-type-filter"]');
        originTypeFilterDropdown.value = 'Flow';
        originTypeFilterDropdown.dispatchEvent(new CustomEvent('change'));

        const matchingLogEntryEvent = { ...mockLogEntryEventTemplate };
        matchingLogEntryEvent.OriginType__c = 'Flow';
        expect(matchingLogEntryEvent.OriginType__c).toEqual(originTypeFilterDropdown.value);
        await jestMockPublish('/event/LogEntryEvent__e', {
            data: {
                payload: matchingLogEntryEvent
            }
        });

        const expectedStreamText = getPlatformEventText(matchingLogEntryEvent);
        const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
        expect(eventStreamDiv.textContent).toBe(expectedStreamText);
    });
    it('excludes non-matching log entry event for origin type filter', async () => {
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await Promise.resolve();
        const originTypeFilterDropdown = element.shadowRoot.querySelector('lightning-combobox[data-id="origin-type-filter"]');
        originTypeFilterDropdown.value = 'Flow';
        originTypeFilterDropdown.dispatchEvent(new CustomEvent('change'));

        const nonMatchingLogEntryEvent = { ...mockLogEntryEventTemplate };
        nonMatchingLogEntryEvent.OriginType__c = 'Apex';
        expect(nonMatchingLogEntryEvent.OriginType__c).not.toEqual(originTypeFilterDropdown.value);
        await jestMockPublish('/event/LogEntryEvent__e', {
            data: {
                payload: nonMatchingLogEntryEvent
            }
        });

        const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
        expect(eventStreamDiv.textContent).toBeFalsy();
    });
    it('includes matching log entry event for origin location filter', async () => {
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await Promise.resolve();
        const originLocationFilterDropdown = element.shadowRoot.querySelector('lightning-input[data-id="origin-location-filter"]');
        originLocationFilterDropdown.value = 'SomeClass.someMethod';
        originLocationFilterDropdown.dispatchEvent(new CustomEvent('change'));

        const matchingLogEntryEvent = { ...mockLogEntryEventTemplate };
        matchingLogEntryEvent.OriginLocation__c = 'SomeClass.someMethod';
        expect(matchingLogEntryEvent.OriginLocation__c).toEqual(originLocationFilterDropdown.value);
        await jestMockPublish('/event/LogEntryEvent__e', {
            data: {
                payload: matchingLogEntryEvent
            }
        });

        const expectedStreamText = getPlatformEventText(matchingLogEntryEvent);
        const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
        expect(eventStreamDiv.textContent).toBe(expectedStreamText);
    });
    it('excludes non-matching log entry event for origin location filter', async () => {
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await Promise.resolve();
        const originLocationFilterDropdown = element.shadowRoot.querySelector('lightning-input[data-id="origin-location-filter"]');
        originLocationFilterDropdown.value = 'SomeClass.someMethod';
        originLocationFilterDropdown.dispatchEvent(new CustomEvent('change'));

        const nonMatchingLogEntryEvent = { ...mockLogEntryEventTemplate };
        nonMatchingLogEntryEvent.OriginLocation__c = 'AnotherClass.someOtherMethod';
        expect(nonMatchingLogEntryEvent.OriginLocation__c).not.toEqual(originLocationFilterDropdown.value);
        await jestMockPublish('/event/LogEntryEvent__e', {
            data: {
                payload: nonMatchingLogEntryEvent
            }
        });

        const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
        expect(eventStreamDiv.textContent).toBeFalsy();
    });
    it('includes matching log entry event for logged by filter', async () => {
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await Promise.resolve();
        const originLocationFilterDropdown = element.shadowRoot.querySelector('lightning-input[data-id="logged-by-filter"]');
        originLocationFilterDropdown.value = 'some.person@test.com';
        originLocationFilterDropdown.dispatchEvent(new CustomEvent('change'));

        const matchingLogEntryEvent = { ...mockLogEntryEventTemplate };
        matchingLogEntryEvent.LoggedByUsername__c = 'some.person@test.com';
        expect(matchingLogEntryEvent.LoggedByUsername__c).toEqual(originLocationFilterDropdown.value);
        await jestMockPublish('/event/LogEntryEvent__e', {
            data: {
                payload: matchingLogEntryEvent
            }
        });

        const expectedStreamText = getPlatformEventText(matchingLogEntryEvent);
        const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
        expect(eventStreamDiv.textContent).toBe(expectedStreamText);
    });
    it('excludes non-matching log entry event for logged by filter', async () => {
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await Promise.resolve();
        const originLocationFilterDropdown = element.shadowRoot.querySelector('lightning-input[data-id="logged-by-filter"]');
        originLocationFilterDropdown.value = 'some.person@test.com';
        originLocationFilterDropdown.dispatchEvent(new CustomEvent('change'));

        const nonMatchingLogEntryEvent = { ...mockLogEntryEventTemplate };
        nonMatchingLogEntryEvent.LoggedByUsername__c = 'a.different.person@test.com';
        expect(nonMatchingLogEntryEvent.LoggedByUsername__c).not.toEqual(originLocationFilterDropdown.value);
        await jestMockPublish('/event/LogEntryEvent__e', {
            data: {
                payload: nonMatchingLogEntryEvent
            }
        });

        const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
        expect(eventStreamDiv.textContent).toBeFalsy();
    });
    it('includes matching log entry event for message filter', async () => {
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await Promise.resolve();
        const messageFilterTextarea = element.shadowRoot.querySelector('lightning-textarea[data-id="message-filter"]');
        messageFilterTextarea.value = 'matching text';
        messageFilterTextarea.dispatchEvent(new CustomEvent('change'));

        const matchingLogEntryEvent = { ...mockLogEntryEventTemplate };
        matchingLogEntryEvent.Message__c = 'Something, something, something,' + messageFilterTextarea.value + ', blah, blah, blah';
        expect(matchingLogEntryEvent.Message__c).toContain(messageFilterTextarea.value);
        await jestMockPublish('/event/LogEntryEvent__e', {
            data: {
                payload: matchingLogEntryEvent
            }
        });

        const expectedStreamText = getPlatformEventText(matchingLogEntryEvent);
        const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
        expect(eventStreamDiv.textContent).toBe(expectedStreamText);
    });
    it('excludes non-matching log entry event for message filter', async () => {
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await Promise.resolve();
        const messageFilterTextarea = element.shadowRoot.querySelector('lightning-textarea[data-id="message-filter"]');
        messageFilterTextarea.value = 'non-matching text';
        messageFilterTextarea.dispatchEvent(new CustomEvent('change'));

        const nonMatchingLogEntryEvent = { ...mockLogEntryEventTemplate };
        nonMatchingLogEntryEvent.Message__c = 'Something, something, something';
        expect(nonMatchingLogEntryEvent.Message__c).not.toContain(messageFilterTextarea.value);
        await jestMockPublish('/event/LogEntryEvent__e', {
            data: {
                payload: nonMatchingLogEntryEvent
            }
        });

        const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
        expect(eventStreamDiv.textContent).toBeFalsy();
    });
});
