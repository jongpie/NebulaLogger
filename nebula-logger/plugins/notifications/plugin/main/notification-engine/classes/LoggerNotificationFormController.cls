//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description AuraEnabled bridge for the guided-form LWCs. Reads `LoggerNotifierType__mdt` records
 *              (so LWCs can render notifier-driven field visibility and setup guidance), and looks
 *              up the CMDT record for an existing service so the guided Edit path can pre-populate
 *              its picker.
 *
 *              CMDT queries are Apex-side because Salesforce doesn't offer a wire adapter for
 *              arbitrary CMDT SOQL. DML is left to `lightning-record-edit-form` inside the LWC so
 *              this controller stays read-only.
 */
public with sharing class LoggerNotificationFormController {
  /**
   * @description Returns every `LoggerNotifierType__mdt` record ordered by display label - the
   *              guided Service form uses this to populate the notifier picker.
   * @return All CMDT records, alphabetized by `DisplayLabel__c`.
   */
  @AuraEnabled(cacheable=true)
  public static List<LoggerNotifierType__mdt> getNotifierTypes() {
    return [
      SELECT
        AtLeastOneRequiredRecipientFields__c,
        AtLeastOneRequiredServiceFields__c,
        Description__c,
        DeveloperName,
        DisplayLabel__c,
        IsChannelIdentifierRequired__c,
        IsEmailAddressRequired__c,
        IsEnabled__c,
        IsUserRequired__c,
        NotifierApexClassName__c,
        SetupGuidanceMarkdown__c,
        SuggestedConfigurationJson__c,
        SupportsChannelIdentifier__c,
        SupportsEmailAddress__c,
        SupportsNamedCredential__c,
        SupportsUser__c,
        SupportsWebhookUrl__c
      FROM LoggerNotifierType__mdt
      WHERE IsEnabled__c = TRUE
      WITH SYSTEM_MODE
      ORDER BY DisplayLabel__c ASC
    ];
  }

  /**
   * @description Looks up the CMDT record matching a service's `NotifierApexClassName__c`. Returns
   *              null when no matching record exists (which is legal - custom notifiers may ship
   *              without CMDT records and still work at runtime, they just don't get guided-form
   *              treatment).
   * @param  notifierApexClassName The `NotifierApexClassName__c` value from the service record.
   * @return                       The matching CMDT record, or null.
   */
  @AuraEnabled(cacheable=true)
  public static LoggerNotifierType__mdt getNotifierTypeForClass(String notifierApexClassName) {
    if (String.isBlank(notifierApexClassName)) {
      return null;
    }
    List<LoggerNotifierType__mdt> matches = [
      SELECT
        AtLeastOneRequiredRecipientFields__c,
        AtLeastOneRequiredServiceFields__c,
        Description__c,
        DeveloperName,
        DisplayLabel__c,
        IsChannelIdentifierRequired__c,
        IsEmailAddressRequired__c,
        IsEnabled__c,
        IsUserRequired__c,
        NotifierApexClassName__c,
        SetupGuidanceMarkdown__c,
        SuggestedConfigurationJson__c,
        SupportsChannelIdentifier__c,
        SupportsEmailAddress__c,
        SupportsNamedCredential__c,
        SupportsUser__c,
        SupportsWebhookUrl__c
      FROM LoggerNotifierType__mdt
      WHERE IsEnabled__c = TRUE AND NotifierApexClassName__c = :notifierApexClassName
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    return matches.isEmpty() ? null : matches.get(0);
  }

  /**
   * @description Returns every enabled `LoggerNotificationService__c` record, ordered by name, for
   *              the guided Rule form's Recipients step. Each entry carries the `NotifierApexClassName__c`
   *              so the LWC can pair it with a `LoggerNotifierType__mdt` record on the client side and
   *              show only the recipient fields the notifier supports.
   * @return Enabled service records only - disabled services aren't offered as recipient targets.
   */
  /**
   * @description Returns the API names of accessible fields on the given SObject, ordered alphabetically.
   *              Used by the guided Rule form's Deduplication Source Field dropdown so admins pick from real
   *              fields on the picked Source SObject Type instead of typing a field name manually. Only
   *              direct fields (not dotted parent-relationship paths) are returned, matching what
   *              `LoggerNotificationProcessor.deduplicateMatchingRecords` supports at runtime.
   * @param  sobjectTypeName Local name of the SObject (e.g. `LogEntry__c`). Namespace-prefixed input is
   *                         accepted too.
   * @return                 Field API names, or an empty list if the type can't be resolved.
   */
  @AuraEnabled(cacheable=true)
  public static List<FieldOption> getFieldsForSObject(String sobjectTypeName) {
    List<FieldOption> options = new List<FieldOption>();
    if (String.isBlank(sobjectTypeName)) {
      return options;
    }
    Schema.SObjectType sobjectType = LoggerNotificationRuleHandler.resolveSObjectType(sobjectTypeName);
    if (sobjectType == null) {
      return options;
    }
    Map<String, Schema.SObjectField> fieldsByName = sobjectType.getDescribe().fields.getMap();
    List<String> fieldApiNames = new List<String>(fieldsByName.keySet());
    fieldApiNames.sort();
    for (String fieldApiName : fieldApiNames) {
      Schema.DescribeFieldResult describe = fieldsByName.get(fieldApiName).getDescribe();
      if (describe.isAccessible() == false) {
        continue;
      }
      FieldOption option = new FieldOption();
      option.apiName = describe.getName();
      option.label = describe.getLabel();
      options.add(option);
    }
    return options;
  }

  /**
   * @description Small DTO for the field-option dropdown. Kept explicit so `@wire`d LWCs get typed
   *              access without deserializing raw `Schema.DescribeFieldResult` blobs.
   */
  public class FieldOption {
    @AuraEnabled
    public String apiName;
    @AuraEnabled
    public String label;
  }

  /**
   * @description Validates a `LoggerNotificationRule__c.SourceSObjectFilter__c` formula expression against a
   *              source SObject type. Returns `null` when the filter compiles and evaluates cleanly against a
   *              bare record; otherwise returns a human-readable error message. Used by the guided rule form's
   *              Filter step so admins hit the same validation before advancing that the before-save trigger
   *              would apply on save - catches typos and unsupported comparisons up-front, rather than at the
   *              end of the wizard.
   * @param  sobjectTypeName Local name of the source SObject (e.g. `LogEntry__c`). Namespace-prefixed input is
   *                         accepted too.
   * @param  filter          The formula expression to validate.
   * @return                 `null` when the filter is valid; otherwise an error message. Also returns an error
   *                         when `sobjectTypeName` can't be resolved to an SObject type.
   */
  @AuraEnabled(cacheable=false)
  public static String validateSourceSObjectFilter(String sobjectTypeName, String filter) {
    if (String.isBlank(sobjectTypeName)) {
      return 'Pick a Source SObject Type before validating the filter.';
    }
    if (String.isBlank(filter)) {
      return 'Filter cannot be blank.';
    }
    Schema.SObjectType sourceType = LoggerNotificationRuleHandler.resolveSObjectType(sobjectTypeName);
    if (sourceType == null) {
      return 'Unknown SObject type: ' + sobjectTypeName;
    }
    return LoggerNotificationRuleHandler.validateFilter(sourceType, filter);
  }

  @AuraEnabled(cacheable=true)
  public static List<LoggerNotificationService__c> getAvailableServices() {
    return [
      SELECT Id, IsEnabled__c, Name, NotifierApexClassName__c
      FROM LoggerNotificationService__c
      WHERE IsEnabled__c = TRUE
      WITH USER_MODE
      ORDER BY Name ASC
    ];
  }

  /**
   * @description Inserts a `LoggerNotificationRule__c` rule and its child `LoggerNotificationRecipient__c`
   *              records atomically. The rule inserts first, its new Id is stamped on each recipient
   *              (the MD parent is required and cannot be set via a nested DML in one call), then the
   *              recipients insert. Any DML failure rolls back the whole transaction so admins never
   *              end up with an orphaned rule.
   * @param  rule       The rule to insert. Should be a `LoggerNotificationRule__c` with no Id set.
   * @param  recipients A list of `LoggerNotificationRecipient__c` records to associate with the new
   *                    rule. Each will have its `LoggerNotificationRule__c` field set to the newly-created
   *                    rule's Id before insert.
   * @return            The inserted rule's Id.
   */
  @AuraEnabled
  public static Id saveRuleWithRecipients(LoggerNotificationRule__c rule, List<LoggerNotificationRecipient__c> recipients) {
    if (rule == null) {
      throw new System.AuraHandledException('A rule is required.');
    }
    System.Savepoint savepoint = System.Database.setSavepoint();
    try {
      LoggerDataStore.getDatabase().insertRecord(rule);
      if (recipients != null) {
        for (LoggerNotificationRecipient__c recipient : recipients) {
          recipient.LoggerNotificationRule__c = rule.Id;
        }
        LoggerDataStore.getDatabase().insertRecords(recipients);
      }
      return rule.Id;
    } catch (System.Exception ex) {
      System.Database.rollback(savepoint);
      // See the update path below for why we set the message on the exception explicitly rather
      // than relying on the constructor: Salesforce hides the message by default.
      System.AuraHandledException auraException = new System.AuraHandledException(ex.getMessage());
      auraException.setMessage(ex.getMessage());
      throw auraException;
    }
  }

  /**
   * @description Loads a `LoggerNotificationRule__c` and its child `LoggerNotificationRecipient__c` records
   *              so the guided rule form's Edit mode can prefill state. Returns null if the rule Id doesn't
   *              exist (the LWC surfaces a friendly error rather than a raw AuraHandledException in that case).
   * @param  ruleId The Id of the rule to load.
   * @return        A `RuleWithRecipients` DTO carrying the rule + its recipients, or null if not found.
   */
  @AuraEnabled(cacheable=false)
  public static RuleWithRecipients getRuleWithRecipients(Id ruleId) {
    if (ruleId == null) {
      return null;
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
        MatchCountThreshold__c,
        MatchThresholdTimePeriodIncrement__c,
        MatchThresholdTimePeriodUnit__c,
        Name,
        NumberOfDaysToRetainDeliveries__c,
        NumberOfDaysToRetainMatches__c,
        SourceSObjectFilter__c,
        SourceSObjectType__c
      FROM LoggerNotificationRule__c
      WHERE Id = :ruleId
      WITH USER_MODE
      LIMIT 1
    ];
    if (rules.isEmpty()) {
      return null;
    }
    List<LoggerNotificationRecipient__c> recipients = [
      SELECT ChannelIdentifier__c, ConfigurationJson__c, EmailAddress__c, Id, IsEnabled__c, LoggerNotificationRule__c, LoggerNotificationService__c, User__c
      FROM LoggerNotificationRecipient__c
      WHERE LoggerNotificationRule__c = :ruleId
      WITH USER_MODE
      ORDER BY CreatedDate ASC
    ];
    RuleWithRecipients result = new RuleWithRecipients();
    result.rule = rules.get(0);
    result.recipients = recipients;
    return result;
  }

  /**
   * @description DTO carrying a `LoggerNotificationRule__c` + its child recipients back to the guided
   *              rule form's Edit mode. Explicit shape (rather than a Map<String, Object>) so the LWC gets
   *              typed access without deserializing raw SObjects.
   */
  public class RuleWithRecipients {
    @AuraEnabled
    public LoggerNotificationRule__c rule;
    @AuraEnabled
    public List<LoggerNotificationRecipient__c> recipients;
  }

  /**
   * @description Updates an existing `LoggerNotificationRule__c` and reconciles its child recipient list
   *              with the wizard's current state. The LWC computes the diff client-side and passes three
   *              explicit lists: recipients to insert (no Id yet), recipients to update (have Ids), and
   *              recipient Ids to delete. Everything runs under a single savepoint so a mid-flight failure
   *              rolls the whole edit back rather than leaving the rule partially reconciled.
   * @param  rule                  The rule with its Id populated and any field-level edits applied.
   * @param  recipientsToInsert    New recipients that don't yet exist in the org. The rule's Id is stamped
   *                               on each before insert so master-detail is satisfied in a single call.
   * @param  recipientsToUpdate    Existing recipients that changed. Each must carry its Id.
   * @param  recipientIdsToDelete  Existing recipient Ids the admin removed from the wizard.
   * @return                       The rule's Id (same as the input; returned for parity with `saveRuleWithRecipients`).
   */
  @AuraEnabled
  @SuppressWarnings('PMD.ExcessiveParameterList')
  public static Id updateRuleWithRecipients(
    LoggerNotificationRule__c rule,
    List<LoggerNotificationRecipient__c> recipientsToInsert,
    List<LoggerNotificationRecipient__c> recipientsToUpdate,
    List<Id> recipientIdsToDelete
  ) {
    System.Savepoint savepoint = System.Database.setSavepoint();
    try {
      LoggerDataStore.getDatabase().updateRecord(rule);
      if (recipientsToUpdate != null) {
        // Salesforce's master-detail FLS check fires on update when the parent field is set in the
        // in-memory record, even if the value is unchanged. Rebuild each SObject with just the Id
        // + edited fields so the parent link isn't touched at all. The record already has the
        // parent stored in the DB; a non-reparentable master-detail doesn't need to see it again
        // on update.
        List<LoggerNotificationRecipient__c> scrubbed = new List<LoggerNotificationRecipient__c>();
        for (LoggerNotificationRecipient__c recipient : recipientsToUpdate) {
          scrubbed.add(
            new LoggerNotificationRecipient__c(
              ChannelIdentifier__c = recipient.ChannelIdentifier__c,
              ConfigurationJson__c = recipient.ConfigurationJson__c,
              EmailAddress__c = recipient.EmailAddress__c,
              Id = recipient.Id,
              IsEnabled__c = recipient.IsEnabled__c,
              LoggerNotificationService__c = recipient.LoggerNotificationService__c,
              User__c = recipient.User__c
            )
          );
        }
        LoggerDataStore.getDatabase().updateRecords(scrubbed);
      }
      if (recipientsToInsert != null) {
        for (LoggerNotificationRecipient__c recipient : recipientsToInsert) {
          recipient.LoggerNotificationRule__c = rule.Id;
        }
        LoggerDataStore.getDatabase().insertRecords(recipientsToInsert);
      }
      if (recipientIdsToDelete != null && recipientIdsToDelete.isEmpty() == false) {
        // Query first + delete concrete records so a stale Id (recipient was already deleted elsewhere)
        // fails loudly rather than silently succeeding. Using a `delete` on Ids skips the existence
        // check the trigger layer would otherwise apply. The `.isEmpty()` guard is here to skip the
        // SOQL query on the common no-deletes path, not to protect the DML (Apex treats DML on an
        // empty list as a no-op).
        List<LoggerNotificationRecipient__c> toDelete = [
          SELECT Id
          FROM LoggerNotificationRecipient__c
          WHERE Id IN :recipientIdsToDelete AND LoggerNotificationRule__c = :rule.Id
          WITH USER_MODE
        ];
        LoggerDataStore.getDatabase().deleteRecords(toDelete);
      }
      return rule.Id;
    } catch (System.Exception ex) {
      System.Database.rollback(savepoint);
      // Salesforce swallows AuraHandledException messages by default (returns "Script-thrown
      // exception" to the client). Call setMessage on the exception itself to force the real
      // message through - callers on the LWC side need the specifics to render a useful banner,
      // and the client-side already runs behind the plugin's admin permset so leaking DML detail
      // isn't a security concern.
      System.AuraHandledException auraException = new System.AuraHandledException(ex.getMessage());
      auraException.setMessage(ex.getMessage());
      throw auraException;
    }
  }
}
