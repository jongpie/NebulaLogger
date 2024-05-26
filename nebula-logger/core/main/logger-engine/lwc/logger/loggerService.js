//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

import { newLogEntry } from './logEntryBuilder';
import getSettings from '@salesforce/apex/ComponentLogger.getSettings';
import saveComponentLogEntries from '@salesforce/apex/ComponentLogger.saveComponentLogEntries';

const COMPONENT_TYPES = {
    LWC: 'LWC',
    AURA: 'AURA'
}

/* eslint-disable @lwc/lwc/no-dupe-class-members */
const LoggerService = class {
    #componentLogEntries = [];
    #settings;
    #scenario;
    #componentType;

    setComponentType(componentType) {
        componentType = componentType.toUpperCase();
        if(!Object.keys(COMPONENT_TYPES).includes(componentType)) {
            throw new Error(`Invalid component type: ${componentType}, expected one of: ${Object.keys(COMPONENT_TYPES).join(', ')}`);
        }
        this.#componentType = componentType;
    }

    getLogEntries() {
        return this.#componentLogEntries;
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

    error(message) {
        return this._newEntry('ERROR', message);
    }

    warn(message) {
        return this._newEntry('WARN', message);
    }

    info(message) {
        return this._newEntry('INFO', message);
    }

    debug(message) {
        return this._newEntry('DEBUG', message);
    }

    fine(message) {
        return this._newEntry('FINE', message);
    }

    finer(message) {
        return this._newEntry('FINER', message);
    }

    finest(message) {
        return this._newEntry('FINEST', message);
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
        } catch (error) {
            /* eslint-disable-next-line no-console */
            console.error(error);
            throw error;
        }
    }

    _meetsUserLoggingLevel(logEntryLoggingLevel) {
        return this.#settings.isEnabled === true && this.#settings.userLoggingLevel.ordinal <= this.#settings?.supportedLoggingLevels[logEntryLoggingLevel];
    }

    _newEntry(loggingLevel, message) {
        const logEntryBuilder = newLogEntry(loggingLevel, this.#settings?.isConsoleLoggingEnabled);
        logEntryBuilder.setMessage(message);
        logEntryBuilder.setScenario(this.#scenario);
        if (this._meetsUserLoggingLevel(loggingLevel)) {
            this.#componentLogEntries.push(logEntryBuilder.getComponentLogEntry());
        }

        return logEntryBuilder;
    }
};

const createLoggerService = async function () {
    const service = new LoggerService();
    service.setComponentType(COMPONENT_TYPES.LWC);
    await service._loadSettingsFromServer();
    return service;
};

export { createLoggerService, COMPONENT_TYPES };
