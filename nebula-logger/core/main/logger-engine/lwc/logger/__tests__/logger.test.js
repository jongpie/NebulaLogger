import { createElement } from 'lwc';
import Logger from 'c/logger';
import getSettings from '@salesforce/apex/ComponentLogger.getSettings';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

const MOCK_GET_SETTINGS = require('./data/getLoggerSettings.json');
const getSettingsAdapter = registerApexTestWireAdapter(getSettings);

jest.mock(
    '@salesforce/apex/ComponentLogger.getSettings',
    () => {
        return {
            default: () => MOCK_GET_SETTINGS
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
        // jest.restoreAllMocks();
    });
    it('returns user settings', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });

        // await Promise.resolve();
        const userSettings = logger.getUserSettings();
        expect(userSettings.defaultSaveMethod).toEqual('EVENT_BUS');
        expect(userSettings.isEnabled).toEqual(true);
        expect(userSettings.isConsoleLoggingEnabled).toEqual(true);
    });
    it('sets a log scenario on all entries', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });
        logger.getUserSettings().isEnabled = true;

        return Promise.resolve().then(() => {
            const scenario = 'some scenario';
            const message = 'some message';
            const firstLogEntry = logger.finest(message);
            expect(firstLogEntry.scenario).toBeUndefined();
            expect(logger.getBufferSize()).toEqual(1);

            const secondLogEntry = logger.info(message);
            expect(secondLogEntry.scenario).toBeUndefined();
            expect(logger.getBufferSize()).toEqual(2);

            logger.setScenario(scenario);

            expect(firstLogEntry.scenario).toEqual(scenario);
            expect(secondLogEntry.scenario).toEqual(scenario);
        });
    });
    it('logs an ERROR entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });

        return Promise.resolve().then(() => {
            const message = 'component log entry with loggingLevel ERROR';
            const logEntry = logger.error(message);

            expect(logger.getBufferSize()).toEqual(1);
            expect(logEntry.loggingLevel).toEqual('ERROR');
            expect(logEntry.message).toEqual(message);
        });
    });
    it('logs a WARN entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });

        return Promise.resolve().then(() => {
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

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });

        return Promise.resolve().then(() => {
            const message = 'component log entry with loggingLevel INFO';
            const logEntry = logger.info(message);

            expect(logger.getBufferSize()).toEqual(1);
            expect(logEntry.loggingLevel).toEqual('INFO');
            expect(logEntry.message).toEqual(message);
        });
    });
    it('logs a DEBUG entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });

        return Promise.resolve().then(() => {
            const message = 'component log entry with loggingLevel DEBUG';
            const logEntry = logger.debug(message);

            expect(logger.getBufferSize()).toEqual(1);
            expect(logEntry.loggingLevel).toEqual('DEBUG');
            expect(logEntry.message).toEqual(message);
        });
    });
    it('logs a FINE entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });

        return Promise.resolve().then(() => {
            const message = 'component log entry with loggingLevel FINE';
            const logEntry = logger.fine(message);

            expect(logger.getBufferSize()).toEqual(1);
            expect(logEntry.loggingLevel).toEqual('FINE');
            expect(logEntry.message).toEqual(message);
        });
    });
    it('logs a FINER entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });

        return Promise.resolve().then(() => {
            const message = 'component log entry with loggingLevel FINER';
            const logEntry = logger.finer(message);

            expect(logger.getBufferSize()).toEqual(1);
            expect(logEntry.loggingLevel).toEqual('FINER');
            expect(logEntry.message).toEqual(message);
        });
    });
    it('logs a FINEST entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });

        return Promise.resolve().then(() => {
            const message = 'component log entry with loggingLevel FINEST';
            const logEntry = logger.finest(message);

            expect(logger.getBufferSize()).toEqual(1);
            expect(logEntry.loggingLevel).toEqual('FINEST');
            expect(logEntry.message).toEqual(message);
        });
    });
    it('sets recordId', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });

        return Promise.resolve().then(() => {
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

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });

        return Promise.resolve().then(() => {
            const logEntry = logger.info('example log entry');
            expect(logEntry.record).toBeFalsy();

            const mockUserId = '0052F000008yLcEQAU';
            const mockUserRecord = { Id: mockUserId, FirstName: 'Jonathan', LastName: 'Gillespie' };
            logEntry.setRecord(mockUserRecord);
            expect(logEntry.record).toEqual(mockUserRecord);
        });
    });
    it('sets error', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });

        return Promise.resolve().then(() => {
            const logEntry = logger.info('example log entry');
            expect(logEntry.error).toBeFalsy();

            let error = new TypeError('oops');
            expect(error).toBeTruthy();
            expect(error.message).toBeTruthy();
            expect(error.stack).toBeTruthy();

            logEntry.setError(error);
            expect(logEntry.error.message).toEqual(error.message);
            expect(logEntry.error.stack).toEqual(error.stack);
            expect(logEntry.error.type).toEqual('TypeError');
        });
    });
    it('adds tags', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });

        return Promise.resolve().then(() => {
            const logEntry = logger.info('example log entry');
            expect(logEntry.recordId).toBeFalsy();

            const mockTags = ['first tag', 'second tag', 'third tag'];
            logEntry.addTags(mockTags);
            expect(logEntry.tags.length).toEqual(mockTags.length);
        });
    });
    it('deduplicates tags', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });

        return Promise.resolve().then(() => {
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
    it('still works for ERROR when disabled', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });
        logger.getUserSettings().isEnabled = false;

        return Promise.resolve().then(() => {
            const logEntry = logger
                .error('example ERROR log entry')
                .setMessage('some message')
                .setRecordId('some_record_Id')
                .setRecord({ Id: 'some_record_Id' })
                .setError(new TypeError('oops'))
                .addTag('a tag')
                .addTags(['a second tag', 'a third tag']);
            expect(logger.getBufferSize()).toEqual(0);
            expect(logEntry.loggingLevel).toEqual(undefined);
            expect(logEntry.shouldSave).toEqual(false);
            expect(logEntry.recordId).toEqual(undefined);
            expect(logEntry.record).toEqual(undefined);
            expect(logEntry.error).toEqual(undefined);
            expect(logEntry.stack).toEqual(undefined);
            expect(logEntry.timestamp).toEqual(undefined);
            expect(logEntry.tags).toEqual(undefined);
        });
    });
    it('still works for WARN when disabled', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });
        logger.getUserSettings().isEnabled = false;

        return Promise.resolve().then(() => {
            const logEntry = logger
                .warn('example WARN log entry')
                .setMessage('some message')
                .setRecordId('some_record_Id')
                .setRecord({ Id: 'some_record_Id' })
                .setError(new TypeError('oops'))
                .addTag('a tag')
                .addTags(['a second tag', 'a third tag']);
            expect(logger.getBufferSize()).toEqual(0);
            expect(logger.getBufferSize()).toEqual(0);
            expect(logEntry.loggingLevel).toEqual(undefined);
            expect(logEntry.shouldSave).toEqual(false);
            expect(logEntry.recordId).toEqual(undefined);
            expect(logEntry.record).toEqual(undefined);
            expect(logEntry.error).toEqual(undefined);
            expect(logEntry.stack).toEqual(undefined);
            expect(logEntry.timestamp).toEqual(undefined);
            expect(logEntry.tags).toEqual(undefined);
        });
    });
    it('still works for INFO when disabled', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });
        logger.getUserSettings().isEnabled = false;

        return Promise.resolve().then(() => {
            const logEntry = logger
                .info('example INFO log entry')
                .setMessage('some message')
                .setRecordId('some_record_Id')
                .setRecord({ Id: 'some_record_Id' })
                .setError(new TypeError('oops'))
                .addTag('a tag')
                .addTags(['a second tag', 'a third tag']);
            expect(logger.getBufferSize()).toEqual(0);
            expect(logger.getBufferSize()).toEqual(0);
            expect(logEntry.loggingLevel).toEqual(undefined);
            expect(logEntry.shouldSave).toEqual(false);
            expect(logEntry.recordId).toEqual(undefined);
            expect(logEntry.record).toEqual(undefined);
            expect(logEntry.error).toEqual(undefined);
            expect(logEntry.stack).toEqual(undefined);
            expect(logEntry.timestamp).toEqual(undefined);
            expect(logEntry.tags).toEqual(undefined);
        });
    });
    it('still works for DEBUG when disabled', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });
        logger.getUserSettings().isEnabled = false;

        return Promise.resolve().then(() => {
            const logEntry = logger
                .debug('example DEBUG log entry')
                .setMessage('some message')
                .setRecordId('some_record_Id')
                .setRecord({ Id: 'some_record_Id' })
                .setError(new TypeError('oops'))
                .addTag('a tag')
                .addTags(['a second tag', 'a third tag']);
            expect(logger.getBufferSize()).toEqual(0);
            expect(logger.getBufferSize()).toEqual(0);
            expect(logEntry.loggingLevel).toEqual(undefined);
            expect(logEntry.shouldSave).toEqual(false);
            expect(logEntry.recordId).toEqual(undefined);
            expect(logEntry.record).toEqual(undefined);
            expect(logEntry.error).toEqual(undefined);
            expect(logEntry.stack).toEqual(undefined);
            expect(logEntry.timestamp).toEqual(undefined);
            expect(logEntry.tags).toEqual(undefined);
        });
    });
    it('still works for FINE when disabled', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });
        logger.getUserSettings().isEnabled = false;

        return Promise.resolve().then(() => {
            const logEntry = logger
                .fine('example FINE log entry')
                .setMessage('some message')
                .setRecordId('some_record_Id')
                .setRecord({ Id: 'some_record_Id' })
                .setError(new TypeError('oops'))
                .addTag('a tag')
                .addTags(['a second tag', 'a third tag']);
            expect(logger.getBufferSize()).toEqual(0);
            expect(logger.getBufferSize()).toEqual(0);
            expect(logEntry.loggingLevel).toEqual(undefined);
            expect(logEntry.shouldSave).toEqual(false);
            expect(logEntry.recordId).toEqual(undefined);
            expect(logEntry.record).toEqual(undefined);
            expect(logEntry.error).toEqual(undefined);
            expect(logEntry.stack).toEqual(undefined);
            expect(logEntry.timestamp).toEqual(undefined);
            expect(logEntry.tags).toEqual(undefined);
        });
    });
    it('still works for FINER when disabled', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });
        logger.getUserSettings().isEnabled = false;

        return Promise.resolve().then(() => {
            const logEntry = logger
                .finer('example FINER log entry')
                .setMessage('some message')
                .setRecordId('some_record_Id')
                .setRecord({ Id: 'some_record_Id' })
                .setError(new TypeError('oops'))
                .addTag('a tag')
                .addTags(['a second tag', 'a third tag']);
            expect(logger.getBufferSize()).toEqual(0);
            expect(logger.getBufferSize()).toEqual(0);
            expect(logEntry.loggingLevel).toEqual(undefined);
            expect(logEntry.shouldSave).toEqual(false);
            expect(logEntry.recordId).toEqual(undefined);
            expect(logEntry.record).toEqual(undefined);
            expect(logEntry.error).toEqual(undefined);
            expect(logEntry.stack).toEqual(undefined);
            expect(logEntry.timestamp).toEqual(undefined);
            expect(logEntry.tags).toEqual(undefined);
        });
    });
    it('still works for FINEST when disabled', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });
        logger.getUserSettings().isEnabled = false;

        return Promise.resolve().then(() => {
            const logEntry = logger
                .finest('example FINEST log entry')
                .setMessage('some message')
                .setRecordId('some_record_Id')
                .setRecord({ Id: 'some_record_Id' })
                .setError(new TypeError('oops'))
                .addTag('a tag')
                .addTags(['a second tag', 'a third tag']);
            expect(logger.getBufferSize()).toEqual(0);
            expect(logger.getBufferSize()).toEqual(0);
            expect(logEntry.loggingLevel).toEqual(undefined);
            expect(logEntry.shouldSave).toEqual(false);
            expect(logEntry.recordId).toEqual(undefined);
            expect(logEntry.record).toEqual(undefined);
            expect(logEntry.error).toEqual(undefined);
            expect(logEntry.stack).toEqual(undefined);
            expect(logEntry.timestamp).toEqual(undefined);
            expect(logEntry.tags).toEqual(undefined);
        });
    });
    it('flushes buffer', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });

        return Promise.resolve().then(() => {
            const numberOfLogEntries = 3;
            for (let i = 0; i < numberOfLogEntries; i++) {
                logger.info('entry number: ' + i);
            }

            expect(logger.getBufferSize()).toEqual(numberOfLogEntries);
            logger.flushBuffer();
            expect(logger.getBufferSize()).toEqual(0);
        });
    });
    it('saves log entries and flushes buffer', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);

        getSettingsAdapter.emit({ ...MOCK_GET_SETTINGS });

        return Promise.resolve()
            .then(() => {
                logger.info('example INFO log entry');
                logger.debug('example DEBUG log entry');
                expect(logger.getBufferSize()).toBe(2);

                logger.saveLog();
            })
            .then(() => {
                expect(logger.getBufferSize()).toBe(0);
            });
    });
});
