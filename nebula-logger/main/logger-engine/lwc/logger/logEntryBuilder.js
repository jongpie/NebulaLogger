//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

const LogEntryBuilder = class {
    constructor(loggingLevel) {
        this.loggingLevel = loggingLevel;

        this.stack = new Error().stack;
        this.timestamp = new Date().toISOString();
        this.tags = [];
    }

    setMessage(message) {
        this.message = message;
        return this;
    }

    setRecordId(recordId) {
        this.recordId = recordId;
        return this;
    }

    setRecord(record) {
        this.record = record;
        return this;
    }

    setException(exception) {
        this.exception = exception;
        return this;
    }

    addTag(tag) {
        this.tags.push(tag);
        // Deduplicate
        this.tags = Array.from(new Set(this.tags));
        return this;
    }
};

export function newLogEntry(loggingLevel) {
    return new LogEntryBuilder(loggingLevel);
}
