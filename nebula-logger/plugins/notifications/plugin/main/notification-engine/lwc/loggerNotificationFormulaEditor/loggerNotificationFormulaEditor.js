/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement, api } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
// Prism ships in the core Nebula Logger LoggerResources static resource. The notifications
// plugin declares core as a dependency in sfdx-project.json, so this import resolves at both
// deploy time and runtime without needing a plugin-local copy of Prism.
import loggerStaticResources from '@salesforce/resourceUrl/LoggerResources';

// Salesforce formula built-in functions. Not exhaustive - matches the subset most commonly used
// in filter formulas. Adding more is cheap: append the identifier to the array; the Prism grammar
// picks them up because it references the array in the built regex.
const SALESFORCE_FORMULA_FUNCTIONS = [
  'AND',
  'BEGINS',
  'BLANKVALUE',
  'CASE',
  'CONTAINS',
  'DATE',
  'DATEVALUE',
  'DAY',
  'FIND',
  'HOUR',
  'IF',
  'ISBLANK',
  'ISCHANGED',
  'ISNEW',
  'ISNULL',
  'ISNUMBER',
  'ISPICKVAL',
  'LEFT',
  'LEN',
  'LOWER',
  'MID',
  'MINUTE',
  'MONTH',
  'NOT',
  'NOW',
  'NULLVALUE',
  'OR',
  'REGEX',
  'RIGHT',
  'SECOND',
  'SUBSTITUTE',
  'TEXT',
  'TIMEVALUE',
  'TODAY',
  'TRIM',
  'UPPER',
  'VALUE',
  'YEAR'
];

// Formula literals treated as reserved words. Case-sensitive to match how the Formula engine
// interprets them (`true` isn't the same as `TRUE` inside a formula).
const SALESFORCE_FORMULA_BOOLEANS = ['TRUE', 'FALSE', 'NULL'];

// Registers a minimal Prism grammar for Salesforce formulas. Intentionally narrow: strings,
// numbers, functions, booleans, operators, custom-field references (identifiers ending in `__c`
// or `__r`), and global-context prefixes (`$User`, `$Setup`, etc.). Anything unmatched falls
// through as unstyled prose. Trying to match Setup's editor pixel-for-pixel is a rabbit hole;
// the goal here is "the filter reads as code, not as sentence."
//
// Idempotent by checking the grammar object rather than a module-level flag: Prism's own
// registry is what matters, and re-assigning the same regex-built object is cheap. Checking the
// Prism instance directly also means the grammar gets re-registered per Prism instance, which
// keeps jest tests (fresh Prism stub per test) working without special setup.
function registerSalesforceFormulaGrammar(prism) {
  if (!prism || !prism.languages || prism.languages['salesforce-formula']) {
    return;
  }
  const functionsPattern = SALESFORCE_FORMULA_FUNCTIONS.join('|');
  const booleansPattern = SALESFORCE_FORMULA_BOOLEANS.join('|');
  prism.languages['salesforce-formula'] = {
    // Salesforce formulas allow both C-style block comments (`/* ... */`) and single-line comments
    // (`// ...`). Comments come FIRST in the grammar so their contents don't get re-tokenized as
    // operators / field references / strings by the rules below. `greedy: true` lets Prism skip
    // ahead past matched comment ranges rather than trying every rule at every position inside a
    // comment - important so a `//` inside a `/* ... */` block doesn't spawn a nested match.
    comment: {
      pattern: /\/\*[\s\S]*?\*\/|\/\/.*/,
      greedy: true
    },
    // Single-quoted strings only (Salesforce formulas don't use double quotes). Handles a simple
    // backslash escape so `\'` inside a string doesn't end the string prematurely.
    string: {
      pattern: /'(?:\\.|[^'\\])*'/,
      greedy: true
    },
    // Numbers with optional sign / decimal. `\b` on both ends so field names like `Foo7__c` don't
    // get their trailing digits highlighted as a separate number.
    number: /\b-?\d+(?:\.\d+)?\b/,
    // Global-context references like `$User.Id`, `$Setup.Foo__c`.
    'global-variable': /\$[A-Za-z_][A-Za-z0-9_]*/,
    // Function names. Case-insensitive so `and(...)` still highlights as a function (formulas are
    // typically upper-case but the engine accepts either). `(?=\s*\()` requires the following
    // paren so a bare identifier that happens to spell `IF` doesn't get styled.
    function: new RegExp(`\\b(?:${functionsPattern})\\b(?=\\s*\\()`, 'i'),
    boolean: new RegExp(`\\b(?:${booleansPattern})\\b`),
    // Custom field / relationship references. Matches anything ending in `__c` or `__r`, with an
    // optional relationship path prefix (`Log__r.LogEntry__c`).
    'field-reference': /\b(?:[A-Za-z_][A-Za-z0-9_]*\.)*[A-Za-z_][A-Za-z0-9_]*__[cr]\b/,
    // Operators - comparison, boolean, arithmetic. Order matters: `<=` before `<`, `!=` before `!`.
    operator: /<=|>=|==|!=|&&|\|\||[+\-*/=<>!&]/,
    punctuation: /[(),.]/
  };
}

export default class LoggerNotificationFormulaEditor extends LightningElement {
  // Value + label + placeholder are `@api` so the parent form binds to them the same way it would
  // bind to a lightning-textarea. `onchange` and `oninput` on the host element carry the same
  // detail shape as a native textarea event: `event.detail.value` holds the current text.
  @api label;
  @api placeholder;
  @api helpText;
  @api required = false;
  @api rows = 4;
  // True to render the error-state border. Parent forms flip this based on their own validation
  // (e.g. `errorMessage` came back from validateSourceSObjectFilter). Component doesn't do its
  // own validation - Prism is a highlighter, not a parser.
  @api hasError = false;

  // Backing store for the reactive `value` getter/setter. Kept private so we can normalise
  // `null` / `undefined` incoming values to empty strings on the way in.
  _value = '';
  hasLoadedPrism = false;
  hasFailedPrismLoad = false;

  @api
  get value() {
    return this._value;
  }
  set value(nextValue) {
    // Coerce incoming null / undefined (which is what a fresh `rule.SourceSObjectFilter__c` will
    // be on a create-mode wizard) so the textarea receives an actual string and the highlight
    // pass doesn't crash when the grammar regexes try to run against `undefined`.
    this._value = nextValue ?? '';
  }

  get errorStateClass() {
    return this.hasError ? 'invalid' : 'valid';
  }

  async renderedCallback() {
    if (!this.hasLoadedPrism && !this.hasFailedPrismLoad) {
      await this.loadPrismOnce();
    }
    this.applyHighlight();
    this.syncTextareaValue();
  }

  // Loads Prism from the core static resource. Mirrors loggerCodeViewer's approach but registers
  // the salesforce-formula grammar afterwards. `hasFailedPrismLoad` gates the retry - if the initial load
  // fails, the component falls back to rendering the textarea alone (unstyled), same
  // graceful-degradation shape loggerCodeViewer uses.
  async loadPrismOnce() {
    const prismScriptUrl = loggerStaticResources + '/Prism/prism.min.js';
    const prismStyleUrl = loggerStaticResources + '/Prism/themes/prism-tomorrow.min.css';
    try {
      await Promise.all([loadScript(this, prismScriptUrl), loadStyle(this, prismStyleUrl)]);
      registerSalesforceFormulaGrammar(window.Prism);
      this.hasLoadedPrism = true;
    } catch (loadError) {
      /* eslint-disable-next-line no-console */
      console.error('Nebula Logger: could not load Prism for formula editor', loadError);
      this.hasFailedPrismLoad = true;
    }
  }

  // Rewrites the highlighted <code> element by delegating to Prism.highlightElement. Prism reads
  // the element's `textContent`, escapes it (so `<` / `>` / `&` in the raw formula can't inject
  // markup), tokenizes against the salesforce-formula grammar, and writes the tokenized HTML back onto
  // the same element. This is the same path loggerCodeViewer uses via Prism.highlightAll and is
  // the documented Prism API for updating highlighted content in place.
  //
  // Trailing newline gets an added space so the caret at end-of-line stays visible - without it,
  // Prism collapses the trailing whitespace and the highlighted layer ends a character short of
  // where the textarea's caret sits.
  applyHighlight() {
    const highlightCode = this.template.querySelector('.formula-editor-highlight code');
    if (!highlightCode) {
      return;
    }
    const displayText = this.appendTrailingSpaceIfNeeded(this._value);
    // Always set textContent first: this both provides the escaped source Prism will tokenize
    // AND acts as a safe fallback when Prism isn't loaded (grammar failure, load error, jest
    // environment without loadScript). The textarea layout still lines up because the fallback
    // is the exact same text with no wrapping markup.
    highlightCode.textContent = displayText;
    if (this.hasLoadedPrism && window.Prism && window.Prism.languages && window.Prism.languages['salesforce-formula']) {
      window.Prism.highlightElement(highlightCode);
    }
  }

  appendTrailingSpaceIfNeeded(rawText) {
    return rawText.endsWith('\n') ? rawText + ' ' : rawText;
  }

  // The textarea's `value={value}` binding only wires the initial render; subsequent setter
  // updates from the parent don't push into the DOM textarea by themselves. Same imperative
  // sync loggerNotificationRuleGuidedForm does for its config JSON textareas.
  syncTextareaValue() {
    const textarea = this.template.querySelector('.formula-editor-textarea');
    if (textarea && textarea.value !== this._value) {
      textarea.value = this._value;
    }
  }

  handleInput(event) {
    this._value = event.target.value;
    this.applyHighlight();
    // Re-dispatch as a plain change event so the parent's `onchange={handleRuleFieldChange}`
    // wiring still receives updates. `handleRuleFieldChange` reads `event.target.value`, which
    // works here because the native <textarea> is the event's target.
    this.dispatchEvent(new CustomEvent('input', { detail: { value: this._value } }));
  }

  handleChange(event) {
    this._value = event.target.value;
    this.dispatchEvent(new CustomEvent('change', { detail: { value: this._value } }));
  }

  // Keeps the highlighted <pre> scrolled in lockstep with the textarea. Without this, an admin
  // typing a formula longer than the visible height sees the caret disappear off the bottom of
  // the textarea while the highlight layer stays pinned to the top.
  handleScroll(event) {
    const highlight = this.template.querySelector('.formula-editor-highlight');
    if (highlight) {
      highlight.scrollTop = event.target.scrollTop;
      highlight.scrollLeft = event.target.scrollLeft;
    }
  }

  // Public passthrough for parent forms that call `.reportValidity()` on every input to build a
  // "which step is valid" gate (see `isCurrentStepValid` in loggerNotificationRuleGuidedForm).
  // Delegates to the underlying textarea so the native required-field validation still fires.
  @api
  reportValidity() {
    const textarea = this.template.querySelector('.formula-editor-textarea');
    if (!textarea) {
      return true;
    }
    return textarea.reportValidity();
  }

  @api
  checkValidity() {
    const textarea = this.template.querySelector('.formula-editor-textarea');
    if (!textarea) {
      return true;
    }
    return textarea.checkValidity();
  }
}
