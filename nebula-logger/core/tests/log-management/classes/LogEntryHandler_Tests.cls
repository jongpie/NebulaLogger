//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class LogEntryHandler_Tests {
    @TestSetup
    static void setupData() {
        LoggerSObjectHandler.shouldExecute(false);
        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        insert log;
        System.Test.setCreatedDate(log.Id, System.now().addDays(-8));
    }

    @IsTest
    static void it_should_return_the_logEntry_sobjectType() {
        System.assertEquals(Schema.LogEntry__c.SObjectType, new LogEntryHandler().getSObjectType());
    }

    @IsTest
    static void it_should_not_run_when_disabled_via_configuration() {
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.assertEquals(0, LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(), 'Handler class should not have executed');
    }

    @IsTest
    static void it_should_save_log_entry_without_related_record_id() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = null);

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.assertEquals(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, RecordId__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(null, logEntry.RecordId__c);
    }

    @IsTest
    static void it_should_populate_related_record_fields_on_log_entry_with_related_user_record_id() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        User currentUser = [SELECT Id, Username FROM User WHERE Id = :UserInfo.getUserId()];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = currentUser.Id);

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.assertEquals(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, RecordId__c, RecordName__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(currentUser.Id, logEntry.RecordId__c);
        System.assertEquals(currentUser.Username, logEntry.RecordName__c);
    }

    @IsTest
    static void it_should_populate_related_record_fields_on_log_entry_with_related_profile_record_id() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        Profile currentProfile = [SELECT Id, Name, Description FROM Profile WHERE Id = :UserInfo.getProfileId()];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = currentProfile.Id);

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.assertEquals(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, RecordId__c, RecordName__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(currentProfile.Id, logEntry.RecordId__c);
        System.assertEquals(currentProfile.Name, logEntry.RecordName__c);
    }

    @IsTest
    static void it_should_set_hasRecordJson_to_true_when_populated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        String recordJson = '{}';
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordJson__c = recordJson);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.assertEquals(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, HasRecordJson__c, RecordJson__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(logEntry.HasRecordJson__c);
        System.assertEquals(recordJson, logEntry.RecordJson__c);
    }

    @IsTest
    static void it_should_set_hasRecordJson_to_true_when_updated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordJson__c = null);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();
        LoggerDataStore.getDatabase().insertRecord(logEntry);
        logEntry = [SELECT Id, RecordJson__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(null, logEntry.RecordJson__c);
        String recordJson = '{}';
        logEntry.RecordJson__c = recordJson;

        update logEntry;

        System.assertEquals(
            4,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed four times - two times for BEFORE_INSERT/AFTER_INSERT' + ' and two more times for BEFORE_UPDATE/AFTER_UPDATE'
        );
        logEntry = [SELECT Id, HasRecordJson__c, RecordJson__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(logEntry.HasRecordJson__c);
        System.assertEquals(recordJson, logEntry.RecordJson__c);
    }

    @IsTest
    static void it_should_set_hasExceptionStackTrace_to_false_when_null() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, ExceptionStackTrace__c = null);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.assertEquals(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, HasExceptionStackTrace__c, ExceptionStackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(!logEntry.HasExceptionStackTrace__c);
        System.assertEquals(null, logEntry.ExceptionStackTrace__c);
    }

    @IsTest
    static void it_should_set_hasExceptionStackTrace_to_true_when_populated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        String stackTrace = 'something';
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, ExceptionStackTrace__c = stackTrace);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.assertEquals(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, HasExceptionStackTrace__c, ExceptionStackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(logEntry.HasExceptionStackTrace__c);
        System.assertEquals(stackTrace, logEntry.ExceptionStackTrace__c);
    }

    @IsTest
    static void it_should_set_hasExceptionStackTrace_to_true_when_updated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, ExceptionStackTrace__c = null);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();
        LoggerDataStore.getDatabase().insertRecord(logEntry);
        logEntry = [SELECT Id, ExceptionStackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(null, logEntry.ExceptionStackTrace__c);

        String stackTrace = 'something';
        logEntry.ExceptionStackTrace__c = stackTrace;
        update logEntry;

        System.assertEquals(
            4,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed four times - two times for BEFORE_INSERT/AFTER_INSERT' + ' and two more times for BEFORE_UPDATE/AFTER_UPDATE'
        );
        logEntry = [SELECT Id, HasExceptionStackTrace__c, ExceptionStackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(logEntry.HasExceptionStackTrace__c);
        System.assertEquals(stackTrace, logEntry.ExceptionStackTrace__c);
    }

    @IsTest
    static void it_should_set_hasStackTrace_to_false_when_null() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, StackTrace__c = null);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.assertEquals(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, HasStackTrace__c, StackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(!logEntry.HasStackTrace__c);
        System.assertEquals(null, logEntry.StackTrace__c);
    }

    @IsTest
    static void it_should_set_hasStackTrace_to_true_when_populated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        String stackTrace = 'something';
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, StackTrace__c = stackTrace);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.assertEquals(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, HasStackTrace__c, StackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(logEntry.HasStackTrace__c);
        System.assertEquals(stackTrace, logEntry.StackTrace__c);
    }

    @IsTest
    static void it_should_set_hasStackTrace_to_true_when_updated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, StackTrace__c = null);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();
        LoggerDataStore.getDatabase().insertRecord(logEntry);
        logEntry = [SELECT Id, StackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(null, logEntry.StackTrace__c);

        String stackTrace = 'something';
        logEntry.StackTrace__c = stackTrace;
        update logEntry;

        System.assertEquals(
            4,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed four times - two times for BEFORE_INSERT/AFTER_INSERT' + ' and two more times for BEFORE_UPDATE/AFTER_UPDATE'
        );
        logEntry = [SELECT Id, HasStackTrace__c, StackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(logEntry.HasStackTrace__c);
        System.assertEquals(stackTrace, logEntry.StackTrace__c);
    }

    @IsTest
    static void it_should_set_skip_setting_apex_class_details_when_origin_location_is_null() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, OriginLocation__c = null, OriginType__c = 'Apex');
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.assertEquals(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [
            SELECT
                Id,
                ApexClassApiVersion__c,
                ApexClassCreatedDate__c,
                ApexClassId__c,
                ApexClassLastModifiedDate__c,
                ApexClassName__c,
                ApexInnerClassName__c,
                ApexMethodName__c,
                OriginLocation__c,
                OriginType__c
            FROM LogEntry__c
            WHERE Id = :logEntry.Id
        ];
        System.assertEquals('Apex', logEntry.OriginType__c);
        System.assertEquals(null, logEntry.OriginLocation__c);
        System.assertEquals(null, logEntry.ApexClassApiVersion__c);
        System.assertEquals(null, logEntry.ApexClassCreatedDate__c);
        System.assertEquals(null, logEntry.ApexClassId__c);
        System.assertEquals(null, logEntry.ApexClassLastModifiedDate__c);
        System.assertEquals(null, logEntry.ApexClassName__c);
        System.assertEquals(null, logEntry.ApexInnerClassName__c);
        System.assertEquals(null, logEntry.ApexMethodName__c);
    }

    @IsTest
    static void it_should_set_apex_class_details_for_top_level_class() {
        String exampleTopLevelClassName = 'Logger';
        String methodName = 'saveLog';
        String exampleTopLevelClassMethodName = exampleTopLevelClassName + '. ' + methodName;
        ApexClass apexClass = [
            SELECT Id, ApiVersion, CreatedDate, LastModifiedDate
            FROM ApexClass
            WHERE NamespacePrefix = :getNamespacePrefix() AND Name = :exampleTopLevelClassName
        ];
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, OriginLocation__c = exampleTopLevelClassMethodName, OriginType__c = 'Apex');
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.assertEquals(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [
            SELECT
                Id,
                ApexClassApiVersion__c,
                ApexClassCreatedDate__c,
                ApexClassId__c,
                ApexClassLastModifiedDate__c,
                ApexClassName__c,
                ApexInnerClassName__c,
                ApexMethodName__c,
                OriginLocation__c
            FROM LogEntry__c
            WHERE Id = :logEntry.Id
        ];
        System.assertEquals(exampleTopLevelClassMethodName, logEntry.OriginLocation__c);
        System.assertEquals('v' + apexClass.ApiVersion, logEntry.ApexClassApiVersion__c);
        System.assertEquals(apexClass.CreatedDate, logEntry.ApexClassCreatedDate__c);
        System.assertEquals(apexClass.Id, logEntry.ApexClassId__c);
        System.assertEquals(apexClass.LastModifiedDate, logEntry.ApexClassLastModifiedDate__c);
        System.assertEquals(exampleTopLevelClassName, logEntry.ApexClassName__c);
        System.assertEquals(null, logEntry.ApexInnerClassName__c);
        System.assertEquals(methodName, logEntry.ApexMethodName__c);
    }

    @IsTest
    static void it_should_set_apex_class_details_for_inner_class() {
        String exampleTopLevelClassName = 'Logger';
        String exampleInnerClassName = 'QueueableSaver';
        String methodName = 'execute';
        String exampleInnerClassMethodName = exampleTopLevelClassName + '.' + exampleInnerClassName + '.' + methodName;
        ApexClass apexClass = [
            SELECT Id, ApiVersion, CreatedDate, LastModifiedDate
            FROM ApexClass
            WHERE NamespacePrefix = :getNamespacePrefix() AND Name = :exampleTopLevelClassName
        ];
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, OriginLocation__c = exampleInnerClassMethodName, OriginType__c = 'Apex');
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.assertEquals(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [
            SELECT
                Id,
                ApexClassApiVersion__c,
                ApexClassCreatedDate__c,
                ApexClassId__c,
                ApexClassLastModifiedDate__c,
                ApexClassName__c,
                ApexInnerClassName__c,
                ApexMethodName__c,
                OriginLocation__c
            FROM LogEntry__c
            WHERE Id = :logEntry.Id
        ];
        System.assertEquals(exampleInnerClassMethodName, logEntry.OriginLocation__c);
        System.assertEquals('v' + apexClass.ApiVersion, logEntry.ApexClassApiVersion__c);
        System.assertEquals(apexClass.CreatedDate, logEntry.ApexClassCreatedDate__c);
        System.assertEquals(apexClass.Id, logEntry.ApexClassId__c);
        System.assertEquals(apexClass.LastModifiedDate, logEntry.ApexClassLastModifiedDate__c);
        System.assertEquals(exampleTopLevelClassName, logEntry.ApexClassName__c);
        System.assertEquals(exampleInnerClassName, logEntry.ApexInnerClassName__c);
        System.assertEquals(methodName, logEntry.ApexMethodName__c);
    }

    private static String getNamespacePrefix() {
        String className = LogEntryHandler_Tests.class.getName();
        String namespacePrefix = className.contains('.') ? className.substringBefore('.') : '';

        return namespacePrefix;
    }
}
