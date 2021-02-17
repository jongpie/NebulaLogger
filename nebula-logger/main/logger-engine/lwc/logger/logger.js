//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

// import { LightningElement, wire } from 'lwc';
// import addComponentLogEntries from '@salesforce/apex/ComponentLogController.addComponentLogEntries';
export { getLoggingLevels, getDefaultLogEntryOptions, newEntry, error, warn, info, debug, saveLog };
export default class ApexWireMethodWithParams extends LightningElement {
    componentLogEntries = [];
    // saveResponse;
    // saveError;

    // @wire(addComponentLogEntries, { componentLogEntries: '$componentLogEntries' })
    // wiredSaveResponse({ error, data }) {
    //     if (data) {
    //         this.saveResponse = data;
    //         this.saveError = undefined;
    //     } else if (error) {
    //         this.saveError = error;
    //         this.saveResponse = undefined;
    //     }
    // }

}

const getLoggingLevels = () => {
    return [
        'ERROR',
        'WARN',
        'INFO',
        'DEBUG'
    ]
}

const getDefaultLogEntryOptions = () => {
    return {
        exception: null,
        recordId : null,
        record: null,
        topics: []
    };
};

const newEntry = (loggingLevel = isRequired(), message = isRequired(), logEntryOptions = getDefaultLogEntryOptions()) => {
    switch(loggingLevel) {
        case 'ERROR':
            error(message, logEntryOptions);
            break;
        case 'WARN':
            warn(message, logEntryOptions);
            break;
        case 'INFO':
            info(message, logEntryOptions);
            break;
        case 'DEBUG':
            debug(message, logEntryOptions);
            break;
        default:
          console.log('Unknown logging level: ' + loggingLevel + ', using DEBUG');
          debug(message, logEntryOptions);
      }
}

const error = (message = isRequired(), logEntryOptions = getDefaultLogEntryOptions()) => {
    let logEntry = logNewEntry('ERROR', message, logEntryOptions);
    console.error(logEntry);
};

const warn = (message = isRequired(), logEntryOptions = getDefaultLogEntryOptions()) => {
    let logEntry = logNewEntry('WARN', message, logEntryOptions);
    console.warn(logEntry);
};

const info = (message = isRequired(), logEntryOptions = getDefaultLogEntryOptions()) => {
    let logEntry = logNewEntry('INFO', message, logEntryOptions);
    console.info(logEntry);
};

const debug = (message = isRequired(), logEntryOptions = getDefaultLogEntryOptions()) => {
    let logEntry = logNewEntry('DEBUG', message, logEntryOptions);
    console.debug(logEntry);
};

const saveLog = () => {
    // TODO add saving via Apex controller
    alert('TODO - no saving yet');
};

/////////////////////////////////
// Private functions           //
/////////////////////////////////

const isRequired = () => {
    throw new Error('Parameter is required');
};

const getStackTrace = () => {
    // TODO consider adding parsing/cleanup for stack traces
    let err = new Error();
    return err.stack;
};

const logNewEntry = (loggingLevel, message, logEntryOptions) => {
    // TODO add checks to make sure logEntryOptions exists & has all the keys/properties

    let entry = {
        exception : null, // TODO create object for JS errors & SF-specific errors
        loggingLevel: loggingLevel,
        message: message,
        recordId: null, // TODO logEntryOptions.recordId,
        record: null, // TODO logEntryOptions.record,
        stackTrace: getStackTrace(),
        timestamp: new Date().toISOString(),
        topics: [] //TODO logEntryOptions.topics
    };
    //entries.push(entry); // TODO store entries somewhere until saved

    alert(loggingLevel + ' Message\n' + message);
    return entry;
};