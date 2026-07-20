//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerNotificationFormController_Tests {
  static {
    // Don't use the org's actual custom metadata records when running tests
    LoggerConfigurationSelector.useMocks();
  }

  @IsTest
  static void it_should_return_notifier_types_ordered_by_display_label() {
    List<LoggerNotifierType__mdt> notifierTypes = LoggerNotificationFormController.getNotifierTypes();

    System.Assert.isTrue(notifierTypes.size() > 0, 'Expected at least one seeded LoggerNotifierType__mdt record');
    for (Integer i = 1; i < notifierTypes.size(); i++) {
      String previousLabel = notifierTypes.get(i - 1).DisplayLabel__c;
      String currentLabel = notifierTypes.get(i).DisplayLabel__c;
      System.Assert.isTrue(
        previousLabel <= currentLabel,
        'Expected records ordered ascending by DisplayLabel__c but found "' + previousLabel + '" before "' + currentLabel + '"'
      );
    }
  }

  @IsTest
  static void it_should_return_null_for_blank_notifier_class_name() {
    System.Assert.isNull(LoggerNotificationFormController.getNotifierTypeForClass(null), 'Null input should return null');
    System.Assert.isNull(LoggerNotificationFormController.getNotifierTypeForClass(''), 'Empty string input should return null');
  }

  @IsTest
  static void it_should_return_notifier_type_matching_notifier_apex_class_name() {
    LoggerNotifierType__mdt notifierType = LoggerNotificationFormController.getNotifierTypeForClass('SlackLoggerNotifier');

    System.Assert.isNotNull(notifierType, 'Expected a matching LoggerNotifierType__mdt record for SlackLoggerNotifier');
    System.Assert.areEqual('SlackLoggerNotifier', notifierType.NotifierApexClassName__c);
  }

  @IsTest
  static void it_should_return_null_for_unknown_notifier_class_name() {
    System.Assert.isNull(LoggerNotificationFormController.getNotifierTypeForClass('NoSuchClassXYZ'));
  }

  @IsTest
  static void it_should_return_only_enabled_services() {
    LoggerNotificationService__c enabledService = buildValidService();
    enabledService.Name = 'Enabled Service';
    enabledService.IsEnabled__c = true;
    LoggerNotificationService__c disabledService = buildValidService();
    disabledService.Name = 'Disabled Service';
    disabledService.IsEnabled__c = false;
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationService__c>{ enabledService, disabledService });

    List<LoggerNotificationService__c> availableServices = LoggerNotificationFormController.getAvailableServices();

    Set<Id> returnedIds = new Set<Id>();
    for (LoggerNotificationService__c service : availableServices) {
      returnedIds.add(service.Id);
      System.Assert.isTrue(service.IsEnabled__c, 'getAvailableServices() should only return enabled services');
    }
    System.Assert.isTrue(returnedIds.contains(enabledService.Id), 'Enabled service should be returned');
    System.Assert.isFalse(returnedIds.contains(disabledService.Id), 'Disabled service should not be returned');
  }

  @IsTest
  static void it_should_save_rule_with_null_recipients_list() {
    LoggerNotificationRule__c rule = buildValidRule();
    rule.Name = 'Rule With Null Recipients';

    Id ruleId = LoggerNotificationFormController.saveRuleWithRecipients(rule, null);

    System.Assert.isNotNull(ruleId, 'Rule Id should have been returned');
    System.Assert.areEqual(1, [SELECT COUNT() FROM LoggerNotificationRule__c WHERE Id = :ruleId]);
    System.Assert.areEqual(0, [SELECT COUNT() FROM LoggerNotificationRecipient__c WHERE LoggerNotificationRule__c = :ruleId]);
  }

  @IsTest
  static void it_should_save_rule_with_empty_recipients_list() {
    LoggerNotificationRule__c rule = buildValidRule();
    rule.Name = 'Rule With Empty Recipients';

    Id ruleId = LoggerNotificationFormController.saveRuleWithRecipients(rule, new List<LoggerNotificationRecipient__c>());

    System.Assert.isNotNull(ruleId, 'Rule Id should have been returned');
    System.Assert.areEqual(1, [SELECT COUNT() FROM LoggerNotificationRule__c WHERE Id = :ruleId]);
    System.Assert.areEqual(0, [SELECT COUNT() FROM LoggerNotificationRecipient__c WHERE LoggerNotificationRule__c = :ruleId]);
  }

  @IsTest
  static void it_should_save_rule_with_recipients_and_stamp_parent_id() {
    LoggerNotificationService__c service = buildValidService();
    service.Name = 'Recipient Target Service';
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRule__c rule = buildValidRule();
    rule.Name = 'Rule With Recipient';
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(LoggerNotificationService__c = service.Id, IsEnabled__c = true);

    Id ruleId = LoggerNotificationFormController.saveRuleWithRecipients(rule, new List<LoggerNotificationRecipient__c>{ recipient });

    System.Assert.areEqual(rule.Id, ruleId, 'Returned Id should match the newly-inserted rule');
    LoggerNotificationRecipient__c requeriedRecipient = [
      SELECT Id, LoggerNotificationRule__c, LoggerNotificationService__c
      FROM LoggerNotificationRecipient__c
      WHERE Id = :recipient.Id
    ];
    System.Assert.areEqual(ruleId, requeriedRecipient.LoggerNotificationRule__c, 'Recipient parent Id should be stamped to the new rule');
    System.Assert.areEqual(service.Id, requeriedRecipient.LoggerNotificationService__c);
  }

  @IsTest
  static void it_should_throw_aura_handled_exception_when_rule_is_null() {
    System.AuraHandledException thrown;
    try {
      LoggerNotificationFormController.saveRuleWithRecipients(null, null);
    } catch (System.AuraHandledException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'A null rule should have thrown System.AuraHandledException');
  }

  @IsTest
  static void it_should_rollback_the_transaction_when_recipient_insert_fails() {
    LoggerNotificationRule__c rule = buildValidRule();
    rule.Name = 'Rule That Should Rollback';
    // Recipient with no LoggerNotificationService__c - the field is required so the recipient insert will fail
    LoggerNotificationRecipient__c badRecipient = new LoggerNotificationRecipient__c(IsEnabled__c = true);

    System.AuraHandledException thrown;
    try {
      LoggerNotificationFormController.saveRuleWithRecipients(rule, new List<LoggerNotificationRecipient__c>{ badRecipient });
    } catch (System.AuraHandledException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'Recipient insert failure should have thrown System.AuraHandledException');
    System.Assert.areEqual(
      0,
      [SELECT COUNT() FROM LoggerNotificationRule__c WHERE Name = 'Rule That Should Rollback'],
      'Rule insert should have been rolled back when recipient insert failed'
    );
  }

  @IsTest
  static void it_should_return_blank_sobject_type_error_when_sobject_type_name_is_null() {
    String result = LoggerNotificationFormController.validateSourceSObjectFilter(null, 'ISPICKVAL(LoggingLevel__c, \'ERROR\')');

    System.Assert.areEqual('Pick a Source SObject Type before validating the filter.', result);
  }

  @IsTest
  static void it_should_return_blank_sobject_type_error_when_sobject_type_name_is_empty() {
    String result = LoggerNotificationFormController.validateSourceSObjectFilter('', 'ISPICKVAL(LoggingLevel__c, \'ERROR\')');

    System.Assert.areEqual('Pick a Source SObject Type before validating the filter.', result);
  }

  @IsTest
  static void it_should_return_blank_filter_error_when_filter_is_empty() {
    String result = LoggerNotificationFormController.validateSourceSObjectFilter('LogEntry__c', '');

    System.Assert.areEqual('Filter cannot be blank.', result);
  }

  @IsTest
  static void it_should_return_unknown_sobject_error_when_sobject_type_name_is_unresolvable() {
    String result = LoggerNotificationFormController.validateSourceSObjectFilter('NoSuchObject__c', 'IsDeleted = FALSE');

    System.Assert.isTrue(result != null && result.contains('Unknown SObject type'), 'Expected unknown-SObject error but got: ' + result);
  }

  @IsTest
  static void it_should_return_null_when_filter_is_valid_against_source_sobject_type() {
    String result = LoggerNotificationFormController.validateSourceSObjectFilter('LogEntry__c', 'ISPICKVAL(LoggingLevel__c, \'ERROR\')');

    System.Assert.isNull(result, 'Expected null (valid) but got: ' + result);
  }

  @IsTest
  static void it_should_return_compile_error_when_filter_references_a_missing_field() {
    String result = LoggerNotificationFormController.validateSourceSObjectFilter('LogEntry__c', 'NoSuchField__c = TRUE');

    System.Assert.isNotNull(result, 'Expected a compile-error message for a missing field');
    System.Assert.isTrue(result.contains('Filter did not compile'), 'Expected the compile-error prefix but got: ' + result);
  }

  @IsTest
  static void it_should_return_null_when_getRuleWithRecipients_is_called_with_a_null_id() {
    LoggerNotificationFormController.RuleWithRecipients result = LoggerNotificationFormController.getRuleWithRecipients(null);

    System.Assert.isNull(result, 'A null Id input should return null (not throw)');
  }

  @IsTest
  static void it_should_return_the_rule_and_no_recipients_when_the_rule_has_none() {
    LoggerNotificationRule__c rule = buildValidRule();
    rule.Name = 'Rule Without Recipients';
    LoggerDataStore.getDatabase().insertRecord(rule);

    LoggerNotificationFormController.RuleWithRecipients result = LoggerNotificationFormController.getRuleWithRecipients(rule.Id);

    System.Assert.isNotNull(result, 'Expected a non-null result for an existing rule Id');
    System.Assert.areEqual(rule.Id, result.rule.Id);
    System.Assert.areEqual('Rule Without Recipients', result.rule.Name);
    System.Assert.areEqual(0, result.recipients.size(), 'Rule has no children, expected empty recipient list');
  }

  @IsTest
  static void it_should_return_the_rule_and_its_child_recipients_ordered_by_created_date() {
    LoggerNotificationService__c service = buildValidService();
    service.Name = 'Get Rule Recipients Service';
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRule__c rule = buildValidRule();
    rule.Name = 'Rule With Recipients';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationRecipient__c firstRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id,
      ChannelIdentifier__c = '#first',
      IsEnabled__c = true
    );
    LoggerNotificationRecipient__c secondRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id,
      ChannelIdentifier__c = '#second',
      IsEnabled__c = false
    );
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationRecipient__c>{ firstRecipient, secondRecipient });

    LoggerNotificationFormController.RuleWithRecipients result = LoggerNotificationFormController.getRuleWithRecipients(rule.Id);

    System.Assert.areEqual(2, result.recipients.size());
    System.Assert.areEqual(firstRecipient.Id, result.recipients.get(0).Id, 'Recipients are returned in insertion order');
    System.Assert.areEqual(secondRecipient.Id, result.recipients.get(1).Id);
    System.Assert.areEqual('#first', result.recipients.get(0).ChannelIdentifier__c);
    System.Assert.areEqual(false, result.recipients.get(1).IsEnabled__c);
  }

  @IsTest
  static void it_should_throw_when_updateRuleWithRecipients_is_called_with_a_null_rule() {
    System.AuraHandledException thrown;
    try {
      LoggerNotificationFormController.updateRuleWithRecipients(null, null, null, null);
    } catch (System.AuraHandledException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'Null rule input should have thrown System.AuraHandledException');
  }

  @IsTest
  static void it_should_throw_when_updateRuleWithRecipients_is_called_with_a_rule_that_has_no_id() {
    LoggerNotificationRule__c ruleWithoutId = buildValidRule();

    System.AuraHandledException thrown;
    try {
      LoggerNotificationFormController.updateRuleWithRecipients(ruleWithoutId, null, null, null);
    } catch (System.AuraHandledException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'Missing rule Id should have thrown System.AuraHandledException');
  }

  @IsTest
  static void it_should_update_a_rule_with_only_field_edits() {
    LoggerNotificationRule__c rule = buildValidRule();
    rule.Name = 'Rule To Edit';
    LoggerDataStore.getDatabase().insertRecord(rule);

    rule.Name = 'Rule Renamed';
    rule.Comments__c = 'New comment';
    Id returnedId = LoggerNotificationFormController.updateRuleWithRecipients(rule, null, null, null);

    System.Assert.areEqual(rule.Id, returnedId);
    LoggerNotificationRule__c requeriedRule = [SELECT Name, Comments__c FROM LoggerNotificationRule__c WHERE Id = :rule.Id];
    System.Assert.areEqual('Rule Renamed', requeriedRule.Name);
    System.Assert.areEqual('New comment', requeriedRule.Comments__c);
  }

  @IsTest
  static void it_should_insert_new_recipients_when_updateRuleWithRecipients_receives_them() {
    LoggerNotificationService__c service = buildValidService();
    service.Name = 'Insert Recipients Service';
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRule__c rule = buildValidRule();
    rule.Name = 'Rule Getting New Recipients';
    LoggerDataStore.getDatabase().insertRecord(rule);

    LoggerNotificationRecipient__c newRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationService__c = service.Id,
      ChannelIdentifier__c = '#new-channel',
      IsEnabled__c = true
    );
    LoggerNotificationFormController.updateRuleWithRecipients(rule, new List<LoggerNotificationRecipient__c>{ newRecipient }, null, null);

    List<LoggerNotificationRecipient__c> recipients = [
      SELECT Id, ChannelIdentifier__c
      FROM LoggerNotificationRecipient__c
      WHERE LoggerNotificationRule__c = :rule.Id
    ];
    System.Assert.areEqual(1, recipients.size());
    System.Assert.areEqual('#new-channel', recipients.get(0).ChannelIdentifier__c);
  }

  @IsTest
  static void it_should_update_existing_recipients_when_updateRuleWithRecipients_receives_them() {
    LoggerNotificationService__c service = buildValidService();
    service.Name = 'Update Recipients Service';
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRule__c rule = buildValidRule();
    rule.Name = 'Rule With Recipient To Update';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id,
      ChannelIdentifier__c = '#original',
      IsEnabled__c = true
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    recipient.ChannelIdentifier__c = '#renamed';
    recipient.IsEnabled__c = false;
    LoggerNotificationFormController.updateRuleWithRecipients(rule, null, new List<LoggerNotificationRecipient__c>{ recipient }, null);

    LoggerNotificationRecipient__c requeried = [SELECT ChannelIdentifier__c, IsEnabled__c FROM LoggerNotificationRecipient__c WHERE Id = :recipient.Id];
    System.Assert.areEqual('#renamed', requeried.ChannelIdentifier__c);
    System.Assert.areEqual(false, requeried.IsEnabled__c);
  }

  @IsTest
  static void it_should_delete_recipients_by_id_when_updateRuleWithRecipients_receives_recipient_ids_to_delete() {
    LoggerNotificationService__c service = buildValidService();
    service.Name = 'Delete Recipients Service';
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRule__c rule = buildValidRule();
    rule.Name = 'Rule With Recipient To Delete';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationRecipient__c toKeep = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id,
      ChannelIdentifier__c = '#keep',
      IsEnabled__c = true
    );
    LoggerNotificationRecipient__c toDelete = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id,
      ChannelIdentifier__c = '#delete',
      IsEnabled__c = true
    );
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationRecipient__c>{ toKeep, toDelete });

    LoggerNotificationFormController.updateRuleWithRecipients(rule, null, null, new List<Id>{ toDelete.Id });

    List<LoggerNotificationRecipient__c> remaining = [SELECT Id FROM LoggerNotificationRecipient__c WHERE LoggerNotificationRule__c = :rule.Id];
    System.Assert.areEqual(1, remaining.size(), 'Only the kept recipient should remain');
    System.Assert.areEqual(toKeep.Id, remaining.get(0).Id);
  }

  @IsTest
  static void it_should_process_mixed_insert_update_and_delete_operations_in_one_call() {
    LoggerNotificationService__c service = buildValidService();
    service.Name = 'Mixed Diff Service';
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRule__c rule = buildValidRule();
    rule.Name = 'Mixed Diff Rule';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationRecipient__c existingToUpdate = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id,
      ChannelIdentifier__c = '#existing',
      IsEnabled__c = true
    );
    LoggerNotificationRecipient__c existingToDelete = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id,
      ChannelIdentifier__c = '#doomed',
      IsEnabled__c = true
    );
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationRecipient__c>{ existingToUpdate, existingToDelete });

    existingToUpdate.ChannelIdentifier__c = '#existing-renamed';
    LoggerNotificationRecipient__c newRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationService__c = service.Id,
      ChannelIdentifier__c = '#new',
      IsEnabled__c = true
    );
    rule.Name = 'Mixed Diff Rule Renamed';

    LoggerNotificationFormController.updateRuleWithRecipients(
      rule,
      new List<LoggerNotificationRecipient__c>{ newRecipient },
      new List<LoggerNotificationRecipient__c>{ existingToUpdate },
      new List<Id>{ existingToDelete.Id }
    );

    LoggerNotificationRule__c requeriedRule = [SELECT Name FROM LoggerNotificationRule__c WHERE Id = :rule.Id];
    System.Assert.areEqual('Mixed Diff Rule Renamed', requeriedRule.Name);
    List<LoggerNotificationRecipient__c> recipients = [
      SELECT Id, ChannelIdentifier__c
      FROM LoggerNotificationRecipient__c
      WHERE LoggerNotificationRule__c = :rule.Id
      ORDER BY ChannelIdentifier__c ASC
    ];
    System.Assert.areEqual(2, recipients.size(), 'One deleted, one updated, one inserted -> 2 remain');
    Set<String> channelIds = new Set<String>();
    for (LoggerNotificationRecipient__c r : recipients) {
      channelIds.add(r.ChannelIdentifier__c);
    }
    System.Assert.isTrue(channelIds.contains('#existing-renamed'));
    System.Assert.isTrue(channelIds.contains('#new'));
    System.Assert.isFalse(channelIds.contains('#doomed'), 'Deleted recipient should not appear');
  }

  @IsTest
  static void it_should_rollback_the_transaction_when_updateRuleWithRecipients_hits_a_failure() {
    LoggerNotificationRule__c rule = buildValidRule();
    rule.Name = 'Rule That Should Not Change';
    LoggerDataStore.getDatabase().insertRecord(rule);

    rule.Name = 'Rule Name That Should Never Persist';
    // A recipient with no LoggerNotificationService__c fails the required-field check on insert;
    // the savepoint should roll back the rule's field edits alongside the failed recipient DML.
    LoggerNotificationRecipient__c badRecipient = new LoggerNotificationRecipient__c(IsEnabled__c = true);

    System.AuraHandledException thrown;
    try {
      LoggerNotificationFormController.updateRuleWithRecipients(rule, new List<LoggerNotificationRecipient__c>{ badRecipient }, null, null);
    } catch (System.AuraHandledException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'Recipient insert failure should have thrown System.AuraHandledException');
    LoggerNotificationRule__c requeriedRule = [SELECT Name FROM LoggerNotificationRule__c WHERE Id = :rule.Id];
    System.Assert.areEqual('Rule That Should Not Change', requeriedRule.Name, 'Rule rename should have been rolled back');
  }

  // Builds a rule that satisfies the LoggerNotificationRuleHandler validation:
  // - has a resolvable SourceSObjectType__c
  // - has a filter that both compiles and evaluates
  // - keeps the match / threshold / delivery-history flags in a legal combination
  private static LoggerNotificationRule__c buildValidRule() {
    return new LoggerNotificationRule__c(
      Name = 'Test Rule',
      SourceSObjectType__c = 'LogEntry__c',
      SourceSObjectFilter__c = 'ISPICKVAL(LoggingLevel__c, \'ERROR\')',
      IsEnabled__c = true,
      IsMatchHistoryEnabled__c = true,
      IsDeliveryHistoryEnabled__c = true,
      IsMatchThresholdEnabled__c = false
    );
  }

  // Builds a service whose NotifierApexClassName__c resolves to a real LoggerNotifier class so
  // the LoggerNotificationServiceHandler validation passes.
  private static LoggerNotificationService__c buildValidService() {
    return new LoggerNotificationService__c(Name = 'Test Service', NotifierApexClassName__c = 'SlackLoggerNotifier', IsEnabled__c = true);
  }
}
