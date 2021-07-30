//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { newLogEntry } from './logEntryBuilder';
import getSettings from '@salesforce/apex/ComponentLogController.getSettings';

export default class Logger extends LightningElement {
    _transactionId = Math.floor(Math.random() * Date.now());

    componentLogEntries = [];
    settings;
    settingsError;

    @wire(getSettings)
    wiredSettings({ error, data }) {
        if (data) {
            console.log('Loaded logger settings');
            console.log(data);

            this.settings = data;
            this.settingsError = undefined;
        } else if (error) {
            this.settings = undefined;
            this.settingsError = error;
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
        if (this.getBufferSize() == 0) {
            // No need to call Apex if there aren't any entries to save
            const noEntriesToastEvent = new ShowToastEvent({
                title: 'Saving Skipped',
                message: 'No entries logged, ignoring call to saveLog()',
                variant: 'info'
            });
            this.dispatchEvent(noEntriesToastEvent);

            return;
        }
        saveComponentLogEntries({ componentLogEntries: this.componentLogEntries })
            .then(result => {
                // TODO cleanup
                // this.message = result;
                // this.error = undefined;
                const saveEntriesToastEvent = new ShowToastEvent({
                    title: 'Success',
                    message: 'Saved ' + this.getBufferSize() + ' log entries',
                    variant: 'success'
                });
                this.dispatchEvent(saveEntriesToastEvent);
                this.flushBuffer();
            })
            .catch(error => {
                alert('error' + JSON.stringify(error));
                console.error(error);
                // TODO cleanup
                // this.message = undefined;
                // this.error = error;
            });
    }

    // Private functions
    _meetsUserLoggingLevel(logEntryLoggingLevel) {
        // console.info('entry level name is ' + logEntryLoggingLevel);
        let logEntryLoggingLevelOrdinal = this.settings.supportedLoggingLevels[logEntryLoggingLevel];
        // console.info('entry level ordinal is ' + logEntryLoggingLevelOrdinal);
        return this.settings.userLoggingLevel.ordinal <= logEntryLoggingLevelOrdinal;
    }

    _registerNewLogEntry(loggingLevel, message) {
        if (this.settings.isEnabled == false) {
            return null;
        }

        if (this._meetsUserLoggingLevel(loggingLevel) == false) {
            // console.log('this._meetsUserLoggingLevel(loggingLevel)==' + this._meetsUserLoggingLevel(loggingLevel));
            return null;
        }

        const logEntryBuilder = newLogEntry(this._transactionId, loggingLevel).setMessage(message);
        this.componentLogEntries.push(logEntryBuilder);

        return logEntryBuilder;
    }
}
