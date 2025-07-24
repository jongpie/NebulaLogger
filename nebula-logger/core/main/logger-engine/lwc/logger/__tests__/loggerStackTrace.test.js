const LoggerStackTrace = require('../loggerStackTrace').default;

// Define the test data structure organized by Salesforce API version
const STACK_TRACE_DATA = {
  v61: {
    chrome: {
      debug: {
        data: require('./data/v61_chrome_debug.json'),
        expected: {
          componentName: 'c/loggerChromeLWCEmbedDemo',
          functionName: 'logInfoExample',
          metadataType: 'LightningComponentBundle'
        }
      },
      withoutDebug: {
        data: require('./data/v61_chrome_without_debug.json'),
        expected: {
          componentName: 'c/loggerAuraEmbedDemo',
          functionName: 'saveLogExample',
          metadataType: 'AuraDefinitionBundle'
        }
      }
    },
    firefox: {
      debug: {
        data: require('./data/v61_firefox_debug.json'),
        expected: {
          componentName: 'c/loggerFirefoxLWCImportDemo',
          functionName: 'logInfoExample',
          metadataType: 'LightningComponentBundle'
        }
      },
      withoutDebug: {
        data: require('./data/v61_firefox_without_debug.json'),
        expected: {
          componentName: 'c/loggerAuraEmbedDemo',
          functionName: 'saveLogExample',
          metadataType: 'AuraDefinitionBundle'
        }
      }
    },
    edge: {
      debug: {
        data: require('./data/v61_edge_debug.json'),
        expected: {
          componentName: 'c/loggerEdgeAuraEmbedDemo',
          functionName: 'saveLogExample',
          metadataType: 'AuraDefinitionBundle'
        }
      },
      withoutDebug: {
        data: require('./data/v61_edge_without_debug.json'),
        expected: {
          componentName: 'c/loggerAuraEmbedDemo',
          functionName: 'saveLogExample',
          metadataType: 'AuraDefinitionBundle'
        }
      }
    }
  },
  v64: {
    firefox: {
      debug: {
        data: require('./data/v64_firefox_debug.json'),
        expected: {
          componentName: 'c/blahhhhh',
          functionName: 'logInfoExample',
          metadataType: 'LightningComponentBundle'
        }
      },
      withoutDebug: {
        data: require('./data/v64_firefox_without_debug.json'),
        expected: {
          componentName: 'c/blahhhhh',
          functionName: 'TODO get a real one without debug!',
          metadataType: 'LightningComponentBundle'
        }
      }
    }
  }
};

// These tests are very basic (at least for now), but provide validation
// that the stack trace parsing works as expected.
//
// Each test imports a JSON file, containing an actual stack trace generated
// by the browser (with 1-2 very minor changes for testing purposes). The same
// approach could/should eventually be done using stack traces generated from more
// targets & browsers, but for now we're just testing the parsing logic for
// Chrome, Edge, and Firefox.
describe('logger stack trace parsing tests', () => {
  afterEach(async () => {
    jest.clearAllMocks();
  });

  it('correctly handles undefined error', async () => {
    const originStackTraceError = undefined;
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(originStackTraceError);

    expect(originStackTrace.componentName).toBeUndefined();
    expect(originStackTrace.functionName).toBeUndefined();
    expect(originStackTrace.metadataType).toBeUndefined();
  });

  it('correctly handles non-null error with undefined stack trace', async () => {
    const originStackTraceError = new Error();
    originStackTraceError.stack = undefined;
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(originStackTraceError);

    expect(originStackTrace.componentName).toBeUndefined();
    expect(originStackTrace.functionName).toBeUndefined();
    expect(originStackTrace.metadataType).toBeUndefined();
  });

  it('correctly handles non-null error with undefined stack trace', async () => {
    const originStackTraceError = new Error();
    originStackTraceError.stack = undefined;
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(originStackTraceError);

    expect(originStackTrace.componentName).toBeUndefined();
    expect(originStackTrace.functionName).toBeUndefined();
    expect(originStackTrace.metadataType).toBeUndefined();
  });

  describe('Salesforce API v64', () => {
    it.each(Object.values(STACK_TRACE_DATA.v64.firefox))('correctly parses Firefox stack trace in debug mode', async testStackTrace => {
      const loggerStackTrace = new LoggerStackTrace();

      const originStackTrace = loggerStackTrace.parse(testStackTrace.data);
      const expected = testStackTrace.expected;

      expect(originStackTrace.componentName).toEqual(expected.componentName);
      expect(originStackTrace.functionName).toEqual(expected.functionName);
      expect(originStackTrace.metadataType).toEqual(expected.metadataType);
    });
  });

  

  // Dynamic tests organized by Salesforce API version
  Object.entries(STACK_TRACE_DATA).forEach(([apiVersion, browsers]) => {
    describe(`Salesforce API ${apiVersion}`, () => {
      Object.entries(browsers).forEach(([browser, debugModes]) => {
        describe(`${browser} browser`, () => {
          const loggerStackTrace = new LoggerStackTrace();

          it(`correctly parses ${browser} stack trace in debug mode`, () => {
            const originStackTrace = loggerStackTrace.parse(debugModes.debug.data);
            const expected = debugModes.debug.expected;

            expect(originStackTrace.componentName).toEqual(expected.componentName);
            expect(originStackTrace.functionName).toEqual(expected.functionName);
            expect(originStackTrace.metadataType).toEqual(expected.metadataType);
          });

          it(`correctly parses ${browser} stack trace without debug mode`, () => {
            const originStackTrace = loggerStackTrace.parse(debugModes.withoutDebug.data);
            const expected = debugModes.withoutDebug.expected;

            expect(originStackTrace.componentName).toEqual(expected.componentName);
            expect(originStackTrace.functionName).toEqual(expected.functionName);
            expect(originStackTrace.metadataType).toEqual(expected.metadataType);
          });
        });
      });
    });
  });
});
