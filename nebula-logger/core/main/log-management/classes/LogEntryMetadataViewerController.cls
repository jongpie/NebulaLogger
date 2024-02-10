//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Controller class for the LWC `logEntryMetadataViewer`
 */
public without sharing class LogEntryMetadataViewerController {
    /**
     * @description Returns an instance of the inner class `LogEntryMetadataViewerController.LogEntryMetadata`,
     *              which contains information about the log entry's origin and exception Apex classes
     * @param       recordId The `ID` of the `LogEntry__c` record
     * @param       sourceMetadata Either the value `Origin` or `Exception`
     * @return      An instance of `LogEntryMetadataViewerController.LogEntryMetadata`
     */
    // @AuraEnabled
    @AuraEnabled(cacheable=true)
    public static LogEntryMetadata getMetadata(Id recordId, String sourceMetadata) {
        LogEntryMetadata metadata = new LogEntryMetadata();
        if (Schema.ApexClass.SObjectType.getDescribe().isAccessible() == false || Schema.ApexTrigger.SObjectType.getDescribe().isAccessible() == false) {
            System.debug('no query access! returning early');
            return metadata;
        }

        LogEntry__c logEntry = LogManagementDataSelector.getInstance().getLogEntryById(recordId);

        String sourceApiName;
        LoggerStackTrace.SourceMetadataType sourceMetadataType;
        switch on sourceMetadata {
            when 'Exception' {
                sourceApiName = (String) logEntry.ExceptionSourceApiName__c;
                sourceMetadataType = String.isBlank(logEntry.ExceptionSourceMetadataType__c) ? null : LoggerStackTrace.SourceMetadataType.valueOf(logEntry.ExceptionSourceMetadataType__c);
            }
            when 'Origin' {
                sourceApiName = (String) logEntry.OriginSourceApiName__c;
                sourceMetadataType = String.isBlank(logEntry.OriginSourceMetadataType__c) ? null : LoggerStackTrace.SourceMetadataType.valueOf(logEntry.OriginSourceMetadataType__c);
            }
        }

        if (sourceMetadataType == null || String.isBlank(sourceApiName)) {
            return metadata;
        }

        querySourceMetadata(logEntry, metadata, sourceMetadataType, sourceApiName);

        System.debug('returning metadata\n' + JSON.serializePretty(metadata));
        return metadata;
    }

    private static void querySourceMetadata(LogEntry__c logEntry, LogEntryMetadata logEntryMetadata, LoggerStackTrace.SourceMetadataType sourceMetadataType, String sourceApiName) {
        Set<String> sourceApiNames = new Set<String>{ sourceApiName };
        List<SObject> metadataRecords;
        Schema.SObjectField codeBodyField;
        Schema.SObjectField lastModifiedDateField;
        switch on sourceMetadataType {
            when ApexClass {
                codeBodyField = Schema.ApexClass.Body;
                lastModifiedDateField = Schema.ApexClass.LastModifiedDate;
                metadataRecords = LogManagementDataSelector.getInstance().getApexClasses(sourceApiNames);
            }
            when ApexTrigger {
                codeBodyField = Schema.ApexTrigger.Body;
                lastModifiedDateField = Schema.ApexTrigger.LastModifiedDate;
                metadataRecords = LogManagementDataSelector.getInstance().getApexTriggers(sourceApiNames);
            }
        }

        if (codeBodyField == null || metadataRecords == null || metadataRecords.isEmpty()) {
            return;
        }

        SObject metadataRecord = metadataRecords.get(0);

        logEntryMetadata.HasCodeBeenModified = ((Datetime) metadataRecord.get(lastModifiedDateField)) > logEntry.Timestamp__c;
        logEntryMetadata.Code = (String) metadataRecord.get(codeBodyField);
    }

    // TODO consider combining with LogEntryHandler.SourceMetadataSnippet (which could become a top-level class)
    @SuppressWarnings('PMD.ApexDoc')
    public class LogEntryMetadata {
        @AuraEnabled
        public String Code {get; set;}
        @AuraEnabled
        public Boolean HasCodeBeenModified {get; set;}
    }
}
