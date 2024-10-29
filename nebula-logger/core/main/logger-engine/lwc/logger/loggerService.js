//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import FORM_FACTOR from '@salesforce/client/formFactor';
import { log as lightningLog } from 'lightning/logger';
import LogEntryEventBuilder from './logEntryBuilder';
import LoggerServiceTaskQueue from './loggerServiceTaskQueue';
import getSettings from '@salesforce/apex/ComponentLogger.getSettings';
import saveComponentLogEntries from '@salesforce/apex/ComponentLogger.saveComponentLogEntries';

const CURRENT_VERSION_NUMBER = 'v4.14.15';

const CONSOLE_OUTPUT_CONFIG = {
  messagePrefix: `%c  Nebula Logger ${CURRENT_VERSION_NUMBER}  `,
  messageFormatting: 'background: #0c598d; color: #fff; font-size: 12px; font-weight:bold;'
};
const LOGGING_LEVEL_EMOJIS = {
  ERROR: '⛔',
  WARN: '⚠️',
  INFO: 'ℹ️',
  DEBUG: '🐞',
  FINE: '👍',
  FINER: '👌',
  FINEST: '🌟'
};

let areSystemMessagesEnabled = true;

export function enableSystemMessages() {
  areSystemMessagesEnabled = true;
}

export function disableSystemMessages() {
  areSystemMessagesEnabled = false;
}

export class BrowserContext {
  address = window.location.href;
  formFactor = FORM_FACTOR;
  language = window.navigator.language;
  screenResolution = window.screen.availWidth + ' x ' + window.screen.availHeight;
  userAgent = window.navigator.userAgent;
  windowResolution = window.innerWidth + ' x ' + window.innerHeight;
}

/* eslint-disable @lwc/lwc/no-dupe-class-members */
export default class LoggerService {
  static hasInitialized = false;

  #componentFieldToValue = {};
  #componentLogEntries = [];
  #settings;
  #scenario;
  #taskQueue = new LoggerServiceTaskQueue();

  constructor() {
    this._loadSettingsFromServer();

    if (areSystemMessagesEnabled && !LoggerService.hasInitialized) {
      this._logToConsole('INFO', 'logger component initialized\n' + JSON.stringify(new BrowserContext(), null, 2));

      LoggerService.hasInitialized = true;
    }
  }

  // TODO deprecate? Or make it async?
  getUserSettings() {
    return this.#settings;
  }

  /**
   * @description Sets multiple field values on every generated `LogEntryEvent__e` record
   * @param  {Object} fieldToValue An object containing the custom field name as a key, with the corresponding value to store.
   *                      Example: `{"SomeField__c": "some value", "AnotherField__c": "another value"}`
   */
  setField(fieldToValue) {
    if (!!fieldToValue && typeof fieldToValue === 'object' && !Array.isArray(fieldToValue)) {
      Object.assign(this.#componentFieldToValue, fieldToValue);
    }
  }

  setScenario(scenario) {
    this.#scenario = scenario;
  }

  exception(message, exception, originStackTraceError) {
    this.error(message, originStackTraceError).setExceptionDetails(exception);
    this.saveLog();
    throw exception;
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
    const saveLogTask = async providedSaveMethodName => {
      if (this.#componentLogEntries.length === 0) {
        return;
      }

      const logEntriesToSave = [...this.#componentLogEntries];
      this.flushBuffer();
      providedSaveMethodName = providedSaveMethodName ?? this.#settings.defaultSaveMethodName;
      try {
        await saveComponentLogEntries({
          componentLogEntries: logEntriesToSave,
          saveMethodName: providedSaveMethodName
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
    };

    this.#taskQueue.enqueueTask(saveLogTask, saveMethodName);
    await this.#taskQueue.executeTasks();
  }

  async _loadSettingsFromServer() {
    const loadSettingsTask = async () => {
      try {
        const retrievedSettings = await getSettings();
        this.#settings = Object.freeze({
          ...retrievedSettings,
          supportedLoggingLevels: Object.freeze(retrievedSettings.supportedLoggingLevels),
          userLoggingLevel: Object.freeze(retrievedSettings.userLoggingLevel)
        });
      } catch (error) {
        /* eslint-disable-next-line no-console */
        console.error(error);
        throw error;
      }
    };

    this.#taskQueue.enqueueTask(loadSettingsTask);
    await this.#taskQueue.executeTasks();
  }

  _newEntry(loggingLevel, message, originStackTraceError) {
    originStackTraceError = originStackTraceError ?? new Error();
    const logEntryBuilder = new LogEntryEventBuilder(loggingLevel, new BrowserContext())
      .parseStackTrace(originStackTraceError)
      .setMessage(message)
      .setScenario(this.#scenario);
    const logEntry = logEntryBuilder.getComponentLogEntry();
    Object.assign(logEntry.fieldToValue, this.#componentFieldToValue);

    const loggingLevelCheckTask = providedLoggingLevel => {
      if (this._meetsUserLoggingLevel(providedLoggingLevel)) {
        this.#componentLogEntries.push(logEntry);

        if (this.#settings.isConsoleLoggingEnabled) {
          this._logToConsole(logEntry.loggingLevel, logEntry.message, logEntry);
        }
        if (this.#settings.isLightningLoggerEnabled) {
          lightningLog(logEntry);
        }
      }
    };

    this.#taskQueue.enqueueTask(loggingLevelCheckTask, loggingLevel);
    this.#taskQueue.executeTasks();

    return logEntryBuilder;
  }

  _meetsUserLoggingLevel(logEntryLoggingLevel) {
    return this.#settings.isEnabled === true && this.#settings.userLoggingLevel.ordinal <= this.#settings.supportedLoggingLevels[logEntryLoggingLevel];
  }

  /* eslint-disable no-console */
  _logToConsole(loggingLevel, message, componentLogEntry) {
    const consoleLoggingFunction = console[loggingLevel.toLowerCase()] ?? console.debug;
    const loggingLevelEmoji = LOGGING_LEVEL_EMOJIS[loggingLevel];
    const qualifiedMessage = `${loggingLevelEmoji} ${loggingLevel}: ${message}`;
    const formattedComponentLogEntryString = !componentLogEntry
      ? ''
      : '\n' +
        JSON.stringify(
          {
            origin: {
              component: componentLogEntry.originStackTrace?.componentName,
              function: componentLogEntry.originStackTrace?.functionName,
              metadataType: componentLogEntry.originStackTrace?.metadataType
            },
            scenario: componentLogEntry.scenario,
            timestamp: componentLogEntry.timestamp
          },
          (_, value) => value ?? undefined,
          2
        );

    consoleLoggingFunction(CONSOLE_OUTPUT_CONFIG.messagePrefix, CONSOLE_OUTPUT_CONFIG.messageFormatting, qualifiedMessage, formattedComponentLogEntryString);
  }
}
