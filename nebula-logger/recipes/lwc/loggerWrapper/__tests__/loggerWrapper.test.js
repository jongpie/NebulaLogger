import { logMessage } from '../loggerWrapper';
import { getLogger } from 'c/logger';

jest.mock(
  'c/logger',
  () => ({
    getLogger: jest.fn()
  }),
  {
    virtual: true
  }
);

describe('loggerWrapper', () => {
  let mockLogger;
  let mockInfo;
  let mockParseStackTrace;

  beforeEach(() => {
    // Create a mock chain: logger.info().parseStackTrace()
    mockParseStackTrace = jest.fn().mockReturnThis();
    mockInfo = jest.fn().mockReturnValue({
      parseStackTrace: mockParseStackTrace
    });
    mockLogger = {
      info: mockInfo,
      saveLog: jest.fn()
    };
    getLogger.mockReturnValue(mockLogger);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should log a message and filter loggerWrapper.js from stack trace', () => {
    const testMessage = 'Test log message';

    logMessage(testMessage);

    // Verify getLogger was called
    expect(getLogger).toHaveBeenCalledTimes(1);

    // Verify logger.info was called with the message
    expect(mockInfo).toHaveBeenCalledTimes(1);
    expect(mockInfo).toHaveBeenCalledWith(testMessage);

    // Verify parseStackTrace was called with an Error object
    expect(mockParseStackTrace).toHaveBeenCalledTimes(1);
    const errorArg = mockParseStackTrace.mock.calls[0][0];
    expect(errorArg).toBeInstanceOf(Error);
    expect(errorArg.stack).toBeDefined();

    // Verify the stack trace does not contain 'loggerWrapper.js'
    expect(errorArg.stack).not.toContain('loggerWrapper.js');

    // Verify saveLog was called
    expect(mockLogger.saveLog).toHaveBeenCalledTimes(1);
  });

  it('should filter out loggerWrapper.js lines from stack trace', () => {
    const testMessage = 'Another test message';

    logMessage(testMessage);

    const errorArg = mockParseStackTrace.mock.calls[0][0];
    const stackLines = errorArg.stack.split('\n');

    // Verify no line in the stack trace contains 'loggerWrapper.js'
    const hasLoggerWrapperLine = stackLines.some(line => line.includes('loggerWrapper.js'));
    expect(hasLoggerWrapperLine).toBe(false);
  });

  it('should preserve other stack trace lines', () => {
    const testMessage = 'Stack trace preservation test';

    logMessage(testMessage);

    const errorArg = mockParseStackTrace.mock.calls[0][0];
    const stackLines = errorArg.stack.split('\n');

    // Should have at least some stack trace lines (Error, at logMessage, etc.)
    expect(stackLines.length).toBeGreaterThan(0);
    expect(errorArg.stack).toContain('Error');
  });

  it('should handle multiple calls correctly', () => {
    logMessage('First message');
    logMessage('Second message');
    logMessage('Third message');

    expect(getLogger).toHaveBeenCalledTimes(3);
    expect(mockInfo).toHaveBeenCalledTimes(3);
    expect(mockParseStackTrace).toHaveBeenCalledTimes(3);
    expect(mockLogger.saveLog).toHaveBeenCalledTimes(3);

    expect(mockInfo).toHaveBeenNthCalledWith(1, 'First message');
    expect(mockInfo).toHaveBeenNthCalledWith(2, 'Second message');
    expect(mockInfo).toHaveBeenNthCalledWith(3, 'Third message');
  });
});
