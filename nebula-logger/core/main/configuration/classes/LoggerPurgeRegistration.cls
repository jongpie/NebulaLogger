//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Declarative registration payload returned by a `LoggerPlugin.Purgeable` plugin.
 *              Carries the SObject type the plugin wants included in the purge chain and the
 *              field token whose Date value `LogBatchPurger` compares against `System.today()`.
 *              The purger builds the SOQL query internally from this declaration - plugins do NOT
 *              write query strings themselves - so the retention semantics (`<= today` +
 *              `!= NULL`, ordering, and the `RETENTION_END_DATE` bind) stay consistent across
 *              every purgeable SObject.
 *
 *              Design intent: keep this DTO append-only so we can add optional properties later
 *              (`additionalWhereClause`, `batchSize`, etc.) without ever breaking the
 *              `LoggerPlugin.Purgeable` interface signature.
 * @see LogBatchPurger
 * @see LoggerPlugin
 */
public class LoggerPurgeRegistration {
  /** @description SObject type to include in the purge chain. */
  public Schema.SObjectType sobjectType { get; private set; }
  /** @description Date field on `sobjectType` whose value drives purge eligibility. */
  public Schema.SObjectField retentionDateField { get; private set; }
  /**
   * @description Fields on `sobjectType` used for `ORDER BY` on the built query, applied in list
   *              order. Determines the order in which records are deleted within a batch execution.
   *              Typically a single-element list containing `retentionDateField` (oldest records
   *              deleted first), but a plugin can point at foreign-key or clustering fields when
   *              it needs child records to be processed in parent order (the built-in LogEntryTag__c
   *              query sorts by `LogEntry__r.Log__r.LogRetentionDate__c, LogEntry__r.Log__c` for
   *              exactly this reason).
   */
  public List<Schema.SObjectField> sortByFields { get; private set; }

  /**
   * @description Builds a registration for a purgeable SObject that sorts by a single field.
   *              Convenience over the multi-field constructor for the common case where a
   *              single ORDER BY column is enough.
   * @param sobjectType The custom SObject type to include in the purge chain. Its API name must
   *                    contain `Log`.
   * @param retentionDateField Date field on `sobjectType` whose value the purger reads to decide
   *                           whether a record is old enough to delete.
   * @param sortByField Single field on `sobjectType` used for `ORDER BY` on the built query.
   *                    Pass the same value as `retentionDateField` for the standard "oldest
   *                    first" behavior, or a different field when the plugin needs a specific
   *                    processing order.
   */
  public LoggerPurgeRegistration(Schema.SObjectType sobjectType, Schema.SObjectField retentionDateField, Schema.SObjectField sortByField) {
    this(sobjectType, retentionDateField, new List<Schema.SObjectField>{ sortByField });
  }

  /**
   * @description Builds a registration for a purgeable SObject that sorts by multiple fields.
   *              Use when a single ORDER BY column isn't enough - e.g. a plugin whose delete
   *              ordering has to cluster by parent record first, then by record age within each
   *              parent.
   * @param sobjectType The custom SObject type to include in the purge chain. Its API name must
   *                    contain `Log`.
   * @param retentionDateField Date field on `sobjectType` whose value the purger reads to decide
   *                           whether a record is old enough to delete.
   * @param sortByFields Fields on `sobjectType` used for `ORDER BY` on the built query, in list
   *                     order.
   */
  public LoggerPurgeRegistration(Schema.SObjectType sobjectType, Schema.SObjectField retentionDateField, List<Schema.SObjectField> sortByFields) {
    if (sobjectType == null) {
      throw new System.IllegalArgumentException('LoggerPurgeRegistration requires a non-null sobjectType');
    }
    if (retentionDateField == null) {
      throw new System.IllegalArgumentException('LoggerPurgeRegistration requires a non-null retentionDateField');
    }
    if (sortByFields == null || sortByFields.isEmpty()) {
      throw new System.IllegalArgumentException('LoggerPurgeRegistration requires at least one sortByFields entry');
    }
    for (Schema.SObjectField sortField : sortByFields) {
      if (sortField == null) {
        throw new System.IllegalArgumentException('LoggerPurgeRegistration.sortByFields must not contain a null entry');
      }
    }
    this.sobjectType = sobjectType;
    this.retentionDateField = retentionDateField;
    this.sortByFields = sortByFields;
  }

  /**
   * @description Builds the SOQL query for this registration. The `!= NULL` clause is what opts an
   *              individual record out of purging - a null retention date is the admin's way of saying
   *              "keep this record forever" - so it needs to be baked into every registered query.
   *              The `:RETENTION_END_DATE` bind resolves against the same `System.today()`
   *              value the core log objects use (defined on `LogBatchPurger` and in scope when
   *              the purger runs the built query), so a purge run has a single moving-target
   *              cutoff across all registered + built-in SObject types. ORDER BY the
   *              plugin-declared sort fields in list order (typically just the retention date
   *              so the oldest records delete first).
   * @return The SOQL query the purger runs to select records for deletion.
   */
  public String buildQuery() {
    String sobjectName = this.sobjectType.getDescribe().getName();
    String retentionFieldName = this.retentionDateField.getDescribe().getName();
    List<String> sortFieldNames = new List<String>();
    for (Schema.SObjectField sortField : this.sortByFields) {
      sortFieldNames.add(sortField.getDescribe().getName());
    }
    return String.format(
      'SELECT Id FROM {0} WHERE {1} <= :RETENTION_END_DATE AND {1} != NULL ORDER BY {2}',
      new List<String>{ sobjectName, retentionFieldName, String.join(sortFieldNames, ', ') }
    );
  }
}
