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

    _scenario;

    @wire(getSettings)
    wiredSettings({ error, data }) {
        if (data) {
            this.settings = data;
        } else if (error) {
            /* eslint-disable-next-line no-console */
            console.error(error);
        }
    }

    @api
    error(message) {
        return this._newEntry('ERROR', message);
    }

    @api
    warn(message) {
        return this._newEntry('WARN', message);
    }

    @api
    info(message) {
        return this._newEntry('INFO', message);
    }

    @api
    debug(message) {
        return this._newEntry('DEBUG', message);
    }

    @api
    fine(message) {
        return this._newEntry('FINE', message);
    }

    @api
    finer(message) {
        return this._newEntry('FINER', message);
    }

    @api
    finest(message) {
        return this._newEntry('FINEST', message);
    }

    @api
    setScenario(scenario) {
        this._scenario = scenario;
        this.componentLogEntries.forEach(logEntry => {
            logEntry.scenario = this._scenario;
        });
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
                .then(this.flushBuffer())
                .catch(error => {
                    if (this.settings.isConsoleLoggingEnabled === true) {
                        /* eslint-disable-next-line no-console */
                        console.error(error);
                        /* eslint-disable-next-line no-console */
                        console.error(this.componentLogEntries);
                    }
                });
        }
    }

    // Private functions
    _meetsUserLoggingLevel(logEntryLoggingLevel) {
        let logEntryLoggingLevelOrdinal = this.settings.supportedLoggingLevels[logEntryLoggingLevel];
        return this.settings && this.settings.isEnabled === true && this.settings.userLoggingLevel.ordinal <= logEntryLoggingLevelOrdinal;
    }

    _newEntry(loggingLevel, message) {
        const shouldSave = this._meetsUserLoggingLevel(loggingLevel);
        const logEntryBuilder = newLogEntry(loggingLevel, shouldSave, this.settings.isConsoleLoggingEnabled).setMessage(message);
        if (this._scenario) {
            logEntryBuilder.scenario = this._scenario;
        }
        if (this._meetsUserLoggingLevel(loggingLevel) === true) {
            this.componentLogEntries.push(logEntryBuilder);
        }

        return logEntryBuilder;
    }
}
