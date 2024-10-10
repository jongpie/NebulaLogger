//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import LoggerStackTrace from './loggerStackTrace';

// JavaScript equivalent to the Apex class ComponentLogger.ComponentLogEntry
class ComponentLogEntry {
  browser = null;
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

  constructor(loggingLevel, browser) {
    this.loggingLevel = loggingLevel;
    this.browser = browser;
  }
}

/* eslint-disable @lwc/lwc/no-dupe-class-members */
export default class LogEntryEventBuilder {
  #componentLogEntry;

  /**
   * @description Constructor used to generate each JavaScript-based log entry event
   *              This class is the JavaScript-equivalent of the Apex class `LogEntryBuilder`
   * @param  {String} loggingLevel The `LoggingLevel` enum to use for the builder's instance of `LogEntryEvent__e`
   * @param  {Object} browserContext An `Object` containing details about the user's browser
   */
  constructor(loggingLevel, componentBrowserContext) {
    this.#componentLogEntry = new ComponentLogEntry(loggingLevel, componentBrowserContext);
  }

  /**
   * @description Sets the log entry event's message field
   * @param  {String} message The string to use to set the entry's message field
   * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
   */
  setMessage(message) {
    this.#componentLogEntry.message = message;
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
   * @description Deprecated - use `setExceptionDetails(exception)` instead
   *              The name of this method is very similar to the logger function logger.error(),
   *              resulting in confusion when used together:
   *                `logger.error('Unexpected error').setError(someErrorObject);`
   *              The new `setExceptionDetails(exception)` function provides the exact same functionality,
   *              but aligns with the Apex builder's method name, and helps reduce the confusion with `logger.error()`
   * @param {Error} error The instance of a JavaScript `Error` object to use, or an Apex HTTP error to use
   * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
   */
  setError(error) {
    return this.setExceptionDetails(error);
  }

  /**
   * @description Sets the log entry event's exception fields
   * @param {Error} exception The instance of a JavaScript `Error` object to use, or an Apex HTTP error to use
   * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
   */
  setExceptionDetails(exception) {
    if (!exception) {
      return this;
    }

    this.#componentLogEntry.error = {};
    if (exception.body) {
      this.#componentLogEntry.error.message = exception.body.message;
      this.#componentLogEntry.error.stackTrace = exception.body.stackTrace;
      this.#componentLogEntry.error.type = exception.body.exceptionType;
    } else {
      this.#componentLogEntry.error.message = exception.message;
      this.#componentLogEntry.error.stackTrace = new LoggerStackTrace().parse(exception);
      this.#componentLogEntry.error.type = 'JavaScript.' + exception.name;
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
   * @param {Error} originStackTraceError The instance of a JavaScript `Error` object with a stack trace to parse
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
}
