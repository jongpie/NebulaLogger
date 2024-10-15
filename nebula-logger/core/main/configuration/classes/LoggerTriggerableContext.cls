//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Class used by the logging system for trigger contextual details
 * @see LoggerSObjectHandler
 * @see LoggerPlugin
 */
@SuppressWarnings('PMD.ApexDoc, PMD.ExcessiveParameterList')
public without sharing class LoggerTriggerableContext {
  @AuraEnabled
  public Database.BatchableContext batchableContext;
  public transient Schema.SObjectType sobjectType;
  @AuraEnabled
  public String sobjectTypeName;
  // public transient Schema.SObjectType sobjectType { get; private set; }
  // public transient System.TriggerOperation triggerOperationType { get; private set; }
  @AuraEnabled
  public List<Log__c> triggerNewLogs;
  @AuraEnabled
  public List<SObject> triggerNew;
  @AuraEnabled
  public Map<Id, SObject> triggerNewMap;
  @AuraEnabled
  public Map<Id, SObject> triggerOldMap;

  // @AuraEnabled
  // public String sobjectTypeName { get; private set; }

  // @AuraEnabled
  // public String triggerOperationTypeName { get; private set; }

  @AuraEnabled
  public List<LogRecordInput> logRecords; // { get; private set; }
  @AuraEnabled
  public List<RecordInput> triggerRecords; // { get; private set; }

  // public LoggerTriggerableContext(Schema.SObjectType sobjectType, System.TriggerOperation triggerOperationType, List<SObject> triggerNew) {
  //   this(sobjectType, triggerOperationType, triggerNew, null, null);
  // }

  // public LoggerTriggerableContext(
  //   Schema.SObjectType sobjectType,
  //   System.TriggerOperation triggerOperationType,
  //   List<SObject> triggerNew,
  //   Map<Id, SObject> triggerNewMap,
  //   Map<Id, SObject> triggerOldMap
  // ) {
  //   // Trigger variables for Apex Developers
  //   this.sobjectType = sobjectType;
  //   this.triggerOperationType = triggerOperationType;
  //   this.triggerNew = triggerNew;
  //   this.triggerNewMap = triggerNewMap;
  //   this.triggerOldMap = triggerOldMap;
  public class InvocableThing {
    @InvocableVariable
    public List<SObject> records;
    @InvocableVariable
    public SObject recordNew;
    @InvocableVariable
    public SObject recordOld;
    @InvocableVariable
    public List<LoggerPluginFlowRecordInput> recordInputs;
    @InvocableVariable
    public LoggerPluginFlowRecordInput recordInput;
  }

  public class InvocableInput {
    @InvocableVariable
    public String sobjectTypeName;
  }

  @InvocableMethod(
    category='Logging'
    label='Get Logger Trigger Context'
    description='Returns the list of account names corresponding to the specified account IDs.'
  )
  public static List<InvocableThing> getTriggerContext(List<InvocableInput> inputs) {
    InvocableThing thing = new InvocableThing();
    thing.records = [SELECT id, username FROM user];
    return new List<InvocableThing>{ thing };
  }

  public LoggerTriggerableContext(Schema.SObjectType sobjectType, System.TriggerOperation triggerOperationType, List<SObject> triggerNew) {
    this(sobjectType, triggerOperationType, triggerNew, null, null);
  }

  //   this.setupAdditionalProperties();
  // }

  // private void setupAdditionalProperties() {
  //   // Additional invocable variables for Flow Builders (and Apex Developers too, if they want to use them)
  //   this.sobjectTypeName = this.sobjectType.getDescribe().getName();
  //   this.triggerOperationTypeName = this.triggerOperationType?.name();
  //   this.triggerRecords = new List<LoggerTriggerableContext.RecordInput>();
  //   if (this.triggerNew != null) {
  //     for (SObject record : this.triggerNew) {
  //       LoggerTriggerableContext.RecordInput recordInput = new LoggerTriggerableContext.RecordInput();
  //       recordInput.triggerRecordNew = record;
  //       if (this.triggerOldMap != null && record.Id != null) {
  //         recordInput.triggerRecordOld = this.triggerOldMap.get(record.Id);
  //       }

  //       this.triggerRecords.add(recordInput);
  //     }
  //   } else if (this.triggerOldMap != null) {
  //     for (SObject record : this.triggerOldMap.values()) {
  //       LoggerTriggerableContext.RecordInput recordInput = new LoggerTriggerableContext.RecordInput();
  //       recordInput.triggerRecordOld = record;

  //       this.triggerRecords.add(recordInput);
  //     }
  //   }
  // }

  /**
   * @description Class used by the logging system to provide trigger record details to Flow
   */
  public class LogRecordInput {
    @AuraEnabled
    public Log__c triggerRecordNew { get; private set; }

    @AuraEnabled
    public Log__c triggerRecordOld { get; private set; }
  }

  public class RecordInput {
    @AuraEnabled
    public SObject triggerRecordNew { get; private set; }

    @AuraEnabled
    public SObject triggerRecordOld { get; private set; }
  }

  // // TODO add a constructor & move logic from LoggerSObjectHandler --> no longer a DTO?
}
