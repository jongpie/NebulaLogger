//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Optional plugin that provides a Big Object, `LogEntryArchive__b`, as an alternative option
 *              to the platform event `LogEntryEvent__e`
 * @see LoggerPlugin
 */
public without sharing class LogEntryArchivePlugin implements LoggerPlugin.Batchable, LoggerPlugin.Triggerable {
  @TestVisible
  private static final String BIG_OBJECT_IMMEDIATE_LOGGER_SAVE_METHOD = LoggerParameter.getString('CustomSaveMethodBigObjectImmediate', null);
  @TestVisible
  private static final String BIG_OBJECT_QUEUEABLE_LOGGER_SAVE_METHOD = LoggerParameter.getString('CustomSaveMethodBigObjectQueueable', null);
  @TestVisible
  private static final String BIG_OBJECT_LOG_PURGE_ACTION = LoggerParameter.getString('CustomLogPurgeActionArchive', null);
  @TestVisible
  private static final String BIG_OBJECT_STORAGE_LOCATION = LoggerParameter.getString('CustomStorageLocationBigObject', null);
  @TestVisible
  private static final List<LogEntryArchive__b> LOG_ENTRY_ARCHIVES_TO_SAVE = new List<LogEntryArchive__b>();

  @TestVisible
  private static String lastSaveMethodUsed;

  /**
   * @description Default constructor
   */
  @SuppressWarnings('PMD.EmptyStatementBlock')
  public LogEntryArchivePlugin() {
  }

  // Batchable interface methods
  /**
   * @description Skips directly deleting `LogEntryTag__c` records in `LogBatchPurger` so that the tags
   *             can be included when `LogEntry__c` records are archived into `LogEntryArchive__b`
   * @param  configuration The instance of `LoggerPlugin__mdt` configured for this specific plugin
   * @param  input The instance of `LoggerBatchableContext`, provided by the logging system
   */
  public void start(LoggerPlugin__mdt configuration, LoggerBatchableContext input) {
    // Skip directly deleting LogEntryTag__c records so that the tags can be included when LogEntry__c records
    // are archived into LogEntryArchive__b
    if (input.sobjectType == Schema.LogEntryTag__c.SObjectType) {
      input.sobjectType = Schema.LogEntry__c.SObjectType;
    }
  }

  /**
   * @description Converts any `LogEntry__c` records into `LogEntryArchive__b` records
   * @param  configuration The instance of `LoggerPlugin__mdt` configured for this specific plugin
   * @param  input The instance of `LoggerBatchableContext`, provided by the logging system
   * @param  loggerRecords The list of `SObject` scope records provider by `LogBatchPurger`
   */
  public void execute(LoggerPlugin__mdt configuration, LoggerBatchableContext input, List<SObject> loggerRecords) {
    if (input.sobjectType != Schema.LogEntry__c.SObjectType) {
      return;
    }

    List<LogEntry__c> logEntries = this.requeryLogEntriesToArchive((List<LogEntry__c>) loggerRecords);
    for (LogEntry__c logEntry : logEntries) {
      LOG_ENTRY_ARCHIVES_TO_SAVE.add(new LogEntryArchiveBuilder(logEntry).getLogEntryArchive());
    }
    this.saveLogEntryArchives(BIG_OBJECT_IMMEDIATE_LOGGER_SAVE_METHOD);
  }

  /**
   * @description No-op method, required by the interface `LoggerPlugin.Batchable`
   * @param  configuration The instance of `LoggerPlugin__mdt` configured for this specific plugin
   * @param  input The instance of `LoggerBatchableContext`, provided by the logging system
   */
  @SuppressWarnings('PMD.EmptyStatementBlock')
  public void finish(LoggerPlugin__mdt configuration, LoggerBatchableContext input) {
    // No-op
  }

  // Triggerable interface method
  /**
   * @description Handles converting Logger's buffer of `LogEntryEvent__e` records into `LogEntryArchive__b` records
   *              for any user with the included custom save method 'BIG_OBJECT'
   * @param  configuration The instance of `LoggerPlugin__mdt` configured for this specific plugin
   * @param  input The instance of `LoggerTriggerableContext`, provided by the logging system
   */
  public void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext input) {
    if (input.sobjectType != Schema.LogEntryEvent__e.SObjectType) {
      return;
    }
    Set<String> bigObjectSaveMethods = new Set<String>{ BIG_OBJECT_IMMEDIATE_LOGGER_SAVE_METHOD, BIG_OBJECT_QUEUEABLE_LOGGER_SAVE_METHOD };

    if (
      input.triggerOperationType == System.TriggerOperation.BEFORE_INSERT &&
      bigObjectSaveMethods.contains(Logger.getUserSettings().DefaultSaveMethod__c) == false
    ) {
      return;
    }

    List<LogEntryEvent__e> logEntryEvents = this.filterLogEntryEventsToSave(input);
    for (LogEntryEvent__e logEntryEvent : logEntryEvents) {
      LOG_ENTRY_ARCHIVES_TO_SAVE.add(new LogEntryArchiveBuilder(logEntryEvent).getLogEntryArchive());
    }

    if (LOG_ENTRY_ARCHIVES_TO_SAVE.isEmpty()) {
      return;
    }

    String saveMethodName;
    switch on input.triggerOperationType {
      when BEFORE_INSERT {
        saveMethodName = Logger.getUserSettings().DefaultSaveMethod__c;
      }
      when AFTER_INSERT {
        saveMethodName = BIG_OBJECT_QUEUEABLE_LOGGER_SAVE_METHOD;
      }
    }
    this.saveLogEntryArchives(saveMethodName);

    Logger.flushBuffer();
  }

  private List<LogEntry__c> requeryLogEntriesToArchive(List<LogEntry__c> logEntries) {
    String logLookupRelationshipName = Schema.LogEntry__c.Log__c.toString().removeEnd('__c') + '__r';
    List<String> logFieldsToQuery = new List<String>();
    for (String fieldName : Schema.Log__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().keySet()) {
      logFieldsToQuery.add(logLookupRelationshipName + '.' + fieldName);
    }
    String closedByUsernameField = getParentFieldPath(
      new List<Schema.SObjectField>{ Schema.LogEntry__c.Log__c, Schema.Log__c.ClosedBy__c, Schema.User.Username }
    );
    logFieldsToQuery.add(closedByUsernameField);
    String parentLogTransactionIdField = getParentFieldPath(
      new List<Schema.SObjectField>{ Schema.LogEntry__c.Log__c, Schema.Log__c.ParentLog__c, Schema.Log__c.TransactionId__c }
    );
    logFieldsToQuery.add(parentLogTransactionIdField);
    List<String> logEntryFieldsToQuery = new List<String>(Schema.LogEntry__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().keySet());
    logEntryFieldsToQuery.addAll(logFieldsToQuery);

    String tagLookupRelationshipName = Schema.LogEntryTag__c.Tag__c.toString().removeEnd('__c') + '__r';
    String tagNameField = tagLookupRelationshipName + '.' + Schema.LoggerTag__c.Name.toString();

    String logPurgeActionParentFieldName = logLookupRelationshipName + '.' + Schema.Log__c.LogPurgeAction__c.toString();
    String queryTemplate = 'SELECT {0}, (SELECT {1} FROM {2}) FROM {3} WHERE Id IN :logEntries AND {4} = :BIG_OBJECT_LOG_PURGE_ACTION';
    List<Object> queryInputs = new List<Object>{
      String.join(logEntryFieldsToQuery, ', '),
      tagNameField,
      'LogEntryTags__r', // TODO replace with strongly-typed reference or namespace-safe string
      Schema.LogEntry__c.SObjectType.toString(),
      logPurgeActionParentFieldName
    };
    String query = String.escapeSingleQuotes(String.format(queryTemplate, queryInputs));
    return (List<LogEntry__c>) System.Database.query(query);
  }

  private String getParentFieldPath(List<Schema.SObjectField> parentFieldChainPieces) {
    String parentFieldPath = '';
    Integer lastIndex = parentFieldChainPieces.size() - 1;
    for (Integer i = 0; i < parentFieldChainPieces.size(); i++) {
      Schema.SObjectField field = parentFieldChainPieces.get(i);
      if (i != lastIndex) {
        parentFieldPath += field.toString().removeEnd('__c') + '__r.';
      } else {
        parentFieldPath += field.toString();
      }
    }
    return parentFieldPath;
  }

  private List<LogEntryEvent__e> filterLogEntryEventsToSave(LoggerTriggerableContext input) {
    // In a BEFORE_INSERT context, if one of the 2 Big Object save methods is used, then
    // all of the LogEntryEvent__e records should be saved in LogEntryArchive__b
    if (
      input.triggerOperationType == System.TriggerOperation.BEFORE_INSERT &&
      new Set<String>{ BIG_OBJECT_IMMEDIATE_LOGGER_SAVE_METHOD, BIG_OBJECT_QUEUEABLE_LOGGER_SAVE_METHOD }
        .contains(Logger.getUserSettings().DefaultSaveMethod__c)
    ) {
      return (List<LogEntryEvent__e>) input.triggerNew;
    }

    if (input.triggerOperationType != System.TriggerOperation.AFTER_INSERT) {
      return new List<LogEntryEvent__e>();
    }

    // In an AFTER_INSERT context, only save LogEntryEvent__e records if the LoggedyId__c user
    // as 'BIG_OBJECT' set as their storage location for platform events (DefaultPlatformEventStorageLocation__c)
    List<LogEntryEvent__e> logEntryEventsToSave = new List<LogEntryEvent__e>();
    for (LogEntryEvent__e logEntryEvent : (List<LogEntryEvent__e>) input.triggerNew) {
      Schema.User loggingUser = new Schema.User(Id = logEntryEvent.LoggedById__c, ProfileId = logEntryEvent.ProfileId__c);
      LoggerSettings__c loggingUserSettings = Logger.getUserSettings(loggingUser);
      if (loggingUserSettings.DefaultPlatformEventStorageLocation__c == BIG_OBJECT_STORAGE_LOCATION) {
        logEntryEventsToSave.add(logEntryEvent);
      }
    }
    return logEntryEventsToSave;
  }

  private void saveLogEntryArchives(String saveMethodName) {
    if (System.Test.isRunningTest()) {
      lastSaveMethodUsed = saveMethodName;
    }

    if (saveMethodName == BIG_OBJECT_IMMEDIATE_LOGGER_SAVE_METHOD && System.Test.isRunningTest() == false) {
      System.Database.insertImmediate(LOG_ENTRY_ARCHIVES_TO_SAVE);
    } else if (saveMethodName == BIG_OBJECT_QUEUEABLE_LOGGER_SAVE_METHOD || saveMethodName == BIG_OBJECT_STORAGE_LOCATION) {
      System.enqueueJob(new QueueableSaver(LOG_ENTRY_ARCHIVES_TO_SAVE));
    }

    if (System.Test.isRunningTest() == false) {
      LOG_ENTRY_ARCHIVES_TO_SAVE.clear();
    }
  }

  /**
   * @description Inner class for publishing log entries via the System.Queueable interface.
   */
  private class QueueableSaver implements System.Queueable {
    private List<LogEntryArchive__b> logEntryArchives = new List<LogEntryArchive__b>();

    private QueueableSaver(List<LogEntryArchive__b> logEntryArchives) {
      this.logEntryArchives = logEntryArchives;
    }

    /**
     * @description Asynchronoulsy inserts the list of `LogEntryArchive_b` records
     * @param queueableContext The context of the current queue, provided by the platform
     */
    public void execute(System.QueueableContext queueableContext) {
      if (System.Test.isRunningTest() == false) {
        System.Database.insertImmediate(this.logEntryArchives);
      }
    }
  }
}
