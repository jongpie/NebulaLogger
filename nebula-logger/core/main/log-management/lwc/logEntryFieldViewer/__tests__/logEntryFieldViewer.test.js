import { createElement } from '@lwc/engine-dom';
import LogEntryFieldViewer from 'c/logEntryFieldViewer';
import { getRecord } from 'lightning/uiRecordApi';

jest.mock(
  'lightning/platformResourceLoader',
  () => ({
    loadScript: () => Promise.resolve(),
    loadStyle: () => Promise.resolve()
  }),
  { virtual: true }
);

const flushPromises = async () => {
  for (let i = 0; i < 12; i++) {
    /* eslint-disable-next-line no-await-in-loop */
    await Promise.resolve();
  }
};

const createViewer = ({ recordId = 'a01000000000001', fieldApiName, config } = {}) => {
  const element = createElement('c-log-entry-field-viewer', { is: LogEntryFieldViewer });
  element.recordId = recordId;
  element.fieldApiName = fieldApiName;
  if (config) {
    element.config = config;
  }
  document.body.appendChild(element);
  return element;
};

describe('c-log-entry-field-viewer', () => {
  beforeEach(() => {
    global.Prism = { highlightAll: jest.fn() };
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    delete global.Prism;
    jest.clearAllMocks();
  });

  it('renders an inner loggerCodeViewer immediately', async () => {
    const element = createViewer({ fieldApiName: 'HttpRequestBody__c' });
    await flushPromises();

    expect(element.shadowRoot.querySelector('c-logger-code-viewer')).toBeTruthy();
  });

  it('passes the record field value as code to loggerCodeViewer', async () => {
    const element = createViewer({ fieldApiName: 'HttpRequestBody__c' });

    getRecord.emit({
      fields: {
        HttpRequestBody__c: { value: '{"hello":"world"}' }
      }
    });
    await flushPromises();

    const viewer = element.shadowRoot.querySelector('c-logger-code-viewer');
    expect(viewer.code).toBe('{"hello":"world"}');
  });

  it('exposes the unprefixed field API name in the inner viewer config', async () => {
    const element = createViewer({ fieldApiName: 'HttpRequestBody__c' });

    getRecord.emit({ fields: { HttpRequestBody__c: { value: 'x' } } });
    await flushPromises();

    const viewer = element.shadowRoot.querySelector('c-logger-code-viewer');
    expect(viewer.config.fieldName).toBe('HttpRequestBody__c');
  });

  it('forwards toolbar capability flags through the config object', async () => {
    const element = createViewer({
      fieldApiName: 'HttpRequestBody__c',
      config: { showThemePicker: true, showLanguagePicker: true, showRememberPreference: false }
    });

    getRecord.emit({ fields: { HttpRequestBody__c: { value: 'x' } } });
    await flushPromises();

    const viewer = element.shadowRoot.querySelector('c-logger-code-viewer');
    expect(viewer.config.showThemePicker).toBe(true);
    expect(viewer.config.showLanguagePicker).toBe(true);
    expect(viewer.config.showRememberPreference).toBe(false);
  });

  describe('Content-Type auto-detection', () => {
    const buildHeadersScenario = headerValue => ({
      fieldApiName: 'HttpResponseBody__c',
      config: { contentTypeHeadersFieldApiName: 'HttpResponseHeaders__c' },
      record: {
        fields: {
          HttpResponseBody__c: { value: '' },
          HttpResponseHeaders__c: { value: headerValue }
        }
      }
    });

    it('detects JSON from a Content-Type header', async () => {
      const scenario = buildHeadersScenario('Content-Type: application/json; charset=utf-8\nServer: nginx');
      const element = createViewer(scenario);
      getRecord.emit(scenario.record);
      await flushPromises();

      expect(element.shadowRoot.querySelector('c-logger-code-viewer').config.autoLanguage).toBe('json');
    });

    it('detects XML from a text/xml Content-Type header', async () => {
      const scenario = buildHeadersScenario('Content-Type: text/xml');
      const element = createViewer(scenario);
      getRecord.emit(scenario.record);
      await flushPromises();

      expect(element.shadowRoot.querySelector('c-logger-code-viewer').config.autoLanguage).toBe('xml');
    });

    it('detects HTML from text/html', async () => {
      const scenario = buildHeadersScenario('Content-Type: text/html');
      const element = createViewer(scenario);
      getRecord.emit(scenario.record);
      await flushPromises();

      expect(element.shadowRoot.querySelector('c-logger-code-viewer').config.autoLanguage).toBe('html');
    });

    it('falls back to plaintext when Content-Type is text/plain', async () => {
      const scenario = buildHeadersScenario('Content-Type: text/plain');
      const element = createViewer(scenario);
      getRecord.emit(scenario.record);
      await flushPromises();

      expect(element.shadowRoot.querySelector('c-logger-code-viewer').config.autoLanguage).toBe('plaintext');
    });

    it('returns no auto language when the headers field is empty', async () => {
      const element = createViewer({
        fieldApiName: 'HttpResponseBody__c',
        config: { contentTypeHeadersFieldApiName: 'HttpResponseHeaders__c' }
      });
      getRecord.emit({
        fields: {
          HttpResponseBody__c: { value: '' },
          HttpResponseHeaders__c: { value: null }
        }
      });
      await flushPromises();

      expect(element.shadowRoot.querySelector('c-logger-code-viewer').config.autoLanguage).toBeUndefined();
    });

    it('returns no auto language when the headers do not include a Content-Type', async () => {
      const scenario = buildHeadersScenario('Server: nginx\nDate: today');
      const element = createViewer(scenario);
      getRecord.emit(scenario.record);
      await flushPromises();

      expect(element.shadowRoot.querySelector('c-logger-code-viewer').config.autoLanguage).toBeUndefined();
    });

    it('matches Content-Type case-insensitively', async () => {
      const scenario = buildHeadersScenario('content-type: APPLICATION/JSON');
      const element = createViewer(scenario);
      getRecord.emit(scenario.record);
      await flushPromises();

      expect(element.shadowRoot.querySelector('c-logger-code-viewer').config.autoLanguage).toBe('json');
    });
  });

  describe('namespaced managed package compatibility', () => {
    it('reads the field value when the record is returned with a namespace-prefixed key', async () => {
      const element = createViewer({ fieldApiName: 'HttpRequestBody__c' });

      getRecord.emit({
        fields: {
          Nebula__HttpRequestBody__c: { value: 'namespaced-body' }
        }
      });
      await flushPromises();

      const viewer = element.shadowRoot.querySelector('c-logger-code-viewer');
      expect(viewer.code).toBe('namespaced-body');
    });

    it('detects Content-Type from a namespace-prefixed headers field key', async () => {
      const element = createViewer({
        fieldApiName: 'HttpResponseBody__c',
        config: { contentTypeHeadersFieldApiName: 'HttpResponseHeaders__c' }
      });

      getRecord.emit({
        fields: {
          Nebula__HttpResponseBody__c: { value: '{}' },
          Nebula__HttpResponseHeaders__c: { value: 'Content-Type: application/json' }
        }
      });
      await flushPromises();

      const viewer = element.shadowRoot.querySelector('c-logger-code-viewer');
      expect(viewer.code).toBe('{}');
      expect(viewer.config.autoLanguage).toBe('json');
    });

    it('prefers the unprefixed field key when both unprefixed and prefixed are present', async () => {
      const element = createViewer({ fieldApiName: 'HttpRequestBody__c' });

      getRecord.emit({
        fields: {
          HttpRequestBody__c: { value: 'unprefixed-wins' },
          Nebula__HttpRequestBody__c: { value: 'should-not-be-used' }
        }
      });
      await flushPromises();

      const viewer = element.shadowRoot.querySelector('c-logger-code-viewer');
      expect(viewer.code).toBe('unprefixed-wins');
    });
  });

  describe('passthrough of additional config keys', () => {
    it('passes config.defaultLanguage to the inner viewer config', async () => {
      const element = createViewer({
        fieldApiName: 'HttpResponseHeaders__c',
        config: { defaultLanguage: 'http' }
      });

      getRecord.emit({ fields: { HttpResponseHeaders__c: { value: 'Content-Type: x' } } });
      await flushPromises();

      expect(element.shadowRoot.querySelector('c-logger-code-viewer').config.defaultLanguage).toBe('http');
    });

    it('passes config.availableLanguages to the inner viewer config', async () => {
      const customLanguages = [
        { label: 'Auto', value: 'auto' },
        { label: 'JSON', value: 'json' }
      ];
      const element = createViewer({
        fieldApiName: 'HttpRequestBody__c',
        config: { availableLanguages: customLanguages }
      });

      getRecord.emit({ fields: { HttpRequestBody__c: { value: '' } } });
      await flushPromises();

      expect(element.shadowRoot.querySelector('c-logger-code-viewer').config.availableLanguages).toEqual(customLanguages);
    });
  });
});
