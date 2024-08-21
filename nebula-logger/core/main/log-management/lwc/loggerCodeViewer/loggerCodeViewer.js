/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement, api } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import loggerStaticResources from '@salesforce/resourceUrl/LoggerResources';

export default class LoggerCodeViewer extends LightningElement {
  @api code;
  @api language;
  @api startingLineNumber;
  @api targetLineNumber;

  isLoaded = false;

  _Prism;

  async renderedCallback() {
    if (this.isLoaded) {
      return;
    }

    await Promise.all([loadStyle(this, loggerStaticResources + '/prism.css'), loadScript(this, loggerStaticResources + '/prism.js')]);

    const container = this.template.querySelector('.prism-viewer');
    // data-line and data-line-offset are effectively the same thing within Prism...
    // but the core Prism code uses data-start for line numbers,
    // and the line-highlight plugin uses data-line-offset for highlighting a line number
    // (╯°□°）╯︵ ┻━┻
    // eslint-disable-next-line @lwc/lwc/no-inner-html
    container.innerHTML =
      `<pre data-start="${this.startingLineNumber}" data-line="${this.targetLineNumber}" data-line-offset="${this.targetLineNumber}">` +
      `<code class="language-${this.language}">${this.code}</code>` +
      `</pre>`;
    // eslint-disable-next-line no-undef
    this._Prism = Prism;
    await this._Prism.highlightAll();
    this.isLoaded = true;
  }
}
