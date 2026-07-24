//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Abstract base class extended by Apex classes that deliver notifications for the Nebula Logger notifications
 *              plugin. Each `LoggerNotificationService__c` record names a concrete subclass via its
 *              `NotifierApexClassName__c` field. The runtime instantiates the subclass dynamically for each recipient
 *              and hands it the matching records plus the recipient's connection configuration.
 *
 *              The base class also provides the shared field-path-walking and record-requery helpers used by
 *              every notifier that reads recipient-configured source fields (Slack, Email, and future notifiers).
 *              These are `public static` because Apex forbids `protected static` and the helpers hold no
 *              instance state - subclasses (and the notifications engine itself) call them as pure utilities.
 */
public abstract class LoggerNotifier {
  /**
   * @description Called by `LoggerNotificationProcessor` when one or more records match a rule that references this service.
   *              Subclasses are responsible for delivering the notification (callout, email, etc.) and
   *              returning a `LoggerNotifierResult` describing what happened. Returning `null` is treated
   *              the same as a bare success by the runtime.
   * @param request The details of the matched rule, recipient, and records.
   * @return A `LoggerNotifierResult` describing the delivery outcome (status, external reference, HTTP details, etc.),
   *         or `null` to accept the runtime's default of "delivered with no additional detail".
   */
  public abstract LoggerNotifierResult sendNotification(LoggerNotifierRequest request);

  /**
   * @description Called by `LoggerNotificationRecipientHandler` on insert / update to validate the
   *              recipient's `ConfigurationJson__c` before the record is persisted. The default
   *              implementation delegates to `LoggerNotifierConfiguration.validate`, which covers every
   *              framework-level defect class (malformed JSON, wrong top-level shape, `sourceFields`
   *              entries with missing / stale field paths). Subclasses override only when they have
   *              notifier-specific rules the framework cannot know about - for example, Email's
   *              `subjectTemplate` merge-token contract, or Slack's mode-specific requirement that
   *              certain fields be populated when a Named Credential is configured. Overrides should
   *              call `super.validateConfiguration(...)` first and append their own errors to the
   *              returned list so both layers of checks report on the same save.
   * @param recipient The recipient whose configuration should be validated.
   * @param sourceType The `Schema.SObjectType` referenced by the rule's `SourceSObjectType__c`. May be
   *                   null when the source type could not be resolved - field-path checks skip in that
   *                   case because the rule handler already reports the unresolved SObject separately.
   * @return An ordered list of human-readable error messages. Empty when the configuration is valid.
   */
  public virtual List<String> validateConfiguration(LoggerNotificationRecipient__c recipient, Schema.SObjectType sourceType) {
    return LoggerNotifierConfiguration.validate(recipient?.ConfigurationJson__c, sourceType);
  }

  /**
   * @description Builds a default `SourceFieldDefinition` list from a notifier's built-in fallback field names.
   *              Used when the recipient's `ConfigurationJson__c` does not specify `sourceFields`.
   * @param fieldNames The bare field API names the notifier falls back to.
   * @return A list of `SourceFieldDefinition` entries with `displayField` and `displayLabel` unset (the
   *         notifier's renderer uses the describe-provided label at render time).
   */
  public static List<LoggerNotifierConfiguration.SourceFieldDefinition> buildDefaultSourceFields(List<String> fieldNames) {
    List<LoggerNotifierConfiguration.SourceFieldDefinition> defaults = new List<LoggerNotifierConfiguration.SourceFieldDefinition>();
    for (String fieldName : fieldNames) {
      defaults.add(new LoggerNotifierConfiguration.SourceFieldDefinition(fieldName, null, null));
    }
    return defaults;
  }

  /**
   * @description Walks a dotted field path (e.g. `Log__r.Name`) on an SObject that has already had its
   *              parent relationships loaded (via SOQL SELECT or `requeryRecordsWithFieldPaths`). Returns
   *              null on any broken hop - unknown relationship name, missing parent, unknown final field.
   */
  public static Object getValueByPath(SObject record, String fieldPath) {
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
  public static Schema.DescribeFieldResult getDescribeByPath(Schema.SObjectType startType, String fieldPath) {
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
   * @description For a REFERENCE-typed field with no explicit `displayField` override, derives the `.Name`
   *              path on the parent record so the notifier can show `<parent Name>` instead of a raw Id.
   *              Returns null if the field is not a REFERENCE, or if the parent type has no `Name` field
   *              (e.g. junctions, some managed objects).
   * @param fieldPath The primary field path (e.g. `LoggedBy__c` or `Log__r.OwnerId`) to derive from.
   * @param startType The SObject type the path is rooted at.
   * @return The `.Name`-terminated path on the parent record, or null when substitution isn't possible.
   */
  public static String deriveParentNamePath(String fieldPath, Schema.SObjectType startType) {
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

  /**
   * @description Gathers every field path a notifier needs pre-loaded on the matching records before
   *              rendering: the primary `sourceField` for each definition, any `displayField` override,
   *              and (for REFERENCE-typed primaries with no override) the parent record's `.Name` so the
   *              renderer can substitute the parent name for the raw Id. The returned set is ready to
   *              hand to `requeryRecordsWithFieldPaths`.
   * @param sourceFields The recipient-configured source-field definitions.
   * @param sourceType The SObject type the paths are rooted at.
   * @return A set of field paths (both flat and dotted) covering the primary field, display-field override,
   *         and REFERENCE-parent-Name fallback for each definition.
   */
  public static Set<String> collectFieldPathsToRequery(List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields, Schema.SObjectType sourceType) {
    Set<String> paths = new Set<String>();
    if (sourceFields == null) {
      return paths;
    }
    for (LoggerNotifierConfiguration.SourceFieldDefinition definition : sourceFields) {
      if (String.isNotBlank(definition.sourceField)) {
        paths.add(definition.sourceField);
      }
      if (String.isNotBlank(definition.displayField)) {
        paths.add(definition.displayField);
      } else {
        // REFERENCE primary field with no explicit display override: pull the parent's Name too so the
        // renderer can substitute it for the raw Id at render time.
        Schema.DescribeFieldResult describe = getDescribeByPath(sourceType, definition.sourceField);
        if (describe != null && describe.getType() == Schema.DisplayType.REFERENCE) {
          String parentNamePath = deriveParentNamePath(definition.sourceField, sourceType);
          if (parentNamePath != null) {
            paths.add(parentNamePath);
          }
        }
      }
    }
    return paths;
  }

  /**
   * @description Resolves the record Id a rendered field should link to, when the field's value points at
   *              a specific record. Returns non-null for three cases: a REFERENCE-typed primary field
   *              (link to the referenced record), the source record's own `Name` (link to the source
   *              record), or a dotted path ending in `.Name` (link to the parent record whose Name is
   *              being displayed). All other paths return null so the notifier renders them as plain text.
   * @param record The already-requeried record carrying the resolved parent lookups.
   * @param fieldPath The primary field path (`sourceField`) from the definition.
   * @param primaryDescribe The describe for the primary field, so the caller doesn't pay for a re-describe.
   * @return The Id to link to, or null when the field shouldn't render as a link.
   */
  public static Id resolveLinkTarget(SObject record, String fieldPath, Schema.DescribeFieldResult primaryDescribe) {
    if (record == null || String.isBlank(fieldPath) || primaryDescribe == null) {
      return null;
    }
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
   * @description When configured source fields include parent-relationship paths (containing a `.`), the
   *              trigger-supplied `matchingRecords` don't have those parent lookups populated - Salesforce
   *              only fills them in on records loaded via SOQL that explicitly selected them. This helper
   *              re-queries the records by Id with a SELECT that includes every configured path (dotted
   *              or not), so subsequent `getValueByPath` calls resolve cleanly. Records without Ids are
   *              left as-is (e.g. platform events, or synthetic in-memory records used by tests).
   *              Unresolvable paths are silently dropped from the SELECT so a single bad path does not
   *              poison the whole query; the renderer already silently drops unresolvable paths at
   *              render time, so the two layers stay consistent.
   * @param records The matching records to re-query.
   * @param fieldPaths The configured field paths - both flat field names and dotted relationships. A set
   *                   so callers can accumulate paths from multiple sources (rule filters, notifier config,
   *                   subject templates) without worrying about deduplication.
   * @return A new list of re-queried records, in the same order as `records`. Records that could not be
   *         re-queried (no Id, query failure) fall through untouched.
   */
  public static List<SObject> requeryRecordsWithFieldPaths(List<SObject> records, Set<String> fieldPaths) {
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
    Map<Id, SObject> requeriedById = new Map<Id, SObject>();
    for (Schema.SObjectType type : idsByType.keySet()) {
      for (SObject queried : queryRecordsWithFieldPaths(type, idsByType.get(type), fieldPaths)) {
        requeriedById.put((Id) queried.get('Id'), queried);
      }
    }
    List<SObject> result = new List<SObject>();
    for (SObject record : records) {
      Id recordId = (Id) record.get('Id');
      SObject requeried = recordId == null ? null : requeriedById.get(recordId);
      result.add(requeried ?? record);
    }
    return result;
  }

  /**
   * @description Runs the re-query SELECT for a single object type. Adds Id, Name (when the object has one),
   *              and LoggingLevel__c (used by notifiers that color-code on LogEntry) alongside the configured
   *              paths so downstream renderers keep working after the re-query replaces the trigger-supplied
   *              record. Uses a Set to deduplicate the field list so a configured path that happens to repeat
   *              one of these fields doesn't produce a `duplicate field` SOQL error. If the query fails an
   *              empty list is returned so the caller falls back to the trigger-supplied records.
   */
  private static List<SObject> queryRecordsWithFieldPaths(Schema.SObjectType type, Set<Id> ids, Set<String> fieldPaths) {
    Map<String, Schema.SObjectField> fieldMap = type.getDescribe().fields.getMap();
    Set<String> selectFieldSet = new Set<String>{ 'Id' };
    if (fieldMap.containsKey('name')) {
      selectFieldSet.add('Name');
    }
    if (fieldMap.containsKey('logginglevel__c')) {
      selectFieldSet.add('LoggingLevel__c');
    }
    // Filter out configured paths that don't resolve against the source type's describe. A single bad
    // path used to poison the whole SELECT via QueryException, which fell back to the trigger-supplied
    // records and made every OTHER configured field render as its null placeholder.
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
        Logger.warn('LoggerNotifier - could not re-query records for field paths ' + fieldPaths + ': ' + ex.getMessage());
      }
      return new List<SObject>();
    }
  }
}
