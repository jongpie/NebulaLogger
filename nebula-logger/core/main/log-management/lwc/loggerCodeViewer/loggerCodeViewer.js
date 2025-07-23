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
    if (this._Prism) {
      // For some reason, calling highlightAll() twice is necessary to get the line highlighting to work.
      // When it's called only once, the line highlighting is not applied (when there is only one instance of the code viewer LWC on the page).
      //
      //
      //
      // Why? I don't know. (╯‵□′)╯︵┻━┻
      //
      //
      //
      // Is this a bug in Prism?
      // Is this a bug in LWC?
      // Is this a bug in Salesforce?
      // Is this a bug in the universe?
      //
      //
      //
      // I don't know.
      //
      // I just simply don't know ¯\_(ツ)_/¯
      //
      //
      //
      // Perhaps there are some things in life that we'll never understand.
      //
      //
      // Things that are simply beyond our comprehension.
      //
      //
      // But I DO know is that (👉ﾟヮﾟ)👉 calling highlightAll() twice in a row 👈(ﾟヮﾟ👈) seems to circumvent the issue.
      //
      //
      // So here we are, calling it twice...
      //
      // ...with just 1 extra line of code.....
      // ........................................
      // ......................
      // ...............................
      // ..............
      // ........................................and a whole bunch of ridiculous comments about it ^_^
      this._Prism.highlightAll();
      // o_O
      this._Prism.highlightAll();
    }

    this.isLoaded = true;
  }
}
