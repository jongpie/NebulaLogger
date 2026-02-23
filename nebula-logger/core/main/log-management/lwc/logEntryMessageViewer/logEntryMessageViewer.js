import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import LOGENTRY_OBJECT from '@salesforce/schema/LogEntry__c';
import MESSAGE_FIELD from '@salesforce/schema/LogEntry__c.Message__c';
import MESSAGE_MASKED_FIELD from '@salesforce/schema/LogEntry__c.MessageMasked__c';
import MESSAGE_TRUNCATED_FIELD from '@salesforce/schema/LogEntry__c.MessageTruncated__c';
import ORIGIN_SOURCE_METADATA_TYPE_FIELD from '@salesforce/schema/LogEntry__c.OriginSourceMetadataType__c';
import STACK_TRACE_FIELD from '@salesforce/schema/LogEntry__c.StackTrace__c';

const STORAGE_KEY = 'logEntryMessageViewer:viewMode';

export default class LogEntryMessageViewer extends LightningElement {
  @api recordId;

  viewMode = 'markdown';

  objectApiName = LOGENTRY_OBJECT;
  messageField = MESSAGE_FIELD;
  messageMaskedField = MESSAGE_MASKED_FIELD;
  messageTruncatedField = MESSAGE_TRUNCATED_FIELD;

  @wire(getRecord, {
    recordId: '$recordId',
    fields: [MESSAGE_FIELD, MESSAGE_MASKED_FIELD, MESSAGE_TRUNCATED_FIELD, STACK_TRACE_FIELD, ORIGIN_SOURCE_METADATA_TYPE_FIELD]
  })
  record;

  get message() {
    return getFieldValue(this.record.data, MESSAGE_FIELD);
  }

  get messageMasked() {
    return getFieldValue(this.record.data, MESSAGE_MASKED_FIELD);
  }

  get messageTruncated() {
    return getFieldValue(this.record.data, MESSAGE_TRUNCATED_FIELD);
  }

  get stackTrace() {
    return getFieldValue(this.record.data, STACK_TRACE_FIELD);
  }

  get hasMessage() {
    const v = this.message;
    return v !== null && v !== undefined && String(v).trim().length > 0;
  }

  get stackTraceLanguage() {
    console.log('>>> start of stackTraceLanguage', this.record.data);
    const metadataType = getFieldValue(this.record.data, ORIGIN_SOURCE_METADATA_TYPE_FIELD);
    console.log('>>> metadataType', metadataType);

    let language;
    switch (metadataType) {
      case 'AnonymousBlock':
      case 'ApexClass':
      case 'ApexTrigger':
        language = 'apex';
        break;
      case 'AuraDefinitionBundle':
      case 'LightningComponentBundle':
        language = 'javascript';
        break;
    }
    console.log('>>> end of stackTraceLanguage', language);
    return language;
  }

  get viewOptions() {
    return [
      { label: 'Markdown', value: 'markdown' },
      { label: 'Text', value: 'text' }
    ];
  }

  get isMarkdown() {
    return this.viewMode === 'markdown';
  }

  connectedCallback() {
    try {
      const saved = window.localStorage.getItem(STORAGE_KEY);
      if (saved === 'markdown' || saved === 'text') this.viewMode = saved;
    } catch {}
  }

  handleViewModeChange(e) {
    this.viewMode = e.detail.value;
    try {
      window.localStorage.setItem(STORAGE_KEY, this.viewMode);
    } catch {}
  }
}
