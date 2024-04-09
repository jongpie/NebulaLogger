/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import canViewLogEntryMetadata from '@salesforce/apex/LogEntryMetadataViewerController.canViewLogEntryMetadata';
import getMetadata from '@salesforce/apex/LogEntryMetadataViewerController.getMetadata';

import LOG_ENTRY_OBJECT from '@salesforce/schema/LogEntry__c';
import EXCEPTION_SOURCE_API_NAME_FIELD from '@salesforce/schema/LogEntry__c.ExceptionSourceApiName__c';
import EXCEPTION_SOURCE_API_VERSION_FIELD from '@salesforce/schema/LogEntry__c.ExceptionSourceApiVersion__c';
import EXCEPTION_SOURCE_METADATA_TYPE_FIELD from '@salesforce/schema/LogEntry__c.ExceptionSourceMetadataType__c';
import EXCEPTION_SOURCE_SNIPPET_FIELD from '@salesforce/schema/LogEntry__c.ExceptionSourceSnippet__c';
import ORIGIN_SOURCE_API_NAME_FIELD from '@salesforce/schema/LogEntry__c.OriginSourceApiName__c';
import ORIGIN_SOURCE_API_VERSION_FIELD from '@salesforce/schema/LogEntry__c.OriginSourceApiVersion__c';
import ORIGIN_SOURCE_METADATA_TYPE_FIELD from '@salesforce/schema/LogEntry__c.OriginSourceMetadataType__c';
import ORIGIN_SOURCE_SNIPPET_FIELD from '@salesforce/schema/LogEntry__c.OriginSourceSnippet__c';

const LOG_ENTRY_FIELDS = [
    EXCEPTION_SOURCE_API_NAME_FIELD,
    EXCEPTION_SOURCE_API_VERSION_FIELD,
    EXCEPTION_SOURCE_METADATA_TYPE_FIELD,
    EXCEPTION_SOURCE_SNIPPET_FIELD,
    ORIGIN_SOURCE_API_NAME_FIELD,
    ORIGIN_SOURCE_API_VERSION_FIELD,
    ORIGIN_SOURCE_METADATA_TYPE_FIELD,
    ORIGIN_SOURCE_SNIPPET_FIELD
];

export default class LogEntryMetadataViewer extends LightningElement {
    @api recordId;
    @api sourceMetadata;

    objectApiName = LOG_ENTRY_OBJECT;
    hasLoaded = false;
    sourceSnippet;

    showFullSourceMetadataModal = false;
    showSourceMetadataModifiedWarning = false;
    fullSourceMetadataTitle;
    fullSourceMetadata;

    _logEntry;
    _logEntryMetadata;

    // get hasLoaded() {
    //     return !!this._logEntry && !!this._logEntryMetadata;
    // }

    get sectionTitle() {
        if (this.sourceMetadata === 'Exception') {
            return 'Exception Source Metadata';
        } else if (this.sourceMetadata === 'Origin') {
            return 'Origin Source Metadata';
        }
        return '';
    }

    get hasFullSourceMetadata() {
        return !!this._logEntryMetadata?.Code;
    }

    get fullSourceModalNotificationClasses() {
        const classNames = ['slds-notify', 'slds-notify_alert'];
        classNames.push(this._logEntryMetadata?.HasCodeBeenModified ? 'slds-alert_warning' : 'slds-alert_offline');
        return classNames.join(' ');
    }

    get fullSourceModalNotificationIcon() {
        return this._logEntryMetadata?.HasCodeBeenModified ? 'utility:warning' : 'utility:success';
    }

    get fullSourceModalNotificationMessage() {
        return this._logEntryMetadata?.HasCodeBeenModified
            ? 'This Apex code has been modified since this log entry was generated.'
            : 'This Apex code has not been modified since this log entry was generated.';
    }

    // async connectedCallback() {
    //     console.log('>>> about to call canViewLogEntryMetadata()');
    //     const res = await canViewLogEntryMetadata();
    //     console.log('>>> canViewLogEntryMetadata result', res);
    //     // const res = await canUserModifyLoggerSettings();
    //     // console.log('>>> canUserModifyLoggerSettings result', res);
    // }

    // async renderedCallback() {
    //     if (!this.recordId || !this.sourceMetadata) {
    //         return;
    //     }

    //     console.log('>>> got a record id and source metadata, going to call method testing');
    //     const res = await getMetadata({ recordId: this.recordId, sourceMetadata: this.sourceMetadata });
    //     console.log('>>> getMetadata res', res);
    // }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: LOG_ENTRY_FIELDS
    })
    async wiredGetLogEntry({ data }) {
        if (data) {
            this._logEntry = data;

            const { sourceApiNameField, sourceApiVersionField, sourceMetadataTypeField, sourceSnippetField } = this._getSourceFields();
            const sourceSnippetJson = getFieldValue(this._logEntry, sourceSnippetField);

            if (!sourceSnippetJson) {
                return;
            }

            const sourceMetadataType = getFieldValue(this._logEntry, sourceMetadataTypeField);
            const sourceExtension = this._getSourceExtension(sourceMetadataType);

            const sourceApiName = getFieldValue(this._logEntry, sourceApiNameField);
            const sourceApiVersion = getFieldValue(this._logEntry, sourceApiVersionField);
            const sourceName = `${sourceApiName}.${sourceExtension} - ${sourceApiVersion}`;
            this.sourceSnippet = { ...JSON.parse(sourceSnippetJson), ...{ Title: sourceName } };

            console.log('>>> about to load metadata');
            this.hasLoaded = true;
            this._logEntryMetadata = await getMetadata({
                recordId: this.recordId,
                sourceMetadata: this.sourceMetadata
            });
            console.log('>>> loaded metadata, maybe', this._logEntryMetadata);
        }
    }

    handleShowFullSourceMetadataModal() {
        this.showSourceMetadataModifiedWarning = this._logEntryMetadata.HasCodeBeenModified;
        this.fullSourceMetadata = { ...this.sourceSnippet, Code: this._logEntryMetadata.Code };
        this.fullSourceMetadataTitle = 'Full Source: ' + this.fullSourceMetadata.Title;
        this.showFullSourceMetadataModal = true;
    }

    handleHideFullSourceMetadataModal() {
        this.showFullSourceMetadataModal = false;
    }

    handleKeyDown(event) {
        if (event.code === 'Escape') {
            this.handleHideFullSourceMetadataModal();
        }
    }

    _getSourceFields() {
        let sourceApiNameField;
        let sourceApiVersionField;
        let sourceMetadataTypeField;
        let sourceSnippetField;
        if (this.sourceMetadata === 'Exception') {
            sourceApiNameField = EXCEPTION_SOURCE_API_NAME_FIELD;
            sourceApiVersionField = EXCEPTION_SOURCE_API_VERSION_FIELD;
            sourceMetadataTypeField = EXCEPTION_SOURCE_METADATA_TYPE_FIELD;
            sourceSnippetField = EXCEPTION_SOURCE_SNIPPET_FIELD;
        } else if (this.sourceMetadata === 'Origin') {
            sourceApiNameField = ORIGIN_SOURCE_API_NAME_FIELD;
            sourceApiVersionField = ORIGIN_SOURCE_API_VERSION_FIELD;
            sourceMetadataTypeField = ORIGIN_SOURCE_METADATA_TYPE_FIELD;
            sourceSnippetField = ORIGIN_SOURCE_SNIPPET_FIELD;
        }
        return { sourceApiNameField, sourceApiVersionField, sourceMetadataTypeField, sourceSnippetField };
    }

    _getSourceExtension(sourceMetadataType) {
        let sourceExtension;
        switch (sourceMetadataType) {
            case 'ApexClass':
                sourceExtension = 'cls';
                break;
            case 'ApexTrigger':
                sourceExtension = 'trigger';
                break;
            default:
                sourceExtension = '';
        }
        return sourceExtension;
    }
}
