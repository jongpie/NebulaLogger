public without sharing class LoggerPluginFlowRecordInput {
  @InvocableVariable
  public SObject triggerRecordNew;

  @AuraEnabled
  public SObject triggerRecordOld;

  public String triggerOperationType;

  @AuraEnabled
  public Log__c log;
  @AuraEnabled
  public Log__c oldLog;
  @AuraEnabled
  public LogEntry__c logEntry;
  @AuraEnabled
  public LogEntry__c oldLogEntry;
}
