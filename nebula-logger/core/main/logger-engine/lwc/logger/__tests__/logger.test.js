import { createElement } from 'lwc';
import Logger from 'c/logger';
import getSettings from '@salesforce/apex/ComponentLogger.getSettings';

const MOCK_GET_SETTINGS = require('./data/getLoggerSettings.json');

jest.mock(
    '@salesforce/apex/ComponentLogger.getSettings',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
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

    it('returns user settings', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });

        const userSettings = logger.getUserSettings();

        expect(userSettings.defaultSaveMethod).toEqual('EVENT_BUS');
        expect(userSettings.isEnabled).toEqual(true);
        expect(userSettings.isConsoleLoggingEnabled).toEqual(true);
    });

    it('sets a log scenario on all entries', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });
        logger.getUserSettings().isEnabled = true;
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

    it('logs an ERROR entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });

        const message = 'component log entry with loggingLevel ERROR';
        const logEntry = logger.error(message);

        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('ERROR');
        expect(logEntry.message).toEqual(message);
    });

    it('logs a WARN entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        getSettings.emit({ ...MOCK_GET_SETTINGS });

        const message = 'component log entry with loggingLevel WARN';
        const logEntry = logger.warn(message);

        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('WARN');
        expect(logEntry.message).toEqual(message);
    });

    it('logs an INFO entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });

        const message = 'component log entry with loggingLevel INFO';
        const logEntry = logger.info(message);

        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('INFO');
        expect(logEntry.message).toEqual(message);
    });

    it('logs a DEBUG entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });

        const message = 'component log entry with loggingLevel DEBUG';
        const logEntry = logger.debug(message);

        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('DEBUG');
        expect(logEntry.message).toEqual(message);
    });

    it('logs a FINE entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });

        const message = 'component log entry with loggingLevel FINE';
        const logEntry = logger.fine(message);

        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('FINE');
        expect(logEntry.message).toEqual(message);
    });

    it('logs a FINER entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });

        const message = 'component log entry with loggingLevel FINER';
        const logEntry = logger.finer(message);

        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('FINER');
        expect(logEntry.message).toEqual(message);
    });

    it('logs a FINEST entry', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });

        const message = 'component log entry with loggingLevel FINEST';
        const logEntry = logger.finest(message);

        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('FINEST');
        expect(logEntry.message).toEqual(message);
    });

    it('sets recordId', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });
        const logEntry = logger.info('example log entry');
        expect(logEntry.recordId).toBeFalsy();

        const mockUserId = '0052F000008yLcEQAU';
        logEntry.setRecordId(mockUserId);

        expect(logEntry.recordId).toEqual(mockUserId);
    });

    it('sets record', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });
        const logEntry = logger.info('example log entry');
        expect(logEntry.record).toBeFalsy();
        const mockUserRecord = { Id: '0052F000008yLcEQAU', FirstName: 'Jonathan', LastName: 'Gillespie' };

        logEntry.setRecord(mockUserRecord);

        expect(logEntry.record).toEqual(mockUserRecord);
    });

    it('sets JavaScript error details', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });
        const logEntry = logger.info('example log entry');
        expect(logEntry.error).toBeFalsy();
        const error = new TypeError('oops');
        expect(error).toBeTruthy();
        expect(error.message).toBeTruthy();
        expect(error.stack).toBeTruthy();

        logEntry.setError(error);

        expect(logEntry.error.message).toEqual(error.message);
        expect(logEntry.error.stack).toEqual(error.stack);
        expect(logEntry.error.type).toEqual('JavaScript.TypeError');
    });

    it('sets Apex error details', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });
        const logEntry = logger.info('example log entry');
        expect(logEntry.error).toBeFalsy();
        const error = {
            body: {
                exceptionType: 'System.DmlException',
                message: 'Some Apex error, oh no!',
                stackTrace: 'Class.SomeApexClass.runSomeMethod: line 314, column 42'
            }
        };
        expect(error).toBeTruthy();
        expect(error.body.exceptionType).toBeTruthy();
        expect(error.body.message).toBeTruthy();
        expect(error.body.stackTrace).toBeTruthy();

        logEntry.setError(error);

        expect(logEntry.error.message).toEqual(error.body.message);
        expect(logEntry.error.stack).toEqual(error.body.stackTrace);
        expect(logEntry.error.type).toEqual(error.body.exceptionType);
    });

    it('adds tags', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });
        const logEntry = logger.info('example log entry');
        expect(logEntry.recordId).toBeFalsy();
        const mockTags = ['first tag', 'second tag', 'third tag'];

        logEntry.addTags(mockTags);

        expect(logEntry.tags.length).toEqual(mockTags.length);
    });

    it('deduplicates tags', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });
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

    it('still works for ERROR logging level when disabled', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });
        logger.getUserSettings().isEnabled = false;

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

    it('still works for WARN logging level when disabled', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });
        logger.getUserSettings().isEnabled = false;

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

    it('still works for INFO logging level when disabled', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });
        logger.getUserSettings().isEnabled = false;

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

    it('still works for DEBUG logging level when disabled', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });
        logger.getUserSettings().isEnabled = false;

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

    it('still works for FINE logging level when disabled', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });
        logger.getUserSettings().isEnabled = false;

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

    it('still works for FINER logging level when disabled', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });
        logger.getUserSettings().isEnabled = false;

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

    it('still works for FINEST logging level when disabled', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });
        logger.getUserSettings().isEnabled = false;

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

    it('flushes buffer', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });
        const numberOfLogEntries = 3;
        for (let i = 0; i < numberOfLogEntries; i++) {
            logger.info('entry number: ' + i);
        }
        expect(logger.getBufferSize()).toEqual(numberOfLogEntries);

        logger.flushBuffer();

        expect(logger.getBufferSize()).toEqual(0);
    });

    it('saves log entries and flushes buffer', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.emit({ ...MOCK_GET_SETTINGS });
        logger.info('example INFO log entry');
        logger.debug('example DEBUG log entry');
        expect(logger.getBufferSize()).toBe(2);

        logger.saveLog();

        await Promise.resolve();
        expect(logger.getBufferSize()).toBe(0);
    });
});
