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

    @isTest
    static void it_should_return_transaction_id() {
        String transactionId = Logger.getTransactionId();
        System.assert(!String.isBlank(transactionId));

        Test.startTest();
        System.assertEquals(transactionId, Logger.getTransactionId());
        Test.stopTest();

        System.assertEquals(transactionId, Logger.getTransactionId());
    }

    @isTest
    static void it_should_add_entry_for_a_class_method_message() {
        String message = 'my test message';
        String className = 'MyClass';
        String methodName = 'myMethod()';

        Test.startTest();
        Logger.addDebugEntry(message, className, methodName);
        Logger.saveLog();
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry();
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(className, logEntry.ClassName__c);
        System.assertEquals(methodName, logEntry.MethodName__c);
        System.assertEquals('Apex', logEntry.SourceType__c);
    }

    @isTest
    static void it_should_add_entry_for_a_class_method_message_with_logging_level() {
        LoggingLevel logLevel = LoggingLevel.WARN;
        String message = 'my test message';
        String className = 'MyClass';
        String methodName = 'myMethod()';

        Test.startTest();
        Logger.addDebugEntry(logLevel, message, className, methodName);
        Logger.saveLog();
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry();
        System.assertEquals(logLevel.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(className, logEntry.ClassName__c);
        System.assertEquals(methodName, logEntry.MethodName__c);
        System.assertEquals('Apex', logEntry.SourceType__c);
    }

    @isTest
    static void it_should_add_entry_for_a_class_method_message_with_parent_id() {
        String message = 'my test message';
        String className = 'MyClass';
        String methodName = 'myMethod()';
        Id parentId = UserInfo.getUserId();

        Test.startTest();
        Logger.addDebugEntry(message, className, methodName, parentId);
        Logger.saveLog();
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry();
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(className, logEntry.ClassName__c);
        System.assertEquals(methodName, logEntry.MethodName__c);
        System.assertEquals(parentId, logEntry.ParentId__c);
        System.assertEquals('Apex', logEntry.SourceType__c);
    }

    @isTest
    static void it_should_add_entry_for_a_class_method_message_with_logging_level_and_parent_id() {
        LoggingLevel logLevel = LoggingLevel.WARN;
        String message = 'my test message';
        String className = 'MyClass';
        String methodName = 'myMethod()';
        Id parentId = UserInfo.getUserId();

        Test.startTest();
        Logger.addDebugEntry(logLevel, message, className, methodName, parentId);
        Logger.saveLog();
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry();
        System.assertEquals(logLevel.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(className, logEntry.ClassName__c);
        System.assertEquals(methodName, logEntry.MethodName__c);
        System.assertEquals(parentId, logEntry.ParentId__c);
        System.assertEquals('Apex', logEntry.SourceType__c);
    }

    @isTest
    static void it_should_add_entry_for_a_class_method_exception() {
        Exception exceptionResult;
        String className = 'MyClass';
        String methodName = 'myMethod()';

        Test.startTest();
        try {
            insert new Lead();
        } catch(Exception ex) {
            exceptionResult = ex;
            Logger.addExceptionEntry(ex, className, methodName);
            Logger.saveLog();
        }
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry();
        System.assertEquals(exceptionResult.getMessage(), logEntry.Message__c);
        System.assertEquals(className, logEntry.ClassName__c);
        System.assertEquals(methodName, logEntry.MethodName__c);
        System.assertEquals('Apex', logEntry.SourceType__c);
    }

    @isTest
    static void it_should_add_entry_for_a_class_method_exception_with_logging_level() {
        LoggingLevel logLevel = LoggingLevel.WARN;
        Exception exceptionResult;
        String className = 'MyClass';
        String methodName = 'myMethod()';

        Test.startTest();
        try {
            insert new Lead();
        } catch(Exception ex) {
            exceptionResult = ex;
            Logger.addExceptionEntry(logLevel, ex, className, methodName);
            Logger.saveLog();
        }
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry();
        System.assertEquals(logLevel.name(), logEntry.LoggingLevel__c);
        System.assertEquals(exceptionResult.getMessage(), logEntry.Message__c);
        System.assertEquals(className, logEntry.ClassName__c);
        System.assertEquals(methodName, logEntry.MethodName__c);
        System.assertEquals('Apex', logEntry.SourceType__c);
    }

    @isTest
    static void it_should_add_entry_for_an_exception_with_logging_level_and_parent_id() {
        LoggingLevel logLevel = LoggingLevel.WARN;
        Exception exceptionResult;
        String className = 'MyClass';
        String methodName = 'myMethod()';
        Id parentId = UserInfo.getUserId();

        Test.startTest();
        try {
            insert new Lead();
        } catch(Exception ex) {
            exceptionResult = ex;
            Logger.addExceptionEntry(logLevel, ex, className, methodName, parentId);
            Logger.saveLog();
        }
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry();
        System.assertEquals(logLevel.name(), logEntry.LoggingLevel__c);
        System.assertEquals(exceptionResult.getMessage(), logEntry.Message__c);
        System.assertEquals(className, logEntry.ClassName__c);
        System.assertEquals(methodName, logEntry.MethodName__c);
        System.assertEquals(parentId, logEntry.ParentId__c);
        System.assertEquals('Apex', logEntry.SourceType__c);
    }

    @isTest
    static void it_should_add_entry_for_a_class_method_exception_with_parent_id() {
        Exception exceptionResult;
        String className = 'MyClass';
        String methodName = 'myMethod()';
        Id parentId = UserInfo.getUserId();

        Test.startTest();
        try {
            insert new Lead();
        } catch(Exception ex) {
            exceptionResult = ex;
            Logger.addExceptionEntry(ex, className, methodName, parentId);
            Logger.saveLog();
        }
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry();
        System.assertEquals(exceptionResult.getMessage(), logEntry.Message__c);
        System.assertEquals(className, logEntry.ClassName__c);
        System.assertEquals(methodName, logEntry.MethodName__c);
        System.assertEquals(parentId, logEntry.ParentId__c);
        System.assertEquals('Apex', logEntry.SourceType__c);
    }

    @isTest
    static void it_should_add_entry_for_a_class_method_exception_with_logging_level_and_parent_id() {
        LoggingLevel logLevel = LoggingLevel.WARN;
        Exception exceptionResult;
        String className = 'MyClass';
        String methodName = 'myMethod()';
        Id parentId = UserInfo.getUserId();

        Test.startTest();
        try {
            insert new Lead();
        } catch(Exception ex) {
            exceptionResult = ex;
            Logger.addExceptionEntry(logLevel, ex, className, methodName, parentId);
            Logger.saveLog();
        }
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry();
        System.assertEquals(logLevel.name(), logEntry.LoggingLevel__c);
        System.assertEquals(exceptionResult.getMessage(), logEntry.Message__c);
        System.assertEquals(className, logEntry.ClassName__c);
        System.assertEquals(methodName, logEntry.MethodName__c);
        System.assertEquals(parentId, logEntry.ParentId__c);
        System.assertEquals('Apex', logEntry.SourceType__c);
    }


    @isTest
    static void it_should_add_entries_for_a_list_of_flow_messages() {
        String message = 'my test message';
        String flowName = 'MyFlowOrProcessBuilder';
        List<FlowLogEntry> flowLogEntries = new List<FlowLogEntry>();

        Test.startTest();
        FlowLogEntry flowLogEntry = new FlowLogEntry();
        flowLogEntry.FlowName = flowName;
        flowLogEntry.Message = message;
        Logger.addFlowEntries(new List<FlowLogEntry>{flowLogEntry});
        Logger.saveLog();
        Test.stopTest();

        LogEntry__c logEntry = getLogEntry();
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(flowName, logEntry.FlowName__c);
        System.assertEquals('Process Builder/Flow', logEntry.SourceType__c);
    }

}