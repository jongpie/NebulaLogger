//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description The runtime for the notifications plugin. Evaluates active `LoggerNotificationRule__c` rules
 *              against inbound records (LogEntry__c / Log__c / LoggerScenario__c / LogEntryTag__c / LoggerTag__c,
 *              depending on the rule's `SourceSObjectType__c`), optionally persists `LoggerNotificationMatch__c`
 *              records (one per matched source record) and `LoggerNotificationDelivery__c` records (one per
 *              (match, recipient) tuple), and dispatches to each recipient's configured `LoggerNotifier`
 *              implementation.
 *
 *              Storage is controlled per-rule by `IsMatchHistoryEnabled__c` and `IsDeliveryHistoryEnabled__c`.
 *              Dispatch is not affected by these flags - a rule with both flags OFF still fires its
 *              notifiers, it just leaves no persistent trail.
 *
 *              Delivery records carry the outcome of each notifier invocation - status, HTTP details, external
 *              reference, error message. Synchronous notifiers are invoked before the delivery record is
 *              inserted so its final status is baked in on insert. Callout-required notifiers are invoked
 *              from the async dispatcher, which updates the pending delivery record on completion.
 *
 *              Rules with `IsOriginOrganizationIdValid__c = FALSE` are ignored so that rules cloned into a
 *              refreshed sandbox from another org do not fire until an admin re-saves them in the current org.
 */
public virtual without sharing class LoggerNotificationProcessor {
  private static Map<String, List<LoggerNotificationRule__c>> cachedRulesBySObjectTypeName;

  private final RuleFilterEvaluator filterEvaluator = new RuleFilterEvaluator();

  /**
   * @description Entry point invoked by the trigger-side integration. Loads active rules for the given
   *              SObject type, filters `records` against each rule's `SourceSObjectFilter__c`, records matches and
   *              deliveries (based on the rule's history flags), and dispatches each matched
   *              rule/recipient to its notifier class.
   * @param sobjectType The SObject type of `records`.
   * @param records The inbound records to evaluate.
   */
  public virtual void sendNotifications(Schema.SObjectType sobjectType, List<SObject> records) {
    // TODO the LoggerNotificatonsPlugin class shouldn't even call this method if these conditions are true
    if (sobjectType == null || records == null || records.isEmpty()) {
      return;
    }

    List<LoggerNotificationRule__c> applicableRules = getActiveRulesBySObjectTypeName().get(sobjectType.toString());
    if (applicableRules == null || applicableRules.isEmpty()) {
      return;
    }

    List<RuleEvaluation> evaluations = this.buildEvaluations(applicableRules, records, sobjectType);
    List<LoggerNotificationMatch__c> matchesToInsert = collectMatchesToInsert(evaluations);
    LoggerDataStore.getDatabase().insertRecords(matchesToInsert);
    List<LoggerNotificationDelivery__c> deliveriesToInsert = new List<LoggerNotificationDelivery__c>();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> asyncDispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>();
    for (RuleEvaluation evaluation : evaluations) {
      if (evaluation.shouldDispatch) {
        this.dispatchToRecipients(evaluation, deliveriesToInsert, asyncDispatches);
      } else {
        this.buildSuppressedDeliveries(evaluation, deliveriesToInsert);
      }
    }
    LoggerDataStore.getDatabase().insertRecords(deliveriesToInsert);
    this.updateAsyncDispatchDeliveryIds(asyncDispatches);
    this.enqueueAsyncDispatches(asyncDispatches);
  }

  private List<RuleEvaluation> buildEvaluations(List<LoggerNotificationRule__c> applicableRules, List<SObject> records, Schema.SObjectType sobjectType) {
    // Trigger.new records have parent lookup IDs but no loaded relationships, so a filter like
    // `Log__r.LoggedBy__r.Username = 'x'` evaluates against a null `Log__r` and silently fails to
    // match. Compile every applicable rule's formula up front, union their referenced field paths,
    // and re-query the trigger.new records by Id with those paths in the SELECT clause. The union
    // makes this one query per invocation instead of one per rule.
    Set<String> referencedFieldPaths = this.filterEvaluator.collectReferencedFieldPaths(sobjectType, applicableRules);
    List<SObject> requeriedRecords = LoggerNotifier.requeryRecordsWithFieldPaths(records, referencedFieldPaths);

    List<RuleEvaluation> evaluations = new List<RuleEvaluation>();
    for (LoggerNotificationRule__c rule : applicableRules) {
      List<SObject> matchingRecords = this.filterEvaluator.evaluate(sobjectType, rule.SourceSObjectFilter__c, requeriedRecords);

      if (matchingRecords.isEmpty()) {
        continue;
      }

      matchingRecords = deduplicateMatchingRecords(matchingRecords, rule.DeduplicationSourceField__c);
      RuleEvaluation evaluation = new RuleEvaluation();
      evaluation.rule = rule;
      evaluation.matchingRecords = matchingRecords;
      evaluation.shouldDispatch = this.shouldSuppressForThreshold(rule, matchingRecords.size()) == false;

      if (rule.IsMatchHistoryEnabled__c == true) {
        evaluation.matches = new List<LoggerNotificationMatch__c>();
        for (SObject match : matchingRecords) {
          evaluation.matches.add(this.buildMatchRecord(rule, sobjectType, match));
        }
      }

      evaluations.add(evaluation);
    }
    return evaluations;
  }

  /**
   * @description Collapses matching records to at most one entry per unique value of `deduplicationSourceField`,
   *              preserving the first-seen order. Records whose deduplication field value is null form their own
   *              group keyed on the sentinel string `<null>`. If `deduplicationSourceField` is blank the records
   *              are returned untouched; if the field does not exist on the source SObject each record
   *              gets its own group (i.e. no deduplication happens - safe fallback rather than throwing).
   */
  private static List<SObject> deduplicateMatchingRecords(List<SObject> matchingRecords, String deduplicationSourceField) {
    if (String.isBlank(deduplicationSourceField) || matchingRecords == null || matchingRecords.isEmpty()) {
      return matchingRecords;
    }
    Map<String, Schema.SObjectField> fieldsByName = matchingRecords.get(0).getSObjectType().getDescribe().fields.getMap();
    if (fieldsByName.containsKey(deduplicationSourceField.toLowerCase()) == false) {
      return matchingRecords;
    }
    Set<String> seenKeys = new Set<String>();
    List<SObject> deduplicated = new List<SObject>();
    for (SObject record : matchingRecords) {
      Object value = record.get(deduplicationSourceField);
      String key = value == null ? '<null>' : String.valueOf(value);
      if (seenKeys.contains(key)) {
        continue;
      }
      seenKeys.add(key);
      deduplicated.add(record);
    }
    return deduplicated;
  }

  private static List<LoggerNotificationMatch__c> collectMatchesToInsert(List<RuleEvaluation> evaluations) {
    List<LoggerNotificationMatch__c> matches = new List<LoggerNotificationMatch__c>();
    for (RuleEvaluation evaluation : evaluations) {
      if (evaluation.matches != null) {
        matches.addAll(evaluation.matches);
      }
    }
    return matches;
  }

  private void dispatchToRecipients(
    RuleEvaluation evaluation,
    List<LoggerNotificationDelivery__c> deliveriesToInsert,
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> pendingDispatches
  ) {
    if (evaluation.rule.LoggerNotificationRecipients__r == null || evaluation.rule.LoggerNotificationRecipients__r.isEmpty()) {
      return;
    }
    // Every recipient goes through the async dispatcher, regardless of whether the notifier
    // makes HTTP callouts. Triggers can't call out at all, so callout-based notifiers (Slack,
    // Teams, PagerDuty, etc.) MUST go async. Non-callout notifiers (Email, CustomNotification)
    // could technically run in-trigger, but pushing them through the same async path keeps the
    // pipeline uniform, isolates notifier failures from the source-record transaction (so a
    // rolled-back LogEntry insert also cancels the pending notifications), and gives every
    // notifier its own governor limit budget instead of sharing the source trigger's.
    Boolean canPersistDeliveries = evaluation.matches != null && evaluation.rule.IsDeliveryHistoryEnabled__c == true;
    for (LoggerNotificationRecipient__c recipient : evaluation.rule.LoggerNotificationRecipients__r) {
      List<LoggerNotificationDelivery__c> deliveriesForRecipient = canPersistDeliveries && recipient.Id != null
        ? this.buildPendingDeliveries(evaluation.rule, evaluation.matches, recipient)
        : null;
      recipient.LoggerNotificationRule__r = evaluation.rule;
      pendingDispatches.add(new LoggerNotificationAsyncDispatcher.PendingDispatch(recipient, evaluation.matchingRecords, deliveriesForRecipient));
      if (deliveriesForRecipient != null) {
        deliveriesToInsert.addAll(deliveriesForRecipient);
      }
    }
  }

  private void buildSuppressedDeliveries(RuleEvaluation evaluation, List<LoggerNotificationDelivery__c> deliveriesToInsert) {
    if (evaluation.rule.IsDeliveryHistoryEnabled__c == false || evaluation.rule.LoggerNotificationRecipients__r == null || evaluation.matches == null) {
      return;
    }

    Date retentionDate = computeRetentionDate(evaluation.rule.NumberOfDaysToRetainDeliveries__c);
    for (LoggerNotificationRecipient__c recipient : evaluation.rule.LoggerNotificationRecipients__r) {
      for (LoggerNotificationMatch__c match : evaluation.matches) {
        LoggerNotificationDelivery__c delivery = new LoggerNotificationDelivery__c(
          AttemptCount__c = 0,
          LoggerNotificationMatch__c = match.Id,
          LoggerNotificationRecipient__c = recipient.Id,
          LoggerNotificationRule__c = evaluation.rule.Id,
          LoggerNotificationService__c = recipient.LoggerNotificationService__c,
          RetentionDate__c = retentionDate,
          Status__c = LoggerNotifierResult.STATUS_SUPPRESSED_BY_THRESHOLD
        );
        deliveriesToInsert.add(delivery);
      }
    }
  }

  private void updateAsyncDispatchDeliveryIds(List<LoggerNotificationAsyncDispatcher.PendingDispatch> asyncDispatches) {
    for (LoggerNotificationAsyncDispatcher.PendingDispatch dispatch : asyncDispatches) {
      if (dispatch.pendingDeliveries == null || dispatch.pendingDeliveries.isEmpty()) {
        continue;
      }
      dispatch.pendingDeliveryIds = new List<Id>();
      for (LoggerNotificationDelivery__c delivery : dispatch.pendingDeliveries) {
        if (delivery.Id != null) {
          dispatch.pendingDeliveryIds.add(delivery.Id);
        }
      }
    }
  }

  private List<LoggerNotificationDelivery__c> buildPendingDeliveries(
    LoggerNotificationRule__c rule,
    List<LoggerNotificationMatch__c> matches,
    LoggerNotificationRecipient__c recipient
  ) {
    Date retentionDate = computeRetentionDate(rule.NumberOfDaysToRetainDeliveries__c);
    List<LoggerNotificationDelivery__c> deliveries = new List<LoggerNotificationDelivery__c>();
    for (LoggerNotificationMatch__c match : matches) {
      LoggerNotificationDelivery__c delivery = new LoggerNotificationDelivery__c(
        AttemptCount__c = 0,
        LoggerNotificationMatch__c = match.Id,
        LoggerNotificationRecipient__c = recipient.Id,
        LoggerNotificationRule__c = rule.Id,
        LoggerNotificationService__c = recipient.LoggerNotificationService__c,
        RetentionDate__c = retentionDate,
        Status__c = LoggerNotifierResult.STATUS_PENDING
      );
      deliveries.add(delivery);
    }
    return deliveries;
  }

  /**
   * @description Computes the `RetentionDate__c` value stamped onto a match or delivery record from the
   *              rule's per-object retention field. A null / non-positive value means "keep the record
   *              forever" - LogBatchPurger's WHERE clauses skip records whose RetentionDate__c is null,
   *              so leaving it blank is the way an admin opts a rule's history out of automatic purging.
   *              Match records use `NumberOfDaysToRetainMatches__c`; delivery records use
   *              `NumberOfDaysToRetainDeliveries__c`.
   */
  private static Date computeRetentionDate(Decimal daysToRetain) {
    if (daysToRetain == null || daysToRetain <= 0) {
      return null;
    }
    return System.today().addDays(daysToRetain.intValue());
  }

  @SuppressWarnings('PMD.UnusedLocalVariable') // The switch statement syntax is terrible & requires a local variable ＼（〇_ｏ）／
  private LoggerNotificationMatch__c buildMatchRecord(LoggerNotificationRule__c rule, Schema.SObjectType sobjectType, SObject matched) {
    Id matchedId = (Id) matched.get('Id');
    LoggerNotificationMatch__c matchRecord = new LoggerNotificationMatch__c(
      LoggerNotificationRule__c = rule.Id,
      MatchedRecordId__c = matchedId,
      MatchedSObjectType__c = sobjectType.toString(),
      RetentionDate__c = computeRetentionDate(rule.NumberOfDaysToRetainMatches__c)
    );

    switch on sobjectType.newSObject() {
      when LogEntry__c logEntry {
        matchRecord.LogEntry__c = matchedId;
      }
      when LogEntryTag__c logEntryTag {
        matchRecord.LogEntryTag__c = matchedId;
      }
      when Log__c log {
        matchRecord.Log__c = matchedId;
      }
      when LoggerScenario__c loggerScenario {
        matchRecord.LoggerScenario__c = matchedId;
      }
      when LoggerTag__c loggerTag {
        matchRecord.LoggerTag__c = matchedId;
      }
    }
    return matchRecord;
  }

  private void enqueueAsyncDispatches(List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches) {
    if (dispatches.isEmpty()) {
      return;
    }
    // TODO uhhhh reenqueue, don't return
    // TODO Pre-inserted PENDING delivery records are permanently orphaned when the queueable governor limit is already at max
    /*
      In enqueueAsyncDispatches, when System.Limits.getQueueableJobs() >= getLimitQueueableJobs(), the method logs a warning and returns early.
      At this point LoggerNotificationDelivery__c records with Status__c = 'Pending' have already been committed to the database (inserted earlier in sendNotifications).
      Those records will remain stuck in the Pending state indefinitely — there is no scheduled retry, no platform event, and no background mechanism to re-attempt the dispatch.
      Admins will see records that appear to be in-flight but will never be delivered.
      At minimum, update the stuck deliveries to Failed before returning so the data reflects reality.
    */
    if (System.Limits.getQueueableJobs() >= System.Limits.getLimitQueueableJobs()) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('Nebula Logger Notifications - queueable limit reached, skipping ' + dispatches.size() + ' async notifier dispatch(es)');
      }
      return;
    }
    LoggerDataStore.getJobQueue().enqueueJob(new LoggerNotificationAsyncDispatcher(dispatches));
  }

  private Boolean shouldSuppressForThreshold(LoggerNotificationRule__c rule, Integer currentMatchCount) {
    // TODO I hate all of this logic
    if (rule.IsMatchThresholdEnabled__c == false || rule.MatchCountThreshold__c == null || rule.MatchCountThreshold__c <= 0) {
      return false;
    }

    Integer priorMatchCount = this.countPriorMatchesInWindow(rule);
    return (priorMatchCount + currentMatchCount) < (Integer) rule.MatchCountThreshold__c;
  }

  private Integer countPriorMatchesInWindow(LoggerNotificationRule__c rule) {
    if (
      rule.MatchThresholdTimePeriodIncrement__c == null ||
      rule.MatchThresholdTimePeriodIncrement__c <= 0 ||
      String.isBlank(rule.MatchThresholdTimePeriodUnit__c)
    ) {
      return 0;
    }

    Datetime cutoff = computeCutoff(System.now(), (Integer) rule.MatchThresholdTimePeriodIncrement__c, rule.MatchThresholdTimePeriodUnit__c);
    if (cutoff == null) {
      return 0;
    }

    return [
      SELECT COUNT()
      FROM LoggerNotificationMatch__c
      WHERE LoggerNotificationRule__c = :rule.Id AND CreatedDate >= :cutoff
      WITH SYSTEM_MODE
    ];
  }

  private static Datetime computeCutoff(Datetime now, Integer increment, String unit) {
    switch on unit {
      when 'Minutes' {
        return now.addMinutes(-increment);
      }
      when 'Hours' {
        return now.addHours(-increment);
      }
      when 'Days' {
        return now.addDays(-increment);
      }
      when else {
        return null;
      }
    }
  }

  private static Map<String, List<LoggerNotificationRule__c>> getActiveRulesBySObjectTypeName() {
    if (cachedRulesBySObjectTypeName != null) {
      return cachedRulesBySObjectTypeName;
    }

    List<LoggerNotificationRule__c> rules = [
      SELECT
        Comments__c,
        DeduplicationSourceField__c,
        Id,
        IsDeliveryHistoryEnabled__c,
        IsEnabled__c,
        IsMatchHistoryEnabled__c,
        IsMatchThresholdEnabled__c,
        IsOriginOrganizationIdValid__c,
        MatchCountThreshold__c,
        MatchThresholdTimePeriodIncrement__c,
        MatchThresholdTimePeriodUnit__c,
        Name,
        NumberOfDaysToRetainDeliveries__c,
        NumberOfDaysToRetainMatches__c,
        SourceSObjectFilter__c,
        SourceSObjectType__c,
        TotalEnabledRecipients__c,
        (
          SELECT
            ChannelIdentifier__c,
            ConfigurationJson__c,
            EmailAddress__c,
            Id,
            LoggerNotificationService__c,
            LoggerNotificationService__r.IsEnabled__c,
            LoggerNotificationService__r.NamedCredentialDeveloperName__c,
            LoggerNotificationService__r.Name,
            LoggerNotificationService__r.NotifierApexClassName__c,
            LoggerNotificationService__r.OriginOrganizationId__c,
            LoggerNotificationService__r.WebhookUrl__c,
            User__c
          FROM LoggerNotificationRecipients__r
          WHERE IsEnabled__c = TRUE AND LoggerNotificationService__r.IsEnabled__c = TRUE AND LoggerNotificationService__r.IsOriginOrganizationIdValid__c = TRUE
        )
      FROM LoggerNotificationRule__c
      WHERE IsEnabled__c = TRUE AND IsOriginOrganizationIdValid__c = TRUE AND TotalEnabledRecipients__c > 0
      WITH SYSTEM_MODE
      ORDER BY Name ASC
    ];
    cachedRulesBySObjectTypeName = bucketBySObjectTypeName(rules);

    return cachedRulesBySObjectTypeName;
  }

  private static Map<String, List<LoggerNotificationRule__c>> bucketBySObjectTypeName(List<LoggerNotificationRule__c> rules) {
    Map<String, List<LoggerNotificationRule__c>> bucketed = new Map<String, List<LoggerNotificationRule__c>>();
    for (LoggerNotificationRule__c rule : rules) {
      Schema.SObjectType resolvedSObjectType = LoggerNotificationRuleHandler.resolveSObjectType(rule.SourceSObjectType__c);

      if (resolvedSObjectType == null) {
        continue;
      }

      String sobjectApiName = resolvedSObjectType.toString();
      if (bucketed.containsKey(sobjectApiName) == false) {
        bucketed.put(sobjectApiName, new List<LoggerNotificationRule__c>());
      }
      bucketed.get(sobjectApiName).add(rule);
    }
    return bucketed;
  }

  private class RuleEvaluation {
    private LoggerNotificationRule__c rule;
    private List<SObject> matchingRecords;
    private List<LoggerNotificationMatch__c> matches;
    private Boolean shouldDispatch;
  }

  private class RuleFilterEvaluator {
    private final Map<String, FormulaEval.FormulaInstance> cachedInstances = new Map<String, FormulaEval.FormulaInstance>();

    /**
     * @description Compiles every applicable rule's filter formula and returns the union of the field
     *              paths those formulas reference. Rules whose filter fails to compile contribute
     *              nothing to the union; they'll be skipped again in the per-record evaluate loop.
     *              Field paths are returned in the format `FormulaInstance.getReferencedFields()` uses
     *              (dotted relationship notation for parent lookups, e.g. `Log__r.LoggedBy__r.Username`),
     *              which is the same syntax `LoggerNotifier.requeryRecordsWithFieldPaths` expects.
     */
    public Set<String> collectReferencedFieldPaths(Schema.SObjectType sobjectType, List<LoggerNotificationRule__c> rules) {
      Set<String> referencedFieldPaths = new Set<String>();
      for (LoggerNotificationRule__c rule : rules) {
        FormulaEval.FormulaInstance formulaInstance = this.getFormulaInstance(sobjectType, rule.SourceSObjectFilter__c);

        if (formulaInstance == null) {
          continue;
        }

        Set<String> ruleFields = formulaInstance.getReferencedFields();
        if (ruleFields != null) {
          referencedFieldPaths.addAll(ruleFields);
        }
      }
      return referencedFieldPaths;
    }

    public Boolean evaluate(Schema.SObjectType sobjectType, String filter, SObject record) {
      // TODO I'm not convinced these checks are all needed - why wouldn't we have an sobjectype or record or filter?
      if (String.isBlank(filter) || sobjectType == null || record == null) {
        return false;
      }
      FormulaEval.FormulaInstance formulaInstance = this.getFormulaInstance(sobjectType, filter);
      if (formulaInstance == null) {
        return false;
      }
      try {
        Object result = formulaInstance.evaluate(record);
        return result instanceof Boolean ? (Boolean) result : false;
      } catch (System.Exception ex) {
        this.logEvaluationFailure(sobjectType, filter, ex);
        return false;
      }
    }

    public List<SObject> evaluate(Schema.SObjectType sobjectType, String filter, List<SObject> records) {
      List<SObject> matches = new List<SObject>();
      // TODO I'm not convinced these checks are all needed - why wouldn't we have an sobjectype or record or filter?
      if (String.isBlank(filter) || sobjectType == null || records == null || records.isEmpty()) {
        return matches;
      }
      FormulaEval.FormulaInstance formulaInstance = this.getFormulaInstance(sobjectType, filter);
      if (formulaInstance == null) {
        return matches;
      }
      for (SObject record : records) {
        try {
          Object result = formulaInstance.evaluate(record);
          // TODO yuck!
          if (result instanceof Boolean && (Boolean) result) {
            matches.add(record);
          }
        } catch (System.Exception ex) {
          this.logEvaluationFailure(sobjectType, filter, ex);
          // Skip this record but keep processing the rest of the batch
        }
      }
      return matches;
    }

    private FormulaEval.FormulaInstance getFormulaInstance(Schema.SObjectType sobjectType, String filter) {
      String cacheKey = sobjectType.toString() + '|' + filter;
      if (this.cachedInstances.containsKey(cacheKey)) {
        return this.cachedInstances.get(cacheKey);
      }
      FormulaEval.FormulaInstance instance;
      try {
        instance = Formula.builder().withType(sobjectType).withReturnType(FormulaEval.FormulaReturnType.BOOLEAN).withFormula(filter).build();
      } catch (System.Exception ex) {
        instance = null;
        this.logCompilationFailure(sobjectType, filter, ex);
      }
      // Cache both successes and failures (null) so we don't retry a broken filter over and over in the same transaction
      this.cachedInstances.put(cacheKey, instance);
      return instance;
    }

    // TODO get rid of these logging methods?
    private void logCompilationFailure(Schema.SObjectType sobjectType, String filter, System.Exception ex) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('Nebula Logger Notifications - failed to compile filter for ' + sobjectType + ': ' + filter, ex);
      }
    }

    private void logEvaluationFailure(Schema.SObjectType sobjectType, String filter, System.Exception ex) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('Nebula Logger Notifications - failed to evaluate filter for ' + sobjectType + ': ' + filter, ex);
      }
    }
  }
}
