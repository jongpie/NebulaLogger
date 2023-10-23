//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import { newLogEntry } from './logEntryBuilder';
import getSettings from '@salesforce/apex/ComponentLogger.getSettings';
import saveComponentLogEntries from '@salesforce/apex/ComponentLogger.saveComponentLogEntries';

const LOADING_ENUM = {
    loading: 'loading',
    enabled: 'enabled',
    disabled: 'disabled'
};

/* eslint-disable @lwc/lwc/no-dupe-class-members */
const LoggerService = class {
    static settings = undefined;

    #isSavingLog = false;
    #componentLogEntries = [];
    #scenario;
    #loggingPromises = [];

    /**
     * @description Returns **read-only** information about the current user's settings, stored in `LoggerSettings__c`
     * @param {Object} parameters Object used to provide control over how user settings are retrieved. Currently, only the property `forceReload` is used.
     * @return {Promise<ComponentLogger.ComponentLoggerSettings>} The current user's instance of the Apex class `ComponentLogger.ComponentLoggerSettings`
     */
    getUserSettings({ forceReload = false } = {}) {
        return this._loadSettingsFromServer(forceReload).then(existingSettings => {
            return Object.freeze({
                ...existingSettings,
                supportedLoggingLevels: Object.freeze(existingSettings.supportedLoggingLevels),
                userLoggingLevel: Object.freeze(existingSettings.userLoggingLevel)
            });
        });
    }

    /**
     * @description Sets the scenario name for the current transaction - this is stored in `LogEntryEvent__e.Scenario__c`
     *              and `Log__c.Scenario__c`, and can be used to filter & group logs
     * @param  {String} scenario The name to use for the current transaction's scenario
     * @return {Promise[]} A list of promises that be resolved before all scenarios are set
     */
    setScenario(scenario) {
        this.#scenario = scenario;
        return Promise.all(this.#loggingPromises).then(
            this.#componentLogEntries.forEach(logEntry => {
                logEntry.scenario = this.#scenario;
            })
        );
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
        return this.#componentLogEntries.length + this.#loggingPromises.length;
    }

    /**
     * @description Discards any entries that have been generated but not yet saved
     * @return {Promise<void>} A promise to clear the entries
     */
    async flushBuffer() {
        return Promise.all(this.#loggingPromises).then(() => {
            this.#componentLogEntries = [];
            this.#loggingPromises = [];
            this.#isSavingLog = false;
        });
    }

    /**
     * @description Saves any entries in Logger's buffer, using the specified save method for only this call
     *              All subsequent calls to saveLog() will use the transaction save method
     * @param  {String} saveMethod The enum value of LoggerService.SaveMethod to use for this specific save action
     */
    async saveLog(saveMethodName) {
        this.#isSavingLog = true;

        const filteredLogEntries = this.#componentLogEntries.filter(
            possibleLogEntry =>
                (possibleLogEntry.loadingEnum === LOADING_ENUM.loading &&
                    this._meetsUserLoggingLevel(possibleLogEntry.loggingLevel) === LOADING_ENUM.enabled) ||
                possibleLogEntry.loadingEnum === LOADING_ENUM.enabled
        );

        if (filteredLogEntries.length > 0) {
            let resolvedSaveMethodName;
            if (!saveMethodName && LoggerService.settings && LoggerService.settings.defaultSaveMethodName) {
                resolvedSaveMethodName = LoggerService.settings.defaultSaveMethodName;
            } else {
                resolvedSaveMethodName = saveMethodName;
            }

            return Promise.all(this.#loggingPromises)
                .then(
                    saveComponentLogEntries({
                        componentLogEntries: filteredLogEntries,
                        saveMethodName: resolvedSaveMethodName
                    })
                )
                .then(this.flushBuffer())
                .catch(error => {
                    if (LoggerService.settings.isConsoleLoggingEnabled === true) {
                        /* eslint-disable-next-line no-console */
                        console.error(error);
                        /* eslint-disable-next-line no-console */
                        console.error(this.#componentLogEntries);
                    }
                });
        }
        return Promise.resolve();
    }

    _loadSettingsFromServer(forceReload) {
        // Loading only once
        return LoggerService.settings === undefined || forceReload === true
            ? getSettings()
                  .then(settings => {
                      LoggerService.settings = settings;
                      return settings;
                  })
                  .catch(error => {
                      /* eslint-disable-next-line no-console */
                      console.error(error);
                  })
            : new Promise(resolve => {
                  resolve(LoggerService.settings);
              });
    }

    _meetsUserLoggingLevel(logEntryLoggingLevel) {
        if (LoggerService.settings && LoggerService.settings.supportedLoggingLevels && LoggerService.settings.userLoggingLevel) {
            const currentIsEnabled =
                LoggerService.settings.isEnabled === true &&
                LoggerService.settings.userLoggingLevel.ordinal <= LoggerService.settings?.supportedLoggingLevels[logEntryLoggingLevel];
            return currentIsEnabled ? LOADING_ENUM.enabled : LOADING_ENUM.disabled;
        }
        return LOADING_ENUM.loading;
    }

    _newEntry(loggingLevel, message) {
        // Builder is returned immediately but console log will be determined after loading settings from server
        const logEntryBuilder = newLogEntry(loggingLevel, this._loadSettingsFromServer);
        logEntryBuilder.setMessage(message);
        if (this.#scenario) {
            logEntryBuilder.scenario = this.#scenario;
        }
        const loggingPromise = this._loadSettingsFromServer().then(() => {
            const isEnabledEnum = this._meetsUserLoggingLevel(loggingLevel);
            if (isEnabledEnum === LOADING_ENUM.enabled || isEnabledEnum === LOADING_ENUM.loading) {
                const componentLogEntry = logEntryBuilder.getComponentLogEntry();
                componentLogEntry.loadingEnum = isEnabledEnum;
                this.#componentLogEntries.push(componentLogEntry);
            }
            if (this.#isSavingLog) {
                this.#isSavingLog = false;
                this.saveLog();
            }
        });
        this.#loggingPromises.push(loggingPromise);

        return logEntryBuilder;
    }
};

/**
 * @return {LoggerService} a LoggerService instance
 */
const createLoggerService = function () {
    return new LoggerService();
};

export { createLoggerService };
