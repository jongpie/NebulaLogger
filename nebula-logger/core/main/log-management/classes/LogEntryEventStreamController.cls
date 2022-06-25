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
        'Timestamp__c',
        'LoggedByUsername__c',
        'OriginLocation__c',
        'LoggingLevel__c',
        'Message__c'
    };
    /**
     * @description Returns the list of columns to be displayed in
     * LogEntryEventStream Datatable.  The fields are configured
     * in the Custom Meta Data (LoggerParameter.LogEntryEventStreamDisplayFields).
     * @return   The instance of `List<String>`, containing the list of columns to be displayed in
     * LogEntryEventStream Datatable .
     */
    @AuraEnabled
    public static List<String> getDataTableDisplayFields() {
        try {
            return LoggerParameter.getStringList(DISPLAY_FIELDS_PARAMETER_NAME, DEFAULT_DISPLAY_FIELDS);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
