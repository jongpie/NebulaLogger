//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@IsTest
private class LoggerApprovalAdapter_Tests {
  @IsTest
  static void transformsLockResultToLoggerCompatibleObject() {
    Approval.LockResult approvalResult = (Approval.LockResult) createResult(Approval.LockResult.class);

    Database.SaveResult saveResult = LoggerApprovalAdapter.transform(approvalResult);

    System.Assert.areEqual(approvalResult.getId(), saveResult.getId());
    System.Assert.areEqual(approvalResult.isSuccess(), saveResult.isSuccess());
    System.Assert.areEqual(approvalResult.getErrors(), saveResult.getErrors());
  }

  @IsTest
  static void transformsLockResultsToLoggerCompatibleObject() {
    Approval.LockResult approvalResult = (Approval.LockResult) createResult(Approval.LockResult.class);

    Database.SaveResult saveResult = LoggerApprovalAdapter.transform(new List<Approval.LockResult>{ approvalResult }).get(0);

    System.Assert.areEqual(approvalResult.getId(), saveResult.getId());
    System.Assert.areEqual(approvalResult.isSuccess(), saveResult.isSuccess());
    System.Assert.areEqual(approvalResult.getErrors(), saveResult.getErrors());
  }

  @IsTest
  static void transformsUnlockResultToLoggerCompatibleObject() {
    Approval.UnlockResult approvalResult = (Approval.UnlockResult) createResult(Approval.UnlockResult.class);

    Database.SaveResult saveResult = LoggerApprovalAdapter.transform(approvalResult);

    System.Assert.areEqual(approvalResult.getId(), saveResult.getId());
    System.Assert.areEqual(approvalResult.isSuccess(), saveResult.isSuccess());
    System.Assert.areEqual(approvalResult.getErrors(), saveResult.getErrors());
  }

  @IsTest
  static void transformsUnlockResultsToLoggerCompatibleObject() {
    Approval.UnlockResult approvalResult = (Approval.UnlockResult) createResult(Approval.UnlockResult.class);

    Database.SaveResult saveResult = LoggerApprovalAdapter.transform(new List<Approval.UnlockResult>{ approvalResult }).get(0);

    System.Assert.areEqual(approvalResult.getId(), saveResult.getId());
    System.Assert.areEqual(approvalResult.isSuccess(), saveResult.isSuccess());
    System.Assert.areEqual(approvalResult.getErrors(), saveResult.getErrors());
  }

  @IsTest
  static void transformsSingleProcessRequestToLoggerCompatibleObject() {
    Approval.ProcessSubmitRequest approval = new Approval.ProcessSubmitRequest();
    approval.setComments('Approve');
    approval.setNextApproverIds(new List<Id>{ System.UserInfo.getUserId() });
    approval.setObjectId(System.UserInfo.getUserId());
    approval.setProcessDefinitionNameOrId('Some_Developer_Name');
    approval.setSkipEntryCriteria(true);
    approval.setSubmitterId(System.UserInfo.getUserId());

    LogEntryEventBuilder builder = LoggerApprovalAdapter.log(approval, System.LoggingLevel.DEBUG);

    System.Assert.areEqual(approval.getObjectId(), builder.getLogEntryEvent().RecordId__c);
    System.Assert.areEqual('Approval.ProcessRequest received:\n' + System.JSON.serialize(approval), builder.getLogEntryEvent().Message__c);
    System.Assert.areEqual('DEBUG', builder.getLogEntryEvent().LoggingLevel__c);
  }

  @IsTest
  static void transformsBulkProcessRequestToLoggerCompatibleObject() {
    Approval.ProcessSubmitRequest approval = new Approval.ProcessSubmitRequest();
    approval.setComments('Approve');
    approval.setNextApproverIds(new List<Id>{ System.UserInfo.getUserId() });
    approval.setObjectId(System.UserInfo.getUserId());
    approval.setProcessDefinitionNameOrId('Some_Developer_Name');
    approval.setSkipEntryCriteria(true);
    approval.setSubmitterId(System.UserInfo.getUserId());
    List<Approval.ProcessRequest> requests = new List<Approval.ProcessRequest>{ approval, approval };

    LogEntryEventBuilder builder = LoggerApprovalAdapter.log(requests, System.LoggingLevel.DEBUG);

    System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
    System.Assert.areEqual('Approval.ProcessRequests received:\n' + System.JSON.serialize(requests), builder.getLogEntryEvent().Message__c);
    System.Assert.areEqual('DEBUG', builder.getLogEntryEvent().LoggingLevel__c);
  }

  @IsTest
  static void transformsSingleProcessWorkitemRequestToLoggerCompatibleObject() {
    Approval.ProcessWorkitemRequest approval = new Approval.ProcessWorkitemRequest();
    approval.setComments('Approve');
    approval.setAction('Approve');
    approval.setNextApproverIds(new List<Id>{ System.UserInfo.getUserId() });
    approval.setWorkitemId(System.UserInfo.getUserId());

    LogEntryEventBuilder builder = LoggerApprovalAdapter.log(approval, System.LoggingLevel.FINE);

    System.Assert.areEqual(approval.getWorkitemId(), builder.getLogEntryEvent().RecordId__c);
    System.Assert.areEqual('Approval.ProcessRequest received:\n' + System.JSON.serialize(approval), builder.getLogEntryEvent().Message__c);
    System.Assert.areEqual('FINE', builder.getLogEntryEvent().LoggingLevel__c);
  }

  @IsTest
  static void transformsBulkProcessWorkitemRequestToLoggerCompatibleObject() {
    Approval.ProcessWorkitemRequest approval = new Approval.ProcessWorkitemRequest();
    approval.setComments('Approve');
    approval.setAction('Approve');
    approval.setNextApproverIds(new List<Id>{ System.UserInfo.getUserId() });
    approval.setWorkitemId(System.UserInfo.getUserId());
    List<Approval.ProcessRequest> requests = new List<Approval.ProcessRequest>{ approval, approval };

    LogEntryEventBuilder builder = LoggerApprovalAdapter.log(requests, System.LoggingLevel.INFO);

    System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
    System.Assert.areEqual('Approval.ProcessRequests received:\n' + System.JSON.serialize(requests), builder.getLogEntryEvent().Message__c);
    System.Assert.areEqual('INFO', builder.getLogEntryEvent().LoggingLevel__c);
  }

  @IsTest
  static void transformsSingleProcessResultToLoggerCompatibleObject() {
    Approval.ProcessResult approval = (Approval.ProcessResult) createResult(Approval.ProcessResult.class);

    LogEntryEventBuilder builder = LoggerApprovalAdapter.log(approval, System.LoggingLevel.FINEST);

    System.Assert.areEqual(approval.getEntityId(), builder.getLogEntryEvent().RecordId__c);
    System.Assert.areEqual('Approval.ProcessResult received:\n' + System.JSON.serialize(approval), builder.getLogEntryEvent().Message__c);
    System.Assert.areEqual('FINEST', builder.getLogEntryEvent().LoggingLevel__c);
  }

  @IsTest
  static void transformsBulkProcessResultToLoggerCompatibleObject() {
    Approval.ProcessResult approval = (Approval.ProcessResult) createResult(Approval.ProcessResult.class);
    List<Approval.ProcessResult> approvals = new List<Approval.ProcessResult>{ approval, approval };

    LogEntryEventBuilder builder = LoggerApprovalAdapter.log(approvals, System.LoggingLevel.WARN);

    System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
    System.Assert.areEqual('Approval.ProcessResults received:\n' + System.JSON.serialize(approvals), builder.getLogEntryEvent().Message__c);
    System.Assert.areEqual('WARN', builder.getLogEntryEvent().LoggingLevel__c);
  }

  private static Object createResult(System.Type targetType) {
    String value = '{ "id" : "001000000000000", "success": true, "errors": [] }';
    return System.JSON.deserialize(value, targetType);
  }
}
