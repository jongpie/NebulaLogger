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

  // Apex HttpRequest offers no getHeaderKeys(), so the notifier hands the runtime the names of every
  // header it set. Content-Type is the only header this notifier sets today.
  private static final List<String> KNOWN_REQUEST_HEADERS = new List<String>{ 'Content-Type' };

  private static final List<String> DEFAULT_SOURCE_FIELDS = new List<String>{
    'LoggingLevel__c',
    'Origin__c',
    'Message__c',
    'StackTrace__c',
    'ExceptionType__c'
  };

  private static final String NULL_VALUE_PLACEHOLDER = '`(null/no value)`';

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
      // TODO: notifiers currently log via Nebula Logger for diagnostics, which can re-trigger the
      // notifications plugin when the resulting LogEntry__c rows match another rule (or the same one).
      // Commented out for now; see Backlog.md for the discussion on removing all Logger.* calls from
      // notifier bundles.
      // Logger.saveLog();
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
    // See Backlog.md: notifier-side Logger.saveLog() re-fires the notifications plugin trigger; commented out for now.
    // Logger.saveLog();
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
    if (String.isNotBlank(request.service.NamedCredentialDeveloperName__c)) {
      // Web API mode: callout: named credential + chat.postMessage path
      endpoint = 'callout:' + request.service.NamedCredentialDeveloperName__c + '/chat.postMessage';
    } else if (String.isNotBlank(request.service.WebhookUrl__c)) {
      endpoint = request.service.WebhookUrl__c;
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
    notification.text = 'Nebula Logger notification for ' + this.buildRuleLink(request.notificationRule);
    if (String.isNotBlank(request.recipient.ChannelIdentifier__c) && String.isNotBlank(request.service.NamedCredentialDeveloperName__c)) {
      // Only the Web API mode uses the channel field on the payload; webhooks are pre-scoped to a channel
      notification.channel = request.recipient.ChannelIdentifier__c;
    }
    List<LoggerNotifierConfiguration.SourceFieldSpec> specs = request.configuration.getSourceFieldSpecs();
    if (specs == null) {
      specs = buildDefaultSpecs(DEFAULT_SOURCE_FIELDS);
    }
    Boolean includeNullValues = request.configuration.getBoolean('includeNullValues', false);
    Schema.SObjectType sourceType = request.matchingRecords.get(0).getSObjectType();
    // Compute every schema path we'll need to resolve values against - the primary field, any overridden
    // display field, and (for REFERENCE-typed primaries with no display override) the parent record's Name.
    List<String> hydrationPaths = collectHydrationPaths(specs, sourceType);
    List<SObject> hydratedRecords = hydrateRecordsWithFieldPaths(request.matchingRecords, hydrationPaths);
    notification.attachments = new List<AttachmentDto>();
    for (SObject record : hydratedRecords) {
      notification.attachments.add(this.buildAttachment(record, specs, includeNullValues));
    }
    // 'short' is a reserved word in Apex, so it's serialized as `isShort` here and swapped in the JSON string
    return System.JSON.serialize(notification, true).replace('"isShort"', '"short"');
  }

  private AttachmentDto buildAttachment(SObject record, List<LoggerNotifierConfiguration.SourceFieldSpec> specs, Boolean includeNullValues) {
    AttachmentDto attachment = new AttachmentDto();
    attachment.color = this.getColorForRecord(record);
    attachment.title = this.getRecordTitle(record);
    attachment.title_link = this.getRecordLink(record);
    // Slack renders <url|text> mrkdwn links inside field values only when the attachment opts in via mrkdwn_in.
    attachment.mrkdwn_in = new List<String>{ 'fields' };
    attachment.fields = new List<FieldDto>();

    for (LoggerNotifierConfiguration.SourceFieldSpec spec : specs) {
      FieldDto rendered = this.renderField(record, spec, includeNullValues);
      if (rendered != null) {
        attachment.fields.add(rendered);
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

  private FieldDto renderField(SObject record, LoggerNotifierConfiguration.SourceFieldSpec spec, Boolean includeNullValues) {
    Schema.DescribeFieldResult primaryDescribe = getDescribeByPath(record.getSObjectType(), spec.field);
    if (primaryDescribe == null) {
      return null;
    }
    // Resolve the display value: explicit displayField > REFERENCE parent Name fallback > primary value.
    String valuePath = String.isNotBlank(spec.displayField)
      ? spec.displayField
      : (primaryDescribe.getType() == Schema.DisplayType.REFERENCE ? deriveParentNamePath(spec.field, record.getSObjectType()) : spec.field);
    if (valuePath == null) {
      valuePath = spec.field;
    }
    Object rawValue = getValueByPath(record, valuePath);
    Boolean isWide = isWideDisplayType(primaryDescribe.getType());
    String label = String.isNotBlank(spec.displayLabel) ? spec.displayLabel : primaryDescribe.getLabel();
    if (rawValue == null || String.isBlank(String.valueOf(rawValue))) {
      if (includeNullValues == false) {
        return null;
      }
      return new FieldDto(label, NULL_VALUE_PLACEHOLDER, isWide == false);
    }
    String stringValue = String.valueOf(rawValue);
    String renderedValue = isWide ? '```' + this.truncate(stringValue, 2000) + '```' : '`' + stringValue + '`';
    // Slack's `<url|text>` mrkdwn wrapping only kicks in when the primary field points at a specific record
    // (a Name on the source record, a parent Name via `.Name`, or a REFERENCE lookup). Everything else stays
    // as plain rendered text.
    Id linkTarget = resolveLinkTarget(record, spec.field, primaryDescribe);
    return new FieldDto(label, wrapAsLink(linkTarget, renderedValue), isWide == false);
  }

  private static String wrapAsLink(Id linkTarget, String rendered) {
    if (linkTarget == null) {
      return rendered;
    }
    return '<' + System.URL.getOrgDomainUrl().toExternalForm() + '/' + linkTarget + '|' + rendered + '>';
  }

  private static Id resolveLinkTarget(SObject record, String fieldPath, Schema.DescribeFieldResult primaryDescribe) {
    if (primaryDescribe.getType() == Schema.DisplayType.REFERENCE) {
      Object value = getValueByPath(record, fieldPath);
      return value instanceof Id ? (Id) value : null;
    }
    List<String> parts = fieldPath.split('\\.');
    if (parts.get(parts.size() - 1).equalsIgnoreCase('Name') == false) {
      return null;
    }
    if (parts.size() == 1) {
      // Source record's own Name - link to the source record.
      Object idValue = record.get('Id');
      return idValue instanceof Id ? (Id) idValue : null;
    }
    // Parent record's Name - link to the parent record. The parent's Id is on the source record via the
    // `__c` (or standard-relationship) column corresponding to the `__r` hop just before Name.
    String parentRelationshipSegment = parts.get(parts.size() - 2);
    // For dotted paths deeper than 2 segments, we walk the intermediate `__r` chain to reach the direct
    // parent, then look up the Id from THAT record's foreign-key column.
    SObject parentHolder = record;
    for (Integer i = 0; i < parts.size() - 2; i++) {
      try {
        parentHolder = parentHolder.getSObject(parts.get(i));
      } catch (System.SObjectException ex) {
        return null;
      }
      if (parentHolder == null) {
        return null;
      }
    }
    Schema.SObjectField fkField = findForeignKeyField(parentHolder.getSObjectType(), parentRelationshipSegment);
    if (fkField == null) {
      return null;
    }
    Object idValue = parentHolder.get(fkField);
    return idValue instanceof Id ? (Id) idValue : null;
  }

  private static Schema.SObjectField findForeignKeyField(Schema.SObjectType type, String relationshipSegment) {
    for (Schema.SObjectField field : type.getDescribe().fields.getMap().values()) {
      Schema.DescribeFieldResult describe = field.getDescribe();
      if (relationshipSegment.equalsIgnoreCase(describe.getRelationshipName())) {
        return field;
      }
    }
    return null;
  }

  /**
   * @description For a REFERENCE-typed primary field with no `displayField` override, derives the `.Name`
   *              path on the parent record so the notifier can show `<parent Name>` instead of a raw Id.
   *              Returns null if the parent type has no `Name` field (e.g. junctions, some managed objects).
   */
  private static String deriveParentNamePath(String fieldPath, Schema.SObjectType startType) {
    Schema.DescribeFieldResult describe = getDescribeByPath(startType, fieldPath);
    if (describe == null || describe.getType() != Schema.DisplayType.REFERENCE) {
      return null;
    }
    List<Schema.SObjectType> refs = describe.getReferenceTo();
    if (refs.isEmpty()) {
      return null;
    }
    Schema.SObjectType parentType = refs.get(0);
    if (parentType.getDescribe().fields.getMap().containsKey('name') == false) {
      return null;
    }
    // Substitute the terminal foreign-key segment (`.LoggedBy__c`) with the relationship+Name pair
    // (`.LoggedBy__r.Name`). The relationship name is the FK's `getRelationshipName()`.
    String relationshipName = describe.getRelationshipName();
    if (String.isBlank(relationshipName)) {
      return null;
    }
    List<String> parts = fieldPath.split('\\.');
    parts.set(parts.size() - 1, relationshipName + '.Name');
    return String.join(parts, '.');
  }

  private static List<String> collectHydrationPaths(List<LoggerNotifierConfiguration.SourceFieldSpec> specs, Schema.SObjectType sourceType) {
    Set<String> pathSet = new Set<String>();
    for (LoggerNotifierConfiguration.SourceFieldSpec spec : specs) {
      if (String.isNotBlank(spec.field)) {
        pathSet.add(spec.field);
      }
      if (String.isNotBlank(spec.displayField)) {
        pathSet.add(spec.displayField);
      } else {
        // REFERENCE primary field with no explicit display override: pull the parent's Name too so the
        // renderer can substitute it for the raw Id at render time.
        Schema.DescribeFieldResult describe = getDescribeByPath(sourceType, spec.field);
        if (describe != null && describe.getType() == Schema.DisplayType.REFERENCE) {
          String parentNamePath = deriveParentNamePath(spec.field, sourceType);
          if (parentNamePath != null) {
            pathSet.add(parentNamePath);
          }
        }
      }
    }
    List<String> paths = new List<String>(pathSet);
    return paths;
  }

  private static Boolean isWideDisplayType(Schema.DisplayType type) {
    // Long-form values (Long Text Area, Rich Text Area, encrypted long text) get their own Slack row and
    // a code block for readability; scalar fields render as half-width tiles.
    return type == Schema.DisplayType.TEXTAREA;
  }

  private String getColorForRecord(SObject record) {
    // TODO BAD! stop assuming everything is probably LogEntry__c
    String loggingLevel = this.tryGetString(record, 'LoggingLevel__c');
    // TODO BAD! Stop hardcoding LoggingLevel enum values
    if (loggingLevel == 'ERROR') {
      return NOTIFICATION_COLOR_RED;
    }
    if (loggingLevel == 'WARN') {
      return NOTIFICATION_COLOR_ORANGE;
    }
    return NOTIFICATION_COLOR_GREEN;
  }

  private String getRecordTitle(SObject record) {
    String objectLabel = record.getSObjectType().getDescribe().getLabel();
    String name = this.tryGetString(record, 'Name');
    return String.isNotBlank(name) ? objectLabel + ' ' + name : objectLabel;
  }

  private String getRecordLink(SObject record) {
    Id recordId = (Id) record.get('Id');
    if (recordId == null) {
      return null;
    }
    return System.URL.getOrgDomainUrl().toExternalForm() + '/' + recordId;
  }

  private String tryGetString(SObject record, String fieldName) {
    Map<String, Schema.SObjectField> fields = record.getSObjectType().getDescribe().fields.getMap();
    if (fields.containsKey(fieldName.toLowerCase()) == false) {
      return null;
    }
    try {
      Object value = record.get(fieldName);
      return value == null ? null : String.valueOf(value);
    } catch (System.SObjectException ex) {
      // Field exists on the schema but wasn't queried on this record instance - treat as absent.
      return null;
    }
  }

  private String truncate(String value, Integer maxLength) {
    if (value == null || value.length() <= maxLength) {
      return value;
    }
    return value.substring(0, maxLength) + '...(truncated)';
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
   *              identifier and channel for external-reference capture on the delivery row. Extra
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
