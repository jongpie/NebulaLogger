/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger/ for full license details.  *
 ************************************************************************************************/

import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const CONTENT_TYPE_TO_LANGUAGE = [
  { match: /\bapplication\/json\b/i, language: 'json' },
  { match: /\b(application|text)\/xml\b/i, language: 'xml' },
  { match: /\btext\/html\b/i, language: 'html' },
  { match: /\btext\/plain\b/i, language: 'plaintext' },
  { match: /\bapplication\/javascript\b/i, language: 'javascript' },
  { match: /\bapplication\/x-www-form-urlencoded\b/i, language: 'http' }
];

export default class LogEntryFieldViewer extends LightningElement {
  @api recordId;
  // Unprefixed field API name (e.g. 'HttpRequestBody__c'). Resolved against LogEntry__c at runtime,
  // which means this same component works in both unlocked (no namespace) and managed (Nebula__) deployments.
  @api fieldApiName;
  // Single config object, mirroring loggerCodeViewer's shape. Recognized keys (all optional):
  //   contentTypeHeadersFieldApiName: string  — sibling field whose value contains a 'Content-Type: ...' line
  //   showThemePicker:                boolean — passthrough to inner viewer
  //   showLanguagePicker:             boolean — passthrough
  //   showRememberPreference:         boolean — passthrough
  //   availableLanguages:             [{label,value}] — passthrough; overrides default language list
  //   defaultLanguage:                string  — passthrough; final fallback when nothing else resolves
  @api config;

  _record;

  get _effectiveConfig() {
    return this.config || {};
  }

  get _fieldsToFetch() {
    const fields = [];
    if (this.fieldApiName) {
      fields.push(`LogEntry__c.${this.fieldApiName}`);
    }
    const headersField = this._effectiveConfig.contentTypeHeadersFieldApiName;
    if (headersField) {
      fields.push(`LogEntry__c.${headersField}`);
    }
    return fields;
  }

  @wire(getRecord, { recordId: '$recordId', fields: '$_fieldsToFetch' })
  wiredRecord({ data }) {
    if (data) {
      this._record = data;
    }
  }

  get code() {
    return this._readField(this.fieldApiName) ?? '';
  }

  get viewerConfig() {
    const cfg = this._effectiveConfig;
    const merged = {
      fieldName: this.fieldApiName,
      showThemePicker: cfg.showThemePicker,
      showLanguagePicker: cfg.showLanguagePicker,
      showRememberPreference: cfg.showRememberPreference,
      availableLanguages: cfg.availableLanguages,
      defaultLanguage: cfg.defaultLanguage
    };
    const autoLanguage = this._detectAutoLanguage();
    if (autoLanguage) {
      merged.autoLanguage = autoLanguage;
    }
    return merged;
  }

  _readField(fieldApiName) {
    if (!fieldApiName || !this._record?.fields) {
      return null;
    }
    // Field keys in the getRecord response are *always* the local field name (without any namespace),
    // even on namespaced packages. So a single lookup works in both deployment modes.
    const entry = this._record.fields[fieldApiName];
    return entry ? entry.value : null;
  }

  _detectAutoLanguage() {
    const headersField = this._effectiveConfig.contentTypeHeadersFieldApiName;
    if (!headersField) {
      return null;
    }
    const headersValue = this._readField(headersField);
    if (!headersValue) {
      return null;
    }
    const contentTypeMatch = headersValue.match(/^[ \t]*content-type[ \t]*:[ \t]*([^\r\n]+)/im);
    if (!contentTypeMatch) {
      return null;
    }
    const contentType = contentTypeMatch[1];
    for (const { match, language } of CONTENT_TYPE_TO_LANGUAGE) {
      if (match.test(contentType)) {
        return language;
      }
    }
    return null;
  }
}
