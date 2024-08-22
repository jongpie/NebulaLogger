import { LoggerStackTrace } from '../loggerStackTrace';

const CHROME_BROWSER_ERROR = require('./data/chromeBrowserError.json');
const EDGE_BROWSER_ERROR = require('./data/edgeBrowserError.json');
const FIREFOX_BROWSER_ERROR = require('./data/firefoxBrowserError.json');

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

  it('correctly parses Chrome stack trace', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(CHROME_BROWSER_ERROR);

    expect(originStackTrace.componentName).toEqual('c/loggerChromeLWCEmbedDemo');
    expect(originStackTrace.functionName).toEqual('logInfoExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });

  it('correctly parses Edge stack trace', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(EDGE_BROWSER_ERROR);

    expect(originStackTrace.componentName).toEqual('c/loggerEdgeAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Firefox stack trace', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(FIREFOX_BROWSER_ERROR);

    expect(originStackTrace.componentName).toEqual('c/loggerFirefoxLWCImportDemo');
    expect(originStackTrace.functionName).toEqual('logInfoExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });
});
