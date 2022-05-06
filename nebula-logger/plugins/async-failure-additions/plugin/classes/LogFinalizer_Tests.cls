//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LogFinalizer_Tests {
    private static final String EXPECTED_ERROR_MESSAGE = 'Gack';
    @IsTest
    static void it_should_not_log_on_queueable_success() {
        Test.startTest();
        System.enqueueJob(new ExampleQueueable());
        Test.stopTest();
        Test.getEventBus().deliver();

        System.assertEquals(0, [SELECT COUNT() FROM Log__c], 'Should not log if no errors');
    }

    @IsTest
    static void it_should_log_on_queueable_error() {
        try {
            Test.startTest();
            System.enqueueJob(new ExampleFailedQueueable());
            Test.stopTest();
        } catch (Exception ex) {
            System.assertEquals(EXPECTED_ERROR_MESSAGE, ex.getMessage());
        }
        Test.getEventBus().deliver();

        List<LogEntry__c> logEntries = [SELECT Message__c, ExceptionMessage__c FROM LogEntry__c];
        System.assertEquals(2, logEntries.size(), 'Should log for errors');
        LogEntry__c firstEntry = logEntries.get(0);
        System.assertEquals('There was an error during this queueable job', firstEntry.Message__c);
        LogEntry__c secondEntry = logEntries.get(1);
        System.assertEquals('Error details', secondEntry.Message__c);
        System.assertEquals(EXPECTED_ERROR_MESSAGE, secondEntry.ExceptionMessage__c);
    }

    private virtual class ExampleQueueable implements System.Queueable {
        public void execute(System.QueueableContext qc) {
            System.attachFinalizer(new LogFinalizer());
            this.innerExecute();
        }

        @SuppressWarnings('PMD.EmptyStatementBlock')
        protected virtual void innerExecute() {
        }
    }

    private virtual class ExampleFailedQueueable extends ExampleQueueable {
        protected override void innerExecute() {
            throw new IllegalArgumentException(EXPECTED_ERROR_MESSAGE);
        }
    }
}
