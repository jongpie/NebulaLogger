import { createElement } from '@lwc/engine-dom';
import LogEntryRestSection from 'c/logEntryRestSection';

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

describe('c-log-entry-rest-section', () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    delete global.Prism;
  });

  const setup = async () => {
    const element = createElement('c-log-entry-rest-section', { is: LogEntryRestSection });
    element.recordId = 'a01000000000001';
    document.body.appendChild(element);
    await flushPromises();
    return element;
  };

  it('renders a logger-page-section titled Apex REST Service Details', async () => {
    const element = await setup();
    const title = element.shadowRoot.querySelector('c-logger-page-section span[slot="title"]');
    expect(title.textContent).toBe('Apex REST Service Details');
  });

  it('renders the REST request resource path, URI, method, and remote address as plain output fields', async () => {
    const element = await setup();
    const fieldNames = Array.from(element.shadowRoot.querySelectorAll('lightning-output-field')).map(f => f.fieldName);

    expect(fieldNames).toContain('RestRequestResourcePath__c');
    expect(fieldNames).toContain('RestRequestUri__c');
    expect(fieldNames).toContain('RestRequestMethod__c');
    expect(fieldNames).toContain('RestRequestRemoteAddress__c');
  });

  it('renders the REST response status code as a plain output field', async () => {
    const element = await setup();
    const fieldNames = Array.from(element.shadowRoot.querySelectorAll('lightning-output-field')).map(f => f.fieldName);

    expect(fieldNames).toContain('RestResponseStatusCode__c');
  });

  it('renders Prism viewers for both REST request and response headers using the http language', async () => {
    const element = await setup();
    const viewers = element.shadowRoot.querySelectorAll('c-log-entry-field-viewer');

    const requestHeaders = Array.from(viewers).find(v => v.fieldApiName === 'RestRequestHeaders__c');
    const responseHeaders = Array.from(viewers).find(v => v.fieldApiName === 'RestResponseHeaders__c');

    expect(requestHeaders).toBeTruthy();
    expect(requestHeaders.config.defaultLanguage).toBe('http');
    expect(responseHeaders).toBeTruthy();
    expect(responseHeaders.config.defaultLanguage).toBe('http');
  });

  it('wires REST body fields to auto-detect language from their corresponding headers field', async () => {
    const element = await setup();
    const viewers = element.shadowRoot.querySelectorAll('c-log-entry-field-viewer');

    const requestBody = Array.from(viewers).find(v => v.fieldApiName === 'RestRequestBody__c');
    expect(requestBody.config.contentTypeHeadersFieldApiName).toBe('RestRequestHeaders__c');

    const responseBody = Array.from(viewers).find(v => v.fieldApiName === 'RestResponseBody__c');
    expect(responseBody.config.contentTypeHeadersFieldApiName).toBe('RestResponseHeaders__c');
  });

  it('renders Prism viewer for RestRequestParameters__c with default language plaintext', async () => {
    const element = await setup();
    const viewers = element.shadowRoot.querySelectorAll('c-log-entry-field-viewer');
    const params = Array.from(viewers).find(v => v.fieldApiName === 'RestRequestParameters__c');
    expect(params).toBeTruthy();
    expect(params.config.defaultLanguage).toBe('plaintext');
  });
});
