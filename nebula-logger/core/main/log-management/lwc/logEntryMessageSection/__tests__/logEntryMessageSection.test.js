import { createElement } from '@lwc/engine-dom';
import LogEntryMessageSection from 'c/logEntryMessageSection';

// loggerCodeViewer renders into the DOM after a successful Prism load. Stub out the resource loader
// and provide a minimal Prism so console.error noise doesn't pollute the test output.
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

describe('c-log-entry-message-section', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it('renders a collapsible logger-page-section with the configured title', async () => {
    const element = createElement('c-log-entry-message-section', { is: LogEntryMessageSection });
    element.recordId = 'a01000000000001';
    document.body.appendChild(element);
    await flushPromises();

    const pageSection = element.shadowRoot.querySelector('c-logger-page-section');
    expect(pageSection).toBeTruthy();
    const title = pageSection.querySelector('span[slot="title"]');
    expect(title).toBeTruthy();
    expect(title.textContent).toBe('Message Details');
  });

  it('renders a record-view-form scoped to LogEntry__c so unprefixed field names resolve at runtime', async () => {
    const element = createElement('c-log-entry-message-section', { is: LogEntryMessageSection });
    element.recordId = 'a01000000000001';
    document.body.appendChild(element);
    await flushPromises();

    const form = element.shadowRoot.querySelector('lightning-record-view-form');
    expect(form).toBeTruthy();
    expect(form.objectApiName).toBe('LogEntry__c');
    expect(form.recordId).toBe('a01000000000001');
  });

  it('renders the masked / truncated indicator output fields', async () => {
    const element = createElement('c-log-entry-message-section', { is: LogEntryMessageSection });
    element.recordId = 'a01000000000001';
    document.body.appendChild(element);
    await flushPromises();

    const fieldNames = Array.from(element.shadowRoot.querySelectorAll('lightning-output-field')).map(f => f.fieldName);
    expect(fieldNames).toContain('MessageMasked__c');
    expect(fieldNames).toContain('MessageTruncated__c');
  });

  it('renders a logEntryFieldViewer for Message__c with language picker enabled', async () => {
    const element = createElement('c-log-entry-message-section', { is: LogEntryMessageSection });
    element.recordId = 'a01000000000001';
    document.body.appendChild(element);
    await flushPromises();

    const viewers = element.shadowRoot.querySelectorAll('c-log-entry-field-viewer');
    const messageViewer = Array.from(viewers).find(v => v.fieldApiName === 'Message__c');
    expect(messageViewer).toBeTruthy();
    expect(messageViewer.recordId).toBe('a01000000000001');
    expect(messageViewer.config.showLanguagePicker).toBe(true);
    expect(messageViewer.config.showThemePicker).toBe(true);
    expect(messageViewer.config.showRememberPreference).toBe(true);
  });

  it('renders a logEntryFieldViewer for StackTrace__c that defaults to apex', async () => {
    const element = createElement('c-log-entry-message-section', { is: LogEntryMessageSection });
    element.recordId = 'a01000000000001';
    document.body.appendChild(element);
    await flushPromises();

    const viewers = element.shadowRoot.querySelectorAll('c-log-entry-field-viewer');
    const stackTraceViewer = Array.from(viewers).find(v => v.fieldApiName === 'StackTrace__c');
    expect(stackTraceViewer).toBeTruthy();
    expect(stackTraceViewer.config.defaultLanguage).toBe('apex');
  });
});
