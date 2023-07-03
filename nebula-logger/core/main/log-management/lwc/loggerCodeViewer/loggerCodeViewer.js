import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import resources from '@salesforce/resourceUrl/LoggerResources';

export default class LoggerCodeViewer extends LightningElement {
    @api code;
    @api endingLineNumber;
    @api startingLineNumber;
    @api targetLineNumber;

    renderedCallback() {
        Promise.all([loadScript(this, resources + '/prism.js'), loadStyle(this, resources + '/prism.css')])
            .then(() => {
                const container = this.template.querySelector('.container');
                container.innerHTML = `<pre data-start="${this.startingLineNumber}" data-line="4"><code class="language-apex">${this.code}</code></pre>`;

                Prism?.highlightAll();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: error.message,
                        title: 'Error loading code viewer',
                        variant: 'error'
                    })
                );
            });
    }
}
