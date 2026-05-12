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

  hasLoadError = false;
  isLoaded = false;

  async renderedCallback() {
    if (this.isLoaded || this.hasLoadError) {
      return;
    }

    try {
      await this._loadPrismResources();

      const container = this.template.querySelector('.prism-viewer');
      // data-line and data-line-offset are effectively the same thing within Prism...
      // but the core Prism code uses data-start for line numbers,
      // and the line-highlight plugin uses data-line-offset for highlighting a line number
      // (╯°□°）╯︵ ┻━┻
      // eslint-disable-next-line
      container.innerHTML =
        `<pre data-start="${this.startingLineNumber}" data-line="${this.targetLineNumber}" data-line-offset="${this.targetLineNumber}">` +
        `<code class="language-${this.language}">${this.code}</code>` +
        `</pre>`;
      this._highlightCode();
      this.isLoaded = true;
    } catch (error) {
      this.hasLoadError = true;
      this.isLoaded = true;
      this._renderFallbackCode();
      /* eslint-disable-next-line no-console */
      console.error(error.message, error);
    }
  }

  async _loadPrismResources() {
    const prismScriptUrl = loggerStaticResources + '/Prism/prism.min.js';
    const prismBaseStyleUrl = loggerStaticResources + '/Prism/themes/prism-tomorrow.min.css';
    const prismCustomStyleUrl = loggerStaticResources + '/Prism/prism.nebula-logger.css';

    const resourceLoads = [
      { resourceType: 'script', resourceUrl: prismScriptUrl, promise: loadScript(this, prismScriptUrl) },
      { resourceType: 'style', resourceUrl: prismBaseStyleUrl, promise: loadStyle(this, prismBaseStyleUrl) },
      { resourceType: 'style', resourceUrl: prismCustomStyleUrl, promise: loadStyle(this, prismCustomStyleUrl) }
    ];

    const resourceLoadResults = await Promise.all(
      resourceLoads.map(async ({ resourceType, resourceUrl, promise }) => {
        try {
          await promise;
          return { status: 'fulfilled', resourceType, resourceUrl };
        } catch (reason) {
          return { status: 'rejected', resourceType, resourceUrl, reason };
        }
      })
    );

    const failedResourceLoads = resourceLoadResults.filter(result => result.status === 'rejected');
    if (failedResourceLoads.length > 0) {
      const serializedLoadFailures = failedResourceLoads.map(this._serializeLoadFailure);

      throw new Error(`Failed to load Prism resources from LoggerResources static resource\n\n${JSON.stringify(serializedLoadFailures, null, 2)}`);
    }
  }

  _highlightCode() {
    // For some reason, calling Prism.highlightAll() twice is necessary (see below) to get the line highlighting to work.
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
    //

    // eslint-disable-next-line
    Prism.highlightAll();
    // o_O
    // eslint-disable-next-line
    Prism.highlightAll();
  }

  _serializeLoadFailure(failure) {
    const serializedFailure = {
      status: failure.status,
      resourceType: failure.resourceType,
      resourceUrl: failure.resourceUrl
    };

    if (failure.reason instanceof Error) {
      serializedFailure.reason = {
        name: failure.reason.name,
        message: failure.reason.message,
        stack: failure.reason.stack
      };
    } else {
      serializedFailure.reason = failure.reason;
      serializedFailure.reasonAsString = String(failure.reason);
    }

    return serializedFailure;
  }

  _renderFallbackCode() {
    const container = this.template.querySelector('.prism-viewer');
    if (!container) {
      return;
    }

    const codeToRender = this.code ?? '';
    container.textContent = '';
    const pre = document.createElement('pre');
    pre.className = 'slds-p-horizontal_medium';
    const code = document.createElement('code');
    code.textContent = codeToRender;
    pre.appendChild(code);
    container.appendChild(pre);
  }
}
