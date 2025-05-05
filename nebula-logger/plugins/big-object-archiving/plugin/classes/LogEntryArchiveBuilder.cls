//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Builder class to create an instance of `LogEntryArchive__b`, used by the Big Object plugin
 * @see LogEntryArchivePlugin
 * @see LogEntryEventBuilder
 */
public without sharing class LogEntryArchiveBuilder {
  private LogEntryEvent__e logEntryEvent;
  private LogEntry__c logEntry;
  private LogEntryArchive__b logEntryArchive;

  /**
   * @description Used by `LogEntryArchivePlugin` to instantiate a new instance of `LogEntryArchiveBuilder`
   * @param  logEntryEvent The `LogEntryEvent__e` record that will be converted to a `LogEntryArchive__b` record
   */
  public LogEntryArchiveBuilder(LogEntryEvent__e logEntryEvent) {
    this.logEntryEvent = logEntryEvent;
  }

  /**
   * @description Used by `LogEntryArchivePlugin` to instantiate a new instance of `LogEntryArchiveBuilder`
   * @param  logEntry The `LogEntry__c` record that will be converted to a `LogEntryArchive__b` record
   */
  public LogEntryArchiveBuilder(LogEntry__c logEntry) {
    this.logEntry = logEntry;
  }

  /**
   * @description Returns the `LogEntryArchive__b` record for this instance of LogEntryEventBuilder
   * @return The `LogEntryArchive__b` record
   */
  public LogEntryArchive__b getLogEntryArchive() {
    if (this.logEntryArchive == null && this.logEntryEvent != null) {
      this.convertLogEntryEventToLogEntryArchive();
      this.truncateFieldValues();
    } else if (this.logEntryArchive == null && this.logEntry != null) {
      this.convertLogEntryToLogEntryArchive();
      this.truncateFieldValues();
    }

    return this.logEntryArchive;
  }

  private void convertLogEntryEventToLogEntryArchive() {
    this.logEntryArchive = new LogEntryArchive__b(
      ApiVersion__c = this.logEntryEvent.ApiVersion__c,
      ArchivedById__c = System.UserInfo.getUserId(),
      ArchivedDate__c = System.now(),
      ArchivedByUsername__c = System.UserInfo.getUsername(),
      ComponentType__c = this.logEntryEvent.ComponentType__c,
      DatabaseResultCollectionSize__c = this.logEntryEvent.DatabaseResultCollectionSize__c,
      DatabaseResultCollectionType__c = this.logEntryEvent.DatabaseResultCollectionType__c,
      DatabaseResultJson__c = this.logEntryEvent.DatabaseResultJson__c,
      DatabaseResultType__c = this.logEntryEvent.DatabaseResultType__c,
      EpochTimestamp__c = this.logEntryEvent.EpochTimestamp__c,
      EventUuid__c = this.logEntryEvent.EventUuid,
      ExceptionMessage__c = this.logEntryEvent.ExceptionMessage__c,
      ExceptionStackTrace__c = this.logEntryEvent.ExceptionStackTrace__c,
      ExceptionType__c = this.logEntryEvent.ExceptionType__c,
      HttpRequestBody__c = this.logEntryEvent.HttpRequestBody__c,
      HttpRequestBodyMasked__c = String.valueOf(this.logEntryEvent.HttpRequestBodyMasked__c),
      HttpRequestCompressed__c = String.valueOf(this.logEntryEvent.HttpRequestCompressed__c),
      HttpRequestEndpoint__c = this.logEntryEvent.HttpRequestEndpoint__c,
      HttpRequestMethod__c = this.logEntryEvent.HttpRequestMethod__c,
      HttpResponseBody__c = this.logEntryEvent.HttpResponseBody__c,
      HttpResponseBodyMasked__c = String.valueOf(this.logEntryEvent.HttpResponseBody__c),
      HttpResponseHeaderKeys__c = this.logEntryEvent.HttpResponseHeaderKeys__c,
      HttpResponseStatus__c = this.logEntryEvent.HttpResponseStatus__c,
      HttpResponseStatusCode__c = this.logEntryEvent.HttpResponseStatusCode__c,
      LimitsAggregateQueriesMax__c = this.logEntryEvent.LimitsAggregateQueriesMax__c,
      LimitsAggregateQueriesUsed__c = this.logEntryEvent.LimitsAggregateQueriesUsed__c,
      LimitsAsyncCallsMax__c = this.logEntryEvent.LimitsAsyncCallsMax__c,
      LimitsAsyncCallsUsed__c = this.logEntryEvent.LimitsAsyncCallsUsed__c,
      LimitsCalloutsUsed__c = this.logEntryEvent.LimitsCalloutsUsed__c,
      LimitsCpuTimeMax__c = this.logEntryEvent.LimitsCpuTimeMax__c,
      LimitsCpuTimeUsed__c = this.logEntryEvent.LimitsCpuTimeUsed__c,
      LimitsDmlRowsMax__c = this.logEntryEvent.LimitsDmlRowsMax__c,
      LimitsDmlRowsUsed__c = this.logEntryEvent.LimitsDmlRowsUsed__c,
      LimitsDmlStatementsMax__c = this.logEntryEvent.LimitsDmlStatementsMax__c,
      LimitsDmlStatementsUsed__c = this.logEntryEvent.LimitsDmlStatementsUsed__c,
      LimitsEmailInvocationsMax__c = this.logEntryEvent.LimitsEmailInvocationsMax__c,
      LimitsEmailInvocationsUsed__c = this.logEntryEvent.LimitsEmailInvocationsUsed__c,
      LimitsFutureCallsMax__c = this.logEntryEvent.LimitsFutureCallsMax__c,
      LimitsFutureCallsUsed__c = this.logEntryEvent.LimitsFutureCallsUsed__c,
      LimitsHeapSizeMax__c = this.logEntryEvent.LimitsHeapSizeMax__c,
      LimitsHeapSizeUsed__c = this.logEntryEvent.LimitsHeapSizeUsed__c,
      LimitsMobilePushApexCallsMax__c = this.logEntryEvent.LimitsMobilePushApexCallsMax__c,
      LimitsMobilePushApexCallsUsed__c = this.logEntryEvent.LimitsMobilePushApexCallsUsed__c,
      LimitsPublishImmediateDmlStatementsMax__c = this.logEntryEvent.LimitsPublishImmediateDmlStatementsMax__c,
      LimitsPublishImmediateDmlStatementsUsed__c = this.logEntryEvent.LimitsPublishImmediateDmlStatementsUsed__c,
      LimitsQueueableJobsMax__c = this.logEntryEvent.LimitsQueueableJobsMax__c,
      LimitsQueueableJobsUsed__c = this.logEntryEvent.LimitsQueueableJobsUsed__c,
      LimitsSoqlQueriesMax__c = this.logEntryEvent.LimitsSoqlQueriesMax__c,
      LimitsSoqlQueriesUsed__c = this.logEntryEvent.LimitsSoqlQueriesUsed__c,
      LimitsSoqlQueryLocatorRowsMax__c = this.logEntryEvent.LimitsSoqlQueryLocatorRowsMax__c,
      LimitsSoqlQueryLocatorRowsUsed__c = this.logEntryEvent.LimitsSoqlQueryLocatorRowsUsed__c,
      LimitsSoqlQueryRowsMax__c = this.logEntryEvent.LimitsSoqlQueryRowsMax__c,
      LimitsSoqlQueryRowsUsed__c = this.logEntryEvent.LimitsSoqlQueryRowsUsed__c,
      LimitsSoslSearchesMax__c = this.logEntryEvent.LimitsSoslSearchesMax__c,
      LimitsSoslSearchesUsed__c = this.logEntryEvent.LimitsSoslSearchesUsed__c,
      Locale__c = this.logEntryEvent.Locale__c,
      // LoggedBy__c = String.isNotBlank(logEntryEvent.LoggedById__c) ? logEntryEvent.LoggedById__c : 'Anonymous',
      LoggedById__c = this.logEntryEvent.LoggedById__c,
      LoggedByUsername__c = String.isNotBlank(this.logEntryEvent.LoggedByUsername__c) ? this.logEntryEvent.LoggedByUsername__c : 'Anonymous',
      LoggerVersionNumber__c = this.logEntryEvent.LoggerVersionNumber__c,
      LoggingLevel__c = this.logEntryEvent.LoggingLevel__c,
      LoggingLevelOrdinal__c = this.logEntryEvent.LoggingLevelOrdinal__c,
      LoginApplication__c = this.logEntryEvent.LoginApplication__c,
      LoginBrowser__c = this.logEntryEvent.LoginBrowser__c,
      LoginHistoryId__c = this.logEntryEvent.LoginHistoryId__c,
      LoginPlatform__c = this.logEntryEvent.LoginPlatform__c,
      LoginType__c = this.logEntryEvent.LoginType__c,
      LogoutUrl__c = this.logEntryEvent.LogoutUrl__c,
      Message__c = this.logEntryEvent.Message__c,
      NetworkId__c = this.logEntryEvent.NetworkId__c,
      NetworkLoginUrl__c = this.logEntryEvent.NetworkLoginUrl__c,
      NetworkLogoutUrl__c = this.logEntryEvent.NetworkLogoutUrl__c,
      NetworkSelfRegistrationUrl__c = this.logEntryEvent.NetworkSelfRegistrationUrl__c,
      NetworkUrlPathPrefix__c = this.logEntryEvent.NetworkUrlPathPrefix__c,
      OrganizationDomainUrl__c = this.logEntryEvent.OrganizationDomainUrl__c,
      OrganizationEnvironmentType__c = this.logEntryEvent.OrganizationEnvironmentType__c,
      OrganizationId__c = this.logEntryEvent.OrganizationId__c,
      OrganizationInstanceName__c = this.logEntryEvent.OrganizationInstanceName__c,
      OrganizationName__c = this.logEntryEvent.OrganizationName__c,
      OrganizationNamespacePrefix__c = this.logEntryEvent.OrganizationNamespacePrefix__c,
      OrganizationType__c = this.logEntryEvent.OrganizationType__c,
      OriginLocation__c = this.logEntryEvent.OriginLocation__c,
      OriginType__c = this.logEntryEvent.OriginType__c,
      ParentLogTransactionId__c = this.logEntryEvent.ParentLogTransactionId__c,
      ProfileId__c = this.logEntryEvent.ProfileId__c,
      ProfileName__c = this.logEntryEvent.ProfileName__c,
      RecordCollectionSize__c = this.logEntryEvent.RecordCollectionSize__c,
      RecordCollectionType__c = this.logEntryEvent.RecordCollectionType__c,
      RecordId__c = this.logEntryEvent.RecordId__c,
      RecordJson__c = this.logEntryEvent.RecordJson__c,
      RecordSObjectClassification__c = this.logEntryEvent.RecordSObjectClassification__c,
      RecordSObjectType__c = this.logEntryEvent.RecordSObjectType__c,
      RecordSObjectTypeNamespace__c = this.logEntryEvent.RecordSObjectTypeNamespace__c,
      SessionId__c = this.logEntryEvent.SessionId__c,
      SessionSecurityLevel__c = this.logEntryEvent.SessionSecurityLevel__c,
      SessionType__c = this.logEntryEvent.SessionType__c,
      SourceIp__c = this.logEntryEvent.SourceIp__c,
      StackTrace__c = this.logEntryEvent.StackTrace__c,
      SystemMode__c = this.logEntryEvent.SystemMode__c,
      Tags__c = this.logEntryEvent.Tags__c,
      ThemeDisplayed__c = this.logEntryEvent.ThemeDisplayed__c,
      Timestamp__c = this.logEntryEvent.Timestamp__c,
      TimestampString__c = this.logEntryEvent.TimestampString__c,
      TimeZoneId__c = this.logEntryEvent.TimeZoneId__c,
      TransactionEntryNumber__c = this.logEntryEvent.TransactionEntryNumber__c,
      TransactionId__c = this.logEntryEvent.TransactionId__c,
      TriggerOperationType__c = this.logEntryEvent.TriggerOperationType__c,
      TriggerSObjectType__c = this.logEntryEvent.TriggerSObjectType__c,
      UserLicenseDefinitionKey__c = this.logEntryEvent.UserLicenseDefinitionKey__c,
      UserLicenseName__c = this.logEntryEvent.UserLicenseName__c,
      UserLoggingLevel__c = this.logEntryEvent.UserLoggingLevel__c,
      UserLoggingLevelOrdinal__c = this.logEntryEvent.UserLoggingLevelOrdinal__c,
      UserRoleId__c = this.logEntryEvent.UserRoleId__c,
      UserRoleName__c = this.logEntryEvent.UserRoleName__c,
      UserType__c = this.logEntryEvent.UserType__c
    );
  }

  private void convertLogEntryToLogEntryArchive() {
    List<String> tagNames = new List<String>();
    for (LogEntryTag__c logEntryTag : this.logEntry.LogEntryTags__r) {
      tagNames.add(logEntryTag.Tag__r.Name);
    }
    tagNames = new List<String>(new Set<String>(tagNames));
    tagNames.sort();

    this.logEntryArchive = new LogEntryArchive__b(
      ApiReleaseNumber__c = this.logEntry.Log__r.ApiReleaseNumber__c,
      ApiReleaseVersion__c = this.logEntry.Log__r.ApiReleaseVersion__c,
      ApiVersion__c = this.logEntry.Log__r.ApiVersion__c,
      ArchivedById__c = System.UserInfo.getUserId(),
      ArchivedDate__c = System.now(),
      ArchivedByUsername__c = System.UserInfo.getUsername(),
      ClosedById__c = this.logEntry.Log__r.ClosedBy__c,
      ClosedByUsername__c = this.logEntry.Log__r.ClosedBy__r.Username,
      ClosedDate__c = this.logEntry.Log__r.ClosedDate__c,
      Comments__c = this.logEntry.Log__r.Comments__c,
      ComponentType__c = this.logEntry.ComponentType__c,
      DatabaseResultCollectionSize__c = this.logEntry.DatabaseResultCollectionSize__c,
      DatabaseResultCollectionType__c = this.logEntry.DatabaseResultCollectionType__c,
      DatabaseResultJson__c = this.logEntry.DatabaseResultJson__c,
      DatabaseResultType__c = this.logEntry.DatabaseResultType__c,
      EpochTimestamp__c = this.logEntry.EpochTimestamp__c,
      EventUuid__c = this.logEntry.EventUuid__c,
      ExceptionMessage__c = this.logEntry.ExceptionMessage__c,
      ExceptionStackTrace__c = this.logEntry.ExceptionStackTrace__c,
      ExceptionType__c = this.logEntry.ExceptionType__c,
      HttpRequestBody__c = this.logEntry.HttpRequestBody__c,
      HttpRequestBodyMasked__c = String.valueOf(this.logEntry.HttpRequestBodyMasked__c),
      HttpRequestCompressed__c = String.valueOf(this.logEntry.HttpRequestCompressed__c),
      HttpRequestEndpoint__c = this.logEntry.HttpRequestEndpoint__c,
      HttpRequestMethod__c = this.logEntry.HttpRequestMethod__c,
      HttpResponseBody__c = this.logEntry.HttpResponseBody__c,
      HttpResponseBodyMasked__c = String.valueOf(this.logEntry.HttpResponseBodyMasked__c),
      HttpResponseHeaderKeys__c = this.logEntry.HttpResponseHeaderKeys__c,
      HttpResponseStatus__c = this.logEntry.HttpResponseStatus__c,
      HttpResponseStatusCode__c = this.logEntry.HttpResponseStatusCode__c,
      IsClosed__c = String.valueOf(this.logEntry.Log__r.IsClosed__c),
      IsResolved__c = String.valueOf(this.logEntry.Log__r.IsResolved__c),
      Issue__c = this.logEntry.Log__r.Issue__c,
      LimitsAggregateQueriesMax__c = this.logEntry.LimitsAggregateQueriesMax__c,
      LimitsAggregateQueriesUsed__c = this.logEntry.LimitsAggregateQueriesUsed__c,
      LimitsAsyncCallsMax__c = this.logEntry.LimitsAsyncCallsMax__c,
      LimitsAsyncCallsUsed__c = this.logEntry.LimitsAsyncCallsUsed__c,
      LimitsCalloutsUsed__c = this.logEntry.LimitsCalloutsUsed__c,
      LimitsCpuTimeMax__c = this.logEntry.LimitsCpuTimeMax__c,
      LimitsCpuTimeUsed__c = this.logEntry.LimitsCpuTimeUsed__c,
      LimitsDmlRowsMax__c = this.logEntry.LimitsDmlRowsMax__c,
      LimitsDmlRowsUsed__c = this.logEntry.LimitsDmlRowsUsed__c,
      LimitsDmlStatementsMax__c = this.logEntry.LimitsDmlStatementsMax__c,
      LimitsDmlStatementsUsed__c = this.logEntry.LimitsDmlStatementsUsed__c,
      LimitsEmailInvocationsMax__c = this.logEntry.LimitsEmailInvocationsMax__c,
      LimitsEmailInvocationsUsed__c = this.logEntry.LimitsEmailInvocationsUsed__c,
      LimitsFutureCallsMax__c = this.logEntry.LimitsFutureCallsMax__c,
      LimitsFutureCallsUsed__c = this.logEntry.LimitsFutureCallsUsed__c,
      LimitsHeapSizeMax__c = this.logEntry.LimitsHeapSizeMax__c,
      LimitsHeapSizeUsed__c = this.logEntry.LimitsHeapSizeUsed__c,
      LimitsMobilePushApexCallsMax__c = this.logEntry.LimitsMobilePushApexCallsMax__c,
      LimitsMobilePushApexCallsUsed__c = this.logEntry.LimitsMobilePushApexCallsUsed__c,
      LimitsPublishImmediateDmlStatementsMax__c = this.logEntry.LimitsPublishImmediateDmlStatementsMax__c,
      LimitsPublishImmediateDmlStatementsUsed__c = this.logEntry.LimitsPublishImmediateDmlStatementsUsed__c,
      LimitsQueueableJobsMax__c = this.logEntry.LimitsQueueableJobsMax__c,
      LimitsQueueableJobsUsed__c = this.logEntry.LimitsQueueableJobsUsed__c,
      LimitsSoqlQueriesMax__c = this.logEntry.LimitsSoqlQueriesMax__c,
      LimitsSoqlQueriesUsed__c = this.logEntry.LimitsSoqlQueriesUsed__c,
      LimitsSoqlQueryLocatorRowsMax__c = this.logEntry.LimitsSoqlQueryLocatorRowsMax__c,
      LimitsSoqlQueryLocatorRowsUsed__c = this.logEntry.LimitsSoqlQueryLocatorRowsUsed__c,
      LimitsSoqlQueryRowsMax__c = this.logEntry.LimitsSoqlQueryRowsMax__c,
      LimitsSoqlQueryRowsUsed__c = this.logEntry.LimitsSoqlQueryRowsUsed__c,
      LimitsSoslSearchesMax__c = this.logEntry.LimitsSoslSearchesMax__c,
      LimitsSoslSearchesUsed__c = this.logEntry.LimitsSoslSearchesUsed__c,
      Locale__c = this.logEntry.Log__r.Locale__c,
      LogEntryName__c = this.logEntry.Name,
      LoggedById__c = this.logEntry.Log__r.LoggedBy__c,
      LoggedByUsername__c = this.logEntry.Log__r.LoggedByUsername__c,
      LoggerVersionNumber__c = this.logEntry.Log__r.LoggerVersionNumber__c,
      LoggingLevel__c = this.logEntry.LoggingLevel__c,
      LoggingLevelOrdinal__c = this.logEntry.LoggingLevelOrdinal__c,
      LoginApplication__c = this.logEntry.Log__r.LoginApplication__c,
      LoginBrowser__c = this.logEntry.Log__r.LoginBrowser__c,
      LoginHistoryId__c = this.logEntry.Log__r.LoginHistoryId__c,
      LoginPlatform__c = this.logEntry.Log__r.LoginPlatform__c,
      LoginType__c = this.logEntry.Log__r.LoginType__c,
      LogName__c = this.logEntry.Log__r.Name,
      LogoutUrl__c = this.logEntry.Log__r.LogoutUrl__c,
      LogPurgeAction__c = this.logEntry.Log__r.LogPurgeAction__c, // TODO Not sure it makes sense to have these fields in archive? Maybe?
      LogRetentionDate__c = this.logEntry.Log__r.LogRetentionDate__c, // TODO Not sure it makes sense to have these fields in archive? Maybe?
      Message__c = this.logEntry.Message__c,
      MessageMasked__c = String.valueOf(this.logEntry.MessageMasked__c),
      MessageTruncated__c = String.valueOf(this.logEntry.MessageTruncated__c),
      NetworkId__c = this.logEntry.Log__r.NetworkId__c,
      NetworkLoginUrl__c = this.logEntry.Log__r.NetworkLoginUrl__c,
      NetworkLogoutUrl__c = this.logEntry.Log__r.NetworkLogoutUrl__c,
      NetworkSelfRegistrationUrl__c = this.logEntry.Log__r.NetworkSelfRegistrationUrl__c,
      NetworkUrlPathPrefix__c = this.logEntry.Log__r.NetworkUrlPathPrefix__c,
      OrganizationDomainUrl__c = this.logEntry.Log__r.OrganizationDomainUrl__c,
      OrganizationEnvironmentType__c = this.logEntry.Log__r.OrganizationEnvironmentType__c,
      OrganizationId__c = this.logEntry.Log__r.OrganizationId__c,
      OrganizationInstanceName__c = this.logEntry.Log__r.OrganizationInstanceName__c,
      OrganizationInstanceReleaseCycle__c = this.logEntry.Log__r.OrganizationInstanceReleaseCycle__c, // TODO deprecated field
      OrganizationName__c = this.logEntry.Log__r.OrganizationName__c,
      OrganizationNamespacePrefix__c = this.logEntry.Log__r.OrganizationNamespacePrefix__c,
      OrganizationType__c = this.logEntry.Log__r.OrganizationType__c,
      OriginLocation__c = this.logEntry.OriginLocation__c,
      OriginType__c = this.logEntry.OriginType__c,
      ParentLogTransactionId__c = this.logEntry.Log__r.ParentLog__r?.TransactionId__c,
      Priority__c = this.logEntry.Log__r.Priority__c,
      ProfileId__c = this.logEntry.Log__r.ProfileId__c,
      ProfileName__c = this.logEntry.Log__r.ProfileName__c,
      RecordCollectionSize__c = this.logEntry.RecordCollectionSize__c,
      RecordCollectionType__c = this.logEntry.RecordCollectionType__c,
      RecordId__c = this.logEntry.RecordId__c,
      RecordJson__c = this.logEntry.RecordJson__c,
      RecordJsonMasked__c = String.valueOf(this.logEntry.RecordJsonMasked__c),
      RecordName__c = String.valueOf(this.logEntry.RecordName__c),
      RecordSObjectClassification__c = this.logEntry.RecordSObjectClassification__c,
      RecordSObjectType__c = this.logEntry.RecordSObjectType__c,
      RecordSObjectTypeNamespace__c = this.logEntry.RecordSObjectTypeNamespace__c,
      SessionId__c = this.logEntry.Log__r.SessionId__c,
      SessionSecurityLevel__c = this.logEntry.Log__r.SessionSecurityLevel__c,
      SessionType__c = this.logEntry.Log__r.SessionType__c,
      SourceIp__c = this.logEntry.Log__r.SourceIp__c,
      StackTrace__c = this.logEntry.StackTrace__c,
      Status__c = this.logEntry.Log__r.Status__c,
      SystemMode__c = this.logEntry.Log__r.SystemMode__c,
      Tags__c = String.join(tagNames, '\n'),
      ThemeDisplayed__c = this.logEntry.Log__r.ThemeDisplayed__c,
      Timestamp__c = this.logEntry.Timestamp__c,
      TimestampString__c = String.valueOf(this.logEntry.Timestamp__c),
      TimeZoneId__c = this.logEntry.Log__r.TimeZoneId__c,
      TransactionEntryNumber__c = this.logEntry.TransactionEntryNumber__c,
      TransactionId__c = this.logEntry.Log__r.TransactionId__c,
      TriggerIsExecuting__c = String.valueOf(this.logEntry.TriggerIsExecuting__c),
      TriggerOperationType__c = this.logEntry.TriggerOperationType__c,
      TriggerSObjectType__c = this.logEntry.TriggerSObjectType__c,
      UserLicenseDefinitionKey__c = this.logEntry.Log__r.UserLicenseDefinitionKey__c,
      UserLicenseName__c = this.logEntry.Log__r.UserLicenseName__c,
      UserLoggingLevel__c = this.logEntry.Log__r.UserLoggingLevel__c,
      UserLoggingLevelOrdinal__c = this.logEntry.Log__r.UserLoggingLevelOrdinal__c,
      UserRoleId__c = this.logEntry.Log__r.UserRoleId__c,
      UserRoleName__c = this.logEntry.Log__r.UserRoleName__c,
      UserType__c = this.logEntry.Log__r.UserType__c
    );
  }

  private void truncateFieldValues() {
    for (String fieldName : this.logEntryArchive.getPopulatedFieldsAsMap().keySet()) {
      Schema.SObjectField field = Schema.LogEntryArchive__b.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().get(fieldName);
      if (field.getDescribe().getSoapType() == Schema.SoapType.STRING) {
        String fieldValue = (String) this.logEntryArchive.get(field);
        this.logEntryArchive.put(field, fieldValue?.left(field.getDescribe().getLength()));
      }
    }
  }
}
