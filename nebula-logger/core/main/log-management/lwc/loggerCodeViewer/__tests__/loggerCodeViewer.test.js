import { createElement } from '@lwc/engine-dom';
import LoggerCodeViewer from 'c/loggerCodeViewer';

// jest.mock factories cannot reference outer variables unless the names start
// with `mock`. These let each test swap in resolve/reject behavior.
let mockLoadScriptImpl;
let mockLoadStyleImpl;

jest.mock(
  'lightning/platformResourceLoader',
  () => ({
    loadScript: (...args) => mockLoadScriptImpl(...args),
    loadStyle: (...args) => mockLoadStyleImpl(...args)
  }),
  { virtual: true }
);

// _loadPrismResources awaits Promise.all over async wrappers, then renderedCallback's
// catch block runs, then LWC re-renders. With rAF stubbed to fire synchronously
// in beforeEach, microtask flushes are sufficient.
const flushPromises = async () => {
  for (let i = 0; i < 12; i++) {
    /* eslint-disable-next-line no-await-in-loop  */
    await Promise.resolve();
  }
};

describe('c-logger-code-viewer', () => {
  let consoleErrorSpy;
  let consoleLogSpy;
  let storage;

  beforeEach(() => {
    global.Prism = { highlightAll: jest.fn() };
    mockLoadScriptImpl = jest.fn(() => Promise.resolve());
    mockLoadStyleImpl = jest.fn(() => Promise.resolve());
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    consoleLogSpy = jest.spyOn(console, 'log').mockImplementation(() => {});

    storage = {};
    Object.defineProperty(global, 'localStorage', {
      configurable: true,
      value: {
        getItem: jest.fn(key => (key in storage ? storage[key] : null)),
        setItem: jest.fn((key, value) => {
          storage[key] = String(value);
        }),
        removeItem: jest.fn(key => {
          delete storage[key];
        }),
        clear: jest.fn(() => {
          storage = {};
        })
      }
    });
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    consoleErrorSpy.mockRestore();
    consoleLogSpy.mockRestore();
    delete global.Prism;
    delete global.localStorage;
    jest.clearAllMocks();
    jest.resetModules();
  });

  describe('existing primitive behavior', () => {
    it('displays Prism code viewer with provided attributes', async () => {
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.language = 'apex';
      element.startingLineNumber = '10';
      element.targetLineNumber = '18';
      let mockCode = '';
      for (let i = 0; i < element.targetLineNumber + 5; i++) {
        mockCode += 'some line of "code", line number is ' + (i + 1) + '\n';
      }
      element.code = mockCode;

      document.body.appendChild(element);
      await flushPromises();

      const prismCodeViewerPre = element.shadowRoot.querySelector('div.prism-viewer pre');
      expect(prismCodeViewerPre).toBeTruthy();
      expect(prismCodeViewerPre.classList.contains('line-numbers')).toBeTruthy();
      expect(prismCodeViewerPre.dataset.start).toBe(element.startingLineNumber);
      expect(prismCodeViewerPre.dataset.line).toBe(element.targetLineNumber);
      expect(prismCodeViewerPre.dataset.lineOffset).toBe(element.targetLineNumber);
      const prismCodeViewerPreCode = element.shadowRoot.querySelector('div.prism-viewer pre code');
      expect(prismCodeViewerPreCode).toBeTruthy();
      expect(prismCodeViewerPreCode.classList.contains('language-' + element.language)).toBeTruthy();
      expect(prismCodeViewerPreCode.textContent).toContain(mockCode);
      expect(global.Prism.highlightAll).toHaveBeenCalled();
      expect(consoleErrorSpy).not.toHaveBeenCalled();
    });

    it('renders code and logs an aggregated error when loadScript rejects', async () => {
      mockLoadScriptImpl = jest.fn(() => Promise.reject(new Error('script-load-failed')));
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = 'plain text line\nsecond line';
      element.language = 'apex';
      element.startingLineNumber = '10';
      element.targetLineNumber = '18';

      document.body.appendChild(element);
      await flushPromises();

      expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
      const prismCodeViewerPre = element.shadowRoot.querySelector('div.prism-viewer pre');
      expect(prismCodeViewerPre).toBeTruthy();
      expect(prismCodeViewerPre.dataset.start).toBe(element.startingLineNumber);
      expect(prismCodeViewerPre.dataset.line).toBe(element.targetLineNumber);
      expect(prismCodeViewerPre.dataset.lineOffset).toBe(element.targetLineNumber);
      const prismCodeViewerPreCode = prismCodeViewerPre.querySelector('code');
      expect(prismCodeViewerPreCode).toBeTruthy();
      expect(prismCodeViewerPreCode.classList.contains('language-' + element.language)).toBeTruthy();
      expect(prismCodeViewerPreCode.textContent).toBe('plain text line\nsecond line');
      expect(global.Prism.highlightAll).not.toHaveBeenCalled();
      expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
      const [loggedMessage, loggedError] = consoleErrorSpy.mock.calls[0];
      expect(loggedMessage).toContain('Failed to load Prism resources');
      expect(loggedError).toBeInstanceOf(Error);
      expect(loggedError.message).toContain('/Prism/prism.min.js');
      expect(loggedError.message).toContain('"resourceType": "script"');
      expect(loggedError.message).toContain('script-load-failed');
    });

    it('renders fallback code and logs an aggregated error when loadStyle rejects', async () => {
      mockLoadStyleImpl = jest.fn((_owner, resourceUrl) => {
        if (resourceUrl && resourceUrl.endsWith('/Prism/themes/prism-tomorrow.min.css')) {
          return Promise.reject(new Error('style-load-failed'));
        }
        return Promise.resolve();
      });
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = 'css-failure-code';

      document.body.appendChild(element);
      await flushPromises();

      const prismCodeViewerPreCode = element.shadowRoot.querySelector('div.prism-viewer pre code');
      expect(prismCodeViewerPreCode).toBeTruthy();
      expect(prismCodeViewerPreCode.textContent).toBe('css-failure-code');
      expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
      const [, loggedError] = consoleErrorSpy.mock.calls[0];
      expect(loggedError.message).toContain('"resourceType": "style"');
      expect(loggedError.message).toContain('/Prism/themes/prism-tomorrow.min.css');
      expect(loggedError.message).toContain('style-load-failed');
      expect(loggedError.message).not.toContain('prism.nebula-logger.css');
    });

    it('aggregates multiple resource failures into a single error message', async () => {
      mockLoadScriptImpl = jest.fn(() => Promise.reject(new Error('script-fail')));
      mockLoadStyleImpl = jest.fn(() => Promise.reject(new Error('style-fail')));

      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = 'x';
      document.body.appendChild(element);
      await flushPromises();

      expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
      const [, loggedError] = consoleErrorSpy.mock.calls[0];
      expect(loggedError.message).toContain('script-fail');
      expect(loggedError.message).toContain('style-fail');
      expect(loggedError.message).toContain('/Prism/prism.min.js');
      expect(loggedError.message).toContain('/Prism/themes/prism-tomorrow.min.css');
      expect(loggedError.message).toContain('/Prism/prism.nebula-logger.css');
    });

    it('serializes non-Error rejection reasons via reasonAsString', async () => {
      mockLoadScriptImpl = jest.fn(() => Promise.reject('plain-string-reason'));

      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = 'x';
      document.body.appendChild(element);
      await flushPromises();

      const [, loggedError] = consoleErrorSpy.mock.calls[0];
      expect(loggedError.message).toContain('"reasonAsString": "plain-string-reason"');
      expect(loggedError.message).toContain('"reason": "plain-string-reason"');
      expect(loggedError.message).not.toContain('"name":');
      expect(loggedError.message).not.toContain('"stack":');
    });

    it('renders an empty fallback code element when @api code is undefined', async () => {
      mockLoadScriptImpl = jest.fn(() => Promise.reject(new Error('any')));

      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      document.body.appendChild(element);
      await flushPromises();

      const fallbackCode = element.shadowRoot.querySelector('div.prism-viewer pre code');
      expect(fallbackCode).toBeTruthy();
      // eslint-disable-next-line
      expect(fallbackCode.innerHTML).toBe('');
    });

    it('does not retry resource loading on later renders after a failure', async () => {
      mockLoadScriptImpl = jest.fn(() => Promise.reject(new Error('boom')));

      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = 'first';
      document.body.appendChild(element);
      await flushPromises();

      expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
      expect(mockLoadScriptImpl).toHaveBeenCalledTimes(1);

      element.code = 'second';
      await flushPromises();

      expect(mockLoadScriptImpl).toHaveBeenCalledTimes(1);
      expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
    });

    it('does not reload Prism core resources on later renders after a successful load', async () => {
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = 'first';
      element.language = 'apex';
      document.body.appendChild(element);
      await flushPromises();

      expect(mockLoadScriptImpl).toHaveBeenCalledTimes(1);

      element.code = 'second';
      await flushPromises();

      expect(mockLoadScriptImpl).toHaveBeenCalledTimes(1);
    });
  });

  describe('toolbar visibility', () => {
    it('hides every toolbar control by default', async () => {
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = 'x';
      document.body.appendChild(element);
      await flushPromises();

      expect(element.shadowRoot.querySelector('[data-id="theme-picker"]')).toBeNull();
      expect(element.shadowRoot.querySelector('[data-id="language-picker"]')).toBeNull();
      expect(element.shadowRoot.querySelector('[data-id="remember-toggle"]')).toBeNull();
    });

    it('renders the theme picker only when config.showThemePicker is true', async () => {
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = 'x';
      element.config = { showThemePicker: true };
      document.body.appendChild(element);
      await flushPromises();

      const themePicker = element.shadowRoot.querySelector('[data-id="theme-picker"]');
      expect(themePicker).toBeTruthy();
      // The dropdown options should reflect the canonical theme list from preferences.
      expect(themePicker.options.length).toBeGreaterThanOrEqual(2);
      const values = themePicker.options.map(o => o.value);
      expect(values).toContain('prism-tomorrow');
      expect(values).toContain('prism-okaidia');
    });

    it('renders the language picker only when config.showLanguagePicker is true', async () => {
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = 'x';
      element.config = { showLanguagePicker: true, fieldName: 'HttpRequestBody__c' };
      document.body.appendChild(element);
      await flushPromises();

      expect(element.shadowRoot.querySelector('[data-id="language-picker"]')).toBeTruthy();
    });

    it('renders the remember toggle only when config.showRememberPreference is true', async () => {
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = 'x';
      element.config = { showRememberPreference: true, fieldName: 'HttpRequestBody__c' };
      document.body.appendChild(element);
      await flushPromises();

      expect(element.shadowRoot.querySelector('[data-id="remember-toggle"]')).toBeTruthy();
    });
  });

  describe('language resolution', () => {
    it('uses the user-saved language from preferences when available', async () => {
      storage['nebula-logger:lang:HttpRequestBody__c'] = 'json';
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = '{"hi":1}';
      element.language = 'plaintext';
      element.config = { fieldName: 'HttpRequestBody__c' };
      document.body.appendChild(element);
      await flushPromises();

      const code = element.shadowRoot.querySelector('div.prism-viewer pre code');
      expect(code.classList.contains('language-json')).toBeTruthy();
    });

    it('falls back to config.autoLanguage when no saved preference exists', async () => {
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = '{"hi":1}';
      element.language = 'plaintext';
      element.config = { fieldName: 'HttpRequestBody__c', autoLanguage: 'json' };
      document.body.appendChild(element);
      await flushPromises();

      const code = element.shadowRoot.querySelector('div.prism-viewer pre code');
      expect(code.classList.contains('language-json')).toBeTruthy();
    });

    it('falls back to @api language when neither saved pref nor autoLanguage exists', async () => {
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = 'foo';
      element.language = 'apex';
      element.config = { fieldName: 'Message__c' };
      document.body.appendChild(element);
      await flushPromises();

      const code = element.shadowRoot.querySelector('div.prism-viewer pre code');
      expect(code.classList.contains('language-apex')).toBeTruthy();
    });

    it('uses config.defaultLanguage when nothing else is provided', async () => {
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = 'foo';
      element.config = { defaultLanguage: 'http' };
      document.body.appendChild(element);
      await flushPromises();

      const code = element.shadowRoot.querySelector('div.prism-viewer pre code');
      expect(code.classList.contains('language-http')).toBeTruthy();
    });
  });

  describe('language picker interaction', () => {
    it('saves the selected language to per-field preferences when remember is enabled', async () => {
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = '<a/>';
      element.language = 'plaintext';
      element.config = { showLanguagePicker: true, fieldName: 'HttpRequestBody__c' };
      document.body.appendChild(element);
      await flushPromises();

      const picker = element.shadowRoot.querySelector('[data-id="language-picker"]');
      picker.dispatchEvent(new CustomEvent('change', { detail: { value: 'xml' } }));
      await flushPromises();

      const code = element.shadowRoot.querySelector('div.prism-viewer pre code');
      expect(code.classList.contains('language-xml')).toBeTruthy();
      expect(storage['nebula-logger:lang:HttpRequestBody__c']).toBe('xml');
    });

    it('does not persist the selected language when remember is disabled', async () => {
      storage['nebula-logger:remember'] = 'false';
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = '<a/>';
      element.config = { showLanguagePicker: true, showRememberPreference: true, fieldName: 'HttpRequestBody__c' };
      document.body.appendChild(element);
      await flushPromises();

      const picker = element.shadowRoot.querySelector('[data-id="language-picker"]');
      picker.dispatchEvent(new CustomEvent('change', { detail: { value: 'xml' } }));
      await flushPromises();

      const code = element.shadowRoot.querySelector('div.prism-viewer pre code');
      expect(code.classList.contains('language-xml')).toBeTruthy();
      expect(storage['nebula-logger:lang:HttpRequestBody__c']).toBeUndefined();
    });

    it('clears the per-field preference when "auto" is chosen and reverts to autoLanguage', async () => {
      storage['nebula-logger:lang:HttpRequestBody__c'] = 'xml';
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = '{}';
      element.config = { showLanguagePicker: true, fieldName: 'HttpRequestBody__c', autoLanguage: 'json' };
      document.body.appendChild(element);
      await flushPromises();

      const picker = element.shadowRoot.querySelector('[data-id="language-picker"]');
      picker.dispatchEvent(new CustomEvent('change', { detail: { value: 'auto' } }));
      await flushPromises();

      expect(storage['nebula-logger:lang:HttpRequestBody__c']).toBeUndefined();
      const code = element.shadowRoot.querySelector('div.prism-viewer pre code');
      expect(code.classList.contains('language-json')).toBeTruthy();
    });
  });

  describe('theme picker interaction', () => {
    it('persists theme selection and re-renders Prism with the new theme stylesheet', async () => {
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = 'x';
      element.config = { showThemePicker: true };
      document.body.appendChild(element);
      await flushPromises();

      mockLoadStyleImpl.mockClear();

      const picker = element.shadowRoot.querySelector('[data-id="theme-picker"]');
      picker.dispatchEvent(new CustomEvent('change', { detail: { value: 'prism-okaidia' } }));
      await flushPromises();

      expect(storage['nebula-logger:theme']).toBe('prism-okaidia');
      const newStyleCalls = mockLoadStyleImpl.mock.calls.map(call => call[1]);
      expect(newStyleCalls.some(url => url.includes('prism-okaidia.min.css'))).toBe(true);
    });

    it('updates other instances when the theme changes (cross-instance broadcast)', async () => {
      const elementA = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      elementA.code = 'a';
      elementA.config = { showThemePicker: true };
      document.body.appendChild(elementA);

      const elementB = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      elementB.code = 'b';
      // Element B does NOT show the theme picker, but should still react to theme changes.
      document.body.appendChild(elementB);

      await flushPromises();
      mockLoadStyleImpl.mockClear();

      const picker = elementA.shadowRoot.querySelector('[data-id="theme-picker"]');
      picker.dispatchEvent(new CustomEvent('change', { detail: { value: 'prism-twilight' } }));
      await flushPromises();

      // Each subscribed instance loads the new theme stylesheet via loadStyle. Two live instances
      // means we expect at least two loadStyle calls for the new theme URL — one per subscriber.
      const twilightLoads = mockLoadStyleImpl.mock.calls.filter(call => call[1] && call[1].includes('prism-twilight.min.css'));
      expect(twilightLoads.length).toBeGreaterThanOrEqual(2);
      // Verify each call had a distinct owner (the two component instances).
      const distinctOwners = new Set(twilightLoads.map(call => call[0]));
      expect(distinctOwners.size).toBeGreaterThanOrEqual(2);
    });
  });

  describe('remember toggle interaction', () => {
    it('persists the remember preference when toggled', async () => {
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = 'x';
      element.config = { showRememberPreference: true, fieldName: 'HttpRequestBody__c' };
      document.body.appendChild(element);
      await flushPromises();

      const toggle = element.shadowRoot.querySelector('[data-id="remember-toggle"]');
      toggle.dispatchEvent(new CustomEvent('change', { detail: { checked: false } }));
      await flushPromises();

      expect(storage['nebula-logger:remember']).toBe('false');
    });
  });

  describe('teardown', () => {
    it('unsubscribes from theme changes when the component is removed', async () => {
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = 'x';
      element.config = { showThemePicker: true };
      document.body.appendChild(element);
      await flushPromises();

      element.remove();
      await flushPromises();

      // After removal, changing theme on another instance should not invoke loadStyle on behalf of
      // the disconnected viewer. We assert by counting how many times loadStyle is called for the
      // detached owner element.
      mockLoadStyleImpl.mockClear();
      const liveElement = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      liveElement.code = 'y';
      liveElement.config = { showThemePicker: true };
      document.body.appendChild(liveElement);
      await flushPromises();
      mockLoadStyleImpl.mockClear();

      const picker = liveElement.shadowRoot.querySelector('[data-id="theme-picker"]');
      picker.dispatchEvent(new CustomEvent('change', { detail: { value: 'prism-coy' } }));
      await flushPromises();

      const ownersCalled = mockLoadStyleImpl.mock.calls.map(call => call[0]);
      // The disconnected element should never appear as the owner of a loadStyle call.
      expect(ownersCalled.includes(element)).toBe(false);
    });
  });
});
