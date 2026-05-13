// Pure unit tests for the loggerCodePreferences utility module — no LWC harness needed.
// jest.isolateModules() is used so each test gets a fresh module state (resetting in-memory subscribers).

describe('loggerCodePreferences', () => {
  let storage;

  beforeEach(() => {
    storage = {};
    // Replace localStorage with an in-memory shim so tests can inspect persisted values
    // without relying on jsdom's implementation.
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
    jest.resetModules();
    delete global.localStorage;
  });

  describe('storage keys', () => {
    it('exposes a stable theme storage key that does not include any namespace prefix', () => {
      const prefs = require('../loggerCodePreferences');

      expect(prefs.STORAGE_KEYS.theme).toBe('nebula-logger:theme');
    });

    it('builds per-field language storage keys from the unprefixed field API name', () => {
      const prefs = require('../loggerCodePreferences');

      expect(prefs.STORAGE_KEYS.languageFor('HttpRequestBody__c')).toBe('nebula-logger:lang:HttpRequestBody__c');
      expect(prefs.STORAGE_KEYS.languageFor('Message__c')).toBe('nebula-logger:lang:Message__c');
    });

    it('exposes a stable remember-preference storage key', () => {
      const prefs = require('../loggerCodePreferences');

      expect(prefs.STORAGE_KEYS.remember).toBe('nebula-logger:remember');
    });
  });

  describe('getAvailableThemes', () => {
    it('returns a non-empty list with the default theme first', () => {
      const prefs = require('../loggerCodePreferences');

      const themes = prefs.getAvailableThemes();

      expect(Array.isArray(themes)).toBe(true);
      expect(themes.length).toBeGreaterThan(0);
      expect(themes[0]).toEqual({ label: expect.any(String), value: prefs.DEFAULT_THEME });
    });

    it('only returns themes that have a label and value', () => {
      const prefs = require('../loggerCodePreferences');

      for (const theme of prefs.getAvailableThemes()) {
        expect(typeof theme.label).toBe('string');
        expect(typeof theme.value).toBe('string');
        expect(theme.label).toBeTruthy();
        expect(theme.value).toBeTruthy();
      }
    });
  });

  describe('getTheme / setTheme', () => {
    it('returns DEFAULT_THEME when nothing is persisted', () => {
      const prefs = require('../loggerCodePreferences');

      expect(prefs.getTheme()).toBe(prefs.DEFAULT_THEME);
    });

    it('returns the persisted theme when localStorage has a value', () => {
      storage['nebula-logger:theme'] = 'prism-okaidia';
      const prefs = require('../loggerCodePreferences');

      expect(prefs.getTheme()).toBe('prism-okaidia');
    });

    it('falls back to DEFAULT_THEME when persisted theme is not in the available list', () => {
      storage['nebula-logger:theme'] = 'not-a-real-theme';
      const prefs = require('../loggerCodePreferences');

      expect(prefs.getTheme()).toBe(prefs.DEFAULT_THEME);
    });

    it('persists the chosen theme to localStorage', () => {
      const prefs = require('../loggerCodePreferences');

      prefs.setTheme('prism-coy');

      expect(localStorage.setItem).toHaveBeenCalledWith('nebula-logger:theme', 'prism-coy');
      expect(prefs.getTheme()).toBe('prism-coy');
    });

    it('ignores attempts to set a theme that is not in the available list', () => {
      const prefs = require('../loggerCodePreferences');

      prefs.setTheme('made-up-theme');

      expect(localStorage.setItem).not.toHaveBeenCalled();
      expect(prefs.getTheme()).toBe(prefs.DEFAULT_THEME);
    });
  });

  describe('theme subscribers', () => {
    it('notifies subscribers when the theme changes', () => {
      const prefs = require('../loggerCodePreferences');
      const subscriber = jest.fn();

      prefs.subscribeToTheme(subscriber);
      prefs.setTheme('prism-twilight');

      expect(subscriber).toHaveBeenCalledTimes(1);
      expect(subscriber).toHaveBeenCalledWith('prism-twilight');
    });

    it('does not notify subscribers when the theme is unchanged', () => {
      const prefs = require('../loggerCodePreferences');
      prefs.setTheme('prism-coy');
      const subscriber = jest.fn();

      prefs.subscribeToTheme(subscriber);
      prefs.setTheme('prism-coy');

      expect(subscriber).not.toHaveBeenCalled();
    });

    it('does not notify subscribers after they unsubscribe', () => {
      const prefs = require('../loggerCodePreferences');
      const subscriber = jest.fn();

      prefs.subscribeToTheme(subscriber);
      prefs.unsubscribeFromTheme(subscriber);
      prefs.setTheme('prism-okaidia');

      expect(subscriber).not.toHaveBeenCalled();
    });

    it('continues notifying remaining subscribers if one throws', () => {
      const prefs = require('../loggerCodePreferences');
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
      const goodSubscriber = jest.fn();
      const badSubscriber = jest.fn(() => {
        throw new Error('subscriber boom');
      });

      prefs.subscribeToTheme(badSubscriber);
      prefs.subscribeToTheme(goodSubscriber);
      prefs.setTheme('prism-twilight');

      expect(badSubscriber).toHaveBeenCalled();
      expect(goodSubscriber).toHaveBeenCalledWith('prism-twilight');
      expect(consoleErrorSpy).toHaveBeenCalled();
      consoleErrorSpy.mockRestore();
    });

    it('ignores duplicate subscribe calls for the same callback', () => {
      const prefs = require('../loggerCodePreferences');
      const subscriber = jest.fn();

      prefs.subscribeToTheme(subscriber);
      prefs.subscribeToTheme(subscriber);
      prefs.setTheme('prism-coy');

      expect(subscriber).toHaveBeenCalledTimes(1);
    });
  });

  describe('per-field language', () => {
    it('returns null when no language has been saved for the field', () => {
      const prefs = require('../loggerCodePreferences');

      expect(prefs.getLanguageForField('HttpRequestBody__c')).toBeNull();
    });

    it('returns the saved language for the given field', () => {
      storage['nebula-logger:lang:HttpRequestBody__c'] = 'json';
      const prefs = require('../loggerCodePreferences');

      expect(prefs.getLanguageForField('HttpRequestBody__c')).toBe('json');
    });

    it('persists language by field API name', () => {
      const prefs = require('../loggerCodePreferences');

      prefs.setLanguageForField('HttpRequestBody__c', 'xml');

      expect(localStorage.setItem).toHaveBeenCalledWith('nebula-logger:lang:HttpRequestBody__c', 'xml');
      expect(prefs.getLanguageForField('HttpRequestBody__c')).toBe('xml');
    });

    it('keeps language preferences isolated between different field names', () => {
      const prefs = require('../loggerCodePreferences');

      prefs.setLanguageForField('HttpRequestBody__c', 'json');
      prefs.setLanguageForField('HttpResponseBody__c', 'xml');

      expect(prefs.getLanguageForField('HttpRequestBody__c')).toBe('json');
      expect(prefs.getLanguageForField('HttpResponseBody__c')).toBe('xml');
    });

    it('clears the saved language when set to null', () => {
      const prefs = require('../loggerCodePreferences');
      prefs.setLanguageForField('HttpRequestBody__c', 'json');

      prefs.setLanguageForField('HttpRequestBody__c', null);

      expect(localStorage.removeItem).toHaveBeenCalledWith('nebula-logger:lang:HttpRequestBody__c');
      expect(prefs.getLanguageForField('HttpRequestBody__c')).toBeNull();
    });

    it('ignores set/get when fieldName is missing', () => {
      const prefs = require('../loggerCodePreferences');

      expect(prefs.getLanguageForField(undefined)).toBeNull();
      expect(prefs.getLanguageForField('')).toBeNull();
      prefs.setLanguageForField(undefined, 'json');
      prefs.setLanguageForField('', 'json');

      expect(localStorage.setItem).not.toHaveBeenCalled();
    });
  });

  describe('remember preference', () => {
    it('defaults remember to true when nothing is persisted', () => {
      const prefs = require('../loggerCodePreferences');

      expect(prefs.getRememberPreference()).toBe(true);
    });

    it('returns false when persisted as "false"', () => {
      storage['nebula-logger:remember'] = 'false';
      const prefs = require('../loggerCodePreferences');

      expect(prefs.getRememberPreference()).toBe(false);
    });

    it('persists the remember preference as a string', () => {
      const prefs = require('../loggerCodePreferences');

      prefs.setRememberPreference(false);

      expect(localStorage.setItem).toHaveBeenCalledWith('nebula-logger:remember', 'false');
      expect(prefs.getRememberPreference()).toBe(false);
    });
  });

  describe('localStorage unavailable', () => {
    it('falls back to in-memory state when localStorage throws', () => {
      // Some Salesforce contexts (e.g., Lightning Out, certain experience cloud sites) restrict storage.
      Object.defineProperty(global, 'localStorage', {
        configurable: true,
        get() {
          throw new Error('storage disabled');
        }
      });
      const prefs = require('../loggerCodePreferences');

      // Theme reads/writes should not throw, and writes should still be reflected on read.
      expect(() => prefs.getTheme()).not.toThrow();
      expect(() => prefs.setTheme('prism-coy')).not.toThrow();
      expect(prefs.getTheme()).toBe('prism-coy');
    });
  });
});
