//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
import FORM_FACTOR from '@salesforce/client/formFactor';
import { ErrorStackParser } from './stackTrace';

const CURRENT_VERSION_NUMBER = 'v4.13.16';

const LOGGING_LEVEL_EMOJIS = {
    ERROR: '⛔',
    WARN: '⚠️',
    INFO: 'ℹ️',
    DEBUG: '🐞',
    FINE: '👍',
    FINER: '👌',
    FINEST: '🌟'
};

const ComponentBrowser = class {
    address = null;
    formFactor = null;
    language = null;
    screenResolution = null;
    userAgent = null;
    windowResolution = null;

    constructor() {
        this.address = window.location.href;
        this.formFactor = FORM_FACTOR;
        this.language = window.navigator.language;
        this.screenResolution = window.screen.availWidth + ' x ' + window.screen.availHeight;
        this.userAgent = window.navigator.userAgent;
        this.windowResolution = window.innerWidth + ' x ' + window.innerHeight;
    }
};

// JavaScript equivalent to the Apex class ComponentLogger.ComponentLogEntry
const ComponentLogEntry = class {
    browserAddress = null;
    browserFormFactor = null;
    browserLanguage = null;
    browserScreenResolution = null;
    // TODO Deprecated, remove in a future release
    browserUrl = null;
    browserUserAgent = null;
    browserWindowResolution = null;
    error = null;
    loggingLevel = null;
    message = null;
    origin = null;
    record = null;
    recordId = null;
    scenario = null;
    stack = null;
    tags = [];
    timestamp = new Date().toISOString();

    constructor(loggingLevel) {
        this.loggingLevel = loggingLevel;
    }
};

/* eslint-disable @lwc/lwc/no-dupe-class-members */
const LogEntryBuilder = class {
    #componentLogEntry;
    #isConsoleLoggingEnabled;

    /**
     * @description Constructor used to generate each JavaScript-based log entry event
     *              This class is the JavaScript-equivalent of the Apex class `LogEntryBuilder`
     * @param  {String} loggingLevel The `LoggingLevel` enum to use for the builder's instance of `LogEntryEvent__e`
     * @param  {Boolean} isConsoleLoggingEnabled Determines if `console.log()` methods are execute
     */
    constructor(loggingLevel, isConsoleLoggingEnabled) {
        this.#componentLogEntry = new ComponentLogEntry(loggingLevel);
        this.#isConsoleLoggingEnabled = isConsoleLoggingEnabled;

        this._setBrowserDetails();
    }

    /**
     * @description Sets the log entry event's message field
     * @param  {String} message The string to use to set the entry's message field
     * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
     */
    setMessage(message) {
        this.#componentLogEntry.message = message;
        this._logToConsole();
        return this;
    }

    /**
     * @description Sets the log entry event's record fields
     * @param  {String} recordId The ID of the SObject record related to the entry
     * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
     */
    setRecordId(recordId) {
        this.#componentLogEntry.recordId = recordId;
        return this;
    }

    /**
     * @description Sets the log entry event's record fields
     * @param  {Object} record The `SObject` record related to the entry. The JSON of the record is automatically added to the entry
     * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
     */
    setRecord(record) {
        this.#componentLogEntry.record = record;
        return this;
    }

    /**
     * @description Sets the log entry event's scenario field
     * @param  {String} scenario The string to use to set the entry's scenario field
     * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
     */
    setScenario(scenario) {
        this.#componentLogEntry.scenario = scenario;
        return this;
    }

    /**
     * @description Sets the log entry event's exception fields
     * @param {Error} error The instance of a JavaScript `Error` object to use, or an Apex HTTP error to use
     * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
     */
    setError(error) {
        if (!error) {
            return this;
        }

        this.#componentLogEntry.error = {};
        if (error.body) {
            this.#componentLogEntry.error.message = error.body.message;
            this.#componentLogEntry.error.stack = error.body.stackTrace;
            this.#componentLogEntry.error.type = error.body.exceptionType;
        } else {
            this.#componentLogEntry.error.message = error.message;
            this.#componentLogEntry.error.stack = error.stack;
            this.#componentLogEntry.error.type = 'JavaScript.' + error.name;
        }
        return this;
    }

    /**
     * @description Appends the tag to the existing list of tags
     * @param {Error} error The instance of a JavaScript `Error` object with a stack trace to parse
     * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
     */
    parseStackTrace(originStackTraceError) {
        if (!originStackTraceError) {
            return this;
        }

        const originStackTraceParticles = new ErrorStackParser().parse(originStackTraceError);
        let originStackTraceParticle;
        const parsedStackTraceLines = [];
        originStackTraceParticles.forEach(particle => {
            if (particle.fileName?.endsWith('/logger.js')) {
                return;
            }

            if (!originStackTraceParticle && particle.fileName?.endsWith('aura_proddebug.js')) {
                return;
            }

            this._cleanStackTraceParticle(particle);

            if (!originStackTraceParticle) {
                originStackTraceParticle = { ...{ componentName: undefined }, ...particle };
            }

            if (particle.source) {
                parsedStackTraceLines.push(particle.source?.trim());
            }
        });
        const parsedStackTraceString = parsedStackTraceLines.join('\n');
        this.#componentLogEntry.origin = { ...originStackTraceParticle, parsedStackTraceString };

        this.#componentLogEntry.stack = originStackTraceError?.stack;
        return this;
    }

    /**
     * @description Appends the tag to the existing list of tags
     * @param {String} tag The string to add as a tag for the current log entry
     * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
     */
    addTag(tag) {
        this.#componentLogEntry.tags.push(tag);
        // Deduplicate the list of tags
        this.#componentLogEntry.tags = Array.from(new Set(this.#componentLogEntry.tags));
        return this;
    }

    /**
     * @description Appends the tag to the existing list of tags
     * @param {String[]} tags The list of strings to add as tags for the current entry
     * @return {LogEntryBuilder} The same instance of `LogEntryBuilder`, useful for chaining methods
     */
    addTags(tags) {
        for (let i = 0; i < tags.length; i++) {
            this.addTag(tags[i]);
        }
        return this;
    }

    /**
     * @description Returns the object used to save log entry data
     * @return {ComponentLogEntry} An instance of `ComponentLogEntry` that matches the Apex class `ComponentLogger.ComponentLogEntry`
     */
    getComponentLogEntry() {
        return this.#componentLogEntry;
    }

    _setBrowserDetails() {
        const browser = new ComponentBrowser();
        this.#componentLogEntry.browserAddress = browser.address;
        this.#componentLogEntry.browserFormFactor = browser.formFactor;
        this.#componentLogEntry.browserLanguage = browser.language;
        this.#componentLogEntry.browserScreenResolution = browser.screenResolution;
        // TODO Deprecated, remove in a future release
        this.#componentLogEntry.browserUrl = browser.address;
        this.#componentLogEntry.browserUserAgent = browser.userAgent;
        this.#componentLogEntry.browserWindowResolution = browser.windowResolution;
    }

    // Handles some Salesforce-specific stack trace parsing for LWC & Aura components
    _cleanStackTraceParticle(stackTraceParticle) {
        stackTraceParticle.source = stackTraceParticle.source?.trim();

        const lwcModulesFileNamePrefix = 'modules/';
        if (stackTraceParticle.fileName?.startsWith(lwcModulesFileNamePrefix)) {
            stackTraceParticle.metadataType = 'LightningComponentBundle';

            stackTraceParticle.fileName = stackTraceParticle.fileName.substring(
                stackTraceParticle.fileName.indexOf(lwcModulesFileNamePrefix) + lwcModulesFileNamePrefix.length
            );
        }
        const auraComponentsContent = '/components/';
        if (stackTraceParticle.fileName?.indexOf(auraComponentsContent) > -1) {
            stackTraceParticle.metadataType = 'AuraDefinitionBundle';

            stackTraceParticle.fileName = stackTraceParticle.fileName.substring(
                stackTraceParticle.fileName.indexOf(auraComponentsContent) + auraComponentsContent.length,
                stackTraceParticle.fileName.length
            );
        }
        const jsFileNameSuffix = '.js';
        if (stackTraceParticle.fileName?.endsWith(jsFileNameSuffix)) {
            stackTraceParticle.componentName = stackTraceParticle.fileName.substring(0, stackTraceParticle.fileName.length - jsFileNameSuffix.length);
        }

        const invalidFunctionNameSuffix = '/<';
        if (stackTraceParticle.functionName?.endsWith(invalidFunctionNameSuffix)) {
            stackTraceParticle.functionName = stackTraceParticle.functionName.substring(
                0,
                stackTraceParticle.functionName.length - invalidFunctionNameSuffix.length
            );
        }

        if (stackTraceParticle.columnNumber) {
            stackTraceParticle.columnNumber = isNaN(stackTraceParticle.columnNumber) ? null : Number(stackTraceParticle.columnNumber);
        }

        if (stackTraceParticle.lineNumber) {
            stackTraceParticle.lineNumber = isNaN(stackTraceParticle.lineNumber) ? null : Number(stackTraceParticle.lineNumber);
        }
    }

    /* eslint-disable no-console */
    _logToConsole() {
        if (!this.#isConsoleLoggingEnabled) {
            return;
        }

        const consoleMessagePrefix = `%c  Nebula Logger ${CURRENT_VERSION_NUMBER}  `;
        const consoleFormatting = 'background: #0c598d; color: #fff; font-size: 12px; font-weight:bold;';
        let consoleLoggingFunction;
        switch (this.#componentLogEntry.loggingLevel) {
            case 'ERROR':
                consoleLoggingFunction = console.error;
                break;
            case 'WARN':
                consoleLoggingFunction = console.warn;
                break;
            case 'INFO':
                consoleLoggingFunction = console.info;
                break;
            default:
                consoleLoggingFunction = console.debug;
                break;
        }

        const loggingLevelEmoji = LOGGING_LEVEL_EMOJIS[this.#componentLogEntry.loggingLevel];
        const qualifiedMessage = `${this.#componentLogEntry.loggingLevel} ${loggingLevelEmoji}: ${this.#componentLogEntry.message}`;
        consoleLoggingFunction(
            consoleMessagePrefix,
            consoleFormatting,
            qualifiedMessage,
            // Some JS stack traces are huuuuge, so don't print it in the browser console.
            // The stack trace will still be saved on the backend.
            '\n' + JSON.stringify(this.#componentLogEntry, replacer, 2)
        );
    }
};

function replacer(key, value) {
    if (Array.isArray(value) && value.length === 0) {
        return undefined;
    }

    if (!value) {
        return undefined;
    }

    const keysToIgnore = new Set([
        'browserAddress',
        'browserFormFactor',
        'browserLanguage',
        'browserScreenResolution',
        'browserUrl',
        'browserUserAgent',
        'browserWindowResolution',
        'loggingLevel',
        'message',
        'stack',
        // These properties exist on the origin object:
        'columnNumber',
        'fileName',
        'lineNumber',
        'parsedStackTraceString',
        'source',
        // tags are set via a builder method after console logging has happened,
        // so always exclude it
        'tags'
    ]);
    if (keysToIgnore.has(key)) {
        return undefined;
    }

    return value;
}

let hasInitialized = false;
export function newLogEntry(loggingLevel, isConsoleLoggingEnabled) {
    if (!hasInitialized) {
        const consoleMessagePrefix = `%c  Nebula Logger ${CURRENT_VERSION_NUMBER}  `;
        const consoleFormatting = 'background: #0c598d; color: #fff; font-size: 12px; font-weight:bold;';
        const browserDetails = new ComponentBrowser();
        /* eslint-disable no-console */
        console.info(consoleMessagePrefix, consoleFormatting, 'INFOℹ️: logger component initialized\n' + JSON.stringify(browserDetails, null, 2));

        hasInitialized = true;
    }
    return new LogEntryBuilder(loggingLevel, isConsoleLoggingEnabled);
}
