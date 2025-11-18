import LogEntryEventBuilder from '../logEntryBuilder';
import LoggerStackTrace from '../loggerStackTrace';

// Mock LoggerStackTrace
jest.mock('../loggerStackTrace');

describe('LogEntryEventBuilder tests', () => {
  let logEntryBuilder;
  const mockBrowserContext = {
    address: 'http://localhost',
    formFactor: 'Large',
    language: 'en-US',
    screenResolution: '1920x1080',
    userAgent: 'Mozilla/5.0',
    windowResolution: '1920x1080'
  };

  beforeEach(() => {
    logEntryBuilder = new LogEntryEventBuilder('INFO', mockBrowserContext);
    jest.clearAllMocks();
  });

  describe('setExceptionDetails edge cases', () => {
    it('handles null/undefined exception gracefully', () => {
      const result = logEntryBuilder.setExceptionDetails(null);
      expect(result).toBe(logEntryBuilder);
      expect(logEntryBuilder.getComponentLogEntry().error).toBeUndefined();

      const result2 = logEntryBuilder.setExceptionDetails(undefined);
      expect(result2).toBe(logEntryBuilder);
      expect(logEntryBuilder.getComponentLogEntry().error).toBeUndefined();
    });

    it('handles Apex error with stack trace containing colon', () => {
      const apexError = {
        body: {
          exceptionType: 'System.DmlException',
          message: 'Some Apex error',
          stackTrace: 'Class.SomeApexClass.runSomeMethod: line 314, column 42'
        }
      };

      const result = logEntryBuilder.setExceptionDetails(apexError);

      expect(result).toBe(logEntryBuilder);
      const logEntry = logEntryBuilder.getComponentLogEntry();
      expect(logEntry.error.message).toBe('Some Apex error');
      expect(logEntry.error.type).toBe('System.DmlException');
      expect(logEntry.error.stackTrace.className).toBe('SomeApexClass');
      expect(logEntry.error.stackTrace.methodName).toBe('runSomeMethod');
      expect(logEntry.error.stackTrace.metadataType).toBe('ApexClass');
      expect(logEntry.error.stackTrace.stackTraceString).toBe('Class.SomeApexClass.runSomeMethod: line 314, column 42');
    });

    it('handles Apex trigger error with stack trace containing colon', () => {
      const apexError = {
        body: {
          exceptionType: 'System.TriggerException',
          message: 'Some trigger error',
          stackTrace: 'Trigger.SomeTrigger: line 10, column 5'
        }
      };

      const result = logEntryBuilder.setExceptionDetails(apexError);

      expect(result).toBe(logEntryBuilder);
      const logEntry = logEntryBuilder.getComponentLogEntry();
      expect(logEntry.error.message).toBe('Some trigger error');
      expect(logEntry.error.type).toBe('System.TriggerException');
      expect(logEntry.error.stackTrace.triggerName).toBe('SomeTrigger');
      expect(logEntry.error.stackTrace.metadataType).toBe('ApexTrigger');
      expect(logEntry.error.stackTrace.stackTraceString).toBe('Trigger.SomeTrigger: line 10, column 5');
    });

    it('handles Apex error with stack trace without colon', () => {
      const apexError = {
        body: {
          exceptionType: 'System.DmlException',
          message: 'Some Apex error',
          stackTrace: 'Class.SomeApexClass.runSomeMethod'
        }
      };

      const result = logEntryBuilder.setExceptionDetails(apexError);

      expect(result).toBe(logEntryBuilder);
      const logEntry = logEntryBuilder.getComponentLogEntry();
      expect(logEntry.error.message).toBe('Some Apex error');
      expect(logEntry.error.type).toBe('System.DmlException');
      expect(logEntry.error.stackTrace.className).toBeUndefined();
      expect(logEntry.error.stackTrace.methodName).toBeUndefined();
      expect(logEntry.error.stackTrace.metadataType).toBeUndefined();
      expect(logEntry.error.stackTrace.stackTraceString).toBe('Class.SomeApexClass.runSomeMethod');
    });

    it('handles JavaScript error without body property', () => {
      const jsError = new Error('JavaScript error');
      jsError.name = 'TypeError';

      const result = logEntryBuilder.setExceptionDetails(jsError);

      expect(result).toBe(logEntryBuilder);
      const logEntry = logEntryBuilder.getComponentLogEntry();
      expect(logEntry.error.message).toBe('JavaScript error');
      expect(logEntry.error.type).toBe('JavaScript.TypeError');
      expect(logEntry.error.stackTrace).toBeDefined();
    });
  });

  describe('setField edge cases', () => {
    it('handles null/undefined fieldToValue gracefully', () => {
      const result = logEntryBuilder.setField(null);
      expect(result).toBe(logEntryBuilder);

      const result2 = logEntryBuilder.setField(undefined);
      expect(result2).toBe(logEntryBuilder);
    });

    it('sets multiple fields correctly', () => {
      const fieldToValue = {
        Field1__c: 'value1',
        Field2__c: 'value2',
        Field3__c: 'value3'
      };

      const result = logEntryBuilder.setField(fieldToValue);

      expect(result).toBe(logEntryBuilder);
      const logEntry = logEntryBuilder.getComponentLogEntry();
      expect(logEntry.fieldToValue['Field1__c']).toBe('value1');
      expect(logEntry.fieldToValue['Field2__c']).toBe('value2');
      expect(logEntry.fieldToValue['Field3__c']).toBe('value3');
    });
  });

  describe('parseStackTrace edge cases', () => {
    it('handles null/undefined originStackTraceError gracefully', () => {
      const result = logEntryBuilder.parseStackTrace(null);
      expect(result).toBe(logEntryBuilder);

      const result2 = logEntryBuilder.parseStackTrace(undefined);
      expect(result2).toBe(logEntryBuilder);
    });

    it('parses stack trace with LoggerStackTrace', () => {
      const mockStackTrace = {
        componentName: 'TestComponent',
        functionName: 'testFunction',
        metadataType: 'LightningComponentBundle'
      };

      LoggerStackTrace.mockImplementation(() => ({
        parse: jest.fn().mockReturnValue(mockStackTrace)
      }));

      const error = new Error('test error');
      const result = logEntryBuilder.parseStackTrace(error);

      expect(result).toBe(logEntryBuilder);
      const logEntry = logEntryBuilder.getComponentLogEntry();
      expect(logEntry.originStackTrace).toEqual(mockStackTrace);
    });
  });

  describe('addTag edge cases', () => {
    it('handles null/undefined tag gracefully', () => {
      const result = logEntryBuilder.addTag(null);
      expect(result).toBe(logEntryBuilder);
      expect(logEntryBuilder.getComponentLogEntry().tags).toEqual([]);

      const result2 = logEntryBuilder.addTag(undefined);
      expect(result2).toBe(logEntryBuilder);
      expect(logEntryBuilder.getComponentLogEntry().tags).toEqual([]);
    });

    it('handles empty string tag gracefully', () => {
      const result = logEntryBuilder.addTag('');
      expect(result).toBe(logEntryBuilder);
      expect(logEntryBuilder.getComponentLogEntry().tags).toEqual([]);

      const result2 = logEntryBuilder.addTag('   ');
      expect(result2).toBe(logEntryBuilder);
      expect(logEntryBuilder.getComponentLogEntry().tags).toEqual([]);
    });

    it('trims whitespace from tags', () => {
      const result = logEntryBuilder.addTag('  test tag  ');
      expect(result).toBe(logEntryBuilder);
      expect(logEntryBuilder.getComponentLogEntry().tags).toEqual(['test tag']);
    });

    it('deduplicates tags correctly', () => {
      logEntryBuilder.addTag('tag1');
      logEntryBuilder.addTag('tag2');
      logEntryBuilder.addTag('tag1'); // Duplicate

      const result = logEntryBuilder.addTag('tag2'); // Another duplicate

      expect(result).toBe(logEntryBuilder);
      const logEntry = logEntryBuilder.getComponentLogEntry();
      expect(logEntry.tags).toEqual(['tag1', 'tag2']);
      expect(logEntry.tags.length).toBe(2);
    });
  });

  describe('addTags edge cases', () => {
    it('handles empty array gracefully', () => {
      const result = logEntryBuilder.addTags([]);
      expect(result).toBe(logEntryBuilder);
      expect(logEntryBuilder.getComponentLogEntry().tags).toEqual([]);
    });

    it('handles array with null/undefined values gracefully', () => {
      const result = logEntryBuilder.addTags([null, undefined, 'valid tag']);
      expect(result).toBe(logEntryBuilder);
      const logEntry = logEntryBuilder.getComponentLogEntry();
      expect(logEntry.tags).toEqual(['valid tag']);
    });

    it('adds multiple tags correctly', () => {
      const tags = ['tag1', 'tag2', 'tag3'];
      const result = logEntryBuilder.addTags(tags);

      expect(result).toBe(logEntryBuilder);
      const logEntry = logEntryBuilder.getComponentLogEntry();
      expect(logEntry.tags).toEqual(tags);
    });

    it('deduplicates tags across multiple addTags calls', () => {
      logEntryBuilder.addTags(['tag1', 'tag2']);
      logEntryBuilder.addTags(['tag2', 'tag3']); // tag2 is duplicate

      const result = logEntryBuilder.addTags(['tag1', 'tag4']); // tag1 is duplicate

      expect(result).toBe(logEntryBuilder);
      const logEntry = logEntryBuilder.getComponentLogEntry();
      expect(logEntry.tags).toEqual(['tag1', 'tag2', 'tag3', 'tag4']);
      expect(logEntry.tags.length).toBe(4);
    });
  });

  describe('setRecordId and setRecord', () => {
    it('sets recordId correctly', () => {
      const recordId = '001XXXXXXXXXXXXXXX';
      const result = logEntryBuilder.setRecordId(recordId);

      expect(result).toBe(logEntryBuilder);
      const logEntry = logEntryBuilder.getComponentLogEntry();
      expect(logEntry.recordId).toBe(recordId);
    });

    it('sets record correctly', () => {
      const record = { Id: '001XXXXXXXXXXXXXXX', Name: 'Test Record' };
      const result = logEntryBuilder.setRecord(record);

      expect(result).toBe(logEntryBuilder);
      const logEntry = logEntryBuilder.getComponentLogEntry();
      expect(logEntry.record).toEqual(record);
    });
  });

  describe('setMessage', () => {
    it('sets message correctly', () => {
      const message = 'Test log message';
      const result = logEntryBuilder.setMessage(message);

      expect(result).toBe(logEntryBuilder);
      const logEntry = logEntryBuilder.getComponentLogEntry();
      expect(logEntry.message).toBe(message);
    });
  });

  describe('setScenario', () => {
    it('sets scenario correctly', () => {
      const scenario = 'Test scenario';
      const result = logEntryBuilder.setScenario(scenario);

      expect(result).toBe(logEntryBuilder);
      const logEntry = logEntryBuilder.getComponentLogEntry();
      expect(logEntry.scenario).toBe(scenario);
    });
  });

  describe('getComponentLogEntry', () => {
    it('returns the correct component log entry structure', () => {
      const logEntry = logEntryBuilder.getComponentLogEntry();

      expect(logEntry).toHaveProperty('loggingLevel');
      expect(logEntry).toHaveProperty('message');
      expect(logEntry).toHaveProperty('timestamp');
      expect(logEntry).toHaveProperty('browser');
      expect(logEntry).toHaveProperty('originStackTrace');
      expect(logEntry).toHaveProperty('error');
      expect(logEntry).toHaveProperty('fieldToValue');
      expect(logEntry).toHaveProperty('recordId');
      expect(logEntry).toHaveProperty('record');
      expect(logEntry).toHaveProperty('scenario');
      expect(logEntry).toHaveProperty('tags');
    });

    it('returns browser context correctly', () => {
      const logEntry = logEntryBuilder.getComponentLogEntry();

      expect(logEntry.browser).toEqual(mockBrowserContext);
    });

    it('returns logging level correctly', () => {
      const logEntry = logEntryBuilder.getComponentLogEntry();

      expect(logEntry.loggingLevel).toBe('INFO');
    });
  });
});
