//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest
private class FlowLogEntry_Tests {
    static FlowLogEntry createFlowLogEntry() {
        FlowLogEntry flowEntry = new FlowLogEntry();
        flowEntry.flowName = 'MyFlowOrProcessBuilder';
        flowEntry.message = 'my test message';
        flowEntry.saveLog = false;

        return flowEntry;
    }

    @IsTest
    static void it_should_save_entry_when_logging_level_met() {
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        LoggingLevel flowEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowEntryLoggingLevel.ordinal());

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();

        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel.name();
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });

        System.assertEquals(1, Logger.getBufferSize());

        Logger.saveLog();
        Test.getEventBus().deliver();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginType__c, OriginLocation__c FROM LogEntry__c ORDER BY CreatedDate LIMIT 1];
        System.assertEquals(flowEntry.loggingLevelName, logEntry.LoggingLevel__c);
        System.assertEquals(flowEntry.message, logEntry.Message__c);
        System.assertEquals('Flow', logEntry.OriginType__c);
    }

    @IsTest
    static void it_should_auto_save_entry_when_saveLog_is_true() {
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        LoggingLevel flowEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowEntryLoggingLevel.ordinal());

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();

        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel.name();
        flowEntry.saveLog = true;
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        Test.getEventBus().deliver();

        Test.stopTest();

        LogEntry__c logEntry = [
            SELECT Id, LoggingLevel__c, Message__c, OriginType__c, OriginLocation__c, RecordId__c, RecordJson__c
            FROM LogEntry__c
            ORDER BY CreatedDate
            LIMIT 1
        ];
        System.assertEquals(flowEntry.loggingLevelName, logEntry.LoggingLevel__c);
        System.assertEquals(flowEntry.message, logEntry.Message__c);
        System.assertEquals('Flow', logEntry.OriginType__c);
    }

    @IsTest
    static void it_should_auto_save_entry_with_save_method_when_saveMethodName_specified() {
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        LoggingLevel flowEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowEntryLoggingLevel.ordinal());

        Test.startTest();
        System.assertEquals(0, Limits.getQueueableJobs(), 'Test should start with 0 queueable jobs used');

        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();

        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel.name();
        flowEntry.saveLog = true;
        flowEntry.saveMethodName = Logger.SaveMethod.QUEUEABLE.name();
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        Test.getEventBus().deliver();

        System.assertEquals(1, Limits.getQueueableJobs(), 'Log entries should have been saved using the QUEUEABLE save method');
        Test.stopTest();

        LogEntry__c logEntry = [
            SELECT Id, LoggingLevel__c, Message__c, OriginType__c, OriginLocation__c, RecordId__c, RecordJson__c
            FROM LogEntry__c
            ORDER BY CreatedDate
            LIMIT 1
        ];
        System.assertEquals(flowEntry.loggingLevelName, logEntry.LoggingLevel__c);
        System.assertEquals(flowEntry.message, logEntry.Message__c);
        System.assertEquals('Flow', logEntry.OriginType__c);
    }

    @IsTest
    static void it_should_not_save_entry_when_logging_level_not_met() {
        LoggingLevel userLoggingLevel = LoggingLevel.ERROR;
        LoggingLevel flowEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() > flowEntryLoggingLevel.ordinal());

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();

        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel.name();
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        Test.getEventBus().deliver();

        System.assertEquals(0, Logger.getBufferSize());

        Test.stopTest();
    }

    @IsTest
    static void it_should_use_debug_as_default_level_when_faultMessage_is_null() {
        LoggingLevel expectedEntryLoggingLevel = LoggingLevel.DEBUG;

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = expectedEntryLoggingLevel.name();

        FlowLogEntry flowEntry = createFlowLogEntry();
        System.assertEquals(null, flowEntry.faultMessage);
        System.assertEquals(null, flowEntry.loggingLevelName);

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });

        System.assertEquals(1, Logger.getBufferSize());

        Logger.saveLog();
        Test.getEventBus().deliver();

        Test.stopTest();

        LogEntry__c logEntry = [
            SELECT Id, ExceptionMessage__c, ExceptionType__c, LoggingLevel__c, Message__c, OriginType__c, OriginLocation__c
            FROM LogEntry__c
            ORDER BY CreatedDate
            LIMIT 1
        ];
        System.assertEquals(null, logEntry.ExceptionMessage__c);
        System.assertEquals(null, logEntry.ExceptionType__c);
        System.assertEquals(expectedEntryLoggingLevel.name(), logEntry.LoggingLevel__c);
        System.assertEquals(flowEntry.message, logEntry.Message__c);
        System.assertEquals('Flow', logEntry.OriginType__c);
    }

    @IsTest
    static void it_should_use_error_as_default_level_when_faultMessage_is_not_null() {
        LoggingLevel expectedEntryLoggingLevel = LoggingLevel.ERROR;

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.FINEST.name();

        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.faultMessage = 'Whoops, a Flow error has occurred.';
        System.assertEquals(null, flowEntry.loggingLevelName);

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });

        System.assertEquals(1, Logger.getBufferSize());

        Logger.saveLog();
        Test.getEventBus().deliver();

        Test.stopTest();

        LogEntry__c logEntry = [
            SELECT Id, ExceptionMessage__c, ExceptionType__c, LoggingLevel__c, Message__c, OriginType__c, OriginLocation__c
            FROM LogEntry__c
            ORDER BY CreatedDate
            LIMIT 1
        ];
        System.assertEquals(flowEntry.faultMessage, logEntry.ExceptionMessage__c);
        System.assertEquals('Flow.FaultError', logEntry.ExceptionType__c);
        System.assertEquals(expectedEntryLoggingLevel.name(), logEntry.LoggingLevel__c);
        System.assertEquals(flowEntry.message, logEntry.Message__c);
        System.assertEquals('Flow', logEntry.OriginType__c);
    }

    @IsTest
    static void it_should_set_log_scenario() {
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = userLoggingLevel.name();
        flowEntry.scenario = 'Some scenario';
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        System.assertEquals(1, Logger.getBufferSize());

        Logger.saveLog();
        Test.getEventBus().deliver();
        String transactionId = Logger.getTransactionId();

        Test.stopTest();

        Log__c log = [SELECT Id, Scenario__c FROM Log__c WHERE TransactionId__c = :transactionId];
        System.assertEquals(flowEntry.scenario, log.Scenario__c);
    }

    @IsTest
    static void it_should_add_tags_to_log_entry() {
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        LoggingLevel flowEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowEntryLoggingLevel.ordinal());

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();

        List<String> tags = new List<String>{ 'first tag', 'SECOND TAG' };
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel.name();
        flowEntry.tagsString = String.join(tags, ', ');
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });

        System.assertEquals(1, Logger.getBufferSize());

        Logger.saveLog();
        Test.getEventBus().deliver();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginType__c, OriginLocation__c FROM LogEntry__c ORDER BY CreatedDate LIMIT 1];
        System.assertEquals(flowEntry.loggingLevelName, logEntry.LoggingLevel__c);
        System.assertEquals(flowEntry.message, logEntry.Message__c);
        System.assertEquals('Flow', logEntry.OriginType__c);

        List<LogEntryTag__c> logEntryTags = [SELECT Id, LogEntry__c, Tag__c, Tag__r.Name FROM LogEntryTag__c WHERE LogEntry__c = :logEntry.Id];
        System.assertEquals(tags.size(), logEntryTags.size(), logEntryTags);
        Set<String> tagsSet = new Set<String>(tags);
        for (LogEntryTag__c logEntryTag : logEntryTags) {
            System.assert(tagsSet.contains(logEntryTag.Tag__r.Name));
        }
    }
}
