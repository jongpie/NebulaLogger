//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import { newLogEntry } from './logEntryBuilder';
import getSettings from '@salesforce/apex/ComponentLogger.getSettings';
import saveComponentLogEntries from '@salesforce/apex/ComponentLogger.saveComponentLogEntries';

/* eslint-disable @lwc/lwc/no-dupe-class-members */
const LoggerService = class {
    #componentLogEntries = [];
    #settings;
    #scenario;

    getUserSettings() {
        return this.#settings;
    }

    setScenario(scenario) {
        this.#scenario = scenario;
        this.#componentLogEntries.forEach(logEntry => {
            logEntry.scenario = this.#scenario;
        });
    }

    error(message, originStackTraceError) {
        return this._newEntry('ERROR', message, originStackTraceError);
    }

    warn(message, originStackTraceError) {
        return this._newEntry('WARN', message, originStackTraceError);
    }

    info(message, originStackTraceError) {
        return this._newEntry('INFO', message, originStackTraceError);
    }

    debug(message, originStackTraceError) {
        return this._newEntry('DEBUG', message, originStackTraceError);
    }

    fine(message, originStackTraceError) {
        return this._newEntry('FINE', message, originStackTraceError);
    }

    finer(message, originStackTraceError) {
        return this._newEntry('FINER', message, originStackTraceError);
    }

    finest(message, originStackTraceError) {
        return this._newEntry('FINEST', message, originStackTraceError);
    }

    getBufferSize() {
        return this.#componentLogEntries.length;
    }

    flushBuffer() {
        this.#componentLogEntries.length = 0;
    }

    /**
     * TODO in a future release, return save results from Apex,
     * including the transaction ID so it can be used as the parent ID
     * on subsequent saveLog() calls
     */
    async saveLog(saveMethodName) {
        if (this.#componentLogEntries.length === 0) {
            return;
        }
        if (!saveMethodName && this.#settings?.defaultSaveMethodName) {
            saveMethodName = this.#settings.defaultSaveMethodName;
        }

        try {
            const logEntriesToSave = [...this.#componentLogEntries];
            // this is an attempt to only flush the buffer for log entries that we are sending to Apex
            // rather than any that could be added if the saveLog call isn't awaited properly
            this.flushBuffer();
            await saveComponentLogEntries({
                componentLogEntries: logEntriesToSave,
                saveMethodName
            });
        } catch (error) {
            if (this.#settings.isConsoleLoggingEnabled === true) {
                /* eslint-disable-next-line no-console */
                console.error(error);
                /* eslint-disable-next-line no-console */
                console.error(this.#componentLogEntries);
            }
            throw error;
        }
    }

    async _loadSettingsFromServer() {
        try {
            const settings = await getSettings();
            this.#settings = Object.freeze({
                ...settings,
                supportedLoggingLevels: Object.freeze(settings.supportedLoggingLevels),
                userLoggingLevel: Object.freeze(settings.userLoggingLevel)
            });
        } catch (error) {
            /* eslint-disable-next-line no-console */
            console.error(error);
            throw error;
        }
    }

    _meetsUserLoggingLevel(logEntryLoggingLevel) {
        return this.#settings.isEnabled === true && this.#settings.userLoggingLevel.ordinal <= this.#settings?.supportedLoggingLevels[logEntryLoggingLevel];
    }

    _newEntry(loggingLevel, message, originStackTraceError) {
        if (!originStackTraceError) {
            originStackTraceError = new Error();
        }
        const logEntryBuilder = newLogEntry(loggingLevel, this.#settings?.isConsoleLoggingEnabled);
        if (this._meetsUserLoggingLevel(loggingLevel)) {
            logEntryBuilder.parseStackTrace(originStackTraceError).setMessage(message);
            logEntryBuilder.setScenario(this.#scenario);
            this.#componentLogEntries.push(logEntryBuilder.getComponentLogEntry());
        }

        return logEntryBuilder;
    }
};

const createLoggerService = async function () {
    const service = new LoggerService();
    await service._loadSettingsFromServer();
    return service;
};

export { createLoggerService };
