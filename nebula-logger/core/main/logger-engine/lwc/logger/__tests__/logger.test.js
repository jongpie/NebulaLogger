import { createElement } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { BrowserContext, enableSystemMessages, disableSystemMessages } from '../loggerService';
// Recommended import getLogger & deprecated import createLogger
import { getLogger, createLogger } from 'c/logger';
// Legacy markup-based approach
import Logger from 'c/logger';
import getSettings from '@salesforce/apex/ComponentLogger.getSettings';
import saveComponentLogEntries from '@salesforce/apex/ComponentLogger.saveComponentLogEntries';
import { log as lightningLog } from 'lightning/logger';

const MOCK_GET_SETTINGS = require('./data/getLoggerSettings.json');

const flushPromises = async () => {
  await new Promise(process.nextTick);
};

jest.mock('lightning/logger', () => ({ log: jest.fn() }), {
  virtual: true
});

jest.mock(
  '@salesforce/apex/ComponentLogger.getSettings',
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

jest.mock(
  '@salesforce/apex/ComponentLogger.saveComponentLogEntries',
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

describe('logger lwc recommended sync getLogger() import approach tests', () => {
  beforeEach(() => {
    disableSystemMessages();
    // One of logger's features (when enabled) is to auto-call the browser's console
    // so devs can see a log entry easily. But during Jest tests, seeing all of the
    // console statements is... a bit overwhelming, so the global console functions
    // are overwritten with an empty function so they're no-ops / they don't show up
    // in the test logs
    console.error = jest.fn();
    console.warn = jest.fn();
    console.info = jest.fn();
    console.debug = jest.fn();
    console.log = jest.fn();
  });
  afterEach(() => {
    jest.clearAllMocks();
  });

  it('returns user settings', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');

    const userSettings = logger.getUserSettings();

    expect(userSettings.defaultSaveMethod).toEqual('EVENT_BUS');
    expect(userSettings.isEnabled).toEqual(true);
    expect(userSettings.isConsoleLoggingEnabled).toEqual(false);
    expect(userSettings.isLightningLoggerEnabled).toEqual(false);
  });

  it('sets a scenario on all subsequent entries', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const scenario = 'some scenario';
    const message = 'some message';

    const firstLogEntry = logger.finest(message).getComponentLogEntry();
    logger.setScenario(scenario);
    const secondLogEntry = logger.info(message).getComponentLogEntry();

    expect(firstLogEntry.scenario).toBeUndefined();
    expect(secondLogEntry.scenario).toEqual(scenario);
  });

  it('calls console.info a single time on initialization', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    enableSystemMessages();
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');

    logger.error('some message');
    logger.warn('some message');
    logger.info('some message');
    logger.debug('some message');
    logger.fine('some message');
    logger.finer('some message');
    logger.finest('some message');

    await flushPromises('Resolve async task queue');
    expect(console.info).toHaveBeenCalledTimes(1);
    const expectedInitializationMessage = 'ℹ️ INFO: logger component initialized\n' + JSON.stringify(new BrowserContext(), null, 2);
    // The first 2 args (index 0 & 1) passed to console statements are a 'Nebula Logger' prefix & text formatting
    expect(console.info.mock.calls[0][2]).toBe(expectedInitializationMessage);
  });

  it('logs an ERROR entry', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel ERROR';

    const logEntry = logger.error(message).getComponentLogEntry();

    await flushPromises('Resolve async task queue');
    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('ERROR');
    expect(logEntry.message).toEqual(message);
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(0);
    expect(lightningLog).toHaveBeenCalledTimes(0);
  });

  it('calls console.error for an ERROR entry when enabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isConsoleLoggingEnabled: true });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel ERROR';

    const componentLogEntry = logger.error(message).getComponentLogEntry();

    await flushPromises('Resolve async task queue');
    expect(console.error).toHaveBeenCalledTimes(1);
    // The first 2 args (index 0 & 1) passed to console statements are a 'Nebula Logger' prefix & text formatting
    expect(console.error.mock.calls[0][2]).toBe('⛔ ERROR: ' + componentLogEntry.message);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(0);
    expect(lightningLog).toHaveBeenCalledTimes(0);
  });

  it('calls lightning/logger.log for an ERROR entry when enabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isLightningLoggerEnabled: true });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel ERROR';

    const componentLogEntry = logger.error(message).getComponentLogEntry();

    await flushPromises('Resolve async task queue');
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(0);
    expect(lightningLog).toHaveBeenCalledTimes(1);
    expect(lightningLog.mock.calls[0][0]).toBe(componentLogEntry);
  });

  it('logs a WARN entry', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel WARN';

    const logEntry = logger.warn(message).getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('WARN');
    expect(logEntry.message).toEqual(message);
    await flushPromises('Resolve async task queue');
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(0);
    expect(lightningLog).toHaveBeenCalledTimes(0);
  });

  it('calls console.warn for an WARN entry when enabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isConsoleLoggingEnabled: true });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel WARN';

    const componentLogEntry = logger.warn(message).getComponentLogEntry();

    await flushPromises('Resolve async task queue');
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(1);
    // The first 2 args (index 0 & 1) passed to console statements are a 'Nebula Logger' prefix & text formatting
    expect(console.warn.mock.calls[0][2]).toBe('⚠️ WARN: ' + componentLogEntry.message);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(0);
    expect(lightningLog).toHaveBeenCalledTimes(0);
  });

  it('calls lightning/logger.log for an WARN entry when enabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isLightningLoggerEnabled: true });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel WARN';

    const componentLogEntry = logger.warn(message).getComponentLogEntry();

    await flushPromises('Resolve async task queue');
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(0);
    expect(lightningLog).toHaveBeenCalledTimes(1);
    expect(lightningLog.mock.calls[0][0]).toBe(componentLogEntry);
  });

  it('logs an INFO entry', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel INFO';

    const logEntry = logger.info(message).getComponentLogEntry();

    await flushPromises('Resolve async task queue');
    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('INFO');
    expect(logEntry.message).toEqual(message);
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(0);
    expect(lightningLog).toHaveBeenCalledTimes(0);
  });

  it('calls console.info for an INFO entry when enabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isConsoleLoggingEnabled: true });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel INFO';

    const componentLogEntry = logger.info(message).getComponentLogEntry();

    await flushPromises('Resolve async task queue');
    expect(logger.getBufferSize()).toEqual(1);
    expect(componentLogEntry.loggingLevel).toEqual('INFO');
    expect(componentLogEntry.message).toEqual(message);
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    // console.info is always called once when c/logger is initialized,
    // so in this case, we check for 2 calls / index 1
    expect(console.info).toHaveBeenCalledTimes(1);
    // The first 2 args (index 0 & 1) passed to console statements are a 'Nebula Logger' prefix & text formatting
    expect(console.info.mock.calls[0][2]).toBe('ℹ️ INFO: ' + componentLogEntry.message);
    expect(console.debug).toHaveBeenCalledTimes(0);
    expect(lightningLog).toHaveBeenCalledTimes(0);
  });

  it('calls lightning/logger.log for an INFO entry when enabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isLightningLoggerEnabled: true });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel INFO';

    const componentLogEntry = logger.info(message).getComponentLogEntry();

    await flushPromises('Resolve async task queue');
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(0);
    expect(lightningLog).toHaveBeenCalledTimes(1);
    expect(lightningLog.mock.calls[0][0]).toBe(componentLogEntry);
  });

  it('logs a DEBUG entry', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel DEBUG';

    const logEntry = logger.debug(message).getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('DEBUG');
    expect(logEntry.message).toEqual(message);
    await flushPromises('Resolve async task queue');
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(0);
    expect(lightningLog).toHaveBeenCalledTimes(0);
  });

  it('calls console.debug for an DEBUG entry when enabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isConsoleLoggingEnabled: true });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel DEBUG';

    const componentLogEntry = logger.debug(message).getComponentLogEntry();

    await flushPromises('Resolve async task queue');
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(1);
    // The first 2 args (index 0 & 1) passed to console statements are a 'Nebula Logger' prefix & text formatting
    expect(console.debug.mock.calls[0][2]).toBe('🐞 DEBUG: ' + componentLogEntry.message);
    expect(lightningLog).toHaveBeenCalledTimes(0);
  });

  it('calls lightning/logger.log for an DEBUG entry when enabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isLightningLoggerEnabled: true });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel DEBUG';

    const componentLogEntry = logger.warn(message).getComponentLogEntry();

    await flushPromises('Resolve async task queue');
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(0);
    expect(lightningLog).toHaveBeenCalledTimes(1);
    expect(lightningLog.mock.calls[0][0]).toBe(componentLogEntry);
  });

  it('logs a FINE entry', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel FINE';

    const logEntry = logger.fine(message).getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('FINE');
    expect(logEntry.message).toEqual(message);
    await flushPromises('Resolve async task queue');
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(0);
    expect(lightningLog).toHaveBeenCalledTimes(0);
  });

  it('calls console.debug for an FINE entry when enabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isConsoleLoggingEnabled: true });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel FINE';

    const componentLogEntry = logger.fine(message).getComponentLogEntry();

    await flushPromises('Resolve async task queue');
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(1);
    // The first 2 args (index 0 & 1) passed to console statements are a 'Nebula Logger' prefix & text formatting
    expect(console.debug.mock.calls[0][2]).toBe('👍 FINE: ' + componentLogEntry.message);
    expect(lightningLog).toHaveBeenCalledTimes(0);
  });

  it('calls lightning/logger.log for an FINE entry when enabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isLightningLoggerEnabled: true });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel FINE';

    const componentLogEntry = logger.fine(message).getComponentLogEntry();

    await flushPromises('Resolve async task queue');
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(0);
    expect(lightningLog).toHaveBeenCalledTimes(1);
    expect(lightningLog.mock.calls[0][0]).toBe(componentLogEntry);
  });

  it('logs a FINER entry', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel FINER';

    const logEntry = logger.finer(message).getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('FINER');
    expect(logEntry.message).toEqual(message);
    await flushPromises('Resolve async task queue');
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(0);
    expect(lightningLog).toHaveBeenCalledTimes(0);
  });

  it('calls console.debug for an FINER entry when enabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isConsoleLoggingEnabled: true });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel FINER';

    const componentLogEntry = logger.finer(message).getComponentLogEntry();

    await flushPromises('Resolve async task queue');
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(1);
    // The first 2 args (index 0 & 1) passed to console statements are a 'Nebula Logger' prefix & text formatting
    expect(console.debug.mock.calls[0][2]).toBe('👌 FINER: ' + componentLogEntry.message);
    expect(lightningLog).toHaveBeenCalledTimes(0);
  });

  it('calls lightning/logger.log for an FINER entry when enabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isLightningLoggerEnabled: true });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel FINER';

    const componentLogEntry = logger.finer(message).getComponentLogEntry();

    await flushPromises('Resolve async task queue');
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(0);
    expect(lightningLog).toHaveBeenCalledTimes(1);
    expect(lightningLog.mock.calls[0][0]).toBe(componentLogEntry);
  });

  it('logs a FINEST entry', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel FINEST';

    const logEntry = logger.finest(message).getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('FINEST');
    expect(logEntry.message).toEqual(message);
    await flushPromises('Resolve async task queue');
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(0);
    expect(lightningLog).toHaveBeenCalledTimes(0);
  });

  it('calls console.debug for an FINEST entry when enabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isConsoleLoggingEnabled: true });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel FINEST';

    const componentLogEntry = logger.finest(message).getComponentLogEntry();

    await flushPromises('Resolve async task queue');
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(1);
    // The first 2 args (index 0 & 1) passed to console statements are a 'Nebula Logger' prefix & text formatting
    expect(console.debug.mock.calls[0][2]).toBe('🌟 FINEST: ' + componentLogEntry.message);
    expect(lightningLog).toHaveBeenCalledTimes(0);
  });

  it('calls lightning/logger.log for an FINEST entry when enabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isLightningLoggerEnabled: true });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'component log entry with loggingLevel FINEST';

    const componentLogEntry = logger.finest(message).getComponentLogEntry();

    await flushPromises('Resolve async task queue');
    expect(console.error).toHaveBeenCalledTimes(0);
    expect(console.warn).toHaveBeenCalledTimes(0);
    expect(console.info).toHaveBeenCalledTimes(0);
    expect(console.debug).toHaveBeenCalledTimes(0);
    expect(lightningLog).toHaveBeenCalledTimes(1);
    expect(lightningLog.mock.calls[0][0]).toBe(componentLogEntry);
  });

  it('sets browser details', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    await logger.getUserSettings();

    const logEntry = logger.info('example log entry').getComponentLogEntry();

    expect(logEntry.browser.address).toEqual(window.location.href);
    expect(logEntry.browser.formFactor).toEqual(FORM_FACTOR);
    expect(logEntry.browser.language).toEqual(window.navigator.language);
    expect(logEntry.browser.screenResolution).toEqual(window.screen.availWidth + ' x ' + window.screen.availHeight);
    expect(logEntry.browser.userAgent).toEqual(window.navigator.userAgent);
    expect(logEntry.browser.windowResolution).toEqual(window.innerWidth + ' x ' + window.innerHeight);
  });

  it('sets multiple custom fields', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    await logger.getUserSettings();
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    const firstFakeFieldName = 'SomeField__c';
    const firstFieldMockValue = 'something';
    const secondFakeFieldName = 'AnotherField__c';
    const secondFieldMockValue = 'another value';
    expect(logEntry.fieldToValue[firstFakeFieldName]).toBeFalsy();
    expect(logEntry.fieldToValue[secondFakeFieldName]).toBeFalsy();

    logEntryBuilder.setField({
      [firstFakeFieldName]: firstFieldMockValue,
      [secondFakeFieldName]: secondFieldMockValue
    });

    expect(logEntry.fieldToValue[firstFakeFieldName]).toEqual(firstFieldMockValue);
    expect(logEntry.fieldToValue[secondFakeFieldName]).toEqual(secondFieldMockValue);
  });

  it('sets recordId', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    await logger.getUserSettings();
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.recordId).toBeFalsy();
    const mockUserId = '0052F000008yLcEQAU';

    logEntryBuilder.setRecordId(mockUserId);

    expect(logEntry.recordId).toEqual(mockUserId);
  });

  it('sets record', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    await logger.getUserSettings();
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.record).toBeFalsy();
    const mockUserRecord = { Id: '0052F000008yLcEQAU', FirstName: 'Jonathan', LastName: 'Gillespie' };

    logEntryBuilder.setRecord(mockUserRecord);

    expect(logEntry.record).toEqual(mockUserRecord);
  });

  it('sets JavaScript error details', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    await logger.getUserSettings();
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.error).toBeFalsy();
    const error = new TypeError('oops');
    expect(error).toBeTruthy();
    expect(error.message).toBeTruthy();
    expect(error.stack).toBeTruthy();

    logEntryBuilder.setExceptionDetails(error);

    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual('JavaScript.TypeError');
  });

  it('sets Apex error details', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
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

    logEntryBuilder.setExceptionDetails(error);

    expect(logEntry.error.message).toEqual(error.body.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual(error.body.exceptionType);
  });

  it('adds tags', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.recordId).toBeFalsy();
    const mockTags = ['first tag', 'second tag', 'third tag'];

    logEntryBuilder.addTags(mockTags);

    expect(logEntry.tags.length).toEqual(mockTags.length);
  });

  it('deduplicates tags', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.recordId).toBeFalsy();
    const mockTags = ['duplicate tag', 'duplicate tag'];
    expect(mockTags.length).toEqual(2);
    expect(new Set(mockTags).size).toEqual(1);

    for (let i = 0; i < mockTags.length; i++) {
      logEntryBuilder.addTag(mockTags[i]);
    }

    expect(logEntry.tags.length).toEqual(1);
  });

  it('auto-saves log & throws exception', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const message = 'some message';
    const mockError = new TypeError('oops');
    let thrownError;

    try {
      logger.exception(message, mockError);
    } catch (error) {
      thrownError = error;
    }

    expect(thrownError).toBe(mockError);
    await flushPromises('Resolve async task queue');
    expect(logger.getBufferSize()).toBe(0);
    expect(saveComponentLogEntries).toHaveBeenCalledTimes(1);
    expect(saveComponentLogEntries.mock.calls[0][0].componentLogEntries.length).toEqual(1);
    const savedComponentLogEntry = saveComponentLogEntries.mock.calls[0][0].componentLogEntries[0];
    expect(savedComponentLogEntry.loggingLevel).toEqual('ERROR');
    expect(savedComponentLogEntry.message).toEqual(message);
  });

  it('still works for ERROR logging level when disabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const settings = logger.getUserSettings({ forceReload: true });
    expect(settings.isEnabled).toEqual(false);
    const error = new TypeError('oops');

    const logEntry = logger
      .error('example ERROR log entry')
      .setMessage('some message')
      .setRecordId('some_record_Id')
      .setRecord({ Id: 'some_record_Id' })
      .setExceptionDetails(error)
      .addTag('a tag')
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual('JavaScript.TypeError');
    expect(logEntry.loggingLevel).toEqual('ERROR');
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    expect(logEntry.timestamp).toBeTruthy();
  });

  it('still works for WARN logging level when disabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const settings = await logger.getUserSettings({ forceReload: true });
    expect(settings.isEnabled).toEqual(false);
    const error = new TypeError('oops');

    const logEntry = logger
      .warn('example WARN log entry')
      .setMessage('some message')
      .setRecordId('some_record_Id')
      .setRecord({ Id: 'some_record_Id' })
      .setExceptionDetails(error)
      .addTag('a tag')
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual('JavaScript.TypeError');
    expect(logEntry.loggingLevel).toEqual('WARN');
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    expect(logEntry.timestamp).toBeTruthy();
  });

  it('still works for INFO logging level when disabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const settings = await logger.getUserSettings({ forceReload: true });
    expect(settings.isEnabled).toEqual(false);
    const error = new TypeError('oops');

    const logEntry = logger
      .info('example INFO log entry')
      .setMessage('some message')
      .setRecordId('some_record_Id')
      .setRecord({ Id: 'some_record_Id' })
      .setExceptionDetails(error)
      .addTag('a tag')
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual('JavaScript.TypeError');
    expect(logEntry.loggingLevel).toEqual('INFO');
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    expect(logEntry.timestamp).toBeTruthy();
  });

  it('still works for DEBUG logging level when disabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const settings = await logger.getUserSettings({ forceReload: true });
    expect(settings.isEnabled).toEqual(false);
    const error = new TypeError('oops');

    const logEntry = logger
      .debug('example DEBUG log entry')
      .setMessage('some message')
      .setRecordId('some_record_Id')
      .setRecord({ Id: 'some_record_Id' })
      .setExceptionDetails(error)
      .addTag('a tag')
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual('JavaScript.TypeError');
    expect(logEntry.loggingLevel).toEqual('DEBUG');
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    expect(logEntry.timestamp).toBeTruthy();
  });

  it('still works for FINE logging level when disabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const settings = await logger.getUserSettings({ forceReload: true });
    expect(settings.isEnabled).toEqual(false);
    const error = new TypeError('oops');

    const logEntry = logger
      .fine('example FINE log entry')
      .setMessage('some message')
      .setRecordId('some_record_Id')
      .setRecord({ Id: 'some_record_Id' })
      .setExceptionDetails(error)
      .addTag('a tag')
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual('JavaScript.TypeError');
    expect(logEntry.loggingLevel).toEqual('FINE');
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    expect(logEntry.timestamp).toBeTruthy();
  });

  it('still works for FINER logging level when disabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const settings = await logger.getUserSettings({ forceReload: true });
    expect(settings.isEnabled).toEqual(false);
    const error = new TypeError('oops');

    const logEntry = logger
      .finer('example FINER log entry')
      .setMessage('some message')
      .setRecordId('some_record_Id')
      .setRecord({ Id: 'some_record_Id' })
      .setExceptionDetails(error)
      .addTag('a tag')
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual('JavaScript.TypeError');
    expect(logEntry.loggingLevel).toEqual('FINER');
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    expect(logEntry.timestamp).toBeTruthy();
  });

  it('still works for FINEST logging level when disabled', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const settings = await logger.getUserSettings({ forceReload: true });
    expect(settings.isEnabled).toEqual(false);
    const error = new TypeError('oops');

    const logEntry = logger
      .finest('example FINEST log entry')
      .setMessage('some message')
      .setRecordId('some_record_Id')
      .setRecord({ Id: 'some_record_Id' })
      .setExceptionDetails(error)
      .addTag('a tag')
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual('JavaScript.TypeError');
    expect(logEntry.loggingLevel).toEqual('FINEST');
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    expect(logEntry.timestamp).toBeTruthy();
  });

  it('flushes buffer', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    await logger.getUserSettings({ forceReload: true });
    const numberOfLogEntries = 3;
    for (let i = 0; i < numberOfLogEntries; i++) {
      logger.info('entry number: ' + i);
    }
    expect(logger.getBufferSize()).toEqual(numberOfLogEntries);

    await logger.flushBuffer();

    expect(logger.getBufferSize()).toEqual(0);
  });

  it('saves log entries and flushes buffer', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    await logger.getUserSettings({ forceReload: true });
    const firstEntryBuilder = logger.info('example INFO log entry added BEFORE saveLog()');
    const secondEntryBuilder = logger.debug('example DEBUG log entry added BEFORE saveLog()');
    await flushPromises();
    expect(logger.getBufferSize()).toBe(2);

    logger.saveLog();
    logger.warn('example WARN log entry added AFTER saveLog()');

    await flushPromises('Resolve async task queue');
    expect(logger.getBufferSize()).toBe(1);
    expect(saveComponentLogEntries).toHaveBeenCalledTimes(1);
    const expectedApexParameter = {
      componentLogEntries: [firstEntryBuilder.getComponentLogEntry(), secondEntryBuilder.getComponentLogEntry()],
      saveMethodName: undefined
    };
    expect(saveComponentLogEntries.mock.calls[0][0]).toEqual(expectedApexParameter);
  });
});

describe('logger lwc deprecated async createLogger() import tests', () => {
  beforeEach(() => {
    disableSystemMessages();
    // One of logger's features (when enabled) is to auto-call the browser's console
    // so devs can see a log entry easily. But during Jest tests, seeing all of the
    // console statements is... a bit overwhelming, so the global console functions
    // are overwritten with an empty function so they're no-ops / they don't show up
    // in the test logs
    const emptyFunction = () => '';
    console.error = emptyFunction;
    console.warn = emptyFunction;
    console.info = emptyFunction;
    console.debug = emptyFunction;
  });
  afterEach(async () => {
    jest.clearAllMocks();
  });

  it('returns user settings when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();

    const userSettings = logger.getUserSettings();

    expect(userSettings.defaultSaveMethod).toEqual('EVENT_BUS');
    expect(userSettings.isEnabled).toEqual(true);
    expect(userSettings.isConsoleLoggingEnabled).toEqual(false);
    expect(userSettings.isLightningLoggerEnabled).toEqual(false);
  });

  it('sets a scenario on all subsequent entries when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    // const logger = getLogger();
    // getLogger() is built to be sync, but internally, some async tasks must execute
    // before some sync tasks are executed
    await flushPromises('Resolve async task queue');
    const logger = await createLogger();
    const scenario = 'some scenario';
    const message = 'some message';

    const firstLogEntry = logger.finest(message).getComponentLogEntry();
    logger.setScenario(scenario);
    const secondLogEntry = logger.info(message).getComponentLogEntry();

    expect(firstLogEntry.scenario).toBeUndefined();
    expect(secondLogEntry.scenario).toEqual(scenario);
  });

  it('logs an ERROR entry when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();
    const message = 'component log entry with loggingLevel ERROR';

    const logEntry = logger.error(message).getComponentLogEntry();

    await flushPromises();
    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('ERROR');
    expect(logEntry.message).toEqual(message);
  });

  it('logs a WARN entry when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();
    const message = 'component log entry with loggingLevel WARN';

    const logEntry = logger.warn(message).getComponentLogEntry();

    await flushPromises();
    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('WARN');
    expect(logEntry.message).toEqual(message);
  });

  it('logs an INFO entry when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();
    const message = 'component log entry with loggingLevel INFO';

    const logEntry = logger.info(message).getComponentLogEntry();

    await flushPromises();
    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('INFO');
    expect(logEntry.message).toEqual(message);
  });

  it('logs a DEBUG entry when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();
    const message = 'component log entry with loggingLevel DEBUG';

    const logEntry = logger.debug(message).getComponentLogEntry();

    await flushPromises();
    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('DEBUG');
    expect(logEntry.message).toEqual(message);
  });

  it('logs a FINE entry when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();
    const message = 'component log entry with loggingLevel FINE';

    const logEntry = logger.fine(message).getComponentLogEntry();

    await flushPromises();
    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('FINE');
    expect(logEntry.message).toEqual(message);
  });

  it('logs a FINER entry when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();
    const message = 'component log entry with loggingLevel FINER';

    const logEntry = logger.finer(message).getComponentLogEntry();

    await flushPromises();
    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('FINER');
    expect(logEntry.message).toEqual(message);
  });

  it('logs a FINEST entry when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();
    const message = 'component log entry with loggingLevel FINEST';

    const logEntry = logger.finest(message).getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('FINEST');
    expect(logEntry.message).toEqual(message);
  });

  it('sets browser details when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();
    await logger.getUserSettings();

    const logEntry = logger.info('example log entry').getComponentLogEntry();

    expect(logEntry.browser.address).toEqual(window.location.href);
    expect(logEntry.browser.formFactor).toEqual(FORM_FACTOR);
    expect(logEntry.browser.language).toEqual(window.navigator.language);
    expect(logEntry.browser.screenResolution).toEqual(window.screen.availWidth + ' x ' + window.screen.availHeight);
    expect(logEntry.browser.userAgent).toEqual(window.navigator.userAgent);
    expect(logEntry.browser.windowResolution).toEqual(window.innerWidth + ' x ' + window.innerHeight);
  });

  it('sets multiple custom fields when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();
    await logger.getUserSettings();
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    const firstFakeFieldName = 'SomeField__c';
    const firstFieldMockValue = 'something';
    const secondFakeFieldName = 'AnotherField__c';
    const secondFieldMockValue = 'another value';
    expect(logEntry.fieldToValue[firstFakeFieldName]).toBeFalsy();
    expect(logEntry.fieldToValue[secondFakeFieldName]).toBeFalsy();

    logEntryBuilder.setField({
      [firstFakeFieldName]: firstFieldMockValue,
      [secondFakeFieldName]: secondFieldMockValue
    });

    expect(logEntry.fieldToValue[firstFakeFieldName]).toEqual(firstFieldMockValue);
    expect(logEntry.fieldToValue[secondFakeFieldName]).toEqual(secondFieldMockValue);
  });

  it('sets recordId when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();
    await logger.getUserSettings();
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.recordId).toBeFalsy();
    const mockUserId = '0052F000008yLcEQAU';

    logEntryBuilder.setRecordId(mockUserId);

    expect(logEntry.recordId).toEqual(mockUserId);
  });

  it('sets record when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();
    await logger.getUserSettings();
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.record).toBeFalsy();
    const mockUserRecord = { Id: '0052F000008yLcEQAU', FirstName: 'Jonathan', LastName: 'Gillespie' };

    logEntryBuilder.setRecord(mockUserRecord);

    expect(logEntry.record).toEqual(mockUserRecord);
  });

  it('sets JavaScript error details when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();
    await logger.getUserSettings();
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.error).toBeFalsy();
    const error = new TypeError('oops');
    expect(error).toBeTruthy();
    expect(error.message).toBeTruthy();
    expect(error.stack).toBeTruthy();

    logEntryBuilder.setError(error);

    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual('JavaScript.TypeError');
  });

  it('sets Apex error details when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
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

    logEntryBuilder.setError(error);

    expect(logEntry.error.message).toEqual(error.body.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual(error.body.exceptionType);
  });

  it('adds tags when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.recordId).toBeFalsy();
    const mockTags = ['first tag', 'second tag', 'third tag'];

    logEntryBuilder.addTags(mockTags);

    expect(logEntry.tags.length).toEqual(mockTags.length);
  });

  it('deduplicates tags when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.recordId).toBeFalsy();
    const mockTags = ['duplicate tag', 'duplicate tag'];
    expect(mockTags.length).toEqual(2);
    expect(new Set(mockTags).size).toEqual(1);

    for (let i = 0; i < mockTags.length; i++) {
      logEntryBuilder.addTag(mockTags[i]);
    }

    expect(logEntry.tags.length).toEqual(1);
  });

  it('auto-saves log & throws exception when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();
    const message = 'some message';
    const mockError = new TypeError('oops');
    let thrownError;

    try {
      logger.exception(message, mockError);
    } catch (error) {
      thrownError = error;
    }

    expect(thrownError).toBe(mockError);
    await flushPromises('Resolve async task queue');
    expect(logger.getBufferSize()).toBe(0);
    expect(saveComponentLogEntries).toHaveBeenCalledTimes(1);
    expect(saveComponentLogEntries.mock.calls[0][0].componentLogEntries.length).toEqual(1);
    const savedComponentLogEntry = saveComponentLogEntries.mock.calls[0][0].componentLogEntries[0];
    expect(savedComponentLogEntry.loggingLevel).toEqual('ERROR');
    expect(savedComponentLogEntry.message).toEqual(message);
  });

  it('still works for ERROR logging level when disabled when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = await createLogger();
    const settings = logger.getUserSettings({ forceReload: true });
    expect(settings.isEnabled).toEqual(false);
    const error = new TypeError('oops');

    const logEntry = logger
      .error('example ERROR log entry')
      .setMessage('some message')
      .setRecordId('some_record_Id')
      .setRecord({ Id: 'some_record_Id' })
      .setError(error)
      .addTag('a tag')
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    await flushPromises();
    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual('JavaScript.TypeError');
    expect(logEntry.loggingLevel).toEqual('ERROR');
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    expect(logEntry.timestamp).toBeTruthy();
  });

  it('still works for WARN logging level when disabled when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = await createLogger();
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
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    await flushPromises();
    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual('JavaScript.TypeError');
    expect(logEntry.loggingLevel).toEqual('WARN');
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    expect(logEntry.timestamp).toBeTruthy();
  });

  it('still works for INFO logging level when disabled when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = await createLogger();
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
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    await flushPromises();
    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual('JavaScript.TypeError');
    expect(logEntry.loggingLevel).toEqual('INFO');
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    expect(logEntry.timestamp).toBeTruthy();
  });

  it('still works for DEBUG logging level when disabled when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = await createLogger();
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
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    await flushPromises();
    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual('JavaScript.TypeError');
    expect(logEntry.loggingLevel).toEqual('DEBUG');
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    expect(logEntry.timestamp).toBeTruthy();
  });

  it('still works for FINE logging level when disabled when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = await createLogger();
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
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    await flushPromises();
    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual('JavaScript.TypeError');
    expect(logEntry.loggingLevel).toEqual('FINE');
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    expect(logEntry.timestamp).toBeTruthy();
  });

  it('still works for FINER logging level when disabled when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = await createLogger();
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
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    await flushPromises();
    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual('JavaScript.TypeError');
    expect(logEntry.loggingLevel).toEqual('FINER');
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    expect(logEntry.timestamp).toBeTruthy();
  });

  it('still works for FINEST logging level when disabled when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = await createLogger();
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
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    await flushPromises();
    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual('JavaScript.TypeError');
    expect(logEntry.loggingLevel).toEqual('FINEST');
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
    expect(logEntry.timestamp).toBeTruthy();
  });

  it('flushes buffer when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();
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

  it('saves log entries and flushes buffer when using deprecated async createLogger() import approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await createLogger();
    const firstEntryBuilder = logger.info('example INFO log entry added BEFORE saveLog()');
    const secondEntryBuilder = logger.debug('example DEBUG log entry added BEFORE saveLog()');
    await flushPromises();
    expect(logger.getBufferSize()).toBe(2);

    logger.saveLog();
    logger.warn('example WARN log entry added AFTER saveLog()');

    await flushPromises('Resolve async task queue');
    expect(logger.getBufferSize()).toBe(1);
    expect(saveComponentLogEntries).toHaveBeenCalledTimes(1);
    const expectedApexParameter = {
      componentLogEntries: [firstEntryBuilder.getComponentLogEntry(), secondEntryBuilder.getComponentLogEntry()],
      saveMethodName: undefined
    };
    expect(saveComponentLogEntries.mock.calls[0][0]).toEqual(expectedApexParameter);
  });
});

describe('logger lwc legacy markup tests', () => {
  beforeEach(() => {
    disableSystemMessages();
    // One of logger's features (when enabled) is to auto-call the browser's console
    // so devs can see a log entry easily. But during Jest tests, seeing all of the
    // console statements is... a bit overwhelming, so the global console functions
    // are overwritten with an empty function so they're no-ops / they don't show up
    // in the test logs
    const emptyFunction = () => '';
    console.error = emptyFunction;
    console.warn = emptyFunction;
    console.info = emptyFunction;
    console.debug = emptyFunction;
  });
  afterEach(async () => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it('returns user settings when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();

    const userSettings = await logger.getUserSettings();

    expect(userSettings.defaultSaveMethod).toEqual('EVENT_BUS');
    expect(userSettings.isEnabled).toEqual(true);
    expect(userSettings.isConsoleLoggingEnabled).toEqual(false);
    expect(userSettings.isLightningLoggerEnabled).toEqual(false);
  });

  it('sets a scenario on all subsequent entries when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();
    const scenario = 'some scenario';
    const message = 'some message';

    const firstLogEntry = logger.finest(message).getComponentLogEntry();
    logger.setScenario(scenario);
    const secondLogEntry = logger.info(message).getComponentLogEntry();

    expect(firstLogEntry.scenario).toBeUndefined();
    expect(secondLogEntry.scenario).toEqual(scenario);
  });

  it('logs an ERROR entry when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();

    const message = 'component log entry with loggingLevel ERROR';
    const logEntry = await logger.error(message).getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('ERROR');
    expect(logEntry.message).toEqual(message);
  });

  it('logs a WARN entry when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();

    const message = 'component log entry with loggingLevel WARN';
    const logEntry = await logger.warn(message).getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('WARN');
    expect(logEntry.message).toEqual(message);
  });

  it('logs an INFO entry when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();

    const message = 'component log entry with loggingLevel INFO';
    const logEntry = logger.info(message).getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('INFO');
    expect(logEntry.message).toEqual(message);
  });

  it('logs a DEBUG entry when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();

    const message = 'component log entry with loggingLevel DEBUG';
    const logEntry = await logger.debug(message).getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('DEBUG');
    expect(logEntry.message).toEqual(message);
  });

  it('logs a FINE entry when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();

    const message = 'component log entry with loggingLevel FINE';
    const logEntry = await logger.fine(message).getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('FINE');
    expect(logEntry.message).toEqual(message);
  });

  it('logs a FINER entry when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();

    const message = 'component log entry with loggingLevel FINER';
    const logEntry = await logger.finer(message).getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('FINER');
    expect(logEntry.message).toEqual(message);
  });

  it('logs a FINEST entry when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();

    const message = 'component log entry with loggingLevel FINEST';
    const logEntry = await logger.finest(message).getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(1);
    expect(logEntry.loggingLevel).toEqual('FINEST');
    expect(logEntry.message).toEqual(message);
  });

  it('sets browser details when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();

    const logEntry = await logger.info('example log entry').getComponentLogEntry();

    expect(logEntry.browser.address).toEqual(window.location.href);
    expect(logEntry.browser.formFactor).toEqual(FORM_FACTOR);
    expect(logEntry.browser.language).toEqual(window.navigator.language);
    expect(logEntry.browser.screenResolution).toEqual(window.screen.availWidth + ' x ' + window.screen.availHeight);
    expect(logEntry.browser.userAgent).toEqual(window.navigator.userAgent);
    expect(logEntry.browser.windowResolution).toEqual(window.innerWidth + ' x ' + window.innerHeight);
  });

  it('sets multiple custom fields when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();
    const logEntryBuilder = await logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    const firstFakeFieldName = 'SomeField__c';
    const firstFieldMockValue = 'something';
    const secondFakeFieldName = 'AnotherField__c';
    const secondFieldMockValue = 'another value';
    expect(logEntry.fieldToValue[firstFakeFieldName]).toBeFalsy();
    expect(logEntry.fieldToValue[secondFakeFieldName]).toBeFalsy();

    logEntryBuilder.setField({
      [firstFakeFieldName]: firstFieldMockValue,
      [secondFakeFieldName]: secondFieldMockValue
    });

    expect(logEntry.fieldToValue[firstFakeFieldName]).toEqual(firstFieldMockValue);
    expect(logEntry.fieldToValue[secondFakeFieldName]).toEqual(secondFieldMockValue);
  });

  it('sets recordId when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();
    const logEntryBuilder = await logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.recordId).toBeFalsy();

    const mockUserId = '0052F000008yLcEQAU';
    logEntryBuilder.setRecordId(mockUserId);

    expect(logEntry.recordId).toEqual(mockUserId);
  });

  it('sets record when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();
    const logEntryBuilder = await logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.record).toBeFalsy();
    const mockUserRecord = { Id: '0052F000008yLcEQAU', FirstName: 'Jonathan', LastName: 'Gillespie' };

    logEntryBuilder.setRecord(mockUserRecord);

    expect(logEntry.record).toEqual(mockUserRecord);
  });

  it('sets JavaScript error details when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();
    const logEntryBuilder = await logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.error).toBeFalsy();
    const error = new TypeError('oops');
    expect(error).toBeTruthy();
    expect(error.message).toBeTruthy();
    expect(error.stack).toBeTruthy();

    logEntryBuilder.setError(error);

    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.error.type).toEqual('JavaScript.TypeError');
  });

  it('sets Apex error details when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
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

    logEntryBuilder.setError(error);

    expect(logEntry.error.message).toEqual(error.body.message);
    expect(logEntry.error.stackTrace).toEqual(error.body.stackTrace);
    expect(logEntry.error.type).toEqual(error.body.exceptionType);
  });

  it('adds tags when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.recordId).toBeFalsy();
    const mockTags = ['first tag', 'second tag', 'third tag'];

    logEntryBuilder.addTags(mockTags);

    expect(logEntry.tags.length).toEqual(mockTags.length);
  });

  it('deduplicates tags when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.recordId).toBeFalsy();
    const mockTags = ['duplicate tag', 'duplicate tag'];
    expect(mockTags.length).toEqual(2);
    expect(new Set(mockTags).size).toEqual(1);

    for (let i = 0; i < mockTags.length; i++) {
      logEntryBuilder.addTag(mockTags[i]);
    }

    expect(logEntry.tags.length).toEqual(1);
  });

  it('auto-saves log & throws exception when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();
    const message = 'some message';
    const mockError = new TypeError('oops');
    let thrownError;

    try {
      logger.exception(message, mockError);
    } catch (error) {
      thrownError = error;
    }

    expect(thrownError).toBe(mockError);
    await flushPromises('Resolve async task queue');
    expect(logger.getBufferSize()).toBe(0);
    expect(saveComponentLogEntries).toHaveBeenCalledTimes(1);
    expect(saveComponentLogEntries.mock.calls[0][0].componentLogEntries.length).toEqual(1);
    const savedComponentLogEntry = saveComponentLogEntries.mock.calls[0][0].componentLogEntries[0];
    expect(savedComponentLogEntry.loggingLevel).toEqual('ERROR');
    expect(savedComponentLogEntry.message).toEqual(message);
  });

  it('still works for ERROR logging level when disabled when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();
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
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.loggingLevel).toEqual('ERROR');
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.error).toBeTruthy();
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.timestamp).toBeTruthy();
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
  });

  it('still works for WARN logging level when disabled when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();
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
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.loggingLevel).toEqual('WARN');
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.error).toBeTruthy();
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.timestamp).toBeTruthy();
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
  });

  it('still works for INFO logging level when disabled when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();
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
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.loggingLevel).toEqual('INFO');
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.error).toBeTruthy();
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.timestamp).toBeTruthy();
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
  });

  it('still works for DEBUG logging level when disabled when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();
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
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.loggingLevel).toEqual('DEBUG');
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.error).toBeTruthy();
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.timestamp).toBeTruthy();
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
  });

  it('still works for FINE logging level when disabled when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();
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
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.loggingLevel).toEqual('FINE');
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.error).toBeTruthy();
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.timestamp).toBeTruthy();
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
  });

  it('still works for FINER logging level when disabled when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();
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
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.loggingLevel).toEqual('FINER');
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.error).toBeTruthy();
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.timestamp).toBeTruthy();
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
  });

  it('still works for FINEST logging level when disabled when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();
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
      .addTags(['a second tag', 'a third tag'])
      .getComponentLogEntry();

    await flushPromises();
    expect(logger.getBufferSize()).toEqual(0);
    expect(logEntry.loggingLevel).toEqual('FINEST');
    expect(logEntry.recordId).toEqual('some_record_Id');
    expect(logEntry.record).toEqual({ Id: 'some_record_Id' });
    expect(logEntry.error).toBeTruthy();
    expect(logEntry.originStackTrace).toBeTruthy();
    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace).toBeTruthy();
    expect(logEntry.timestamp).toBeTruthy();
    expect(logEntry.tags).toEqual(['a tag', 'a second tag', 'a third tag']);
  });

  it('flushes buffer when using deprecated markup approach', async () => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = createElement('c-logger', { is: Logger });
    document.body.appendChild(logger);
    await flushPromises();
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
    await flushPromises('Resolve async task queue');
    await logger.getUserSettings({ forceReload: true });
    const firstEntryBuilder = logger.info('example INFO log entry added BEFORE saveLog()');
    const secondEntryBuilder = logger.debug('example DEBUG log entry added BEFORE saveLog()');
    await flushPromises();
    expect(logger.getBufferSize()).toBe(2);

    logger.saveLog();
    logger.warn('example WARN log entry added AFTER saveLog()');

    await flushPromises('Resolve async task queue');
    expect(logger.getBufferSize()).toBe(1);
    expect(saveComponentLogEntries).toHaveBeenCalledTimes(1);
    const expectedApexParameter = {
      componentLogEntries: [firstEntryBuilder.getComponentLogEntry(), secondEntryBuilder.getComponentLogEntry()],
      saveMethodName: undefined
    };
    expect(saveComponentLogEntries.mock.calls[0][0]).toEqual(expectedApexParameter);
  });
});
