/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
@isTest
private class Logger_Tests {

    private class Logger_TestsException extends Exception {}

    static LogEntry__c getLogEntry() {
        List<String> fields = new List<String>(Schema.LogEntry__c.SobjectType.getDescribe().fields.getMap().keySet());
        String query = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + Schema.LogEntry__c.SobjectType;
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
    }

    @isTest
    static void it_should_return_logging_level() {
        System.assertEquals(LoggingLevel.NONE, Logger.getLoggingLevel('fake'));
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
        String originLocation = 'MyClass.myMethod()';

        Test.startTest();
        Logger.addDebugEntry(message, originLocation);
        Logger.saveLog();
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry();
        System.assertEquals(LoggingLevel.DEBUG.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals('Apex', logEntry.OriginType__c);
        System.assertEquals(originLocation, logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_add_a_debug_entry_with_logging_level() {
        LoggingLevel logLevel = LoggingLevel.WARN;
        String message = 'my test message';
        String originLocation = 'MyClass.myMethod()';

        Test.startTest();
        Logger.addDebugEntry(logLevel, message, originLocation);
        Logger.saveLog();
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry();
        System.assertEquals(logLevel.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals('Apex', logEntry.OriginType__c);
        System.assertEquals(originLocation, logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_add_a_debug_entry_and_truncate_a_long_message() {
        LoggingLevel logLevel = LoggingLevel.WARN;
        Integer messageMaxLength = Schema.LogEntry__c.SobjectType.Message__c.getDescribe().getLength();
        String message = 'my test message string';
        while(message.length() < messageMaxLength + 200) {
            message += message;
        }
        String originLocation = 'MyClass.myMethod()';

        Test.startTest();
        Logger.addDebugEntry(logLevel, message, originLocation);
        Logger.saveLog();
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry();
        System.assertEquals(message.left(messageMaxLength), logEntry.Message__c);
        System.assertEquals(true, logEntry.MessageTruncated__c);
        System.assertEquals('Apex', logEntry.OriginType__c);
        System.assertEquals(originLocation, logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_add_a_debug_entry_with_topics() {
        LoggingLevel logLevel = LoggingLevel.WARN;
        String message = 'my test message';
        String originLocation = 'MyClass.myMethod()';
        List<String> topicNames = new List<String>{'MyTopic', 'AnotherTopic'};

        Test.startTest();
        Logger.addDebugEntry(logLevel, message, originLocation, topicNames);
        Logger.saveLog();
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry();
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals('Apex', logEntry.OriginType__c);
        System.assertEquals(originLocation, logEntry.OriginLocation__c);

        List<TopicAssignment> topicAssignments = [SELECT Id, TopicId, Topic.Name FROM TopicAssignment WHERE EntityId = :logEntry.Id];
        System.assertEquals(topicNames.size(), topicAssignments.size());
        for(TopicAssignment topicAssignment : topicAssignments) {
            System.assert(new Set<String>(topicNames).contains(topicAssignment.Topic.Name));
        }
    }

    @isTest
    static void it_should_add_entry_for_an_exception() {
        Exception exceptionResult;
        String originLocation = 'MyClass.myMethod()';

        Test.startTest();
        try {
            insert new Lead();
        } catch(Exception ex) {
            exceptionResult = ex;
            Logger.addExceptionEntry(ex, originLocation);
            Logger.saveLog();
        }
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry();
        System.assertEquals(exceptionResult.getMessage(), logEntry.Message__c);
        System.assertEquals('Apex', logEntry.OriginType__c);
        System.assertEquals(originLocation, logEntry.OriginLocation__c);

    }

    @isTest
    static void it_should_add_entry_for_an_exception_with_topics() {
        Exception exceptionResult;
        String originLocation = 'MyClass.myMethod()';
        List<String> topicNames = new List<String>{'MyTopic', 'AnotherTopic'};

        Test.startTest();
        try {
            insert new Lead();
        } catch(Exception ex) {
            exceptionResult = ex;
            Logger.addExceptionEntry(ex, originLocation, topicNames);
            Logger.saveLog();
        }
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry();
        System.assertEquals(exceptionResult.getMessage(), logEntry.Message__c);
        System.assertEquals('Apex', logEntry.OriginType__c);
        System.assertEquals(originLocation, logEntry.OriginLocation__c);


        List<TopicAssignment> topicAssignments = [SELECT Id, TopicId, Topic.Name FROM TopicAssignment WHERE EntityId = :logEntry.Id];
        System.assertEquals(topicNames.size(), topicAssignments.size());
        for(TopicAssignment topicAssignment : topicAssignments) {
            System.assert(new Set<String>(topicNames).contains(topicAssignment.Topic.Name));
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

        LogEntry__c logEntry = getLogEntry();
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

        LogEntry__c logEntry = getLogEntry();
        System.assertEquals(lightningLogEntry.componentName, logEntry.ContextLightningComponentName__c);
        System.assertEquals(lightningLogEntry.message, logEntry.Message__c);
        System.assertEquals('Lightning Component', logEntry.OriginType__c);
        System.assertEquals(lightningLogEntry.originLocation, logEntry.OriginLocation__c);
        System.assertEquals(timestamp, logEntry.Timestamp__c);
    }

}