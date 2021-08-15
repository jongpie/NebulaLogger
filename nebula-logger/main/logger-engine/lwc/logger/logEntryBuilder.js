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

    setError(error) {
        this.error = {};
        this.error.message = error.message;
        this.error.stack = error.stack;
        this.error.type = error.name;
        return this;
    }

    addTag(tag) {
        this.tags.push(tag);
        // Deduplicate the list of tags
        this.tags = Array.from(new Set(this.tags));
        return this;
    }

    addTags(tags) {
        for (let i = 0; i < tags.length; i++) {
            this.addTag(tags[i]);
        }
        return this;
    }
};

export function newLogEntry(loggingLevel) {
    return new LogEntryBuilder(loggingLevel);
}
