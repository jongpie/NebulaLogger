//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@isTest
private class LogEntryEventBuilder_Tests {
    @isTest
    static void it_should_short_circuit_when_not_enabled() {
        Boolean shouldSave = false;
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.DEBUG, shouldSave);

        System.assertEquals(null, builder.getLogEntryEvent());
        System.assertEquals(null, builder.setMessage('test').getLogEntryEvent());
        System.assertEquals(null, builder.setExceptionDetails(new IllegalArgumentException('test')).getLogEntryEvent());
        System.assertEquals(null, builder.setRecordId(new Account()).getLogEntryEvent());
        System.assertEquals(null, builder.setRecordId('005000000000001').getLogEntryEvent());
        System.assertEquals(null, builder.setTopics(new List<String>{ '', ' ' }).getLogEntryEvent());
    }

    @isTest
    static void it_should_short_circuit_when_enabled_logging_level_above_called_level() {
        Boolean shouldSave = Logger.isEnabled(LoggingLevel.FINE);
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.FINE, false);

        System.assertEquals(null, builder.getLogEntryEvent());
    }

    @isTest
    static void it_should_not_short_circuit_when_enabledl() {
        Boolean shouldSave = true;
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.FINE, shouldSave);

        System.assertNotEquals(null, builder.getLogEntryEvent());
    }

    @isTest
    static void it_should_set_message_fields_for_logMessage() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Message__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);

        Test.startTest();

        LogMessage logMessage = new LogMessage('The time is {0}', System.now());
        builder.setMessage(logMessage);

        Test.stopTest();

        System.assertEquals(logMessage.getMessage(), builder.getLogEntryEvent().Message__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);
    }

    @isTest
    static void it_should_set_message_fields_for_string() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Message__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);

        Test.startTest();

        String message = 'The time is ' + String.valueOf(System.now());
        builder.setMessage(message);

        Test.stopTest();

        System.assertEquals(message, builder.getLogEntryEvent().Message__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);
    }

    @isTest
    static void it_should_truncate_a_long_message() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Message__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);

        Integer messageFieldMaxLength = Schema.LogEntryEvent__e.Message__c.getDescribe().getLength();

        String randomMessage = 'The time is ' + String.valueOf(System.now());
        String longMessage = '';
        while (longMessage.length() <= messageFieldMaxLength) {
            longMessage += randomMessage;
        }
        System.assert(longMessage.length() > messageFieldMaxLength);

        Test.startTest();

        builder.setMessage(longMessage);

        Test.stopTest();

        String expectedTruncatedMessage = longMessage.left(messageFieldMaxLength);
        System.assertEquals(expectedTruncatedMessage, builder.getLogEntryEvent().Message__c);
        System.assertEquals(true, builder.getLogEntryEvent().MessageTruncated__c);
    }

    @isTest
    static void it_should_set_exception_fields_for_dmlException() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, builder.getLogEntryEvent().ExceptionType__c);

        Test.startTest();

        DmlException dmlException = new DmlException('Test DML exception');
        builder.setExceptionDetails(dmlException);

        Test.stopTest();

        System.assertEquals(dmlException.getMessage(), builder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(dmlException.getTypeName(), builder.getLogEntryEvent().ExceptionType__c);
    }

    @isTest
    static void it_should_set_record_fields_for_recordId() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);

        Test.startTest();

        Id currentUserId = UserInfo.getUserId();
        builder.setRecordId(currentUserId);

        Test.stopTest();

        System.assertEquals(currentUserId, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
    }

    @isTest
    static void it_should_set_record_fields_for_record() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);

        Test.startTest();

        User currentUser = [SELECT Id, Name, ProfileId, Profile.Name, IsActive FROM User WHERE Id = :UserInfo.getUserId()];
        builder.setRecordId(currentUser);

        Test.stopTest();

        System.assertEquals(currentUser.Id, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(currentUser), builder.getLogEntryEvent().RecordJson__c);
    }

    @isTest
    static void it_should_set_topics_string_for_list_of_topics() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Topics__c);

        Test.startTest();

        List<String> topics = new List<String>{ 'some-topic', 'another One', 'here\'s one more!' };
        builder.setTopics(topics);

        Test.stopTest();

        String expectedTopicsString = String.escapeSingleQuotes(String.join(topics, ','));
        System.assertEquals(expectedTopicsString, builder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_deduplicate_topics() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Topics__c);

        Test.startTest();

        List<String> topics = new List<String>{ 'duplicate-topic', 'duplicate-topic', 'another One' };
        builder.setTopics(topics);

        Test.stopTest();

        String expectedTopicsString = 'duplicate-topic,another One';
        System.assertEquals(expectedTopicsString, builder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_set_stack_trace_and_origin_location_for_stack_trace_string() {
        DmlException stackTraceHandler = new DmlException();

        Boolean shouldSave = true;
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.FINE, shouldSave);
        builder.getLogEntryEvent().OriginLocation__c = null;
        builder.getLogEntryEvent().StackTrace__c = null;

        Test.startTest();
        builder.parseStackTrace(stackTraceHandler.getStackTraceString());
        Test.stopTest();

        String expectedOriginLocation = stackTraceHandler.getStackTraceString().split('\n').get(0).substringBefore(':').substringAfter('Class.');
        String expectedStackTrace = stackTraceHandler.getStackTraceString();

        System.assertNotEquals(null, builder.getLogEntryEvent().OriginLocation__c);
        System.assertEquals(expectedOriginLocation, builder.getLogEntryEvent().OriginLocation__c);
        System.assertNotEquals(null, builder.getLogEntryEvent().StackTrace__c);
        System.assertEquals(expectedStackTrace, builder.getLogEntryEvent().StackTrace__c);
    }

    @isTest
    static void it_should_not_set_stack_trace_and_origin_location_for_invalid_stack_trace_string() {
        final String invalidStackTrace = '()';

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        // Clear out any auto-set values
        builder.getLogEntryEvent().OriginLocation__c = null;
        builder.getLogEntryEvent().StackTrace__c = null;

        Test.startTest();
        builder.parseStackTrace(invalidStackTrace);
        Test.stopTest();

        System.assertEquals(null, builder.getLogEntryEvent().OriginLocation__c);
        System.assertEquals(null, builder.getLogEntryEvent().StackTrace__c);
    }

    @isTest
    static void it_should_return_value_of_shouldSave_when_true() {
        Boolean inputValue = true;

        Test.startTest();
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, inputValue);
        Test.stopTest();

        System.assertEquals(inputValue, builder.shouldSave());
    }

    @isTest
    static void it_should_return_value_of_shouldSave_when_false() {
        Boolean inputValue = false;

        Test.startTest();
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, inputValue);
        Test.stopTest();

        System.assertEquals(inputValue, builder.shouldSave());
    }
}
