/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import LOGGER_SETTINGS_OBJECT from '@salesforce/schema/LoggerSettings__c';
import CREATED_BY_ID_FIELD from '@salesforce/schema/LoggerSettings__c.CreatedById';
import CREATED_DATE_FIELD from '@salesforce/schema/LoggerSettings__c.CreatedDate';
import DEFAULT_LOG_SHARE_ACCESS_LEVEL_FIELD from '@salesforce/schema/LoggerSettings__c.DefaultLogShareAccessLevel__c';
import DEFAULT_NUMBER_OF_DAYS_TO_RETAIN_LOGS_FIELD from '@salesforce/schema/LoggerSettings__c.DefaultNumberOfDaysToRetainLogs__c';
import DEFAULT_SAVE_METHOD_FIELD from '@salesforce/schema/LoggerSettings__c.DefaultSaveMethod__c';
import IS_ANONYMOUS_MODE_ENABLED_FIELD from '@salesforce/schema/LoggerSettings__c.IsAnonymousModeEnabled__c';
import IS_APEX_SYSTEM_DEBUG_LOGGING_ENABLED_FIELD from '@salesforce/schema/LoggerSettings__c.IsApexSystemDebugLoggingEnabled__c';
import IS_DATA_MASKING_ENABLED_FIELD from '@salesforce/schema/LoggerSettings__c.IsDataMaskingEnabled__c';
import IS_ENABLED_FIELD from '@salesforce/schema/LoggerSettings__c.IsEnabled__c';
import IS_JAVA_SCRIPT_CONSOLE_LOGGING_ENABLED_FIELD from '@salesforce/schema/LoggerSettings__c.IsJavaScriptConsoleLoggingEnabled__c';
import LAST_MODIFIED_BY_ID_FIELD from '@salesforce/schema/LoggerSettings__c.LastModifiedById';
import LAST_MODIFIED_DATE_FIELD from '@salesforce/schema/LoggerSettings__c.LastModifiedDate';
import LOGGING_LEVEL_FIELD from '@salesforce/schema/LoggerSettings__c.LoggingLevel__c';
import STRIP_INACCESSIBLE_RECORD_FIELDS_FIELD from '@salesforce/schema/LoggerSettings__c.StripInaccessibleRecordFields__c';
import SETUP_OWNER_ID_FIELD from '@salesforce/schema/LoggerSettings__c.SetupOwnerId';

const LOGGER_SETTINGS_SCHEMA = {
    sobject: LOGGER_SETTINGS_OBJECT,
    fields: {
        CreatedById: CREATED_BY_ID_FIELD.fieldApiName,
        CreatedDate: CREATED_DATE_FIELD.fieldApiName,
        DefaultLogShareAccessLevel__c: DEFAULT_LOG_SHARE_ACCESS_LEVEL_FIELD.fieldApiName,
        DefaultNumberOfDaysToRetainLogs__c: DEFAULT_NUMBER_OF_DAYS_TO_RETAIN_LOGS_FIELD.fieldApiName,
        DefaultSaveMethod__c: DEFAULT_SAVE_METHOD_FIELD.fieldApiName,
        IsAnonymousModeEnabled__c: IS_ANONYMOUS_MODE_ENABLED_FIELD.fieldApiName,
        IsApexSystemDebugLoggingEnabled__c: IS_APEX_SYSTEM_DEBUG_LOGGING_ENABLED_FIELD.fieldApiName,
        IsDataMaskingEnabled__c: IS_DATA_MASKING_ENABLED_FIELD.fieldApiName,
        IsEnabled__c: IS_ENABLED_FIELD.fieldApiName,
        IsJavaScriptConsoleLoggingEnabled__c: IS_JAVA_SCRIPT_CONSOLE_LOGGING_ENABLED_FIELD.fieldApiName,
        LastModifiedById: LAST_MODIFIED_BY_ID_FIELD.fieldApiName,
        LastModifiedDate: LAST_MODIFIED_DATE_FIELD.fieldApiName,
        LoggingLevel__c: LOGGING_LEVEL_FIELD.fieldApiName,
        SetupOwnerId: SETUP_OWNER_ID_FIELD.fieldApiName,
        StripInaccessibleRecordFields__c: STRIP_INACCESSIBLE_RECORD_FIELDS_FIELD.fieldApiName
    }
};

export default LOGGER_SETTINGS_SCHEMA;
