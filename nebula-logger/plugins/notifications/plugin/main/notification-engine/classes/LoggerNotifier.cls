//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description The runtime for the notifications plugin. Evaluates active `LoggerNotificationRule__c` rules
 *              against inbound records (LogEntry__c / Log__c / LoggerScenario__c / LogEntryTag__c / LoggerTag__c,
 *              depending on the rule's `SourceSObjectType__c`), optionally persists `LoggerNotificationMatch__c`
 *              rows (one per matched source record) and `LoggerNotificationDelivery__c` rows (one per
 *              (match, recipient) tuple), and dispatches to each recipient's configured `LoggerNotifiable`
 *              implementation.
 *
 *              Storage is controlled per-rule by `IsMatchHistoryEnabled__c` and `IsDeliveryHistoryEnabled__c`.
 *              Dispatch is not affected by these flags - a rule with both flags OFF still fires its
 *              notifiers, it just leaves no persistent trail.
 *
 *              Delivery rows carry the outcome of each notifier invocation - status, HTTP details, external
 *              reference, error message. Synchronous notifiers are invoked before the delivery row is
 *              inserted so its final status is baked in on insert. Callout-required notifiers are invoked
 *              from the async dispatcher, which updates the pending delivery row on completion.
 *
 *              Rules with `IsOriginOrganizationIdValid__c = FALSE` are ignored so that rules cloned into a
 *              refreshed sandbox from another org do not fire until an admin re-saves them in the current org.
 */
public virtual without sharing class LoggerNotifier {
  @TestVisible
  private static final String CACHE_KEY_ACTIVE_RULES = 'LoggerNotificationRules';
  @TestVisible
  private static final Boolean USE_PLATFORM_CACHE = LoggerParameter.getBoolean('NotificationsUsePlatformCache', true);

  @TestVisible
  private static Map<String, List<LoggerNotificationRule__c>> cachedRulesBySObjectTypeName;
  @TestVisible
  private static RuleFilterEvaluator filterEvaluatorOverride;

  private final RuleFilterEvaluator filterEvaluator;

  /**
   * @description Default constructor.
   */
  public LoggerNotifier() {
    this.filterEvaluator = filterEvaluatorOverride != null ? filterEvaluatorOverride : new RuleFilterEvaluator();
  }

  /**
   * @description Entry point invoked by the trigger-side integration. Loads active rules for the given
   *              SObject type, filters `records` against each rule's `SourceSObjectFilter__c`, records matches and
   *              deliveries (based on the rule's history flags), and dispatches each matched
   *              rule/recipient to its notifier class.
   * @param sobjectType The SObject type of `records`.
   * @param records The inbound records to evaluate.
   */
  public virtual void sendNotifications(Schema.SObjectType sobjectType, List<SObject> records) {
    if (sobjectType == null || records == null || records.isEmpty()) {
      return;
    }
    String sobjectTypeName = sobjectType.toString();
    List<LoggerNotificationRule__c> applicableRules = getActiveRulesBySObjectTypeName().get(sobjectTypeName);
    if (applicableRules == null || applicableRules.isEmpty()) {
      return;
    }

    List<RuleWorkItem> workItems = this.buildWorkItems(applicableRules, records, sobjectType, sobjectTypeName);
    List<LoggerNotificationMatch__c> matchesToInsert = collectMatchesToInsert(workItems);
    LoggerDataStore.getDatabase().insertRecords(matchesToInsert);
    List<LoggerNotificationDelivery__c> deliveriesToInsert = new List<LoggerNotificationDelivery__c>();
    List<LoggerNotifierAsyncDispatcher.PendingDispatch> asyncDispatches = new List<LoggerNotifierAsyncDispatcher.PendingDispatch>();
    for (RuleWorkItem work : workItems) {
      if (work.shouldDispatch) {
        this.dispatchToRecipients(work, deliveriesToInsert, asyncDispatches);
      } else {
        this.buildSuppressedDeliveries(work, deliveriesToInsert);
      }
    }
    LoggerDataStore.getDatabase().insertRecords(deliveriesToInsert);
    this.updateAsyncDispatchDeliveryIds(asyncDispatches);
    this.enqueueAsyncDispatches(asyncDispatches);
  }

  private List<RuleWorkItem> buildWorkItems(
    List<LoggerNotificationRule__c> applicableRules,
    List<SObject> records,
    Schema.SObjectType sobjectType,
    String sobjectTypeName
  ) {
    List<RuleWorkItem> items = new List<RuleWorkItem>();
    for (LoggerNotificationRule__c rule : applicableRules) {
      List<SObject> matchingRecords = this.filterEvaluator.evaluate(sobjectType, rule.SourceSObjectFilter__c, records);
      if (matchingRecords.isEmpty()) {
        continue;
      }
      matchingRecords = deduplicateMatchingRecords(matchingRecords, rule.DeduplicationSourceField__c);
      RuleWorkItem work = new RuleWorkItem();
      work.rule = rule;
      work.matchingRecords = matchingRecords;
      work.shouldDispatch = this.shouldSuppressForThreshold(rule, matchingRecords.size()) == false;
      // Only persist match rows for rules that were loaded from the database. Rules that were hydrated
      // in memory (e.g. tests using LoggerNotifier.setCachedRules with a non-inserted rule) still get
      // dispatched, but skip DML because the required master-detail parent isn't set.
      if (rule.Id != null && rule.IsMatchHistoryEnabled__c == true) {
        work.matches = new List<LoggerNotificationMatch__c>();
        for (SObject match : matchingRecords) {
          work.matches.add(this.buildMatchRow(rule, sobjectType, sobjectTypeName, match));
        }
      }
      items.add(work);
    }
    return items;
  }

  /**
   * @description Collapses matching records to at most one entry per unique value of `deduplicationSourceField`,
   *              preserving the first-seen order. Records whose deduplication field value is null form their own
   *              group keyed on the sentinel string `<null>`. If `deduplicationSourceField` is blank the records
   *              are returned untouched; if the field does not exist on the source SObject each record
   *              gets its own group (i.e. no deduplication happens - safe fallback rather than throwing).
   */
  @TestVisible
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

  private static List<LoggerNotificationMatch__c> collectMatchesToInsert(List<RuleWorkItem> workItems) {
    List<LoggerNotificationMatch__c> all = new List<LoggerNotificationMatch__c>();
    for (RuleWorkItem work : workItems) {
      if (work.matches != null) {
        all.addAll(work.matches);
      }
    }
    // After matches are inserted (by caller), record their Ids on the work item for delivery FK use.
    return all;
  }

  private void dispatchToRecipients(
    RuleWorkItem work,
    List<LoggerNotificationDelivery__c> deliveriesToInsert,
    List<LoggerNotifierAsyncDispatcher.PendingDispatch> asyncDispatches
  ) {
    LoggerNotificationRule__c rule = work.rule;
    if (rule.LoggerNotificationRecipients__r == null || rule.LoggerNotificationRecipients__r.isEmpty()) {
      return;
    }
    // Every recipient goes through the async dispatcher, regardless of whether the notifier
    // makes HTTP callouts. Triggers can't call out at all, so callout-based notifiers (Slack,
    // Teams, PagerDuty, etc.) MUST go async. Non-callout notifiers (Email, CustomNotification)
    // could technically run in-trigger, but pushing them through the same async path keeps the
    // pipeline uniform, isolates notifier failures from the source-record transaction (so a
    // rolled-back LogEntry insert also cancels the pending notifications), and gives every
    // notifier its own governor limit budget instead of sharing the source trigger's.
    Boolean canPersistDeliveries = work.matches != null && rule.IsDeliveryHistoryEnabled__c == true;
    for (LoggerNotificationRecipient__c recipient : rule.LoggerNotificationRecipients__r) {
      LoggerNotificationService__c service = recipient.LoggerNotificationService__r;
      List<LoggerNotificationDelivery__c> deliveriesForRecipient = canPersistDeliveries && recipient.Id != null
        ? this.buildPendingDeliveryRows(rule, work.matches, recipient)
        : null;
      LoggerNotifierAsyncDispatcher.PendingDispatch pending = new LoggerNotifierAsyncDispatcher.PendingDispatch(rule, recipient, service, work.matchingRecords);
      pending.pendingDeliveries = deliveriesForRecipient;
      asyncDispatches.add(pending);
      if (deliveriesForRecipient != null) {
        deliveriesToInsert.addAll(deliveriesForRecipient);
      }
    }
  }

  private void buildSuppressedDeliveries(RuleWorkItem work, List<LoggerNotificationDelivery__c> deliveriesToInsert) {
    LoggerNotificationRule__c rule = work.rule;
    if (rule.LoggerNotificationRecipients__r == null || rule.LoggerNotificationRecipients__r.isEmpty()) {
      return;
    }
    if (work.matches == null || rule.IsDeliveryHistoryEnabled__c != true) {
      return;
    }
    Date retentionDate = computeRetentionDate(rule.NumberOfDaysToRetainDeliveries__c);
    for (LoggerNotificationRecipient__c recipient : rule.LoggerNotificationRecipients__r) {
      if (recipient.Id == null) {
        continue;
      }
      for (LoggerNotificationMatch__c match : work.matches) {
        LoggerNotificationDelivery__c delivery = new LoggerNotificationDelivery__c(
          LoggerNotificationRule__c = rule.Id,
          LoggerNotificationMatch__c = match.Id,
          LoggerNotificationRecipient__c = recipient.Id,
          LoggerNotificationService__c = recipient.LoggerNotificationService__c,
          Status__c = LoggerNotifiableResult.STATUS_SUPPRESSED_BY_THRESHOLD,
          AttemptCount__c = 0,
          RetentionDate__c = retentionDate
        );
        deliveriesToInsert.add(delivery);
      }
    }
  }

  private void updateAsyncDispatchDeliveryIds(List<LoggerNotifierAsyncDispatcher.PendingDispatch> asyncDispatches) {
    for (LoggerNotifierAsyncDispatcher.PendingDispatch dispatch : asyncDispatches) {
      if (dispatch.pendingDeliveries == null || dispatch.pendingDeliveries.isEmpty()) {
        continue;
      }
      List<Id> ids = new List<Id>();
      for (LoggerNotificationDelivery__c row : dispatch.pendingDeliveries) {
        if (row.Id != null) {
          ids.add(row.Id);
        }
      }
      dispatch.pendingDeliveryIds = ids;
    }
  }

  private List<LoggerNotificationDelivery__c> buildPendingDeliveryRows(
    LoggerNotificationRule__c rule,
    List<LoggerNotificationMatch__c> matches,
    LoggerNotificationRecipient__c recipient
  ) {
    Date retentionDate = computeRetentionDate(rule.NumberOfDaysToRetainDeliveries__c);
    List<LoggerNotificationDelivery__c> rows = new List<LoggerNotificationDelivery__c>();
    for (LoggerNotificationMatch__c match : matches) {
      LoggerNotificationDelivery__c delivery = new LoggerNotificationDelivery__c(
        LoggerNotificationRule__c = rule.Id,
        LoggerNotificationMatch__c = match.Id,
        LoggerNotificationRecipient__c = recipient.Id,
        LoggerNotificationService__c = recipient.LoggerNotificationService__c,
        Status__c = LoggerNotifiableResult.STATUS_PENDING,
        AttemptCount__c = 0,
        RetentionDate__c = retentionDate
      );
      rows.add(delivery);
    }
    return rows;
  }

  /**
   * @description Copies the outcome of one notifier invocation onto every delivery row for that
   *              (rule, recipient) dispatch. Also stamps timing fields. Used by both the sync
   *              runtime and the async dispatcher.
   * @param deliveries The delivery rows to update.
   * @param result The outcome returned by the notifier (null is treated as a bare success).
   * @param dispatchStart When the notifier invocation started.
   * @param dispatchEnd When the notifier invocation returned.
   */
  public static void applyResultToDeliveries(
    List<LoggerNotificationDelivery__c> deliveries,
    LoggerNotifiableResult result,
    Datetime dispatchStart,
    Datetime dispatchEnd
  ) {
    if (deliveries == null || deliveries.isEmpty()) {
      return;
    }
    String status = result != null && String.isNotBlank(result.status) ? result.status : LoggerNotifiableResult.STATUS_DELIVERED;
    Integer httpStatusCode = result != null ? result.httpStatusCode : null;
    String httpStatusReason = result != null ? result.httpStatusReason : null;
    String responseBody = result != null ? result.responseBody : null;
    String responseHeaders = result != null ? result.responseHeaders : null;
    String errorMessage = result != null ? result.errorMessage : null;
    String errorStackTrace = result != null ? result.errorStackTrace : null;
    String externalReferenceId = result != null ? result.externalReferenceId : null;
    String externalReferenceUrl = result != null ? result.externalReferenceUrl : null;
    String requestUrl = result != null ? truncateForRow(result.requestUrl, 1300) : null;
    String requestMethod = result != null ? truncateForRow(result.requestMethod, 10) : null;
    String requestBody = result != null ? truncateForRow(result.requestBody, 32768) : null;
    String requestHeaders = result != null ? truncateForRow(result.requestHeaders, 32768) : null;
    Id jobId = result != null ? result.jobId : null;
    Long durationMs = dispatchStart != null && dispatchEnd != null ? (dispatchEnd.getTime() - dispatchStart.getTime()) : null;
    for (LoggerNotificationDelivery__c row : deliveries) {
      row.Status__c = status;
      row.HttpStatusCode__c = httpStatusCode;
      row.HttpStatusReason__c = httpStatusReason;
      row.ResponseBody__c = responseBody;
      row.ResponseHeaders__c = responseHeaders;
      row.ErrorMessage__c = errorMessage;
      row.ErrorStackTrace__c = errorStackTrace;
      row.ExternalReferenceId__c = externalReferenceId;
      row.ExternalReferenceUrl__c = externalReferenceUrl;
      row.RequestUrl__c = requestUrl;
      row.RequestMethod__c = requestMethod;
      row.RequestBody__c = requestBody;
      row.RequestHeaders__c = requestHeaders;
      row.DispatchTimestamp__c = dispatchStart;
      row.CompletedTimestamp__c = dispatchEnd;
      row.DurationMilliseconds__c = durationMs;
      row.AttemptCount__c = (row.AttemptCount__c == null ? 0 : row.AttemptCount__c) + 1;
      if (jobId != null && String.isBlank(row.JobId__c)) {
        row.JobId__c = jobId;
      }
    }
  }

  private static String truncateForRow(String value, Integer maxLength) {
    if (value == null || value.length() <= maxLength) {
      return value;
    }
    return value.substring(0, maxLength - 15) + '...(truncated)';
  }

  /**
   * @description Computes the `RetentionDate__c` value stamped onto a match or delivery row from the
   *              rule's per-object retention field. A null / non-positive value means "keep the row
   *              forever" - LogBatchPurger's WHERE clauses skip rows whose RetentionDate__c is null,
   *              so leaving it blank is the way an admin opts a rule's history out of automatic purging.
   *              Match rows use `NumberOfDaysToRetainMatches__c`; delivery rows use
   *              `NumberOfDaysToRetainDeliveries__c`.
   */
  private static Date computeRetentionDate(Decimal daysToRetain) {
    if (daysToRetain == null || daysToRetain <= 0) {
      return null;
    }
    return System.today().addDays(daysToRetain.intValue());
  }

  @TestVisible
  private LoggerNotificationMatch__c buildMatchRow(LoggerNotificationRule__c rule, Schema.SObjectType sobjectType, String sobjectTypeName, SObject matched) {
    Id matchedId = (Id) matched.get('Id');
    LoggerNotificationMatch__c row = new LoggerNotificationMatch__c(
      LoggerNotificationRule__c = rule.Id,
      MatchedRecordId__c = matchedId == null ? null : String.valueOf(matchedId),
      MatchedSObjectType__c = sobjectTypeName,
      RetentionDate__c = computeRetentionDate(rule.NumberOfDaysToRetainMatches__c)
    );
    if (sobjectType == Schema.LogEntry__c.SObjectType) {
      row.LogEntry__c = matchedId;
    } else if (sobjectType == Schema.LogEntryTag__c.SObjectType) {
      row.LogEntryTag__c = matchedId;
    } else if (sobjectType == Schema.Log__c.SObjectType) {
      row.Log__c = matchedId;
    } else if (sobjectType == Schema.LoggerScenario__c.SObjectType) {
      row.LoggerScenario__c = matchedId;
    } else if (sobjectType == Schema.LoggerTag__c.SObjectType) {
      row.LoggerTag__c = matchedId;
    }
    return row;
  }

  private void enqueueAsyncDispatches(List<LoggerNotifierAsyncDispatcher.PendingDispatch> dispatches) {
    if (dispatches.isEmpty()) {
      return;
    }
    if (System.Limits.getQueueableJobs() >= System.Limits.getLimitQueueableJobs()) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('Nebula Logger Notifications - queueable limit reached, skipping ' + dispatches.size() + ' async notifier dispatch(es)');
      }
      return;
    }
    LoggerDataStore.getJobQueue().enqueueJob(new LoggerNotifierAsyncDispatcher(dispatches));
  }

  private Boolean shouldSuppressForThreshold(LoggerNotificationRule__c rule, Integer currentMatchCount) {
    if (rule.IsMatchThresholdEnabled__c != true) {
      return false;
    }
    if (rule.MatchCountThreshold__c == null || rule.MatchCountThreshold__c <= 0) {
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
    ];
  }

  @TestVisible
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

    if (USE_PLATFORM_CACHE && LoggerCache.getOrganizationCache().contains(CACHE_KEY_ACTIVE_RULES)) {
      cachedRulesBySObjectTypeName = (Map<String, List<LoggerNotificationRule__c>>) LoggerCache.getOrganizationCache().get(CACHE_KEY_ACTIVE_RULES);
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
      ORDER BY Name ASC
    ];
    cachedRulesBySObjectTypeName = bucketBySObjectTypeName(rules);

    if (USE_PLATFORM_CACHE) {
      LoggerCache.getOrganizationCache().put(CACHE_KEY_ACTIVE_RULES, cachedRulesBySObjectTypeName);
    }

    return cachedRulesBySObjectTypeName;
  }

  private static Map<String, List<LoggerNotificationRule__c>> bucketBySObjectTypeName(List<LoggerNotificationRule__c> rules) {
    Map<String, List<LoggerNotificationRule__c>> bucketed = new Map<String, List<LoggerNotificationRule__c>>();
    for (LoggerNotificationRule__c rule : rules) {
      Schema.SObjectType resolved = LoggerNotificationRuleHandler.resolveSObjectType(rule.SourceSObjectType__c);
      if (resolved == null) {
        continue;
      }
      String key = resolved.toString();
      if (bucketed.containsKey(key) == false) {
        bucketed.put(key, new List<LoggerNotificationRule__c>());
      }
      bucketed.get(key).add(rule);
    }
    return bucketed;
  }

  @TestVisible
  private static void setCachedRules(List<LoggerNotificationRule__c> rules) {
    cachedRulesBySObjectTypeName = bucketBySObjectTypeName(rules);
  }

  private class RuleWorkItem {
    private LoggerNotificationRule__c rule;
    private List<SObject> matchingRecords;
    private List<LoggerNotificationMatch__c> matches;
    private Boolean shouldDispatch;
  }

  /**
   * @description Compiles and evaluates a `LoggerNotificationRule__c.SourceSObjectFilter__c` formula expression against records of
   *              the rule's `SourceSObjectType__c`. Wraps Salesforce's `FormulaEval.FormulaBuilder` API and caches
   *              compiled formulas per (SObjectType, formula) pair so repeated evaluations in the same transaction
   *              do not recompile.
   */
  @TestVisible
  private class RuleFilterEvaluator {
    @TestVisible
    private final Map<String, FormulaEval.FormulaInstance> cachedInstances = new Map<String, FormulaEval.FormulaInstance>();

    public Boolean evaluate(Schema.SObjectType sobjectType, String filter, SObject record) {
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
