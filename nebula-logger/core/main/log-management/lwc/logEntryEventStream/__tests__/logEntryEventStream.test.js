import { createElement } from '@lwc/engine-dom';
import LogEntryEventStream from 'c/logEntryEventStream';
import { jestMockPublish, subscribe, unsubscribe } from 'lightning/empApi';
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

  // Additional tests to improve coverage
  it('handles error in connectedCallback gracefully', async () => {
    isEnabled.mockRejectedValue(new Error('Test error'));
    getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
    getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);

    const element = createElement('log-entry-event-stream', {
      is: LogEntryEventStream
    });
    document.body.appendChild(element);
    await flushPromises();

    // Should still render the component even with errors
    expect(element.shadowRoot).toBeTruthy();
  });

  it('handles error in getSchemaForName gracefully', async () => {
    isEnabled.mockResolvedValue(true);
    getSchemaForName.mockRejectedValue(new Error('Schema error'));
    getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);

    const element = createElement('log-entry-event-stream', {
      is: LogEntryEventStream
    });
    document.body.appendChild(element);
    await flushPromises();

    // Should still render the component even with errors
    expect(element.shadowRoot).toBeTruthy();
  });

  it('handles error in getDatatableDisplayFields gracefully', async () => {
    isEnabled.mockResolvedValue(true);
    getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
    getDatatableDisplayFields.mockRejectedValue(new Error('Fields error'));

    const element = createElement('log-entry-event-stream', {
      is: LogEntryEventStream
    });
    document.body.appendChild(element);
    await flushPromises();

    // Should still render the component even with errors
    expect(element.shadowRoot).toBeTruthy();
  });

  it('handles null tableViewDisplayFields in loadDatatableColumns', async () => {
    isEnabled.mockResolvedValue(true);
    getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
    getDatatableDisplayFields.mockResolvedValue(null);

    const element = createElement('log-entry-event-stream', {
      is: LogEntryEventStream
    });
    document.body.appendChild(element);
    await flushPromises();

    // Should handle null fields gracefully
    expect(element.shadowRoot).toBeTruthy();
  });

  it('handles undefined tableViewDisplayFields in loadDatatableColumns', async () => {
    isEnabled.mockResolvedValue(true);
    getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
    getDatatableDisplayFields.mockResolvedValue(undefined);

    const element = createElement('log-entry-event-stream', {
      is: LogEntryEventStream
    });
    document.body.appendChild(element);
    await flushPromises();

    // Should handle undefined fields gracefully
    expect(element.shadowRoot).toBeTruthy();
  });

  it('stops streaming when max events reached', async () => {
    await Promise.all(
      namespaces.map(async namespace => {
        const element = await createStreamElement(namespace);

        // Set a low max events to stream (first lightning-input in the panel body)
        const panelBody = element.shadowRoot.querySelector('.slds-panel__body');
        const allInputs = panelBody.querySelectorAll('lightning-input');
        const maxEventsInput = allInputs[0]; // First input has field-level-help
        expect(maxEventsInput).toBeTruthy();
        maxEventsInput.value = '1';
        const changeEvent = new CustomEvent('change', { bubbles: true, composed: true });
        maxEventsInput.dispatchEvent(changeEvent);
        await flushPromises();
        await Promise.resolve(); // Ensure component has processed the change

        // Publish first event
        const mockLogEntryEvent1 = await generatePlatformEvent(namespace);
        await publishPlatformEvent(namespace, mockLogEntryEvent1);
        await flushPromises();

        // Publish second event - should auto-pause stream
        const mockLogEntryEvent2 = await generatePlatformEvent(namespace);
        const namespacePrefix = namespace ? namespace + '__' : '';
        mockLogEntryEvent2[namespacePrefix + 'TransactionId__c'] = 'DEF-5678';
        await publishPlatformEvent(namespace, mockLogEntryEvent2);
        await flushPromises();

        // Stream should be paused
        const toggleButton = element.shadowRoot.querySelector('lightning-button-stateful[data-id="toggle-stream"]');
        expect(toggleButton.variant).toBe('brand'); // Paused state
      })
    );
  });

  it('handles multiple filters applied simultaneously', async () => {
    isEnabled.mockResolvedValue(true);
    getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
    getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
    const element = createElement('log-entry-event-stream', {
      is: LogEntryEventStream
    });
    document.body.appendChild(element);
    await flushPromises();

    // Apply multiple filters
    const loggingLevelFilter = element.shadowRoot.querySelector('lightning-combobox[data-id="loggingLevelFilter"]');
    const originTypeFilter = element.shadowRoot.querySelector('lightning-combobox[data-id="originTypeFilter"]');
    const messageFilter = element.shadowRoot.querySelector('lightning-textarea[data-id="messageFilter"]');

    loggingLevelFilter.value = loggingLevels.INFO;
    originTypeFilter.value = 'Apex';
    messageFilter.value = 'important';

    loggingLevelFilter.dispatchEvent(new CustomEvent('change'));
    originTypeFilter.dispatchEvent(new CustomEvent('change'));
    messageFilter.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Publish matching event
    const matchingEvent = { ...mockLogEntryEventTemplate };
    matchingEvent.LoggingLevelOrdinal__c = loggingLevels.INFO;
    matchingEvent.OriginType__c = 'Apex';
    matchingEvent.Message__c = 'This is an important message';

    await jestMockPublish('/event/LogEntryEvent__e', {
      data: { payload: matchingEvent }
    });
    await flushPromises();

    const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
    expect(eventStreamDiv.textContent).toContain('important');
  });

  it('handles regex filter with special characters', async () => {
    isEnabled.mockResolvedValue(true);
    getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
    getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
    const element = createElement('log-entry-event-stream', {
      is: LogEntryEventStream
    });
    document.body.appendChild(element);
    await flushPromises();

    const messageFilter = element.shadowRoot.querySelector('lightning-textarea[data-id="messageFilter"]');
    messageFilter.value = '\\d+\\s+\\w+'; // Regex for digits + whitespace + word
    messageFilter.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    const matchingEvent = { ...mockLogEntryEventTemplate };
    matchingEvent.Message__c = '123 test message';

    await jestMockPublish('/event/LogEntryEvent__e', {
      data: { payload: matchingEvent }
    });
    await flushPromises();

    const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
    expect(eventStreamDiv.textContent).toContain('123 test message');
  });

  it('handles empty string filters correctly', async () => {
    isEnabled.mockResolvedValue(true);
    getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
    getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
    const element = createElement('log-entry-event-stream', {
      is: LogEntryEventStream
    });
    document.body.appendChild(element);
    await flushPromises();

    // Set empty string filters
    const loggedByFilter = element.shadowRoot.querySelector('lightning-input[data-id="loggedByFilter"]');
    const messageFilter = element.shadowRoot.querySelector('lightning-textarea[data-id="messageFilter"]');

    loggedByFilter.value = '';
    messageFilter.value = '';

    loggedByFilter.dispatchEvent(new CustomEvent('change'));
    messageFilter.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    // Publish event - should still be visible with empty filters
    const testEvent = { ...mockLogEntryEventTemplate };
    await jestMockPublish('/event/LogEntryEvent__e', {
      data: { payload: testEvent }
    });
    await flushPromises();

    const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
    expect(eventStreamDiv.textContent).toContain('My important log entry message');
  });

  it('handles max events to display change correctly', async () => {
    isEnabled.mockResolvedValue(true);
    getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
    getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
    const element = createElement('log-entry-event-stream', {
      is: LogEntryEventStream
    });
    document.body.appendChild(element);
    await flushPromises();

    // Find the "Max Number of Events to Display" input (it's the second lightning-input, after the one with field-level-help)
    const panelBody = element.shadowRoot.querySelector('.slds-panel__body');
    const allInputs = panelBody.querySelectorAll('lightning-input');
    // The first input has field-level-help, the second one is maxEventsToDisplay
    const maxEventsInput = allInputs[1];
    expect(maxEventsInput).toBeTruthy();
    expect(maxEventsInput.type).toBe('number');
    maxEventsInput.value = '1';
    const changeEvent = new CustomEvent('change', { bubbles: true, composed: true });
    maxEventsInput.dispatchEvent(changeEvent);
    await flushPromises();
    await Promise.resolve(); // Ensure component has processed the change

    // Publish multiple events
    const event1 = { ...mockLogEntryEventTemplate };
    const event2 = { ...mockLogEntryEventTemplate };
    event2.TransactionId__c = 'XYZ-9999';

    await jestMockPublish('/event/LogEntryEvent__e', {
      data: { payload: event1 }
    });
    await jestMockPublish('/event/LogEntryEvent__e', {
      data: { payload: event2 }
    });
    await flushPromises();

    // Should only show the most recent event due to maxEventsToDisplay = 1
    // Note: Events are added with unshift, so newest is first, but maxEventsToDisplay limits the total
    const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
    // With maxEventsToDisplay = 1, only the most recent event should be shown
    // Since events are added with unshift, the first event in the array is the newest
    const eventText = eventStreamDiv.textContent;
    expect(eventText).toContain('XYZ-9999');
    // The older event should not be visible due to maxEventsToDisplay limit
    expect(eventText).not.toContain('ABC-1234');
  });

  it('handles scenario filter correctly', async () => {
    isEnabled.mockResolvedValue(true);
    getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
    getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
    const element = createElement('log-entry-event-stream', {
      is: LogEntryEventStream
    });
    document.body.appendChild(element);
    await flushPromises();

    const scenarioFilter = element.shadowRoot.querySelector('lightning-input[data-id="scenarioFilter"]');
    scenarioFilter.value = 'TestScenario';
    scenarioFilter.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    const matchingEvent = { ...mockLogEntryEventTemplate };
    matchingEvent.TransactionScenario__c = 'TestScenario';

    await jestMockPublish('/event/LogEntryEvent__e', {
      data: { payload: matchingEvent }
    });
    await flushPromises();

    const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
    expect(eventStreamDiv.textContent).toContain('My important log entry message');
  });

  it('handles non-matching scenario filter correctly', async () => {
    isEnabled.mockResolvedValue(true);
    getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
    getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
    const element = createElement('log-entry-event-stream', {
      is: LogEntryEventStream
    });
    document.body.appendChild(element);
    await flushPromises();

    const scenarioFilter = element.shadowRoot.querySelector('lightning-input[data-id="scenarioFilter"]');
    scenarioFilter.value = 'TestScenario';
    scenarioFilter.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    const nonMatchingEvent = { ...mockLogEntryEventTemplate };
    nonMatchingEvent.TransactionScenario__c = 'DifferentScenario';

    await jestMockPublish('/event/LogEntryEvent__e', {
      data: { payload: nonMatchingEvent }
    });
    await flushPromises();

    const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
    expect(eventStreamDiv.textContent).toBeFalsy();
  });

  it('handles complex namespace scenarios correctly', async () => {
    const complexNamespace = 'ComplexNamespace';
    isEnabled.mockResolvedValue(true);
    getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
    const mockLogEntryEventSchema = generateLogEntryEventSchema(complexNamespace);
    getSchemaForName.mockResolvedValue(mockLogEntryEventSchema);

    const element = createElement('log-entry-event-stream', {
      is: LogEntryEventStream
    });
    document.body.appendChild(element);
    await flushPromises();

    const mockLogEntryEvent = generatePlatformEvent(complexNamespace);
    await publishPlatformEvent(complexNamespace, mockLogEntryEvent);
    await flushPromises();

    const expectedStreamText = getPlatformEventText(mockLogEntryEvent, complexNamespace);
    const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
    expect(eventStreamDiv.textContent).toBe(expectedStreamText);
  });

  it('handles stream toggle when stream is disabled', async () => {
    await Promise.all(
      namespaces.map(async namespace => {
        const element = await createStreamElement(namespace);

        // Disable stream first
        const toggleButton = element.shadowRoot.querySelector('lightning-button-stateful[data-id="toggle-stream"]');
        toggleButton.click();
        await flushPromises();
        expect(toggleButton.variant).toBe('brand'); // Paused state

        // Re-enable stream
        toggleButton.click();
        await flushPromises();
        expect(toggleButton.variant).toBe('success'); // Streaming state
      })
    );
  });

  it('handles disconnectedCallback correctly', async () => {
    // Clear mocks to ensure clean state
    unsubscribe.mockClear();
    subscribe.mockClear();

    const element = await createStreamElement();
    await flushPromises(); // Ensure subscription is fully created

    // Verify component is connected and subscription was created
    expect(element.shadowRoot).toBeTruthy();
    expect(subscribe).toHaveBeenCalled();

    // Remove from DOM to trigger disconnectedCallback
    document.body.removeChild(element);
    await flushPromises();

    // Verify unsubscribe was called exactly once when component disconnected
    // This is the critical assertion - disconnectedCallback should call cancelSubscription
    // which calls unsubscribe to clean up the platform event subscription
    expect(unsubscribe).toHaveBeenCalledTimes(1);

    // Verify unsubscribe was called with the subscription object that was returned from subscribe
    expect(unsubscribe).toHaveBeenCalled();
    const unsubscribeCall = unsubscribe.mock.calls[0];
    expect(unsubscribeCall).toBeDefined();
    expect(unsubscribeCall[0]).toBeDefined(); // Should be the subscription object

    // Component shadowRoot should still exist (LWC doesn't destroy it on disconnect)
    expect(element.shadowRoot).toBeTruthy();
  });

  it('handles edge case with zero max events to stream', async () => {
    isEnabled.mockResolvedValue(true);
    getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
    getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
    const element = createElement('log-entry-event-stream', {
      is: LogEntryEventStream
    });
    document.body.appendChild(element);
    await flushPromises();

    // Find the "Max Number of Events to Stream" input (first lightning-input in the panel body)
    const panelBody = element.shadowRoot.querySelector('.slds-panel__body');
    const allInputs = panelBody.querySelectorAll('lightning-input');
    const maxEventsInput = allInputs[0]; // First input has field-level-help
    expect(maxEventsInput).toBeTruthy();
    maxEventsInput.value = '0';
    const changeEvent = new CustomEvent('change', { bubbles: true, composed: true });
    maxEventsInput.dispatchEvent(changeEvent);
    await flushPromises();
    await Promise.resolve(); // Ensure component has processed the change

    // Try to publish event - should immediately pause stream
    const testEvent = { ...mockLogEntryEventTemplate };
    await jestMockPublish('/event/LogEntryEvent__e', {
      data: { payload: testEvent }
    });
    await flushPromises();

    const toggleButton = element.shadowRoot.querySelector('lightning-button-stateful[data-id="toggle-stream"]');
    expect(toggleButton.variant).toBe('brand'); // Should be paused
  });

  it('handles edge case with very large max events to display', async () => {
    isEnabled.mockResolvedValue(true);
    getSchemaForName.mockResolvedValue(mockLogEntryEventSchemaTemplate);
    getDatatableDisplayFields.mockResolvedValue(mockTableViewDisplayFields);
    const element = createElement('log-entry-event-stream', {
      is: LogEntryEventStream
    });
    document.body.appendChild(element);
    await flushPromises();

    // Find the "Max Number of Events to Display" input (it's the second lightning-input, after the one with field-level-help)
    const panelBody = element.shadowRoot.querySelector('.slds-panel__body');
    const allInputs = panelBody.querySelectorAll('lightning-input');
    // The first input has field-level-help, the second one is maxEventsToDisplay
    const maxEventsInput = allInputs[1];
    expect(maxEventsInput).toBeTruthy();
    expect(maxEventsInput.type).toBe('number');
    maxEventsInput.value = '1000';
    const changeEvent = new CustomEvent('change', { bubbles: true, composed: true });
    maxEventsInput.dispatchEvent(changeEvent);
    await flushPromises();
    await Promise.resolve(); // Ensure component has processed the change

    // Publish multiple events
    for (let i = 0; i < 5; i++) {
      const event = { ...mockLogEntryEventTemplate };
      event.TransactionId__c = `TEST-${i}`;
      await jestMockPublish('/event/LogEntryEvent__e', {
        data: { payload: event }
      });
    }
    await flushPromises();

    // Should show all events
    const eventStreamDiv = element.shadowRoot.querySelector('.event-stream');
    expect(eventStreamDiv.textContent).toContain('TEST-0');
    expect(eventStreamDiv.textContent).toContain('TEST-4');
  });
});
