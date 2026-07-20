//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Handles trigger events for the `LoggerNotificationRule__c` object. Stamps `OriginOrganizationId__c`
 *              on insert so that records cloned into a refreshed sandbox from another org are flagged as
 *              invalid until an admin re-saves them in the current org. Also validates the
 *              `SourceSObjectFilter__c` formula expression against `SourceSObjectType__c` at save time so that admins
 *              cannot save a rule whose filter would fail at runtime (e.g. an unsupported picklist
 *              comparison, a missing field, or a syntax error).
 */
public without sharing class LoggerNotificationRuleHandler extends LoggerSObjectHandler {
  /**
   * @description Returns the SObject Type that the handler is responsible for processing
   * @return      The instance of `SObjectType`
   */
  public override Schema.SObjectType getSObjectType() {
    return Schema.LoggerNotificationRule__c.SObjectType;
  }

  protected override void executeBeforeInsert(List<SObject> triggerNew) {
    this.stampOriginOrganizationId(triggerNew);
    this.validateFilters(triggerNew, null);
    this.validateDeduplicationSourceFields(triggerNew, null);
    this.validateHistoryFlags(triggerNew);
    this.validateRetentionDays(triggerNew);
  }

  protected override void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
    this.validateFilters(triggerNewMap.values(), triggerOldMap);
    this.validateDeduplicationSourceFields(triggerNewMap.values(), triggerOldMap);
    this.validateHistoryFlags(triggerNewMap.values());
    this.validateRetentionDays(triggerNewMap.values());
  }

  private void validateRetentionDays(List<SObject> records) {
    // Delivery rows are master-detail children of match rows, so a match row's cascade delete takes
    // its delivery rows with it. If a rule specified a longer delivery retention than match retention,
    // the delivery rows would still get deleted early (via cascade) and the configured value would
    // silently misbehave. Rejecting the mismatch at save time keeps the storage semantics honest.
    for (SObject record : records) {
      LoggerNotificationRule__c rule = (LoggerNotificationRule__c) record;
      // Null on either side means "keep forever" for that object, which never runs afoul of the
      // "delivery cascades with match" problem - a null match retention leaves the match row (and
      // therefore its delivery children) untouched by the purger regardless of the delivery value.
      if (rule.NumberOfDaysToRetainMatches__c == null || rule.NumberOfDaysToRetainDeliveries__c == null) {
        continue;
      }
      if (rule.NumberOfDaysToRetainDeliveries__c > rule.NumberOfDaysToRetainMatches__c) {
        rule.NumberOfDaysToRetainDeliveries__c.addError(
          'Days to Retain Deliveries (' +
            rule.NumberOfDaysToRetainDeliveries__c +
            ') cannot be greater than Days to Retain Matches (' +
            rule.NumberOfDaysToRetainMatches__c +
            '). Delivery rows are master-detail children of match rows, so a deleted match cascades its deliveries with it - a longer delivery retention would never take effect.'
        );
      }
    }
  }

  private void validateHistoryFlags(List<SObject> records) {
    // Replaces two Validation Rules (DeliveryHistoryRequiresMatchHistory + MatchThresholdRequiresMatchHistory)
    // per the plugin convention: validation for plugin-owned objects lives in the handler, not in
    // declarative Validation Rules, so it can be edited freely across package versions.
    for (SObject record : records) {
      LoggerNotificationRule__c rule = (LoggerNotificationRule__c) record;
      if (rule.IsDeliveryHistoryEnabled__c == true && rule.IsMatchHistoryEnabled__c == false) {
        rule.IsDeliveryHistoryEnabled__c.addError(
          'Delivery History Enabled cannot be TRUE when Match History Enabled is FALSE. Delivery rows are master-detail children of match rows, so match history must be stored.'
        );
      }
      if (rule.IsMatchThresholdEnabled__c == true && rule.IsMatchHistoryEnabled__c == false) {
        rule.IsMatchThresholdEnabled__c.addError(
          'Match Threshold Enabled cannot be TRUE when Match History Enabled is FALSE. The threshold-over-time feature counts prior match rows, so match history must be stored.'
        );
      }
    }
  }

  private void stampOriginOrganizationId(List<SObject> records) {
    String currentOrganizationId = System.UserInfo.getOrganizationId();
    for (SObject record : records) {
      ((LoggerNotificationRule__c) record).OriginOrganizationId__c = currentOrganizationId;
    }
  }

  private void validateDeduplicationSourceFields(List<SObject> records, Map<Id, SObject> triggerOldMap) {
    for (SObject record : records) {
      LoggerNotificationRule__c rule = (LoggerNotificationRule__c) record;
      if (String.isBlank(rule.DeduplicationSourceField__c) || String.isBlank(rule.SourceSObjectType__c)) {
        continue;
      }
      if (triggerOldMap != null) {
        LoggerNotificationRule__c oldRule = (LoggerNotificationRule__c) triggerOldMap.get(rule.Id);
        if (
          oldRule != null &&
          oldRule.DeduplicationSourceField__c == rule.DeduplicationSourceField__c &&
          oldRule.SourceSObjectType__c == rule.SourceSObjectType__c
        ) {
          continue;
        }
      }
      Schema.SObjectType sourceType = resolveSObjectType(rule.SourceSObjectType__c);
      if (sourceType == null) {
        // The SourceSObjectType__c error message from validateFilters will already surface here on the same save.
        continue;
      }
      Map<String, Schema.SObjectField> fieldsByName = sourceType.getDescribe().fields.getMap();
      if (fieldsByName.containsKey(rule.DeduplicationSourceField__c.toLowerCase()) == false) {
        rule.DeduplicationSourceField__c.addError(
          'Field ' +
            rule.DeduplicationSourceField__c +
            ' does not exist on ' +
            rule.SourceSObjectType__c +
            ' - use the API name of a field on the source SObject.'
        );
      }
    }
  }

  private void validateFilters(List<SObject> records, Map<Id, SObject> triggerOldMap) {
    for (SObject record : records) {
      LoggerNotificationRule__c rule = (LoggerNotificationRule__c) record;
      if (String.isBlank(rule.SourceSObjectFilter__c) || String.isBlank(rule.SourceSObjectType__c)) {
        continue;
      }
      if (triggerOldMap != null) {
        LoggerNotificationRule__c oldRule = (LoggerNotificationRule__c) triggerOldMap.get(rule.Id);
        if (oldRule != null && oldRule.SourceSObjectFilter__c == rule.SourceSObjectFilter__c && oldRule.SourceSObjectType__c == rule.SourceSObjectType__c) {
          continue;
        }
      }
      Schema.SObjectType sourceType = resolveSObjectType(rule.SourceSObjectType__c);
      if (sourceType == null) {
        rule.SourceSObjectType__c.addError('Unknown SObject type: ' + rule.SourceSObjectType__c);
        continue;
      }
      String validationError = validateFilter(sourceType, rule.SourceSObjectFilter__c);
      if (validationError != null) {
        rule.SourceSObjectFilter__c.addError(validationError);
      }
    }
  }

  /**
   * @description Resolves a `SourceSObjectType__c` string (as stored on `LoggerNotificationRule__c`) to a
   *              `Schema.SObjectType`. Stored values use the unqualified local name (e.g. `LogEntry__c`).
   *              In managed-package installations the runtime name of the same object is namespace-prefixed
   *              (e.g. `Nebula__LogEntry__c`), so this method retries with the runtime namespace prefix -
   *              derived from `Logger.class`, never hardcoded - when the raw lookup fails.
   * @param  sobjectTypeName The stored source-SObject-type name.
   * @return                 The resolved `Schema.SObjectType`, or `null` if it cannot be resolved even
   *                         after applying the namespace prefix.
   */
  public static Schema.SObjectType resolveSObjectType(String sobjectTypeName) {
    if (String.isBlank(sobjectTypeName)) {
      return null;
    }
    Schema.SObjectType resolved = sobjectTypeFromName(sobjectTypeName);
    if (resolved != null) {
      return resolved;
    }
    String namespacePrefix = Logger.getNamespacePrefix();
    if (String.isNotBlank(namespacePrefix) && sobjectTypeName.contains('__') && sobjectTypeName.startsWith(namespacePrefix + '__') == false) {
      resolved = sobjectTypeFromName(namespacePrefix + '__' + sobjectTypeName);
    }
    return resolved;
  }

  private static Schema.SObjectType sobjectTypeFromName(String qualifiedName) {
    System.Type sobjectClass = System.Type.forName(qualifiedName);
    if (sobjectClass == null) {
      return null;
    }
    Object instance = sobjectClass.newInstance();
    return instance instanceof SObject ? ((SObject) instance).getSObjectType() : null;
  }

  /**
   * @description Validates a `SourceSObjectFilter__c` expression against a source SObject type. Returns `null` when
   *              the filter compiles and evaluates cleanly against a bare record; otherwise returns a
   *              human-readable error message. Used by both the before-save trigger validation and the
   *              editor LWC's live-validation loop so admins get consistent feedback.
   * @param sourceType The SObject type the filter compiles against.
   * @param filter The formula expression to validate.
   * @return `null` when valid; otherwise an error message.
   */
  public static String validateFilter(Schema.SObjectType sourceType, String filter) {
    FormulaEval.FormulaInstance compiled;
    try {
      compiled = Formula.builder().withType(sourceType).withReturnType(FormulaEval.FormulaReturnType.BOOLEAN).withFormula(filter).build();
    } catch (System.Exception compileException) {
      return 'Filter did not compile against ' + sourceType + ': ' + compileException.getMessage();
    }
    try {
      compiled.evaluate(sourceType.newSObject());
    } catch (System.Exception evaluateException) {
      return 'Filter did not evaluate against ' + sourceType + ': ' + evaluateException.getMessage();
    }
    return null;
  }
}
