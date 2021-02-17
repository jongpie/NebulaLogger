//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import { LightningElement, wire } from 'lwc';
// import saveComponentLogEntries from '@salesforce/apex/ComponentLogController.saveComponentLogEntries';
export { getLoggingLevels, getDefaultLogEntryOptions, newEntry, error, warn, info, debug, fine, finer, finest, saveLog };
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
        componentName : null,
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
    let logEntry = createNewComponentLogEntry('ERROR', message, logEntryOptions);
    console.error(logEntry);
};

const warn = (message = isRequired(), logEntryOptions = getDefaultLogEntryOptions()) => {
    let logEntry = createNewComponentLogEntry('WARN', message, logEntryOptions);
    console.warn(logEntry);
};

const info = (message = isRequired(), logEntryOptions = getDefaultLogEntryOptions()) => {
    let logEntry = createNewComponentLogEntry('INFO', message, logEntryOptions);
    console.info(logEntry);
};

const debug = (message = isRequired(), logEntryOptions = getDefaultLogEntryOptions()) => {
    let logEntry = createNewComponentLogEntry('DEBUG', message, logEntryOptions);
    console.debug(logEntry);
};

const fine = (message = isRequired(), logEntryOptions = getDefaultLogEntryOptions()) => {
    let logEntry = createNewComponentLogEntry('FINE', message, logEntryOptions);
    console.debug(logEntry);
};

const finer = (message = isRequired(), logEntryOptions = getDefaultLogEntryOptions()) => {
    let logEntry = createNewComponentLogEntry('FINER', message, logEntryOptions);
    console.debug(logEntry);
};

const finest = (message = isRequired(), logEntryOptions = getDefaultLogEntryOptions()) => {
    let logEntry = createNewComponentLogEntry('FINEST', message, logEntryOptions);
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
    // TODO consider adding parsing/cleanup for stack traces
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
        componentLogName : logEntryOptions.componentLogName,
        componentError : logEntryOptions.exception, // TODO create object for JS errors & SF-specific errors
        loggingLevel: loggingLevel,
        message: message,
        recordId: logEntryOptions.recordId,
        record: logEntryOptions.record,
        stack: getStack(),
        timestamp: new Date().toISOString(),
        topics: logEntryOptions.topics
    };
    //entries.push(entry); // TODO store entries somewhere until saved

    let formattedMessage = loggingLevel + ' Message\n\n' + message;
    // if(topics && topics.length > 0) {
    //     formattedMessage += '\nTopics: ' + topics.join(', ');
    // }
    alert(formattedMessage);

    return componentLogEntry;
};