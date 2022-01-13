/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { api, LightningElement, wire } from 'lwc';
import getLog from '@salesforce/apex/Logger.getLog';

export default class LogJSON extends LightningElement {
    @api
    recordId;

    log;
    logJSON;
    jsonCopied = false;

    @wire(getLog, { logId: '$recordId' })
    wiredGetLog(result) {
        console.log('running wired getLog function', result);
        this.log = result;
        // console.log('this.log', this.log);

        let formattedLog;
        // Sort the keys (fields) in the log object
        if (result.data) {
            formattedLog = Object.keys(result.data)
                .sort()
                .reduce((obj, key) => {
                    obj[key] = result.data[key];
                    return obj;
                }, {});
        }
        // return formattedLog ? JSON.stringify(formattedLog, null, '\t') : '';
        this.logJSON = JSON.stringify(formattedLog, null, '\t');
        console.log('loaded log JSON', this.logJSON);
    }

    @api
    get title() {
        return this.log.data ? 'JSON for ' + this.log.data.Name : '';
    }

    get variant() {
        return this.jsonCopied ? 'success' : 'brand';
    }

    async copyToClipboard() {
        const value = this.template.querySelector('pre').textContent;

        const textArea = document.createElement('textarea');
        textArea.value = value;
        // Avoid scrolling to bottom
        textArea.style.top = '0';
        textArea.style.left = '0';
        textArea.style.position = 'fixed';

        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        document.execCommand('copy');
        document.body.removeChild(textArea);

        /* eslint-disable-next-line no-console */
        console.log('Log data successfully copied to clipboard', JSON.parse(value));
        this.jsonCopied = true;

        /* eslint-disable-next-line @lwc/lwc/no-async-operation */
        setTimeout(() => {
            this.jsonCopied = false;
        }, 5000);
    }
}
