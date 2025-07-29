/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getSchemaForName from '@salesforce/apex/LoggerSObjectMetadata.getSchemaForName';

// LogEntry__c object and fields
import LOG_ENTRY_OBJECT from '@salesforce/schema/LogEntry__c';
import DATABASE_RESULT_COLLECTION_SIZE_FIELD from '@salesforce/schema/LogEntry__c.DatabaseResultCollectionSize__c';
import DATABASE_RESULT_COLLECTION_TYPE_FIELD from '@salesforce/schema/LogEntry__c.DatabaseResultCollectionType__c';
import DATABASE_RESULT_JSON_FIELD from '@salesforce/schema/LogEntry__c.DatabaseResultJson__c';
import DATABASE_RESULT_TYPE_FIELD from '@salesforce/schema/LogEntry__c.DatabaseResultType__c';
import EXCEPTION_MESSAGE_FIELD from '@salesforce/schema/LogEntry__c.ExceptionMessage__c';
import EXCEPTION_STACK_TRACE_FIELD from '@salesforce/schema/LogEntry__c.ExceptionStackTrace__c';
import EXCEPTION_TYPE_FIELD from '@salesforce/schema/LogEntry__c.ExceptionType__c';
import HTTP_REQUEST_BODY_FIELD from '@salesforce/schema/LogEntry__c.HttpRequestBody__c';
import HTTP_REQUEST_COMPRESSED_FIELD from '@salesforce/schema/LogEntry__c.HttpRequestCompressed__c';
import HTTP_REQUEST_ENDPOINT_ADDRESS_FIELD from '@salesforce/schema/LogEntry__c.HttpRequestEndpointAddress__c';
import HTTP_REQUEST_HEADER_KEYS_FIELD from '@salesforce/schema/LogEntry__c.HttpRequestHeaderKeys__c';
import HTTP_REQUEST_HEADERS_FIELD from '@salesforce/schema/LogEntry__c.HttpRequestHeaders__c';
import HTTP_REQUEST_METHOD_FIELD from '@salesforce/schema/LogEntry__c.HttpRequestMethod__c';
import HTTP_RESPONSE_BODY_FIELD from '@salesforce/schema/LogEntry__c.HttpResponseBody__c';
import HTTP_RESPONSE_HEADERS_FIELD from '@salesforce/schema/LogEntry__c.HttpResponseHeaders__c';
import HTTP_RESPONSE_HEADER_KEYS_FIELD from '@salesforce/schema/LogEntry__c.HttpResponseHeaderKeys__c';
import HTTP_RESPONSE_STATUS_CODE_FIELD from '@salesforce/schema/LogEntry__c.HttpResponseStatusCode__c';
import HTTP_RESPONSE_STATUS_FIELD from '@salesforce/schema/LogEntry__c.HttpResponseStatus__c';
import MESSAGE_FIELD from '@salesforce/schema/LogEntry__c.Message__c';
import MESSAGE_MASKED_FIELD from '@salesforce/schema/LogEntry__c.MessageMasked__c';
import MESSAGE_TRUNCATED_FIELD from '@salesforce/schema/LogEntry__c.MessageTruncated__c';
import RELATED_RECORD_ID_FIELD from '@salesforce/schema/LogEntry__c.RecordId__c';
import RELATED_RECORD_JSON_FIELD from '@salesforce/schema/LogEntry__c.RecordJson__c';
import RELATED_RECORD_NAME_FIELD from '@salesforce/schema/LogEntry__c.RecordName__c';
import RELATED_RECORD_SOBJECT_CLASSIFICATION_FIELD from '@salesforce/schema/LogEntry__c.RecordSObjectClassification__c';
import RELATED_RECORD_SOBJECT_TYPE_FIELD from '@salesforce/schema/LogEntry__c.RecordSObjectType__c';
import RELATED_RECORD_COLLECTION_SIZE_FIELD from '@salesforce/schema/LogEntry__c.RecordCollectionSize__c';
import STACK_TRACE_FIELD from '@salesforce/schema/LogEntry__c.StackTrace__c';

// Define field sets for each section type
const SECTION_FIELD_SETS = {
  Message: [MESSAGE_FIELD, STACK_TRACE_FIELD, MESSAGE_MASKED_FIELD, MESSAGE_TRUNCATED_FIELD],
  Exception: [EXCEPTION_TYPE_FIELD, EXCEPTION_MESSAGE_FIELD, EXCEPTION_STACK_TRACE_FIELD],
  'HTTP Request': [
    HTTP_REQUEST_ENDPOINT_ADDRESS_FIELD,
    HTTP_REQUEST_METHOD_FIELD,
    HTTP_REQUEST_COMPRESSED_FIELD,
    HTTP_REQUEST_HEADER_KEYS_FIELD,
    HTTP_REQUEST_HEADERS_FIELD,
    HTTP_REQUEST_BODY_FIELD
  ],
  'HTTP Response': [
    HTTP_RESPONSE_STATUS_CODE_FIELD,
    HTTP_RESPONSE_STATUS_FIELD,
    HTTP_RESPONSE_HEADER_KEYS_FIELD,
    HTTP_RESPONSE_HEADERS_FIELD,
    HTTP_RESPONSE_BODY_FIELD
  ],
  'Database Result Details': [
    DATABASE_RESULT_TYPE_FIELD,
    DATABASE_RESULT_COLLECTION_TYPE_FIELD,
    DATABASE_RESULT_COLLECTION_SIZE_FIELD,
    DATABASE_RESULT_JSON_FIELD
  ],
  'Related Record Details': [
    RELATED_RECORD_ID_FIELD,
    RELATED_RECORD_NAME_FIELD,
    RELATED_RECORD_SOBJECT_TYPE_FIELD,
    RELATED_RECORD_SOBJECT_CLASSIFICATION_FIELD,
    RELATED_RECORD_COLLECTION_SIZE_FIELD,
    RELATED_RECORD_JSON_FIELD
  ]
};

// Define which fields should use loggerCodeViewer and their language
const CODE_VIEWER_FIELDS = {
  DatabaseResultJson__c: 'json',
  ExceptionMessage__c: 'text',
  ExceptionStackTrace__c: 'apex',
  HttpRequestBody__c: 'json',
  HttpRequestHeaders__c: 'http',
  HttpRequestHeaderKeys__c: 'http',
  HttpResponseBody__c: 'json',
  HttpResponseHeaders__c: 'http',
  HttpResponseHeaderKeys__c: 'http',
  Message__c: 'text',
  RecordJson__c: 'json',
  StackTrace__c: 'apex'
};

// Function to get the correct field name based on namespace
function _getCodeViewerFieldName(fieldApiName) {
  // Remove the __c suffix first, then check for namespace prefix
  const withoutSuffix = fieldApiName.replace('__c', '');
  const parts = withoutSuffix.split('__');

  // If there are multiple parts, the last part is the base field name
  // If there's only one part, it's already the base field name
  const baseFieldName = parts.length > 1 ? parts[parts.length - 1] : parts[0];

  // Add back the __c suffix
  return baseFieldName + '__c';
}

// Function to check if a field should use code viewer
function _shouldUseCodeViewer(fieldApiName) {
  const baseFieldName = _getCodeViewerFieldName(fieldApiName);
  return CODE_VIEWER_FIELDS.hasOwnProperty(baseFieldName);
}

// Function to get the language for a field
function _getCodeViewerLanguage(fieldApiName) {
  const baseFieldName = _getCodeViewerFieldName(fieldApiName);
  return CODE_VIEWER_FIELDS[baseFieldName] || null;
}

export default class LogEntryPageSection extends LightningElement {
  @api recordId;
  @api sectionType;

  objectApiName = LOG_ENTRY_OBJECT;
  hasLoaded = false;
  logEntry = {};
  sectionFields = [];
  sectionTitle = '';
  sectionIcon = '';
  fieldMetadata = {};

  get sectionFieldSet() {
    return SECTION_FIELD_SETS[this.sectionType] || [];
  }

  get sectionConfig() {
    const configs = {
      Message: {
        title: 'Message Details'
        // icon: 'utility:message'
      },
      Exception: {
        title: 'Exception Details',
        icon: 'utility:error'
      },
      'HTTP Request': {
        title: 'HTTP Callout Request',
        icon: 'utility:upload'
      },
      'HTTP Response': {
        title: 'HTTP Callout Response',
        icon: 'utility:download'
      },
      'Database Result Details': {
        title: 'Database Result Details',
        icon: 'utility:database'
      },
      'Related Record Details': {
        title: 'Related Record Details',
        icon: 'utility:record'
      }
    };
    return configs[this.sectionType] || { title: this.sectionType, icon: 'utility:info' };
  }

  @wire(getRecord, {
    recordId: '$recordId',
    fields: '$sectionFieldSet'
  })
  async wiredGetLogEntry({ data, error }) {
    if (data) {
      this.logEntry = data;
      this.sectionTitle = this.sectionConfig.title;
      this.sectionIcon = this.sectionConfig.icon;

      // Load field metadata for LogEntry__c
      try {
        this.fieldMetadata = await getSchemaForName({ sobjectApiName: 'LogEntry__c' });
        this.sectionFields = this._buildSectionFields();
      } catch (error) {
        console.error('Error loading field metadata:', error);
        this.sectionFields = this._buildSectionFields();
      }

      this.hasLoaded = true;
    } else if (error) {
      console.error('Error loading log entry:', error);
      this.hasLoaded = true;
    }
  }

  _buildSectionFields() {
    const fields = [];

    this.sectionFieldSet.forEach(field => {
      const fieldValue = getFieldValue(this.logEntry, field);
      if (fieldValue !== null && fieldValue !== undefined && fieldValue !== '') {
        const fieldApiName = field.fieldApiName;
        const shouldUseCodeViewer = _shouldUseCodeViewer(fieldApiName);
        const codeViewerLanguage = shouldUseCodeViewer ? _getCodeViewerLanguage(fieldApiName) : null;

        // Get field metadata from the schema
        const fieldSchema = this.fieldMetadata.fields?.[fieldApiName];
        const fieldLabel = fieldSchema?.label || fieldApiName;
        const fieldType = fieldSchema?.type || 'string';
        const isBoolean = fieldType === 'boolean';
        const isNumber = fieldType === 'int' || fieldType === 'double' || fieldType === 'number';

        fields.push({
          apiName: fieldApiName,
          label: fieldLabel,
          value: fieldValue,
          type: fieldType,
          isLongText: fieldType === 'string' && fieldValue && fieldValue.length > 255,
          isBoolean: isBoolean,
          isNumber: isNumber,
          useCodeViewer: shouldUseCodeViewer,
          codeViewerLanguage: codeViewerLanguage
        });
      }
    });

    return fields;
  }

  get hasSectionData() {
    return this.sectionFields.length > 0;
  }

  get showSection() {
    return this.hasLoaded && this.hasSectionData;
  }
}
