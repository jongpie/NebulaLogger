import { createElement } from '@lwc/engine-dom';
import LogEntryExceptionSection from 'c/logEntryExceptionSection';

jest.mock(
  'lightning/platformResourceLoader',
  () => ({
    loadScript: () => {
      global.Prism = { highlightAll: jest.fn() };
      return Promise.resolve();
    },
    loadStyle: () => Promise.resolve()
  }),
  { virtual: true }
);

const flushPromises = async () => {
  for (let i = 0; i < 4; i++) {
    /* eslint-disable-next-line no-await-in-loop */
    await Promise.resolve();
  }
};

describe('c-log-entry-exception-section', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    delete global.Prism;
  });

  it('renders a collapsible logger-page-section titled Exception Details', async () => {
    const element = createElement('c-log-entry-exception-section', { is: LogEntryExceptionSection });
    element.recordId = 'a01000000000001';
    document.body.appendChild(element);
    await flushPromises();

    const title = element.shadowRoot.querySelector('c-logger-page-section span[slot="title"]');
    expect(title.textContent).toBe('Exception Details');
  });

  it('renders the exception type as a plain output field', async () => {
    const element = createElement('c-log-entry-exception-section', { is: LogEntryExceptionSection });
    element.recordId = 'a01000000000001';
    document.body.appendChild(element);
    await flushPromises();

    const fieldNames = Array.from(element.shadowRoot.querySelectorAll('lightning-output-field')).map(f => f.fieldName);
    expect(fieldNames).toContain('ExceptionType__c');
  });

  it('renders ExceptionMessage__c through a logEntryFieldViewer with language picker enabled', async () => {
    const element = createElement('c-log-entry-exception-section', { is: LogEntryExceptionSection });
    element.recordId = 'a01000000000001';
    document.body.appendChild(element);
    await flushPromises();

    const viewers = element.shadowRoot.querySelectorAll('c-log-entry-field-viewer');
    const messageViewer = Array.from(viewers).find(v => v.fieldApiName === 'ExceptionMessage__c');
    expect(messageViewer).toBeTruthy();
    expect(messageViewer.recordId).toBe('a01000000000001');
    expect(messageViewer.config.showLanguagePicker).toBe(true);
  });

  it('renders ExceptionStackTrace__c through a logEntryFieldViewer that defaults to apex', async () => {
    const element = createElement('c-log-entry-exception-section', { is: LogEntryExceptionSection });
    element.recordId = 'a01000000000001';
    document.body.appendChild(element);
    await flushPromises();

    const viewers = element.shadowRoot.querySelectorAll('c-log-entry-field-viewer');
    const stackTraceViewer = Array.from(viewers).find(v => v.fieldApiName === 'ExceptionStackTrace__c');
    expect(stackTraceViewer).toBeTruthy();
    expect(stackTraceViewer.config.defaultLanguage).toBe('apex');
  });
});
