/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement, api } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import loggerStaticResources from '@salesforce/resourceUrl/LoggerResources';

export default class LoggerCodeViewer extends LightningElement {
  _code;
  _language;
  _startingLineNumber;
  _targetLineNumber;

  isLoaded = false;
  _Prism;

  @api
  get code() {
    return this._code;
  }
  set code(value) {
    this._code = value;
    if (this.isLoaded) {
      this._renderCode();
    }
  }

  @api
  get language() {
    return this._language;
  }
  set language(value) {
    this._language = value;
    if (this.isLoaded) {
      this._renderCode();
    }
  }

  @api
  get startingLineNumber() {
    return this._startingLineNumber;
  }
  set startingLineNumber(value) {
    this._startingLineNumber = value;
    if (this.isLoaded) {
      this._renderCode();
    }
  }

  @api
  get targetLineNumber() {
    return this._targetLineNumber;
  }
  set targetLineNumber(value) {
    this._targetLineNumber = value;
    if (this.isLoaded) {
      this._renderCode();
    }
  }

  async renderedCallback() {
    if (this.isLoaded) {
      return;
    }

    try {
      await Promise.all([loadStyle(this, loggerStaticResources + '/prism.css'), loadScript(this, loggerStaticResources + '/prism.js')]);

      // eslint-disable-next-line no-undef
      this._Prism = Prism;

      this._renderCode();
      this.isLoaded = true;
    } catch (error) {
      console.error('Error loading Prism.js:', error);
    }
  }

  _renderCode() {
    const container = this.template.querySelector('.prism-viewer');
    if (!container) return;

    // Clear any existing content
    container.innerHTML = '';

    // Create the pre element with proper attributes for line highlighting
    const preElement = document.createElement('pre');
    preElement.setAttribute('data-start', this.startingLineNumber || 1);

    // Set line highlighting attributes
    if (this.targetLineNumber) {
      preElement.setAttribute('data-line', this.targetLineNumber);
      preElement.setAttribute('data-line-offset', this.targetLineNumber);
    }

    // Create the code element
    const codeElement = document.createElement('code');
    codeElement.className = `language-${this.language || 'text'}`;
    codeElement.textContent = this.code || '';

    // Assemble the structure
    preElement.appendChild(codeElement);
    container.appendChild(preElement);

    // Use multiple timing strategies to ensure highlighting works
    this._applyHighlighting(container, preElement);
  }

  _applyHighlighting(container, preElement) {
    // Strategy 1: Immediate highlighting
    if (this._Prism) {
      this._Prism.highlightAllUnder(container);
    }

    // Strategy 2: Delayed highlighting to ensure DOM is ready
    setTimeout(() => {
      if (this._Prism) {
        this._Prism.highlightAllUnder(container);

        // Force line highlighting plugin to work
        if (this.targetLineNumber && this._Prism.plugins.lineHighlight) {
          // Trigger the line highlighting plugin manually
          const highlightFunction = this._Prism.plugins.lineHighlight.highlightLines(preElement);
          if (typeof highlightFunction === 'function') {
            highlightFunction();
          }
        }
      }
    }, 0);

    // Strategy 3: Additional delay for edge cases
    setTimeout(() => {
      if (this._Prism) {
        this._Prism.highlightAllUnder(container);

        // Force a re-render of line highlighting if target line is specified
        if (this.targetLineNumber && this._Prism.plugins.lineHighlight) {
          // Trigger line highlighting manually
          const event = new Event('DOMContentLoaded');
          document.dispatchEvent(event);
        }
      }
    }, 50);

    // Strategy 4: Final attempt with longer delay for stubborn cases
    setTimeout(() => {
      if (this._Prism && this.targetLineNumber) {
        // Force re-highlighting and ensure line highlighting is applied
        this._Prism.highlightAllUnder(container);

        // Manually create line highlighting if plugin didn't work
        if (this._Prism.plugins.lineHighlight) {
          const highlightFunction = this._Prism.plugins.lineHighlight.highlightLines(preElement);
          if (typeof highlightFunction === 'function') {
            highlightFunction();
          }
        }
      }
    }, 100);
  }
}
