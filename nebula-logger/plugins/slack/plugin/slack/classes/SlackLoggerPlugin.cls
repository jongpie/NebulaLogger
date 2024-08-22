//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Optional plugin that integrates with Slack to send alerts for important logs
 */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.CyclomaticComplexity, PMD.ExcessivePublicCount')
public without sharing class SlackLoggerPlugin implements LoggerPlugin.Triggerable, System.Queueable, Database.AllowsCallouts {
  @TestVisible
  private static final String ENDPOINT = LoggerParameter.getString('SlackEndpoint', null);
  @TestVisible
  private static final String FIELD_SET_NAME = LoggerParameter.getString('SlackFieldSet', 'SlackLogNotificationFields');
  @TestVisible
  private static final Boolean IGNORE_NULL_FIELDS = true;
  @TestVisible
  private static final List<Schema.SObjectField> LOG_ENTRY_FIELDS = new List<Schema.SObjectField>{
    Schema.LogEntry__c.ExceptionStackTrace__c,
    Schema.LogEntry__c.StackTrace__c
  };
  @TestVisible
  private static final String NOTIFICATION_COLOR_RED = '#FF7373';
  @TestVisible
  private static final String NOTIFICATION_COLOR_ORANGE = '#FFC873';
  @TestVisible
  private static final String NOTIFICATION_COLOR_GREEN = '#7CD197';
  @TestVisible
  private static final System.LoggingLevel NOTIFICATION_LOGGING_LEVEL = Logger.getLoggingLevel(
    LoggerParameter.getString('SlackNotificationLoggingLevel', System.LoggingLevel.WARN.name())
  );
  @TestVisible
  private static final String NOTIFICATION_TITLE = 'Salesforce Log Alert';

  private List<Log__c> logs;

  /**
   * @description Default constructor
   */
  @SuppressWarnings('PMD.EmptyStatementBlock')
  public SlackLoggerPlugin() {
  }

  private SlackLoggerPlugin(List<Log__c> unsentLogs) {
    this();
    this.logs = unsentLogs;
  }

  /**
   * @description Handles the integration with Slack. This method is automatically called by Nebula Logger's plugin framework.
   * @param  configuration The instance of `LoggerPlugin__mdt` configured for this specific plugin
   * @param  context The instance of `LoggerTriggerableContext`, provided by the logging system
   */
  public void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext context) {
    if (context.sobjectType != Schema.Log__c.SObjectType || String.isBlank(ENDPOINT)) {
      return;
    }

    this.logs = (List<Log__c>) context.triggerNew;
    switch on context.triggerOperationType {
      when BEFORE_INSERT, BEFORE_UPDATE {
        this.flagLogsForSlackNotification();
      }
      when AFTER_INSERT, AFTER_UPDATE {
        this.sendAsyncSlackNotifications();
      }
    }
  }

  /**
   * @description Handles the queuable execute logic. Required by the System.Queueable interface.
   * @param queueableContext Context of the current queuable instance.
   */
  public void execute(System.QueueableContext queueableContext) {
    // Since this runs in an async context, requery the logs just in case any field values have changed
    this.requeryLogs();
    // TODO bulkify tags querying
    // this.requeryTags();

    if (this.logs.isEmpty()) {
      return;
    }

    List<Log__c> sentLogs = new List<Log__c>();
    List<Log__c> unsentLogs = new List<Log__c>();
    for (Log__c log : this.logs) {
      if (System.Limits.getCallouts() == System.Limits.getLimitCallouts()) {
        // If there are too many logs to send in the same transaction
        // add them to the unsentLogs list, which will be queued as a separate job
        unsentLogs.add(log);
        continue;
      }

      System.HttpRequest request = this.createSlackHttpRequest();
      NotificationDto notification = new NotificationDto();
      notification.text = NOTIFICATION_TITLE;
      notification.attachments = new List<LogDto>{ this.convertLog(log) };
      // 'Short' is a reserved word in Apex, but used in Slack's API, so the conversion happens in JSON
      String notificationJson = System.JSON.serialize(notification).replace('"isShort"', '"short"');
      request.setBody(notificationJson);
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.finest('Sending log entries to Slack endpoint').setHttpRequestDetails(request);
      }

      System.HttpResponse response = new System.Http().send(request);
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.finest('Sent log entries to Slack endpoint').setHttpResponseDetails(response);
      }

      log.SlackNotificationDate__c = System.now();
      sentLogs.add(log);
    }
    Logger.saveLog();
    update sentLogs;

    // If any logs couldn't be sent due to governor limits, start a new instance of the job
    if (unsentLogs.size() > 0) {
      System.enqueueJob(new SlackLoggerPlugin(unsentLogs));
    }
  }

  private void flagLogsForSlackNotification() {
    if (NOTIFICATION_LOGGING_LEVEL == null) {
      return;
    }

    for (Log__c log : this.logs) {
      if (log.MaxLogEntryLoggingLevelOrdinal__c >= NOTIFICATION_LOGGING_LEVEL.ordinal()) {
        log.SendSlackNotification__c = true;
      }
    }
  }

  private void sendAsyncSlackNotifications() {
    List<Log__c> logsToSend = new List<Log__c>();
    for (Log__c log : this.logs) {
      if (log.SendSlackNotification__c) {
        logsToSend.add(log);
      }
    }
    // Since plugins are called from trigger handlers, and triggers can't make callouts
    // run this class as a queueable (async) job
    if (logsToSend.isEmpty() == false) {
      System.enqueueJob(new SlackLoggerPlugin(logsToSend));
    }
  }

  private Schema.FieldSet getFieldSet() {
    return Schema.SObjectType.Log__c.fieldSets.getMap().get(FIELD_SET_NAME);
  }

  @SuppressWarnings('PMD.UnusedLocalVariable')
  private void requeryLogs() {
    Integer loggingLevelOrdinal = NOTIFICATION_LOGGING_LEVEL.ordinal();
    String logEntryChildQuery =
      '\n(' +
      '\nSELECT Id, LoggingLevel__c, Message__c, ExceptionStackTrace__c, StackTrace__c' +
      '\nFROM LogEntries__r' +
      '\nWHERE LoggingLevelOrdinal__c >= :loggingLevelOrdinal' +
      '\nORDER BY Timestamp__c DESC' +
      '\nLIMIT 1' +
      '\n)';
    List<String> fieldNames = new List<String>{
      Schema.Log__c.Name.getDescribe().getName(),
      logEntryChildQuery,
      'LoggedBy__r.Username',
      'TYPEOF Owner WHEN User THEN Username ELSE Name END'
    };
    for (Schema.FieldSetMember fieldSetMember : getFieldSet().getFields()) {
      fieldNames.add(fieldSetMember.getFieldPath());
    }
    // Deduplicate the list of field names
    fieldNames = new List<String>(new Set<String>(fieldNames));
    String query =
      'SELECT ' +
      String.join(fieldNames, ', ') +
      ' FROM Log__c' +
      '\nWHERE Id IN :logs' +
      '\nAND MaxLogEntryLoggingLevelOrdinal__c >= :loggingLevelOrdinal' +
      '\nAND SendSlackNotification__c = TRUE' +
      '\nAND SlackNotificationDate__c = NULL';
    this.logs = (List<Log__c>) System.Database.query(query);
  }

  private System.HttpRequest createSlackHttpRequest() {
    System.HttpRequest request = new System.HttpRequest();
    request.setEndpoint(ENDPOINT);
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('Created Slack HTTP Request').setHttpRequestDetails(request);
    }
    return request;
  }

  @SuppressWarnings('PMD.NcssMethodCount')
  private LogDto convertLog(Log__c log) {
    LogDto notification = createNotification(log);

    notification.fields = new List<FieldDto>();
    notification.fields.addAll(createRecordNotificationFields(LOG_ENTRY_FIELDS, log.LogEntries__r.get(0)));
    notification.fields.addAll(createRecordNotificationFields(getFieldSet().getFields(), log));
    notification.fields.addAll(createTagsNotificationFields(log));

    return notification;
  }

  private LogDto createNotification(Log__c log) {
    LogEntry__c lastLogEntry = log.LogEntries__r.get(0);
    String lastLogEntryMessage = 'Last Log Entry Message' + '\n```' + lastLogEntry.LoggingLevel__c + ': ' + lastLogEntry.Message__c + '```';
    LogDto notification = new LogDto();
    notification.author_link = System.URL.getOrgDomainUrl().toExternalForm() + '/' + log.LoggedBy__c;
    notification.author_name = log.LoggedBy__r.Username;
    notification.color = this.getNotificationColor(log);
    notification.fields = new List<FieldDto>();
    notification.text = lastLogEntryMessage;
    notification.title = log.Name;
    notification.title_link = System.URL.getOrgDomainUrl().toExternalForm() + '/' + log.Id;

    return notification;
  }

  private String getNotificationColor(Log__c log) {
    if (log.TotalERRORLogEntries__c >= 1) {
      return NOTIFICATION_COLOR_RED;
    } else if (log.TotalWARNLogEntries__c >= 1) {
      return NOTIFICATION_COLOR_ORANGE;
    } else {
      return NOTIFICATION_COLOR_GREEN;
    }
  }

  private List<FieldDto> createRecordNotificationFields(List<Schema.FieldSetMember> fieldSetMembers, SObject record) {
    List<FieldDto> notificationFields = new List<FieldDto>();
    for (Schema.FieldSetMember fieldSetMember : fieldSetMembers) {
      FieldDto notificationField = this.createRecordNotificationField(fieldSetMember.getFieldPath(), fieldSetMember.getSObjectField(), record);
      if (notificationField != null) {
        notificationFields.add(notificationField);
      }
    }
    return notificationFields;
  }

  private List<FieldDto> createRecordNotificationFields(List<Schema.SObjectField> fields, SObject record) {
    List<FieldDto> notificationFields = new List<FieldDto>();
    for (Schema.SObjectField field : fields) {
      FieldDto notificationField = this.createRecordNotificationField(field.getDescribe().getName(), field, record);
      if (notificationField != null) {
        notificationFields.add(notificationField);
      }
    }
    return notificationFields;
  }

  private FieldDto createRecordNotificationField(String fieldPath, Schema.SObjectField field, SObject record) {
    FieldDto fieldDto = new FieldDto();
    fieldDto.fieldPath = fieldPath;
    fieldDto.title = field.getDescribe().getLabel();

    Object fieldValue;
    List<String> fieldPieces = fieldPath.split('\\.');
    if (fieldPieces.size() == 2) {
      // Field set members can only go up 1 level, so no need to check for multiple
      // hops to grandparent records
      SObject parentRecord = record.getSObject(fieldPieces.get(0));
      fieldValue = parentRecord?.get(fieldPieces.get(1));
    } else {
      fieldValue = record.get(fieldPath);
    }

    if (IGNORE_NULL_FIELDS && fieldValue == null) {
      return null;
    }

    String stringValue = String.valueOf(fieldValue);
    Integer maxShortLength = 255;
    fieldDto.isShort = stringValue.contains('\n') == false || stringValue.length() <= maxShortLength;
    String valueWrapper = fieldDto.isShort ? '`' : '\n```\n';
    fieldDto.value = valueWrapper + stringValue + valueWrapper;
    return fieldDto;
  }

  private List<FieldDto> createTagsNotificationFields(Log__c log) {
    List<FieldDto> notificationFields = new List<FieldDto>();
    // TODO bulkify! this is a query within a query
    List<String> tagNames = new List<String>();
    List<LoggerTag__c> tags = [
      SELECT UniqueId__c
      FROM LoggerTag__c
      WHERE Id IN (SELECT Tag__c FROM LogEntryTag__c WHERE LogEntry__r.Log__c = :log.Id)
      ORDER BY UniqueId__c
    ];
    for (LoggerTag__c tag : tags) {
      tagNames.add('`' + tag.UniqueId__c + '`');
    }
    if (tags.isEmpty() == false) {
      FieldDto tagNamesField = new FieldDto();
      tagNamesField.isShort = false;
      tagNamesField.fieldPath = null;
      tagNamesField.title = 'Tags';
      tagNamesField.value = String.join(tagNames, ' ');
      notificationFields.add(tagNamesField);
    }
    return notificationFields;
  }

  private String createTagsField(Log__c log) {
    // TODO Add Scenario__c field
    // TODO Possible include to LogEntryTag__c (tag names)
    // TODO bulkify! this is a query within a query
    List<String> tagNames = new List<String>();
    List<LoggerTag__c> tags = [
      SELECT UniqueId__c
      FROM LoggerTag__c
      WHERE Id IN (SELECT Tag__c FROM LogEntryTag__c WHERE LogEntry__r.Log__c = :log.Id)
      ORDER BY UniqueId__c
    ];

    if (tagNames.isEmpty()) {
      return null;
    }

    for (LoggerTag__c tag : tags) {
      tagNames.add('`' + tag.UniqueId__c + '`');
    }
    return String.join(tagNames, ' ');
  }

  // Private DTO classes that match Slack's API
  @TestVisible
  private class NotificationDto {
    public List<LogDto> attachments;
    public String text;
  }

  @SuppressWarnings('PMD.FieldNamingConventions, PMD.VariableNamingConventions')
  @TestVisible
  private class LogDto {
    public String author_name;
    public String author_link;
    public String color;
    public List<FieldDto> fields;
    public String footer;
    public String pretext;
    public String text;
    public String title;
    public String title_link;
  }

  @TestVisible
  private class FieldDto {
    public Boolean isShort;
    public String fieldPath;
    public String title;
    public String value;
  }
}
