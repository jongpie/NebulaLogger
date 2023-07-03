import { LightningElement, api } from 'lwc';

// TODO move to a separate, dedicated Apex controller class or LWC service (?)
import getLogEntry from '@salesforce/apex/LogEntrySectionController.getLogEntry';

export default class LogEntryCodeSnippetViewer extends LightningElement {
    @api
    recordId;
    @api
    section;

    codeSnippet;
    logEntry;

    get sectionTitle() {
        if (this._showExceptionApexClassCode) {
            return 'Exception Apex Class Snippet';
        } else if (this._showLoggingApexClassCode) {
            return 'Apex Class Snippet';
        }
    }

    get _showExceptionApexClassCode() {
        return this.section === 'Exception Apex Class Snippet';
    }

    get _showLoggingApexClassCode() {
        return this.section === 'Logging Apex Class Snippet';
    }

    // get codeSnippet() {
    //     console.log('>>> loading codeSnippet for logEntry', JSON.parse(JSON.stringify(this.logEntry)));
    //     let snippet;
    //     if (this._showExceptionApexClassCode && this.logEntry?.ExceptionApexClassSnippet__c) {
    //         snippet = JSON.parse(this.logEntry?.ExceptionApexClassSnippet__c);
    //     } else if (this._showLoggingApexClassCode && this.logEntry?.ApexClassSnippet__c) {
    //         snippet = JSON.parse(this.logEntry?.ApexClassSnippet__c);
    //     }
    //     console.log('>>> loaded codeSnippet', snippet);
    //     return snippet;
    // }

    connectedCallback() {
        if (!this.recordId || this.logEntry) {
            return;
        }

        console.log('>>> running getLogEntry function', this.recordId);
        getLogEntry({ logEntryId: this.recordId }).then(result => {
            console.log('getLogEntry result', JSON.parse(JSON.stringify(result)));
            this.logEntry = result.logEntry;
            this.logEntryContext = result;
            console.log('>>> log entry context', JSON.parse(JSON.stringify(this.logEntryContext)));
            console.log('>>> log entry record', JSON.parse(JSON.stringify(this.logEntry)));
            // this.template.querySelector('.code-editor').innerHTML = `<pre><code class="language-apex">${this.logEntryContext.apexClass.Body}</code></pre>`;
            // this.template.querySelector('pre').innerHTML = Prism.highlight(`console.log('hello, world);`, Prism.languages.javascript, 'javascript');

            if (this._showExceptionApexClassCode && this.logEntry?.ExceptionApexClassSnippet__c) {
                this.codeSnippet = JSON.parse(this.logEntry?.ExceptionApexClassSnippet__c);
            } else if (this._showLoggingApexClassCode && this.logEntry?.ApexClassSnippet__c) {
                this.codeSnippet = JSON.parse(this.logEntry?.ApexClassSnippet__c);
            }
        });
    }
}
