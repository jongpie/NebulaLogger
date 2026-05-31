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
      this._renderPrismHtml();
      Prism.highlightAll();
    } catch (error) {
      this._renderPrismHtml();
      /* eslint-disable-next-line no-console */
      console.error(error.message, error);
      this.hasLoadError = true;
    } finally {
      this.isLoaded = true;
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

  _renderPrismHtml() {
    /*
      A few notes on using Prism:
        1. The `line-numbers` class must be on the <pre> itself (not just on an
          ancestor) before highlightAll runs. Otherwise line-highlight's
          'complete' hook takes its non-deferred branch, runs before line-numbers
          has built the gutter, and ends up appending an unpositioned overlay.

        2. The properties data-line and data-line-offset are effectively the same thing within Prism...
          but the core Prism code uses data-start for line numbers,
          and the line-highlight plugin uses data-line-offset for highlighting a line number

          (╯°□°）╯︵ ┻━┻
     */

    const container = this.template.querySelector('.prism-viewer');
    // eslint-disable-next-line
    container.innerHTML =
      `<pre class="line-numbers" data-start="${this.startingLineNumber}" data-line="${this.targetLineNumber}" data-line-offset="${this.targetLineNumber}">` +
      `<code class="language-${this.language}">${this.code ?? ''}</code>` +
      `</pre>`;
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
}
