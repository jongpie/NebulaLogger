@IsTest
private class LoggerBenchmarking_Tests {
    @IsTest
    static void it_benchmarks() {
        /**
        * the majority of LogEntryEventBuilder's per-log-entry-cost is due to the setting of transactional limits
        * which can be shown/measured by uncommenting the below
        **/
        // LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'StoreTransactionLimits', Value__c = JSON.serialize(false)));
        ContactPointAddress record = new ContactPointAddress(Name = 'Benchmarking');
        insert record;
        for (Integer index = 0; index < 200; index++) {
            Logger.info('Creating complex message using arguments').setRecord(record);
        }
        Logger.saveLog();

        System.Assert.isTrue('Made it here without an uncatchable System.LimitException being thrown');
    }
}