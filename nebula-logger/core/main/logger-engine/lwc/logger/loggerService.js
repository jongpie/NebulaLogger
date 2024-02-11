//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import { newLogEntry } from './logEntryBuilder';
import getSettings from '@salesforce/apex/ComponentLogger.getSettings';
import saveComponentLogEntries from '@salesforce/apex/ComponentLogger.saveComponentLogEntries';

/* eslint-disable @lwc/lwc/no-dupe-class-members */
const LoggerService = class {
    static currentVersionNumber;

    #componentLogEntries = [];
    #settings;
    #scenario;

    constructor(currentVersionNumber) {
        LoggerService.currentVersionNumber = currentVersionNumber;
    }

    async initializeUserSettings({ forceReload = false } = {}) {
        return this._loadSettingsFromServer(forceReload);
    }

    /**
     * @description Returns **read-only** information about the current user's settings, stored in `LoggerSettings__c`
     * @param {Object} parameters Object used to provide control over how user settings are retrieved. Currently, only the property `forceReload` is used.
     * @return {Promise<ComponentLogger.ComponentLoggerSettings>} The current user's instance of the Apex class `ComponentLogger.ComponentLoggerSettings`
     */
    getUserSettings() {
        return this.#settings;
    }

    /**
     * @description Sets the scenario name for the current transaction - this is stored in `LogEntryEvent__e.Scenario__c`
     *              and `Log__c.Scenario__c`, and can be used to filter & group logs
     * @param  {String} scenario The name to use for the current transaction's scenario
     * @return {Promise[]} A list of promises that be resolved before all scenarios are set
     */
    setScenario(scenario) {
        this.#scenario = scenario;
        this.#componentLogEntries.forEach(logEntry => {
            logEntry.scenario = this.#scenario;
        });
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    error(message) {
        return this._newEntry('ERROR', message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    warn(message) {
        return this._newEntry('WARN', message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    info(message) {
        return this._newEntry('INFO', message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    debug(message) {
        return this._newEntry('DEBUG', message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    fine(message) {
        return this._newEntry('FINE', message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    finer(message) {
        return this._newEntry('FINER', message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    finest(message) {
        return this._newEntry('FINEST', message);
    }

    /**
     * @description Returns the number of entries that have been generated but not yet saved
     * @return {Integer} The buffer's current size
     */
    getBufferSize() {
        return this.#componentLogEntries.length;
    }

    /**
     * @description Discards any entries that have been generated but not yet saved
     * @return {Promise<void>} A promise to clear the entries
     */
    flushBuffer() {
        this.#componentLogEntries.length = 0;
    }

    /**
     * @description Saves any entries in Logger's buffer, using the specified save method for only this call
     *              All subsequent calls to saveLog() will use the transaction save method
     * @param  {String} saveMethod The enum value of LoggerService.SaveMethod to use for this specific save action
     */
    async saveLog(saveMethodName) {
        if (this.#componentLogEntries.length === 0) {
            return Promise.resolve();
        }
        let resolvedSaveMethodName;
        if (!saveMethodName && this.#settings && this.#settings.defaultSaveMethodName) {
            resolvedSaveMethodName = this.#settings.defaultSaveMethodName;
        } else {
            resolvedSaveMethodName = saveMethodName;
        }

        return saveComponentLogEntries({
            componentLogEntries: this.#componentLogEntries,
            saveMethodName: resolvedSaveMethodName
        })
            .then(() => {
                this.flushBuffer();
                // TODO in a future release, return save results from Apex,
                // including the transaction ID so it can be used as the parent ID
                // on subsequent saveLog() calls
                return Promise.resolve();
            })
            .catch(error => {
                if (this.#settings.isConsoleLoggingEnabled === true) {
                    /* eslint-disable-next-line no-console */
                    console.error(error);
                    /* eslint-disable-next-line no-console */
                    console.error(this.#componentLogEntries);
                }
                return Promise.reject(error);
            });
    }

    async _loadSettingsFromServer(forceReload) {
        // Loading only once
        if (this.#settings !== undefined && forceReload !== true) {
            return Promise.resolve(this.#settings);
        }

        return getSettings()
            .then(settings => {
                this.#settings = Object.freeze({
                    ...settings,
                    supportedLoggingLevels: Object.freeze(settings.supportedLoggingLevels),
                    userLoggingLevel: Object.freeze(settings.userLoggingLevel)
                });
                return settings;
            })
            .catch(error => {
                /* eslint-disable-next-line no-console */
                console.error(error);
                return Promise.reject(error);
            });
    }

    _meetsUserLoggingLevel(logEntryLoggingLevel) {
        return this.#settings.isEnabled === true && this.#settings.userLoggingLevel.ordinal <= this.#settings?.supportedLoggingLevels[logEntryLoggingLevel];
    }

    _newEntry(loggingLevel, message) {
        // Builder is returned immediately but console log will be determined after loading settings from server
        const logEntryBuilder = newLogEntry(loggingLevel, this.#settings?.isConsoleLoggingEnabled, LoggerService.currentVersionNumber);
        logEntryBuilder.setMessage(message);
        if (this.#scenario) {
            logEntryBuilder.scenario = this.#scenario;
        }
        if (this._meetsUserLoggingLevel(loggingLevel)) {
            this.#componentLogEntries.push(logEntryBuilder.getComponentLogEntry());
        }

        return logEntryBuilder;
    }
};

/**
 * @return {LoggerService} a LoggerService instance
 */
const createLoggerService = async function (currentVersionNumber) {
    const service = new LoggerService(currentVersionNumber);
    const loggerPromise = new Promise((resolve, reject) => {
        return service
            .initializeUserSettings()
            .then(() => resolve(service))
            .catch(reject);
    });
    return loggerPromise;
};

export { createLoggerService };
