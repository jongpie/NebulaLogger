//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Delivers a `LoggerNotifiableContext` to a Salesforce user or email address using
 *              `Messaging.SingleEmailMessage`. The recipient's `User__c` and/or
 *              `EmailAddress__c` fields determine the target.
 *
 *              Which record fields render in the body is controlled by the recipient's
 *              `ConfigurationJson__c.sourceFields` (same shape as the Slack notifier). Bare strings
 *              render the field's value with its describe-provided label. Object entries
 *              `{field, displayField?, displayLabel?}` let admins override the value or the label
 *              independently. Blank / null values are suppressed by default; set
 *              `includeNullValues: true` to render an `(empty)` placeholder instead.
 *
 *              The subject line can be customized via `ConfigurationJson__c.subjectTemplate`. Merge
 *              tokens are wrapped in `{!...}`:
 *                - `{!ruleName}` - the matching rule's Name
 *                - `{!matchCount}` - the number of matching records
 *                - `{!<FieldApiName>}` / `{!Parent__r.Field__c}` - the field's value on the first
 *                  matching record (dotted paths supported for parent lookups)
 *              Unknown tokens resolve to an empty string. A blank / all-blank template falls back
 *              to the default subject.
 */
public without sharing class EmailLoggerNotifier implements LoggerNotifiable {
  private static final List<String> DEFAULT_SOURCE_FIELDS = new List<String>{ 'LoggingLevel__c', 'Origin__c', 'Message__c', 'StackTrace__c' };
  private static final String NULL_VALUE_PLACEHOLDER = '(empty)';
  private static final System.Pattern MERGE_TOKEN_PATTERN = System.Pattern.compile('\\{!([^{}]+)\\}');

  /**
   * @description Called by `LoggerNotifierAsyncDispatcher`.
   * @param context The rule + recipient + service + matching records to deliver.
   */
  public LoggerNotifiableResult sendNotification(LoggerNotifiableContext context) {
    if (context == null || context.recipient == null || context.matchingRecords == null || context.matchingRecords.isEmpty()) {
      return null;
    }
    List<LoggerNotifiableConfiguration.SourceFieldSpec> specs = context.config.getSourceFieldSpecs();
    if (specs == null) {
      specs = buildDefaultSpecs();
    }
    Boolean includeNullValues = context.config.getBoolean('includeNullValues', false);
    String subjectTemplate = context.config.getString('subjectTemplate');

    Schema.SObjectType sourceType = context.matchingRecords.get(0).getSObjectType();
    List<String> hydrationPaths = collectHydrationPaths(specs, subjectTemplate, sourceType);
    List<SObject> hydratedRecords = hydrateRecordsWithFieldPaths(context.matchingRecords, hydrationPaths);

    Messaging.SingleEmailMessage email = this.buildEmail(context, hydratedRecords, specs, includeNullValues, subjectTemplate);
    if (email == null) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('EmailLoggerNotifier - recipient has neither User__c nor EmailAddress__c; skipping delivery');
      }
      LoggerNotifiableResult skipped = new LoggerNotifiableResult();
      skipped.status = LoggerNotifiableResult.STATUS_SKIPPED;
      skipped.errorMessage = 'Recipient has neither User__c nor EmailAddress__c configured';
      return skipped;
    }
    List<Messaging.SendEmailResult> results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email }, false);
    LoggerNotifiableResult outcome = new LoggerNotifiableResult();
    outcome.status = LoggerNotifiableResult.STATUS_DELIVERED;
    List<String> errors = new List<String>();
    for (Messaging.SendEmailResult result : results) {
      if (result.isSuccess() == false) {
        outcome.status = LoggerNotifiableResult.STATUS_FAILED;
        for (Messaging.SendEmailError err : result.getErrors()) {
          errors.add(err.getMessage());
        }
        if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
          Logger.warn('EmailLoggerNotifier - send failed: ' + Messaging.SingleEmailMessage.class.getName() + ' -> ' + result.getErrors());
        }
      }
    }
    if (errors.isEmpty() == false) {
      outcome.errorMessage = String.join(errors, '\n');
    }
    // See Backlog.md: notifier-side Logger.saveLog() re-fires the notifications plugin trigger; commented out for now.
    // Logger.saveLog();
    return outcome;
  }

  @TestVisible
  private Messaging.SingleEmailMessage buildEmail(
    LoggerNotifiableContext context,
    List<SObject> hydratedRecords,
    List<LoggerNotifiableConfiguration.SourceFieldSpec> specs,
    Boolean includeNullValues,
    String subjectTemplate
  ) {
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    Boolean targeted = false;
    if (context.recipient.User__c != null) {
      email.setTargetObjectId(context.recipient.User__c);
      email.setSaveAsActivity(false);
      targeted = true;
    } else if (String.isNotBlank(context.recipient.EmailAddress__c)) {
      email.setToAddresses(new List<String>{ context.recipient.EmailAddress__c });
      targeted = true;
    }
    if (targeted == false) {
      return null;
    }
    email.setSubject(this.buildSubject(context, hydratedRecords, subjectTemplate));
    email.setPlainTextBody(this.buildBody(context, hydratedRecords, specs, includeNullValues));
    return email;
  }

  private String buildSubject(LoggerNotifiableContext context, List<SObject> hydratedRecords, String subjectTemplate) {
    if (String.isNotBlank(subjectTemplate)) {
      String rendered = renderSubjectTemplate(subjectTemplate, context, hydratedRecords);
      if (String.isNotBlank(rendered)) {
        return rendered;
      }
    }
    Integer matchCount = context.matchingRecords.size();
    String recordLabel = matchCount == 1 ? 'log record' : 'log records';
    return 'Nebula Logger: ' + matchCount + ' ' + recordLabel + ' matched ' + context.notificationRule.Name;
  }

  private static String renderSubjectTemplate(String template, LoggerNotifiableContext context, List<SObject> hydratedRecords) {
    SObject firstRecord = hydratedRecords.isEmpty() ? null : hydratedRecords.get(0);
    System.Matcher matcher = MERGE_TOKEN_PATTERN.matcher(template);
    List<String> segments = new List<String>();
    Integer cursor = 0;
    while (matcher.find()) {
      segments.add(template.substring(cursor, matcher.start()));
      String tokenName = matcher.group(1).trim();
      segments.add(resolveSubjectToken(tokenName, context, firstRecord));
      cursor = matcher.end();
    }
    segments.add(template.substring(cursor));
    return String.join(segments, '');
  }

  private static String resolveSubjectToken(String tokenName, LoggerNotifiableContext context, SObject firstRecord) {
    if (String.isBlank(tokenName)) {
      return '';
    }
    if (tokenName.equalsIgnoreCase('ruleName')) {
      return context.notificationRule == null || context.notificationRule.Name == null ? '' : context.notificationRule.Name;
    }
    if (tokenName.equalsIgnoreCase('matchCount')) {
      return String.valueOf(context.matchingRecords.size());
    }
    if (firstRecord == null) {
      return '';
    }
    Object value = getValueByPath(firstRecord, tokenName);
    return value == null ? '' : String.valueOf(value);
  }

  private String buildBody(
    LoggerNotifiableContext context,
    List<SObject> hydratedRecords,
    List<LoggerNotifiableConfiguration.SourceFieldSpec> specs,
    Boolean includeNullValues
  ) {
    List<String> lines = new List<String>();
    lines.add('Rule: ' + context.notificationRule.Name);
    if (String.isNotBlank(context.notificationRule.SourceSObjectFilter__c)) {
      lines.add('Filter: ' + context.notificationRule.SourceSObjectFilter__c);
    }
    lines.add('Matching records: ' + context.matchingRecords.size());
    lines.add('');
    Schema.SObjectType sourceType = hydratedRecords.get(0).getSObjectType();
    Integer index = 1;
    for (SObject record : hydratedRecords) {
      lines.add('--- Record ' + index + ' ---');
      for (LoggerNotifiableConfiguration.SourceFieldSpec spec : specs) {
        String rendered = renderField(record, sourceType, spec, includeNullValues);
        if (rendered != null) {
          lines.add(rendered);
        }
      }
      Id recordId = (Id) record.get('Id');
      if (recordId != null) {
        lines.add('Record link: ' + System.URL.getOrgDomainUrl().toExternalForm() + '/' + recordId);
      }
      lines.add('');
      index++;
    }
    return String.join(lines, '\n');
  }

  private static String renderField(
    SObject record,
    Schema.SObjectType sourceType,
    LoggerNotifiableConfiguration.SourceFieldSpec spec,
    Boolean includeNullValues
  ) {
    Schema.DescribeFieldResult primaryDescribe = getDescribeByPath(sourceType, spec.field);
    if (primaryDescribe == null) {
      return null;
    }
    String valuePath = String.isNotBlank(spec.displayField) ? spec.displayField : spec.field;
    Object rawValue = getValueByPath(record, valuePath);
    String label = String.isNotBlank(spec.displayLabel) ? spec.displayLabel : primaryDescribe.getLabel();
    if (rawValue == null || String.isBlank(String.valueOf(rawValue))) {
      if (includeNullValues == false) {
        return null;
      }
      return label + ': ' + NULL_VALUE_PLACEHOLDER;
    }
    return label + ': ' + String.valueOf(rawValue);
  }

  private static List<LoggerNotifiableConfiguration.SourceFieldSpec> buildDefaultSpecs() {
    List<LoggerNotifiableConfiguration.SourceFieldSpec> defaults = new List<LoggerNotifiableConfiguration.SourceFieldSpec>();
    for (String fieldName : DEFAULT_SOURCE_FIELDS) {
      defaults.add(new LoggerNotifiableConfiguration.SourceFieldSpec(fieldName, null, null));
    }
    return defaults;
  }

  private static List<String> collectHydrationPaths(
    List<LoggerNotifiableConfiguration.SourceFieldSpec> specs,
    String subjectTemplate,
    Schema.SObjectType sourceType
  ) {
    Set<String> pathSet = new Set<String>();
    for (LoggerNotifiableConfiguration.SourceFieldSpec spec : specs) {
      if (String.isNotBlank(spec.field)) {
        pathSet.add(spec.field);
      }
      if (String.isNotBlank(spec.displayField)) {
        pathSet.add(spec.displayField);
      }
    }
    if (String.isNotBlank(subjectTemplate)) {
      System.Matcher matcher = MERGE_TOKEN_PATTERN.matcher(subjectTemplate);
      while (matcher.find()) {
        String tokenName = matcher.group(1).trim();
        if (tokenName.equalsIgnoreCase('ruleName') || tokenName.equalsIgnoreCase('matchCount')) {
          continue;
        }
        if (getDescribeByPath(sourceType, tokenName) != null) {
          pathSet.add(tokenName);
        }
      }
    }
    List<String> paths = new List<String>(pathSet);
    return paths;
  }

  private static Object getValueByPath(SObject record, String fieldPath) {
    if (record == null || String.isBlank(fieldPath)) {
      return null;
    }
    List<String> parts = fieldPath.split('\\.');
    SObject current = record;
    for (Integer i = 0; i < parts.size() - 1; i++) {
      if (current == null) {
        return null;
      }
      try {
        current = current.getSObject(parts.get(i));
      } catch (System.SObjectException ex) {
        return null;
      }
    }
    if (current == null) {
      return null;
    }
    try {
      return current.get(parts.get(parts.size() - 1));
    } catch (System.SObjectException ex) {
      return null;
    }
  }

  private static Schema.DescribeFieldResult getDescribeByPath(Schema.SObjectType startType, String fieldPath) {
    if (startType == null || String.isBlank(fieldPath)) {
      return null;
    }
    List<String> parts = fieldPath.split('\\.');
    Schema.SObjectType currentType = startType;
    for (Integer i = 0; i < parts.size() - 1; i++) {
      Schema.SObjectType nextType = getRelatedType(currentType, parts.get(i));
      if (nextType == null) {
        return null;
      }
      currentType = nextType;
    }
    Schema.SObjectField finalToken = currentType.getDescribe().fields.getMap().get(parts.get(parts.size() - 1).toLowerCase());
    return finalToken == null ? null : finalToken.getDescribe();
  }

  private static Schema.SObjectType getRelatedType(Schema.SObjectType currentType, String relationshipSegment) {
    for (Schema.SObjectField field : currentType.getDescribe().fields.getMap().values()) {
      Schema.DescribeFieldResult describe = field.getDescribe();
      if (relationshipSegment.equalsIgnoreCase(describe.getRelationshipName())) {
        List<Schema.SObjectType> refs = describe.getReferenceTo();
        if (refs.isEmpty() == false) {
          return refs.get(0);
        }
      }
    }
    return null;
  }

  private static List<SObject> hydrateRecordsWithFieldPaths(List<SObject> records, List<String> fieldPaths) {
    if (records == null || records.isEmpty() || fieldPaths == null || fieldPaths.isEmpty()) {
      return records;
    }
    Boolean anyDottedPath = false;
    for (String path : fieldPaths) {
      if (path != null && path.contains('.')) {
        anyDottedPath = true;
        break;
      }
    }
    if (anyDottedPath == false) {
      return records;
    }
    Map<Schema.SObjectType, Set<Id>> idsByType = new Map<Schema.SObjectType, Set<Id>>();
    for (SObject record : records) {
      Id recordId = (Id) record.get('Id');
      if (recordId == null) {
        continue;
      }
      Schema.SObjectType type = record.getSObjectType();
      if (idsByType.containsKey(type) == false) {
        idsByType.put(type, new Set<Id>());
      }
      idsByType.get(type).add(recordId);
    }
    if (idsByType.isEmpty()) {
      return records;
    }
    Map<Id, SObject> hydratedById = new Map<Id, SObject>();
    for (Schema.SObjectType type : idsByType.keySet()) {
      Set<Id> ids = idsByType.get(type);
      Map<String, Schema.SObjectField> fieldMap = type.getDescribe().fields.getMap();
      Set<String> selectFieldSet = new Set<String>{ 'Id' };
      if (fieldMap.containsKey('name')) {
        selectFieldSet.add('Name');
      }
      selectFieldSet.addAll(fieldPaths);
      String query = 'SELECT ' + String.join(new List<String>(selectFieldSet), ', ') + ' FROM ' + type.getDescribe().getName() + ' WHERE Id IN :ids';
      try {
        for (SObject queried : System.Database.query(query)) {
          hydratedById.put((Id) queried.get('Id'), queried);
        }
      } catch (System.QueryException ex) {
        if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
          Logger.warn('EmailLoggerNotifier - could not hydrate records for field paths ' + fieldPaths + ': ' + ex.getMessage());
        }
      }
    }
    List<SObject> result = new List<SObject>();
    for (SObject record : records) {
      Id recordId = (Id) record.get('Id');
      SObject hydrated = recordId == null ? null : hydratedById.get(recordId);
      result.add(hydrated != null ? hydrated : record);
    }
    return result;
  }
}
