//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class SlackLoggerPlugin_Tests {
  @IsTest
  static void it_should_not_flag_log_to_send_slack_notification_when_logging_level_is_not_met() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.WARN;
    System.LoggingLevel slackNotificationLoggingLevel = System.LoggingLevel.ERROR;
    System.Assert.isTrue(logEntryLoggingLevel.ordinal() < slackNotificationLoggingLevel.ordinal(), 'Slack logging level ordinal was incorrect');
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(slackNotificationLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, false);
    Log__c log = logs.get(0);
    System.Assert.isFalse(log.SendSlackNotification__c);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.BEFORE_INSERT, logs);

    SlackLoggerPlugin plugin = new SlackLoggerPlugin();
    plugin.execute(pluginConfiguration, context);

    System.Assert.isFalse(log.SendSlackNotification__c, 'SendSlackNotification__c incorrectly set to true');
    System.Assert.isNull(log.SlackNotificationDate__c, 'SlackNotificationDate__c was not null');
  }

  @IsTest
  static void it_should_flag_log_to_send_slack_notification_when_logging_level_is_met() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.ERROR;
    System.LoggingLevel slackNotificationLoggingLevel = System.LoggingLevel.WARN;
    System.Assert.isTrue(logEntryLoggingLevel.ordinal() > slackNotificationLoggingLevel.ordinal(), 'Slack logging level ordinal was incorrect');
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(slackNotificationLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, false);
    Log__c log = logs.get(0);
    System.Assert.isFalse(log.SendSlackNotification__c);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.BEFORE_INSERT, logs);

    SlackLoggerPlugin plugin = new SlackLoggerPlugin();
    plugin.execute(pluginConfiguration, context);

    log = logs.get(0);
    System.Assert.isTrue(log.SendSlackNotification__c, 'SendSlackNotification__c incorrectly set to false');
    System.Assert.isNull(log.SlackNotificationDate__c, 'SlackNotificationDate__c was not null');
  }

  @IsTest
  static void it_should_not_send_slack_notification_for_log_when_logging_level_is_not_met() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.WARN;
    System.LoggingLevel slackNotificationLoggingLevel = System.LoggingLevel.ERROR;
    System.Assert.isTrue(logEntryLoggingLevel.ordinal() < slackNotificationLoggingLevel.ordinal(), 'Slack logging level ordinal was incorrect');
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(slackNotificationLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, false);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    SlackLoggerPlugin plugin = new SlackLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Assert.areEqual(0, System.Limits.getAsyncCalls(), 'The queueable job should not have been enqueued');
    System.Test.stopTest();

    Log__c log = queryLogs(logEntryLoggingLevel).get(0);
    System.Assert.isFalse(log.SendSlackNotification__c, 'SendSlackNotification__c incorrectly set to true');
    System.Assert.isNull(log.SlackNotificationDate__c, 'SlackNotificationDate__c was not null');
    System.Assert.isNull(calloutMock.request);
  }

  @IsTest
  static void it_should_send_slack_notification_for_log_when_logging_level_is_met_for_error() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.ERROR;
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(logEntryLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, true);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    SlackLoggerPlugin plugin = new SlackLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Test.stopTest();

    SlackLoggerPlugin.NotificationDto slackNotification = validateSlackNotification(calloutMock, logs.get(0));
    System.Assert.areEqual(SlackLoggerPlugin.NOTIFICATION_COLOR_RED, slackNotification.attachments.get(0).color);
  }

  @IsTest
  static void it_should_send_slack_notification_for_log_when_logging_level_is_met_for_warn() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.WARN;
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(logEntryLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, true);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    SlackLoggerPlugin plugin = new SlackLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Test.stopTest();

    SlackLoggerPlugin.NotificationDto slackNotification = validateSlackNotification(calloutMock, logs.get(0));
    System.Assert.areEqual(SlackLoggerPlugin.NOTIFICATION_COLOR_ORANGE, slackNotification.attachments.get(0).color);
  }

  @IsTest
  static void it_should_send_slack_notification_for_log_when_logging_level_is_met_for_info() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.INFO;
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(logEntryLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, true);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    SlackLoggerPlugin plugin = new SlackLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Test.stopTest();

    SlackLoggerPlugin.NotificationDto slackNotification = validateSlackNotification(calloutMock, logs.get(0));
    System.Assert.areEqual(SlackLoggerPlugin.NOTIFICATION_COLOR_GREEN, slackNotification.attachments.get(0).color);
  }

  @IsTest
  static void it_should_send_slack_notification_for_log_when_logging_level_is_met_for_debug() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.DEBUG;
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(logEntryLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, true);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    SlackLoggerPlugin plugin = new SlackLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Test.stopTest();

    SlackLoggerPlugin.NotificationDto slackNotification = validateSlackNotification(calloutMock, logs.get(0));
    System.Assert.areEqual(SlackLoggerPlugin.NOTIFICATION_COLOR_GREEN, slackNotification.attachments.get(0).color);
  }

  @IsTest
  static void it_should_send_slack_notification_for_log_when_logging_level_is_met_for_fine() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.FINE;
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(logEntryLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, true);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    SlackLoggerPlugin plugin = new SlackLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Test.stopTest();

    SlackLoggerPlugin.NotificationDto slackNotification = validateSlackNotification(calloutMock, logs.get(0));
    System.Assert.areEqual(SlackLoggerPlugin.NOTIFICATION_COLOR_GREEN, slackNotification.attachments.get(0).color);
  }

  @IsTest
  static void it_should_send_slack_notification_for_log_when_logging_level_is_met_for_finer() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.FINER;
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(logEntryLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, true);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    SlackLoggerPlugin plugin = new SlackLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Test.stopTest();

    SlackLoggerPlugin.NotificationDto slackNotification = validateSlackNotification(calloutMock, logs.get(0));
    System.Assert.areEqual(SlackLoggerPlugin.NOTIFICATION_COLOR_GREEN, slackNotification.attachments.get(0).color);
  }

  @IsTest
  static void it_should_send_slack_notification_for_log_when_logging_level_is_met_for_finest() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.FINEST;
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(logEntryLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, true);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    SlackLoggerPlugin plugin = new SlackLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Test.stopTest();

    SlackLoggerPlugin.NotificationDto slackNotification = validateSlackNotification(calloutMock, logs.get(0));
    System.Assert.areEqual(SlackLoggerPlugin.NOTIFICATION_COLOR_GREEN, slackNotification.attachments.get(0).color);
  }

  private static LoggerPlugin__mdt mockConfigurations(System.LoggingLevel notificationLoggingLevel) {
    String mockEndpoint = 'https://fake.slack.com/';
    LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'SlackEndpoint', Value__c = mockEndpoint));
    LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'SlackNotificationLoggingLevel', Value__c = notificationLoggingLevel.name()));
    System.Assert.areEqual(mockEndpoint, LoggerParameter.getString('SlackEndpoint', null));
    System.Assert.areEqual(mockEndpoint, SlackLoggerPlugin.ENDPOINT);
    System.Assert.areEqual(notificationLoggingLevel.name(), LoggerParameter.getString('SlackNotificationLoggingLevel', null));
    System.Assert.areEqual(notificationLoggingLevel, SlackLoggerPlugin.NOTIFICATION_LOGGING_LEVEL);

    LoggerPlugin__mdt pluginConfiguration = new LoggerPlugin__mdt(
      DeveloperName = 'SlackPlugin',
      IsEnabled__c = true,
      SObjectHandlerApexClass__c = SlackLoggerPlugin.class.getName()
    );
    LoggerTestConfigurator.setMock(pluginConfiguration);
    return pluginConfiguration;
  }

  private static LoggerTriggerableContext mockContext(System.TriggerOperation operationType, List<Log__c> logs) {
    return new LoggerTriggerableContext(Schema.Log__c.SObjectType, operationType, logs, new Map<Id, SObject>(logs), new Map<Id, SObject>(logs));
  }

  private static List<Log__c> insertLogAndLogEntry(System.LoggingLevel logEntryLoggingLevel, Boolean sendSlackNotification) {
    LoggerSObjectHandler.shouldExecute(false);
    Log__c log = new Log__c(LoggedBy__c = System.UserInfo.getUserId(), SendSlackNotification__c = sendSlackNotification, TransactionId__c = '1234');
    insert log;
    LogEntry__c logEntry = new LogEntry__c(
      ExceptionStackTrace__c = 'Some exception stack trace',
      Log__c = log.Id,
      LoggingLevel__c = logEntryLoggingLevel.name(),
      LoggingLevelOrdinal__c = logEntryLoggingLevel.ordinal(),
      StackTrace__c = 'A stack trace',
      Timestamp__c = System.now()
    );
    insert logEntry;
    return queryLogs(logEntryLoggingLevel);
  }

  private static SlackLoggerPlugin.NotificationDto validateSlackNotification(LoggerMockDataCreator.MockHttpCallout calloutMock, Log__c log) {
    // 'Short' is a reserved word in Apex, but used in Slack's API, so the conversion happens in JSON
    String requestBody = calloutMock.request.getBody().replace('"short"', '"isShort"');
    SlackLoggerPlugin.NotificationDto slackNotification = (SlackLoggerPlugin.NotificationDto) System.JSON.deserialize(
      requestBody,
      SlackLoggerPlugin.NotificationDto.class
    );
    System.Assert.areEqual(SlackLoggerPlugin.NOTIFICATION_TITLE, slackNotification.text);
    System.Assert.areEqual(1, slackNotification.attachments.size());
    validateSlackNotificationFields(slackNotification, log);

    return slackNotification;
  }

  private static void validateSlackNotificationFields(SlackLoggerPlugin.NotificationDto slackNotification, Log__c log) {
    List<String> expectedFieldPaths = new List<String>();
    for (Schema.FieldSetMember fieldSetMember : Schema.SObjectType.Log__c.fieldSets.getMap().get(SlackLoggerPlugin.FIELD_SET_NAME).getFields()) {
      if (SlackLoggerPlugin.IGNORE_NULL_FIELDS == false || isFieldPathPopulated(log, fieldSetMember.getFieldPath())) {
        expectedFieldPaths.add(fieldSetMember.getFieldPath());
      }
    }

    Set<String> returnedFieldPaths = new Set<String>();
    for (SlackLoggerPlugin.FieldDto notificationField : slackNotification.attachments.get(0).fields) {
      if (notificationField.fieldPath != null) {
        returnedFieldPaths.add(notificationField.fieldPath);
      }
    }

    for (String expectedFieldPath : expectedFieldPaths) {
      System.Assert.isTrue(returnedFieldPaths.contains(expectedFieldPath), 'Field ' + expectedFieldPath + ' was not included in the Slack notification');
    }
  }

  private static Boolean isFieldPathPopulated(Log__c log, String fieldPath) {
    List<String> fieldPieces = fieldPath.split('\\.');
    if (fieldPieces.size() == 2) {
      // Field set members can only go up 1 level, so no need to check for multiple
      // hops to grandparent records
      SObject parentRecord = log.getSObject(fieldPieces.get(0));
      return parentRecord?.get(fieldPieces.get(1)) != null;
    } else {
      return log.getPopulatedFieldsAsMap().containsKey(fieldPath);
    }
  }

  @SuppressWarnings('PMD.UnusedLocalVariable')
  private static List<Log__c> queryLogs(System.LoggingLevel notificationLoggingLevel) {
    List<String> fieldNames = new List<String>{
      Schema.Log__c.MaxLogEntryLoggingLevelOrdinal__c.toString(),
      Schema.Log__c.SendSlackNotification__c.toString(),
      Schema.Log__c.SlackNotificationDate__c.toString()
    };
    for (Schema.FieldSetMember fieldSetMember : Schema.SObjectType.Log__c.fieldSets.getMap().get(SlackLoggerPlugin.FIELD_SET_NAME).getFields()) {
      fieldNames.add(fieldSetMember.getFieldPath());
    }

    Integer notificationLoggingLevelOrdinal = notificationLoggingLevel.ordinal();
    String logEntryChildQuery =
      '\n(' +
      '\nSELECT Id, LoggingLevel__c, Message__c, ExceptionStackTrace__c, StackTrace__c' +
      '\nFROM LogEntries__r' +
      '\nWHERE LoggingLevelOrdinal__c >= :notificationLoggingLevelOrdinal' +
      '\nORDER BY Timestamp__c DESC' +
      '\nLIMIT 1' +
      '\n)';
    fieldNames.add(logEntryChildQuery);

    String query = 'SELECT ' + String.join(fieldNames, ', ') + ' FROM Log__c';
    return (List<Log__c>) System.Database.query(query);
  }
}
