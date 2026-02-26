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
  @AuraEnabled(cacheable=true)
  public static LogEntryMetadata getMetadata(Id recordId, String sourceMetadata) {
    LogEntryMetadata metadata = new LogEntryMetadata();
    if (canViewLogEntryMetadata() == false) {
      return metadata;
    }

    LogEntry__c logEntry = LogManagementDataSelector.getInstance().getLogEntryById(recordId);

    String sourceApiName;
    LoggerStackTrace.SourceMetadataType sourceMetadataType;
    switch on sourceMetadata {
      when 'Exception' {
        sourceApiName = logEntry.ExceptionSourceApiName__c;
        sourceMetadataType = getSourceMetadataType(logEntry.ExceptionSourceMetadataType__c);
      }
      when 'Origin' {
        sourceApiName = logEntry.OriginSourceApiName__c;
        sourceMetadataType = getSourceMetadataType(logEntry.OriginSourceMetadataType__c);
      }
    }

    if (String.isNotBlank(sourceApiName) && sourceMetadataType != null) {
      querySourceMetadata(logEntry, metadata, sourceMetadataType, sourceApiName);
    }

    return metadata;
  }

  private static Boolean canViewLogEntryMetadata() {
    return Schema.ApexClass.SObjectType.getDescribe().isAccessible() || System.FeatureManagement.checkPermission('CanViewLogEntryMetadata');
  }

  private static LoggerStackTrace.SourceMetadataType getSourceMetadataType(String sourceMetadata) {
    return String.isBlank(sourceMetadata) ? null : LoggerStackTrace.SourceMetadataType.valueOf(sourceMetadata);
  }

  @SuppressWarnings('PMD.ExcessiveParameterList')
  private static void querySourceMetadata(
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

    if (codeBodyField != null && metadataRecords != null && metadataRecords.isEmpty() == false) {
      SObject metadataRecord = metadataRecords.get(0);

      logEntryMetadata.HasCodeBeenModified = ((Datetime) metadataRecord.get(lastModifiedDateField)) > logEntry.Timestamp__c;
      logEntryMetadata.Code = (String) metadataRecord.get(codeBodyField);
    }
  }

  // TODO consider combining with LogEntryHandler.SourceMetadataSnippet (which could become a top-level class)
  @SuppressWarnings('PMD.ApexDoc, PMD.AvoidBooleanMethodParameters, PMD.PropertyNamingConventions')
  public class LogEntryMetadata {
    @AuraEnabled
    public String Code { get; set; }

    @AuraEnabled
    public Boolean HasCodeBeenModified { get; set; }
  }
}
