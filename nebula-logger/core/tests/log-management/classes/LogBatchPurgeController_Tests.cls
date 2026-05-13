//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@SuppressWarnings('PMD.ApexDoc, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.MethodNamingConventions')
@IsTest(IsParallel=false)
private class LogBatchPurgeController_Tests {
  private static final String CUSTOM_PURGE_ACTION = 'Custom';
  private static final String DEFAULT_PURGE_ACTION = 'Delete';
  private static final Integer DEFAULT_RECORD_COUNT = 5;
  private static final Integer CUSTOM_RECORD_COUNT = 4;

  static {
    // Don't use the org's actual custom metadata records when running tests
    LoggerConfigurationSelector.useMocks();
  }

  @IsTest
  static void it_should_return_purge_action_options_with_delete_and_configured_custom_actions() {
    List<String> fakeLogPurgeActions = new List<String>{ 'A_FAKE_PURGE_ACTION', 'ANOTHER_ONE', 'SOME_OTHER_PURGE_ACTION' };
    for (String fakeLogPurgeAction : fakeLogPurgeActions) {
      LoggerTestConfigurator.setMock(
        new LoggerParameter__mdt(DeveloperName = LogBatchPurgeController.CUSTOM_LOG_PURGE_ACTION_PREFIX + fakeLogPurgeAction, Value__c = fakeLogPurgeAction)
      );
    }

    List<LogBatchPurgeController.PicklistOption> picklistOptions = LogBatchPurgeController.getPurgeActionOptions();

    Set<String> expectedLogPurgeActions = new Set<String>{ LogBatchPurgeController.DELETE_LOG_PURGE_ACTION };
    expectedLogPurgeActions.addAll(fakeLogPurgeActions);
    System.Assert.areEqual(
      expectedLogPurgeActions.size(),
      picklistOptions.size(),
      'Returned picklist option count should match configured purge actions + Delete'
    );
    for (LogBatchPurgeController.PicklistOption picklistOption : picklistOptions) {
      System.Assert.areEqual(picklistOption.value, picklistOption.label, 'Picklist option label should equal value');
      System.Assert.isTrue(expectedLogPurgeActions.contains(picklistOption.value), 'Unexpected purge action returned: ' + picklistOption.value);
    }
  }

  @IsTest
  static void it_should_return_log_summary_for_today_filter() {
    runLogSummaryTest('TODAY');
  }

  @IsTest
  static void it_should_return_log_summary_for_this_week_filter() {
    runLogSummaryTest('THIS_WEEK');
  }

  @IsTest
  static void it_should_return_log_summary_for_this_month_filter() {
    runLogSummaryTest('THIS_MONTH');
  }

  @IsTest
  static void it_should_return_log_entry_summary_for_today_filter() {
    runLogEntrySummaryTest('TODAY');
  }

  @IsTest
  static void it_should_return_log_entry_summary_for_this_week_filter() {
    runLogEntrySummaryTest('THIS_WEEK');
  }

  @IsTest
  static void it_should_return_log_entry_summary_for_this_month_filter() {
    runLogEntrySummaryTest('THIS_MONTH');
  }

  @IsTest
  static void it_should_return_log_entry_tag_summary_for_today_filter() {
    runLogEntryTagSummaryTest('TODAY');
  }

  @IsTest
  static void it_should_return_log_entry_tag_summary_for_this_week_filter() {
    runLogEntryTagSummaryTest('THIS_WEEK');
  }

  @IsTest
  static void it_should_return_log_entry_tag_summary_for_this_month_filter() {
    runLogEntryTagSummaryTest('THIS_MONTH');
  }

  private static void runLogSummaryTest(String dateFilterOption) {
    // System.today() falls within each of TODAY / THIS_WEEK / THIS_MONTH, so a single
    // retention date works for all three filter variants.
    createLogRecords(DEFAULT_PURGE_ACTION, DEFAULT_RECORD_COUNT, System.today());
    createLogRecords(CUSTOM_PURGE_ACTION, CUSTOM_RECORD_COUNT, System.today());

    List<AggregateResult> logObjectResult = LogBatchPurgeController.getLogObjectSummary(dateFilterOption);

    assertSummaryCounts(logObjectResult, dateFilterOption);
  }

  private static void runLogEntrySummaryTest(String dateFilterOption) {
    createLogEntryRecords(DEFAULT_PURGE_ACTION, DEFAULT_RECORD_COUNT, System.today());
    createLogEntryRecords(CUSTOM_PURGE_ACTION, CUSTOM_RECORD_COUNT, System.today());

    List<AggregateResult> logEntryObjectResult = LogBatchPurgeController.getLogEntryObjectSummary(dateFilterOption);

    assertSummaryCounts(logEntryObjectResult, dateFilterOption);
  }

  private static void runLogEntryTagSummaryTest(String dateFilterOption) {
    createLogEntryTagRecords(DEFAULT_PURGE_ACTION, DEFAULT_RECORD_COUNT, System.today());
    createLogEntryTagRecords(CUSTOM_PURGE_ACTION, CUSTOM_RECORD_COUNT, System.today());

    List<AggregateResult> logEntryTagObjectResult = LogBatchPurgeController.getLogEntryTagObjectSummary(dateFilterOption);

    assertSummaryCounts(logEntryTagObjectResult, dateFilterOption);
  }

  @IsTest
  static void it_should_return_metrics_for_all_three_objects() {
    createLogEntryTagRecords(DEFAULT_PURGE_ACTION, DEFAULT_RECORD_COUNT, System.today());
    createLogEntryTagRecords(CUSTOM_PURGE_ACTION, CUSTOM_RECORD_COUNT, System.today());

    Map<String, Object> metricsResult = LogBatchPurgeController.getMetrics('TODAY');

    System.Assert.areEqual(
      new Set<String>{ 'Log__c', 'LogEntry__c', 'LogEntryTag__c' },
      metricsResult.keySet(),
      'Metrics result should have one entry per supported object'
    );
    for (String objectApiName : metricsResult.keySet()) {
      List<AggregateResult> summary = (List<AggregateResult>) metricsResult.get(objectApiName);
      assertSummaryCounts(summary, 'TODAY');
    }
  }

  @IsTest
  static void it_should_throw_when_date_filter_option_is_not_supported() {
    try {
      LogBatchPurgeController.getMetrics('LAST_QUARTER');
      System.Assert.fail('Expected IllegalArgumentException for unsupported dateFilterOption');
    } catch (System.IllegalArgumentException ex) {
      System.Assert.isTrue(ex.getMessage().contains('LAST_QUARTER'), 'Exception message should reference the offending value');
    }
  }

  @IsTest
  static void it_should_throw_when_date_filter_option_attempts_soql_injection() {
    try {
      LogBatchPurgeController.getMetrics('TODAY OR Id != null');
      System.Assert.fail('Expected IllegalArgumentException for SOQL injection attempt');
    } catch (System.IllegalArgumentException ex) {
      System.Assert.isNotNull(ex.getMessage(), 'Exception message should not be null');
    }
  }

  @IsTest
  static void it_should_permit_user_to_execute_purge_batch_when_custom_permission_is_assigned() {
    Schema.User standardUser = createTestUser();
    assignCanExecuteLogBatchPurgerPermission(standardUser);

    System.runAs(standardUser) {
      System.Assert.isTrue(
        System.FeatureManagement.checkPermission(LogBatchPurgeController.CAN_EXECUTE_LOG_BATCH_PURGER_PERMISSION),
        'Test user should have CanExecuteLogBatchPurger custom permission'
      );
      System.Assert.isTrue(LogBatchPurgeController.canUserRunLogBatchPurger(), 'Test user should be permitted to run LogBatchPurger via custom permission');
    }
  }

  @IsTest
  static void it_should_not_permit_user_to_execute_purge_batch_when_custom_permission_is_not_assigned() {
    Schema.User standardUser = createTestUser();

    System.runAs(standardUser) {
      System.Assert.isFalse(
        System.FeatureManagement.checkPermission(LogBatchPurgeController.CAN_EXECUTE_LOG_BATCH_PURGER_PERMISSION),
        'Test user should not have CanExecuteLogBatchPurger custom permission'
      );
      System.Assert.isFalse(
        LogBatchPurgeController.canUserRunLogBatchPurger(),
        'Test user without delete access or custom permission should not be permitted to run LogBatchPurger'
      );
    }
  }

  @IsTest
  static void it_should_execute_the_purge_batch_and_return_a_job_id() {
    System.Test.startTest();
    String jobId = LogBatchPurgeController.runBatchPurge();
    System.Test.stopTest();

    System.Assert.isNotNull(jobId, 'runBatchPurge should return the queued AsyncApexJob ID');
    Schema.AsyncApexJob queuedJob = [SELECT Id, JobType FROM AsyncApexJob WHERE Id = :jobId];
    System.Assert.isNotNull(queuedJob, 'AsyncApexJob should exist for the returned job ID');
  }

  @IsTest
  static void it_should_return_purge_batch_job_records() {
    System.Test.startTest();
    LogBatchPurgeController.runBatchPurge();
    System.Test.stopTest();

    List<Schema.AsyncApexJob> purgeJobs = LogBatchPurgeController.getBatchPurgeJobRecords();

    System.Assert.areEqual(1, purgeJobs.size(), 'Exactly one LogBatchPurger job should be returned');
    Schema.AsyncApexJob job = purgeJobs.get(0);
    System.Assert.isNotNull(job.JobType, 'JobType should be populated');
    System.Assert.isNotNull(job.Status, 'Status should be populated');
    System.Assert.isNotNull(job.CreatedDate, 'CreatedDate should be populated');
    System.Assert.isNotNull(job.CreatedBy.Name, 'CreatedBy.Name should be populated');
  }

  // Helpers

  private static void assertSummaryCounts(List<AggregateResult> summary, String dateFilterOption) {
    System.Assert.areEqual(2, summary.size(), 'Summary should have one row per purge action for ' + dateFilterOption);
    Map<String, Integer> countsByPurgeAction = new Map<String, Integer>();
    for (AggregateResult row : summary) {
      countsByPurgeAction.put((String) row.get('LogPurgeAction__c'), (Integer) row.get('recordCount'));
    }
    System.Assert.areEqual(DEFAULT_RECORD_COUNT, countsByPurgeAction.get(DEFAULT_PURGE_ACTION), 'Delete count mismatch for ' + dateFilterOption);
    System.Assert.areEqual(CUSTOM_RECORD_COUNT, countsByPurgeAction.get(CUSTOM_PURGE_ACTION), 'Custom count mismatch for ' + dateFilterOption);
  }

  private static void createLogRecords(String purgeAction, Integer recordCount, Date retentionDate) {
    List<Log__c> logs = new List<Log__c>();
    for (Integer i = 0; i < recordCount; i++) {
      logs.add(new Log__c(TransactionId__c = System.UUID.randomUUID().toString(), LogPurgeAction__c = purgeAction, LogRetentionDate__c = retentionDate));
    }
    insert logs;
  }

  private static void createLogEntryRecords(String purgeAction, Integer recordCount, Date retentionDate) {
    Log__c log = new Log__c(TransactionId__c = System.UUID.randomUUID().toString(), LogPurgeAction__c = purgeAction, LogRetentionDate__c = retentionDate);
    insert log;

    List<LogEntry__c> logEntries = new List<LogEntry__c>();
    for (Integer i = 0; i < recordCount; i++) {
      LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, TransactionEntryNumber__c = i + 1);
      LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields();
      logEntries.add(logEntry);
    }
    insert logEntries;
  }

  private static void createLogEntryTagRecords(String purgeAction, Integer recordCount, Date retentionDate) {
    Log__c log = new Log__c(TransactionId__c = System.UUID.randomUUID().toString(), LogPurgeAction__c = purgeAction, LogRetentionDate__c = retentionDate);
    insert log;

    List<LogEntry__c> logEntries = new List<LogEntry__c>();
    for (Integer i = 0; i < recordCount; i++) {
      LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.INFO.name());
      LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields();
      logEntries.add(logEntry);
    }
    insert logEntries;

    String uniqueTagId = System.UUID.randomUUID().toString();
    LoggerTag__c tag = new LoggerTag__c(Name = uniqueTagId, UniqueId__c = uniqueTagId);
    LoggerMockDataCreator.createDataBuilder(tag).populateRequiredFields();
    insert tag;

    List<LogEntryTag__c> logEntryTags = new List<LogEntryTag__c>();
    for (LogEntry__c logEntry : logEntries) {
      LogEntryTag__c logEntryTag = new LogEntryTag__c(LogEntry__c = logEntry.Id, Tag__c = tag.Id);
      LoggerMockDataCreator.createDataBuilder(logEntryTag).populateRequiredFields();
      logEntryTags.add(logEntryTag);
    }
    insert logEntryTags;
  }

  private static Schema.User createTestUser() {
    Schema.Profile standardProfile = [SELECT Id FROM Profile WHERE Name IN ('Standard User', 'Usuario estándar', '標準ユーザー')];
    Schema.User standardUser = LoggerMockDataCreator.createUser(standardProfile.Id);
    insert standardUser;
    return standardUser;
  }

  private static void assignCanExecuteLogBatchPurgerPermission(Schema.User user) {
    Schema.PermissionSet permissionSet = new Schema.PermissionSet(Name = 'CanExecuteLogBatchPurger', Label = 'Custom Permission Enabled');
    insert permissionSet;
    SetupEntityAccess setupEntityAccess = new SetupEntityAccess(ParentId = permissionSet.Id, SetupEntityId = getCanExecuteLogBatchPurgerCustomPermissionId());
    Schema.PermissionSetAssignment permissionSetAssignment = new Schema.PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = permissionSet.Id);
    insert new List<SObject>{ setupEntityAccess, permissionSetAssignment };
  }

  private static Id getCanExecuteLogBatchPurgerCustomPermissionId() {
    String className = LogBatchPurgeController_Tests.class.getName();
    String namespacePrefix = className.contains('.') ? className.substringBefore('.') : null;
    return [
      SELECT Id
      FROM CustomPermission
      WHERE DeveloperName = :LogBatchPurgeController.CAN_EXECUTE_LOG_BATCH_PURGER_PERMISSION AND NamespacePrefix = :namespacePrefix
    ]
    .Id;
  }
}
