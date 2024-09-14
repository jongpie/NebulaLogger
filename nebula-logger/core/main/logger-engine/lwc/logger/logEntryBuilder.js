//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
import FORM_FACTOR from '@salesforce/client/formFactor';
import { log as lightningLog } from 'lightning/logger';
import { LoggerStackTrace } from './loggerStackTrace';

const CURRENT_VERSION_NUMBER = 'v4.14.10';

const LOGGING_LEVEL_EMOJIS = {
  ERROR: '⛔',
  WARN: '⚠️',
  INFO: 'ℹ️',
  DEBUG: '🐞',
  FINE: '👍',
  FINER: '👌',
  FINEST: '🌟'
};

const ComponentBrowser = class {
  address = window.location.href;
  formFactor = FORM_FACTOR;
  language = window.navigator.language;
  screenResolution = window.screen.availWidth + ' x ' + window.screen.availHeight;
  userAgent = window.navigator.userAgent;
  windowResolution = window.innerWidth + ' x ' + window.innerHeight;
};

// JavaScript equivalent to the Apex class ComponentLogger.ComponentLogEntry
const ComponentLogEntry = class {
  browser = new ComponentBrowser();
  error = null;
  fieldToValue = {};
  loggingLevel = null;
  message = null;
  originStackTrace = null;
  record = null;
  recordId = null;
  scenario = null;
  tags = [];
  timestamp = new Date().toISOString();

  constructor(loggingLevel) {
    this.loggingLevel = loggingLevel;
  }
};

/* eslint-disable @lwc/lwc/no-dupe-class-members */
const LogEntryBuilder = class {
  #componentLogEntry;
  #isConsoleLoggingEnabled;
  #isLightningLoggerEnabled;

  /**
   * @description Constructor used to generate each JavaScript-based log entry event
   *              This class is the JavaScript-equivalent of the Apex class `LogEntryBuilder`
   * @param  {String} loggingLevel The `LoggingLevel` enum to use for the builder's instance of `LogEntryEvent__e`
   * @param  {Boolean} isConsoleLoggingEnabled Determines if `console.log()` methods are execute
   * @param  {Boolean} isLightningLoggerEnabled Determines if `lightning-logger` LWC is called
   */
  constructor(loggingLevel, isConsoleLoggingEnabled, isLightningLoggerEnabled) {
    this.#componentLogEntry = new ComponentLogEntry(loggingLevel);
    this.#isConsoleLoggingEnabled = isConsoleLoggingEnabled;
    this.#isLightningLoggerEnabled = isLightningLoggerEnabled;
  }

  /**
   * @description Sets the log entry event's message field
   * @param  {String} message The string to use to set the entry's message field
   * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
   */
  setMessage(message) {
    this.#componentLogEntry.message = message;
    this._logToConsole();
    this._logToLightningLogger();
    return this;
  }

  /**
   * @description Sets the log entry event's record fields
   * @param  {String} recordId The ID of the SObject record related to the entry
   * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
   */
  setRecordId(recordId) {
    this.#componentLogEntry.recordId = recordId;
    return this;
  }

  /**
   * @description Sets the log entry event's record fields
   * @param  {Object} record The `SObject` record related to the entry. The JSON of the record is automatically added to the entry
   * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
   */
  setRecord(record) {
    this.#componentLogEntry.record = record;
    return this;
  }

  /**
   * @description Sets the log entry event's scenario field
   * @param  {String} scenario The string to use to set the entry's scenario field
   * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
   */
  setScenario(scenario) {
    this.#componentLogEntry.scenario = scenario;
    return this;
  }

  /**
   * @description Sets the log entry event's exception fields
   * @param {Error} error The instance of a JavaScript `Error` object to use, or an Apex HTTP error to use
   * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
   */
  setError(error) {
    if (!error) {
      return this;
    }

    this.#componentLogEntry.error = {};
    if (error.body) {
      this.#componentLogEntry.error.message = error.body.message;
      this.#componentLogEntry.error.stackTrace = error.body.stackTrace;
      this.#componentLogEntry.error.type = error.body.exceptionType;
    } else {
      this.#componentLogEntry.error.message = error.message;
      this.#componentLogEntry.error.stackTrace = new LoggerStackTrace().parse(error);
      this.#componentLogEntry.error.type = 'JavaScript.' + error.name;
    }
    return this;
  }

  /**
   * @description Sets multiple field values on the builder's `LogEntryEvent__e` record
   * @param  {Object} fieldToValue An object containing the custom field name as a key, with the corresponding value to store.
   *                      Example: `{"SomeField__c": "some value", "AnotherField__c": "another value"}`
   * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
   */
  setField(fieldToValue) {
    if (!fieldToValue) {
      return this;
    }

    Object.keys(fieldToValue).forEach(fieldName => {
      this.#componentLogEntry.fieldToValue[fieldName] = fieldToValue[fieldName];
    });

    return this;
  }

  /**
   * @description Parses the provided error's stack trace and sets the log entry's origin & stack trace fields
   * @param {Error} error The instance of a JavaScript `Error` object with a stack trace to parse
   * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
   */
  parseStackTrace(originStackTraceError) {
    if (!originStackTraceError) {
      return this;
    }

    this.#componentLogEntry.originStackTrace = new LoggerStackTrace().parse(originStackTraceError);
    return this;
  }

  /**
   * @description Appends the tag to the existing list of tags
   * @param {String} tag The string to add as a tag for the current log entry
   * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
   */
  addTag(tag) {
    this.#componentLogEntry.tags.push(tag);
    // Deduplicate the list of tags
    this.#componentLogEntry.tags = Array.from(new Set(this.#componentLogEntry.tags));
    return this;
  }

  /**
   * @description Appends the tag to the existing list of tags
   * @param {String[]} tags The list of strings to add as tags for the current entry
   * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
   */
  addTags(tags) {
    for (let i = 0; i < tags.length; i++) {
      this.addTag(tags[i]);
    }
    return this;
  }

  /**
   * @description Returns the object used to save log entry data
   * @return {ComponentLogEntry} An instance of `ComponentLogEntry` that matches the Apex class `ComponentLogger.ComponentLogEntry`
   */
  getComponentLogEntry() {
    return this.#componentLogEntry;
  }

  /* eslint-disable no-console */
  _logToConsole() {
    if (!this.#isConsoleLoggingEnabled) {
      return;
    }

    const consoleMessagePrefix = `%c  Nebula Logger ${CURRENT_VERSION_NUMBER}  `;
    const consoleFormatting = 'background: #0c598d; color: #fff; font-size: 12px; font-weight:bold;';
    let consoleLoggingFunction;
    switch (this.#componentLogEntry.loggingLevel) {
      case 'ERROR':
        consoleLoggingFunction = console.error;
        break;
      case 'WARN':
        consoleLoggingFunction = console.warn;
        break;
      case 'INFO':
        consoleLoggingFunction = console.info;
        break;
      default:
        consoleLoggingFunction = console.debug;
        break;
    }

    const loggingLevelEmoji = LOGGING_LEVEL_EMOJIS[this.#componentLogEntry.loggingLevel];
    const qualifiedMessage = `${loggingLevelEmoji} ${this.#componentLogEntry.loggingLevel}: ${this.#componentLogEntry.message}`;
    consoleLoggingFunction(
      consoleMessagePrefix,
      consoleFormatting,
      qualifiedMessage,
      // Some JS stack traces are huuuuge, so don't print it in the browser console.
      // The stack trace will still be saved on the backend.
      // '\n' + JSON.stringify(this.#componentLogEntry, replacer, 2)
      '\n' +
        JSON.stringify(
          {
            origin: {
              component: this.#componentLogEntry.originStackTrace?.componentName,
              function: this.#componentLogEntry.originStackTrace?.functionName,
              metadataType: this.#componentLogEntry.originStackTrace?.metadataType
            },
            scenario: this.#componentLogEntry.scenario,
            timestamp: this.#componentLogEntry.timestamp
          },
          (_, value) => value ?? undefined,
          2
        )
    );
  }

  _logToLightningLogger() {
    if (this.#isLightningLoggerEnabled) {
      lightningLog(this.#componentLogEntry);
    }
  }
};

let hasInitialized = false;
export function newLogEntry(loggingLevel, isConsoleLoggingEnabled, isLightningLoggerEnabled) {
  if (!hasInitialized) {
    const consoleMessagePrefix = `%c  Nebula Logger ${CURRENT_VERSION_NUMBER}  `;
    const consoleFormatting = 'background: #0c598d; color: #fff; font-size: 12px; font-weight:bold;';
    const browserDetails = new ComponentBrowser();
    /* eslint-disable no-console */
    console.info(consoleMessagePrefix, consoleFormatting, 'ℹ️ INFO: logger component initialized\n' + JSON.stringify(browserDetails, null, 2));

    hasInitialized = true;
  }
  return new LogEntryBuilder(loggingLevel, isConsoleLoggingEnabled, isLightningLoggerEnabled);
}
