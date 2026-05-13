import { createElement } from '@lwc/engine-dom';
import LogEntryHttpSection from 'c/logEntryHttpSection';

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

describe('c-log-entry-http-section', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    delete global.Prism;
  });

  const setup = async () => {
    const element = createElement('c-log-entry-http-section', { is: LogEntryHttpSection });
    element.recordId = 'a01000000000001';
    document.body.appendChild(element);
    await flushPromises();
    return element;
  };

  it('renders a logger-page-section titled HTTP Callout Details', async () => {
    const element = await setup();
    const title = element.shadowRoot.querySelector('c-logger-page-section span[slot="title"]');
    expect(title.textContent).toBe('HTTP Callout Details');
  });

  it('renders the HTTP request endpoint, method, and compressed flag as plain output fields', async () => {
    const element = await setup();
    const fieldNames = Array.from(element.shadowRoot.querySelectorAll('lightning-output-field')).map(f => f.fieldName);

    expect(fieldNames).toContain('HttpRequestEndpoint__c');
    expect(fieldNames).toContain('HttpRequestMethod__c');
    expect(fieldNames).toContain('HttpRequestCompressed__c');
  });

  it('renders the HTTP response status and status code as plain output fields', async () => {
    const element = await setup();
    const fieldNames = Array.from(element.shadowRoot.querySelectorAll('lightning-output-field')).map(f => f.fieldName);

    expect(fieldNames).toContain('HttpResponseStatusCode__c');
    expect(fieldNames).toContain('HttpResponseStatus__c');
  });

  it('renders a Prism viewer for HttpRequestHeaders__c using the http language', async () => {
    const element = await setup();
    const viewers = element.shadowRoot.querySelectorAll('c-log-entry-field-viewer');
    const viewer = Array.from(viewers).find(v => v.fieldApiName === 'HttpRequestHeaders__c');
    expect(viewer).toBeTruthy();
    expect(viewer.config.defaultLanguage).toBe('http');
  });

  it('renders a Prism viewer for HttpResponseHeaders__c using the http language', async () => {
    const element = await setup();
    const viewers = element.shadowRoot.querySelectorAll('c-log-entry-field-viewer');
    const viewer = Array.from(viewers).find(v => v.fieldApiName === 'HttpResponseHeaders__c');
    expect(viewer).toBeTruthy();
    expect(viewer.config.defaultLanguage).toBe('http');
  });

  it('wires HttpRequestBody__c to auto-detect language from HttpRequestHeaders__c', async () => {
    const element = await setup();
    const viewers = element.shadowRoot.querySelectorAll('c-log-entry-field-viewer');
    const viewer = Array.from(viewers).find(v => v.fieldApiName === 'HttpRequestBody__c');
    expect(viewer).toBeTruthy();
    expect(viewer.config.contentTypeHeadersFieldApiName).toBe('HttpRequestHeaders__c');
  });

  it('wires HttpResponseBody__c to auto-detect language from HttpResponseHeaders__c', async () => {
    const element = await setup();
    const viewers = element.shadowRoot.querySelectorAll('c-log-entry-field-viewer');
    const viewer = Array.from(viewers).find(v => v.fieldApiName === 'HttpResponseBody__c');
    expect(viewer).toBeTruthy();
    expect(viewer.config.contentTypeHeadersFieldApiName).toBe('HttpResponseHeaders__c');
  });

  it('exposes both request body and response body viewers with theme + language pickers enabled', async () => {
    const element = await setup();
    const viewers = element.shadowRoot.querySelectorAll('c-log-entry-field-viewer');
    const requestBody = Array.from(viewers).find(v => v.fieldApiName === 'HttpRequestBody__c');
    const responseBody = Array.from(viewers).find(v => v.fieldApiName === 'HttpResponseBody__c');

    for (const viewer of [requestBody, responseBody]) {
      expect(viewer.config.showThemePicker).toBe(true);
      expect(viewer.config.showLanguagePicker).toBe(true);
      expect(viewer.config.showRememberPreference).toBe(true);
    }
  });
});
