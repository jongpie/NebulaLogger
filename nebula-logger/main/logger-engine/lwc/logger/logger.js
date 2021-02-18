//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import { LightningElement, wire } from 'lwc';
// import saveComponentLogEntries from '@salesforce/apex/ComponentLogController.saveComponentLogEntries';
export { getDefaultLogEntryOptions, error, warn, info, debug, fine, finer, finest, saveLog };
export default class ApexWireMethodWithParams extends LightningElement {
    componentLogEntries = [];
    // saveResponse;
    // saveError;

    // @wire(saveComponentLogEntries, { componentLogEntries: '$componentLogEntries' })
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

const getDefaultLogEntryOptions = () => {
    return {
        exception: null,
        recordId : null,
        record: null,
        topics: []
    };
};

const error = (message = isRequired(), logEntryOptions = getDefaultLogEntryOptions()) => {
    let logEntry = createNewComponentLogEntry('ERROR', message, logEntryOptions);
    console.error(logEntry.message);
    console.error(logEntry);
};

const warn = (message = isRequired(), logEntryOptions = getDefaultLogEntryOptions()) => {
    let logEntry = createNewComponentLogEntry('WARN', message, logEntryOptions);
    console.warn(logEntry.message);
    console.warn(logEntry);
};

const info = (message = isRequired(), logEntryOptions = getDefaultLogEntryOptions()) => {
    let logEntry = createNewComponentLogEntry('INFO', message, logEntryOptions);
    console.info(logEntry.message);
    console.info(logEntry);
};

const debug = (message = isRequired(), logEntryOptions = getDefaultLogEntryOptions()) => {
    let logEntry = createNewComponentLogEntry('DEBUG', message, logEntryOptions);
    console.debug(logEntry.message);
    console.debug(logEntry);
};

const fine = (message = isRequired(), logEntryOptions = getDefaultLogEntryOptions()) => {
    let logEntry = createNewComponentLogEntry('FINE', message, logEntryOptions);
    console.debug(logEntry.message);
    console.debug(logEntry);
};

const finer = (message = isRequired(), logEntryOptions = getDefaultLogEntryOptions()) => {
    let logEntry = createNewComponentLogEntry('FINER', message, logEntryOptions);
    console.debug(logEntry.message);
    console.debug(logEntry);
};

const finest = (message = isRequired(), logEntryOptions = getDefaultLogEntryOptions()) => {
    let logEntry = createNewComponentLogEntry('FINEST', message, logEntryOptions);
    console.debug(logEntry.message);
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

const getStack = () => {
    // TODO consider adding parsing/cleanup for stack traces (but might be best to handle within Logger.parseStackTrace())
    let err = new Error();
    //return err.stack.replace('@', '<br>');
    return err.stack;
};

const createNewComponentLogEntry = (loggingLevel, message, logEntryOptions) => {
    // TODO add checks to make sure logEntryOptions exists & has all the keys/properties

    if (typeof logEntryOptions == 'undefined') {
        logEntryOptions = getDefaultLogEntryOptions();
    }
    logEntryOptions = Object.assign(getDefaultLogEntryOptions(), logEntryOptions);

    let componentLogEntry = {
        componentError : logEntryOptions.exception, // TODO create object for JS errors & SF-specific errors
        loggingLevel: loggingLevel,
        message: message,
        recordId: logEntryOptions.recordId,
        record: logEntryOptions.record,
        stack: getStack(),
        timestamp: new Date().toISOString(),
        topics: logEntryOptions.topics
    };

    // FIXME store entries somewhere until saved
    //componentLogEntries.push(entry);

    //let formattedMessage = loggingLevel + ' Message\n\n' + message;
    // if(topics && topics.length > 0) {
    //     formattedMessage += '\nTopics: ' + topics.join(', ');
    // }
    //alert(formattedMessage);

    return componentLogEntry;
};