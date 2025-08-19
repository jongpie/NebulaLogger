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

  it('correctly parses Chrome LWC v61.0 stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v61/chrome_LightningComponentBundle_debugMode.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerLWCEmbedDemo');
    expect(originStackTrace.functionName).toEqual('logInfoExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });

  it('correctly parses Chrome LWC v61.0 stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v61/chrome_AuraDefinitionBundle_withoutDebugMode.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerLWCEmbedDemo');
    expect(originStackTrace.functionName).toEqual('logInfoExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Edge LWC v61.0 stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v61/edge_LightningComponentBundle_debugMode.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerEdgeAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Edge LWC v61.0 stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v61/edge_LightningComponentBundle_withoutDebugMode.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerAuraEmbedDemo');
    expect(originStackTrace.functionName).toEqual('saveLogExample');
    expect(originStackTrace.metadataType).toEqual('AuraDefinitionBundle');
  });

  it('correctly parses Firefox LWC v61.0 stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v61/firefox_LightningComponentBundle_debugMode.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerFirefoxLWCImportDemo');
    expect(originStackTrace.functionName).toEqual('logInfoExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });

  it('correctly parses Firefox LWC v61.0 stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v61/firefox_LightningComponentBundle_withoutDebugMode.json'));

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
  //     require(`./data/stack-traces/${apiVersion}/${browser.toLowerCase()}_${componentType.toLowerCase()}_debugMode.json`)
  //   );

  //   expect(originStackTrace.componentName).toEqual(`c/logger${browser}EmbedDemo`);
  //   expect(originStackTrace.functionName).toEqual('logInfoExample');
  //   expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  // });

  it('correctly parses Firefox LWC v64.0 stack trace when debug mode is enabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v64/firefox_LightningComponentBundle_debugMode.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerFirefoxLWCImportDemo');
    expect(originStackTrace.functionName).toEqual('logInfoExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });

  it('correctly parses Firefox LWC v64.0 stack trace when debug mode is disabled', async () => {
    const loggerStackTrace = new LoggerStackTrace();

    const originStackTrace = loggerStackTrace.parse(require('./data/stack-traces/v64/firefox_LightningComponentBundle_withoutDebugMode.json'));

    expect(originStackTrace.componentName).toEqual('c/loggerFirefoxLWCImportDemo');
    expect(originStackTrace.functionName).toEqual('logInfoExample');
    expect(originStackTrace.metadataType).toEqual('LightningComponentBundle');
  });

  describe('ErrorStackParser edge cases', () => {
    it('handles error without stack property', () => {
      const loggerStackTrace = new LoggerStackTrace();
      const error = new Error('test error');
      delete error.stack;

      const result = loggerStackTrace.parse(error);

      expect(result.componentName).toBeUndefined();
      expect(result.functionName).toBeUndefined();
      expect(result.metadataType).toBeUndefined();
    });

    it('handles error with empty stack property', () => {
      const loggerStackTrace = new LoggerStackTrace();
      const error = new Error('test error');
      error.stack = '';

      const result = loggerStackTrace.parse(error);

      expect(result.componentName).toBeUndefined();
      expect(result.functionName).toBeUndefined();
      expect(result.metadataType).toBeUndefined();
    });

    it('handles error with stack that does not match Chrome/IE pattern', () => {
      const loggerStackTrace = new LoggerStackTrace();
      const error = new Error('test error');
      error.stack = 'Some custom stack format';

      const result = loggerStackTrace.parse(error);

      expect(result.componentName).toBeUndefined();
      expect(result.functionName).toBeUndefined();
      expect(result.metadataType).toBeUndefined();
    });
  });

  describe('extractLocation edge cases', () => {
    it('handles URL-like string without colons', () => {
      const loggerStackTrace = new LoggerStackTrace();
      const error = new Error('test error');
      error.stack = 'at someFunction (native)';

      const result = loggerStackTrace.parse(error);

      expect(result.componentName).toBeUndefined();
      expect(result.functionName).toBeUndefined();
      expect(result.metadataType).toBeUndefined();
    });

    it('handles URL-like string with only one colon', () => {
      const loggerStackTrace = new LoggerStackTrace();
      const error = new Error('test error');
      error.stack = 'at someFunction (file.js:123)';

      const result = loggerStackTrace.parse(error);

      expect(result.componentName).toBeUndefined();
      expect(result.functionName).toBeUndefined();
      expect(result.metadataType).toBeUndefined();
    });

    it('handles URL-like string with two colons', () => {
      const loggerStackTrace = new LoggerStackTrace();
      const error = new Error('test error');
      error.stack = 'at someFunction (file.js:123:45)';

      const result = loggerStackTrace.parse(error);

      expect(result.componentName).toBeUndefined();
      expect(result.functionName).toBeUndefined();
      expect(result.metadataType).toBeUndefined();
    });
  });

  describe('parseV8OrIE edge cases', () => {
    it('handles eval code in stack trace', () => {
      const loggerStackTrace = new LoggerStackTrace();
      const error = new Error('test error');
      error.stack = 'at eval (eval code:1:1)\nat someFunction (file.js:123:45)';

      const result = loggerStackTrace.parse(error);

      expect(result.componentName).toBeUndefined();
      expect(result.functionName).toBeUndefined();
      expect(result.metadataType).toBeUndefined();
    });

    it('handles Proxy prefix in function name', () => {
      const loggerStackTrace = new LoggerStackTrace();
      const error = new Error('test error');
      error.stack = 'at Proxy.someFunction (file.js:123:45)';

      const result = loggerStackTrace.parse(error);

      expect(result.componentName).toBeUndefined();
      expect(result.functionName).toBeUndefined();
      expect(result.metadataType).toBeUndefined();
    });

    it('handles anonymous function names', () => {
      const loggerStackTrace = new LoggerStackTrace();
      const error = new Error('test error');
      error.stack = 'at <anonymous> (file.js:123:45)';

      const result = loggerStackTrace.parse(error);

      expect(result.componentName).toBeUndefined();
      expect(result.functionName).toBeUndefined();
      expect(result.metadataType).toBeUndefined();
    });
  });

  describe('parseFFOrSafari edge cases', () => {
    it('handles Safari eval frames with only function names', () => {
      const loggerStackTrace = new LoggerStackTrace();
      const error = new Error('test error');
      error.stack = 'someFunction\nanotherFunction';

      const result = loggerStackTrace.parse(error);

      expect(result.componentName).toBeUndefined();
      expect(result.functionName).toBeUndefined();
      expect(result.metadataType).toBeUndefined();
    });

    it('handles eval information in Firefox stack trace', () => {
      const loggerStackTrace = new LoggerStackTrace();
      const error = new Error('test error');
      error.stack = 'someFunction > eval line 1 > eval:1:1';

      const result = loggerStackTrace.parse(error);

      expect(result.componentName).toBeUndefined();
      expect(result.functionName).toBeUndefined();
      expect(result.metadataType).toBeUndefined();
    });

    it('handles function names with quotes', () => {
      const loggerStackTrace = new LoggerStackTrace();
      const error = new Error('test error');
      error.stack = '"someFunction"@file.js:123:45';

      const result = loggerStackTrace.parse(error);

      expect(result.componentName).toBeUndefined();
      expect(result.functionName).toBeUndefined();
      expect(result.metadataType).toBeUndefined();
    });
  });

  describe('_cleanStackTraceParticle edge cases', () => {
    it('handles LWC modules filename prefix', () => {
      const loggerStackTrace = new LoggerStackTrace();
      const error = new Error('test error');
      error.stack = 'at someFunction (modules/component/component.js:123:45)';

      const result = loggerStackTrace.parse(error);

      expect(result.metadataType).toBe('LightningComponentBundle');
      expect(result.fileName).toBe('component/component.js');
      expect(result.componentName).toBe('component');
    });

    it('handles Aura components content', () => {
      const loggerStackTrace = new LoggerStackTrace();
      const error = new Error('test error');
      error.stack = 'at someFunction (/components/auraComponent/auraComponent.js:123:45)';

      const result = loggerStackTrace.parse(error);

      expect(result.metadataType).toBe('AuraDefinitionBundle');
      expect(result.fileName).toBe('auraComponent/auraComponent.js');
      expect(result.componentName).toBe('auraComponent');
    });

    it('handles function names ending with invalid suffix', () => {
      const loggerStackTrace = new LoggerStackTrace();
      const error = new Error('test error');
      error.stack = 'at someFunction/< (file.js:123:45)';

      const result = loggerStackTrace.parse(error);

      expect(result.functionName).toBe('someFunction');
    });

    it('handles function names without invalid suffix', () => {
      const loggerStackTrace = new LoggerStackTrace();
      const error = new Error('test error');
      error.stack = 'at someFunction (file.js:123:45)';

      const result = loggerStackTrace.parse(error);

      expect(result.functionName).toBe('someFunction');
    });
  });
});
