//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@isTest
private class FlowLogEntry_Tests {
    static FlowLogEntry createFlowLogEntry() {
        FlowLogEntry flowEntry = new FlowLogEntry();
        flowEntry.flowName = 'MyFlowOrProcessBuilder';
        flowEntry.message = 'my test message';
        flowEntry.saveLog = false;

        return flowEntry;
    }

    @isTest
    static void it_should_add_entry_to_buffer_when_logging_level_met() {
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        LoggingLevel flowEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowEntryLoggingLevel.ordinal());

        Test.startTest();

        Logger.getUserSettings().IsEnabled__c = true;
        Logger.getUserSettings().EnableSystemMessages__c = false;
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();

        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel.name();
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());

        LogEntryEvent__e logEntryEvent = Logger.getBuffer().get(0).getLogEntryEvent();
        System.assertEquals(flowEntryLoggingLevel.name(), logEntryEvent.LoggingLevel__c);
        System.assertEquals(flowEntry.message, logEntryEvent.Message__c);
        System.assertEquals('Flow', logEntryEvent.OriginType__c);
        System.assertEquals(flowEntry.flowName, logEntryEvent.OriginLocation__c);
    }

    @isTest
    static void it_should_not_add_entry_to_buffer_when_logging_level_not_met() {
        LoggingLevel userLoggingLevel = LoggingLevel.ERROR;
        LoggingLevel flowEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() > flowEntryLoggingLevel.ordinal());

        List<LogEntry__c> logEntries = [SELECT Id, Message__c, OriginType__c, OriginLocation__c FROM LogEntry__c];
        System.assertEquals(0, logEntries.size());

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();

        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel.name();
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });

        Test.stopTest();

        System.assertEquals(0, Logger.getBufferSize());
    }

    @isTest
    static void it_should_use_debug_as_default_level_when_faultMessage_is_null() {
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();

        FlowLogEntry flowEntry = createFlowLogEntry();
        System.assertEquals(null, flowEntry.faultMessage);
        System.assertEquals(null, flowEntry.loggingLevelName);

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        System.assertEquals(LoggingLevel.DEBUG.name(), flowEntry.loggingLevelName);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());

        LogEntryEvent__e logEntryEvent = Logger.getBuffer().get(0).getLogEntryEvent();
        System.assertEquals(LoggingLevel.DEBUG.name(), logEntryEvent.LoggingLevel__c);
        System.assertEquals(flowEntry.message, logEntryEvent.Message__c);
        System.assertEquals('Flow', logEntryEvent.OriginType__c);
        System.assertEquals(flowEntry.flowName, logEntryEvent.OriginLocation__c);
    }

    @isTest
    static void it_should_use_error_as_default_level_when_faultMessage_is_not_null() {
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();

        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.faultMessage = 'Whoops, a Flow error has occurred.';
        System.assertNotEquals(null, flowEntry.faultMessage);
        System.assertEquals(null, flowEntry.loggingLevelName);

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        System.assertEquals(LoggingLevel.ERROR.name(), flowEntry.loggingLevelName);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());

        LogEntryEvent__e logEntryEvent = Logger.getBuffer().get(0).getLogEntryEvent();
        System.assertEquals(LoggingLevel.ERROR.name(), logEntryEvent.LoggingLevel__c);
        System.assertEquals(flowEntry.faultMessage, logEntryEvent.ExceptionMessage__c);
        System.assertEquals('Flow.FaultError', logEntryEvent.ExceptionType__c);
        System.assertEquals(flowEntry.message, logEntryEvent.Message__c);
        System.assertEquals('Flow', logEntryEvent.OriginType__c);
        System.assertEquals(flowEntry.flowName, logEntryEvent.OriginLocation__c);
    }

    @isTest
    static void it_should_set_related_record_id_when_id_parameter_is_used() {
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        LoggingLevel flowEntryLoggingLevel = LoggingLevel.DEBUG;

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();

        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel.name();
        flowEntry.recordId = UserInfo.getUserId();
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());

        LogEntryEvent__e logEntryEvent = Logger.getBuffer().get(0).getLogEntryEvent();
        System.assertEquals(flowEntryLoggingLevel.name(), logEntryEvent.LoggingLevel__c);
        System.assertEquals(UserInfo.getUserId(), logEntryEvent.RecordId__c);
        System.assertEquals(null, logEntryEvent.RecordJson__c);
    }
}
