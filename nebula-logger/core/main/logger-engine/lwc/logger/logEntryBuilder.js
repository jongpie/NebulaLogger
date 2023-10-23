//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
import FORM_FACTOR from '@salesforce/client/formFactor';

// JavaScript equivalent to the Apex class ComponentLogger.ComponentLogEntry
const ComponentLogEntry = class {
    browserFormFactor = null;
    browserLanguage = null;
    browserScreenResolution = null;
    browserUrl = null;
    browserUserAgent = null;
    browserWindowResolution = null;
    error = null;
    loggingLevel = null;
    message = null;
    record = null;
    recordId = null;
    scenario = null;
    stack = new Error().stack;
    tags = [];
    timestamp = new Date().toISOString();

    constructor(loggingLevel) {
        this.loggingLevel = loggingLevel;
    }
};

/* eslint-disable @lwc/lwc/no-dupe-class-members */
const LogEntryBuilder = class {
    #componentLogEntry;
    #settingsPromise;

    /**
     * @description Constructor used to generate each JavaScript-based log entry event
     *              This class is the JavaScript-equivalent of the Apex class `LogEntryBuilder`
     * @param  {String} loggingLevel The `LoggingLevel` enum to use for the builder's instance of `LogEntryEvent__e`
     * @param  {Boolean} isConsoleLoggingEnabled Determines if `console.log()` methods are execute
     */
    constructor(loggingLevel, settingsPromise) {
        this.#componentLogEntry = new ComponentLogEntry(loggingLevel);
        this.#settingsPromise = settingsPromise;

        this._setBrowserDetails();
    }

    /**
     * @description Sets the log entry event's message field
     * @param  {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
     */
    setMessage(message) {
        this.#componentLogEntry.message = message;
        this._logToConsole();
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
     * @description Sets the log entry event's exception fields
     * @param {Error} error The instance of a JavaScript `Error` object to use, or an Apex HTTP error to use
     * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
     */
    setError(error) {
        this.#componentLogEntry.error = {};
        if (error.body) {
            this.#componentLogEntry.error.message = error.body.message;
            this.#componentLogEntry.error.stack = error.body.stackTrace;
            this.#componentLogEntry.error.type = error.body.exceptionType;
        } else {
            this.#componentLogEntry.error.message = error.message;
            this.#componentLogEntry.error.stack = error.stack;
            this.#componentLogEntry.error.type = 'JavaScript.' + error.name;
        }
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

    _setBrowserDetails() {
        this.#componentLogEntry.browserFormFactor = FORM_FACTOR;
        this.#componentLogEntry.browserLanguage = window.navigator.language;
        this.#componentLogEntry.browserScreenResolution = window.screen.availWidth + ' x ' + window.screen.availHeight;
        this.#componentLogEntry.browserUrl = window.location.href;
        this.#componentLogEntry.browserUserAgent = window.navigator.userAgent;
        this.#componentLogEntry.browserWindowResolution = window.innerWidth + ' x ' + window.innerHeight;
    }

    /* eslint-disable no-console */
    _logToConsole() {
        this.#settingsPromise().then(setting => {
            this.isConsoleLoggingEnabled = !!setting?.isConsoleLoggingEnabled;

            if (!this.isConsoleLoggingEnabled) {
                return;
            }

            const consoleMessagePrefix = '%c Nebula Logger ';
            const consoleFormatting = 'background: #0c598d; color: #fff; font-size: 12px; font-weight:bold;';
            let consoleLoggingFunction;
            switch (this.loggingLevel) {
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

            consoleLoggingFunction(consoleMessagePrefix, consoleFormatting, this.#componentLogEntry.message);
            console.groupCollapsed(consoleMessagePrefix, consoleFormatting, 'Details for: ' + this.#componentLogEntry.message);
            // The use of JSON.parse(JSON.stringify()) is intended to help ensure that the output is readable,
            // including handling proxy objects. If any cyclic objects are used, this approach could fail
            consoleLoggingFunction(JSON.parse(JSON.stringify(this)));
            // console.trace();
            console.groupEnd();
        });
    }
};

export function newLogEntry(loggingLevel, settingPromise) {
    return new LogEntryBuilder(loggingLevel, settingPromise);
}
