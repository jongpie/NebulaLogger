import LoggerStackTrace from '../loggerStackTrace';

const CHROME_AURA_STACK_TRACE_DEBUG_MODE = require('./data/stack-traces/v64/chrome_aura_debug.json');
const CHROME_AURA_STACK_TRACE_WITHOUT_DEBUG_MODE = require('./data/stack-traces/v64/chrome_aura_without_debug.json');
const CHROME_LWC_STACK_TRACE_DEBUG_MODE = require('./data/stack-traces/v64/chrome_lwc_debug.json');
const CHROME_LWC_STACK_TRACE_WITHOUT_DEBUG_MODE = require('./data/stack-traces/v64/chrome_lwc_without_debug.json');
const EDGE_AURA_STACK_TRACE_DEBUG_MODE = require('./data/stack-traces/v64/edge_aura_debug.json');
const EDGE_AURA_STACK_TRACE_WITHOUT_DEBUG_MODE = require('./data/stack-traces/v64/edge_aura_without_debug.json');
const EDGE_LWC_STACK_TRACE_DEBUG_MODE = require('./data/stack-traces/v64/edge_lwc_debug.json');
const EDGE_LWC_STACK_TRACE_WITHOUT_DEBUG_MODE = require('./data/stack-traces/v64/edge_lwc_without_debug.json');
const FIREFOX_AURA_STACK_TRACE_DEBUG_MODE = require('./data/stack-traces/v64/firefox_aura_debug.json');
const FIREFOX_AURA_STACK_TRACE_WITHOUT_DEBUG_MODE = require('./data/stack-traces/v64/firefox_aura_without_debug.json');
const FIREFOX_LWC_STACK_TRACE_DEBUG_MODE = require('./data/stack-traces/v64/firefox_lwc_debug.json');
const FIREFOX_LWC_STACK_TRACE_WITHOUT_DEBUG_MODE = require('./data/stack-traces/v64/firefox_lwc_without_debug.json');

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

  it('correctly parses Chrome Aura stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(CHROME_AURA_STACK_TRACE_DEBUG_MODE);

    expect(originStackTrace.componentName).toEqual('c/loggerChromeAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogWithDebugExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Chrome Aura stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(CHROME_AURA_STACK_TRACE_WITHOUT_DEBUG_MODE);

    expect(originStackTrace.componentName).toEqual('c/loggerChromeAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogWithoutDebugExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Chrome LWC stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(CHROME_LWC_STACK_TRACE_DEBUG_MODE);

    expect(originStackTrace.componentName).toEqual('c/loggerChromeLWCEmbedDemo');
    expect(originStackTrace.functionName).toEqual('logInfoWithDebugExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });

  it('correctly parses Chrome LWC stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(CHROME_LWC_STACK_TRACE_WITHOUT_DEBUG_MODE);

    expect(originStackTrace.componentName).toEqual('c/loggerChromeLWCImportDemo');
    expect(originStackTrace.functionName).toEqual('logInfoWithoutDebugExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });

  it('correctly parses Edge Aura stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(EDGE_AURA_STACK_TRACE_DEBUG_MODE);

    expect(originStackTrace.componentName).toEqual('c/loggerEdgeAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogWithDebugExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Edge Aura stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(EDGE_AURA_STACK_TRACE_WITHOUT_DEBUG_MODE);

    expect(originStackTrace.componentName).toEqual('c/loggerEdgeAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogWithoutDebugExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Edge LWC stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(EDGE_LWC_STACK_TRACE_DEBUG_MODE);

    expect(originStackTrace.componentName).toEqual('c/loggerEdgeLWCEmbedDemo');
    expect(originStackTrace.functionName).toEqual('logInfoWithDebugExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });

  it('correctly parses Edge LWC stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(EDGE_LWC_STACK_TRACE_WITHOUT_DEBUG_MODE);

    expect(originStackTrace.componentName).toEqual('c/loggerEdgeLWCEmbedDemo');
    expect(originStackTrace.functionName).toEqual('logInfoWithoutDebugExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });

  it('correctly parses Firefox Aura stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(FIREFOX_AURA_STACK_TRACE_DEBUG_MODE);

    expect(originStackTrace.componentName).toEqual('c/loggerFirefoxAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogWithDebugExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Firefox Aura stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(FIREFOX_AURA_STACK_TRACE_WITHOUT_DEBUG_MODE);

    expect(originStackTrace.componentName).toEqual('c/loggerFirefoxAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogWithoutDebugExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Firefox LWC stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(FIREFOX_LWC_STACK_TRACE_DEBUG_MODE);

    expect(originStackTrace.componentName).toEqual('c/loggerFirefoxLWCImportDemo');
    expect(originStackTrace.functionName).toEqual('logInfoWithDebugExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });

  it('correctly parses Firefox LWC stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(FIREFOX_LWC_STACK_TRACE_WITHOUT_DEBUG_MODE);

    expect(originStackTrace.componentName).toEqual('c/loggerFirefoxLWCImportDemo');
    expect(originStackTrace.functionName).toEqual('logInfoWithoutDebugExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });
});
