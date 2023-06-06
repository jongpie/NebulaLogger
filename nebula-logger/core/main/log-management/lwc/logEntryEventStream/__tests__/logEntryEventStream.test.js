import { createElement } from 'lwc';
import LogEntryEventStream from 'c/logEntryEventStream';
import { jestMockPublish } from 'lightning/empApi';
import getSchemaForName from '@salesforce/apex/LoggerSObjectMetadata.getSchemaForName';
import isEnabled from '@salesforce/apex/LogEntryEventStreamController.isEnabled';
import getDatatableDisplayFields from '@salesforce/apex/LogEntryEventStreamController.getDatatableDisplayFields';

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

const mockLogEntryEventSchemaTemplate = require('./data/getSchemaForName.json');
const mockTableViewDisplayFields = require('./data/getDatatableDisplayFields.json');

jest.mock(
    '@salesforce/apex/LoggerSObjectMetadata.getSchemaForName',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/LogEntryEventStreamController.isEnabled',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/LogEntryEventStreamController.getDatatableDisplayFields',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

const flushPromises = () => new Promise(process.nextTick);

async function createStreamElement(namespace) {
    isEnabled.mockResolvedValue(true);
    getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
    const mockLogEntryEventSchema = generateLogEntryEventSchema(namespace);
    getSchemaForName.mockResolvedValue(mockLogEntryEventSchema);
    const element = createElement('log-entry-event-stream', {
        is: LogEntryEventStream
    });
    document.body.appendChild(element);
    await flushPromises();
    return element;
}

function generateLogEntryEventSchema(namespace) {
    namespace = !!namespace ? namespace + '__' : '';
    const schemaTemplate = { ...mockLogEntryEventSchemaTemplate };
    const schema = { ...schemaTemplate };
    schema.apiName += namespace;
    schema.namespacePrefix = namespace;
    schema.fields = {};
    Object.keys(schemaTemplate.fields).forEach(templateKey => {
        schema.fields[templateKey] = schemaTemplate.fields[templateKey];
        schema.fields[templateKey].apiName = namespace + templateKey;
    });
    return schema;
}

function generatePlatformEvent(namespace) {
    namespace = !!namespace ? namespace + '__' : '';
    return {
        [namespace + 'LoggedByUsername__c']: 'some.person@test.com',
        [namespace + 'LoggingLevel__c']: 'INFO',
        [namespace + 'LoggingLevelOrdinal__c']: 6,
        [namespace + 'Message__c']: 'My important log entry message',
        [namespace + 'OriginType__c']: 'Apex',
        [namespace + 'OriginLocation__c']: 'SomeClass.someMethod',
        [namespace + 'Timestamp__c']: new Date().toISOString(),
        [namespace + 'TransactionId__c']: 'ABC-1234',
        [namespace + 'TransactionEntryNumber__c']: 1
    };
}

function getPlatformEventText(mockLogEntryEvent, namespace) {
    namespace = !!namespace ? namespace + '__' : '';
    return (
        mockLogEntryEvent[namespace + 'Timestamp__c'] +
        mockLogEntryEvent[namespace + 'LoggedByUsername__c'] +
        ' - ' +
        mockLogEntryEvent[namespace + 'TransactionId__c'] +
        '__' +
        mockLogEntryEvent[namespace + 'TransactionEntryNumber__c'] +
        mockLogEntryEvent[namespace + 'OriginType__c'] +
        '.' +
        mockLogEntryEvent[namespace + 'OriginLocation__c'] +
        ' ' +
        mockLogEntryEvent[namespace + 'LoggingLevel__c'] +
        mockLogEntryEvent[namespace + 'Message__c']
    );
}

async function publishPlatformEvent(namespace, mockLogEntryEvent) {
    const mockLogEntryEventSchema = generateLogEntryEventSchema(namespace);
    await jestMockPublish('/event/' + mockLogEntryEventSchema.apiName, {
        data: {
            payload: mockLogEntryEvent
        }
    });
}

describe('LogEntryEventStream tests', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    const namespaces = ['', 'SomeNamespace'];

    it('shows warning when component is disabled', async () => {
        isEnabled.mockResolvedValue(false);
        getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
        getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);

        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await flushPromises();

        const warningElement = element.shadowRoot.querySelector('.disabled-warning-message');
        expect(warningElement).toBeTruthy();
        expect(warningElement.querySelector('.slds-text-heading_medium').innerHTML).toEqual(
            'The log entry event stream has been disabled by an admin, using the record LoggerParameter__mdt.EnableLogEntryEventStream.'
        );
        const buttonElements = element.shadowRoot.querySelectorAll('lightning-button, lightning-button-menu, lightning-button-stateful');
        expect(buttonElements.length).toEqual(0);
        const inputElements = element.shadowRoot.querySelectorAll('lightning-combobox, lightning-input, lightning-textarea');
        inputElements.forEach(inputElement => {
            expect(inputElement.disabled).toEqual(true);
        });
    });

    it('streams a single log entry event', async () => {
        await Promise.all(
            namespaces.map(async namespace => {
                const element = await createStreamElement(namespace);
                const mockLogEntryEvent = await generatePlatformEvent(namespace);

                await publishPlatformEvent(namespace, mockLogEntryEvent);

                const expectedStreamText = getPlatformEventText(mockLogEntryEvent, namespace);
                const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
                expect(eventStreamDiv.textContent).toBe(expectedStreamText);
            })
        );
    });

    it('toggles streaming when button clicked', async () => {
        await Promise.all(
            namespaces.map(async namespace => {
                const element = await createStreamElement(namespace);
                const toggleButton = element.shadowRoot.querySelector('lightning-button-stateful[data-id="toggle-stream"]');

                return Promise.resolve()
                    .then(() => {
                        expect(toggleButton.variant).toBe('success');
                        toggleButton.click();
                    })
                    .then(() => {
                        expect(toggleButton.variant).toBe('brand');
                    });
            })
        );
    });

    it('clears stream when clear button clicked', async () => {
        await Promise.all(
            namespaces.map(async namespace => {
                const element = await createStreamElement(namespace);
                const mockLogEntryEvent = await generatePlatformEvent(namespace);
                await publishPlatformEvent(namespace, mockLogEntryEvent);
                const expectedStreamText = getPlatformEventText(mockLogEntryEvent, namespace);

                let eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
                expect(eventStreamDiv.textContent).toBe(expectedStreamText);

                const clearButton = element.shadowRoot.querySelector('lightning-button[data-id="clear"]');
                clearButton.click();

                return Promise.resolve().then(() => {
                    eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
                    expect(eventStreamDiv.textContent).toBeFalsy();
                });
            })
        );
    });

    it('includes matching log entry event for logging level filter', async () => {
        await Promise.all(
            namespaces.map(async namespace => {
                const element = await createStreamElement(namespace);

                const loggingLevelFilterDropdown = element.shadowRoot.querySelector('lightning-combobox[data-id="loggingLevelFilter"]');
                loggingLevelFilterDropdown.value = loggingLevels.DEBUG;
                loggingLevelFilterDropdown.dispatchEvent(new CustomEvent('change'));
                await flushPromises();

                const matchingLogEntryEvent = generatePlatformEvent(namespace);
                const namespacePrefix = !!namespace ? namespace + '__' : '';
                matchingLogEntryEvent[namespacePrefix + 'LoggingLevel__c'] = 'INFO';
                matchingLogEntryEvent[namespacePrefix + 'LoggingLevelOrdinal__c'] = loggingLevels.INFO;
                expect(matchingLogEntryEvent[namespacePrefix + 'LoggingLevelOrdinal__c']).toBeGreaterThan(Number(loggingLevelFilterDropdown.value));

                await publishPlatformEvent(namespace, matchingLogEntryEvent);
                const expectedStreamText = getPlatformEventText(matchingLogEntryEvent, namespace);
                const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
                expect(eventStreamDiv.textContent).toBe(expectedStreamText);
            })
        );
    });

    it('excludes non-matching log entry event for logging level filter', async () => {
        await Promise.all(
            namespaces.map(async namespace => {
                const element = await createStreamElement(namespace);

                const loggingLevelFilterDropdown = element.shadowRoot.querySelector('lightning-combobox[data-id="loggingLevelFilter"]');
                loggingLevelFilterDropdown.value = loggingLevels.DEBUG;
                loggingLevelFilterDropdown.dispatchEvent(new CustomEvent('change'));

                const matchingLogEntryEvent = generatePlatformEvent(namespace);
                const namespacePrefix = !!namespace ? namespace + '__' : '';
                matchingLogEntryEvent[namespacePrefix + 'LoggingLevel__c'] = 'FINEST';
                matchingLogEntryEvent[namespacePrefix + 'LoggingLevelOrdinal__c'] = loggingLevels.FINEST;
                expect(matchingLogEntryEvent[namespacePrefix + 'LoggingLevelOrdinal__c']).toBeLessThan(Number(loggingLevelFilterDropdown.value));

                await publishPlatformEvent(namespace, matchingLogEntryEvent);

                const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
                expect(eventStreamDiv.textContent).toBeFalsy();
            })
        );
    });

    it('includes matching log entry event for origin type filter', async () => {
        isEnabled.mockResolvedValue(true);
        getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
        getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await flushPromises();

        const originTypeFilterDropdown = element.shadowRoot.querySelector('lightning-combobox[data-id="originTypeFilter"]');
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
        isEnabled.mockResolvedValue(true);
        getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
        getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);

        const originTypeFilterDropdown = element.shadowRoot.querySelector('lightning-combobox[data-id="originTypeFilter"]');
        originTypeFilterDropdown.value = 'Flow';
        originTypeFilterDropdown.dispatchEvent(new CustomEvent('change'));
        await flushPromises();

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
        isEnabled.mockResolvedValue(true);
        getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
        getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);

        const originLocationFilterDropdown = element.shadowRoot.querySelector('lightning-input[data-id="originLocationFilter"]');
        originLocationFilterDropdown.value = 'SomeClass.someMethod';
        originLocationFilterDropdown.dispatchEvent(new CustomEvent('change'));
        await flushPromises();

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
        isEnabled.mockResolvedValue(true);
        getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
        getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);

        const originLocationFilterDropdown = element.shadowRoot.querySelector('lightning-input[data-id="originLocationFilter"]');
        originLocationFilterDropdown.value = 'SomeClass.someMethod';
        originLocationFilterDropdown.dispatchEvent(new CustomEvent('change'));
        await flushPromises();

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
        isEnabled.mockResolvedValue(true);
        getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
        getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);

        const originLocationFilterDropdown = element.shadowRoot.querySelector('lightning-input[data-id="loggedByFilter"]');
        originLocationFilterDropdown.value = 'some.person@test.com';
        originLocationFilterDropdown.dispatchEvent(new CustomEvent('change'));
        await flushPromises();

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
        isEnabled.mockResolvedValue(true);
        getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
        getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await flushPromises();

        const originLocationFilterDropdown = element.shadowRoot.querySelector('lightning-input[data-id="loggedByFilter"]');
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

    it('includes matching log entry event using string for message filter', async () => {
        isEnabled.mockResolvedValue(true);
        getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
        getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await flushPromises();

        const messageFilterTextarea = element.shadowRoot.querySelector('lightning-textarea[data-id="messageFilter"]');
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
        isEnabled.mockResolvedValue(true);
        getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
        getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await flushPromises();

        const messageFilterTextarea = element.shadowRoot.querySelector('lightning-textarea[data-id="messageFilter"]');
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

    it('includes matching log entry event using regex for message filter', async () => {
        isEnabled.mockResolvedValue(true);
        getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
        getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        document.body.appendChild(element);
        await flushPromises();

        const messageFilterTextarea = element.shadowRoot.querySelector('lightning-textarea[data-id="messageFilter"]');
        messageFilterTextarea.value = 'Something.+? blah$';
        messageFilterTextarea.dispatchEvent(new CustomEvent('change'));
        await Promise.resolve();

        const matchingLogEntryEvent = { ...mockLogEntryEventTemplate };
        matchingLogEntryEvent.Message__c = 'Something, something, something, beep boop beep!!!!!!!%@#$!%, blah, blah, blah';
        await jestMockPublish('/event/LogEntryEvent__e', {
            data: {
                payload: matchingLogEntryEvent
            }
        });

        const expectedStreamText = getPlatformEventText(matchingLogEntryEvent);
        const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
        expect(eventStreamDiv.textContent).toBe(expectedStreamText);
    });

    it('shows the splitview as expanded by default', async () => {
        isEnabled.mockResolvedValue(true);
        getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
        getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        const nonMatchingLogEntryEvent = { ...mockLogEntryEventTemplate };
        nonMatchingLogEntryEvent.LoggedByUsername__c = 'a.different.person@test.com';
        await jestMockPublish('/event/LogEntryEvent__e', {
            data: {
                payload: nonMatchingLogEntryEvent
            }
        });
        document.body.appendChild(element);
        await flushPromises();

        let splitViewContainer = element.shadowRoot.querySelector('[data-id="split-view-container"]');
        expect(splitViewContainer.className).toContain('slds-is-open');

        const toggleSplitViewButton = element.shadowRoot.querySelector('[data-id="split-view-button"]');
        expect(toggleSplitViewButton.className).toContain('slds-is-open');
        toggleSplitViewButton.click();
        await flushPromises();

        splitViewContainer = element.shadowRoot.querySelector('[data-id="split-view-container"]');
        expect(splitViewContainer.className).toContain('slds-is-closed');
    });

    it('collapses the split view when user click on the splitview panel button', async () => {
        getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
        getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);

        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        const nonMatchingLogEntryEvent = { ...mockLogEntryEventTemplate };
        nonMatchingLogEntryEvent.LoggedByUsername__c = 'a.different.person@test.com';
        await jestMockPublish('/event/LogEntryEvent__e', {
            data: {
                payload: nonMatchingLogEntryEvent
            }
        });

        document.body.appendChild(element);
        await flushPromises();

        const splitViewContainer = element.shadowRoot.querySelector('[data-id="split-view-container"]');
        const toggleSplitViewButton = element.shadowRoot.querySelector('[data-id="split-view-button"]');
        toggleSplitViewButton.click();

        expect(splitViewContainer.className).toContain('slds-is-closed');
        expect(toggleSplitViewButton.className).toContain('slds-is-closed');

        const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
    });

    it('expands the console when user click on the expand button', async () => {
        isEnabled.mockResolvedValue(true);
        getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
        getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        const nonMatchingLogEntryEvent = { ...mockLogEntryEventTemplate };
        nonMatchingLogEntryEvent.LoggedByUsername__c = 'a.different.person@test.com';
        await jestMockPublish('/event/LogEntryEvent__e', {
            data: {
                payload: nonMatchingLogEntryEvent
            }
        });

        document.body.appendChild(element);
        await flushPromises();

        const toggleExpandButton = element.shadowRoot.querySelector('lightning-button-stateful[data-id="expand-toggle"]');
        toggleExpandButton.click();

        const consoleBlock = element.shadowRoot.querySelector('[data-id="event-stream-console"]');
        expect(consoleBlock.className).toContain('expanded');
    });

    it('exits full screen mode when user click on the contract button', async () => {
        isEnabled.mockResolvedValue(true);
        getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
        getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
        const element = createElement('log-entry-event-stream', {
            is: LogEntryEventStream
        });
        const nonMatchingLogEntryEvent = { ...mockLogEntryEventTemplate };
        nonMatchingLogEntryEvent.LoggedByUsername__c = 'a.different.person@test.com';
        await jestMockPublish('/event/LogEntryEvent__e', {
            data: {
                payload: nonMatchingLogEntryEvent
            }
        });

        document.body.appendChild(element);
        await flushPromises();

        const toggleExpandButton = element.shadowRoot.querySelector('lightning-button-stateful[data-id="expand-toggle"]');
        toggleExpandButton.click(); //expanded
        toggleExpandButton.click(); //contracted

        const consoleBlock = element.shadowRoot.querySelector('[data-id="event-stream-console"]');
        expect(consoleBlock.className).not.toContain('expanded');
    });

    it('shows log entries in console when user selects console view ', async () => {
        await Promise.all(
            namespaces.map(async namespace => {
                const element = await createStreamElement(namespace);
                const mockLogEntryEvent = await generatePlatformEvent(namespace);

                await publishPlatformEvent(namespace, mockLogEntryEvent);
                const buttonMenu = element.shadowRoot.querySelector('lightning-button-menu');
                buttonMenu.dispatchEvent(new CustomEvent('select', { detail: { value: 'console' } }));
                await flushPromises();

                const datatable = element.shadowRoot.querySelector('[data-id="event-stream-datatable"]');
                expect(datatable).toBe(null);
                const expectedStreamText = getPlatformEventText(mockLogEntryEvent, namespace);
                const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
                expect(eventStreamDiv.textContent).toBe(expectedStreamText);
            })
        );
    });

    it('shows log entries in datatable when user select tabular view ', async () => {
        await Promise.all(
            namespaces.map(async namespace => {
                const element = await createStreamElement(namespace);
                const mockLogEntryEvent = await generatePlatformEvent(namespace);

                await publishPlatformEvent(namespace, mockLogEntryEvent);
                const buttonMenu = element.shadowRoot.querySelector('lightning-button-menu');
                buttonMenu.dispatchEvent(new CustomEvent('select', { detail: { value: 'table' } }));
                await flushPromises();

                const datatable = element.shadowRoot.querySelector('[data-id="event-stream-datatable"]');
                expect(datatable.columns.length).toBe(2);
                expect(datatable.data.length).toBe(1);
                const expectedStreamText = getPlatformEventText(mockLogEntryEvent, namespace);
                const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
                expect(eventStreamDiv).toBe(null);
            })
        );
    });
});
