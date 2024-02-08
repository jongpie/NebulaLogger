/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement, api, wire } from 'lwc';
import LightningAlert from 'lightning/alert';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getMetadata from '@salesforce/apex/LogEntryMetadataViewerController.getMetadata';
import getEinsteinExceptionInsight from '@salesforce/apex/LogEntryMetadataViewerController.getEinsteinExceptionInsight';

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
    sourceSnippet;

    showEinsteinInsights = true;
    showEinsteinInsightsModal = false;
    modalEinsteinInsightsTitle;

    showFullSourceMetadataModal = false;
    showModalWarning = false;
    modalSourceSnippetTitle;
    modalSourceSnippet;

    _logEntry;
    _logEntryMetadata;

    get hasLoaded() {
        return !!this._logEntry && !!this._logEntryMetadata;
    }

    get sectionTitle() {
        if (this.sourceMetadata === 'Exception') {
            return 'Exception Source Metadata';
        } else if (this.sourceMetadata === 'Origin') {
            return 'Origin Source Metadata';
        } else {
            return '';
        }
    }

    get hasFullSourceMetadata() {
        return !!this._logEntryMetadata?.Code;
    }

    connectedCallback() {
        this.showEinsteinInsights = this.sourceMetadata === 'Exception';
    }

    @wire(getMetadata, {
        recordId: '$recordId',
        sourceMetadata: '$sourceMetadata'
    })
    wiredGetLogEntryMetadata({ error, data }) {
        console.log('>>>> running wiredGetLogEntryMetadata', data, error);
        if (data) {
            this._logEntryMetadata = data;
        } else if (error) {
            this._logEntryMetadata = undefined;
        }
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: LOG_ENTRY_FIELDS
    })
    async wiredGetLogEntry({ data }) {
        console.log('>>>> running wiredGetLogEntry', data);
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
            console.log('>>>> this.sourceSnippet', this.sourceSnippet);

            // const metadataResponse = await getMetadata({ recordId: this.recordId });
            // console.log('>>>> running getMetadata', metadataResponse);
            // if (metadataResponse) {
            //     this._logEntryMetadata = metadataResponse;
            //     // } else if (metadataResponse.error) {
            //     //     this._logEntryMetadata = undefined;
            // }
        }
    }

    // @wire(getEinsteinExceptionInsight, {
    //     recordId: '$recordId'
    // })
    // wiredGetEinsteinExceptionInsight({ error, data }) {
    //     console.log('>>>> running wiredGetEinsteinExceptionInsight', data, error);
    //     if (data) {
    //         this._logEntryMetadata = data;
    //     } else if (error) {
    //         this._logEntryMetadata = undefined;
    //     }
    // }

    handleShowEinsteinInsightsModal() {
        console.info('>>> running handleShowEinsteinInsightsModal');
        this.showEinsteinInsightsModal = true;
        getEinsteinExceptionInsight({
            recordId: this.recordId
        })
            .then(result => {
                console.log('>>>> getEinsteinExceptionInsight result', result);
                this.modalEinsteinInsightsTitle = 'Einstein Insights';
                this.einsteinInsight = result;
            })
            .catch(async error => {
                this.einsteinInsight = undefined;
                console.error('>>>> getEinsteinExceptionInsight error', error);
                // TODO revisit/finalize error handling, and possible add
                // a retry mechanism
                await LightningAlert.open({
                    label: 'Einstein Error',
                    message: JSON.stringify(errror),
                    theme: 'error'
                });
            });
    }

    handleHideEinsteinInsightsModal() {
        this.einsteinInsight = undefined;
        this.modalEinsteinInsightsTitle = undefined;
        this.showEinsteinInsightsModal = false;
    }

    handleShowFullSourceMetadataModal() {
        console.info('>>> running handleShowFullSourceMetadataModal');
        this.showModalWarning = this._logEntryMetadata.HasCodeBeenModified;
        this.modalSourceSnippet = { ...this.sourceSnippet, Code: this._logEntryMetadata.Code };
        this.modalSourceSnippetTitle = 'Full Source: ' + this.modalSourceSnippet.Title;
        this.showFullSourceMetadataModal = true;

        console.info('>>> this.modalSourceSnippet', this.modalSourceSnippet);
    }

    handleHideFullSourceMetadataModal() {
        this.showFullSourceMetadataModal = false;
    }

    handleKeyDown(event) {
        if (event.code === 'Escape') {
            this.handleHideEinsteinInsightsModal();
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
