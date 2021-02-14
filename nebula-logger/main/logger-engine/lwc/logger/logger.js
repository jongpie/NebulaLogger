// videoPlayer.js
import { LightningElement, api } from 'lwc';

export default class Logger extends LightningElement {
    @api
    error(message, recordId, record, topics) {
        this.newEntry('ERROR', message, recordId, record, topics);
        console.error(message);
    }

    @api
    warn(message, recordId, record, topics) {
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
        let err = new Error();
        return err.stack;
    }

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
