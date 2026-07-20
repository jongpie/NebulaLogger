//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerNotificationRuleHandler_Tests {
  static {
    // Don't use the org's actual custom metadata records when running tests
    LoggerConfigurationSelector.useMocks();
  }

  @IsTest
  static void it_should_return_the_loggerNotification_sobjectType() {
    System.Assert.areEqual(Schema.LoggerNotificationRule__c.SObjectType, new LoggerNotificationRuleHandler().getSObjectType());
  }

  @IsTest
  static void it_should_stamp_origin_organization_id_on_insert() {
    LoggerNotificationRule__c notificationRule = buildValidNotification();
    notificationRule.OriginOrganizationId__c = null;

    LoggerDataStore.getDatabase().insertRecord(notificationRule);

    LoggerNotificationRule__c requeriedNotification = [
      SELECT Id, OriginOrganizationId__c, IsOriginOrganizationIdValid__c
      FROM LoggerNotificationRule__c
      WHERE Id = :notificationRule.Id
    ];
    System.Assert.areEqual(System.UserInfo.getOrganizationId(), requeriedNotification.OriginOrganizationId__c);
    System.Assert.isTrue(requeriedNotification.IsOriginOrganizationIdValid__c, 'IsOriginOrganizationIdValid__c should be true after insert in the current org');
  }

  @IsTest
  static void it_should_overwrite_origin_organization_id_supplied_on_insert() {
    String otherOrganizationId = LoggerMockDataCreator.createId(Schema.Organization.SObjectType);
    LoggerNotificationRule__c notificationRule = buildValidNotification();
    notificationRule.OriginOrganizationId__c = otherOrganizationId;

    LoggerDataStore.getDatabase().insertRecord(notificationRule);

    LoggerNotificationRule__c requeriedNotification = [SELECT Id, OriginOrganizationId__c FROM LoggerNotificationRule__c WHERE Id = :notificationRule.Id];
    System.Assert.areEqual(
      System.UserInfo.getOrganizationId(),
      requeriedNotification.OriginOrganizationId__c,
      'Handler should have overwritten the supplied org id'
    );
  }

  @IsTest
  static void it_should_reject_a_rule_whose_filter_cannot_be_compiled() {
    LoggerNotificationRule__c notificationRule = buildValidNotification();
    notificationRule.SourceSObjectType__c = 'LogEntry__c';
    notificationRule.SourceSObjectFilter__c = 'this is not a valid formula (((';

    System.DmlException thrown;
    try {
      LoggerDataStore.getDatabase().insertRecord(notificationRule);
    } catch (System.DmlException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'A malformed filter should have blocked the insert');
    System.Assert.isTrue(
      thrown.getMessage().contains('Filter did not compile'),
      'Error message should identify the compilation failure: ' + thrown.getMessage()
    );
  }

  @IsTest
  static void it_should_reject_a_rule_that_uses_equals_against_a_picklist_field() {
    // `=` comparison against a picklist field is not supported by Salesforce's formula engine.
    // Depending on org, the failure surfaces at compile time or at evaluate time - either way, the
    // handler should block the save so the admin never persists a rule that would fail at runtime.
    LoggerNotificationRule__c notificationRule = buildValidNotification();
    notificationRule.SourceSObjectType__c = 'LogEntry__c';
    notificationRule.SourceSObjectFilter__c = 'LoggingLevel__c = \'ERROR\'';

    System.DmlException thrown;
    try {
      LoggerDataStore.getDatabase().insertRecord(notificationRule);
    } catch (System.DmlException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'A picklist = filter should have blocked the insert');
    String message = thrown.getMessage();
    System.Assert.isTrue(
      message.contains('Filter did not compile') || message.contains('Filter did not evaluate'),
      'Error message should surface the compile or evaluate failure: ' + message
    );
  }

  @IsTest
  static void it_should_accept_a_rule_with_a_valid_filter() {
    LoggerNotificationRule__c notificationRule = buildValidNotification();
    notificationRule.SourceSObjectType__c = 'LogEntry__c';
    notificationRule.SourceSObjectFilter__c = 'ISPICKVAL(LoggingLevel__c, \'ERROR\')';

    LoggerDataStore.getDatabase().insertRecord(notificationRule);

    LoggerNotificationRule__c requeried = [SELECT Id, SourceSObjectFilter__c FROM LoggerNotificationRule__c WHERE Id = :notificationRule.Id];
    System.Assert.areEqual('ISPICKVAL(LoggingLevel__c, \'ERROR\')', requeried.SourceSObjectFilter__c);
  }

  @IsTest
  static void it_should_skip_validation_when_filter_is_blank() {
    LoggerNotificationRule__c notificationRule = buildValidNotification();
    notificationRule.SourceSObjectType__c = 'LogEntry__c';
    notificationRule.SourceSObjectFilter__c = null;

    LoggerDataStore.getDatabase().insertRecord(notificationRule);

    System.Assert.areEqual(1, [SELECT COUNT() FROM LoggerNotificationRule__c WHERE Id = :notificationRule.Id]);
  }

  @IsTest
  static void it_should_resolve_the_source_sobject_type_by_local_name() {
    System.Assert.areEqual(Schema.LogEntry__c.SObjectType, LoggerNotificationRuleHandler.resolveSObjectType('LogEntry__c'));
    System.Assert.areEqual(Schema.Log__c.SObjectType, LoggerNotificationRuleHandler.resolveSObjectType('Log__c'));
    System.Assert.areEqual(Schema.LoggerScenario__c.SObjectType, LoggerNotificationRuleHandler.resolveSObjectType('LoggerScenario__c'));
    System.Assert.areEqual(Schema.LogEntryTag__c.SObjectType, LoggerNotificationRuleHandler.resolveSObjectType('LogEntryTag__c'));
  }

  @IsTest
  static void it_should_return_null_for_a_blank_source_sobject_type_name() {
    System.Assert.isNull(LoggerNotificationRuleHandler.resolveSObjectType(null));
    System.Assert.isNull(LoggerNotificationRuleHandler.resolveSObjectType(''));
    System.Assert.isNull(LoggerNotificationRuleHandler.resolveSObjectType('   '));
  }

  @IsTest
  static void it_should_return_null_for_an_unresolvable_source_sobject_type_name() {
    System.Assert.isNull(LoggerNotificationRuleHandler.resolveSObjectType('NoSuchObject__c'));
  }

  @IsTest
  static void it_should_skip_revalidation_on_update_when_filter_and_source_are_unchanged() {
    // Save with a valid filter, then update an unrelated field. The unchanged filter should not be re-validated.
    LoggerNotificationRule__c notificationRule = buildValidNotification();
    notificationRule.SourceSObjectType__c = 'LogEntry__c';
    notificationRule.SourceSObjectFilter__c = 'ISPICKVAL(LoggingLevel__c, \'ERROR\')';
    LoggerDataStore.getDatabase().insertRecord(notificationRule);

    notificationRule.Comments__c = 'unrelated tweak';
    LoggerDataStore.getDatabase().updateRecord(notificationRule);

    System.Assert.areEqual('unrelated tweak', [SELECT Comments__c FROM LoggerNotificationRule__c WHERE Id = :notificationRule.Id].Comments__c);
  }

  @IsTest
  static void it_should_reject_a_deduplication_source_field_that_does_not_exist_on_the_source_sobject() {
    LoggerNotificationRule__c notificationRule = buildValidNotification();
    notificationRule.SourceSObjectType__c = 'LogEntry__c';
    notificationRule.SourceSObjectFilter__c = 'ISPICKVAL(LoggingLevel__c, \'ERROR\')';
    notificationRule.DeduplicationSourceField__c = 'ThisFieldDoesNotExist__c';

    System.DmlException thrown;
    try {
      LoggerDataStore.getDatabase().insertRecord(notificationRule);
    } catch (System.DmlException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'A bogus deduplication field should have blocked the insert');
    System.Assert.isTrue(
      thrown.getMessage().contains('ThisFieldDoesNotExist__c') && thrown.getMessage().contains('does not exist'),
      'Error message should identify the missing field: ' + thrown.getMessage()
    );
  }

  @IsTest
  static void it_should_accept_a_deduplication_source_field_that_exists_on_the_source_sobject() {
    LoggerNotificationRule__c notificationRule = buildValidNotification();
    notificationRule.SourceSObjectType__c = 'LogEntry__c';
    notificationRule.SourceSObjectFilter__c = 'ISPICKVAL(LoggingLevel__c, \'ERROR\')';
    notificationRule.DeduplicationSourceField__c = 'Log__c';

    LoggerDataStore.getDatabase().insertRecord(notificationRule);

    LoggerNotificationRule__c requeried = [SELECT Id, DeduplicationSourceField__c FROM LoggerNotificationRule__c WHERE Id = :notificationRule.Id];
    System.Assert.areEqual('Log__c', requeried.DeduplicationSourceField__c);
  }

  @IsTest
  static void it_should_skip_deduplication_field_validation_when_the_field_is_blank() {
    LoggerNotificationRule__c notificationRule = buildValidNotification();
    notificationRule.SourceSObjectType__c = 'LogEntry__c';
    notificationRule.SourceSObjectFilter__c = 'ISPICKVAL(LoggingLevel__c, \'ERROR\')';
    notificationRule.DeduplicationSourceField__c = null;

    LoggerDataStore.getDatabase().insertRecord(notificationRule);

    LoggerNotificationRule__c requeried = [SELECT Id, DeduplicationSourceField__c FROM LoggerNotificationRule__c WHERE Id = :notificationRule.Id];
    System.Assert.isNull(requeried.DeduplicationSourceField__c);
  }

  @IsTest
  static void it_should_not_re_stamp_origin_organization_id_on_update() {
    // OriginOrganizationId__c is intentionally stamped only on insert. A rule cloned into a refreshed
    // sandbox carries the source org's id and stays flagged as invalid until an admin explicitly re-saves
    // it (which is a hard delete + insert in the admin UI). A regular update must leave the field alone.
    LoggerNotificationRule__c notificationRule = buildValidNotification();
    LoggerDataStore.getDatabase().insertRecord(notificationRule);
    // Simulate a record that was cloned in from another org - overwrite the field post-insert via DML that bypasses the trigger
    LoggerSObjectHandler.shouldExecute(false);
    Id foreignOrgId = LoggerMockDataCreator.createId(Schema.Organization.SObjectType);
    notificationRule.OriginOrganizationId__c = foreignOrgId;
    LoggerDataStore.getDatabase().updateRecord(notificationRule);
    LoggerSObjectHandler.shouldExecute(true);

    notificationRule.Comments__c = 'triggering an update';
    LoggerDataStore.getDatabase().updateRecord(notificationRule);

    LoggerNotificationRule__c afterUpdate = [
      SELECT Id, OriginOrganizationId__c, IsOriginOrganizationIdValid__c
      FROM LoggerNotificationRule__c
      WHERE Id = :notificationRule.Id
    ];
    System.Assert.areEqual(foreignOrgId, afterUpdate.OriginOrganizationId__c, 'Update should not have re-stamped the origin org id');
    System.Assert.isFalse(afterUpdate.IsOriginOrganizationIdValid__c, 'Formula should still evaluate to false against the foreign org id');
  }

  // LoggerMockDataCreator.populateRequiredFields() inverts boolean default values on purpose (to prove
  // the field was intentionally set), so it would end up with IsMatchHistoryEnabled__c = FALSE and
  // IsMatchThresholdEnabled__c = TRUE - which trips the "threshold requires match history" validation
  // rule. Reset those flags to their real defaults after the builder runs.
  @IsTest
  static void it_should_reject_a_rule_whose_delivery_retention_exceeds_match_retention() {
    // Delivery rows are master-detail children of match rows - a deleted match cascades its deliveries
    // with it, so a delivery retention longer than match retention would never take effect. Handler
    // blocks the save with a field-level error rather than let admins persist an ineffective config.
    LoggerNotificationRule__c notificationRule = buildValidNotification();
    notificationRule.NumberOfDaysToRetainMatches__c = 14;
    notificationRule.NumberOfDaysToRetainDeliveries__c = 30;

    System.DmlException thrown;
    try {
      LoggerDataStore.getDatabase().insertRecord(notificationRule);
    } catch (System.DmlException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'A delivery-retention > match-retention config should be rejected');
    System.Assert.isTrue(
      thrown.getMessage().contains('cannot be greater than Days to Retain Matches'),
      'Error message should identify the retention constraint: ' + thrown.getMessage()
    );
  }

  @IsTest
  static void it_should_allow_delivery_retention_equal_to_match_retention() {
    // Boundary case: the check is `> `, not `>=`, so identical values on both sides are legal.
    LoggerNotificationRule__c notificationRule = buildValidNotification();
    notificationRule.NumberOfDaysToRetainMatches__c = 14;
    notificationRule.NumberOfDaysToRetainDeliveries__c = 14;

    LoggerDataStore.getDatabase().insertRecord(notificationRule);

    LoggerNotificationRule__c requeried = [
      SELECT Id, NumberOfDaysToRetainMatches__c, NumberOfDaysToRetainDeliveries__c
      FROM LoggerNotificationRule__c
      WHERE Id = :notificationRule.Id
    ];
    System.Assert.areEqual(14, requeried.NumberOfDaysToRetainMatches__c);
    System.Assert.areEqual(14, requeried.NumberOfDaysToRetainDeliveries__c);
  }

  @IsTest
  static void it_should_allow_a_null_match_or_delivery_retention_value() {
    // A null on either side means "keep forever" for that object. If matches never age out, delivery
    // rows (whether retained forever or on a fixed schedule) also never get cascade-deleted before
    // their retention date, so the constraint doesn't apply.
    LoggerNotificationRule__c ruleWithNullMatches = buildValidNotification();
    ruleWithNullMatches.NumberOfDaysToRetainMatches__c = null;
    ruleWithNullMatches.NumberOfDaysToRetainDeliveries__c = 30;

    LoggerDataStore.getDatabase().insertRecord(ruleWithNullMatches);

    LoggerNotificationRule__c ruleWithNullDeliveries = buildValidNotification();
    ruleWithNullDeliveries.NumberOfDaysToRetainMatches__c = 30;
    ruleWithNullDeliveries.NumberOfDaysToRetainDeliveries__c = null;

    LoggerDataStore.getDatabase().insertRecord(ruleWithNullDeliveries);

    System.Assert.isNotNull(ruleWithNullMatches.Id, 'Null match retention should allow any (or null) delivery retention value');
    System.Assert.isNotNull(ruleWithNullDeliveries.Id, 'Null delivery retention should be accepted alongside any match retention value');
  }

  @IsTest
  static void it_should_reject_an_update_that_raises_delivery_retention_above_match_retention() {
    LoggerNotificationRule__c notificationRule = buildValidNotification();
    notificationRule.NumberOfDaysToRetainMatches__c = 30;
    notificationRule.NumberOfDaysToRetainDeliveries__c = 14;
    LoggerDataStore.getDatabase().insertRecord(notificationRule);

    notificationRule.NumberOfDaysToRetainDeliveries__c = 60;
    System.DmlException thrown;
    try {
      LoggerDataStore.getDatabase().updateRecord(notificationRule);
    } catch (System.DmlException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'An update that raises delivery retention above match retention should be rejected');
    System.Assert.isTrue(
      thrown.getMessage().contains('cannot be greater than Days to Retain Matches'),
      'Error message should identify the retention constraint: ' + thrown.getMessage()
    );
  }

  private static LoggerNotificationRule__c buildValidNotification() {
    LoggerNotificationRule__c notificationRule = (LoggerNotificationRule__c) LoggerMockDataCreator.createDataBuilder(
        Schema.LoggerNotificationRule__c.SObjectType
      )
      .populateRequiredFields()
      .getRecord();
    notificationRule.IsMatchHistoryEnabled__c = true;
    notificationRule.IsDeliveryHistoryEnabled__c = true;
    notificationRule.IsMatchThresholdEnabled__c = false;
    return notificationRule;
  }
}
