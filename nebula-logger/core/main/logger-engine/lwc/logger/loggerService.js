//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import { newLogEntry } from './logEntryBuilder';
import getSettings from '@salesforce/apex/ComponentLogger.getSettings';
import saveComponentLogEntries from '@salesforce/apex/ComponentLogger.saveComponentLogEntries';

/* eslint-disable @lwc/lwc/no-dupe-class-members */
export const LoggerService = class {
    #componentLogEntries = [];
    #settings;
    #scenario;
    #settingsPromise = null;
    #isSettingsLoaded = false;

    constructor() {
        this.#settingsPromise = this._loadSettingsFromServer();
    }

    getUserSettings() {
        return this.#settings;
    }

    setScenario(scenario) {
        this.#scenario = scenario;
        this.#componentLogEntries.forEach(logEntry => {
            logEntry.scenario = this.#scenario;
        });
    }

    error(stack, message) {
        return this._newEntry('ERROR', message, stack);
    }

    warn(stack, message) {
        return this._newEntry('WARN', message, stack);
    }

    info(stack, message) {
        return this._newEntry('INFO', message, stack);
    }

    debug(stack, message) {
        return this._newEntry('DEBUG', message, stack);
    }

    fine(stack, message) {
        return this._newEntry('FINE', message, stack);
    }

    finer(stack, message) {
        return this._newEntry('FINER', message, stack);
    }

    finest(stack, message) {
        return this._newEntry('FINEST', message, stack);
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
        // some JIT logic here to load settings if they haven't been loaded yet
        if(!this.#isSettingsLoaded) {
            // may not be loaded if you trigger the log before the promise resolves
            // may throw an error if settings can't be loaded
            await this.#settingsPromise;
            this.#componentLogEntries = this.#componentLogEntries.filter(
                logEntry => this._meetsUserLoggingLevel(logEntry.loggingLevel)
            );
        }

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
            this.#isSettingsLoaded = true;
        } catch (error) {
            /* eslint-disable-next-line no-console */
            console.error(error);
            throw error;
        }
    }

    _meetsUserLoggingLevel(logEntryLoggingLevel) {
        // return true until settings are loaded
        if(!this.#isSettingsLoaded) {
            return true;
        }

        return this.#settings.isEnabled === true && this.#settings.userLoggingLevel.ordinal <= this.#settings?.supportedLoggingLevels[logEntryLoggingLevel];
    }

    _newEntry(loggingLevel, message, stack) {
        const logEntryBuilder = newLogEntry(loggingLevel, this.#settings?.isConsoleLoggingEnabled);
        logEntryBuilder.setMessage(message);
        logEntryBuilder.setScenario(this.#scenario);
        logEntryBuilder.setStack(stack);
        if (this._meetsUserLoggingLevel(loggingLevel)) {
            this.#componentLogEntries.push(logEntryBuilder.getComponentLogEntry());
        }
        return logEntryBuilder;
    }
};

const createLoggerService = function () {
    const service = new LoggerService();
    return service;
};

export { createLoggerService };