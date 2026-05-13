import { createElement } from '@lwc/engine-dom';
import LoggerCodeViewer from 'c/loggerCodeViewer';

// jest.mock factories cannot reference outer variables unless the names start
// with `mock`. These let each test swap in resolve/reject behavior.
let mockLoadScriptImpl;
let mockLoadStyleImpl;

jest.mock(
  'lightning/platformResourceLoader',
  () => ({
    loadScript: (...args) => mockLoadScriptImpl(...args),
    loadStyle: (...args) => mockLoadStyleImpl(...args)
  }),
  { virtual: true }
);

// _loadPrismResources awaits Promise.all over async wrappers, then renderedCallback's
// catch block runs, then LWC re-renders. With rAF stubbed to fire synchronously
// in beforeEach, microtask flushes are sufficient.
const flushPromises = async () => {
  for (let i = 0; i < 8; i++) {
    /* eslint-disable-next-line no-await-in-loop  */
    await Promise.resolve();
  }
};

describe('c-logger-code-viewer', () => {
  let consoleErrorSpy;
  let consoleLogSpy;

  beforeEach(() => {
    global.Prism = { highlightAll: jest.fn() };
    mockLoadScriptImpl = jest.fn(() => Promise.resolve());
    mockLoadStyleImpl = jest.fn(() => Promise.resolve());
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    consoleLogSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    consoleErrorSpy.mockRestore();
    consoleLogSpy.mockRestore();
    delete global.Prism;
    jest.clearAllMocks();
  });

  it('displays Prism code viewer with provided attributes', async () => {
    const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
    element.language = 'apex';
    element.startingLineNumber = '10';
    element.targetLineNumber = '18';
    let mockCode = '';
    for (let i = 0; i < element.targetLineNumber + 5; i++) {
      mockCode += 'some line of "code", line number is ' + (i + 1) + '\n';
    }
    element.code = mockCode;

    document.body.appendChild(element);
    await flushPromises();

    const prismCodeViewerPre = element.shadowRoot.querySelector('div.prism-viewer pre');
    expect(prismCodeViewerPre).toBeTruthy();
    expect(prismCodeViewerPre.classList.contains('line-numbers')).toBeTruthy();
    expect(prismCodeViewerPre.dataset.start).toBe(element.startingLineNumber);
    expect(prismCodeViewerPre.dataset.line).toBe(element.targetLineNumber);
    expect(prismCodeViewerPre.dataset.lineOffset).toBe(element.targetLineNumber);
    const prismCodeViewerPreCode = element.shadowRoot.querySelector('div.prism-viewer pre code');
    expect(prismCodeViewerPreCode).toBeTruthy();
    expect(prismCodeViewerPreCode.classList.contains('language-' + element.language)).toBeTruthy();
    expect(prismCodeViewerPreCode.textContent).toContain(mockCode);
    expect(global.Prism.highlightAll).toHaveBeenCalled();
    expect(consoleErrorSpy).not.toHaveBeenCalled();
  });

  it('renders code and logs an aggregated error when loadScript rejects', async () => {
    mockLoadScriptImpl = jest.fn(() => Promise.reject(new Error('script-load-failed')));
    const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
    element.code = 'plain text line\nsecond line';
    element.language = 'apex';
    element.startingLineNumber = '10';
    element.targetLineNumber = '18';

    document.body.appendChild(element);
    await flushPromises();

    expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
    const prismCodeViewerPre = element.shadowRoot.querySelector('div.prism-viewer pre');
    expect(prismCodeViewerPre).toBeTruthy();
    expect(prismCodeViewerPre.dataset.start).toBe(element.startingLineNumber);
    expect(prismCodeViewerPre.dataset.line).toBe(element.targetLineNumber);
    expect(prismCodeViewerPre.dataset.lineOffset).toBe(element.targetLineNumber);
    const prismCodeViewerPreCode = prismCodeViewerPre.querySelector('code');
    expect(prismCodeViewerPreCode).toBeTruthy();
    expect(prismCodeViewerPreCode.classList.contains('language-' + element.language)).toBeTruthy();
    expect(prismCodeViewerPreCode.textContent).toBe('plain text line\nsecond line');
    expect(global.Prism.highlightAll).not.toHaveBeenCalled();
    expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
    const [loggedMessage, loggedError] = consoleErrorSpy.mock.calls[0];
    expect(loggedMessage).toContain('Failed to load Prism resources');
    expect(loggedError).toBeInstanceOf(Error);
    // Aggregated message contains the failing resource URL and the underlying error message.
    expect(loggedError.message).toContain('/Prism/prism.min.js');
    expect(loggedError.message).toContain('"resourceType": "script"');
    expect(loggedError.message).toContain('script-load-failed');
  });

  it('renders fallback code and logs an aggregated error when loadStyle rejects', async () => {
    mockLoadStyleImpl = jest.fn((_owner, resourceUrl) => {
      // Fail only on the base Prism theme stylesheet to also exercise the partial-failure branch.
      if (resourceUrl && resourceUrl.endsWith('/Prism/themes/prism-tomorrow.min.css')) {
        return Promise.reject(new Error('style-load-failed'));
      }
      return Promise.resolve();
    });
    const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
    element.code = 'css-failure-code';

    document.body.appendChild(element);
    await flushPromises();

    const prismCodeViewerPreCode = element.shadowRoot.querySelector('div.prism-viewer pre code');
    expect(prismCodeViewerPreCode).toBeTruthy();
    expect(prismCodeViewerPreCode.textContent).toBe('css-failure-code');
    expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
    const [, loggedError] = consoleErrorSpy.mock.calls[0];
    expect(loggedError.message).toContain('"resourceType": "style"');
    expect(loggedError.message).toContain('/Prism/themes/prism-tomorrow.min.css');
    expect(loggedError.message).toContain('style-load-failed');
    // The custom stylesheet still resolved, so it should not appear in the failure list.
    expect(loggedError.message).not.toContain('prism.nebula-logger.css');
  });

  it('aggregates multiple resource failures into a single error message', async () => {
    mockLoadScriptImpl = jest.fn(() => Promise.reject(new Error('script-fail')));
    mockLoadStyleImpl = jest.fn(() => Promise.reject(new Error('style-fail')));

    const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
    element.code = 'x';
    document.body.appendChild(element);
    await flushPromises();

    expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
    const [, loggedError] = consoleErrorSpy.mock.calls[0];
    expect(loggedError.message).toContain('script-fail');
    expect(loggedError.message).toContain('style-fail');
    expect(loggedError.message).toContain('/Prism/prism.min.js');
    expect(loggedError.message).toContain('/Prism/themes/prism-tomorrow.min.css');
    expect(loggedError.message).toContain('/Prism/prism.nebula-logger.css');
  });

  it('serializes non-Error rejection reasons via reasonAsString', async () => {
    mockLoadScriptImpl = jest.fn(() => Promise.reject('plain-string-reason'));

    const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
    element.code = 'x';
    document.body.appendChild(element);
    await flushPromises();

    const [, loggedError] = consoleErrorSpy.mock.calls[0];
    // The Error-branch fields should be absent; the string-branch fields should be present.
    expect(loggedError.message).toContain('"reasonAsString": "plain-string-reason"');
    expect(loggedError.message).toContain('"reason": "plain-string-reason"');
    expect(loggedError.message).not.toContain('"name":');
    expect(loggedError.message).not.toContain('"stack":');
  });

  it('renders an empty fallback code element when @api code is undefined', async () => {
    mockLoadScriptImpl = jest.fn(() => Promise.reject(new Error('any')));

    const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
    // Intentionally do not set element.code
    document.body.appendChild(element);
    await flushPromises();

    const fallbackCode = element.shadowRoot.querySelector('div.prism-viewer pre code');
    expect(fallbackCode).toBeTruthy();
    // eslint-disable-next-line
    expect(fallbackCode.innerHTML).toBe('');
  });

  it('does not retry resource loading on later renders after a failure', async () => {
    mockLoadScriptImpl = jest.fn(() => Promise.reject(new Error('boom')));

    const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
    element.code = 'first';
    document.body.appendChild(element);
    await flushPromises();

    expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
    expect(mockLoadScriptImpl).toHaveBeenCalledTimes(1);

    // Mutating a public prop forces another render → renderedCallback runs again.
    element.code = 'second';
    await flushPromises();

    expect(mockLoadScriptImpl).toHaveBeenCalledTimes(1);
    expect(mockLoadStyleImpl).toHaveBeenCalledTimes(2); // initial run loaded both styles
    expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
  });

  it('does not reload Prism resources on later renders after a successful load', async () => {
    const element = createElement('c-logger-code-viewer', { is: LoggerCodeViewer });
    element.code = 'first';
    element.language = 'apex';
    document.body.appendChild(element);
    await flushPromises();

    expect(mockLoadScriptImpl).toHaveBeenCalledTimes(1);
    expect(global.Prism.highlightAll).toHaveBeenCalledTimes(1);

    element.code = 'second';
    await flushPromises();

    expect(mockLoadScriptImpl).toHaveBeenCalledTimes(1);
    // Prism.highlightAll is gated by the same isLoaded short-circuit, so it should not run again.
    expect(global.Prism.highlightAll).toHaveBeenCalledTimes(1);
  });
});
