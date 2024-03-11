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
            // TODO decide if it makes more sense to return null
            return metadata;
        }

        LogEntry__c logEntry = LogManagementDataSelector.getInstance().getLogEntryById(recordId);

        String sourceApiName;
        LoggerStackTrace.SourceMetadataType sourceMetadataType;
        switch on sourceMetadata {
            when 'Exception' {
                sourceApiName = logEntry.ExceptionSourceApiName__c;
                sourceMetadataType = String.isBlank(logEntry.ExceptionSourceMetadataType__c)
                    ? null
                    : LoggerStackTrace.SourceMetadataType.valueOf(logEntry.ExceptionSourceMetadataType__c);
            }
            when 'Origin' {
                sourceApiName = logEntry.OriginSourceApiName__c;
                sourceMetadataType = String.isBlank(logEntry.OriginSourceMetadataType__c)
                    ? null
                    : LoggerStackTrace.SourceMetadataType.valueOf(logEntry.OriginSourceMetadataType__c);
            }
        }

        if (sourceMetadataType == null || String.isBlank(sourceApiName)) {
            return metadata;
        }

        querySourceMetadataViaSoql(logEntry, metadata, sourceMetadataType, sourceApiName);

        return metadata;
    }

    private static void getSourceMetadata(String sourceMetadataType, String sourceApiName) {
        switch on sourceMetadataType {
            when 'ApexClass', 'ApexTrigger' {
                // querySourceMetadataViaSoql
            }
            when 'AuraBundleDefinition', 'LightningComponentBundle', 'Flow' {
                // retrieveSourceMetadataViaToolingApi();
            }
        }
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void querySourceMetadataViaSoql(
        LogEntry__c logEntry,
        LogEntryMetadata logEntryMetadata,
        LoggerStackTrace.SourceMetadataType sourceMetadataType,
        String sourceApiName
    ) {
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

    public static void retrieveSourceMetadataViaToolingApi() {
        // String sessionJson = System.Page.LoggerSessionId.getContent().toString();
        // Map<String, Object> sessionInfo = (Map<String, Object>) JSON.deserializeUntyped(sessionJson);
        // System.debug('sessionInfo: ' + sessionInfo);
        // String sessionId = (String) sessionInfo.get('sessionId');
        String sessionId = System.Page.LoggerSessionId.getContent().toString().trim();
        System.HttpRequest request = new System.HttpRequest();
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + sessionId);
        request.setHeader('Content-Type', 'application/json');
        String flowName = 'Account_Flow_Logger_Example';
        String flowEndpoint =
            '/services/data/v60.0/tooling/query/?q=SELECT+LastModifiedDate,Metadata+FROM+Flow+WHERE+Definition.DeveloperName=\'' +
            flowName +
            '\'';
        // String flowEndpoint = '/services/data/v60.0/tooling/query/?q=SELECT+Metadata+FROM+FlowDefinition+WHERE+DeveloperName=\'' + flowName + '\'';
        // String flowEndpoint = '/services/data/v60.0/tooling/query/?q=SELECT+Metadata+FROM+Flow+LIMIT+1';
        request.setEndpoint(System.URL.getOrgDomainUrl().toExternalForm() + flowEndpoint);

        System.HttpResponse response = new System.Http().send(request);
    }

    // TODO consider combining with LogEntryHandler.SourceMetadataSnippet (which could become a top-level class)
    @SuppressWarnings('PMD.ApexDoc, PMD.PropertyNamingConventions')
    public class LogEntryMetadata {
        @AuraEnabled
        public String Code { get; set; }
        @AuraEnabled
        public Boolean HasCodeBeenModified { get; set; }
    }

    // Inspired by https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/tooling_api_objects_lightningcomponentbundle.htm
    public class SourceMetadata {
        public String ApiName { get; set; }
        public Boolean HasMetadataBeenModified { get; set; }
        public Datetime LastModifiedDate { get; set; }
        public List<SourceMetadataResource> Resources { get; set; }
    }

    // Inspired by https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/tooling_api_objects_lightningcomponentresource.htm
    public class SourceMetadataResource {
        public String FileName { get; set; }
        // public String FilePath { get; set; }
        public String Format { get; set; }
        public String Source { get; set; }
    }
}
