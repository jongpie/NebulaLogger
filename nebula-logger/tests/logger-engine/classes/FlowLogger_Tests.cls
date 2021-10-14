//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest
private class FlowLogger_Tests {
    @IsTest
    static void it_should_add_entry_to_logger_buffer() {
        LoggingLevel entryLoggingLevel = LoggingLevel.DEBUG;

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = entryLoggingLevel.name();

        FlowLogger.LogEntry logEntry = new FlowLogger.LogEntry();
        logEntry.flowName = 'MyFlow';
        logEntry.message = 'hello from Flow';
        logEntry.loggingLevelName = entryLoggingLevel.name();
        logEntry.saveLog = false;
        logEntry.timestamp = System.now();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(0, [SELECT COUNT() FROM LogEntry__c]);

        FlowLogger.addEntries(new List<FlowLogger.LogEntry>{ logEntry });
        System.assertEquals(1, Logger.getBufferSize());

        Logger.saveLog();

        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM LogEntry__c]);
    }

    @IsTest
    static void it_should_auto_save_entry_when_saveLog_is_true() {
        LoggingLevel entryLoggingLevel = LoggingLevel.DEBUG;

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = entryLoggingLevel.name();

        FlowLogger.LogEntry logEntry = new FlowLogger.LogEntry();
        logEntry.flowName = 'MyFlow';
        logEntry.message = 'hello from Flow';
        logEntry.loggingLevelName = entryLoggingLevel.name();
        logEntry.saveLog = true;
        logEntry.timestamp = System.now();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(0, [SELECT COUNT() FROM LogEntry__c]);

        FlowLogger.addEntries(new List<FlowLogger.LogEntry>{ logEntry });
        System.assertEquals(0, Logger.getBufferSize());

        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM LogEntry__c]);
    }
}
