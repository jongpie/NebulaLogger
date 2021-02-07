import { api, LightningElement, wire } from 'lwc';
import getLog from '@salesforce/apex/Logger.getLog';

export default class LogJSONViewer extends LightningElement {
    @api
    recordId;
    @wire(getLog, { logId: '$recordId' })
    log;

    jsonCopied = false;

    get logJson() {
        return this.log.data ? JSON.stringify(this.log.data, null, '\t') : '';
    }

    get title() {
        return this.log.data ? 'JSON for ' + this.log.data.Name : '';
    }

    get variant() {
        return this.jsonCopied ? 'success' : 'brand';
    }

    copyToClipboard(value) {
        // Add a hidden input to store the JSON
        const hiddenJSONInput = document.createElement('input');
        hiddenJSONInput.setAttribute('value', value);
        document.body.appendChild(hiddenJSONInput);
        hiddenJSONInput.select();

        // Copy to clipboard
        document.execCommand('copy');
        document.body.removeChild(hiddenJSONInput);
        this.jsonCopied = true;
    }
}
