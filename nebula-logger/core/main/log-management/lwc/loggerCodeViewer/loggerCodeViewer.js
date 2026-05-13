/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement, api } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import loggerStaticResources from '@salesforce/resourceUrl/LoggerResources';
import {
  DEFAULT_THEME,
  getAvailableThemes,
  getLanguageForField,
  getRememberPreference,
  getTheme,
  setLanguageForField,
  setRememberPreference,
  setTheme,
  subscribeToTheme,
  unsubscribeFromTheme
} from 'c/loggerCodePreferences';

const AUTO_LANGUAGE_VALUE = 'auto';

const DEFAULT_LANGUAGE_OPTIONS = [
  { label: 'Auto', value: AUTO_LANGUAGE_VALUE },
  { label: 'Plain text', value: 'plaintext' },
  { label: 'JSON', value: 'json' },
  { label: 'XML', value: 'xml' },
  { label: 'HTML', value: 'html' },
  { label: 'HTTP', value: 'http' },
  { label: 'Apex', value: 'apex' },
  { label: 'JavaScript', value: 'javascript' },
  { label: 'TypeScript', value: 'typescript' },
  { label: 'SQL', value: 'sql' },
  { label: 'Markdown', value: 'markdown' },
  { label: 'CSS', value: 'css' }
];

export default class LoggerCodeViewer extends LightningElement {
  @api code;
  @api language;
  @api startingLineNumber;
  @api targetLineNumber;
  // Single config object so capability flags can evolve without growing the @api surface.
  // Recognized keys (all optional):
  //   showThemePicker:        boolean — render the theme dropdown
  //   showLanguagePicker:     boolean — render the language dropdown
  //   showRememberPreference: boolean — render the "remember my choice" toggle
  //   fieldName:              string  — unprefixed field API name; scopes the language preference
  //   availableLanguages:     [{label, value}] — overrides the default language dropdown options
  //   autoLanguage:           string  — the auto-resolved language (e.g., from a Content-Type header)
  //   defaultLanguage:        string  — final fallback when no other source resolves a language
  @api config;

  hasLoadError = false;
  isLoaded = false;
  _activeLanguage;
  _activeTheme;
  _activeThemeUrl;
  _themeSubscriber;

  connectedCallback() {
    this._activeTheme = getTheme();
    this._themeSubscriber = newTheme => this._onThemeChanged(newTheme);
    subscribeToTheme(this._themeSubscriber);
  }

  disconnectedCallback() {
    if (this._themeSubscriber) {
      unsubscribeFromTheme(this._themeSubscriber);
      this._themeSubscriber = null;
    }
  }

  get _effectiveConfig() {
    return this.config || {};
  }

  get showThemePicker() {
    return !!this._effectiveConfig.showThemePicker;
  }

  get showLanguagePicker() {
    return !!this._effectiveConfig.showLanguagePicker;
  }

  get showRememberPreference() {
    return !!this._effectiveConfig.showRememberPreference;
  }

  get hasToolbar() {
    return this.showThemePicker || this.showLanguagePicker || this.showRememberPreference;
  }

  get themeOptions() {
    return getAvailableThemes();
  }

  get currentTheme() {
    return this._activeTheme || DEFAULT_THEME;
  }

  get languageOptions() {
    return this._effectiveConfig.availableLanguages || DEFAULT_LANGUAGE_OPTIONS;
  }

  get currentLanguageSelection() {
    // The picker shows "auto" when there is no per-field saved preference.
    const fieldName = this._effectiveConfig.fieldName;
    const saved = fieldName ? getLanguageForField(fieldName) : null;
    return saved || AUTO_LANGUAGE_VALUE;
  }

  get rememberChecked() {
    return getRememberPreference();
  }

  async renderedCallback() {
    if (this.isLoaded || this.hasLoadError) {
      return;
    }

    try {
      await this._loadPrismResources();
      this._renderPrismHtml();
      Prism.highlightAll();
    } catch (error) {
      this._renderPrismHtml();
      /* eslint-disable-next-line no-console */
      console.error(error.message, error);
      this.hasLoadError = true;
    } finally {
      this.isLoaded = true;
    }
  }

  async _loadPrismResources() {
    const prismScriptUrl = loggerStaticResources + '/Prism/prism.min.js';
    const prismBaseStyleUrl = this._buildThemeUrl(this._activeTheme || DEFAULT_THEME);
    const prismCustomStyleUrl = loggerStaticResources + '/Prism/prism.nebula-logger.css';

    const resourceLoads = [
      { resourceType: 'script', resourceUrl: prismScriptUrl, promise: loadScript(this, prismScriptUrl) },
      { resourceType: 'style', resourceUrl: prismBaseStyleUrl, promise: loadStyle(this, prismBaseStyleUrl) },
      { resourceType: 'style', resourceUrl: prismCustomStyleUrl, promise: loadStyle(this, prismCustomStyleUrl) }
    ];

    const resourceLoadResults = await Promise.all(
      resourceLoads.map(async ({ resourceType, resourceUrl, promise }) => {
        try {
          await promise;
          return { status: 'fulfilled', resourceType, resourceUrl };
        } catch (reason) {
          return { status: 'rejected', resourceType, resourceUrl, reason };
        }
      })
    );

    const failedResourceLoads = resourceLoadResults.filter(result => result.status === 'rejected');
    if (failedResourceLoads.length > 0) {
      const serializedLoadFailures = failedResourceLoads.map(this._serializeLoadFailure);
      throw new Error(`Failed to load Prism resources from LoggerResources static resource\n\n${JSON.stringify(serializedLoadFailures, null, 2)}`);
    }

    this._activeThemeUrl = prismBaseStyleUrl;
  }

  _buildThemeUrl(theme) {
    return `${loggerStaticResources}/Prism/themes/${theme}.min.css`;
  }

  _renderPrismHtml() {
    /*
      A few notes on using Prism:
        1. The `line-numbers` class must be on the <pre> itself (not just on an
          ancestor) before highlightAll runs. Otherwise line-highlight's
          'complete' hook takes its non-deferred branch, runs before line-numbers
          has built the gutter, and ends up appending an unpositioned overlay.

        2. The properties data-line and data-line-offset are effectively the same thing within Prism...
          but the core Prism code uses data-start for line numbers,
          and the line-highlight plugin uses data-line-offset for highlighting a line number

          (╯°□°）╯︵ ┻━┻
     */

    const container = this.template.querySelector('.prism-viewer');
    if (!container) {
      return;
    }
    const language = this._resolveLanguage();
    this._activeLanguage = language;
    // eslint-disable-next-line
    container.innerHTML =
      `<pre class="line-numbers" data-start="${this.startingLineNumber}" data-line="${this.targetLineNumber}" data-line-offset="${this.targetLineNumber}">` +
      `<code class="language-${language}">${this.code ?? ''}</code>` +
      `</pre>`;
  }

  _resolveLanguage() {
    const cfg = this._effectiveConfig;
    if (cfg.fieldName) {
      const saved = getLanguageForField(cfg.fieldName);
      if (saved) {
        return saved;
      }
    }
    if (cfg.autoLanguage) {
      return cfg.autoLanguage;
    }
    if (this.language) {
      return this.language;
    }
    return cfg.defaultLanguage || 'plaintext';
  }

  handleLanguageChange(event) {
    const newValue = event.detail?.value;
    const fieldName = this._effectiveConfig.fieldName;

    if (newValue === AUTO_LANGUAGE_VALUE) {
      // "Auto" clears the per-field preference so resolution falls back to autoLanguage / @api language.
      if (fieldName) {
        setLanguageForField(fieldName, null);
      }
    } else if (fieldName && getRememberPreference()) {
      setLanguageForField(fieldName, newValue);
    }

    // Override resolution for this render even if we didn't persist (so the user sees their pick immediately).
    this._activeLanguage = newValue === AUTO_LANGUAGE_VALUE ? null : newValue;
    this._renderActiveLanguage(newValue);
  }

  _renderActiveLanguage(selection) {
    const container = this.template.querySelector('.prism-viewer');
    if (!container) {
      return;
    }
    const language = selection === AUTO_LANGUAGE_VALUE ? this._resolveLanguage() : selection;
    // eslint-disable-next-line
    container.innerHTML =
      `<pre class="line-numbers" data-start="${this.startingLineNumber}" data-line="${this.targetLineNumber}" data-line-offset="${this.targetLineNumber}">` +
      `<code class="language-${language}">${this.code ?? ''}</code>` +
      `</pre>`;
    if (typeof Prism !== 'undefined' && Prism.highlightAll) {
      Prism.highlightAll();
    }
  }

  handleThemeChange(event) {
    setTheme(event.detail?.value);
  }

  handleRememberChange(event) {
    setRememberPreference(!!event.detail?.checked);
  }

  async _onThemeChanged(newTheme) {
    if (!newTheme || newTheme === this._activeTheme) {
      return;
    }
    this._activeTheme = newTheme;
    const newUrl = this._buildThemeUrl(newTheme);
    try {
      await loadStyle(this, newUrl);
      this._activeThemeUrl = newUrl;
    } catch (error) {
      /* eslint-disable-next-line no-console */
      console.error(`Failed to load Prism theme: ${newUrl}`, error);
    }
  }

  _serializeLoadFailure(failure) {
    const serializedFailure = {
      status: failure.status,
      resourceType: failure.resourceType,
      resourceUrl: failure.resourceUrl
    };

    if (failure.reason instanceof Error) {
      serializedFailure.reason = {
        name: failure.reason.name,
        message: failure.reason.message,
        stack: failure.reason.stack
      };
    } else {
      serializedFailure.reason = failure.reason;
      serializedFailure.reasonAsString = String(failure.reason);
    }

    return serializedFailure;
  }
}
