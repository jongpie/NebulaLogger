import { createElement } from 'lwc';
import Logger from 'c/logger';
import getSettings from '@salesforce/apex/ComponentLogger.getSettings';
import saveComponentLogEntries from '@salesforce/apex/ComponentLogger.saveComponentLogEntries';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

// Mock data
const mockGetSettings = require('./data/getLoggerSettings.json');

// Register a test wire adapter
const getSettingsAdapter = registerApexTestWireAdapter(getSettings);

function flushPromises() {
    return new Promise(resolve => setTimeout(resolve, 0));
}

jest.mock(
    '@salesforce/apex/ComponentLogger.getSettings',
    () => {
        return {
            default: () => mockGetSettings
        };
    },
    { virtual: true }
);

describe('Logger lwc tests', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });
    it('logs an ERROR entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit(mockGetSettings);

        return flushPromises().then(() => {
            const message = 'component log entry with loggingLevel ERROR';
            const logEntry = logger.error(message);

            expect(logger.getBufferSize()).toEqual(1);
            expect(logEntry.loggingLevel).toEqual('ERROR');
            expect(logEntry.message).toEqual(message);
        });
    });
    it('logs an WARN entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit(mockGetSettings);

        return flushPromises().then(() => {
            const message = 'component log entry with loggingLevel WARN';
            const logEntry = logger.warn(message);

            // const logEntries = logger.getBuffer();
            expect(logger.getBufferSize()).toEqual(1);
            expect(logEntry.loggingLevel).toEqual('WARN');
            expect(logEntry.message).toEqual(message);
        });
    });
    it('logs an INFO entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit(mockGetSettings);

        return flushPromises().then(() => {
            const message = 'component log entry with loggingLevel INFO';
            const logEntry = logger.info(message);

            expect(logger.getBufferSize()).toEqual(1);
            expect(logEntry.loggingLevel).toEqual('INFO');
            expect(logEntry.message).toEqual(message);
        });
    });
    it('logs an DEBUG entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit(mockGetSettings);

        return flushPromises().then(() => {
            const message = 'component log entry with loggingLevel DEBUG';
            const logEntry = logger.debug(message);

            expect(logger.getBufferSize()).toEqual(1);
            expect(logEntry.loggingLevel).toEqual('DEBUG');
            expect(logEntry.message).toEqual(message);
        });
    });
    it('logs an FINE entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit(mockGetSettings);

        return flushPromises().then(() => {
            const message = 'component log entry with loggingLevel FINE';
            const logEntry = logger.fine(message);

            expect(logger.getBufferSize()).toEqual(1);
            expect(logEntry.loggingLevel).toEqual('FINE');
            expect(logEntry.message).toEqual(message);
        });
    });
    it('logs an FINER entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit(mockGetSettings);

        return flushPromises().then(() => {
            const message = 'component log entry with loggingLevel FINER';
            const logEntry = logger.finer(message);

            expect(logger.getBufferSize()).toEqual(1);
            expect(logEntry.loggingLevel).toEqual('FINER');
            expect(logEntry.message).toEqual(message);
        });
    });
    it('logs an FINEST entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit(mockGetSettings);

        return flushPromises().then(() => {
            const message = 'component log entry with loggingLevel FINEST';
            const logEntry = logger.finest(message);

            expect(logger.getBufferSize()).toEqual(1);
            expect(logEntry.loggingLevel).toEqual('FINEST');
            expect(logEntry.message).toEqual(message);
        });
    });
    it('flushes buffer', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit(mockGetSettings);

        return flushPromises().then(() => {
            const numberOfLogEntries = 3;
            for (let i = 0; i < numberOfLogEntries; i++) {
                const logEntry = logger.info('entry number: ' + i);
            }

            expect(logger.getBufferSize()).toEqual(numberOfLogEntries);
            logger.flushBuffer();
            expect(logger.getBufferSize()).toEqual(0);
        });
    });
    it('sets recordId', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit(mockGetSettings);

        return flushPromises().then(() => {
            const logEntry = logger.info('example log entry');
            expect(logEntry.recordId).toBeFalsy();

            const mockUserId = '0052F000008yLcEQAU';
            logEntry.setRecordId(mockUserId);
            expect(logEntry.recordId).toEqual(mockUserId);
        });
    });
    it('sets record', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit(mockGetSettings);

        return flushPromises().then(() => {
            const logEntry = logger.info('example log entry');
            expect(logEntry.record).toBeFalsy();

            const mockUserId = '0052F000008yLcEQAU';
            const mockUserRecord = { Id: mockUserId, FirstName: 'Jonathan', LastName: 'Gillespie' };
            logEntry.setRecord(mockUserRecord);
            expect(logEntry.record).toEqual(mockUserRecord);
        });
    });
    it('sets exception', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit(mockGetSettings);

        return flushPromises().then(() => {
            const logEntry = logger.info('example log entry');
            expect(logEntry.exception).toBeFalsy();

            const mockException = new Error();
            logEntry.setException(mockException);
            expect(logEntry.exception).toEqual(mockException);
        });
    });
    it('adds tags', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit(mockGetSettings);

        return flushPromises().then(() => {
            const logEntry = logger.info('example log entry');
            expect(logEntry.recordId).toBeFalsy();

            const mockTags = ['first tag', 'second tag', 'third tag'];
            for (let i = 0; i < mockTags.length; i++) {
                logEntry.addTag(mockTags[i]);
            }
            expect(logEntry.tags.length).toEqual(mockTags.length);
        });
    });
    it('deduplicates tags', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit(mockGetSettings);

        return flushPromises().then(() => {
            const logEntry = logger.info('example log entry');
            expect(logEntry.recordId).toBeFalsy();

            const mockTags = ['duplicate tag', 'duplicate tag'];
            expect(mockTags.length).toEqual(2);
            expect(new Set(mockTags).size).toEqual(1);
            for (let i = 0; i < mockTags.length; i++) {
                logEntry.addTag(mockTags[i]);
            }
            expect(logEntry.tags.length).toEqual(1);
        });
    });
    it('flushes buffer after saving log entries', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit(mockGetSettings);

        return flushPromises().then(() => {
            logger.info('example INFO log entry');
            logger.debug('example DEBUG log entry');
            expect(logger.getBufferSize()).toBe(2);

            logger.saveLog();
        }).then(() => {
            expect(logger.getBufferSize()).toBe(0);
        });
    });
});
