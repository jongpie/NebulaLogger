import LoggerStackTrace from '../loggerStackTrace';

const CHROME_BROWSER_ERROR_DEBUG_MODE = require('./data/chromeBrowserError_debugMode.json');
const CHROME_BROWSER_ERROR_WITHOUT_DEBUG_MODE = require('./data/chromeBrowserError_withoutDebugMode.json');
const EDGE_BROWSER_ERROR_DEBUG_MODE = require('./data/edgeBrowserError_debugMode.json');
const EDGE_BROWSER_ERROR_WITHOUT_DEBUG_MODE = require('./data/edgeBrowserError_withoutDebugMode.json');
const FIREFOX_BROWSER_ERROR_DEBUG_MODE = require('./data/firefoxBrowserError_debugMode.json');
const FIREFOX_BROWSER_ERROR_WITHOUT_DEBUG_MODE = require('./data/firefoxBrowserError_withoutDebugMode.json');

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

  it('correctly parses Chrome stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(CHROME_BROWSER_ERROR_DEBUG_MODE);

    expect(originStackTrace.componentName).toEqual('c/loggerChromeLWCEmbedDemo');
    expect(originStackTrace.functionName).toEqual('logInfoExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });

  it('correctly parses Chrome stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(CHROME_BROWSER_ERROR_WITHOUT_DEBUG_MODE);

    expect(originStackTrace.componentName).toEqual('c/loggerAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Edge stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(EDGE_BROWSER_ERROR_DEBUG_MODE);

    expect(originStackTrace.componentName).toEqual('c/loggerEdgeAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Edge stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(EDGE_BROWSER_ERROR_WITHOUT_DEBUG_MODE);

    expect(originStackTrace.componentName).toEqual('c/loggerAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Firefox stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(FIREFOX_BROWSER_ERROR_DEBUG_MODE);

    expect(originStackTrace.componentName).toEqual('c/loggerFirefoxLWCImportDemo');
    expect(originStackTrace.functionName).toEqual('logInfoExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });

  it('correctly parses Firefox stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(FIREFOX_BROWSER_ERROR_WITHOUT_DEBUG_MODE);

    expect(originStackTrace.componentName).toEqual('c/loggerAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });
});
