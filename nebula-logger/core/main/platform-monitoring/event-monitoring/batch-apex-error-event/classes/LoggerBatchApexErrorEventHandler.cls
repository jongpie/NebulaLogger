//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
/**
 * @group Plugins
 * @description `BatchApexErrorEvent` handler to log unexpected batch errors for classes that implement `Database.RaisesPlatformEvents` and opt into processing via `LoggerParameter__mdt`
 * @see LoggerSObjectHandler
 */
public without sharing class LoggerBatchApexErrorEventHandler extends LoggerSObjectHandler {
  public static final String BATCH_ERROR_LOGGER = 'BatchError';
  public static final String LOG_MESSAGE = 'An unexpected job error occurred: {0} with exception type: {1} and message: {2} during batch phase: {3}.\nStacktrace: {4}';
  private static Boolean shouldSaveLogs = false;

  private List<BatchApexErrorEvent> batchApexErrorEvents;

  /**
   * @description Opts into the default constructor
   */
  public LoggerBatchApexErrorEventHandler() {
    super();
  }

  public override Schema.SObjectType getSObjectType() {
    return Schema.BatchApexErrorEvent.SObjectType;
  }

  protected override void executeAfterInsert(List<SObject> triggerNew) {
    this.batchApexErrorEvents = (List<BatchApexErrorEvent>) triggerNew;
    this.handleJobErrors();
  }

  private void handleJobErrors() {
    Set<Id> asyncApexJobIds = new Set<Id>();
    for (BatchApexErrorEvent evt : this.batchApexErrorEvents) {
      asyncApexJobIds.add(evt.AsyncApexJobId);
    }

    Map<Id, AsyncApexJob> jobIdToClass = new Map<Id, AsyncApexJob>([SELECT Id, ApexClass.Name FROM AsyncApexJob WHERE Id IN :asyncApexJobIds]);
    Logger.error('Batch job terminated unexpectedly');
    for (BatchApexErrorEvent errorEvent : this.batchApexErrorEvents) {
      shouldSaveLogs = this.getShouldSaveLogs(jobIdToClass, errorEvent);
      LogMessage logMessage = new LogMessage(
        LOG_MESSAGE,
        new List<String>{ errorEvent.AsyncApexJobId, errorEvent.ExceptionType, errorEvent.Message, errorEvent.Phase, errorEvent.StackTrace }
      );
      Logger.error(logMessage);
    }
    if (shouldSaveLogs) {
      Logger.saveLog();
    }
  }

  private Boolean getShouldSaveLogs(Map<Id, AsyncApexJob> jobIdToClass, BatchApexErrorEvent errorEvent) {
    if (shouldSaveLogs == false) {
      AsyncApexJob job = jobIdToClass.get(errorEvent.AsyncApexJobId);
      List<LoggerParameter__mdt> configurationList = LoggerParameter.matchOnPrefix(BATCH_ERROR_LOGGER);
      for (LoggerParameter__mdt config : configurationList) {
        if (config.Value__c == job?.ApexClass.Name) {
          shouldSaveLogs = true;
          break;
        }
      }
    }
    return shouldSaveLogs;
  }
}
