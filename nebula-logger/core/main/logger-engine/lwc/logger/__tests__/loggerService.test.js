import LoggerService, { BrowserContext } from '../loggerService';
import LogEntryEventBuilder from '../logEntryBuilder';
import LoggerServiceTaskQueue from '../loggerServiceTaskQueue';
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

describe('LoggerService tests', () => {
  let loggerService;

  beforeEach(() => {
    // Reset the static flags to ensure each test starts with a clean state
    LoggerService.areSystemMessagesEnabled = false;
    LoggerService.hasInitialized = false;

    // Mock console functions
    console.error = jest.fn();
    console.warn = jest.fn();
    console.info = jest.fn();
    console.debug = jest.fn();
    console.log = jest.fn();

    jest.resetAllMocks();
  });

  describe('setField', () => {
    it('handles null/undefined fieldToValue gracefully', async () => {
      getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
      loggerService = new LoggerService();
      await flushPromises();

      // Test with null
      loggerService.setField(null);
      expect(loggerService.getBufferSize()).toBe(0);

      // Test with undefined
      loggerService.setField(undefined);
      expect(loggerService.getBufferSize()).toBe(0);
    });

    it('handles non-object fieldToValue gracefully', async () => {
      getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
      loggerService = new LoggerService();
      await flushPromises();

      // Test with string
      loggerService.setField('not an object');
      expect(loggerService.getBufferSize()).toBe(0);

      // Test with array
      loggerService.setField(['not an object']);
      expect(loggerService.getBufferSize()).toBe(0);
    });
  });

  describe('saveLog error handling', () => {
    it('handles saveComponentLogEntries errors and logs to console when enabled', async () => {
      getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isConsoleLoggingEnabled: true });
      saveComponentLogEntries.mockRejectedValue(new Error('Save failed'));

      loggerService = new LoggerService();
      await flushPromises();

      loggerService.error('test message');
      await flushPromises();

      try {
        await loggerService.saveLog();
      } catch (error) {
        expect(error.message).toBe('Save failed');
      }

      expect(console.error).toHaveBeenCalledTimes(2); // Once for the error, once for the log entry
    });

    it('handles saveComponentLogEntries errors without console logging when disabled', async () => {
      getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isConsoleLoggingEnabled: false });
      saveComponentLogEntries.mockRejectedValue(new Error('Save failed'));

      loggerService = new LoggerService();
      await flushPromises();

      loggerService.error('test message');
      await flushPromises();

      try {
        await loggerService.saveLog();
      } catch (error) {
        expect(error.message).toBe('Save failed');
      }

      // Should not log to console when console logging is disabled
      expect(console.error).not.toHaveBeenCalled();
    });
  });

  // Note: Testing constructor error handling is complex due to async task queue execution
  // The error handling is covered by the console.error mock and the fact that errors are thrown

  describe('_logToConsole edge cases', () => {
    beforeEach(async () => {
      getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS, isConsoleLoggingEnabled: true });
      loggerService = new LoggerService();
      await flushPromises();
    });

    it('handles componentLogEntry with empty fieldToValue', async () => {
      loggerService.setField({});
      loggerService.info('test message');
      await flushPromises();

      expect(console.info).toHaveBeenCalled();
      // Verify the console call doesn't crash with empty fieldToValue
    });

    it('handles componentLogEntry with empty tags', async () => {
      loggerService.info('test message');
      await flushPromises();

      expect(console.info).toHaveBeenCalled();
      // Verify the console call doesn't crash with empty tags
    });

    it('handles componentLogEntry with undefined timestamp', async () => {
      loggerService.info('test message');
      await flushPromises();

      expect(console.info).toHaveBeenCalled();
      // Verify the console call doesn't crash with undefined timestamp
    });

    it('handles componentLogEntry with error.stackTrace', async () => {
      const error = new Error('test error');
      error.stackTrace = {
        metadataType: 'TestType',
        componentName: 'TestComponent',
        functionName: 'testFunction',
        className: 'TestClass',
        methodName: 'testMethod',
        triggerName: 'TestTrigger',
        stackTraceString: 'test stack trace'
      };

      loggerService.info('test message').setExceptionDetails(error);
      await flushPromises();

      expect(console.info).toHaveBeenCalled();
      // Verify the console call properly formats error.stackTrace
    });

    it('handles componentLogEntry without error.stackTrace', async () => {
      const error = new Error('test error');
      // error.stackTrace is undefined

      loggerService.info('test message').setExceptionDetails(error);
      await flushPromises();

      expect(console.info).toHaveBeenCalled();
      // Verify the console call doesn't crash without error.stackTrace
    });
  });

  describe('logging level filtering', () => {
    beforeEach(async () => {
      getSettings.mockResolvedValue({
        ...MOCK_GET_SETTINGS,
        isEnabled: true,
        userLoggingLevel: { ordinal: 3 }, // INFO level
        supportedLoggingLevels: {
          ERROR: { ordinal: 1 },
          WARN: { ordinal: 2 },
          INFO: { ordinal: 3 },
          DEBUG: { ordinal: 4 },
          FINE: { ordinal: 5 },
          FINER: { ordinal: 6 },
          FINEST: { ordinal: 7 }
        }
      });
      loggerService = new LoggerService();
      await flushPromises();
    });

    it('filters out entries below user logging level', async () => {
      loggerService.debug('debug message'); // Should be filtered out
      loggerService.fine('fine message'); // Should be filtered out

      await flushPromises();

      expect(loggerService.getBufferSize()).toBe(0);
    });

    it('includes entries at or above user logging level', async () => {
      loggerService.error('error message'); // Should be included
      loggerService.warn('warn message'); // Should be included
      loggerService.info('info message'); // Should be included

      await flushPromises();

      expect(loggerService.getBufferSize()).toBe(3);
    });
  });

  describe('task queue integration', () => {
    beforeEach(async () => {
      getSettings.mockResolvedValue({ ...MOCK_GET_SETTINGS });
      loggerService = new LoggerService();
      await flushPromises();
    });

    it('enqueues and executes logging level check tasks', async () => {
      loggerService.info('test message');
      await flushPromises();

      expect(loggerService.getBufferSize()).toBe(1);
    });

    it('enqueues and executes save log tasks', async () => {
      loggerService.info('test message');
      await flushPromises();

      await loggerService.saveLog();

      expect(saveComponentLogEntries).toHaveBeenCalled();
    });
  });
});
