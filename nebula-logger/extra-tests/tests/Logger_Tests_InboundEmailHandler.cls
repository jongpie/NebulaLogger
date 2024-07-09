//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class Logger_Tests_InboundEmailHandler {
    @IsTest
    private static void it_should_save_logs_when_running_within_email_service() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.plainTextBody = 'Example email content';
        email.fromAddress = 'test@test.com';
        email.subject = 'My example email';
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        ExampleInboundEmailHandler emailHandler = new ExampleInboundEmailHandler();
        System.Test.startTest();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        String transactionId = Logger.getTransactionId();
        System.Assert.areNotEqual(1, Logger.saveLogCallCount, 'No logging should have occurred yet');

        Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(email, envelope);

        System.Assert.areNotEqual(0, Logger.saveLogCallCount, 'ExampleInboundEmailHandler class should have logged & saved some logging data');
        System.Test.stopTest();
        System.Assert.isTrue(result.success, 'InboundEmailResult returned a failure message');
        List<Log__c> logs = [SELECT Id, TransactionId__c FROM Log__c];
        System.Assert.areEqual(1, logs.size(), 'Logs size did not match expected value of 1.');
        System.Assert.areEqual(transactionId, logs.get(0).TransactionId__c, 'Transaction Id does match expected value');
        List<LogEntry__c> logEntries = [SELECT Id, Message__c FROM LogEntry__c];
        System.Assert.areEqual(2, logEntries.size(), 'Log entries size did not match expected value of 2 ' + System.JSON.serializePretty(logEntries));
        System.Assert.areEqual(ExampleInboundEmailHandler.logEntryMessage, logEntries.get(0).Message__c, 'Log entries message did not match expected value');
    }
}
