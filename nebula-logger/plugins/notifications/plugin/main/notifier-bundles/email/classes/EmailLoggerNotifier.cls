//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Delivers a `LoggerNotifierRequest` to a Salesforce user or email address using
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
public without sharing class EmailLoggerNotifier extends LoggerNotifier {
  // TODO eliminate this, the list of source fields will vary based on rule's SourceSObjectType__c,
  // so definining defaults needs to be sobject-specific.
  // The recipients should provide a list of source fields, so there shouldn't be a need for default fields.
  private static final List<String> DEFAULT_SOURCE_FIELDS = new List<String>{ 'LoggingLevel__c', 'Origin__c', 'Message__c', 'StackTrace__c' };
  private static final String NULL_VALUE_PLACEHOLDER = '(empty)';
  private static final System.Pattern MERGE_TOKEN_PATTERN = System.Pattern.compile('\\{!([^{}]+)\\}');

  /**
   * @description Called by `LoggerNotificationAsyncDispatcher`.
   * @param request The rule + recipient + service + matching records to deliver.
   */
  public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
    if (request == null || request.recipient == null || request.matchingRecords == null || request.matchingRecords.isEmpty()) {
      return null;
    }
    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields = request.configuration.getSourceFields();
    if (sourceFields == null) {
      sourceFields = LoggerNotifier.buildDefaultSourceFields(DEFAULT_SOURCE_FIELDS);
    }
    Boolean includeNullValues = request.configuration.getBoolean('includeNullValues', false);
    String subjectTemplate = request.configuration.getString('subjectTemplate');

    Schema.SObjectType sourceType = request.matchingRecords.get(0).getSObjectType();
    List<String> hydrationPaths = collectHydrationPaths(sourceFields, subjectTemplate, sourceType);
    List<SObject> hydratedRecords = LoggerNotifier.hydrateRecordsWithFieldPaths(request.matchingRecords, hydrationPaths);

    Messaging.SingleEmailMessage email = this.buildEmail(request, hydratedRecords, sourceFields, includeNullValues, subjectTemplate);
    if (email == null) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('EmailLoggerNotifier - recipient has neither User__c nor EmailAddress__c; skipping delivery');
      }
      LoggerNotifierResult skipped = new LoggerNotifierResult();
      skipped.status = LoggerNotifierResult.STATUS_SKIPPED;
      skipped.errorMessage = 'Recipient has neither User__c nor EmailAddress__c configured';
      return skipped;
    }
    List<Messaging.SendEmailResult> results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email }, false);
    LoggerNotifierResult outcome = new LoggerNotifierResult();
    outcome.status = LoggerNotifierResult.STATUS_DELIVERED;
    List<String> errors = new List<String>();
    for (Messaging.SendEmailResult result : results) {
      if (result.isSuccess() == false) {
        outcome.status = LoggerNotifierResult.STATUS_FAILED;
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
    return outcome;
  }

  @SuppressWarnings('PMD.ExcessiveParameterList')
  @TestVisible
  private Messaging.SingleEmailMessage buildEmail(
    LoggerNotifierRequest request,
    List<SObject> hydratedRecords,
    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields,
    Boolean includeNullValues,
    String subjectTemplate
  ) {
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    Boolean targeted = false;
    if (request.recipient.User__c != null) {
      email.setTargetObjectId(request.recipient.User__c);
      email.setSaveAsActivity(false);
      targeted = true;
    } else if (String.isNotBlank(request.recipient.EmailAddress__c)) {
      email.setToAddresses(new List<String>{ request.recipient.EmailAddress__c });
      targeted = true;
    }
    if (targeted == false) {
      return null;
    }
    email.setSubject(this.buildSubject(request, hydratedRecords, subjectTemplate));
    email.setPlainTextBody(this.buildBody(request, hydratedRecords, sourceFields, includeNullValues));
    return email;
  }

  private String buildSubject(LoggerNotifierRequest request, List<SObject> hydratedRecords, String subjectTemplate) {
    if (String.isNotBlank(subjectTemplate)) {
      String rendered = renderSubjectTemplate(subjectTemplate, request, hydratedRecords);
      if (String.isNotBlank(rendered)) {
        return rendered;
      }
    }
    Integer matchCount = request.matchingRecords.size();
    String recordLabel = matchCount == 1 ? 'record' : 'records';
    return 'Nebula Logger: ' + matchCount + ' ' + recordLabel + ' matched ' + request.recipient.LoggerNotificationRule__r.Name;
  }

  private static String renderSubjectTemplate(String template, LoggerNotifierRequest request, List<SObject> hydratedRecords) {
    SObject firstRecord = hydratedRecords.isEmpty() ? null : hydratedRecords.get(0);
    System.Matcher matcher = MERGE_TOKEN_PATTERN.matcher(template);
    List<String> segments = new List<String>();
    Integer cursor = 0;
    while (matcher.find()) {
      segments.add(template.substring(cursor, matcher.start()));
      String tokenName = matcher.group(1).trim();
      segments.add(resolveSubjectToken(tokenName, request, firstRecord));
      cursor = matcher.end();
    }
    segments.add(template.substring(cursor));
    return String.join(segments, '');
  }

  private static String resolveSubjectToken(String tokenName, LoggerNotifierRequest request, SObject firstRecord) {
    if (String.isBlank(tokenName)) {
      return '';
    }
    if (tokenName.equalsIgnoreCase('ruleName')) {
      return request.recipient.LoggerNotificationRule__r == null ||
        request.recipient.LoggerNotificationRule__r.Name == null
        ? ''
        : request.recipient.LoggerNotificationRule__r.Name;
    }
    if (tokenName.equalsIgnoreCase('matchCount')) {
      return String.valueOf(request.matchingRecords.size());
    }
    if (firstRecord == null) {
      return '';
    }
    Object value = LoggerNotifier.getValueByPath(firstRecord, tokenName);
    return value == null ? '' : String.valueOf(value);
  }

  @SuppressWarnings('PMD.ExcessiveParameterList')
  private String buildBody(
    LoggerNotifierRequest request,
    List<SObject> hydratedRecords,
    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields,
    Boolean includeNullValues
  ) {
    List<String> lines = new List<String>();
    lines.add('Rule: ' + request.recipient.LoggerNotificationRule__r.Name);
    if (String.isNotBlank(request.recipient.LoggerNotificationRule__r.SourceSObjectFilter__c)) {
      lines.add('Filter: ' + request.recipient.LoggerNotificationRule__r.SourceSObjectFilter__c);
    }
    lines.add('Matching records: ' + request.matchingRecords.size());
    lines.add('');
    Schema.SObjectType sourceType = hydratedRecords.get(0).getSObjectType();
    Integer index = 1;
    for (SObject record : hydratedRecords) {
      lines.add('--- Record ' + index + ' ---');
      for (LoggerNotifierConfiguration.SourceFieldDefinition definition : sourceFields) {
        String renderedField = renderField(record, sourceType, definition, includeNullValues);
        if (renderedField != null) {
          lines.add(renderedField);
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

  @SuppressWarnings('PMD.ExcessiveParameterList')
  private static String renderField(
    SObject record,
    Schema.SObjectType sourceType,
    LoggerNotifierConfiguration.SourceFieldDefinition definition,
    Boolean includeNullValues
  ) {
    Schema.DescribeFieldResult primaryDescribe = LoggerNotifier.getDescribeByPath(sourceType, definition.sourceField);
    if (primaryDescribe == null) {
      return null;
    }
    String valuePath = String.isNotBlank(definition.displayField) ? definition.displayField : definition.sourceField;
    Object rawValue = LoggerNotifier.getValueByPath(record, valuePath);
    String label = String.isNotBlank(definition.displayLabel) ? definition.displayLabel : primaryDescribe.getLabel();
    if (rawValue == null || String.isBlank(String.valueOf(rawValue))) {
      if (includeNullValues == false) {
        return null;
      }
      return label + ': ' + NULL_VALUE_PLACEHOLDER;
    }
    return label + ': ' + String.valueOf(rawValue);
  }

  private static List<String> collectHydrationPaths(
    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields,
    String subjectTemplate,
    Schema.SObjectType sourceType
  ) {
    Set<String> pathSet = new Set<String>();
    for (LoggerNotifierConfiguration.SourceFieldDefinition definition : sourceFields) {
      if (String.isNotBlank(definition.sourceField)) {
        pathSet.add(definition.sourceField);
      }
      if (String.isNotBlank(definition.displayField)) {
        pathSet.add(definition.displayField);
      }
    }
    if (String.isNotBlank(subjectTemplate)) {
      System.Matcher matcher = MERGE_TOKEN_PATTERN.matcher(subjectTemplate);
      while (matcher.find()) {
        String tokenName = matcher.group(1).trim();
        if (tokenName.equalsIgnoreCase('ruleName') || tokenName.equalsIgnoreCase('matchCount')) {
          continue;
        }
        if (LoggerNotifier.getDescribeByPath(sourceType, tokenName) != null) {
          pathSet.add(tokenName);
        }
      }
    }
    List<String> paths = new List<String>(pathSet);
    return paths;
  }
}
