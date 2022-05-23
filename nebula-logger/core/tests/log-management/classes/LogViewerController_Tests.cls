//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LogViewerController_Tests {
    @TestSetup
    static void setupData() {
        LoggerSObjectHandler.shouldExecute(false);
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        List<LogEntry__c> logEntries = new List<LogEntry__c>();
        for (Integer i = 0; i < 5; i++) {
            logEntries.add(new LogEntry__c(Log__c = log.Id, Message__c = 'some message, number ' + i));
        }
        insert logEntries;
    }

    @IsTest
    static void it_should_return_log_when_id_provided() {
        Log__c log = [SELECT Id, TransactionId__c FROM Log__c];

        Log__c returnedLog = LogViewerController.getLog(log.Id);

        System.assertEquals(log.Id, returnedLog.Id);
    }
}
