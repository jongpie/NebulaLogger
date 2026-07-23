//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Delivers a `LoggerNotifierRequest` to Slack. The `LoggerNotificationRecipient__c` referenced
 *              by the rule provides either a `WebhookUrl__c` (Incoming Webhooks) or a
 *              `NamedCredentialDeveloperName__c` plus optional `ChannelIdentifier__c` (Web API via
 *              `chat.postMessage`).
 *
 *              Which record fields render on each attachment is controlled by the recipient's
 *              `ConfigurationJson__c.sourceFields`. Bare strings render the field's value with
 *              its describe-provided label. Object entries `{field, displayField?, displayLabel?}` let
 *              admins override the value or the label independently. `Name` fields and lookup (REFERENCE)
 *              fields are automatically rendered as Slack mrkdwn links pointing at the underlying record;
 *              REFERENCE fields fall back to the target's `Name` for display when `displayField` is not set.
 *
 *              Null / blank field values are suppressed by default so attachments only carry data that
 *              was actually populated on the source record. Setting `includeNullValues: true` on the
 *              recipient's `ConfigurationJson__c` renders them as the mrkdwn placeholder
 *              `` `(null/no value)` `` so admins can still see which fields were empty at match time.
 */
public without sharing class SlackLoggerNotifier extends LoggerNotifier {
  private static final String NOTIFICATION_COLOR_RED = '#FF7373';
  private static final String NOTIFICATION_COLOR_ORANGE = '#FFC873';
  private static final String NOTIFICATION_COLOR_GREEN = '#7CD197';
  private static final String NOTIFICATION_COLOR_BLUE = '#7C8CD1';

  // Apex HttpRequest offers no getHeaderKeys(), so the notifier hands the runtime the names of every
  // header it set. Content-Type is the only header this notifier sets today.
  private static final List<String> KNOWN_REQUEST_HEADERS = new List<String>{ 'Content-Type' };

  // Per-SObject default sourceFields used when a recipient's ConfigurationJson__c does not specify its
  // own list. Keys are the source SObject's unqualified API name (matching how rules store
  // SourceSObjectType__c and how SuggestedConfigurationJson__c is keyed). The '*' key is the fallback
  // for any SObject not spelled out - it renders the record's Name only, which every LoggerNotifier
  // source type has.
  private static final Map<String, List<String>> DEFAULT_SOURCE_FIELDS_BY_SOBJECT = new Map<String, List<String>>{
    Schema.LogEntry__c.SObjectType.toString() => new List<String>{
      'Log__r.LoggedBy__c',
      'LoggingLevel__c',
      'Origin__c',
      'Message__c',
      'StackTrace__c',
      'ExceptionType__c'
    },
    Schema.Log__c.SObjectType.toString() => new List<String>{
      'Name',
      'LoggedBy__c',
      'TransactionId__c',
      'TotalERRORLogEntries__c',
      'TotalWARNLogEntries__c',
      'StartTime__c',
      'EndTime__c'
    },
    '*' => new List<String>{ 'Name' }
  };

  private static final String NULL_VALUE_PLACEHOLDER = '`(null/no value)`';

  // Slack's legacy-attachment field-value ceiling is ~2000 characters; the buffer leaves room for the
  // triple-backtick wrapping on wide values and the abbreviate() ellipsis without tripping the truncation.
  private static final Integer MAX_RENDERED_FIELD_LENGTH = 1990;

  /**
   * @description Called by `LoggerNotificationAsyncDispatcher` in an async, callout-legal context.
   * @param request The rule + recipient + service + matching records to deliver.
   */
  public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
    if (request == null || request.recipient == null || request.matchingRecords == null || request.matchingRecords.isEmpty()) {
      return null;
    }
    System.HttpRequest httpRequest = this.buildRequest(request);
    if (httpRequest == null) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('SlackLoggerNotifier - service has neither Webhook URL nor Named Credential; skipping delivery');
      }
      LoggerNotifierResult skipped = new LoggerNotifierResult();
      skipped.status = LoggerNotifierResult.STATUS_SKIPPED;
      skipped.errorMessage = 'Service has neither Webhook URL nor Named Credential configured';
      return skipped;
    }
    httpRequest.setBody(this.buildPayload(request));
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('SlackLoggerNotifier - sending payload').setHttpRequestDetails(httpRequest);
    }
    System.HttpResponse response;
    try {
      response = new System.Http().send(httpRequest);
    } catch (System.CalloutException ex) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.error('SlackLoggerNotifier - callout failed', ex);
      }
      LoggerNotifierResult failed = new LoggerNotifierResult();
      failed.status = LoggerNotifierResult.STATUS_FAILED;
      failed.errorMessage = ex.getMessage();
      failed.errorStackTrace = ex.getStackTraceString();
      failed.requestUrl = httpRequest.getEndpoint();
      failed.requestMethod = httpRequest.getMethod();
      failed.requestBody = httpRequest.getBody();
      // Named-credential-access errors surface a specific message so admins can jump straight to the
      // right fix (permset assignment on the async-execution user) rather than chasing the notifier.
      if (ex.getMessage() != null && ex.getMessage().contains('external credential')) {
        failed.errorMessage =
          ex.getMessage() +
          ' | Nebula Logger dispatches Slack notifications from a Queueable that runs as the enqueueing user, which is typically the Automated Process user for platform-event-triggered flows. Assign the LoggerNotificationsPluginAdmin permission set (or a permission set with the ExternalCredentialPrincipal access) to the Automated Process user, OR route dispatches through a user that already has the permset.';
      }
      return failed;
    }
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('SlackLoggerNotifier - response received').setHttpResponseDetails(response);
    }
    LoggerNotifierResult result = new LoggerNotifierResult(httpRequest, response, KNOWN_REQUEST_HEADERS);
    interpretSlackResponse(response, result);
    return result;
  }

  /**
   * @description Web-API-mode Slack responses come back as HTTP 200 with a JSON body carrying an `ok` flag,
   *              a `ts` message identifier, and the `channel` the message landed in. The default HTTP
   *              status treatment in `fromHttpResponse` maps 200 to Delivered, but Slack routinely 200s
   *              with `{"ok":false, "error":"..."}` for logical failures (invalid channel, bad token,
   *              scope missing) - so we override the status when `ok` is false, and on true we capture
   *              `ts` as the external reference id and build a Slack app-redirect deep link. Webhook-mode
   *              responses (just the plaintext string `ok`) are skipped because they carry no useful data.
   */
  private static void interpretSlackResponse(System.HttpResponse response, LoggerNotifierResult result) {
    if (response == null || result == null) {
      return;
    }
    String body = response.getBody();
    if (String.isBlank(body) || body.startsWith('{') == false) {
      return;
    }
    ChatPostMessageResponse parsed;
    try {
      parsed = (ChatPostMessageResponse) System.JSON.deserialize(body, ChatPostMessageResponse.class);
    } catch (System.JSONException ex) {
      return;
    }
    if (parsed == null || parsed.ok == null) {
      return;
    }
    if (parsed.ok == false) {
      result.status = LoggerNotifierResult.STATUS_FAILED;
      if (String.isNotBlank(parsed.error)) {
        result.errorMessage = 'Slack error: ' + parsed.error;
      }
      return;
    }
    if (String.isNotBlank(parsed.ts)) {
      result.externalReferenceId = parsed.ts;
      if (String.isNotBlank(parsed.channel)) {
        result.externalReferenceUrl = 'https://slack.com/app_redirect?channel=' + parsed.channel + '&message_ts=' + parsed.ts;
      }
    }
  }

  private System.HttpRequest buildRequest(LoggerNotifierRequest request) {
    String endpoint;
    if (String.isNotBlank(request.recipient.LoggerNotificationService__r.NamedCredentialDeveloperName__c)) {
      // Web API mode: callout: named credential + chat.postMessage path
      endpoint = 'callout:' + request.recipient.LoggerNotificationService__r.NamedCredentialDeveloperName__c + '/chat.postMessage';
    } else if (String.isNotBlank(request.recipient.LoggerNotificationService__r.WebhookUrl__c)) {
      endpoint = request.recipient.LoggerNotificationService__r.WebhookUrl__c;
    } else {
      return null;
    }
    System.HttpRequest httpRequest = new System.HttpRequest();
    httpRequest.setEndpoint(endpoint);
    httpRequest.setMethod('POST');
    httpRequest.setHeader('Content-Type', 'application/json');
    return httpRequest;
  }

  private String buildPayload(LoggerNotifierRequest request) {
    NotificationDto notification = new NotificationDto();
    // Top-level text is Slack's summary line above the attachments. It uses <url|text> mrkdwn syntax
    // automatically (no opt-in flag needed at this level), so linkifying the rule name here Just Works.
    notification.text = 'Nebula Logger notification for ' + this.buildRuleLink(request.recipient.LoggerNotificationRule__r);
    if (
      String.isNotBlank(request.recipient.ChannelIdentifier__c) &&
      String.isNotBlank(request.recipient.LoggerNotificationService__r.NamedCredentialDeveloperName__c)
    ) {
      // Only the Web API mode uses the channel field on the payload; webhooks are pre-scoped to a channel
      notification.channel = request.recipient.ChannelIdentifier__c;
    }
    Schema.SObjectType sourceSObjectType = request.matchingRecords.get(0).getSObjectType();
    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields = request.configuration.getSourceFields();
    if (sourceFields == null) {
      sourceFields = LoggerNotifier.buildDefaultSourceFields(getDefaultSourceFields(sourceSObjectType));
    }
    Boolean includeNullValues = request.configuration.getBoolean('includeNullValues', false);
    // Compute every schema path we'll need to resolve values against - the primary field, any overridden
    // display field, and (for REFERENCE-typed primaries with no display override) the parent record's Name.
    Set<String> fieldPathsToRequery = LoggerNotifier.collectFieldPathsToRequery(sourceFields, sourceSObjectType);
    List<SObject> requeriedRecords = LoggerNotifier.requeryRecordsWithFieldPaths(request.matchingRecords, fieldPathsToRequery);
    notification.attachments = new List<AttachmentDto>();
    for (SObject record : requeriedRecords) {
      notification.attachments.add(this.buildAttachment(record, sourceFields, includeNullValues));
    }
    // 'short' is a reserved word in Apex, so it's serialized as `isShort` here and swapped in the JSON string
    return System.JSON.serialize(notification, true).replace('"isShort"', '"short"');
  }

  private AttachmentDto buildAttachment(SObject record, List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields, Boolean includeNullValues) {
    AttachmentDto attachment = new AttachmentDto();
    attachment.color = this.getColorForRecord(record);
    attachment.title = this.getRecordTitle(record);
    attachment.title_link = this.getRecordLink(record);
    // Slack renders <url|text> mrkdwn links inside field values only when the attachment opts in via mrkdwn_in.
    attachment.mrkdwn_in = new List<String>{ 'fields' };
    attachment.fields = new List<FieldDto>();

    for (LoggerNotifierConfiguration.SourceFieldDefinition definition : sourceFields) {
      FieldDto renderedField = this.renderField(record, definition, includeNullValues);
      if (renderedField != null) {
        attachment.fields.add(renderedField);
      }
    }
    return attachment;
  }

  private String buildRuleLink(LoggerNotificationRule__c rule) {
    if (rule == null || rule.Id == null) {
      return rule?.Name;
    }
    String ruleLink = System.URL.getOrgDomainUrl().toExternalForm() + '/' + rule.Id;
    return '<' + ruleLink + '|' + rule.Name + '>';
  }

  private FieldDto renderField(SObject record, LoggerNotifierConfiguration.SourceFieldDefinition definition, Boolean includeNullValues) {
    Schema.DescribeFieldResult primaryDescribe = LoggerNotifier.getDescribeByPath(record.getSObjectType(), definition.sourceField);
    if (primaryDescribe == null) {
      return null;
    }
    // Resolve the display value: explicit displayField > REFERENCE parent Name fallback > primary value.
    String valuePath = String.isNotBlank(definition.displayField)
      ? definition.displayField
      : (primaryDescribe.getType() == Schema.DisplayType.REFERENCE
          ? LoggerNotifier.deriveParentNamePath(definition.sourceField, record.getSObjectType())
          : definition.sourceField);
    if (valuePath == null) {
      valuePath = definition.sourceField;
    }
    Object rawValue = LoggerNotifier.getValueByPath(record, valuePath);
    Boolean isWide = primaryDescribe.getType() == Schema.DisplayType.TEXTAREA;
    String label = String.isNotBlank(definition.displayLabel) ? definition.displayLabel : primaryDescribe.getLabel();
    if (rawValue == null || String.isBlank(String.valueOf(rawValue))) {
      if (includeNullValues == false) {
        return null;
      }
      return new FieldDto(label, NULL_VALUE_PLACEHOLDER, isWide == false);
    }
    // Slack's per-field ceiling is a hard limit; admin-configured maxLength clamps within that ceiling.
    // `abbreviate` requires a minimum width of 4 to fit the ellipsis, so any smaller admin value is
    // rounded up to 4 rather than blowing up the render.
    Integer effectiveMaxLength = definition.maxLength == null
      ? MAX_RENDERED_FIELD_LENGTH
      : Math.max(4, Math.min(definition.maxLength, MAX_RENDERED_FIELD_LENGTH));
    String stringValue = String.valueOf(rawValue).abbreviate(effectiveMaxLength);
    String renderedValue = isWide ? '```' + stringValue + '```' : '`' + stringValue + '`';
    // Slack's `<url|text>` mrkdwn wrapping only kicks in when the primary field points at a specific record
    // (a Name on the source record, a parent Name via `.Name`, or a REFERENCE lookup). Everything else stays
    // as plain rendered text.
    Id linkTarget = LoggerNotifier.resolveLinkTarget(record, definition.sourceField, primaryDescribe);
    return new FieldDto(label, wrapAsLink(linkTarget, renderedValue), isWide == false);
  }

  private static String wrapAsLink(Id linkTarget, String renderedValue) {
    if (linkTarget == null) {
      return renderedValue;
    }
    return '<' + System.URL.getOrgDomainUrl().toExternalForm() + '/' + linkTarget + '|' + renderedValue + '>';
  }

  private static List<String> getDefaultSourceFields(Schema.SObjectType sourceSObjectType) {
    if (sourceSObjectType != null) {
      List<String> match = DEFAULT_SOURCE_FIELDS_BY_SOBJECT.get(sourceSObjectType.toString());
      if (match != null) {
        return match;
      }
    }
    return DEFAULT_SOURCE_FIELDS_BY_SOBJECT.get('*');
  }

  private String getColorForRecord(SObject record) {
    String color;

    switch on record {
      when Log__c log {
        if (log.TotalERRORLogEntries__c > 0) {
          color = NOTIFICATION_COLOR_RED;
        } else if (log.TotalWARNLogEntries__c > 0) {
          color = NOTIFICATION_COLOR_RED;
        } else {
          color = NOTIFICATION_COLOR_GREEN;
        }
      }
      when LogEntry__c logEntry {
        if (logEntry.LoggingLevel__c == System.LoggingLevel.ERROR.name()) {
          color = NOTIFICATION_COLOR_RED;
        } else if (logEntry.LoggingLevel__c == System.LoggingLevel.WARN.name()) {
          color = NOTIFICATION_COLOR_ORANGE;
        } else {
          color = NOTIFICATION_COLOR_GREEN;
        }
      }
    }

    return color ?? NOTIFICATION_COLOR_BLUE;
  }

  private String getRecordTitle(SObject record) {
    String sobjectLabel = record.getSObjectType().getDescribe().getLabel();
    String recordName = ((String) record.get('Name')) ?? '';

    return (sobjectLabel + ' ' + recordName).trim();
  }

  private String getRecordLink(SObject record) {
    if (record?.Id == null) {
      return null;
    }
    return System.URL.getOrgDomainUrl().toExternalForm() + '/' + record.Id;
  }

  // Slack payload DTOs

  private class NotificationDto {
    public String text;
    public String channel;
    public List<AttachmentDto> attachments;
  }

  @SuppressWarnings('PMD.FieldNamingConventions, PMD.VariableNamingConventions')
  private class AttachmentDto {
    public String color;
    public String title;
    public String title_link;
    public List<String> mrkdwn_in;
    public List<FieldDto> fields;
  }

  private class FieldDto {
    public String title;
    public String value;
    public Boolean isShort;

    @SuppressWarnings('PMD.AvoidBooleanMethodParameters')
    public FieldDto(String title, String value, Boolean isShort) {
      this.title = title;
      this.value = value;
      this.isShort = isShort;
    }
  }

  /**
   * @description Typed shape of Slack's `chat.postMessage` response used to extract the message
   *              identifier and channel for external-reference capture on the delivery record. Extra
   *              fields Slack returns (`message`, `warning`, `response_metadata`, etc.) are ignored
   *              by the deserializer.
   */
  private class ChatPostMessageResponse {
    public Boolean ok;
    public String error;
    public String channel;
    public String ts;
  }
}
