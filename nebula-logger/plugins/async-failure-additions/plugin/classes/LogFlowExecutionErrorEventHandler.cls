//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
/**
 * @group Plugins
 * @description `FlowExecutionErrorEvent` messages are created and fired by the platform when Screen Flows have unhandled errors, and this creates logs for them
 */
public without sharing class LogFlowExecutionErrorEventHandler {
  @TestVisible
  private static final String PARAMETER_DEV_NAME = 'FlowExecutionErrorEventHandled';
  @TestVisible
  private static final String LOG_STRING = 'An unhandled screen flow error occurred during element API name: {0} for flow version # {1}';

  /**
   * @description Invocable method called by platform event-triggered flow to add errors to logs
   * @param flowErrorEvents The `List<Schema.FlowExecutionErrorEvent>` associated with the unhandled exception(s)
   */
  @InvocableMethod(category='Logging' description='Adds error handling for unhandled errors in Screen Flows')
  public static void logErrors(List<Schema.FlowExecutionErrorEvent> flowErrorEvents) {
    if (LoggerParameter.getBoolean(PARAMETER_DEV_NAME, false) == false) {
      return;
    }
    Map<String, List<LogEntryEventBuilder>> usernameToBuilders = new Map<String, List<LogEntryEventBuilder>>();
    for (Schema.FlowExecutionErrorEvent flowExecutionErrorEvent : flowErrorEvents) {
      FlowLogger.LogEntry flowLogEntry = new FlowLogger.LogEntry();
      flowLogEntry.faultMessage = flowExecutionErrorEvent.ErrorMessage;
      flowLogEntry.flowName = flowExecutionErrorEvent.FlowApiName;
      flowLogEntry.loggingLevelName = System.LoggingLevel.ERROR.name();
      flowLogEntry.message = String.format(
        LOG_STRING,
        new List<String>{ flowExecutionErrorEvent.ElementApiName, flowExecutionErrorEvent.FlowVersionNumber.format() }
      );
      flowLogEntry.timestamp = flowExecutionErrorEvent.EventDate;
      LogEntryEventBuilder builder = flowLogEntry.addToLoggerBuffer()?.setRecord(flowExecutionErrorEvent.FlowVersionId);
      if (builder.shouldSave()) {
        // TODO remove this in a future release, this is a temporary fix until orgs have upgraded to v4.8.4.
        // Prior to v4.8.4, there was a bug in core package where the TimestampString__c field would be out of
        // sync with the Timestamp__c field, resulting in inaccurate data being used.
        // builder.getLogEntryEvent().Timestamp__c = flowLogEntry.timestamp.getTime());
        builder.getLogEntryEvent().TimestampString__c = String.valueOf(flowLogEntry.timestamp.getTime());

        List<LogEntryEventBuilder> builders = usernameToBuilders.containsKey(flowExecutionErrorEvent.Username)
          ? usernameToBuilders.get(flowExecutionErrorEvent.Username)
          : new List<LogEntryEventBuilder>();
        builders.add(builder);
        usernameToBuilders.put(flowExecutionErrorEvent.Username, builders);
      }
    }
    overrideUserInfo(usernameToBuilders);
    Logger.saveLog();
  }

  @SuppressWarnings('PMD.ApexCrudViolation')
  private static void overrideUserInfo(Map<String, List<LogEntryEventBuilder>> usernameToBuilders) {
    Map<String, Schema.User> usernameToUser = new Map<String, Schema.User>();
    for (Schema.User user : [
      SELECT
        Id,
        ProfileId,
        Profile.Name,
        Profile.UserLicenseId,
        Profile.UserLicense.LicenseDefinitionKey,
        Profile.UserLicense.Name,
        TimeZoneSidKey,
        Username,
        UserRoleId,
        UserRole.Name,
        UserType
      FROM User
      WHERE Username = :usernameToBuilders.keySet()
    ]) {
      usernameToUser.put(user.Username, user);
    }
    for (String username : usernameToBuilders.keySet()) {
      List<LogEntryEventBuilder> builders = usernameToBuilders.get(username);
      Schema.User loggingUser = usernameToUser.get(username);
      TimeZone tz = Timezone.getTimeZone(loggingUser.TimeZoneSidKey);
      for (LogEntryEventBuilder builder : builders) {
        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();
        // override Schema.User-level fields
        logEntryEvent.LoggedById__c = loggingUser.Id;
        logEntryEvent.LoggedByUsername__c = loggingUser.Username;
        logEntryEvent.ProfileName__c = loggingUser.Profile.Name;
        logEntryEvent.UserLicenseDefinitionKey__c = loggingUser.Profile.UserLicense.LicenseDefinitionKey;
        logEntryEvent.UserLicenseId__c = loggingUser.Profile.UserLicenseId;
        logEntryEvent.UserLicenseName__c = loggingUser.Profile.UserLicense.Name;
        logEntryEvent.UserRoleName__c = loggingUser.UserRole?.Name;
        logEntryEvent.ProfileId__c = loggingUser.ProfileId;
        logEntryEvent.TimeZoneId__c = tz.getId();
        logEntryEvent.TimeZoneName__c = tz.getDisplayName();
        logEntryEvent.UserRoleId__c = loggingUser.UserRoleId;
        logEntryEvent.UserType__c = loggingUser.UserType;

        // clear Auth-related fields
        logEntryEvent.LoginApplication__c = null;
        logEntryEvent.LoginBrowser__c = null;
        logEntryEvent.LoginHistoryId__c = null;
        logEntryEvent.LoginPlatform__c = null;
        logEntryEvent.LoginType__c = null;
        logEntryEvent.LogoutUrl__c = null;
        logEntryEvent.NetworkId__c = null;
        logEntryEvent.SessionId__c = null;
        logEntryEvent.SessionSecurityLevel__c = null;
        logEntryEvent.SessionType__c = null;
        logEntryEvent.SourceIp__c = null;
      }
    }
  }
}
