//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

const LogEntryBuilder = class {
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

    setMessage(message) {
        if (this.shouldSave === true) {
            this.message = message;
            this._logToConsole();
        }
        return this;
    }

    setRecordId(recordId) {
        if (this.shouldSave === true) {
            this.recordId = recordId;
        }
        return this;
    }

    setRecord(record) {
        if (this.shouldSave === true) {
            this.record = record;
        }
        return this;
    }

    setError(error) {
        if (this.shouldSave === true) {
            this.error = {};
            this.error.message = error.message;
            this.error.stack = error.stack;
            this.error.type = error.name;
        }
        return this;
    }

    addTag(tag) {
        if (this.shouldSave === true) {
            this.tags.push(tag);
            // Deduplicate the list of tags
            this.tags = Array.from(new Set(this.tags));
        }
        return this;
    }

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
                console.error(this.message);
                console.error(this);
                break;
            case 'WARN':
                console.warn(this.message);
                console.warn(this);
                break;
            case 'INFO':
                console.info(this.message);
                console.info(this);
                break;
            default:
                console.debug(this.message);
                console.debug(this);
                break;
        }
    }
};

export function newLogEntry(loggingLevel, shouldSave, isConsoleLoggingEnabled) {
    return new LogEntryBuilder(loggingLevel, shouldSave, isConsoleLoggingEnabled);
}
