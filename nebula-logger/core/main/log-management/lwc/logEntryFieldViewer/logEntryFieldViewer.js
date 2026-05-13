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
  @api
  get fieldApiName() {
    return this._fieldApiName;
  }
  set fieldApiName(value) {
    this._fieldApiName = value;
    this._recomputeFieldsToFetch();
  }

  @api
  get config() {
    return this._config;
  }
  set config(value) {
    this._config = value;
    this._recomputeFieldsToFetch();
  }

  _fieldApiName;
  _config;
  _record;
  _fieldsToFetch = [];

  get _effectiveConfig() {
    return this._config || {};
  }

  _recomputeFieldsToFetch() {
    const fields = [];
    if (this._fieldApiName) {
      fields.push(`LogEntry__c.${this._fieldApiName}`);
    }
    const headersField = this._effectiveConfig.contentTypeHeadersFieldApiName;
    if (headersField) {
      fields.push(`LogEntry__c.${headersField}`);
    }
    this._fieldsToFetch = fields;
  }

  @wire(getRecord, { recordId: '$recordId', fields: '$_fieldsToFetch' })
  wiredRecord({ data }) {
    if (data) {
      this._record = data;
    }
  }

  get code() {
    return this._readField(this._fieldApiName) ?? '';
  }

  get viewerConfig() {
    const cfg = this._effectiveConfig;
    const merged = {
      fieldName: this._fieldApiName,
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
    // In unlocked and most contexts, getRecord returns field keys with the local (unprefixed) name.
    // In some namespaced managed package contexts, the keys arrive prefixed (e.g., Nebula__Foo__c).
    // Try the local key first, then fall back to any key that ends with '__<fieldApiName>'.
    const fields = this._record.fields;
    if (fields[fieldApiName]) {
      return fields[fieldApiName].value ?? null;
    }
    const namespacedKey = Object.keys(fields).find(key => key === fieldApiName || key.endsWith(`__${fieldApiName}`));
    return namespacedKey ? (fields[namespacedKey].value ?? null) : null;
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
