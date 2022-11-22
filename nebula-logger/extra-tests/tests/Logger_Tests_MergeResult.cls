//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

// TODO move these test methods back into Logger_Tests, now that mocking is possible via LoggerMockDataCreator.createDatabaseMergeResult()
//      (and then delete this class)
@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class Logger_Tests_MergeResult {
    static String getMessage() {
        return 'Hello, world';
    }

    static LogMessage getLogMessage() {
        return new LogMessage('The current date is {0}', System.today());
    }

    static List<Database.MergeResult> getMergeResultList() {
        return new List<Database.MergeResult>{ LoggerMockDataCreator.createDatabaseMergeResult(true) };
    }

    @IsTest
    static void addErrorEntryForLogMessageWithMergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        Database.MergeResult mergeResult = LoggerMockDataCreator.createDatabaseMergeResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), mergeResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Logging level name was incorrect.');
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect');
        System.Assert.areEqual(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry record JSON was incorrect.');
        System.Assert.areEqual(
            JSON.serializePretty(mergeResult),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            'Single',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry tags was incorrect.');
    }

    @IsTest
    static void addErrorEntryForLogMessageWithMergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        List<Database.MergeResult> mergeResults = getMergeResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), mergeResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Logging level was incorrect.');
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry record JSON was incorrect.');
        System.Assert.areEqual(
            JSON.serializePretty(mergeResults),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags was incorrect.');
    }

    @IsTest
    static void addErrorEntryForStringMessageWithMergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        Database.MergeResult mergeResult = LoggerMockDataCreator.createDatabaseMergeResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), mergeResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Logging level was incorrect.');
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.areEqual(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            'Single',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            JSON.serializePretty(mergeResult),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was incorrect.');
    }

    @IsTest
    static void addErrorEntryForStringMessageWithMergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        List<Database.MergeResult> mergeResults = getMergeResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), mergeResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            'List',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            JSON.serializePretty(mergeResults),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was incorrect.');
    }

    @IsTest
    static void addWarnEntryForLogMessageWithMergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        Database.MergeResult mergeResult = LoggerMockDataCreator.createDatabaseMergeResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), mergeResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.areEqual(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            JSON.serializePretty(mergeResult),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            'Single',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field not null.');
    }

    @IsTest
    static void addWarnEntryForLogMessageWithMergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        List<Database.MergeResult> mergeResults = getMergeResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), mergeResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            JSON.serializePretty(mergeResults),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }

    @IsTest
    static void addWarnEntryForStringMessageWithMergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        Database.MergeResult mergeResult = LoggerMockDataCreator.createDatabaseMergeResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), mergeResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.areEqual(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            'Single',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            JSON.serializePretty(mergeResult),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null');
    }

    @IsTest
    static void addWarnEntryForStringMessageWithMergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        List<Database.MergeResult> mergeResults = getMergeResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), mergeResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event recrd JSON was incorrect.');
        System.Assert.areEqual(
            'List',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event databse result collection type was incorrect.'
        );
        System.Assert.areEqual(
            JSON.serializePretty(mergeResults),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result json was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }

    @IsTest
    static void addAnInfoEntryForLogMessageWithMergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        Database.MergeResult mergeResult = LoggerMockDataCreator.createDatabaseMergeResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), mergeResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.areEqual(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was not null.');
        System.Assert.areEqual(
            JSON.serializePretty(mergeResult),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            'Single',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }

    @IsTest
    static void addInfoEntryForLogMessageWithMergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        List<Database.MergeResult> mergeResults = getMergeResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), mergeResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            JSON.serializePretty(mergeResults),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null');
    }

    @IsTest
    static void addInfoEntryForStringMessageWithMergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        Database.MergeResult mergeResult = LoggerMockDataCreator.createDatabaseMergeResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), mergeResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.areEqual(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            'Single',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            JSON.serializePretty(mergeResult),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null');
    }

    @IsTest
    static void addAnInfoEntryForStringMessageWithMergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Log entry buffer size was incorrect.');

        List<Database.MergeResult> mergeResults = getMergeResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), mergeResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry record JSON was incorrect.');
        System.Assert.areEqual(
            'List',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            JSON.serializePretty(mergeResults),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }

    @IsTest
    static void addDebugEntryForLogMessageWithMergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        Database.MergeResult mergeResult = LoggerMockDataCreator.createDatabaseMergeResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), mergeResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.areEqual(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            JSON.serializePretty(mergeResult),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            'Single',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }

    @IsTest
    static void addDebugEntryForLogMessageWithMergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        List<Database.MergeResult> mergeResults = getMergeResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), mergeResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            JSON.serializePretty(mergeResults),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }

    @IsTest
    static void addDebugEntryForStringMessageWithMergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        Database.MergeResult mergeResult = LoggerMockDataCreator.createDatabaseMergeResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), mergeResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.areEqual(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            'Single',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            JSON.serializePretty(mergeResult),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }

    @IsTest
    static void addDebugEntryForStringMessageWithMergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        List<Database.MergeResult> mergeResults = getMergeResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), mergeResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            'List',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            JSON.serializePretty(mergeResults),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }

    @IsTest
    static void addFineEntryForLogMessageWithMergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        Database.MergeResult mergeResult = LoggerMockDataCreator.createDatabaseMergeResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), mergeResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.areEqual(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            JSON.serializePretty(mergeResult),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            'Single',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }

    @IsTest
    static void addFineEntryForLogMessageWithMergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        List<Database.MergeResult> mergeResults = getMergeResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), mergeResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            JSON.serializePretty(mergeResults),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }

    @IsTest
    static void addFineEntryForStringMessageWithMergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        Database.MergeResult mergeResult = LoggerMockDataCreator.createDatabaseMergeResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), mergeResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log event logging level was incorrect.');
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.areEqual(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            'Single',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            JSON.serializePretty(mergeResult),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was incorrect.');
    }

    @IsTest
    static void addFineEntryForStringMessageWithMergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        List<Database.MergeResult> mergeResults = getMergeResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), mergeResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            'List',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            JSON.serializePretty(mergeResults),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }

    @IsTest
    static void addFinerEntryForLogMessageWithMergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        Database.MergeResult mergeResult = LoggerMockDataCreator.createDatabaseMergeResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), mergeResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.areEqual(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            JSON.serializePretty(mergeResult),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            'Single',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }

    @IsTest
    static void addFinerEntryForLogMessageWithMergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        List<Database.MergeResult> mergeResults = getMergeResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), mergeResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            JSON.serializePretty(mergeResults),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }

    @IsTest
    static void addFinerEntryForStringMessageWithMergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        Database.MergeResult mergeResult = LoggerMockDataCreator.createDatabaseMergeResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), mergeResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.areEqual(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            'Single',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            JSON.serializePretty(mergeResult),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }

    @IsTest
    static void addFinerEntryForStringMessageWithMergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        List<Database.MergeResult> mergeResults = getMergeResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), mergeResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            'List',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            JSON.serializePretty(mergeResults),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }

    @IsTest
    static void addFinestEntryForLogMessageWithMergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        Database.MergeResult mergeResult = LoggerMockDataCreator.createDatabaseMergeResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), mergeResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.areEqual(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            JSON.serializePretty(mergeResult),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            'Single',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }

    @IsTest
    static void addFinestEntryForLogMessageWithMergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        List<Database.MergeResult> mergeResults = getMergeResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), mergeResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            JSON.serializePretty(mergeResults),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }

    @IsTest
    static void addFinestEntryForStringMessageWithMergeResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        Database.MergeResult mergeResult = LoggerMockDataCreator.createDatabaseMergeResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), mergeResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.areEqual(mergeResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            'Single',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            JSON.serializePretty(mergeResult),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }

    @IsTest
    static void addFinestEntryForStringMessageWithMergeResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
        System.Assert.areEqual(0, Logger.getBufferSize(), 'Logger buffer size was incorrect.');

        List<Database.MergeResult> mergeResults = getMergeResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), mergeResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize(), 'Logger buffer size was incorrect.');
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c, 'Log entry event logging level was incorrect.');
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c, 'Log entry event message was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c, 'Log entry event record id was incorrect.');
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c, 'Log entry event record JSON was incorrect.');
        System.Assert.areEqual(
            'List',
            entryBuilder.getLogEntryEvent().DatabaseResultCollectionType__c,
            'Log entry event database result collection type was incorrect.'
        );
        System.Assert.areEqual(
            JSON.serializePretty(mergeResults),
            entryBuilder.getLogEntryEvent().DatabaseResultJson__c,
            'Log entry event database result JSON was incorrect.'
        );
        System.Assert.areEqual(
            Database.MergeResult.class.getName(),
            entryBuilder.getLogEntryEvent().DatabaseResultType__c,
            'Log entry event database result type was incorrect.'
        );
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c, 'Log entry event tags field was not null.');
    }
}
