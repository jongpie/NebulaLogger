/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement, api, wire } from 'lwc';
import getLog from '@salesforce/apex/LogViewerController.getLog';
import LOG_ENTRY_EPOCH_TIMESTAMP_FIELD from '@salesforce/schema/LogEntry__c.EpochTimestamp__c';
import LOG_ENTRY_LOGGING_LEVEL_FIELD from '@salesforce/schema/LogEntry__c.LoggingLevel__c';
import LOG_ENTRY_MESSAGE_FIELD from '@salesforce/schema/LogEntry__c.Message__c';
import LOG_ENTRY_STACK_TRACE_FIELD from '@salesforce/schema/LogEntry__c.StackTrace__c';
import LOG_ORGANIZATION_ID_FIELD from '@salesforce/schema/Log__c.OrganizationId__c';

export default class LogViewer extends LightningElement {
    // logId is deprecated - it was used before quickActions supported LWC.
    // recordId is now used instead, but logId has to be kept for the managed package
    @api
    logId; // Deprecated

    @api
    recordId;

    isLoaded = false;
    logEntriesRelationshipName = '';
    log = {};
    currentMode = {};
    dataCopied = false;

    _logFileContent;
    _logJSONContent;

    @wire(getLog, { logId: '$recordId' })
    wiredGetLog(result) {
        if (result.data) {
            const reconstructedLog = JSON.parse(JSON.stringify(result.data.log));
            this.logEntriesRelationshipName = result.data.logEntriesRelationshipName;
            reconstructedLog[this.logEntriesRelationshipName] = JSON.parse(JSON.stringify(result.data.logEntries));
            this.log = reconstructedLog;
            this._loadLogFileContent();
            this._loadLogJSONContent();
            this.isLoaded = true;
        }
    }

    @api
    get title() {
        return this.log?.Name;
    }

    get variant() {
        return this.dataCopied ? 'success' : 'brand';
    }

    get downloadButtonLabel() {
        return `Download ${this.currentMode?.label}`;
    }

    handleTabActivated(event) {
        this.currentMode = {
            label: event.target.label,
            value: event.target.value
        };

        /* eslint-disable-next-line default-case */
        switch (this.currentMode.value) {
            case 'file':
                this.currentMode.data = this._logFileContent;
                this.currentMode.extension = 'log';
                break;
            case 'json':
                this.currentMode.data = this._logJSONContent;
                this.currentMode.extension = 'json';
                break;
        }
    }

    async copyToClipboard() {
        const value = this.currentMode.data;

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
        console.log('Log data successfully copied to clipboard', value);
        this.dataCopied = true;

        /* eslint-disable-next-line @lwc/lwc/no-async-operation */
        setTimeout(() => {
            this.dataCopied = false;
        }, 5000);
    }

    async downloadFile() {
        const exportedFilename = this.log.Name + '_' + this.log[LOG_ORGANIZATION_ID_FIELD.fieldApiName] + '.' + this.currentMode.extension;
        const encodedValue = encodeURIComponent(this.currentMode.data);

        const link = window.document.createElement('a');
        link.href = 'data:text;charset=utf-8,' + encodedValue;
        link.target = '_blank';
        link.download = exportedFilename;
        link.click();
    }

    _loadLogFileContent() {
        const fieldDelimiter = '\n';
        const lineDelimiter = '\n\n' + '-'.repeat(36) + '\n\n';
        const logFileLines = [];

        this.log[this.logEntriesRelationshipName].forEach(logEntry => {
            const columns = [];
            columns.push(
                '[' +
                    new Date(logEntry[LOG_ENTRY_EPOCH_TIMESTAMP_FIELD.fieldApiName]).toISOString() +
                    ' - ' +
                    logEntry[LOG_ENTRY_LOGGING_LEVEL_FIELD.fieldApiName] +
                    ']'
            );
            columns.push('[Message]\n' + logEntry[LOG_ENTRY_MESSAGE_FIELD.fieldApiName]);
            columns.push('\n[Stack Trace]\n' + logEntry[LOG_ENTRY_STACK_TRACE_FIELD.fieldApiName]);

            logFileLines.push(columns.join(fieldDelimiter));
        });
        this._logFileContent = logFileLines.join(lineDelimiter);
    }

    _loadLogJSONContent() {
        // Sort the keys (fields) in the log object
        let formattedLog;
        formattedLog = Object.keys(this.log)
            .sort()
            .reduce((obj, key) => {
                obj[key] = this.log[key];
                return obj;
            }, {});
        this._logJSONContent = JSON.stringify(formattedLog, null, '\t');
    }
}
