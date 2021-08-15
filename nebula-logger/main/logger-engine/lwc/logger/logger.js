//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import { LightningElement, api, wire } from 'lwc';
import { newLogEntry } from './logEntryBuilder';
import getSettings from '@salesforce/apex/ComponentLogger.getSettings';
import saveComponentLogEntries from '@salesforce/apex/ComponentLogger.saveComponentLogEntries';

export default class Logger extends LightningElement {
    componentLogEntries = [];
    settings;

    @wire(getSettings)
    wiredSettings({ error, data }) {
        if (data) {
            console.log('Loaded logger settings');
            console.log(data);

            this.settings = data;
        }
    }

    @api
    error(message) {
        const loggingLevel = 'ERROR';
        if (this._meetsUserLoggingLevel(loggingLevel) == true) {
            const logEntryBuilder = this._registerNewLogEntry(loggingLevel, message);
            console.error(logEntryBuilder.message);
            console.error(logEntryBuilder);
            return logEntryBuilder;
        }
    }

    @api
    warn(message) {
        const loggingLevel = 'WARN';
        if (this._meetsUserLoggingLevel(loggingLevel) == true) {
            const logEntryBuilder = this._registerNewLogEntry(loggingLevel, message);
            console.warn(logEntryBuilder.message);
            console.warn(logEntryBuilder);
            return logEntryBuilder;
        }
    }

    @api
    info(message) {
        const loggingLevel = 'INFO';
        if (this._meetsUserLoggingLevel(loggingLevel) == true) {
            const logEntryBuilder = this._registerNewLogEntry(loggingLevel, message);
            console.info(logEntryBuilder.message);
            console.info(logEntryBuilder);
            return logEntryBuilder;
        }
    }

    @api
    debug(message) {
        const loggingLevel = 'DEBUG';
        if (this._meetsUserLoggingLevel(loggingLevel) == true) {
            const logEntryBuilder = this._registerNewLogEntry(loggingLevel, message);
            console.debug(logEntryBuilder.message);
            console.debug(logEntryBuilder);
            return logEntryBuilder;
        }
    }

    @api
    fine(message) {
        const loggingLevel = 'FINE';
        if (this._meetsUserLoggingLevel(loggingLevel) == true) {
            const logEntryBuilder = this._registerNewLogEntry(loggingLevel, message);
            console.debug(logEntryBuilder.message);
            console.debug(logEntryBuilder);
            return logEntryBuilder;
        }
    }

    @api
    finer(message) {
        const loggingLevel = 'FINER';
        if (this._meetsUserLoggingLevel(loggingLevel) == true) {
            const logEntryBuilder = this._registerNewLogEntry(loggingLevel, message);
            console.debug(logEntryBuilder.message);
            console.debug(logEntryBuilder);
            return logEntryBuilder;
        }
    }

    @api
    finest(message) {
        const loggingLevel = 'FINEST';
        if (this._meetsUserLoggingLevel(loggingLevel) == true) {
            const logEntryBuilder = this._registerNewLogEntry(loggingLevel, message);
            console.debug(logEntryBuilder.message);
            console.debug(logEntryBuilder);
            return logEntryBuilder;
        }
    }

    @api
    getBufferSize() {
        return this.componentLogEntries.length;
    }

    @api
    flushBuffer() {
        this.componentLogEntries = [];
    }

    @api
    saveLog() {
        if (this.getBufferSize() > 0) {
            saveComponentLogEntries({ componentLogEntries: this.componentLogEntries })
                .then(result => {
                    console.log('Saved ' + this.getBufferSize() + ' log entries');
                    this.flushBuffer();
                })
                .catch(error => {
                    console.error(error);
                    console.error(this.componentLogEntries);
                });
        }
    }

    // Private functions
    _meetsUserLoggingLevel(logEntryLoggingLevel) {
        let logEntryLoggingLevelOrdinal = this.settings.supportedLoggingLevels[logEntryLoggingLevel];
        return this.settings.userLoggingLevel.ordinal <= logEntryLoggingLevelOrdinal;
    }

    _registerNewLogEntry(loggingLevel, message) {
        const logEntryBuilder = newLogEntry(loggingLevel).setMessage(message);

        if (this.settings && this.settings.isEnabled == true && this._meetsUserLoggingLevel(loggingLevel) == true) {
            this.componentLogEntries.push(logEntryBuilder);
        }

        return logEntryBuilder;
    }
}
