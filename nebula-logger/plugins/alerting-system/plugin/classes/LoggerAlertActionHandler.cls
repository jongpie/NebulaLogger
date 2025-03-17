//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Handles trigger events for the `LoggerAlertAction__c` object
 */
public without sharing class LoggerAlertActionHandler extends LoggerSObjectHandler {
  private static final String TYPE_SLACK = 'Slack';

  private static final Map<String, Schema.SObjectField> LOG_ENTRY_EVENT_FIELD_NAME_TO_FIELD {
    get {
      if (LOG_ENTRY_EVENT_FIELD_NAME_TO_FIELD == null) {
        LOG_ENTRY_EVENT_FIELD_NAME_TO_FIELD = Schema.SObjectType.LogEntryEvent__e.fields.getMap();
      }
      return LOG_ENTRY_EVENT_FIELD_NAME_TO_FIELD;
    }
    private set;
  }

  private static final Map<String, Schema.SObjectField> LOG_FIELD_NAME_TO_FIELD {
    get {
      if (LOG_FIELD_NAME_TO_FIELD == null) {
        LOG_FIELD_NAME_TO_FIELD = Schema.SObjectType.Log__c.fields.getMap();
      }
      return LOG_FIELD_NAME_TO_FIELD;
    }
    private set;
  }

  private static final Map<String, Schema.SObjectField> LOG_ENTRY_FIELD_NAME_TO_FIELD {
    get {
      if (LOG_ENTRY_FIELD_NAME_TO_FIELD == null) {
        LOG_ENTRY_FIELD_NAME_TO_FIELD = Schema.SObjectType.LogEntry__c.fields.getMap();
      }
      return LOG_ENTRY_FIELD_NAME_TO_FIELD;
    }
    private set;
  }

  private static final Map<String, Schema.SObjectField> LOG_ENTRY_TAG_FIELD_NAME_TO_FIELD {
    get {
      if (LOG_ENTRY_TAG_FIELD_NAME_TO_FIELD == null) {
        LOG_ENTRY_TAG_FIELD_NAME_TO_FIELD = Schema.SObjectType.LogEntryTag__c.fields.getMap();
      }
      return LOG_ENTRY_TAG_FIELD_NAME_TO_FIELD;
    }
    private set;
  }

  /**
   * @description Returns SObject Type that the handler is responsible for processing
   * @return      The instance of `SObjectType`
   */
  public override Schema.SObjectType getSObjectType() {
    return Schema.LoggerAlertAction__c.SObjectType;
  }

  protected override void executeBeforeInsert(List<SObject> triggerNew) {
    List<LoggerAlertAction__c> loggerAlertActions = (List<LoggerAlertAction__c>) triggerNew;

    LoggerAlertActionHandler.validateNamedCredentials(loggerAlertActions);
    LoggerAlertActionHandler.validateDisplayFields(loggerAlertActions);
  }

  protected override void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
    List<LoggerAlertAction__c> loggerAlertActions = (List<LoggerAlertAction__c>) triggerNewMap.values();
    Map<Id, LoggerAlertAction__c> idToOldLoggerAlertAction = (Map<Id, LoggerAlertAction__c>) triggerOldMap;

    LoggerAlertActionHandler.validateNamedCredentials(loggerAlertActions, idToOldLoggerAlertAction);
    LoggerAlertActionHandler.validateDisplayFields(loggerAlertActions, idToOldLoggerAlertAction);
  }

  private static void validateNamedCredentials(
    List<LoggerAlertAction__c> loggerAlertActions,
    Map<Id, LoggerAlertAction__c> loggerAlertActionIdToOldLoggerAlertAction
  ) {
    List<LoggerAlertAction__c> changedLoggerAlertActions = new List<LoggerAlertAction__c>();
    for (LoggerAlertAction__c loggerAlertAction : loggerAlertActions) {
      LoggerAlertAction__c oldLoggerAlertAction = loggerAlertActionIdToOldLoggerAlertAction.get(loggerAlertAction.Id);
      if (
        String.isNotBlank(loggerAlertAction.CalloutNamedCredential__c) &&
        loggerAlertAction.CalloutNamedCredential__c != oldLoggerAlertAction.CalloutNamedCredential__c
      ) {
        changedLoggerAlertActions.add(loggerAlertAction);
      }
    }

    LoggerAlertActionHandler.validateNamedCredentials(changedLoggerAlertActions);
  }

  /**
   * @description Validates that the field `CalloutNamedCredential__c` contains a valid developer name
   * @param  loggerAlertActions The action records to validate
   */
  private static void validateNamedCredentials(List<LoggerAlertAction__c> loggerAlertActions) {
    List<LoggerAlertAction__c> actionsToValidate = new List<LoggerAlertAction__c>();
    List<String> namedCredentialDeveloperNames = new List<String>();
    for (LoggerAlertAction__c loggerAlertAction : loggerAlertActions) {
      if (String.isNotBlank(loggerAlertAction.CalloutNamedCredential__c)) {
        actionsToValidate.add(loggerAlertAction);
        namedCredentialDeveloperNames.add(loggerAlertAction.CalloutNamedCredential__c);
      }
    }

    Map<String, Schema.NamedCredential> developerNameToNamedCredential = new Map<String, Schema.NamedCredential>();
    for (Schema.NamedCredential matchingNamedCredential : [
      SELECT Id, DeveloperName
      FROM NamedCredential
      WHERE DeveloperName IN :namedCredentialDeveloperNames
    ]) {
      developerNameToNamedCredential.put(matchingNamedCredential.DeveloperName, matchingNamedCredential);
    }

    for (LoggerAlertAction__c loggerAlertAction : actionsToValidate) {
      if (developerNameToNamedCredential.get(loggerAlertAction.CalloutNamedCredential__c) == null) {
        loggerAlertAction.CalloutNamedCredential__c.addError('Unknown name credential ' + loggerAlertAction.CalloutNamedCredential__c);
      }
    }
  }

  private static void validateDisplayFields(
    List<LoggerAlertAction__c> loggerAlertActions,
    Map<Id, LoggerAlertAction__c> loggerAlertActionIdToOldLoggerAlertAction
  ) {
    List<LoggerAlertAction__c> changedLoggerAlertActions = new List<LoggerAlertAction__c>();
    for (LoggerAlertAction__c loggerAlertAction : loggerAlertActions) {
      if (loggerAlertAction.Type__c != TYPE_SLACK) {
        continue;
      }

      LoggerAlertAction__c oldLoggerAlertAction = loggerAlertActionIdToOldLoggerAlertAction.get(loggerAlertAction.Id);
      if (loggerAlertAction.OutputFields__c != oldLoggerAlertAction.OutputFields__c) {
        changedLoggerAlertActions.add(loggerAlertAction);
      }
    }

    LoggerAlertActionHandler.validateDisplayFields(changedLoggerAlertActions);
  }

  /**
   * @description Validates that the field `OutputFields__c` contains 1 or more valid fields that should be included
   *              in the Slack message. This includes support for parent level fields (e.g. `Log__r.TransactionId__c`)
   * @param  loggerAlertActions The action records to validate
   */
  private static void validateDisplayFields(List<LoggerAlertAction__c> loggerAlertActions) {
    for (LoggerAlertAction__c loggerAlertAction : loggerAlertActions) {
      if (loggerAlertAction.Type__c != TYPE_SLACK) {
        continue;
      }

      if (String.isBlank(loggerAlertAction.OutputFields__c)) {
        loggerAlertAction.OutputFields__c.addError('1 or more ' + loggerAlertAction.SourceSObjectType__c + ' fields must be specified for Slack action');
        continue;
      }

      Schema.SObjectType sourceSObjectType = getSObjectType(loggerAlertAction.SourceSObjectType__c);
      Map<String, Schema.SObjectField> sourceSObjectFieldNameToField = getSourceFieldMap(loggerAlertAction.SourceSObjectType__c);
      List<String> displayFieldNames = loggerAlertAction.OutputFields__c.split('[ ,\\n]');
      List<String> cleanedDisplayFieldNames = new List<String>();
      List<String> invalidFieldPathStrings = new List<String>();
      for (String displayFieldName : displayFieldNames) {
        String cleanedDisplayFieldName = displayFieldName?.trim();
        // When splitting the field OutputFields__c, some empty strings occur if there are multiple delimiters in a row.
        // Example: 'First_Field__c,\nAnother_Field__c'
        if (String.isBlank(cleanedDisplayFieldName)) {
          continue;
        }

        LoggerSObjectMetadata.FieldPath fieldPath = new LoggerSObjectMetadata.FieldPath(sourceSObjectType, cleanedDisplayFieldName);
        if (fieldPath.isValid() == false) {
          invalidFieldPathStrings.add(cleanedDisplayFieldName);
        } else {
          cleanedDisplayFieldNames.add(fieldPath.getFormattedFieldPath());
        }
      }

      if (invalidFieldPathStrings.size() > 0) {
        String errorMessageTemplate = 'Unknown field{0} specified: {1}';
        List<String> errorMessageTemplateParameters = new List<String>{
          invalidFieldPathStrings.size() == 1 ? '' : 's',
          String.join(invalidFieldPathStrings, ', ')
        };
        loggerAlertAction.OutputFields__c.addError(String.format(errorMessageTemplate, errorMessageTemplateParameters));
      } else {
        cleanedDisplayFieldNames.sort();
        Set<String> deduplicatedDisplayFieldNames = new Set<String>(cleanedDisplayFieldNames);
        loggerAlertAction.OutputFields__c = String.join(deduplicatedDisplayFieldNames, '\n');
      }
    }
  }

  private static Schema.SObjectType getSObjectType(String sourceSObjectType) {
    switch on sourceSObjectType {
      when 'LogEntryEvent__e' {
        return LogEntryEvent__e.SObjectType;
      }
      when 'Log__c' {
        return Log__c.SObjectType;
      }
      when 'LogEntry__c' {
        return LogEntry__c.SObjectType;
      }
      when 'LogEntryTag__c' {
        return LogEntryTag__c.SObjectType;
      }
      when else {
        throw new System.IllegalArgumentException('Unsupported source SObject type: ' + sourceSObjectType);
      }
    }
  }

  private static Map<String, Schema.SObjectField> getSourceFieldMap(String sourceSObjectType) {
    switch on sourceSObjectType {
      when 'LogEntryEvent__e' {
        return LOG_ENTRY_EVENT_FIELD_NAME_TO_FIELD;
      }
      when 'Log__c' {
        return LOG_FIELD_NAME_TO_FIELD;
      }
      when 'LogEntry__c' {
        return LOG_ENTRY_FIELD_NAME_TO_FIELD;
      }
      when 'LogEntryTag__c' {
        return LOG_ENTRY_TAG_FIELD_NAME_TO_FIELD;
      }
      when else {
        throw new System.IllegalArgumentException('Unsupported source SObject type: ' + sourceSObjectType);
      }
    }
  }
}
