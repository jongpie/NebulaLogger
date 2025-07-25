import LoggerStackTrace from '../loggerStackTrace';

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

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v61/chrome_debug.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerChromeLWCEmbedDemo');
    expect(originStackTrace.functionName).toEqual('logInfoExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });

  it('correctly parses Chrome stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v61/chrome_without_debug.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Edge stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v61/edge_debug.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerEdgeAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Edge stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v61/edge_without_debug.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Firefox stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v61/firefox_debug.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerFirefoxLWCImportDemo');
    expect(originStackTrace.functionName).toEqual('logInfoExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });

  it('correctly parses Firefox stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v61/firefox_without_debug.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it.each([
    ['v61', 'Chrome'],
    ['v61', 'Edge'],
    ['v61', 'Firefox'],
    ['v64', 'Firefox']
  ])('correctly parses stack trace when api version is %s and browser is %s', async (apiVersion, browser) => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require(`./data/stack-traces/${apiVersion}/${browser.toLowerCase()}_debug.json`));

    expect(originStackTrace.componentName).toEqual(`c/logger${browser}LWCEmbedDemo`);
    expect(originStackTrace.functionName).toEqual('logInfoExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });
});
