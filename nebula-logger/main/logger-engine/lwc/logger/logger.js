// videoPlayer.js
import { LightningElement, api } from 'lwc';

const isRequired = () => {
    throw new Error('Parameter is required');
};

export default class Logger extends LightningElement {
    @api
    error(message = isRequired(), logEntryOptions = { exception: null, recordId: null, record: null, topics: [] }) {
        this.logNewEntry('ERROR', message, logEntryOptions);
        //this.newEntry('ERROR', message, recordId, record, topics);
        console.error(message);
    }

    @api
    warn(message = isRequired(), recordId, record, topics) {
        this.newEntry('WARN', message, recordId, record, topics);
        console.warn(message);
    }

    @api
    info(message, recordId, record, topics) {
        this.newEntry('INFO', message, recordId, record, topics);
        console.info(message);
    }

    @api
    debug(message, recordId, record, topics) {
        this.newEntry('DEBUG', message, recordId, record, topics);
        console.debug(message);
    }

    // TODO consider adding fine, finer and finest, even though JS doesn't really have them
    // @api
    // fine(message, recordId, record, topics) {
    //     this.newEntry('FINE', message, recordId, record, topics);
    //     console.debug(message);
    // }

    @api
    saveLog() {
        alert('TODO');
    }

    //@track
    entries = [];

    // private methods
    get loggerSettings() {
        return 'TODO';
    }

    get stackTrace() {
        // TODO consider adding parsing/cleanup for stack traces
        let err = new Error();
        return err.stack;
    }

    logNewEntry(loggingLevel, message, logEntryOptions) {
        // TODO add checks to make sure logEntryOptions exists & has all the keys/properties


        let stackTrace = stackTrace();

        let entry = {
            exception : null, // TODO create object for JS errors & SF-specific errors
            loggingLevel: loggingLevel,
            message: message,
            recordId: logEntryOptions.recordId,
            record: logEntryOptions.record,
            stackTrace: stackTrace,
            timestamp: new Date().toISOString(),
            topics: logEntryOptions.topics
        };
        this.entries.push(entry);

        return entry;
    }

    // TODO delete?
    newEntry(loggingLevel, message, recordId, record, topics) {
        let entry = {
            loggingLevel: loggingLevel,
            message: message,
            recordId: recordId,
            record: record,
            stackTrace: stackTrace(),
            timestamp: new Date().toISOString(),
            topics: topics
        };
        this.entries.push(entry);

        return entry;
    }
}
