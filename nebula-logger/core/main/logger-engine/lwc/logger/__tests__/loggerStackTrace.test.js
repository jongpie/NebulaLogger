import LoggerStackTrace from '../loggerStackTrace';

// These tests are very basic (at least for now), but provide validation
// that the stack trace parsing works as expected.
//
// Each test imports a JSON file, containing an actual stack trace generated
// by the browser (with 1-2 very minor changes for testing purposes). The same
// approach could/should eventually be done using stack traces generated from more
// targets & browsers, but for now we're just testing the parsing logic for
// Chrome, Edge, and Firefox.
describe('logger stack trace parsing tests for API v61.0', () => {
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

  it('correctly parses Chrome LWC v61.0 stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v61/chrome_lwc_debug.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerLWCEmbedDemo');
    expect(originStackTrace.functionName).toEqual('logInfoExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });

  it('correctly parses Chrome LWC v61.0 stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v61/chrome_lwc_without_debug.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerLWCEmbedDemo');
    expect(originStackTrace.functionName).toEqual('logInfoExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Edge LWC v61.0 stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v61/edge_lwc_debug.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerEdgeAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Edge LWC v61.0 stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v61/edge_lwc_without_debug.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Firefox LWC v61.0 stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v61/firefox_lwc_debug.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerFirefoxLWCImportDemo');
    expect(originStackTrace.functionName).toEqual('logInfoExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });

  it('correctly parses Firefox LWC v61.0 stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v61/firefox_lwc_without_debug.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerFirefoxLWCImportDemo');
    expect(originStackTrace.functionName).toEqual('logInfoExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });

  // it.each([
  //   ['v61', 'Chrome', 'LWC'],
  //   ['v61', 'Chrome', 'Aura'],
  //   ['v61', 'Edge', 'TODO'],
  //   ['v61', 'Firefox', 'TODO'],
  //   ['v64', 'Firefox', 'TODO']
  // ])('correctly parses stack trace when api version is %s and browser is %s', async (apiVersion, browser, componentType) => {
  //   const loggerStackTrace = new LoggerStackTrace();

  //   const originStackTrace = loggerStackTrace.parse(
  //     require(`./data/stack-traces/${apiVersion}/${browser.toLowerCase()}_${componentType.toLowerCase()}_debug.json`)
  //   );

  //   expect(originStackTrace.componentName).toEqual(`c/logger${browser}EmbedDemo`);
  //   expect(originStackTrace.functionName).toEqual('logInfoExample');
  //   expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  // });
});

describe('logger stack trace parsing tests for API v64.0', () => {
  afterEach(async () => {
    jest.clearAllMocks();
  });

  it('correctly parses Firefox LWC v64.0 stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v64/firefox_lwc_debug.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerFirefoxLWCImportDemo');
    expect(originStackTrace.functionName).toEqual('logInfoExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });

  it('correctly parses Firefox LWC v64.0 stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v64/firefox_lwc_without_debug.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerFirefoxLWCImportDemo');
    expect(originStackTrace.functionName).toEqual('logInfoExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });
});
