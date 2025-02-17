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

const getMarkupLogger = async () => {
  const logger = createElement('c-logger', { is: Logger });
  document.body.appendChild(logger);
  await flushPromises();
  return logger;
};

describe('logger tests', () => {
  beforeAll(() => {
    disableSystemMessages();
    setTimeout = callbackFunction => callbackFunction();
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

  it('calls console.info a single time on initialization', async () => {
    // this test is non-parameterized due to issues with console.info
    // being actually set to jest.fn() in it.each calls
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    enableSystemMessages();
    const logger = getLogger();
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

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('returns user settings', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();

    const userSettings = logger.getUserSettings();

    expect(userSettings.defaultSaveMethod).toEqual('EVENT_BUS');
    expect(userSettings.isEnabled).toEqual(true);
    expect(userSettings.isConsoleLoggingEnabled).toEqual(false);
    expect(userSettings.isLightningLoggerEnabled).toEqual(false);
  });

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('sets a scenario on all subsequent entries', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
    await flushPromises('Resolve async task queue');
    const scenario = 'some scenario';
    const message = 'some message';

    const firstLogEntry = logger.finest(message).getComponentLogEntry();
    logger.setScenario(scenario);
    const secondLogEntry = logger.info(message).getComponentLogEntry();

    expect(firstLogEntry.scenario).toBeUndefined();
    expect(secondLogEntry.scenario).toEqual(scenario);
  });

  it.each([
    [getLogger, 'getLogger'],
    [createLogger, 'createLogger'],
    [getMarkupLogger, 'markupLogger']
  ])('logs an ERROR entry', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
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

  it.each([
    [getLogger, 'getLogger'],
    [createLogger, 'createLogger'],
    [getMarkupLogger, 'markupLogger']
  ])('calls console.error for an ERROR entry when enabled', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isConsoleLoggingEnabled: true });
    const logger = await loggingFunction();
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

  it.each([
    [getLogger, 'getLogger'],
    [createLogger, 'createLogger'],
    [getMarkupLogger, 'markupLogger']
  ])('calls lightning/logger.log for an ERROR entry when enabled', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isLightningLoggerEnabled: true });
    const logger = await loggingFunction();
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

  it.each([
    [getLogger, 'getLogger'],
    [createLogger, 'createLogger'],
    [getMarkupLogger, 'markupLogger']
  ])('logs a WARN entry', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
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

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('logs an INFO entry', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
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

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('logs a DEBUG entry', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
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

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('logs a FINE entry', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
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

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('logs a FINER entry', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
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

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('logs a FINEST entry', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
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

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('sets browser details', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
    await flushPromises('Resolve async task queue');

    const logEntry = logger.info('example log entry').getComponentLogEntry();

    expect(logEntry.browser.address).toEqual(window.location.href);
    expect(logEntry.browser.formFactor).toEqual(FORM_FACTOR);
    expect(logEntry.browser.language).toEqual(window.navigator.language);
    expect(logEntry.browser.screenResolution).toEqual(window.screen.availWidth + ' x ' + window.screen.availHeight);
    expect(logEntry.browser.userAgent).toEqual(window.navigator.userAgent);
    expect(logEntry.browser.windowResolution).toEqual(window.innerWidth + ' x ' + window.innerHeight);
  });

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('sets multiple custom component fields on subsequent entries', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
    await flushPromises('Resolve async task queue');
    const firstFakeFieldName = 'SomeField__c';
    const firstFieldMockValue = 'something';
    const secondFakeFieldName = 'AnotherField__c';
    const secondFieldMockValue = 'another value';

    const previousLogEntry = logger.info('example log entry from before setField() is called').getComponentLogEntry();
    logger.setField({
      [firstFakeFieldName]: firstFieldMockValue,
      [secondFakeFieldName]: secondFieldMockValue
    });
    const subsequentLogEntry = logger.info('example log entry from after setField() is called').getComponentLogEntry();

    expect(previousLogEntry.fieldToValue[firstFakeFieldName]).toBeUndefined();
    expect(previousLogEntry.fieldToValue[secondFakeFieldName]).toBeUndefined();
    expect(subsequentLogEntry.fieldToValue[firstFakeFieldName]).toEqual(firstFieldMockValue);
    expect(subsequentLogEntry.fieldToValue[secondFakeFieldName]).toEqual(secondFieldMockValue);
  });

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('sets multiple custom entry fields on a single entry', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
    await flushPromises('Resolve async task queue');
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

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('sets recordId', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
    await flushPromises('Resolve async task queue');
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.recordId).toBeFalsy();
    const mockUserId = '0052F000008yLcEQAU';

    logEntryBuilder.setRecordId(mockUserId);

    expect(logEntry.recordId).toEqual(mockUserId);
  });

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('sets record', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
    await flushPromises('Resolve async task queue');
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.record).toBeFalsy();
    const mockUserRecord = { Id: '0052F000008yLcEQAU', FirstName: 'Jonathan', LastName: 'Gillespie' };

    logEntryBuilder.setRecord(mockUserRecord);

    expect(logEntry.record).toEqual(mockUserRecord);
  });

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('sets JavaScript error details', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
    await flushPromises('Resolve async task queue');
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.error).toBeFalsy();
    const error = new TypeError('oops');
    expect(error).toBeTruthy();
    expect(error.message).toBeTruthy();
    expect(error.stack).toBeTruthy();

    logEntryBuilder.setExceptionDetails(error);

    expect(logEntry.error.message).toEqual(error.message);
    expect(logEntry.error.stackTrace.stackTraceString).toEqual(error.stackTrace);
    expect(logEntry.error.type).toEqual('JavaScript.TypeError');
  });

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('sets Apex error details', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
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
    expect(logEntry.error.stackTrace.metadataType).toEqual('ApexClass');
    expect(logEntry.error.stackTrace.className).toEqual('SomeApexClass');
    expect(logEntry.error.stackTrace.methodName).toEqual('runSomeMethod');
    expect(logEntry.error.stackTrace.stackTraceString).toEqual(error.body.stackTrace);
    expect(logEntry.error.type).toEqual(error.body.exceptionType);
  });

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('adds tags', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
    await flushPromises('Resolve async task queue');
    const logEntryBuilder = logger.info('example log entry');
    const logEntry = logEntryBuilder.getComponentLogEntry();
    expect(logEntry.recordId).toBeFalsy();
    const mockTags = ['first tag', 'second tag', 'third tag'];

    logEntryBuilder.addTags(mockTags);

    expect(logEntry.tags.length).toEqual(mockTags.length);
  });

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('deduplicates tags', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
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

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('auto-saves log & throws exception', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
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

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('still works for ERROR logging level when disabled', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = await loggingFunction();
    await flushPromises('Resolve async task queue');
    const settings = logger.getUserSettings();
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

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('still works for WARN logging level when disabled', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = await loggingFunction();
    await flushPromises('Resolve async task queue');
    const settings = await logger.getUserSettings();
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

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('still works for INFO logging level when disabled', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = await loggingFunction();
    await flushPromises('Resolve async task queue');
    const settings = await logger.getUserSettings();
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

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('still works for DEBUG logging level when disabled', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = await loggingFunction();
    await flushPromises('Resolve async task queue');
    const settings = await logger.getUserSettings();
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

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('still works for FINE logging level when disabled', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = await loggingFunction();
    await flushPromises('Resolve async task queue');
    const settings = await logger.getUserSettings();
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

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('still works for FINER logging level when disabled', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = await loggingFunction();
    await flushPromises('Resolve async task queue');
    const settings = await logger.getUserSettings();
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

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('still works for FINEST logging level when disabled', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isEnabled: false });
    const logger = await loggingFunction();
    await flushPromises('Resolve async task queue');
    const settings = await logger.getUserSettings();
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

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('flushes buffer', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
    await flushPromises('Resolve async task queue');
    const numberOfLogEntries = 3;
    for (let i = 0; i < numberOfLogEntries; i++) {
      logger.info('entry number: ' + i);
    }
    expect(logger.getBufferSize()).toEqual(numberOfLogEntries);

    await logger.flushBuffer();

    expect(logger.getBufferSize()).toEqual(0);
  });

  it.each([[createLogger], [getLogger], [getMarkupLogger]])('saves log entries and flushes buffer', async loggingFunction => {
    getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
    const logger = await loggingFunction();
    await flushPromises('Resolve async task queue');
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
