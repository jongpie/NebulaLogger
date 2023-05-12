import { createElement } from 'lwc';
// Recommended approach
import { getLogger } from 'c/logger';
// Legacy approach
import Logger from 'c/logger';
import getSettings from '@salesforce/apex/ComponentLogger.getSettings';

const MOCK_GET_SETTINGS = require('./data/getLoggerSettings.json');

const flushPromises = async () => {
    await new Promise(process.nextTick);
};

jest.mock(
    '@salesforce/apex/ComponentLogger.getSettings',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

describe('logger lwc import tests', () => {
    afterEach(() => {
        getLogger().flushBuffer();
        jest.clearAllMocks();
    });

    it('returns user settings when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });

        const userSettings = await logger.getUserSettings();

        expect(userSettings.defaultSaveMethod).toEqual('EVENT_BUS');
        expect(userSettings.isEnabled).toEqual(true);
        expect(userSettings.isConsoleLoggingEnabled).toEqual(true);
    });

    it('sets a log scenario on all entries when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        await logger.getUserSettings();
        const scenario = 'some scenario';
        const message = 'some message';
        const firstLogEntry = await logger.finest(message);
        await flushPromises();
        expect(firstLogEntry.scenario).toBeUndefined();
        expect(logger.getBufferSize()).toEqual(1);
        const secondLogEntry = logger.info(message);
        await flushPromises();
        expect(secondLogEntry.scenario).toBeUndefined();
        expect(logger.getBufferSize()).toEqual(2);

        await logger.setScenario(scenario);

        expect(firstLogEntry.scenario).toEqual(scenario);
        expect(secondLogEntry.scenario).toEqual(scenario);
    });

    it('logs an ERROR entry when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        const message = 'component log entry with loggingLevel ERROR';

        const logEntry = logger.error(message);

        await flushPromises();
        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('ERROR');
        expect(logEntry.message).toEqual(message);
    });

    it('logs a WARN entry when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        const message = 'component log entry with loggingLevel WARN';

        const logEntry = logger.warn(message);

        await flushPromises();
        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('WARN');
        expect(logEntry.message).toEqual(message);
    });

    it('logs an INFO entry when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        const message = 'component log entry with loggingLevel INFO';

        const logEntry = logger.info(message);

        await flushPromises();
        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('INFO');
        expect(logEntry.message).toEqual(message);
    });

    it('logs a DEBUG entry when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        const message = 'component log entry with loggingLevel DEBUG';

        const logEntry = logger.debug(message);

        await flushPromises();
        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('DEBUG');
        expect(logEntry.message).toEqual(message);
    });

    it('logs a FINE entry when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        const message = 'component log entry with loggingLevel FINE';

        const logEntry = logger.fine(message);

        await flushPromises();
        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('FINE');
        expect(logEntry.message).toEqual(message);
    });

    it('logs a FINER entry when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        const message = 'component log entry with loggingLevel FINER';

        const logEntry = logger.finer(message);

        await flushPromises();
        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('FINER');
        expect(logEntry.message).toEqual(message);
    });

    it('logs a FINEST entry when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        const message = 'component log entry with loggingLevel FINEST';

        const logEntry = logger.finest(message);

        await flushPromises();
        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('FINEST');
        expect(logEntry.message).toEqual(message);
    });

    it('sets recordId when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        await logger.getUserSettings();
        const logEntry = logger.info('example log entry');
        expect(logEntry.recordId).toBeFalsy();
        const mockUserId = '0052F000008yLcEQAU';

        logEntry.setRecordId(mockUserId);

        expect(logEntry.recordId).toEqual(mockUserId);
    });

    it('sets record when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        await logger.getUserSettings();
        const logEntry = logger.info('example log entry');
        expect(logEntry.record).toBeFalsy();
        const mockUserRecord = { Id: '0052F000008yLcEQAU', FirstName: 'Jonathan', LastName: 'Gillespie' };

        logEntry.setRecord(mockUserRecord);

        expect(logEntry.record).toEqual(mockUserRecord);
    });

    it('sets JavaScript error details when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        await logger.getUserSettings();
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

    it('sets Apex error details when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
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

    it('adds tags when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        const logEntry = logger.info('example log entry');
        expect(logEntry.recordId).toBeFalsy();
        const mockTags = ['first tag', 'second tag', 'third tag'];

        logEntry.addTags(mockTags);

        expect(logEntry.tags.length).toEqual(mockTags.length);
    });

    it('deduplicates tags when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
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

    it('still works for ERROR logging level when disabled when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
        const settings = await logger.getUserSettings({ forceReload: true });
        expect(settings.isEnabled).toEqual(false);
        const error = new TypeError('oops');

        const logEntry = logger
            .error('example ERROR log entry')
            .setMessage('some message')
            .setRecordId('some_record_Id')
            .setRecord({ Id: 'some_record_Id' })
            .setError(error)
            .addTag('a tag')
            .addTags(['a second tag', 'a third tag']);

        await flushPromises();
        expect(logger.getBufferSize()).toEqual(0);
        expect(logEntry.loggingLevel).toEqual('ERROR');
        expect(logEntry.recordId).toEqual('some_record_Id');
        expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
        expect(logEntry.error).toBeTruthy();
        expect(logEntry.stack).toBeTruthy();
        expect(logEntry.error.message).toEqual(error.message);
        expect(logEntry.error.stack).toEqual(error.stack);
        expect(logEntry.timestamp).toBeTruthy();
        expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    });

    it('still works for WARN logging level when disabled when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
        const settings = await logger.getUserSettings({ forceReload: true });
        expect(settings.isEnabled).toEqual(false);
        const error = new TypeError('oops');

        const logEntry = logger
            .warn('example WARN log entry')
            .setMessage('some message')
            .setRecordId('some_record_Id')
            .setRecord({ Id: 'some_record_Id' })
            .setError(error)
            .addTag('a tag')
            .addTags(['a second tag', 'a third tag']);

        await flushPromises();
        expect(logger.getBufferSize()).toEqual(0);
        expect(logEntry.loggingLevel).toEqual('WARN');
        expect(logEntry.recordId).toEqual('some_record_Id');
        expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
        expect(logEntry.error).toBeTruthy();
        expect(logEntry.stack).toBeTruthy();
        expect(logEntry.error.message).toEqual(error.message);
        expect(logEntry.error.stack).toEqual(error.stack);
        expect(logEntry.timestamp).toBeTruthy();
        expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    });

    it('still works for INFO logging level when disabled when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
        const settings = await logger.getUserSettings({ forceReload: true });
        expect(settings.isEnabled).toEqual(false);
        const error = new TypeError('oops');

        const logEntry = logger
            .info('example INFO log entry')
            .setMessage('some message')
            .setRecordId('some_record_Id')
            .setRecord({ Id: 'some_record_Id' })
            .setError(error)
            .addTag('a tag')
            .addTags(['a second tag', 'a third tag']);

        await flushPromises();
        expect(logger.getBufferSize()).toEqual(0);
        expect(logEntry.loggingLevel).toEqual('INFO');
        expect(logEntry.recordId).toEqual('some_record_Id');
        expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
        expect(logEntry.error).toBeTruthy();
        expect(logEntry.stack).toBeTruthy();
        expect(logEntry.error.message).toEqual(error.message);
        expect(logEntry.error.stack).toEqual(error.stack);
        expect(logEntry.timestamp).toBeTruthy();
        expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    });

    it('still works for DEBUG logging level when disabled when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
        const settings = await logger.getUserSettings({ forceReload: true });
        expect(settings.isEnabled).toEqual(false);
        const error = new TypeError('oops');

        const logEntry = logger
            .debug('example DEBUG log entry')
            .setMessage('some message')
            .setRecordId('some_record_Id')
            .setRecord({ Id: 'some_record_Id' })
            .setError(error)
            .addTag('a tag')
            .addTags(['a second tag', 'a third tag']);

        await flushPromises();
        expect(logger.getBufferSize()).toEqual(0);
        expect(logEntry.loggingLevel).toEqual('DEBUG');
        expect(logEntry.recordId).toEqual('some_record_Id');
        expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
        expect(logEntry.error).toBeTruthy();
        expect(logEntry.stack).toBeTruthy();
        expect(logEntry.error.message).toEqual(error.message);
        expect(logEntry.error.stack).toEqual(error.stack);
        expect(logEntry.timestamp).toBeTruthy();
        expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    });

    it('still works for FINE logging level when disabled when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
        const settings = await logger.getUserSettings({ forceReload: true });
        expect(settings.isEnabled).toEqual(false);
        const error = new TypeError('oops');

        const logEntry = logger
            .fine('example FINE log entry')
            .setMessage('some message')
            .setRecordId('some_record_Id')
            .setRecord({ Id: 'some_record_Id' })
            .setError(error)
            .addTag('a tag')
            .addTags(['a second tag', 'a third tag']);

        await flushPromises();
        expect(logger.getBufferSize()).toEqual(0);
        expect(logEntry.loggingLevel).toEqual('FINE');
        expect(logEntry.recordId).toEqual('some_record_Id');
        expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
        expect(logEntry.error).toBeTruthy();
        expect(logEntry.stack).toBeTruthy();
        expect(logEntry.error.message).toEqual(error.message);
        expect(logEntry.error.stack).toEqual(error.stack);
        expect(logEntry.timestamp).toBeTruthy();
        expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    });

    it('still works for FINER logging level when disabled when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
        const settings = await logger.getUserSettings({ forceReload: true });
        expect(settings.isEnabled).toEqual(false);
        const error = new TypeError('oops');

        const logEntry = logger
            .finer('example FINER log entry')
            .setMessage('some message')
            .setRecordId('some_record_Id')
            .setRecord({ Id: 'some_record_Id' })
            .setError(error)
            .addTag('a tag')
            .addTags(['a second tag', 'a third tag']);

        await flushPromises();
        expect(logger.getBufferSize()).toEqual(0);
        expect(logEntry.loggingLevel).toEqual('FINER');
        expect(logEntry.recordId).toEqual('some_record_Id');
        expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
        expect(logEntry.error).toBeTruthy();
        expect(logEntry.stack).toBeTruthy();
        expect(logEntry.error.message).toEqual(error.message);
        expect(logEntry.error.stack).toEqual(error.stack);
        expect(logEntry.timestamp).toBeTruthy();
        expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    });

    it('still works for FINEST logging level when disabled when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
        const settings = await logger.getUserSettings({ forceReload: true });
        expect(settings.isEnabled).toEqual(false);
        const error = new TypeError('oops');

        const logEntry = logger
            .finest('example FINEST log entry')
            .setMessage('some message')
            .setRecordId('some_record_Id')
            .setRecord({ Id: 'some_record_Id' })
            .setError(error)
            .addTag('a tag')
            .addTags(['a second tag', 'a third tag']);

        await flushPromises();
        expect(logger.getBufferSize()).toEqual(0);
        expect(logEntry.loggingLevel).toEqual('FINEST');
        expect(logEntry.recordId).toEqual('some_record_Id');
        expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
        expect(logEntry.error).toBeTruthy();
        expect(logEntry.stack).toBeTruthy();
        expect(logEntry.error.message).toEqual(error.message);
        expect(logEntry.error.stack).toEqual(error.stack);
        expect(logEntry.timestamp).toBeTruthy();
        expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    });

    it('flushes buffer when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        await logger.getUserSettings({ forceReload: true });
        const numberOfLogEntries = 3;
        for (let i = 0; i < numberOfLogEntries; i++) {
            logger.info('entry number: ' + i);
        }
        await flushPromises();
        expect(logger.getBufferSize()).toEqual(numberOfLogEntries);

        await logger.flushBuffer();

        expect(logger.getBufferSize()).toEqual(0);
    });

    it('saves log entries and flushes buffer when using recommended import approach', async () => {
        const logger = getLogger();
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        await logger.getUserSettings({ forceReload: true });
        logger.info('example INFO log entry');
        logger.debug('example DEBUG log entry');
        await flushPromises();
        expect(logger.getBufferSize()).toBe(2);

        logger.saveLog();

        await flushPromises();
        expect(logger.getBufferSize()).toBe(0);
    });
});

describe('logger lwc legacy markup tests', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        getLogger().flushBuffer();
        jest.clearAllMocks();
    });

    it('returns user settings when using deprecated markup approach', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });

        const userSettings = await logger.getUserSettings();

        expect(userSettings.defaultSaveMethod).toEqual('EVENT_BUS');
        expect(userSettings.isEnabled).toEqual(true);
        expect(userSettings.isConsoleLoggingEnabled).toEqual(true);
    });

    it('sets a log scenario on all entries when using deprecated markup approach', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        const message = 'some message';
        const firstLogEntry = await logger.finest(message);
        expect(firstLogEntry.scenario).toBeUndefined();
        expect(logger.getBufferSize()).toEqual(1);
        const secondLogEntry = await logger.info(message);
        expect(secondLogEntry.scenario).toBeUndefined();
        expect(logger.getBufferSize()).toEqual(2);

        const scenario = 'some scenario';
        logger.setScenario(scenario);

        expect(firstLogEntry.scenario).toEqual(scenario);
        expect(secondLogEntry.scenario).toEqual(scenario);
    });

    it('logs an ERROR entry when using deprecated markup approach', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });

        const message = 'component log entry with loggingLevel ERROR';
        const logEntry = await logger.error(message);

        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('ERROR');
        expect(logEntry.message).toEqual(message);
    });

    it('logs a WARN entry when using deprecated markup approach', async () => {
        const logger = createElement('c-logger', { is: Logger });
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });

        const message = 'component log entry with loggingLevel WARN';
        const logEntry = await logger.warn(message);

        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('WARN');
        expect(logEntry.message).toEqual(message);
    });

    it('logs an INFO entry when using deprecated markup approach', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });

        const message = 'component log entry with loggingLevel INFO';
        const logEntry = await logger.info(message);

        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('INFO');
        expect(logEntry.message).toEqual(message);
    });

    it('logs a DEBUG entry when using deprecated markup approach', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });

        const message = 'component log entry with loggingLevel DEBUG';
        const logEntry = await logger.debug(message);

        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('DEBUG');
        expect(logEntry.message).toEqual(message);
    });

    it('logs a FINE entry when using deprecated markup approach', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });

        const message = 'component log entry with loggingLevel FINE';
        const logEntry = await logger.fine(message);

        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('FINE');
        expect(logEntry.message).toEqual(message);
    });

    it('logs a FINER entry when using deprecated markup approach', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });

        const message = 'component log entry with loggingLevel FINER';
        const logEntry = await logger.finer(message);

        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('FINER');
        expect(logEntry.message).toEqual(message);
    });

    it('logs a FINEST entry when using deprecated markup approach', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });

        const message = 'component log entry with loggingLevel FINEST';
        const logEntry = await logger.finest(message);

        expect(logger.getBufferSize()).toEqual(1);
        expect(logEntry.loggingLevel).toEqual('FINEST');
        expect(logEntry.message).toEqual(message);
    });

    it('sets recordId when using deprecated markup approach', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        const logEntry = await logger.info('example log entry');
        expect(logEntry.recordId).toBeFalsy();

        const mockUserId = '0052F000008yLcEQAU';
        logEntry.setRecordId(mockUserId);

        expect(logEntry.recordId).toEqual(mockUserId);
    });

    it('sets record when using deprecated markup approach', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        const logEntry = await logger.info('example log entry');
        expect(logEntry.record).toBeFalsy();
        const mockUserRecord = { Id: '0052F000008yLcEQAU', FirstName: 'Jonathan', LastName: 'Gillespie' };

        logEntry.setRecord(mockUserRecord);

        expect(logEntry.record).toEqual(mockUserRecord);
    });

    it('sets JavaScript error details when using deprecated markup approach', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        const logEntry = await logger.info('example log entry');
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

    it('sets Apex error details when using deprecated markup approach', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        const logEntry = await logger.info('example log entry');
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

    it('adds tags when using deprecated markup approach', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        const logEntry = await logger.info('example log entry');
        expect(logEntry.recordId).toBeFalsy();
        const mockTags = ['first tag', 'second tag', 'third tag'];

        logEntry.addTags(mockTags);

        expect(logEntry.tags.length).toEqual(mockTags.length);
    });

    it('deduplicates tags when using deprecated markup approach', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        const logEntry = await logger.info('example log entry');
        expect(logEntry.recordId).toBeFalsy();
        const mockTags = ['duplicate tag', 'duplicate tag'];
        expect(mockTags.length).toEqual(2);
        expect(new Set(mockTags).size).toEqual(1);

        for (let i = 0; i < mockTags.length; i++) {
            logEntry.addTag(mockTags[i]);
        }

        expect(logEntry.tags.length).toEqual(1);
    });

    it('still works for ERROR logging level when disabled when using deprecated markup approach', async () => {
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        const settings = await logger.getUserSettings({ forceReload: true });
        expect(settings.isEnabled).toEqual(false);
        const error = new TypeError('oops');

        const logEntry = logger
            .error('example ERROR log entry')
            .setMessage('some message')
            .setRecordId('some_record_Id')
            .setRecord({ Id: 'some_record_Id' })
            .setError(error)
            .addTag('a tag')
            .addTags(['a second tag', 'a third tag']);

        expect(logger.getBufferSize()).toEqual(0);
        expect(logEntry.loggingLevel).toEqual('ERROR');
        expect(logEntry.recordId).toEqual('some_record_Id');
        expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
        expect(logEntry.error).toBeTruthy();
        expect(logEntry.stack).toBeTruthy();
        expect(logEntry.error.message).toEqual(error.message);
        expect(logEntry.error.stack).toEqual(error.stack);
        expect(logEntry.timestamp).toBeTruthy();
        expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    });

    it('still works for WARN logging level when disabled when using deprecated markup approach', async () => {
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        const settings = await logger.getUserSettings({ forceReload: true });
        expect(settings.isEnabled).toEqual(false);
        const error = new TypeError('oops');

        const logEntry = logger
            .warn('example WARN log entry')
            .setMessage('some message')
            .setRecordId('some_record_Id')
            .setRecord({ Id: 'some_record_Id' })
            .setError(error)
            .addTag('a tag')
            .addTags(['a second tag', 'a third tag']);

        expect(logger.getBufferSize()).toEqual(0);
        expect(logEntry.loggingLevel).toEqual('WARN');
        expect(logEntry.recordId).toEqual('some_record_Id');
        expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
        expect(logEntry.error).toBeTruthy();
        expect(logEntry.stack).toBeTruthy();
        expect(logEntry.error.message).toEqual(error.message);
        expect(logEntry.error.stack).toEqual(error.stack);
        expect(logEntry.timestamp).toBeTruthy();
        expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    });

    it('still works for INFO logging level when disabled when using deprecated markup approach', async () => {
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        const settings = await logger.getUserSettings({ forceReload: true });
        expect(settings.isEnabled).toEqual(false);
        const error = new TypeError('oops');

        const logEntry = logger
            .info('example INFO log entry')
            .setMessage('some message')
            .setRecordId('some_record_Id')
            .setRecord({ Id: 'some_record_Id' })
            .setError(error)
            .addTag('a tag')
            .addTags(['a second tag', 'a third tag']);

        expect(logger.getBufferSize()).toEqual(0);
        expect(logEntry.loggingLevel).toEqual('INFO');
        expect(logEntry.recordId).toEqual('some_record_Id');
        expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
        expect(logEntry.error).toBeTruthy();
        expect(logEntry.stack).toBeTruthy();
        expect(logEntry.error.message).toEqual(error.message);
        expect(logEntry.error.stack).toEqual(error.stack);
        expect(logEntry.timestamp).toBeTruthy();
        expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    });

    it('still works for DEBUG logging level when disabled when using deprecated markup approach', async () => {
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        const settings = await logger.getUserSettings({ forceReload: true });
        expect(settings.isEnabled).toEqual(false);
        const error = new TypeError('oops');

        const logEntry = logger
            .debug('example DEBUG log entry')
            .setMessage('some message')
            .setRecordId('some_record_Id')
            .setRecord({ Id: 'some_record_Id' })
            .setError(error)
            .addTag('a tag')
            .addTags(['a second tag', 'a third tag']);

        expect(logger.getBufferSize()).toEqual(0);
        expect(logEntry.loggingLevel).toEqual('DEBUG');
        expect(logEntry.recordId).toEqual('some_record_Id');
        expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
        expect(logEntry.error).toBeTruthy();
        expect(logEntry.stack).toBeTruthy();
        expect(logEntry.error.message).toEqual(error.message);
        expect(logEntry.error.stack).toEqual(error.stack);
        expect(logEntry.timestamp).toBeTruthy();
        expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    });

    it('still works for FINE logging level when disabled when using deprecated markup approach', async () => {
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        const settings = await logger.getUserSettings({ forceReload: true });
        expect(settings.isEnabled).toEqual(false);
        const error = new TypeError('oops');

        const logEntry = logger
            .fine('example FINE log entry')
            .setMessage('some message')
            .setRecordId('some_record_Id')
            .setRecord({ Id: 'some_record_Id' })
            .setError(error)
            .addTag('a tag')
            .addTags(['a second tag', 'a third tag']);

        expect(logger.getBufferSize()).toEqual(0);
        expect(logEntry.loggingLevel).toEqual('FINE');
        expect(logEntry.recordId).toEqual('some_record_Id');
        expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
        expect(logEntry.error).toBeTruthy();
        expect(logEntry.stack).toBeTruthy();
        expect(logEntry.error.message).toEqual(error.message);
        expect(logEntry.error.stack).toEqual(error.stack);
        expect(logEntry.timestamp).toBeTruthy();
        expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    });

    it('still works for FINER logging level when disabled when using deprecated markup approach', async () => {
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        const settings = await logger.getUserSettings({ forceReload: true });
        expect(settings.isEnabled).toEqual(false);
        const error = new TypeError('oops');

        const logEntry = logger
            .finer('example FINER log entry')
            .setMessage('some message')
            .setRecordId('some_record_Id')
            .setRecord({ Id: 'some_record_Id' })
            .setError(error)
            .addTag('a tag')
            .addTags(['a second tag', 'a third tag']);

        expect(logger.getBufferSize()).toEqual(0);
        expect(logEntry.loggingLevel).toEqual('FINER');
        expect(logEntry.recordId).toEqual('some_record_Id');
        expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
        expect(logEntry.error).toBeTruthy();
        expect(logEntry.stack).toBeTruthy();
        expect(logEntry.error.message).toEqual(error.message);
        expect(logEntry.error.stack).toEqual(error.stack);
        expect(logEntry.timestamp).toBeTruthy();
        expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    });

    it('still works for FINEST logging level when disabled when using deprecated markup approach', async () => {
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: true });
        const settings = await logger.getUserSettings();
        expect(settings.isEnabled).toEqual(false);
        const error = new TypeError('oops');

        const logEntry = logger
            .finest('example FINEST log entry')
            .setMessage('some message')
            .setRecordId('some_record_Id')
            .setRecord({ Id: 'some_record_Id' })
            .setError(error)
            .addTag('a tag')
            .addTags(['a second tag', 'a third tag']);

        await flushPromises();
        expect(logger.getBufferSize()).toEqual(0);
        expect(logEntry.loggingLevel).toEqual('FINEST');
        expect(logEntry.recordId).toEqual('some_record_Id');
        expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
        expect(logEntry.error).toBeTruthy();
        expect(logEntry.stack).toBeTruthy();
        expect(logEntry.error.message).toEqual(error.message);
        expect(logEntry.error.stack).toEqual(error.stack);
        expect(logEntry.timestamp).toBeTruthy();
        expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    });

    it('flushes buffer when using deprecated markup approach', async () => {
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        const settings = await logger.getUserSettings({ forceReload: true });
        expect(settings.isEnabled).toEqual(true);
        const numberOfLogEntries = 3;
        for (let i = 0; i < numberOfLogEntries; i++) {
            logger.info('entry number: ' + i);
        }
        await flushPromises();
        expect(logger.getBufferSize()).toEqual(numberOfLogEntries);

        await logger.flushBuffer();

        await flushPromises();
        expect(logger.getBufferSize()).toEqual(0);
    });

    it('saves log entries and flushes buffer when using deprecated markup approach', async () => {
        getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
        const logger = createElement('c-logger', { is: Logger });
        document.body.appendChild(logger);
        const settings = await logger.getUserSettings({ forceReload: true });
        expect(settings.isEnabled).toEqual(true);
        logger.info('example INFO log entry');
        logger.debug('example DEBUG log entry');
        await flushPromises();
        expect(logger.getBufferSize()).toBe(2);

        logger.saveLog();

        await flushPromises();
        expect(logger.getBufferSize()).toBe(0);
    });
});
