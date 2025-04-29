//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Controller class for the LWC `logViewer`, used to provided different views on a `Log__c` record
 */
public with sharing class LogViewerController {
  /**
   * @description Returns a Log__c record from the database, using either the Salesforce ID or transaction ID
   * @param  logId The Salesforce ID or TransactionId__c of the Log__c
   * @return       The matching record, with all fields that the current user can access
   */
  @AuraEnabled(cacheable=true)
  public static LogDTO getLog(Id logId) {
    LogDTO logDto = new LogDTO();
    logDto.log = queryLog(logId);
    logDto.logEntries = queryLogEntries(logId);
    logDto.logEntriesRelationshipName = getNamespacePrefix() + 'LogEntries__r';

    // TODO need to revist, this Log__c would not have child LogEntries__r populated (or tags within those entries)
    logDto.otelLogsPayload = LoggerOTelAdapter.convertToOTel(logDto.log);

    return logDto;
  }

  @AuraEnabled(cacheable=true)
  public static LoggerOTelSchema.LogsPayload getOTelLogPayload(Id logId) {
    LogDTO logDto = getLog(logId);

    // TODO need to finalize if/how/when/where log will have child records for logEntries, etc.
    LoggerOTelSchema.LogsPayload logsPayload = LoggerOTelAdapter.convertToOTel(logDto.log);

    return logsPayload;
  }

  private static Log__c queryLog(Id logId) {
    System.SObjectAccessDecision securityDecision = System.Security.stripInaccessible(
      System.AccessType.READABLE,
      new List<Log__c>{ LogManagementDataSelector.getInstance().getLogById(logId) }
    );
    return securityDecision.getRecords().isEmpty() ? null : (Log__c) securityDecision.getRecords().get(0);
  }

  private static List<LogEntry__c> queryLogEntries(Id logId) {
    System.SObjectAccessDecision securityDecision = System.Security.stripInaccessible(
      System.AccessType.READABLE,
      LogManagementDataSelector.getInstance().getLogEntriesByLogId(logId)
    );
    return (List<LogEntry__c>) securityDecision.getRecords();
  }

  private static String getNamespacePrefix() {
    String className = LoggerSObjectMetadata.class.getName();
    String namespacePrefix = className.contains('.') ? className.substringBefore('.') + '__' : '';

    return namespacePrefix;
  }

  @SuppressWarnings('PMD.ApexDoc')
  public class LogDTO {
    @AuraEnabled
    public Log__c log;
    @AuraEnabled
    public List<LogEntry__c> logEntries;
    @AuraEnabled
    public String logEntriesRelationshipName;
    @AuraEnabled
    public LoggerOTelSchema.LogsPayload otelLogsPayload;
  }
}
