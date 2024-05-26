//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import { LightningElement, api } from 'lwc';
import { createLoggerService } from './loggerService';

export default class Logger extends LightningElement {
    #loggerService;

    async connectedCallback() {
        this.#loggerService = await createLoggerService();
    }

    /**
     * @description Returns **read-only** information about the current user's settings, stored in `LoggerSettings__c`
     * @return {ComponentLogger.ComponentLoggerSettings} The current user's instance of the Apex class `ComponentLogger.ComponentLoggerSettings`
     */
    @api
    getUserSettings() {
        return this.#loggerService.getUserSettings();
    }

    /**
     * @description Sets the scenario name for the current transaction - this is stored in `LogEntryEvent__e.Scenario__c`
     *              and `Log__c.Scenario__c`, and can be used to filter & group logs
     * @param  {String} scenario The name to use for the current transaction's scenario
     */
    @api
    setScenario(scenario) {
        this.#loggerService.setScenario(scenario);
    }

    /**
     * 
     * @param {String} message log message
     * @param {String} level function name to call on loggerService 
     * @returns {LogEntry}
     */
    _log(message, level) {
        const stack = new Error().stack;
        const logEntry = this.#loggerService[level](message);
        logEntry.setComponentLogEntryStack(stack);
        return logEntry;
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    error(message) {
        return this._log(message, 'error');
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    warn(message) {
        return this._log(message, 'warn');
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    info(message) {
        return this._log(message, 'info');
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    debug(message) {
        return this._log(message, 'debug');
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    fine(message) {
        return this._log(message, 'fine');
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    finer(message) {
        return this._log(message, 'finer');
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    finest(message) {
        return this._log(message, 'finest');
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
     */
    @api
    flushBuffer() {
        this.#loggerService.flushBuffer();
    }

    /**
     * @description Saves any entries in Logger's buffer, using the specified save method for only this call
     *              All subsequent calls to saveLog() will use the transaction save method
     * @param  {String} saveMethod The enum value of Logger.SaveMethod to use for this specific save action
     */
    @api
    async saveLog(saveMethodName) {
        return this.#loggerService.saveLog(saveMethodName);
    }

    /**
     * 
     * @returns {Logger}
     */
    @api
    createLogger() {
        return this;
    }
}

/**
 * @return {Promise<LoggerService>} a LoggerService instance
 */
const createLogger = createLoggerService;

export { createLogger };