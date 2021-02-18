//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSettings from '@salesforce/apex/ComponentLogController.getSettings';
import saveComponentLogEntries from '@salesforce/apex/ComponentLogController.saveComponentLogEntries';

export default class Logger extends LightningElement {
    componentLogEntries = [];
    settings;
    settingsError;

    @wire(getSettings)
    wiredSettings({ error, data }) {
        if (data) {
            console.log('loading settings');
            console.log(data);

            this.settings = data;
            this.settingsError = undefined;
        } else if (error) {
            this.settings = undefined;
            this.settingsError = error;
        }
    }

    @api
    getDefaultLogEntryOptions() {
        return {
            exception: null,
            recordId : null,
            record: null,
            topics: []
        };
    }

    @api
    error(message, logEntryOptions) {
        console.log('running error(message, logEntryOptions)');

        let logEntry = this.createNewComponentLogEntry('ERROR', message, logEntryOptions);
        if(logEntry) {
            console.error(logEntry.message);
            console.error(logEntry);
        }
    };

    @api
    warn(message, logEntryOptions) {
        let logEntry = this.createNewComponentLogEntry('WARN', message, logEntryOptions);
        if(logEntry) {
            console.warn(logEntry.message);
            console.warn(logEntry);
        }
    };

    @api
    info(message, logEntryOptions) {
        let logEntry = this.createNewComponentLogEntry('INFO', message, logEntryOptions);
        if(logEntry) {
            console.info(logEntry.message);
            console.info(logEntry);
        }
    };

    @api
    debug(message, logEntryOptions) {
        let logEntry = this.createNewComponentLogEntry('DEBUG', message, logEntryOptions);
        if(logEntry) {
            console.debug(logEntry.message);
            console.debug(logEntry);
        }
    };

    @api
    fine(message, logEntryOptions) {
        let logEntry = this.createNewComponentLogEntry('FINE', message, logEntryOptions);
        if(logEntry) {
            console.debug(logEntry.message);
            console.debug(logEntry);
        }
    };

    @api
    finer(message, logEntryOptions) {
        let logEntry = this.createNewComponentLogEntry('FINER', message, logEntryOptions);
        if(logEntry) {
            console.debug(logEntry.message);
            console.debug(logEntry);
        }
    };

    @api
    finest(message, logEntryOptions) {
        let logEntry = this.createNewComponentLogEntry('FINEST', message, logEntryOptions);
        if(logEntry) {
            console.debug(logEntry.message);
            console.debug(logEntry);
        }
    };

    @api
    saveLog() {
        saveComponentLogEntries({ componentLogEntries: this.componentLogEntries })
            .then((result) => {
                // TODO cleanup
                // this.message = result;
                // this.error = undefined;
                const evt = new ShowToastEvent({
                    title: 'Success',
                    message: 'Saved ' + this.componentLogEntries.length + ' log entries',
                    variant: 'success',
                });
                this.dispatchEvent(evt);
                this.componentLogEntries = [];
            })
            .catch((error) => {
                alert('error' + JSON.stringify(error));
                console.error(error);
                // TODO cleanup
                // this.message = undefined;
                // this.error = error;
            });
    };

    // Private functions
    meetsUserLoggingLevel(logEntryLoggingLevel) {
        //FIXME logEntryLoggingLevel is a string, not an object, so there's currently not an ordinal
        return this.settings.userLoggingLevel.ordinal <= logEntryLoggingLevel.ordinal;
    }

    createNewComponentLogEntry(loggingLevel, message, logEntryOptions) {
        if(this.settings.isEnabled == false) {
            return null;
        }

        if (typeof logEntryOptions == 'undefined') {
            logEntryOptions = this.getDefaultLogEntryOptions();
        }
        logEntryOptions = Object.assign(this.getDefaultLogEntryOptions(), logEntryOptions);

        let componentLogEntry = {
            //componentError : logEntryOptions.exception, // TODO create object for JS errors & SF-specific errors
            loggingLevel: loggingLevel,
            message: message,
            // recordId: logEntryOptions.recordId,
            // record: logEntryOptions.record,
            stack: new Error().stack,
            timestamp: new Date().toISOString(),
            topics: [] //logEntryOptions.topics
        };

        this.componentLogEntries.push(componentLogEntry);
        return componentLogEntry;
    }

}