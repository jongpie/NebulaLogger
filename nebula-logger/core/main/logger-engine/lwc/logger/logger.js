//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import { LightningElement, api } from 'lwc';
import { createLoggerService } from './loggerService';

const CURRENT_VERSION_NUMBER = 'v4.12.0';

export default class Logger extends LightningElement {
    #loggerService = createLoggerService();

    /**
     * @description Returns **read-only** information about the current user's settings, stored in `LoggerSettings__c`
     * @param {Object} parameters Object used to provide control over how user settings are retrieved. Currently, only the property `forceReload` is used.
     * @return {Promise<ComponentLogger.ComponentLoggerSettings>} The current user's instance of the Apex class `ComponentLogger.ComponentLoggerSettings`
     */
    @api
    getUserSettings(parameters = { forceReload: false }) {
        return this.#loggerService.getUserSettings(parameters);
    }

    /**
     * @description Sets the scenario name for the current transaction - this is stored in `LogEntryEvent__e.Scenario__c`
     *              and `Log__c.Scenario__c`, and can be used to filter & group logs
     * @param  {String} scenario The name to use for the current transaction's scenario
     * @return {Promise[]} A list of promises that be resolved before all scenarios are set
     */
    @api
    setScenario(scenario) {
        return this.#loggerService.setScenario(scenario);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    error(message) {
        return this.#loggerService.error(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    warn(message) {
        return this.#loggerService.warn(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    info(message) {
        return this.#loggerService.info(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    debug(message) {
        return this.#loggerService.debug(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    fine(message) {
        return this.#loggerService.fine(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    finer(message) {
        return this.#loggerService.finer(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    finest(message) {
        return this.#loggerService.finest(message);
    }

    /**
     * @description Returns the number of entries that have been generated but not yet saved
     * @return {Integer} The buffer's current size
     */
    @api
    getBufferSize() {
        return this.#loggerService.getBufferSize();
    }

    /**
     * @description Discards any entries that have been generated but not yet saved
     * @return {Promise<void>} A promise to clear the entries
     */
    @api
    flushBuffer() {
        return this.#loggerService.flushBuffer();
    }

    /**
     * @description Saves any entries in Logger's buffer, using the specified save method for only this call
     *              All subsequent calls to saveLog() will use the transaction save method
     * @param  {String} saveMethod The enum value of Logger.SaveMethod to use for this specific save action
     */
    @api
    saveLog(saveMethodName) {
        this.#loggerService.saveLog(saveMethodName);
    }
}

/**
 * @return {LoggerService} a LoggerService instance
 */
const createLogger = function () {
    const consoleMessagePrefix = '%c Nebula Logger ';
    const consoleFormatting = 'background: #0c598d; color: #fff;';
    /* eslint-disable no-console */
    console.info(consoleMessagePrefix, consoleFormatting, 'Nebula Logger Version Number: ' + CURRENT_VERSION_NUMBER);
    return createLoggerService();
};

export { createLogger };
