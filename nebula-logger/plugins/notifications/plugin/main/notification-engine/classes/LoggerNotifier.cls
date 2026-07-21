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
 *              The base class also provides the shared field-path-walking and record-hydration helpers used by
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
   * @description Builds a default `SourceFieldSpec` list from a notifier's built-in fallback field names.
   *              Used when the recipient's `ConfigurationJson__c` does not specify `sourceFields`.
   * @param fieldNames The bare field API names the notifier falls back to.
   * @return A list of specs with `displayField` and `displayLabel` unset (the notifier's renderer uses the
   *         describe-provided label at render time).
   */
  public static List<LoggerNotifierConfiguration.SourceFieldSpec> buildDefaultSpecs(List<String> fieldNames) {
    List<LoggerNotifierConfiguration.SourceFieldSpec> defaults = new List<LoggerNotifierConfiguration.SourceFieldSpec>();
    for (String fieldName : fieldNames) {
      defaults.add(new LoggerNotifierConfiguration.SourceFieldSpec(fieldName, null, null));
    }
    return defaults;
  }

  /**
   * @description Walks a dotted field path (e.g. `Log__r.Name`) on a hydrated SObject. Returns null on any
   *              broken hop - unknown relationship name, missing parent, unknown final field.
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
   * @description When configured source fields include parent-relationship paths (containing a `.`), the
   *              trigger-supplied `matchingRecords` don't have those parent lookups populated - Salesforce
   *              only fills them in on records loaded via SOQL that explicitly selected them. This helper
   *              re-queries the records by Id with a SELECT that includes every configured path (dotted
   *              or not), so subsequent `getValueByPath` calls resolve cleanly. Records without Ids are
   *              left as-is (e.g. platform events, or synthetic in-memory records used by tests).
   *              Unresolvable paths are silently dropped from the SELECT so a single bad path does not
   *              poison the whole query; the renderer already silently drops unresolvable paths at
   *              render time, so the two layers stay consistent.
   * @param records The matching records to hydrate.
   * @param fieldPaths The configured field paths - both flat field names and dotted relationships.
   * @return A new list of hydrated records, in the same order as `records`. Records that could not be
   *         hydrated (no Id, query failure) fall through untouched.
   */
  public static List<SObject> hydrateRecordsWithFieldPaths(List<SObject> records, List<String> fieldPaths) {
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
   *              and LoggingLevel__c (used by notifiers that color-code on LogEntry) alongside the configured
   *              paths so downstream renderers keep working after hydration replaces the trigger-supplied
   *              record. Uses a Set to deduplicate the field list so a configured path that happens to repeat
   *              one of these fields doesn't produce a `duplicate field` SOQL error. If the query fails an
   *              empty list is returned so the caller falls back to the un-hydrated records.
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
    // and made every OTHER configured field render as its null placeholder.
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
        Logger.warn('LoggerNotifier - could not hydrate records for field paths ' + fieldPaths + ': ' + ex.getMessage());
      }
      return new List<SObject>();
    }
  }
}
