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
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    error(message) {
        // parseStackTrace() has to be called from here (in logger.js, not loggerService.js) so that accurate stack traces
        // are generated in Chrome & Firefox when the logger LWC is embedded in a component's markup
        // TEMP
        const stackTraceSourceError = new Error();
        const builder = this.#loggerService.error(message).parseStackTrace(stackTraceSourceError);
        console.log(
            '>>> Nebula Logger testing - logger.js - overriding stack trace in logger markup embed, now using generated stack trace:\n\n' +
                stackTraceSourceError.stack
        );
        return builder;
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    warn(message) {
        // parseStackTrace() has to be called from here (in logger.js, not loggerService.js) so that accurate stack traces
        // are generated in Chrome & Firefox when the logger LWC is embedded in a component's markup
        // TEMP
        const stackTraceSourceError = new Error();
        const builder = this.#loggerService.warn(message).parseStackTrace(stackTraceSourceError);
        console.log(
            '>>> Nebula Logger testing - logger.js - overriding stack trace in logger markup embed, now using generated stack trace:\n\n' +
                stackTraceSourceError.stack
        );
        return builder;
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    info(message) {
        // parseStackTrace() has to be called from here (in logger.js, not loggerService.js) so that accurate stack traces
        // are generated in Chrome & Firefox when the logger LWC is embedded in a component's markup
        // TEMP
        const stackTraceSourceError = new Error();
        const builder = this.#loggerService.info(message).parseStackTrace(stackTraceSourceError);
        console.log(
            '>>> Nebula Logger testing - logger.js - overriding stack trace in logger markup embed, now using generated stack trace:\n\n' +
                stackTraceSourceError.stack
        );
        return builder;
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    debug(message) {
        // parseStackTrace() has to be called from here (in logger.js, not loggerService.js) so that accurate stack traces
        // are generated in Chrome & Firefox when the logger LWC is embedded in a component's markup
        // TEMP
        const stackTraceSourceError = new Error();
        const builder = this.#loggerService.debug(message).parseStackTrace(stackTraceSourceError);
        console.log(
            '>>> Nebula Logger testing - logger.js - overriding stack trace in logger markup embed, now using generated stack trace:\n\n' +
                stackTraceSourceError.stack
        );
        return builder;
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    fine(message) {
        // parseStackTrace() has to be called from here (in logger.js, not loggerService.js) so that accurate stack traces
        // are generated in Chrome & Firefox when the logger LWC is embedded in a component's markup
        // TEMP
        const stackTraceSourceError = new Error();
        const builder = this.#loggerService.fine(message).parseStackTrace(stackTraceSourceError);
        console.log(
            '>>> Nebula Logger testing - logger.js - overriding stack trace in logger markup embed, now using generated stack trace:\n\n' +
                stackTraceSourceError.stack
        );
        return builder;
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    finer(message) {
        // parseStackTrace() has to be called from here (in logger.js, not loggerService.js) so that accurate stack traces
        // are generated in Chrome & Firefox when the logger LWC is embedded in a component's markup
        // TEMP
        const stackTraceSourceError = new Error();
        const builder = this.#loggerService.finer(message).parseStackTrace(stackTraceSourceError);
        console.log(
            '>>> Nebula Logger testing - logger.js - overriding stack trace in logger markup embed, now using generated stack trace:\n\n' +
                stackTraceSourceError.stack
        );
        return builder;
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @api
    finest(message) {
        // parseStackTrace() has to be called from here (in logger.js, not loggerService.js) so that accurate stack traces
        // are generated in Chrome & Firefox when the logger LWC is embedded in a component's markup
        // TEMP
        const stackTraceSourceError = new Error();
        const builder = this.#loggerService.finest(message).parseStackTrace(stackTraceSourceError);
        console.log(
            '>>> Nebula Logger testing - logger.js - overriding stack trace in logger markup embed, now using generated stack trace:\n\n' +
                stackTraceSourceError.stack
        );
        return builder;
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
}

/**
 * @return {Promise<LoggerService>} a LoggerService instance
 */
const createLogger = createLoggerService;

export { createLogger };
