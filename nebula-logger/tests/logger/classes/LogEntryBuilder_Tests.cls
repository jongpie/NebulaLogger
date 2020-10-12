/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
@isTest
private class LogEntryBuilder_Tests {
    @TestSetup
    static void setup() {
        insert new LoggerSettings__c(IsEnabled__c = false, LoggingLevel__c = 'DEBUG', Name = 'Test Settings');
    }

    @isTest
    static void it_should_short_circuit_when_logging_is_not_enabled() {
        LogEntryBuilder builder = new LogEntryBuilder(LoggingLevel.DEBUG);

        System.assertEquals(null, builder.getLogEntryEvent());
        System.assertEquals(
            null,
            builder.parseComponentLogEntry(new ComponentLogEntry()).getLogEntryEvent()
        );
        System.assertEquals(
            null,
            builder.parseFlowLogEntry(new FlowLogEntry()).getLogEntryEvent()
        );
        System.assertEquals(null, builder.setMessage('test').getLogEntryEvent());
        System.assertEquals(
            null,
            builder.setExceptionDetails(new IllegalArgumentException('test')).getLogEntryEvent()
        );
        System.assertEquals(null, builder.setRecordId(new Account()).getLogEntryEvent());
        System.assertEquals(null, builder.setRecordId('005000000000001').getLogEntryEvent());
        System.assertEquals(
            null,
            builder.setTopics(new List<String>{ '', ' ' }).getLogEntryEvent()
        );
    }

    @isTest
    static void it_should_short_circuit_when_enabled_logging_level_above_called_level() {
        LoggerSettings__c settings = [SELECT Id, IsEnabled__c FROM LoggerSettings__c];
        settings.IsEnabled__c = true;
        update settings;

        LogEntryBuilder builder = new LogEntryBuilder(LoggingLevel.FINE);

        System.assertEquals(null, builder.getLogEntryEvent());
    }

    @isTest
    static void it_should_not_short_circuit_when_enabled_logging_level_meets_called_level() {
        LoggerSettings__c settings = [SELECT Id, IsEnabled__c FROM LoggerSettings__c];
        settings.IsEnabled__c = true;
        settings.LoggingLevel__c = 'FINE';
        update settings;

        LogEntryBuilder builder = new LogEntryBuilder(LoggingLevel.FINE);

        System.assertNotEquals(null, builder.getLogEntryEvent());
    }
}