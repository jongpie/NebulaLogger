//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.MethodNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts')
@IsTest(IsParallel=true)
private class LogBatchApexErrorEventHandler_Tests implements Database.Batchable<SObject>, Database.RaisesPlatformEvents {
    private enum Phase {
        START,
        EXECUTE,
        FINISH
    }

    private final Phase throwLocation;

    @IsTest
    static void it_should_create_log_when_batch_job_throws_in_start_method() {
        runTestForPhase(Phase.START);
    }

    @IsTest
    static void it_should_create_log_when_batch_job_throws_in_execute_method() {
        // need an account for the query to actually hand records off to the "execute" method
        insert new Account(Name = LogBatchApexErrorEventHandler_Tests.class.getName());
        runTestForPhase(Phase.EXECUTE);
    }

    @IsTest
    static void it_should_create_log_when_batch_job_throws_in_finish_method() {
        runTestForPhase(Phase.FINISH);
    }

    @SuppressWarnings('PMD.EmptyCatchBlock')
    private static void runTestForPhase(Phase phase) {
        LoggerParameter__mdt mockParam = new LoggerParameter__mdt();
        mockParam.Value__c = LogBatchApexErrorEventHandler_Tests.class.getName();
        mockParam.DeveloperName = LogBatchApexErrorEventHandler.BATCH_ERROR_LOGGER + 'Test';
        LoggerParameter.setMock(mockParam);
        try {
            Test.startTest();
            Database.executeBatch(new LogBatchApexErrorEventHandler_Tests(phase));
            Test.stopTest();
        } catch (Exception ex) {
            // via https://salesforce.stackexchange.com/questions/263419/testing-batchapexerrorevent-trigger
        }
        // at this point, we're still two async-levels deep into Platform Event-land; we need to call "deliver()" twice
        Test.getEventBus().deliver(); // fires the platform event for Database.RaisesPlatformEvents
        Test.getEventBus().deliver(); // fires the logger's platform event

        assertLogWasCreatedForPhase(phase);
    }

    private static void assertLogWasCreatedForPhase(Phase phase) {
        Log__c logEntry = getLog();
        System.assertNotEquals(null, logEntry, 'Log should have been created!');
        System.assertEquals(2, logEntry.LogEntries__r.size(), 'Two log entries should have been created');
        System.assertEquals('Batch job terminated unexpectedly', logEntry.LogEntries__r[0].Message__c);
        System.assertEquals(
            String.format(
                    LogBatchApexErrorEventHandler.LOG_MESSAGE,
                    new List<String>{ 'someId', 'System.IllegalArgumentException', phase.name(), phase.name(), 'stacktrace' }
                )
                .subStringAfter('with')
                .substringBefore('Stacktrace:'),
            logEntry.LogEntries__r[1].Message__c.substringAfter('with').substringBefore('Stacktrace:')
        );
    }

    /**
     * the `BatchApexErrorEvent` type has a property, `Phase` with three possible values:
     * - START
     * - EXECUTE
     * - FINISH
     */
    public LogBatchApexErrorEventHandler_Tests(Phase throwLocation) {
        this.throwLocation = throwLocation;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        throwOnLocationMatch(Phase.START);
        return Database.getQueryLocator([SELECT Id FROM Account LIMIT 1]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        throwOnLocationMatch(Phase.EXECUTE);
    }

    public void finish(Database.BatchableContext bc) {
        throwOnLocationMatch(Phase.FINISH);
    }

    private void throwOnLocationMatch(Phase phase) {
        if (this.throwLocation == phase) {
            throw new IllegalArgumentException(this.throwLocation.name());
        }
    }

    private static Log__c getLog() {
        return [SELECT Id, (SELECT Message__c FROM LogEntries__r) FROM Log__c];
    }
}
