//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

const LogEntryBuilder = class {
    #settingsPromise;

    /**
     * @description Constructor used to generate each JavaScript-based log entry event
     *              This class is the JavaScript-equivalent of the Apex class `LogEntryBuilder`
     * @param  {String} loggingLevel The `LoggingLevel` enum to use for the builder's instance of `LogEntryEvent__e`
     * @param  {Boolean} isConsoleLoggingEnabled Determines if `console.log()` methods are execute
     */
    constructor(loggingLevel, settingsPromise) {
        this.#settingsPromise = settingsPromise;
        this.loggingLevel = loggingLevel;
        this.stack = new Error().stack;
        this.timestamp = new Date().toISOString();
        this.tags = [];
    }

    /**
     * @description Sets the log entry event's message field
     * @param  {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
     */
    setMessage(message) {
        this.message = message;
        this._logToConsole();
        return this;
    }

    /**
     * @description Sets the log entry event's record fields
     * @param  {String} recordId The ID of the SObject record related to the entry
     * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
     */
    setRecordId(recordId) {
        this.recordId = recordId;
        return this;
    }

    /**
     * @description Sets the log entry event's record fields
     * @param  {Object} record The `SObject` record related to the entry. The JSON of the record is automatically added to the entry
     * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
     */
    setRecord(record) {
        this.record = record;
        return this;
    }

    /**
     * @description Sets the log entry event's exception fields
     * @param {Error} error The instance of a JavaScript `Error` object to use, or an Apex HTTP error to use
     * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
     */
    setError(error) {
        this.error = {};
        if (error.body) {
            this.error.message = error.body.message;
            this.error.stack = error.body.stackTrace;
            this.error.type = error.body.exceptionType;
        } else {
            this.error.message = error.message;
            this.error.stack = error.stack;
            this.error.type = 'JavaScript.' + error.name;
        }
        return this;
    }

    /**
     * @description Appends the tag to the existing list of tags
     * @param {String} tag The string to add as a tag for the current log entry
     * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
     */
    addTag(tag) {
        this.tags.push(tag);
        // Deduplicate the list of tags
        this.tags = Array.from(new Set(this.tags));
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

    /* eslint-disable no-console */
    _logToConsole() {
        this.#settingsPromise().then(setting => {
            this.isConsoleLoggingEnabled = setting.isConsoleLoggingEnabled;

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

            consoleLoggingFunction(consoleMessagePrefix, consoleFormatting, this.message);
            console.groupCollapsed(consoleMessagePrefix, consoleFormatting, 'Details for: ' + this.message);
            // The use of JSON.parse(JSON.stringify()) is intended to help ensure that the output is readable,
            // including handling proxy objects. If any cyclic objects are used, this approach could fail
            consoleLoggingFunction(JSON.parse(JSON.stringify(this)));
            console.trace();
            console.groupEnd();
        });
    }
};

export function newLogEntry(loggingLevel, settingPromise) {
    return new LogEntryBuilder(loggingLevel, settingPromise);
}
