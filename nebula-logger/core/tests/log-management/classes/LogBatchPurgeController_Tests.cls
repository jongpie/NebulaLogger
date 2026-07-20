//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@SuppressWarnings('PMD.ApexDoc, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions')
@IsTest(IsParallel=false)
private class LogBatchPurgeController_Tests {
  private static final String CUSTOM_PURGE_ACTION = 'Custom';
  private static final String DEFAULT_PURGE_ACTION = 'Delete';
  private static final String CAN_EXECUTE_LOG_BATCH_PURGER_PERMISSION = 'CanExecuteLogBatchPurger';
  private static final String CUSTOM_LOG_PURGE_ACTION_PREFIX = 'CustomLogPurgeAction';
  private static final Schema.Profile STANDARD_USER_PROFILE = [SELECT Id FROM Profile WHERE Name IN ('Standard User', 'Usuario estándar', '標準ユーザー')];

  static {
    LoggerConfigurationSelector.useMocks();
  }

  @IsTest
  static void it_should_return_logPurgeAction_options() {
    List<String> fakeLogPurgeActions = new List<String>{ 'A_FAKE_PURGE_ACTION', 'ANOTHER_ONE', 'SOME_OTHER_PURGE_ACTION' };
    for (String fakeLogPurgeAction : fakeLogPurgeActions) {
      LoggerTestConfigurator.setMock(
        new LoggerParameter__mdt(DeveloperName = CUSTOM_LOG_PURGE_ACTION_PREFIX + fakeLogPurgeAction, Value__c = fakeLogPurgeAction)
      );
    }

    List<LogBatchPurgeController.PicklistOption> picklistOptions = LogBatchPurgeController.getPurgeActionOptions();

    Set<String> expectedLogPurgeActions = new Set<String>{ DEFAULT_PURGE_ACTION };
    expectedLogPurgeActions.addAll(fakeLogPurgeActions);
    Integer expectedLogPurgeActionsSize = expectedLogPurgeActions.size();
    System.Assert.areEqual(expectedLogPurgeActionsSize, picklistOptions.size(), 'Purge Action size mismatch');
    for (LogBatchPurgeController.PicklistOption picklistOption : picklistOptions) {
      System.Assert.areEqual(picklistOption.value, picklistOption.label, 'Purge action label mismatch');
      System.Assert.isTrue(expectedLogPurgeActions.contains(picklistOption.value), 'Purge Action not found');
    }
  }

  @IsTest
  private static void it_should_include_log_object_metrics_for_today_filter() {
    Integer expectedRecordCountWithPurgeActionDelete = 5;
    Integer expectedRecordCountWithPurgeActionCustom = 4;
    createLogRecords(DEFAULT_PURGE_ACTION, expectedRecordCountWithPurgeActionDelete, System.today());
    createLogRecords(CUSTOM_PURGE_ACTION, expectedRecordCountWithPurgeActionCustom, System.today());

    Map<String, Object> metrics = LogBatchPurgeController.getMetrics('TODAY');

    Assert.isNotNull(metrics);
    assertPurgeActionCountsForKey(metrics, 'Log__c', expectedRecordCountWithPurgeActionDelete, expectedRecordCountWithPurgeActionCustom);
  }

  @IsTest
  private static void it_should_exclude_log_records_whose_retention_date_falls_outside_the_filter_range() {
    // A log created today but with a retention date set 60 days out (i.e. an admin explicitly opted the row
    // into a longer retention window) must not appear in the "TODAY" metrics panel - the metrics panel
    // shows what's actually scheduled for purge, not what happens to have been created recently.
    Integer expectedTodayCount = 3;
    createLogRecords(DEFAULT_PURGE_ACTION, expectedTodayCount, System.today());
    createLogRecords(DEFAULT_PURGE_ACTION, 7, System.today().addDays(60));

    Map<String, Object> metrics = LogBatchPurgeController.getMetrics('TODAY');

    List<AggregateResult> logResults = (List<AggregateResult>) metrics.get('Log__c');
    System.Assert.areEqual(1, logResults.size(), 'Only the rows whose retention date is today should be counted');
    System.Assert.areEqual(expectedTodayCount, logResults[0].get('expr0'), 'Only rows with retention date = TODAY should be counted');
  }

  @IsTest
  private static void it_should_exclude_rows_with_null_retention_dates() {
    // A null LogRetentionDate__c is the admin's way of saying "keep forever". Rows with a null retention
    // date must not appear in the metrics panel because they'll never be purged.
    Integer expectedCount = 2;
    createLogRecords(DEFAULT_PURGE_ACTION, expectedCount, System.today());
    List<Log__c> keepForeverLogs = new List<Log__c>();
    for (Integer index = 0; index < 4; index++) {
      Log__c log = new Log__c(TransactionId__c = System.UUID.randomUUID().toString(), LogPurgeAction__c = DEFAULT_PURGE_ACTION);
      keepForeverLogs.add(log);
    }
    insert keepForeverLogs;

    Map<String, Object> metrics = LogBatchPurgeController.getMetrics('TODAY');

    List<AggregateResult> logResults = (List<AggregateResult>) metrics.get('Log__c');
    System.Assert.areEqual(1, logResults.size(), 'Null-retention-date rows should be excluded from the aggregate');
    System.Assert.areEqual(expectedCount, logResults[0].get('expr0'), 'Null-retention-date rows should be excluded from the count');
  }

  @IsTest
  private static void it_should_include_log_entry_metrics_for_today_filter() {
    Integer expectedRecordCountWithPurgeActionDelete = 5;
    Integer expectedRecordCountWithPurgeActionCustom = 4;
    createLogEntryRecords(DEFAULT_PURGE_ACTION, expectedRecordCountWithPurgeActionDelete, System.today());
    createLogEntryRecords(CUSTOM_PURGE_ACTION, expectedRecordCountWithPurgeActionCustom, System.today());

    Map<String, Object> metrics = LogBatchPurgeController.getMetrics('TODAY');

    Assert.isNotNull(metrics);
    assertPurgeActionCountsForKey(metrics, 'LogEntry__c', expectedRecordCountWithPurgeActionDelete, expectedRecordCountWithPurgeActionCustom);
  }

  @IsTest
  private static void it_should_include_log_entry_tag_metrics_for_today_filter() {
    Integer expectedRecordCountWithPurgeActionDelete = 5;
    Integer expectedRecordCountWithPurgeActionCustom = 4;
    createLogEntryTagRecords(DEFAULT_PURGE_ACTION, expectedRecordCountWithPurgeActionDelete, System.today());
    createLogEntryTagRecords(CUSTOM_PURGE_ACTION, expectedRecordCountWithPurgeActionCustom, System.today());

    Map<String, Object> metrics = LogBatchPurgeController.getMetrics('TODAY');

    Assert.isNotNull(metrics);
    assertPurgeActionCountsForKey(metrics, 'LogEntryTag__c', expectedRecordCountWithPurgeActionDelete, expectedRecordCountWithPurgeActionCustom);
  }

  @IsTest
  private static void it_should_include_all_core_objects_for_all_time_filter() {
    // ALL_TIME returns every row scheduled to be purged, regardless of whether the retention date is
    // in the past, present, or future - only the null-retention "keep forever" opt-out is honored.
    // The earlier "<= today" cap made ALL_TIME return fewer rows than THIS_MONTH, since a row created
    // today with a 30-day retention date matched THIS_MONTH but not ALL_TIME.
    createLogRecords(DEFAULT_PURGE_ACTION, 2, System.today().addDays(-7));
    createLogRecords(DEFAULT_PURGE_ACTION, 3, System.today().addDays(7));

    Map<String, Object> metrics = LogBatchPurgeController.getMetrics('ALL_TIME');

    List<AggregateResult> logResults = (List<AggregateResult>) metrics.get('Log__c');
    System.Assert.areEqual(1, logResults.size(), 'One row per LogPurgeAction__c grouping is expected');
    System.Assert.areEqual(5, logResults[0].get('expr0'), 'ALL_TIME should count every row with a non-null retention date, past OR future');
  }

  @IsTest
  private static void it_should_reject_an_unsupported_date_filter_option() {
    try {
      LogBatchPurgeController.getMetrics('BOGUS');
      System.Assert.fail('Expected IllegalArgumentException for unsupported date filter option');
    } catch (System.IllegalArgumentException ex) {
      System.Assert.isTrue(ex.getMessage().contains('BOGUS'), 'Exception message should name the rejected value: ' + ex.getMessage());
    }
  }

  @IsTest
  private static void it_should_return_metrics_map_keyed_by_all_three_core_sobjects() {
    createLogEntryTagRecords(DEFAULT_PURGE_ACTION, 2, System.today());

    Map<String, Object> metricsResult = LogBatchPurgeController.getMetrics('TODAY');

    System.Assert.isNotNull(metricsResult.get('Log__c'), 'Log__c key should be present');
    System.Assert.isNotNull(metricsResult.get('LogEntry__c'), 'LogEntry__c key should be present');
    System.Assert.isNotNull(metricsResult.get('LogEntryTag__c'), 'LogEntryTag__c key should be present');
  }

  @IsTest
  private static void it_should_return_registered_purgeable_sobject_types() {
    // No plugin registrations are configured in the base test setup, so the list is empty. The core
    // registrar behavior is exercised in LogBatchPurger_Tests_Registrar; this test just proves the
    // controller entry point returns a well-shaped list.
    List<LogBatchPurgeController.RegisteredPurgeableSObjectType> registeredTypes = LogBatchPurgeController.getRegisteredPurgeableSObjectTypes();

    System.Assert.isNotNull(registeredTypes, 'Registered types list should never be null');
  }

  @IsTest
  static void it_should_permit_user_to_execute_purge_batch_when_custom_permission_is_assigned() {
    Schema.User standardUser = LoggerMockDataCreator.createUser(STANDARD_USER_PROFILE.Id);
    insert standardUser;
    Schema.PermissionSet permissionSet = new Schema.PermissionSet(Name = 'CanExecuteLogBatchPurger', Label = 'Custom Permisison Enabled');
    insert permissionSet;
    SetupEntityAccess setupEntityAccess = new SetupEntityAccess(ParentId = permissionSet.Id, SetupEntityId = getCanExecuteLogBatchPurgerCustomPermissionId());
    Schema.PermissionSetAssignment permissionSetAssignment = new Schema.PermissionSetAssignment(
      AssigneeId = standardUser.Id,
      PermissionSetId = permissionSet.Id
    );
    insert new List<SObject>{ setupEntityAccess, permissionSetAssignment };

    System.runAs(standardUser) {
      System.Assert.isTrue(
        System.FeatureManagement.checkPermission(CAN_EXECUTE_LOG_BATCH_PURGER_PERMISSION),
        System.JSON.serializePretty(permissionSetAssignment)
      );
      System.Assert.areEqual(
        true,
        LogBatchPurgeController.canUserRunLogBatchPurger(),
        'it did not allow user to execute purge batch when custom permission assigned'
      );
    }
  }

  @IsTest
  private static void it_should_return_purge_batch_job_records() {
    System.Test.startTest();
    LogBatchPurgeController.runBatchPurge();
    System.Test.stopTest();
    List<Schema.AsyncApexJob> purgeJobs = LogBatchPurgeController.getBatchPurgeJobRecords();
    System.Assert.areEqual(1, purgeJobs.size(), 'should return purge batch job records');
    for (Schema.AsyncApexJob job : purgeJobs) {
      System.Assert.isNotNull(job.JobType, 'it should return job type');
      System.Assert.isNotNull(job.JobItemsProcessed, 'it should return JobItemsProcessed');
      System.Assert.isNotNull(job.NumberOfErrors, 'it should return noOfErrors');
      System.Assert.isNotNull(job.Status, 'it should return JobStatus');
      System.Assert.isNotNull(job.CreatedDate, 'it should return job CreatedDate');
      System.Assert.isNotNull(job.CreatedBy.Name, 'it should return job CreatedBy.Name');
    }
  }

  @IsTest
  static void it_should_not_permit_user_to_execute_purge_batch_when_custom_permission_is_not_assigned() {
    Schema.User standardUser = LoggerMockDataCreator.createUser(STANDARD_USER_PROFILE.Id);
    insert standardUser;
    Schema.PermissionSet permissionSet = new Schema.PermissionSet(Name = 'CanExecuteLogBatchPurger', Label = 'Custom Permisison Enabled');
    insert permissionSet;
    SetupEntityAccess setupEntityAccess = new SetupEntityAccess(ParentId = permissionSet.Id, SetupEntityId = getCanExecuteLogBatchPurgerCustomPermissionId());
    insert new List<SObject>{ setupEntityAccess };

    System.runAs(standardUser) {
      System.Assert.isFalse(System.FeatureManagement.checkPermission(CAN_EXECUTE_LOG_BATCH_PURGER_PERMISSION), 'permission set assigned');
      System.Assert.areEqual(
        false,
        LogBatchPurgeController.canUserRunLogBatchPurger(),
        'it did allow user to execute purge batch when custom permission is not assigned'
      );
    }
  }

  @IsTest
  private static void it_should_execute_the_purge_batch() {
    System.Test.startTest();
    String jobId = LogBatchPurgeController.runBatchPurge();
    System.Test.stopTest();

    String apexClassNamespacePrefix = LogBatchPurger.class.getName().contains('.') ? LogBatchPurger.class.getName().substringBefore('.') : null;
    String apexClassName = LogBatchPurger.class.getName().contains('.') ? LogBatchPurger.class.getName().substringAfter('.') : LogBatchPurger.class.getName();
    List<Schema.AsyncApexJob> purgeBatchJobs = [
      SELECT Id
      FROM AsyncApexJob
      WHERE
        JobType IN ('ScheduledApex', 'BatchApex', 'BatchApexWorker')
        AND ApexClass.NamespacePrefix = :apexClassNamespacePrefix
        AND ApexClass.Name = :apexClassName
        AND Id = :jobId
    ];
    System.Assert.areEqual(1, purgeBatchJobs.size(), 'should execute the purge batch job');
  }

  private static void assertPurgeActionCountsForKey(
    Map<String, Object> metrics,
    String sobjectApiName,
    Integer expectedDeleteCount,
    Integer expectedCustomCount
  ) {
    List<AggregateResult> results = (List<AggregateResult>) metrics.get(sobjectApiName);
    System.Assert.areEqual(2, results.size(), sobjectApiName + ' should return one aggregate row per LogPurgeAction__c value');
    for (AggregateResult summary : results) {
      if (summary.get('LogPurgeAction__c') === DEFAULT_PURGE_ACTION) {
        System.Assert.areEqual(expectedDeleteCount, summary.get('expr0'), sobjectApiName + ' delete count mismatch');
      }
      if (summary.get('LogPurgeAction__c') === CUSTOM_PURGE_ACTION) {
        System.Assert.areEqual(expectedCustomCount, summary.get('expr0'), sobjectApiName + ' custom count mismatch');
      }
    }
  }

  private static void createLogRecords(String purgeAction, Integer noOfRecords, Date retentionDate) {
    List<Log__c> logs = new List<Log__c>();
    for (Integer index = 1; index <= noOfRecords; index++) {
      Log__c log = new Log__c(TransactionId__c = System.UUID.randomUUID().toString());
      log.LogPurgeAction__c = purgeAction;
      log.LogRetentionDate__c = retentionDate;
      logs.add(log);
    }
    insert logs;
  }

  private static void createLogEntryRecords(String purgeAction, Integer noOfRecords, Date retentionDate) {
    Log__c log = new Log__c(TransactionId__c = System.UUID.randomUUID().toString());
    log.LogPurgeAction__c = purgeAction;
    log.LogRetentionDate__c = retentionDate;
    insert log;
    List<LogEntry__c> logEntries = new List<LogEntry__c>();
    for (Integer index = 1; index <= noOfRecords; index++) {
      LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, TransactionEntryNumber__c = index + 1);
      LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields();
      logEntries.add(logEntry);
    }
    insert logEntries;
  }

  private static void createLogEntryTagRecords(String purgeAction, Integer noOfRecords, Date retentionDate) {
    Log__c log = new Log__c(TransactionId__c = System.UUID.randomUUID().toString());
    log.LogPurgeAction__c = purgeAction;
    log.LogRetentionDate__c = retentionDate;
    insert log;

    List<LogEntry__c> logEntries = new List<LogEntry__c>();
    for (Integer index = 0; index < noOfRecords; index++) {
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

  private static Id getCanExecuteLogBatchPurgerCustomPermissionId() {
    String className = LogBatchPurgeController_Tests.class.getName();
    String namespacePrefix = className.contains('.') ? className.substringBefore('.') : null;
    return [SELECT Id FROM CustomPermission WHERE DeveloperName = :CAN_EXECUTE_LOG_BATCH_PURGER_PERMISSION AND NamespacePrefix = :namespacePrefix].Id;
  }
}
