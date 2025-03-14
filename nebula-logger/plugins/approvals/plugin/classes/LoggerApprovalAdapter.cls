//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
/**
 * @group Plugins
 * @description Static adapter layer that can transform Approval namespace classes into Logger-compatible outputs
 */
public class LoggerApprovalAdapter {
  /**
   * @description Transforms single LockResult into a Logger-compatible `Database.SaveResult`
   * @param lockResult The `Approval.LockResult` to transform
   * @return `Database.SaveResult` that can be used in `LogEntryEventBuilder.setDatabaseResult()` calls
   */
  public static Database.SaveResult transform(Approval.LockResult lockResult) {
    return (Database.SaveResult) System.JSON.deserialize(System.JSON.serialize(lockResult), Database.SaveResult.class);
  }

  /**
   * @description Transforms LockResults into a Logger-compatible `List<Database.SaveResult>`
   * @param lockResults The `List<Approval.LockResult>` to transform
   * @return `List<Database.SaveResult>` that can be used in `LogEntryEventBuilder.setDatabaseResult()` calls
   */
  public static List<Database.SaveResult> transform(List<Approval.LockResult> lockResults) {
    return (List<Database.SaveResult>) System.JSON.deserialize(System.JSON.serialize(lockResults), List<Database.SaveResult>.class);
  }

  /**
   * @description Transforms single UnlockResult into a Logger-compatible `Database.SaveResult`
   * @param unlockResult The `Approval.UnlockResult` to transform
   * @return `Database.SaveResult` that can be used in `LogEntryEventBuilder.setDatabaseResult()` calls
   */
  public static Database.SaveResult transform(Approval.UnlockResult unlockResult) {
    return (Database.SaveResult) System.JSON.deserialize(System.JSON.serialize(unlockResult), Database.SaveResult.class);
  }

  /**
   * @description Transforms UnlockResults into a Logger-compatible `List<Database.SaveResult>`
   * @param unlockResults The `List<Approval.UnlockResult>` to transform
   * @return `List<Database.SaveResult>` that can be used in `LogEntryEventBuilder.setDatabaseResult()` calls
   */
  public static List<Database.SaveResult> transform(List<Approval.UnlockResult> unlockResults) {
    return (List<Database.SaveResult>) System.JSON.deserialize(System.JSON.serialize(unlockResults), List<Database.SaveResult>.class);
  }

  /**
   * @description Logs a single process request at the specified logging level`
   * @param processRequest The `Approval.ProcessRequest` to log
   * @param loggingLevel The `System.LoggingLevel` to use
   * @return `LogEntryEventBuilder` that can be used in further Logger calls
   */
  public static LogEntryEventBuilder log(Approval.ProcessRequest processRequest, System.LoggingLevel loggingLevel) {
    return log(new List<Approval.ProcessRequest>{ processRequest }, loggingLevel);
  }

  /**
   * @description Logs process requests at the specified logging level`
   * @param processRequests The `List<Approval.ProcessRequest>` to log
   * @param loggingLevel The `System.LoggingLevel` to use
   * @return `LogEntryEventBuilder` that can be used in further Logger calls
   */
  public static LogEntryEventBuilder log(List<Approval.ProcessRequest> processRequests, System.LoggingLevel loggingLevel) {
    return setupBuilder('Approval.ProcessRequest', processRequests, loggingLevel);
  }

  /**
   * @description Logs a single process result at the specified logging level`
   * @param processResult The `Approval.ProcessRequest` to log
   * @param loggingLevel The `System.LoggingLevel` to use
   * @return `LogEntryEventBuilder` that can be used in further Logger calls
   */
  public static LogEntryEventBuilder log(Approval.ProcessResult processResult, System.LoggingLevel loggingLevel) {
    return log(new List<Approval.ProcessResult>{ processResult }, loggingLevel);
  }

  /**
   * @description Logs process results at the specified logging level`
   * @param processResults The `List<Approval.ProcessResult>` to log
   * @param loggingLevel The `System.LoggingLevel` to use
   * @return `LogEntryEventBuilder` that can be used in further Logger calls
   */
  public static LogEntryEventBuilder log(List<Approval.ProcessResult> processResults, System.LoggingLevel loggingLevel) {
    return setupBuilder('Approval.ProcessResult', processResults, loggingLevel);
  }

  private static LogEntryEventBuilder setupBuilder(String typeName, List<Object> approvals, System.LoggingLevel loggingLevel) {
    LogEntryEventBuilder builder = Logger.newEntry(loggingLevel, getFormattedLogMessage(typeName, approvals));
    List<Id> entityIds = getEntityIds(approvals);
    if (entityIds.size() == 1) {
      builder.setRecord(entityIds[0]);
    } else {
      builder.setRecord(entityIds);
    }
    return builder;
  }

  private static LogMessage getFormattedLogMessage(String approvalType, List<Object> approvals) {
    Object messageTarget = approvals.size() > 1 ? (Object) approvals : (Object) approvals[0];
    return new LogMessage('{0}{1} received:\n{2}', new List<String>{ approvalType, approvals.size() > 1 ? 's' : '', System.JSON.serialize(messageTarget) });
  }

  private static List<Id> getEntityIds(List<Object> processes) {
    List<Id> results = new List<Id>();
    for (Object process : processes) {
      Id possibleEntityId;
      if (process instanceof Approval.ProcessSubmitRequest) {
        possibleEntityId = ((Approval.ProcessSubmitRequest) process).getObjectId();
      } else if (process instanceof Approval.ProcessWorkitemRequest) {
        possibleEntityId = ((Approval.ProcessWorkitemRequest) process).getWorkitemId();
      } else if (process instanceof Approval.ProcessResult) {
        possibleEntityId = ((Approval.ProcessResult) process).getEntityId();
      }
      if (possibleEntityId != null) {
        results.add(possibleEntityId);
      }
    }
    return results;
  }
}
