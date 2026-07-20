import { createElement } from '@lwc/engine-dom';
import LoggerNotificationFormulaEditor from 'c/loggerNotificationFormulaEditor';

// jest.mock factories can't reference outer variables unless the names start with `mock`, so
// mutable per-test overrides live at module scope.
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

// loadPrismOnce awaits Promise.all over the two loader calls, then renderedCallback continues
// with applyHighlight + syncTextareaValue. A few microtask flushes are enough for both branches.
const flushPromises = async () => {
  for (let iteration = 0; iteration < 8; iteration++) {
    /* eslint-disable-next-line no-await-in-loop */
    await Promise.resolve();
  }
};

// Minimal stub of the parts of Prism the component touches. `highlightElement` mimics the real
// Prism behavior: it reads textContent, escapes it (no-op here - we assert on textContent, not
// innerHTML), and marks the element so tests can prove it ran. `highlight` isn't used but keeping
// it here documents the surface for future contributors.
function buildPrismStub() {
  return {
    languages: {},
    highlightElement: jest.fn(codeElement => {
      // Simulate Prism wrapping the source in token spans. Tests assert on data-prism-ran and on
      // the raw textContent (which stays the same because Prism preserves the source).
      codeElement.dataset.prismRan = 'true';
    }),
    highlight: jest.fn((source, _grammar, _language) => `HL(${source})`)
  };
}

describe('c-logger-notification-formula-editor', () => {
  let consoleErrorSpy;

  beforeEach(() => {
    global.Prism = buildPrismStub();
    mockLoadScriptImpl = jest.fn(() => Promise.resolve());
    mockLoadStyleImpl = jest.fn(() => Promise.resolve());
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    consoleErrorSpy.mockRestore();
    delete global.Prism;
    jest.clearAllMocks();
  });

  it('renders the shared editor scaffolding with a labeled textarea overlay', async () => {
    const element = createElement('c-logger-notification-formula-editor', { is: LoggerNotificationFormulaEditor });
    element.label = 'Source SObject Filter';
    element.placeholder = 'e.g. ISPICKVAL(...)';
    element.helpText = 'Salesforce formula syntax.';
    element.rows = 4;
    element.value = "ISPICKVAL(LoggingLevel__c, 'ERROR')";
    document.body.appendChild(element);
    await flushPromises();

    const label = element.shadowRoot.querySelector('label');
    expect(label).toBeTruthy();
    expect(label.textContent).toContain('Source SObject Filter');
    // Required-indicator is absent when `required` isn't set - the abbr renders inside the label
    // only when required=true.
    expect(label.querySelector('abbr.slds-required')).toBeNull();

    const textarea = element.shadowRoot.querySelector('textarea.formula-editor-textarea');
    expect(textarea).toBeTruthy();
    expect(textarea.getAttribute('placeholder')).toBe('e.g. ISPICKVAL(...)');
    // rows is a number attribute; LWC serializes it as a string.
    expect(String(textarea.getAttribute('rows'))).toBe('4');

    const helpBlock = element.shadowRoot.querySelector('.slds-form-element__help');
    expect(helpBlock).toBeTruthy();
    expect(helpBlock.textContent).toContain('Salesforce formula syntax.');
  });

  it('renders the required indicator when required is true', async () => {
    const element = createElement('c-logger-notification-formula-editor', { is: LoggerNotificationFormulaEditor });
    element.label = 'Filter';
    element.required = true;
    document.body.appendChild(element);
    await flushPromises();

    const requiredMarker = element.shadowRoot.querySelector('label abbr.slds-required');
    expect(requiredMarker).toBeTruthy();
    expect(requiredMarker.getAttribute('title')).toBe('required');
  });

  it('loads Prism resources from the core LoggerResources static resource on first render', async () => {
    const element = createElement('c-logger-notification-formula-editor', { is: LoggerNotificationFormulaEditor });
    element.value = 'AND(TRUE, FALSE)';
    document.body.appendChild(element);
    await flushPromises();

    expect(mockLoadScriptImpl).toHaveBeenCalledTimes(1);
    expect(mockLoadStyleImpl).toHaveBeenCalledTimes(1);
    // First arg is the component instance; second is the resource URL. Assert on the URL substring
    // so a future rename of the static resource proxy is easy to spot.
    const [, scriptUrl] = mockLoadScriptImpl.mock.calls[0];
    expect(scriptUrl).toContain('/Prism/prism.min.js');
    const [, styleUrl] = mockLoadStyleImpl.mock.calls[0];
    expect(styleUrl).toContain('/Prism/themes/prism-tomorrow.min.css');
  });

  it('registers a salesforce-formula grammar on Prism after resources load', async () => {
    const element = createElement('c-logger-notification-formula-editor', { is: LoggerNotificationFormulaEditor });
    element.value = "CONTAINS(Message__c, 'callout')";
    document.body.appendChild(element);
    await flushPromises();

    expect(global.Prism.languages['salesforce-formula']).toBeDefined();
    // Spot-check the grammar shape: named token categories that the CSS targets for coloring.
    expect(global.Prism.languages['salesforce-formula'].string).toBeDefined();
    expect(global.Prism.languages['salesforce-formula'].function).toBeInstanceOf(RegExp);
    expect(global.Prism.languages['salesforce-formula'].boolean).toBeInstanceOf(RegExp);
    expect(global.Prism.languages['salesforce-formula']['field-reference']).toBeInstanceOf(RegExp);
  });

  it('feeds the current value into the highlight layer and asks Prism to highlight it', async () => {
    const element = createElement('c-logger-notification-formula-editor', { is: LoggerNotificationFormulaEditor });
    element.value = "ISPICKVAL(LoggingLevel__c, 'ERROR')";
    document.body.appendChild(element);
    await flushPromises();

    const highlightCode = element.shadowRoot.querySelector('.formula-editor-highlight code');
    expect(highlightCode).toBeTruthy();
    expect(highlightCode.textContent).toBe("ISPICKVAL(LoggingLevel__c, 'ERROR')");
    // Component uses Prism.highlightElement rather than assigning innerHTML directly, so Prism is
    // responsible for the escaped source -> token markup transform.
    expect(global.Prism.highlightElement).toHaveBeenCalledWith(highlightCode);
    expect(highlightCode.dataset.prismRan).toBe('true');
  });

  it('appends a trailing space when the value ends with a newline so the caret stays visible', async () => {
    const element = createElement('c-logger-notification-formula-editor', { is: LoggerNotificationFormulaEditor });
    element.value = "AND(\n  ISPICKVAL(LoggingLevel__c, 'ERROR')\n";
    document.body.appendChild(element);
    await flushPromises();

    const highlightCode = element.shadowRoot.querySelector('.formula-editor-highlight code');
    // Real value: `...ERROR')\n`. Rendered in the pre: `...ERROR')\n ` (extra space) so a trailing
    // newline isn't collapsed and the pre's rendered end sits under the textarea's end-of-line
    // caret. Without the appended space the highlight would end one character short.
    expect(highlightCode.textContent.endsWith('\n ')).toBe(true);
  });

  it('normalises null / undefined incoming values to an empty string', async () => {
    const element = createElement('c-logger-notification-formula-editor', { is: LoggerNotificationFormulaEditor });
    element.value = null;
    document.body.appendChild(element);
    await flushPromises();
    expect(element.value).toBe('');

    element.value = undefined;
    await flushPromises();
    expect(element.value).toBe('');

    // Highlight layer stays empty rather than rendering `null` / `undefined` as source text.
    const highlightCode = element.shadowRoot.querySelector('.formula-editor-highlight code');
    expect(highlightCode.textContent).toBe('');
  });

  it('imperatively syncs the DOM textarea when the value property changes after first render', async () => {
    const element = createElement('c-logger-notification-formula-editor', { is: LoggerNotificationFormulaEditor });
    element.value = 'initial';
    document.body.appendChild(element);
    await flushPromises();

    const textarea = element.shadowRoot.querySelector('textarea.formula-editor-textarea');
    expect(textarea.value).toBe('initial');

    element.value = "OR(\n  ISPICKVAL(LoggingLevel__c, 'ERROR'),\n  ISPICKVAL(LoggingLevel__c, 'WARN')\n)";
    await flushPromises();

    // Without the imperative sync in renderedCallback, LWC's textarea `value` attribute binding
    // only fires on first render and later property changes wouldn't hit the DOM element.
    expect(textarea.value).toBe("OR(\n  ISPICKVAL(LoggingLevel__c, 'ERROR'),\n  ISPICKVAL(LoggingLevel__c, 'WARN')\n)");
    const highlightCode = element.shadowRoot.querySelector('.formula-editor-highlight code');
    expect(highlightCode.textContent).toContain('ISPICKVAL(LoggingLevel__c,');
  });

  it('re-highlights on every input event and re-dispatches a value-bearing input event', async () => {
    const element = createElement('c-logger-notification-formula-editor', { is: LoggerNotificationFormulaEditor });
    element.value = '';
    const inputHandler = jest.fn();
    element.addEventListener('input', inputHandler);
    document.body.appendChild(element);
    await flushPromises();

    // First highlight was fired by the initial render.
    const initialHighlightCount = global.Prism.highlightElement.mock.calls.length;

    const textarea = element.shadowRoot.querySelector('textarea.formula-editor-textarea');
    textarea.value = "AND(ISPICKVAL(LoggingLevel__c, 'ERROR'), HasException__c)";
    textarea.dispatchEvent(new CustomEvent('input'));
    await flushPromises();

    expect(global.Prism.highlightElement.mock.calls.length).toBeGreaterThan(initialHighlightCount);
    expect(inputHandler).toHaveBeenCalledTimes(1);
    const dispatchedEvent = inputHandler.mock.calls[0][0];
    // Parent forms in this repo pull the current value off `event.target.value` (native textarea
    // event semantics). Verify BOTH the re-dispatched CustomEvent's detail AND that the underlying
    // textarea still exposes the fresh value on event.target, since handleRuleFieldChange in the
    // guided form reads via event.target.value.
    expect(dispatchedEvent.detail.value).toBe("AND(ISPICKVAL(LoggingLevel__c, 'ERROR'), HasException__c)");
  });

  it('re-dispatches change events with the current value on detail', async () => {
    const element = createElement('c-logger-notification-formula-editor', { is: LoggerNotificationFormulaEditor });
    const changeHandler = jest.fn();
    element.addEventListener('change', changeHandler);
    document.body.appendChild(element);
    await flushPromises();

    const textarea = element.shadowRoot.querySelector('textarea.formula-editor-textarea');
    textarea.value = 'TotalERRORLogEntries__c >= 3';
    textarea.dispatchEvent(new CustomEvent('change'));
    await flushPromises();

    expect(changeHandler).toHaveBeenCalledTimes(1);
    expect(changeHandler.mock.calls[0][0].detail.value).toBe('TotalERRORLogEntries__c >= 3');
  });

  it('mirrors textarea scroll position onto the highlight layer so tokens track the caret', async () => {
    const element = createElement('c-logger-notification-formula-editor', { is: LoggerNotificationFormulaEditor });
    element.value = 'x';
    document.body.appendChild(element);
    await flushPromises();

    const textarea = element.shadowRoot.querySelector('textarea.formula-editor-textarea');
    const highlight = element.shadowRoot.querySelector('.formula-editor-highlight');
    // jsdom doesn't compute layout, so directly write the scroll properties to simulate a scroll.
    Object.defineProperty(textarea, 'scrollTop', { value: 42, configurable: true });
    Object.defineProperty(textarea, 'scrollLeft', { value: 12, configurable: true });
    textarea.dispatchEvent(new CustomEvent('scroll'));
    await flushPromises();

    expect(highlight.scrollTop).toBe(42);
    expect(highlight.scrollLeft).toBe(12);
  });

  it('flips the error-state data attribute when hasError is true', async () => {
    const element = createElement('c-logger-notification-formula-editor', { is: LoggerNotificationFormulaEditor });
    document.body.appendChild(element);
    await flushPromises();

    const wrapper = element.shadowRoot.querySelector('.slds-form-element');
    expect(wrapper.dataset.errorState).toBe('valid');

    element.hasError = true;
    await flushPromises();
    expect(wrapper.dataset.errorState).toBe('invalid');
  });

  it('exposes reportValidity and checkValidity by delegating to the underlying textarea', async () => {
    const element = createElement('c-logger-notification-formula-editor', { is: LoggerNotificationFormulaEditor });
    element.required = true;
    document.body.appendChild(element);
    await flushPromises();

    const textarea = element.shadowRoot.querySelector('textarea.formula-editor-textarea');
    // Passthrough delegates so a parent form's `.reportValidity()` sweep (used by
    // isCurrentStepValid in loggerNotificationRuleGuidedForm) can gate step advancement.
    textarea.reportValidity = jest.fn().mockReturnValue(false);
    textarea.checkValidity = jest.fn().mockReturnValue(false);

    expect(element.reportValidity()).toBe(false);
    expect(textarea.reportValidity).toHaveBeenCalledTimes(1);
    expect(element.checkValidity()).toBe(false);
    expect(textarea.checkValidity).toHaveBeenCalledTimes(1);
  });

  it('renders unstyled textContent and logs an aggregated error when Prism fails to load', async () => {
    mockLoadScriptImpl = jest.fn(() => Promise.reject(new Error('prism-load-boom')));

    const element = createElement('c-logger-notification-formula-editor', { is: LoggerNotificationFormulaEditor });
    element.value = "ISPICKVAL(LoggingLevel__c, 'ERROR')";
    document.body.appendChild(element);
    await flushPromises();

    const highlightCode = element.shadowRoot.querySelector('.formula-editor-highlight code');
    // Fallback path still renders the source text so the layout doesn't collapse; just no token
    // markup. Prism.highlightElement is NOT called because the load failed.
    expect(highlightCode.textContent).toBe("ISPICKVAL(LoggingLevel__c, 'ERROR')");
    expect(global.Prism.highlightElement).not.toHaveBeenCalled();
    expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
    // Guaranteed shape: message identifies the component, underlying error carries the boom.
    const [loggedMessage, loggedError] = consoleErrorSpy.mock.calls[0];
    expect(loggedMessage).toContain('formula editor');
    expect(loggedError).toBeInstanceOf(Error);
    expect(loggedError.message).toContain('prism-load-boom');
  });

  it('does not retry the Prism load on later renders after a failure', async () => {
    mockLoadScriptImpl = jest.fn(() => Promise.reject(new Error('boom')));
    const element = createElement('c-logger-notification-formula-editor', { is: LoggerNotificationFormulaEditor });
    element.value = 'first';
    document.body.appendChild(element);
    await flushPromises();

    expect(mockLoadScriptImpl).toHaveBeenCalledTimes(1);

    element.value = 'second';
    await flushPromises();

    // `hasFailedPrismLoad` gates the retry - subsequent renders leave the loader alone so a single
    // failure doesn't produce N repeated network calls as the admin types.
    expect(mockLoadScriptImpl).toHaveBeenCalledTimes(1);
    expect(mockLoadStyleImpl).toHaveBeenCalledTimes(1);
  });

  it('does not reload Prism resources on later renders after a successful load', async () => {
    const element = createElement('c-logger-notification-formula-editor', { is: LoggerNotificationFormulaEditor });
    element.value = 'first';
    document.body.appendChild(element);
    await flushPromises();

    expect(mockLoadScriptImpl).toHaveBeenCalledTimes(1);

    element.value = 'second';
    await flushPromises();
    element.value = 'third';
    await flushPromises();

    // hasLoadedPrism short-circuits loadPrismOnce; the loader runs exactly once per component.
    expect(mockLoadScriptImpl).toHaveBeenCalledTimes(1);
    expect(mockLoadStyleImpl).toHaveBeenCalledTimes(1);
  });
});
