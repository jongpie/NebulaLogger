//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import { newLogEntry } from './logEntryBuilder';
import getSettings from '@salesforce/apex/ComponentLogger.getSettings';
import saveComponentLogEntries from '@salesforce/apex/ComponentLogger.saveComponentLogEntries';
import { TaskQueue } from './taskQueue';

/* eslint-disable @lwc/lwc/no-dupe-class-members */
const LoggerService = class {
  #componentLogEntries = [];
  #settings;
  #scenario;
  #taskQueue = new TaskQueue();

  // TODO deprecate? Or make it async?
  getUserSettings() {
    return this.#settings;
  }

  setScenario(scenario) {
    this.#scenario = scenario;
    this.#componentLogEntries.forEach(logEntry => {
      logEntry.scenario = this.#scenario;
    });
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
    const logEntryBuilder = newLogEntry(loggingLevel).parseStackTrace(originStackTraceError).setMessage(message).setScenario(this.#scenario);
    const logEntry = logEntryBuilder.getComponentLogEntry();
    logEntry.scenario = this.#scenario;

    const loggingLevelCheckTask = providedLoggingLevel => {
      if (this._meetsUserLoggingLevel(providedLoggingLevel)) {
        this.#componentLogEntries.push(logEntry);

        if (this.#settings.isConsoleLoggingEnabled) {
          logEntryBuilder.logToConsole();
        }
        if (this.#settings.isLightningLoggerEnabled) {
          logEntryBuilder.logToLightningLogger();
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
};

const getLoggerService = function () {
  const service = new LoggerService();
  service._loadSettingsFromServer();
  return service;
};

const createLoggerService = async function () {
  const service = new LoggerService();
  await service._loadSettingsFromServer();
  await Promise.resolve();
  return service;
};

export { createLoggerService, getLoggerService };
