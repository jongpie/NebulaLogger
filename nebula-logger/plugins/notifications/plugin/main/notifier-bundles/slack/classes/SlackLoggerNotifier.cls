//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Delivers a `LoggerNotifiableContext` to Slack. The `LoggerNotificationRecipient__c` referenced
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
public without sharing class SlackLoggerNotifier implements LoggerNotifiable {
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

  private static final String NULL_VALUE_PLACEHOLDER = '(null/no value)';

  /**
   * @description Called by `LoggerNotifierAsyncDispatcher` in an async, callout-legal context.
   * @param context The rule + recipient + service + matching records to deliver.
   */
  public LoggerNotifiableResult sendNotification(LoggerNotifiableContext context) {
    if (context == null || context.recipient == null || context.matchingRecords == null || context.matchingRecords.isEmpty()) {
      return null;
    }
    System.HttpRequest request = this.buildRequest(context);
    if (request == null) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('SlackLoggerNotifier - service has neither Webhook URL nor Named Credential; skipping delivery');
      }
      LoggerNotifiableResult skipped = new LoggerNotifiableResult();
      skipped.status = LoggerNotifiableResult.STATUS_SKIPPED;
      skipped.errorMessage = 'Service has neither Webhook URL nor Named Credential configured';
      return skipped;
    }
    request.setBody(this.buildPayload(context));
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('SlackLoggerNotifier - sending payload').setHttpRequestDetails(request);
    }
    System.HttpResponse response;
    try {
      response = new System.Http().send(request);
    } catch (System.CalloutException ex) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.error('SlackLoggerNotifier - callout failed', ex);
      }
      // TODO: notifiers currently log via Nebula Logger for diagnostics, which can re-trigger the
      // notifications plugin when the resulting LogEntry__c rows match another rule (or the same one).
      // Commented out for now; see Backlog.md for the discussion on removing all Logger.* calls from
      // notifier bundles.
      // Logger.saveLog();
      LoggerNotifiableResult failed = new LoggerNotifiableResult();
      failed.status = LoggerNotifiableResult.STATUS_FAILED;
      failed.errorMessage = ex.getMessage();
      failed.errorStackTrace = ex.getStackTraceString();
      failed.requestUrl = request.getEndpoint();
      failed.requestMethod = request.getMethod();
      failed.requestBody = request.getBody();
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
    LoggerNotifiableResult result = LoggerNotifiableResult.fromHttpRequestAndResponse(request, response, KNOWN_REQUEST_HEADERS);
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
  private static void interpretSlackResponse(System.HttpResponse response, LoggerNotifiableResult result) {
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
      result.status = LoggerNotifiableResult.STATUS_FAILED;
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

  private System.HttpRequest buildRequest(LoggerNotifiableContext context) {
    String endpoint;
    if (String.isNotBlank(context.service.NamedCredentialDeveloperName__c)) {
      // Web API mode: callout: named credential + chat.postMessage path
      endpoint = 'callout:' + context.service.NamedCredentialDeveloperName__c + '/chat.postMessage';
    } else if (String.isNotBlank(context.service.WebhookUrl__c)) {
      endpoint = context.service.WebhookUrl__c;
    } else {
      return null;
    }
    System.HttpRequest request = new System.HttpRequest();
    request.setEndpoint(endpoint);
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    return request;
  }

  private String buildPayload(LoggerNotifiableContext context) {
    NotificationDto notification = new NotificationDto();
    // Top-level text is Slack's summary line above the attachments. It uses <url|text> mrkdwn syntax
    // automatically (no opt-in flag needed at this level), so linkifying the rule name here Just Works.
    notification.text = 'Nebula Logger notification for ' + this.buildRuleLink(context.notificationRule);
    if (String.isNotBlank(context.recipient.ChannelIdentifier__c) && String.isNotBlank(context.service.NamedCredentialDeveloperName__c)) {
      // Only the Web API mode uses the channel field on the payload; webhooks are pre-scoped to a channel
      notification.channel = context.recipient.ChannelIdentifier__c;
    }
    List<LoggerNotifiableConfiguration.SourceFieldSpec> specs = context.config.getSourceFieldSpecs();
    if (specs == null) {
      specs = buildDefaultSpecs();
    }
    Boolean includeNullValues = context.config.getBoolean('includeNullValues', false);
    Schema.SObjectType sourceType = context.matchingRecords.get(0).getSObjectType();
    // Compute every schema path we'll need to resolve values against - the primary field, any overridden
    // display field, and (for REFERENCE-typed primaries with no display override) the parent record's Name.
    List<String> hydrationPaths = collectHydrationPaths(specs, sourceType);
    List<SObject> hydratedRecords = hydrateRecordsWithFieldPaths(context.matchingRecords, hydrationPaths);
    notification.attachments = new List<AttachmentDto>();
    for (SObject record : hydratedRecords) {
      notification.attachments.add(this.buildAttachment(record, specs, includeNullValues));
    }
    // 'short' is a reserved word in Apex, so it's serialized as `isShort` here and swapped in the JSON string
    return System.JSON.serialize(notification, true).replace('"isShort"', '"short"');
  }

  private static List<LoggerNotifiableConfiguration.SourceFieldSpec> buildDefaultSpecs() {
    List<LoggerNotifiableConfiguration.SourceFieldSpec> defaults = new List<LoggerNotifiableConfiguration.SourceFieldSpec>();
    for (String fieldName : DEFAULT_SOURCE_FIELDS) {
      defaults.add(new LoggerNotifiableConfiguration.SourceFieldSpec(fieldName, null, null));
    }
    return defaults;
  }

  private AttachmentDto buildAttachment(SObject record, List<LoggerNotifiableConfiguration.SourceFieldSpec> specs, Boolean includeNullValues) {
    AttachmentDto attachment = new AttachmentDto();
    attachment.color = this.getColorForRecord(record);
    attachment.title = this.getRecordTitle(record);
    attachment.title_link = this.getRecordLink(record);
    // Slack renders <url|text> mrkdwn links inside field values only when the attachment opts in via mrkdwn_in.
    attachment.mrkdwn_in = new List<String>{ 'fields' };
    attachment.fields = new List<FieldDto>();

    for (LoggerNotifiableConfiguration.SourceFieldSpec spec : specs) {
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

  private FieldDto renderField(SObject record, LoggerNotifiableConfiguration.SourceFieldSpec spec, Boolean includeNullValues) {
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

  private static List<String> collectHydrationPaths(List<LoggerNotifiableConfiguration.SourceFieldSpec> specs, Schema.SObjectType sourceType) {
    Set<String> pathSet = new Set<String>();
    for (LoggerNotifiableConfiguration.SourceFieldSpec spec : specs) {
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

  /**
   * @description Walks a dotted field path (e.g. `Log__r.Name`) on a hydrated SObject. Returns null on any
   *              broken hop - unknown relationship name, missing parent, unknown final field.
   */
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

  /**
   * @description Traverses the schema graph for a dotted field path and returns the terminal field's
   *              describe (used for label + DisplayType). Handles both custom `__r` relationships and
   *              standard relationships (Owner, CreatedBy, etc.) uniformly by matching each segment
   *              against `DescribeFieldResult.getRelationshipName()` on the current type.
   */
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

  /**
   * @description When configured source fields include parent-relationship paths (containing a `.`), the
   *              trigger-supplied `matchingRecords` don't have those parent lookups populated - Salesforce
   *              only fills them in on records loaded via SOQL that explicitly selected them. This helper
   *              re-queries the records by Id with a SELECT that includes every configured path (dotted
   *              or not), so subsequent `getValueByPath` calls resolve cleanly. Records without Ids are
   *              left as-is (e.g. platform events, or synthetic in-memory records used by tests). If any
   *              configured path is invalid the whole query fails; the un-hydrated records are returned
   *              and `renderField` just drops fields it can't resolve.
   * @param records The matching records to hydrate.
   * @param fieldPaths The configured field paths - both flat field names and dotted relationships.
   * @return A new list of hydrated records, in the same order as `records`.
   */
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
      for (SObject queried : queryHydratedRecords(type, idsByType.get(type), fieldPaths)) {
        hydratedById.put((Id) queried.get('Id'), queried);
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

  /**
   * @description Runs the hydration SELECT for a single object type. Adds Id, Name (when the object has one),
   *              and LoggingLevel__c (used for color-coding on LogEntry) alongside the configured paths so
   *              the attachment's title + color logic still work after hydration replaces the trigger-supplied
   *              record. Uses a Set to deduplicate the field list so a configured path that happens to repeat
   *              one of these fields doesn't produce a `duplicate field` SOQL error. If the query fails
   *              (invalid path, missing field access, etc.) an empty list is returned so the caller falls back
   *              to the un-hydrated records.
   */
  private static List<SObject> queryHydratedRecords(Schema.SObjectType type, Set<Id> ids, List<String> fieldPaths) {
    Map<String, Schema.SObjectField> fieldMap = type.getDescribe().fields.getMap();
    Set<String> selectFieldSet = new Set<String>{ 'Id' };
    if (fieldMap.containsKey('name')) {
      selectFieldSet.add('Name');
    }
    if (fieldMap.containsKey('logginglevel__c')) {
      selectFieldSet.add('LoggingLevel__c');
    }
    // Filter out configured paths that don't resolve against the source type's describe. A single bad
    // path used to poison the whole SELECT via QueryException, which fell back to un-hydrated records
    // and made every OTHER configured field render as its null placeholder. Dropping unresolvable paths
    // here lets the good ones still hydrate; `renderField` already silently drops unresolvable paths at
    // render time, so the two layers stay consistent.
    for (String path : fieldPaths) {
      if (getDescribeByPath(type, path) != null) {
        selectFieldSet.add(path);
      }
    }
    String query = 'SELECT ' + String.join(new List<String>(selectFieldSet), ', ') + ' FROM ' + type.getDescribe().getName() + ' WHERE Id IN :ids';
    try {
      return System.Database.queryWithBinds(query, new Map<String, Object>{ 'ids' => ids }, System.AccessLevel.SYSTEM_MODE);
    } catch (System.QueryException ex) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('SlackLoggerNotifier - could not hydrate records for field paths ' + fieldPaths + ': ' + ex.getMessage());
      }
      return new List<SObject>();
    }
  }

  private static Boolean isWideDisplayType(Schema.DisplayType type) {
    // Long-form values (Long Text Area, Rich Text Area, encrypted long text) get their own Slack row and
    // a code block for readability; scalar fields render as half-width tiles.
    return type == Schema.DisplayType.TEXTAREA;
  }

  private String getColorForRecord(SObject record) {
    String loggingLevel = this.tryGetString(record, 'LoggingLevel__c');
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
