//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Controller class for lwc `logEntryEventStream`, used to stream Log Entries in console and Tabular view.
 */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.CyclomaticComplexity, PMD.ExcessivePublicCount')
public with sharing class LogEntryEventStreamController {
    @TestVisible
    private static final String DISPLAY_FIELDS_PARAMETER_NAME = 'LogEntryEventStreamDisplayFields';
    @TestVisible
    private static final List<String> DEFAULT_DISPLAY_FIELDS = new List<String>{
        Schema.LogEntryEvent__e.Timestamp__c.getDescribe().getLocalName(),
        Schema.LogEntryEvent__e.LoggedByUsername__c.getDescribe().getLocalName(),
        Schema.LogEntryEvent__e.OriginLocation__c.getDescribe().getLocalName(),
        Schema.LogEntryEvent__e.LoggingLevel__c.getDescribe().getLocalName(),
        Schema.LogEntryEvent__e.Message__c.getDescribe().getLocalName()
    };

    /**
     * @description Indicates if the LWC `logEntryEventStream` has been enabled (default) or disabled
     * @return   The `Boolean` value of the `LoggerParameter__mdt` record `LoggerParameter.EnableLogEntryEventStream`
     */
    @AuraEnabled
    public static Boolean isEnabled() {
        return LoggerParameter.ENABLE_LOG_ENTRY_EVENT_STREAM;
    }

    /**
     * @description Returns the list of columns to be displayed in LogEntryEventStream datatable.
     *              The fields are configured in the custom metadata record LoggerParameter__mdt.LogEntryEventStreamDisplayFields.
     * @return   The instance of `List<String>`, containing the list of columns to be displayed in
     *           LogEntryEventStream datatable.
     */
    @AuraEnabled
    public static List<String> getDatatableDisplayFields() {
        return LoggerParameter.getStringList(DISPLAY_FIELDS_PARAMETER_NAME, DEFAULT_DISPLAY_FIELDS);
    }
}
