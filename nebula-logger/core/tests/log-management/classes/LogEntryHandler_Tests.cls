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
        System.Assert.areEqual(Schema.LogEntry__c.SObjectType, new LogEntryHandler().getSObjectType());
    }

    @IsTest
    static void it_should_not_run_when_disabled_via_configuration() {
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.Assert.areEqual(
            0,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should not have executed'
        );
    }

    @IsTest
    static void it_should_save_log_entry_without_related_record_id() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = null);

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, RecordId__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.isNull(logEntry.RecordId__c);
    }

    @IsTest
    static void it_should_populate_related_record_fields_on_log_entry_with_related_user_record_id() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        User currentUser = [SELECT Id, Username FROM User WHERE Id = :System.UserInfo.getUserId()];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = currentUser.Id);

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, RecordId__c, RecordName__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.areEqual(currentUser.Id, logEntry.RecordId__c);
        System.Assert.areEqual(currentUser.Username, logEntry.RecordName__c);
    }

    @IsTest
    static void it_should_populate_related_record_fields_on_log_entry_with_related_profile_record_id() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        Profile currentProfile = [SELECT Id, Name FROM Profile WHERE Id = :System.UserInfo.getProfileId()];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = currentProfile.Id);

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, RecordId__c, RecordName__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.areEqual(currentProfile.Id, logEntry.RecordId__c);
        System.Assert.areEqual(currentProfile.Name, logEntry.RecordName__c);
    }

    @IsTest
    static void it_should_not_populate_related_record_fields_on_log_entry_with_related_template_standard_object_record_id() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        Id templateSObjectRecordId = LoggerMockDataCreator.createId(Schema.CaseComment.SObjectType);
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = templateSObjectRecordId);

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, RecordId__c, RecordName__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.areEqual(templateSObjectRecordId, logEntry.RecordId__c);
        System.Assert.isNull(logEntry.RecordName__c);
    }

    @IsTest
    static void it_should_not_populate_related_record_fields_on_log_entry_when_disabled_via_logger_parameter() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        User currentUser = [SELECT Id, Username FROM User WHERE Id = :System.UserInfo.getUserId()];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = currentUser.Id);
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryRelatedRecordData', Value__c = String.valueOf(false)));

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, RecordId__c, RecordName__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.areEqual(currentUser.Id, logEntry.RecordId__c);
        System.Assert.isNull(logEntry.RecordName__c);
    }

    @IsTest
    static void it_should_set_hasRecordJson_to_true_when_populated_on_insert() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        String recordJson = '{}';
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordJson__c = recordJson);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, HasRecordJson__c, RecordJson__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.areEqual(true, logEntry.HasRecordJson__c);
        System.Assert.areEqual(recordJson, logEntry.RecordJson__c);
    }

    @IsTest
    static void it_should_set_hasRecordJson_to_false_when_not_populated_on_insert() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        String recordJson = null;
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordJson__c = recordJson);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, HasRecordJson__c, RecordJson__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.areEqual(false, logEntry.HasRecordJson__c);
        System.Assert.isNull(logEntry.RecordJson__c);
    }

    @IsTest
    static void it_should_set_hasRecordJson_to_true_when_populated_on_updated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordJson__c = null);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();
        LoggerDataStore.getDatabase().insertRecord(logEntry);
        logEntry = [SELECT Id, RecordJson__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.isNull(logEntry.RecordJson__c);
        String recordJson = '{}';
        logEntry.RecordJson__c = recordJson;

        update logEntry;

        System.Assert.areEqual(
            4,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed four times - two times for BEFORE_INSERT/AFTER_INSERT' + ' and two more times for BEFORE_UPDATE/AFTER_UPDATE'
        );
        logEntry = [SELECT Id, HasRecordJson__c, RecordJson__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.areEqual(true, logEntry.HasRecordJson__c);
        System.Assert.areEqual(recordJson, logEntry.RecordJson__c);
    }

    @IsTest
    static void it_should_set_hasRecordJson_to_false_when_not_populated_on_updated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        String recordJson = '{}';
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordJson__c = recordJson);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();
        LoggerDataStore.getDatabase().insertRecord(logEntry);
        logEntry = [SELECT Id, RecordJson__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.isNotNull(logEntry.RecordJson__c);
        logEntry.RecordJson__c = null;

        update logEntry;

        System.Assert.areEqual(
            4,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed four times - two times for BEFORE_INSERT/AFTER_INSERT' + ' and two more times for BEFORE_UPDATE/AFTER_UPDATE'
        );
        logEntry = [SELECT Id, HasRecordJson__c, RecordJson__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.areEqual(false, logEntry.HasRecordJson__c);
        System.Assert.isNull(logEntry.RecordJson__c);
    }

    @IsTest
    static void it_should_set_hasExceptionStackTrace_to_false_when_null() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, ExceptionStackTrace__c = null);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, HasExceptionStackTrace__c, ExceptionStackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.isTrue(!logEntry.HasExceptionStackTrace__c);
        System.Assert.isNull(logEntry.ExceptionStackTrace__c);
    }

    @IsTest
    static void it_should_set_hasExceptionStackTrace_to_true_when_populated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        String stackTrace = 'something';
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, ExceptionStackTrace__c = stackTrace);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, HasExceptionStackTrace__c, ExceptionStackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.isTrue(logEntry.HasExceptionStackTrace__c);
        System.Assert.areEqual(stackTrace, logEntry.ExceptionStackTrace__c);
    }

    @IsTest
    static void it_should_set_hasExceptionStackTrace_to_true_when_updated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, ExceptionStackTrace__c = null);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();
        LoggerDataStore.getDatabase().insertRecord(logEntry);
        logEntry = [SELECT Id, ExceptionStackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.isNull(logEntry.ExceptionStackTrace__c);

        String stackTrace = 'something';
        logEntry.ExceptionStackTrace__c = stackTrace;
        update logEntry;

        System.Assert.areEqual(
            4,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed four times - two times for BEFORE_INSERT/AFTER_INSERT' + ' and two more times for BEFORE_UPDATE/AFTER_UPDATE'
        );
        logEntry = [SELECT Id, HasExceptionStackTrace__c, ExceptionStackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.isTrue(logEntry.HasExceptionStackTrace__c);
        System.Assert.areEqual(stackTrace, logEntry.ExceptionStackTrace__c);
    }

    @IsTest
    static void it_should_set_hasStackTrace_to_false_when_null() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, StackTrace__c = null);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, HasStackTrace__c, StackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.isTrue(!logEntry.HasStackTrace__c);
        System.Assert.isNull(logEntry.StackTrace__c);
    }

    @IsTest
    static void it_should_set_hasStackTrace_to_true_when_populated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        String stackTrace = 'something';
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, StackTrace__c = stackTrace);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        logEntry = [SELECT Id, HasStackTrace__c, StackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.isTrue(logEntry.HasStackTrace__c);
        System.Assert.areEqual(stackTrace, logEntry.StackTrace__c);
    }

    @IsTest
    static void it_should_set_hasStackTrace_to_true_when_updated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, StackTrace__c = null);
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();
        LoggerDataStore.getDatabase().insertRecord(logEntry);
        logEntry = [SELECT Id, StackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.isNull(logEntry.StackTrace__c);

        String stackTrace = 'something';
        logEntry.StackTrace__c = stackTrace;
        update logEntry;

        System.Assert.areEqual(
            4,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should have executed four times - two times for BEFORE_INSERT/AFTER_INSERT' + ' and two more times for BEFORE_UPDATE/AFTER_UPDATE'
        );
        logEntry = [SELECT Id, HasStackTrace__c, StackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.Assert.isTrue(logEntry.HasStackTrace__c);
        System.Assert.areEqual(stackTrace, logEntry.StackTrace__c);
    }

    @IsTest
    static void it_should_set_skip_setting_apex_class_details_when_origin_location_is_null() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, OriginLocation__c = null, OriginType__c = 'Apex');
        LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

        LoggerDataStore.getDatabase().insertRecord(logEntry);

        System.Assert.areEqual(
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
        System.Assert.areEqual('Apex', logEntry.OriginType__c);
        System.Assert.isNull(logEntry.OriginLocation__c);
        System.Assert.isNull(logEntry.ApexClassApiVersion__c);
        System.Assert.isNull(logEntry.ApexClassCreatedDate__c);
        System.Assert.isNull(logEntry.ApexClassId__c);
        System.Assert.isNull(logEntry.ApexClassLastModifiedDate__c);
        System.Assert.isNull(logEntry.ApexClassName__c);
        System.Assert.isNull(logEntry.ApexInnerClassName__c);
        System.Assert.isNull(logEntry.ApexMethodName__c);
    }

    @IsTest
    static void it_should_set_apex_class_details_for_top_level_class() {
        // FIXME the implementation does not seem to properly handle classes with a namespace prefix
        // (including when both the managed & unlocked packages are installed in an org), so skip the tests for now,
        // but revisit this test + implementation
        if (String.isNotBlank(Logger.getNamespacePrefix()) == true) {
            return;
        }

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

        System.Assert.areEqual(
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
        System.Assert.areEqual(exampleTopLevelClassMethodName, logEntry.OriginLocation__c);
        System.Assert.areEqual('v' + apexClass.ApiVersion, logEntry.ApexClassApiVersion__c);
        System.Assert.areEqual(apexClass.CreatedDate, logEntry.ApexClassCreatedDate__c);
        System.Assert.areEqual(apexClass.Id, logEntry.ApexClassId__c);
        System.Assert.areEqual(apexClass.LastModifiedDate, logEntry.ApexClassLastModifiedDate__c);
        System.Assert.areEqual(exampleTopLevelClassName, logEntry.ApexClassName__c);
        System.Assert.isNull(logEntry.ApexInnerClassName__c);
        System.Assert.areEqual(methodName, logEntry.ApexMethodName__c);
    }

    @IsTest
    static void it_should_set_apex_class_details_for_inner_class() {
        // FIXME the implementation does not seem to properly handle classes with a namespace prefix
        // (including when both the managed & unlocked packages are installed in an org), so skip the tests for now,
        // but revisit this test + implementation
        if (String.isNotBlank(Logger.getNamespacePrefix()) == true) {
            return;
        }

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

        System.Assert.areEqual(
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
        System.Assert.areEqual(exampleInnerClassMethodName, logEntry.OriginLocation__c);
        System.Assert.areEqual('v' + apexClass.ApiVersion, logEntry.ApexClassApiVersion__c);
        System.Assert.areEqual(apexClass.CreatedDate, logEntry.ApexClassCreatedDate__c);
        System.Assert.areEqual(apexClass.Id, logEntry.ApexClassId__c);
        System.Assert.areEqual(apexClass.LastModifiedDate, logEntry.ApexClassLastModifiedDate__c);
        System.Assert.areEqual(exampleTopLevelClassName, logEntry.ApexClassName__c);
        System.Assert.areEqual(exampleInnerClassName, logEntry.ApexInnerClassName__c);
        System.Assert.areEqual(methodName, logEntry.ApexMethodName__c);
    }

    private static String getNamespacePrefix() {
        String className = LogEntryHandler_Tests.class.getName();
        String namespacePrefix = className.contains('.') ? className.substringBefore('.') : '';

        return namespacePrefix;
    }

    private class MockLogManagementDataSelector extends LogManagementDataSelector {
        private Integer apexClassesQueryCount = 0;

        public override List<ApexClass> getApexClasses(List<String> apexClassNames) {
            this.apexClassesQueryCount++;
            return super.getApexClasses(apexClassNames);
        }

        public Integer getApexClassesQueryCount() {
            return apexClassesQueryCount;
        }
    }
}
