//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@isTest
private class FlowRecordLogEntry_Tests {
    static FlowRecordLogEntry createFlowRecordLogEntry() {
        FlowRecordLogEntry flowRecordEntry = new FlowRecordLogEntry();
        flowRecordEntry.flowName = 'MyFlowOrProcessBuilder';
        flowRecordEntry.message = 'my test message';
        flowRecordEntry.saveLog = false;

        return flowRecordEntry;
    }

    @isTest
    static void it_should_add_entry_to_buffer_when_logging_level_met() {
        User currentUser = new User(
            Id = UserInfo.getUserId(),
            FirstName = UserInfo.getFirstName(),
            LastName = UserInfo.getLastName(),
            Username = UserInfo.getUserName()
        );
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        LoggingLevel flowRecordEntryLoggingLevel = LoggingLevel.DEBUG;

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();

        FlowRecordLogEntry flowRecordEntry = createFlowRecordLogEntry();
        flowRecordEntry.loggingLevelName = flowRecordEntryLoggingLevel.name();
        flowRecordEntry.record = currentUser;
        FlowRecordLogEntry.addFlowRecordEntries(new List<FlowRecordLogEntry>{ flowRecordEntry });

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());

        String expectedUserJson = JSON.serializePretty(currentUser);

        LogEntryEvent__e logEntryEvent = Logger.getBuffer().get(0).getLogEntryEvent();
        System.assertEquals(flowRecordEntry.loggingLevelName, logEntryEvent.LoggingLevel__c);
        System.assertEquals(currentUser.Id, logEntryEvent.RecordId__c);
        System.assertEquals(expectedUserJson, logEntryEvent.RecordJson__c);
    }

    @isTest
    static void it_should_not_add_entry_to_buffer_when_logging_level_not_met() {
        User currentUser = new User(Id = UserInfo.getUserId());
        LoggingLevel userLoggingLevel = LoggingLevel.ERROR;
        LoggingLevel flowRecordEntryLoggingLevel = LoggingLevel.DEBUG;

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();

        FlowRecordLogEntry flowRecordEntry = createFlowRecordLogEntry();
        flowRecordEntry.loggingLevelName = flowRecordEntryLoggingLevel.name();
        flowRecordEntry.record = currentUser;
        FlowRecordLogEntry.addFlowRecordEntries(new List<FlowRecordLogEntry>{ flowRecordEntry });
        System.assertEquals(0, Logger.getBufferSize());

        Test.stopTest();
    }

    @isTest
    static void it_should_use_debug_as_default_level_when_faultMessage_is_null() {
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();

        FlowRecordLogEntry flowEntry = createFlowRecordLogEntry();
        System.assertEquals(null, flowEntry.faultMessage);
        System.assertEquals(null, flowEntry.loggingLevelName);

        FlowRecordLogEntry.addFlowRecordEntries(new List<FlowRecordLogEntry>{ flowEntry });
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
        String userLoggingLevel = 'FINEST';

        Test.startTest();

        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel;

        FlowRecordLogEntry flowEntry = createFlowRecordLogEntry();
        flowEntry.faultMessage = 'Whoops, a Flow error has occurred.';
        System.assertNotEquals(null, flowEntry.faultMessage);
        System.assertEquals(null, flowEntry.loggingLevelName);

        FlowRecordLogEntry.addFlowRecordEntries(new List<FlowRecordLogEntry>{ flowEntry });
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
}
