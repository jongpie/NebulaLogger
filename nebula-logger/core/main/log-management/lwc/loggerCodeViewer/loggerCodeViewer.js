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

        // console.log('>>> aaaaaand setting innerHTML');
        // await Promise.resolve(() => {
        //     container.innerHTML =
        //     // data-line and data-line-offset are effectively the same thing within Prism...
        //     // but the core Prism code uses data-start for line numbers,
        //     // and the line-highlight plugin uses data-line-offset for highlighting a line number
        //     // (╯°□°）╯︵ ┻━┻
        //     `<pre data-start="${this.startingLineNumber}" data-line="${this.targetLineNumber}" data-line-offset="${this.targetLineNumber}">` +
        //     `<code class="language-${this.language}">${this.code}</code>` +
        //     `</pre>`;
        // });
        // // await Promise.resolve();
        // console.log('>>> aaaaaand set innerHTML', container.innerHTML);

        // await new Promise(async (resolve, reject) => {
        //     console.log('>>> setting innerHTML');
        //     container.innerHTML =
        //         // data-line and data-line-offset are effectively the same thing within Prism...
        //         // but the core Prism code uses data-start for line numbers,
        //         // and the line-highlight plugin uses data-line-offset for highlighting a line number
        //         // (╯°□°）╯︵ ┻━┻
        //         `<pre data-start="${this.startingLineNumber}" data-line="${this.targetLineNumber}" data-line-offset="${this.targetLineNumber}">` +
        //         `<code class="language-${this.language}">${this.code}</code>` +
        //         `</pre>`;
        //     await Promise.resolve();
        //     console.log('>>> set innerHTML', container.innerHTML);

        //     return resolve(true);
        // }).then(() => {
        //     console.log('>>> starting to load script & style');
        //     // return Promise.all([loadScript(this, loggerStaticResources + '/prism.js'), loadStyle(this, loggerStaticResources + '/prism.css')])
        //     return Promise.all([loadScript(this, loggerStaticResources + '/prism.js'), loadStyle(this, loggerStaticResources + '/prism.css')]).then(() => {
        //         console.log('>>> Prism', Prism);
        //         Prism.highlightAll();
        //         this.isLoaded = true;
        //     })
        // // }).then((args) => {
        // //     Prism.highlightAll();
        // //     this.isLoaded = true;
        // })

        // const container = this.template.querySelector('.prism-viewer');

        //     // eslint-disable-next-line @lwc/lwc/no-inner-html
        //     container.innerHTML =
        //         // data-line and data-line-offset are effectively the same thing within Prism...
        //         // but the core Prism code uses data-start for line numbers,
        //         // and the line-highlight plugin uses data-line-offset for highlighting a line number
        //         // (╯°□°）╯︵ ┻━┻
        //         `<pre data-start="${this.startingLineNumber}" data-line="${this.targetLineNumber}" data-line-offset="${this.targetLineNumber}">` +
        //         `<code class="language-${this.language}">${this.code}</code>` +
        //         `</pre>`;

        //         await Promise.resolve();
        await loadStyle(this, loggerStaticResources + '/prism.css');
        await loadScript(this, loggerStaticResources + '/prism.js');

        // Promise.resolve(loadStyle(this, loggerStaticResources + '/prism.css')).then(Promise.resolve(loadScript(this, loggerStaticResources + '/prism.js')))
        //     loadStyle(this, loggerStaticResources + '/prism.css')})
        //         .then(() => {
        // Promise.all([loadStyle(this, loggerStaticResources + '/prism.css'), loadScript(this, loggerStaticResources + '/prism.js')]).then(() => {

        const container = this.template.querySelector('.prism-viewer');
        // // eslint-disable-next-line @lwc/lwc/no-inner-html
        container.innerHTML =
            // data-line and data-line-offset are effectively the same thing within Prism...
            // but the core Prism code uses data-start for line numbers,
            // and the line-highlight plugin uses data-line-offset for highlighting a line number
            // (╯°□°）╯︵ ┻━┻
            `<pre data-start="${this.startingLineNumber}" data-line="${this.targetLineNumber}" data-line-offset="${this.targetLineNumber}">` +
            `<code class="language-${this.language}">${this.code}</code>` +
            `</pre>`;

        // eslint-disable-next-line no-undef
        this._Prism = Prism;
        // console.log('>>> this._Prism', this._Prism);
        // console.log('>>> this._Prism.highlightAll', this._Prism.highlightAll);
        console.log('>>>> this._Prism: ', this._Prism);
        await this._Prism.highlightAll();
        // await this._Prism.highlightAll();
        this.isLoaded = true;
        // setTimeout(() => this._Prism.highlightAll(), 0);
        //     return Prism;
        // }).then((Prism) => {
        //     Prism.highlightAll();
        // });
    }
}
