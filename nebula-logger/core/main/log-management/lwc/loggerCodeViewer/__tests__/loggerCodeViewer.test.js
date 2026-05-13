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
        if (resourceUrl && resourceUrl.endsWith('/Prism/prism.nebula-logger.css')) {
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
      expect(loggedError.message).toContain('/Prism/prism.nebula-logger.css');
      expect(loggedError.message).toContain('style-load-failed');
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
    const queryThemeLink = element => element.shadowRoot.querySelector('link[data-id="theme-stylesheet"]');

    it('renders exactly one theme stylesheet link and updates its href on theme change', async () => {
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = 'x';
      element.config = { showThemePicker: true };
      document.body.appendChild(element);
      await flushPromises();

      let themeLink = queryThemeLink(element);
      expect(themeLink).toBeTruthy();
      expect(themeLink.getAttribute('rel')).toBe('stylesheet');
      expect(themeLink.getAttribute('href')).toContain('prism-tomorrow.min.css');

      const picker = element.shadowRoot.querySelector('[data-id="theme-picker"]');
      picker.dispatchEvent(new CustomEvent('change', { detail: { value: 'prism-okaidia' } }));
      await flushPromises();

      // Still exactly one link, with the new theme href — no accumulation.
      const allLinks = element.shadowRoot.querySelectorAll('link[data-id="theme-stylesheet"]');
      expect(allLinks.length).toBe(1);
      themeLink = allLinks[0];
      expect(themeLink.getAttribute('href')).toContain('prism-okaidia.min.css');
      expect(themeLink.getAttribute('href')).not.toContain('prism-tomorrow.min.css');
      expect(storage['nebula-logger:theme']).toBe('prism-okaidia');
    });

    it('does not call loadStyle for theme stylesheets (theme is managed via a single link element)', async () => {
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = 'x';
      element.config = { showThemePicker: true };
      document.body.appendChild(element);
      await flushPromises();

      const themeStyleLoads = mockLoadStyleImpl.mock.calls.filter(call => call[1] && call[1].includes('/Prism/themes/'));
      expect(themeStyleLoads.length).toBe(0);
    });

    it('keeps exactly one stylesheet link after switching themes back and forth multiple times', async () => {
      const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      element.code = 'x';
      element.config = { showThemePicker: true };
      document.body.appendChild(element);
      await flushPromises();

      const picker = element.shadowRoot.querySelector('[data-id="theme-picker"]');
      const themeRotation = ['prism-okaidia', 'prism-tomorrow', 'prism-twilight', 'prism-coy', 'prism-okaidia'];
      for (const theme of themeRotation) {
        picker.dispatchEvent(new CustomEvent('change', { detail: { value: theme } }));
        /* eslint-disable-next-line no-await-in-loop */
        await flushPromises();
      }

      const allLinks = element.shadowRoot.querySelectorAll('link[data-id="theme-stylesheet"]');
      expect(allLinks.length).toBe(1);
      expect(allLinks[0].getAttribute('href')).toContain('prism-okaidia.min.css');
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

      const picker = elementA.shadowRoot.querySelector('[data-id="theme-picker"]');
      picker.dispatchEvent(new CustomEvent('change', { detail: { value: 'prism-twilight' } }));
      await flushPromises();

      // Both instances should now reference the new theme via their own single link element.
      expect(queryThemeLink(elementA).getAttribute('href')).toContain('prism-twilight.min.css');
      expect(queryThemeLink(elementB).getAttribute('href')).toContain('prism-twilight.min.css');
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
      const detachedElement = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      detachedElement.code = 'x';
      detachedElement.config = { showThemePicker: true };
      document.body.appendChild(detachedElement);
      await flushPromises();

      // Capture the detached element's shadow root *before* removal so we can inspect it after.
      const detachedShadow = detachedElement.shadowRoot;
      const initialHref = detachedShadow.querySelector('link[data-id="theme-stylesheet"]').getAttribute('href');

      detachedElement.remove();
      await flushPromises();

      const liveElement = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
      liveElement.code = 'y';
      liveElement.config = { showThemePicker: true };
      document.body.appendChild(liveElement);
      await flushPromises();

      const picker = liveElement.shadowRoot.querySelector('[data-id="theme-picker"]');
      picker.dispatchEvent(new CustomEvent('change', { detail: { value: 'prism-coy' } }));
      await flushPromises();

      // The detached element's stylesheet link should NOT have been mutated by the theme change.
      const detachedHrefAfter = detachedShadow.querySelector('link[data-id="theme-stylesheet"]')?.getAttribute('href');
      expect(detachedHrefAfter).toBe(initialHref);
      // And the live element's link reflects the new theme.
      expect(liveElement.shadowRoot.querySelector('link[data-id="theme-stylesheet"]').getAttribute('href')).toContain('prism-coy.min.css');
    });
  });
});
