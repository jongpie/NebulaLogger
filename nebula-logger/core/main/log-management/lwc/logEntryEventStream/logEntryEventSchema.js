/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import LOG_ENTRY_EVENT_OBJECT from '@salesforce/schema/LogEntryEvent__e';
import LOGGED_BY_USERNAME_FIELD from '@salesforce/schema/LogEntryEvent__e.LoggedByUsername__c';
import LOGGING_LEVEL_ORDINAL_FIELD from '@salesforce/schema/LogEntryEvent__e.LoggingLevelOrdinal__c';
import MESSAGE_FIELD from '@salesforce/schema/LogEntryEvent__e.Message__c';
import ORIGIN_LOCATION_FIELD from '@salesforce/schema/LogEntryEvent__e.OriginLocation__c';
import ORIGIN_TYPE_FIELD from '@salesforce/schema/LogEntryEvent__e.OriginType__c';
import SCENARIO_FIELD from '@salesforce/schema/LogEntryEvent__e.Scenario__c';
import TRANSACTION_ENTRY_NUMBER_FIELD from '@salesforce/schema/LogEntryEvent__e.TransactionEntryNumber__c';
import TRANSACTION_ID_FIELD from '@salesforce/schema/LogEntryEvent__e.TransactionId__c';

const LOG_ENTRY_EVENT_SCHEMA = {
    apiName: LOG_ENTRY_EVENT_OBJECT.objectApiName.replace('__c', '__e'),
    fields: {
        LoggedByUsername__c: LOGGED_BY_USERNAME_FIELD.fieldApiName,
        LoggingLevelOrdinal__c: LOGGING_LEVEL_ORDINAL_FIELD.fieldApiName,
        Message__c: MESSAGE_FIELD.fieldApiName,
        OriginLocation__c: ORIGIN_LOCATION_FIELD.fieldApiName,
        OriginType__c: ORIGIN_TYPE_FIELD.fieldApiName,
        Scenario__c: SCENARIO_FIELD.fieldApiName,
        TransactionEntryNumber__c: TRANSACTION_ENTRY_NUMBER_FIELD.fieldApiName,
        TransactionId__c: TRANSACTION_ID_FIELD.fieldApiName
    }
};

export default LOG_ENTRY_EVENT_SCHEMA;
