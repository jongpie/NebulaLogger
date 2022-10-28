//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import { newLogEntry } from './logEntryBuilder';
import getSettings from '@salesforce/apex/ComponentLogger.getSettings';
import saveComponentLogEntries from '@salesforce/apex/ComponentLogger.saveComponentLogEntries';

const LwcLogger = class {
    componentLogEntries = [];

    static settings = undefined;

    _scenario;
    /**
     * @description Queue of promises to be logged.
     */
    #loggingPromises = [];

    /**
     * @description Returns **read-only** information about the current user's settings, stored in `LoggerSettings__c`
     * @return {Promise<ComponentLogger.ComponentLoggerSettings>} The current user's instance of the Apex class `ComponentLogger.ComponentLoggerSettings`
     */
    getUserSettings() {
        return this.loadSettingsFromServer().then(existingSettings => {
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
        this._scenario = scenario;
        return Promise.all(this.#loggingPromises).then(
            this.componentLogEntries.forEach(logEntry => {
                logEntry.scenario = this._scenario;
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
        return this.componentLogEntries.length;
    }

    /**
     * @description Discards any entries that have been generated but not yet saved
     * @return {Promise<void>} A promise to clear the entries
     */
    flushBuffer() {
        return Promise.all(this.#loggingPromises).then(() => {
            this.componentLogEntries = [];
            this.#loggingPromises = [];
        });
    }

    /**
     * @description Saves any entries in Logger's buffer, using the specified save method for only this call
     *              All subsequent calls to saveLog() will use the transaction save method
     * @param  {String} saveMethod The enum value of Logger.SaveMethod to use for this specific save action
     */
    saveLog(saveMethodName) {
        if (this.getBufferSize() > 0) {
            let resolvedSaveMethodName;
            if (!saveMethodName && LwcLogger.settings && LwcLogger.settings.defaultSaveMethodName) {
                resolvedSaveMethodName = LwcLogger.settings.defaultSaveMethodName;
            } else {
                resolvedSaveMethodName = saveMethodName;
            }

            Promise.all(this.#loggingPromises)
                .then(saveComponentLogEntries({ componentLogEntries: this.componentLogEntries, saveMethodName: resolvedSaveMethodName }))
                .then(this.flushBuffer())
                .catch(error => {
                    if (LwcLogger.settings.isConsoleLoggingEnabled === true) {
                        /* eslint-disable-next-line no-console */
                        console.error(error);
                        /* eslint-disable-next-line no-console */
                        console.error(this.componentLogEntries);
                    }
                });
        }
    }

    /**
     * @description Loads configurations for the user from the server
     * @param {Boolean} forceReload Force the configuration to be reloaded even if it was previously loaded
     * @returns {Promise<Any>} A promise with the latest current user's instance of the Apex class `ComponentLogger.ComponentLoggerSettings`
     */
    loadSettingsFromServer(forceReload) {
        // Loading only once
        return LwcLogger.settings === undefined || forceReload === true
            ? getSettings()
                  .then(settings => {
                      LwcLogger.settings = settings;
                      return settings;
                  })
                  .catch(error => {
                      /* eslint-disable-next-line no-console */
                      console.error(error);
                  })
            : new Promise(resolve => {
                  resolve(LwcLogger.settings);
              });
    }

    // Private functions
    _meetsUserLoggingLevel(logEntryLoggingLevel) {
        let logEntryLoggingLevelOrdinal = LwcLogger.settings.supportedLoggingLevels[logEntryLoggingLevel];
        return LwcLogger.settings && LwcLogger.settings.isEnabled === true && LwcLogger.settings.userLoggingLevel.ordinal <= logEntryLoggingLevelOrdinal;
    }

    _newEntry(loggingLevel, message) {
        // Builder is returned immediately but console log will be determined after loadding settings from server
        const logEntryBuilder = newLogEntry(loggingLevel, this.loadSettingsFromServer);
        logEntryBuilder.setMessage(message);
        if (this._scenario) {
            logEntryBuilder.scenario = this._scenario;
        }
        const loggingPromise = this.loadSettingsFromServer().then(() => {
            if (this._meetsUserLoggingLevel(loggingLevel) === true) {
                this.componentLogEntries.push(logEntryBuilder);
            }
        });
        this.#loggingPromises.push(loggingPromise);
        return logEntryBuilder;
    }
};

/**
 * @return {LwcLogger} a Logger instance
 */
const createLogger = function () {
    return new LwcLogger();
};

export { createLogger };
