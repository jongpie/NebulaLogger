@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest
private class LoggerBenchmarking_Tests {
  private static final LoggerParameter__mdt ORG_LIMIT_PARAM = new LoggerParameter__mdt(DeveloperName = 'StoreOrganizationLimits');
  private static final LoggerParameter__mdt HEAP_LIMIT_PARAM = new LoggerParameter__mdt(DeveloperName = 'StoreHeapSizeLimit');
  private static final LoggerParameter__mdt TRANSACTION_LIMIT_PARAM = new LoggerParameter__mdt(DeveloperName = 'StoreTransactionLimits');

  @IsTest
  static void it_benchmarks_while_setting_transaction_limits() {
    TRANSACTION_LIMIT_PARAM.Value__c = String.valueOf(true);
    HEAP_LIMIT_PARAM.Value__c = TRANSACTION_LIMIT_PARAM.Value__c;
    ORG_LIMIT_PARAM.Value__c = TRANSACTION_LIMIT_PARAM.Value__c;

    logForEntries(500);

    System.Assert.isTrue(true, 'Made it here without an uncatchable System.LimitException being thrown');
  }

  @IsTest
  static void it_benchmarks_without_setting_heap_limit() {
    TRANSACTION_LIMIT_PARAM.Value__c = String.valueOf(true);
    HEAP_LIMIT_PARAM.Value__c = String.valueOf(false);
    ORG_LIMIT_PARAM.Value__c = TRANSACTION_LIMIT_PARAM.Value__c;

    logForEntries(500);

    System.Assert.isTrue(true, 'Made it here without an uncatchable System.LimitException being thrown');
  }

  @IsTest
  static void it_benchmarks_without_setting_limit_info() {
    // the majority of the time it takes for Log Entries to be created is actually due to the System.Limits
    // invocations within LogEntryEventBuilder. When those calls are disabled, Logger is MUCH more performant in tests
    TRANSACTION_LIMIT_PARAM.Value__c = String.valueOf(false);
    HEAP_LIMIT_PARAM.Value__c = TRANSACTION_LIMIT_PARAM.Value__c;
    ORG_LIMIT_PARAM.Value__c = TRANSACTION_LIMIT_PARAM.Value__c;

    logForEntries(800);

    System.Assert.isTrue(true, 'Made it here without an uncatchable System.LimitException being thrown');
  }

  static void logForEntries(Integer numberOfEntries) {
    LoggerParameter.setMock(HEAP_LIMIT_PARAM);
    LoggerParameter.setMock(ORG_LIMIT_PARAM);
    LoggerParameter.setMock(TRANSACTION_LIMIT_PARAM);

    ContactPointAddress record = new ContactPointAddress(Name = 'Benchmarking');
    insert record;
    for (Integer index = 0; index < numberOfEntries; index++) {
      Logger.info('Creating complex message using arguments').setRecord(record);
    }
    Logger.saveLog();
  }
}
