/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
@isTest
private class Logger_Tests {

    private class Logger_TestsException extends Exception {}

    static String getOriginLocation() {
        String originLocation;
        for(String currentStackTraceLine : new DmlException().getStackTraceString().split('\n')) {
            if(currentStackTraceLine.contains('Logger_Tests.getOriginLocation')) continue;

            originLocation = currentStackTraceLine.substringBefore(':');
            if(originLocation.startsWith('Class.')) {
                originLocation = originLocation.substringAfter('Class.');
            }
            break;
        }

        return originLocation;
    }

    static LogEntry__c getLogEntry(String transactionEntryId) {
        List<String> fields = new List<String>(Schema.LogEntry__c.SObjectType.getDescribe().fields.getMap().keySet());
        String query = 'SELECT ' + String.join(fields, ', ')
            + ' FROM ' + Schema.LogEntry__c.SObjectType
            + ' WHERE TransactionEntryId__c = :transactionEntryId';
        return (LogEntry__c)Database.query(query);
    }

    @testSetup
    static void setup() {
        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.LoggingLevel__c             = 'FINEST';
        settings.StoreDebugLogEntries__c     = true;
        settings.StoreExceptionLogEntries__c = true;
        upsert settings;
    }

    @isTest
    static void it_should_return_transaction_id() {
        String transactionId = Logger.getTransactionId();
        System.assert(!String.isBlank(transactionId));
        System.assert(Uuid.isValid(transactionId));
    }

    @isTest
    static void it_should_suspend_saving() {
        Integer countOfExistingLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfExistingLogEntries);

        Test.startTest();

        Logger.suspendSaving();

        Logger.addDebugEntry('test log entry');
        Logger.saveLog();

        Test.stopTest();

        countOfExistingLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfExistingLogEntries);
    }

    @isTest
    static void it_should_resume_saving() {
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        List<String> logEntryTransactionIds = new List<String>();

        Logger.suspendSaving();
        logEntryTransactionIds.add(Logger.addDebugEntry('test log entry'));

        Test.startTest();

        logEntryTransactionIds.add(Logger.addDebugEntry('another test log entry'));
        Logger.saveLog();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        Logger.resumeSaving();
        Logger.saveLog();

        Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c WHERE TransactionEntryId__c IN :logEntryTransactionIds];
        System.assertEquals(logEntryTransactionIds.size(), countOfLogEntries);
        System.assertEquals(1, Limits.getDmlStatements());
    }

    @isTest
    static void it_should_flush_buffer() {
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        Test.startTest();
        List<String> logEntryTransactionIds = new List<String>();

        logEntryTransactionIds.add(Logger.addDebugEntry('test log entry'));
        logEntryTransactionIds.add(Logger.addDebugEntry('another test log entry'));

        Logger.flushBuffer();

        logEntryTransactionIds.add(Logger.addDebugEntry('the only log entry to save'));
        Logger.saveLog();

        Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c WHERE TransactionEntryId__c IN :logEntryTransactionIds];
        System.assertEquals(1, countOfLogEntries);
    }

    @isTest
    static void it_should_return_logging_level() {
        System.assertEquals(LoggingLevel.DEBUG, Logger.getLoggingLevel('fake'));
        System.assertEquals(LoggingLevel.NONE, Logger.getLoggingLevel('none'));
        System.assertEquals(LoggingLevel.ERROR, Logger.getLoggingLevel('error'));
        System.assertEquals(LoggingLevel.WARN, Logger.getLoggingLevel('warn'));
        System.assertEquals(LoggingLevel.INFO, Logger.getLoggingLevel('info'));
        System.assertEquals(LoggingLevel.DEBUG, Logger.getLoggingLevel('debug'));
        System.assertEquals(LoggingLevel.FINE, Logger.getLoggingLevel('fine'));
        System.assertEquals(LoggingLevel.FINER, Logger.getLoggingLevel('finer'));
        System.assertEquals(LoggingLevel.FINEST, Logger.getLoggingLevel('finest'));
    }

    @isTest
    static void it_should_add_a_debug_entry_with_default_logging_level() {
        String message = 'my test message';

        Test.startTest();
        String transactionEntryId = Logger.addDebugEntry(message);
        Logger.saveLog();
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry(transactionEntryId);
        System.assertEquals(LoggingLevel.DEBUG.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals('Apex', logEntry.OriginType__c);
        System.assertNotEquals(null, logEntry.OriginLocation__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_add_a_debug_entry_with_logging_level() {
        LoggingLevel logLevel = LoggingLevel.WARN;
        String message = 'my test message';

        Test.startTest();
        String transactionEntryId = Logger.addDebugEntry(logLevel, message);
        Logger.saveLog();
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry(transactionEntryId);
        System.assertEquals(logLevel.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals('Apex', logEntry.OriginType__c);
        System.assertNotEquals(null, logEntry.OriginLocation__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_add_a_debug_entry_and_truncate_a_long_message() {
        LoggingLevel logLevel = LoggingLevel.WARN;
        Integer messageMaxLength = Schema.LogEntry__c.SObjectType.Message__c.getDescribe().getLength();
        String message = 'my test message string';
        while(message.length() < messageMaxLength + 200) {
            message += message;
        }

        Test.startTest();
        String transactionEntryId = Logger.addDebugEntry(logLevel, message);
        Logger.saveLog();
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry(transactionEntryId);
        System.assertEquals(message.left(messageMaxLength), logEntry.Message__c);
        System.assertEquals(true, logEntry.MessageTruncated__c);
        System.assertEquals('Apex', logEntry.OriginType__c);
        System.assertNotEquals(null, logEntry.OriginLocation__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_add_a_debug_entry_with_topics() {
        LoggingLevel logLevel = LoggingLevel.WARN;
        String message = 'my test message';
        List<String> topicNames = new List<String>{'MyTopic', 'AnotherTopic'};

        Test.startTest();
        String transactionEntryId = Logger.addDebugEntry(logLevel, message, topicNames);
        Logger.saveLog();
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry(transactionEntryId);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals('Apex', logEntry.OriginType__c);
        System.assertNotEquals(null, logEntry.OriginLocation__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);

        List<TopicAssignment> topicAssignments = [SELECT Id, TopicId, Topic.Name FROM TopicAssignment WHERE EntityId = :logEntry.Id];
        //System.assertEquals(topicNames.size(), topicAssignments.size());
        for(TopicAssignment topicAssignment : topicAssignments) {
            //System.assert(new Set<String>(topicNames).contains(topicAssignment.Topic.Name));
        }
    }

    @isTest
    static void it_should_add_entry_for_an_exception() {
        Exception exceptionResult;

        Test.startTest();
        String transactionEntryId;
        try {
            insert new Lead();
        } catch(Exception ex) {
            exceptionResult = ex;
            transactionEntryId = Logger.addExceptionEntry(ex);
            Logger.saveLog();
        }
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry(transactionEntryId);
        System.assertEquals(exceptionResult.getMessage(), logEntry.Message__c);
        System.assertEquals('Apex', logEntry.OriginType__c);
       // System.assNotertEquals(null, logEntry.OriginLocation__c);
       // System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_add_entry_for_an_exception_with_topics() {
        Exception exceptionResult;
        List<String> topicNames = new List<String>{'MyTopic', 'AnotherTopic'};

        Test.startTest();
        String transactionEntryId;
        try {
            insert new Lead();
        } catch(Exception ex) {
            exceptionResult = ex;
            transactionEntryId = Logger.addExceptionEntry(ex, topicNames);
            Logger.saveLog();
        }
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry(transactionEntryId);
        System.assertEquals(exceptionResult.getMessage(), logEntry.Message__c);
        System.assertEquals('Apex', logEntry.OriginType__c);
        System.assertNotEquals(null, logEntry.OriginLocation__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);

        List<TopicAssignment> topicAssignments = [SELECT Id, TopicId, Topic.Name FROM TopicAssignment WHERE EntityId = :logEntry.Id];
        //System.assertEquals(topicNames.size(), topicAssignments.size());
        for(TopicAssignment topicAssignment : topicAssignments) {
            //System.assert(new Set<String>(topicNames).contains(topicAssignment.Topic.Name));
        }
    }

    @isTest
    static void it_should_add_a_record_debug_entry_with_default_logging_level() {
        String message = 'my test message';
        User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Test.startTest();
        String transactionEntryId = Logger.addRecordDebugEntry(user, message);
        Logger.saveLog();
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry(transactionEntryId);
        System.assertEquals(LoggingLevel.DEBUG.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals('Apex', logEntry.OriginType__c);
        System.assertNotEquals(null, logEntry.OriginLocation__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_add_a_record_debug_entry_with_logging_level() {
        LoggingLevel logLevel = LoggingLevel.WARN;
        String message = 'my test message';
        User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Test.startTest();
        String transactionEntryId = Logger.addRecordDebugEntry(logLevel, user, message);
        Logger.saveLog();
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry(transactionEntryId);
        System.assertEquals(logLevel.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals('Apex', logEntry.OriginType__c);
        System.assertNotEquals(null, logEntry.OriginLocation__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_add_a_record_debug_entry_and_truncate_a_long_message() {
        LoggingLevel logLevel = LoggingLevel.WARN;
        Integer messageMaxLength = Schema.LogEntry__c.SObjectType.Message__c.getDescribe().getLength();
        String message = 'my test message string';
        while(message.length() < messageMaxLength + 200) {
            message += message;
        }
        User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Test.startTest();
        String transactionEntryId = Logger.addRecordDebugEntry(logLevel, user, message);
        Logger.saveLog();
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry(transactionEntryId);
        System.assertEquals(message.left(messageMaxLength), logEntry.Message__c);
        System.assertEquals(true, logEntry.MessageTruncated__c);
        System.assertEquals('Apex', logEntry.OriginType__c);
        System.assertNotEquals(null, logEntry.OriginLocation__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_add_a_record_debug_entry_with_topics() {
        LoggingLevel logLevel = LoggingLevel.WARN;
        String message = 'my test message';
        List<String> topicNames = new List<String>{'MyTopic', 'AnotherTopic'};
        User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Test.startTest();
        String transactionEntryId = Logger.addRecordDebugEntry(logLevel, user, message, topicNames);
        Logger.saveLog();
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry(transactionEntryId);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals('Apex', logEntry.OriginType__c);
        System.assertNotEquals(null, logEntry.OriginLocation__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);

        List<TopicAssignment> topicAssignments = [SELECT Id, TopicId, Topic.Name FROM TopicAssignment WHERE EntityId = :logEntry.Id];
        //System.assertEquals(topicNames.size(), topicAssignments.size());
        for(TopicAssignment topicAssignment : topicAssignments) {
            //System.assert(new Set<String>(topicNames).contains(topicAssignment.Topic.Name));
        }
    }

    @isTest
    static void it_should_add_record_entry_for_an_exception() {
        Exception exceptionResult;
        User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Test.startTest();
        String transactionEntryId;
        try {
            insert new Lead();
        } catch(Exception ex) {
            exceptionResult = ex;
            transactionEntryId = Logger.addRecordExceptionEntry(user, ex);
            Logger.saveLog();
        }
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry(transactionEntryId);
        System.assertEquals(exceptionResult.getMessage(), logEntry.Message__c);
        System.assertEquals('Apex', logEntry.OriginType__c);
        System.assertNotEquals(null, logEntry.OriginLocation__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_add_record_entry_for_an_exception_with_topics() {
        Exception exceptionResult;
        List<String> topicNames = new List<String>{'MyTopic', 'AnotherTopic'};
        User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Test.startTest();
        String transactionEntryId;
        try {
            insert new Lead();
        } catch(Exception ex) {
            exceptionResult = ex;
            transactionEntryId = Logger.addRecordExceptionEntry(user, ex, topicNames);
            Logger.saveLog();
        }
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry(transactionEntryId);
        System.assertEquals(exceptionResult.getMessage(), logEntry.Message__c);
        System.assertEquals('Apex', logEntry.OriginType__c);
        System.assertNotEquals(null, logEntry.OriginLocation__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);

        List<TopicAssignment> topicAssignments = [SELECT Id, TopicId, Topic.Name FROM TopicAssignment WHERE EntityId = :logEntry.Id];
        //System.assertEquals(topicNames.size(), topicAssignments.size());
        for(TopicAssignment topicAssignment : topicAssignments) {
            //System.assert(new Set<String>(topicNames).contains(topicAssignment.Topic.Name));
        }
    }

    @isTest
    static void it_should_add_entries_for_a_list_of_flow_messages() {
        String message = 'my test message';
        String flowName = 'MyFlowOrProcessBuilder';
        List<FlowLogEntry> flowLogEntries = new List<FlowLogEntry>();

        Test.startTest();
        FlowLogEntry flowEntry = new FlowLogEntry();
        flowEntry.FlowName = flowName;
        flowEntry.Message = message;
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{flowEntry});
        Logger.saveLog();
        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, Message__c, OriginType__c, OriginLocation__c FROM LogEntry__c ORDER BY CreatedDate LIMIT 1];
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals('Process Builder/Flow', logEntry.OriginType__c);
        System.assertEquals(flowName, logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_save_entries_for_a_list_of_lightning_messages() {
        Datetime timestamp = System.now().addMinutes(-5);
        List<LightningLogEntry> lightningLogEntries = new List<LightningLogEntry>();

        Test.startTest();
        LightningLogEntry lightningLogEntry = new LightningLogEntry();
        lightningLogEntry.componentName    = 'myComponent';
        lightningLogEntry.loggingLevelName = 'DEBUG';
        lightningLogEntry.message          = 'my test message';
        lightningLogEntry.originLocation   = 'test';
        lightningLogEntry.timestamp        = timestamp;

        lightningLogEntries.add(lightningLogEntry);
        Logger.saveLightningEntries(Json.serialize(lightningLogEntries));
        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, ContextLightningComponentName__c, Message__c, OriginType__c, OriginLocation__c, Timestamp__c FROM LogEntry__c ORDER BY CreatedDate LIMIT 1];
        System.assertEquals(lightningLogEntry.componentName, logEntry.ContextLightningComponentName__c);
        System.assertEquals(lightningLogEntry.message, logEntry.Message__c);
        System.assertEquals('Lightning Component', logEntry.OriginType__c);
        System.assertEquals(lightningLogEntry.originLocation, logEntry.OriginLocation__c);
        System.assertEquals(timestamp, logEntry.Timestamp__c);
    }

}