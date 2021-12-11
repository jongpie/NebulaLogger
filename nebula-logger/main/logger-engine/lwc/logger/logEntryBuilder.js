//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

const LogEntryBuilder = class {
    /**
     * @description Constructor used to generate each JavaScript-based log entry event
     *              This class is the JavaScript-equivalent of the Apex class `LogEntryEventBuilder`
     * @param  {} loggingLevel The `LoggingLevel` enum to use for the builder's instance of `LogEntryEvent__e`
     * @param  {} shouldSave Determines if the builder's instance of `LogEntryEvent__e` should be saved
     * @param  {} isConsoleLoggingEnabled Determines if `console.log()` methods are execute
     */
    constructor(loggingLevel, shouldSave, isConsoleLoggingEnabled) {
        this.shouldSave = shouldSave;
        this.isConsoleLoggingEnabled = isConsoleLoggingEnabled;
        if (this.shouldSave === true) {
            this.loggingLevel = loggingLevel;
            this.stack = new Error().stack;
            this.timestamp = new Date().toISOString();
            this.tags = [];
        }
    }

    /**
     * @description Sets the log entry event's message field
     * @param  {} message The string to use to set the entry's message field
     * @return The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    setMessage(message) {
        if (this.shouldSave === true) {
            this.message = message;
            this._logToConsole();
        }
        return this;
    }

    /**
     * @description Sets the log entry event's record fields
     * @param  {} recordId The ID of the SObject record related to the entry
     * @return The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    setRecordId(recordId) {
        if (this.shouldSave === true) {
            this.recordId = recordId;
        }
        return this;
    }

    /**
     * @description Sets the log entry event's record fields
     * @param  {} record The `SObject` record related to the entry. The JSON of the record is automatically added to the entry
     * @return The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    setRecord(record) {
        if (this.shouldSave === true) {
            this.record = record;
        }
        return this;
    }

    /**
     * @description Sets the log entry event's exception fields
     * @param  apexException The instance of an `Exception` to use.
     * @return               The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    setError(error) {
        if (this.shouldSave === true) {
            this.error = {};
            this.error.message = error.message;
            this.error.stack = error.stack;
            this.error.type = error.name;
        }
        return this;
    }

    /**
     * @description Appends the tag to the existing list of tags
     * @param tag The string to use as a tag for the current entry
     * @return The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    addTag(tag) {
        if (this.shouldSave === true) {
            this.tags.push(tag);
            // Deduplicate the list of tags
            this.tags = Array.from(new Set(this.tags));
        }
        return this;
    }

    /**
     * @description Appends the tag to the existing list of tags
     * @param tags The list of strings to use as tags for the current entry
     * @return The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    addTags(tags) {
        for (let i = 0; i < tags.length; i++) {
            this.addTag(tags[i]);
        }
        return this;
    }

    _logToConsole() {
        if (!this.isConsoleLoggingEnabled) {
            return;
        }

        /* eslint-disable no-console */
        switch (this.loggingLevel) {
            case 'ERROR':
                console.error(this.message, this);
                break;
            case 'WARN':
                console.warn(this.message, this);
                break;
            case 'INFO':
                console.info(this.message, this);
                break;
            default:
                console.debug(this.message, this);
                break;
        }
    }
};

export function newLogEntry(loggingLevel, shouldSave, isConsoleLoggingEnabled) {
    return new LogEntryBuilder(loggingLevel, shouldSave, isConsoleLoggingEnabled);
}
