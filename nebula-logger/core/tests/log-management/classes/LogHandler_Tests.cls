//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=false)
private class LogHandler_Tests {
    private static final String HIGH_PRIORITY = Schema.Log__c.Priority__c.getDescribe().getPicklistValues().get(0).getValue();
    private static final String MEDIUM_PRIORITY = Schema.Log__c.Priority__c.getDescribe().getPicklistValues().get(1).getValue();
    private static final String LOW_PRIORITY = Schema.Log__c.Priority__c.getDescribe().getPicklistValues().get(2).getValue();

    private static final String FIRST_STATUS = Schema.Log__c.Status__c.getDescribe().getPicklistValues().get(0).getValue();
    private static final String SECOND_STATUS = Schema.Log__c.Status__c.getDescribe().getPicklistValues().get(1).getValue();

    @IsTest
    static void it_should_return_the_log_sobjectType() {
        System.Assert.areEqual(Schema.Log__c.SObjectType, new LogHandler().getSObjectType());
    }

    @IsTest
    static void it_should_not_run_when_disabled_via_configuration() {
        setupConfigurations();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations(false);
        Log__c log = new Log__c(
            ClosedBy__c = System.UserInfo.getUserId(),
            ClosedDate__c = System.now(),
            IsClosed__c = true,
            IsResolved__c = true,
            Status__c = FIRST_STATUS,
            TransactionId__c = '1234'
        );

        LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(0, LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(), 'Handler class should not have executed');
    }

    @IsTest
    static void it_should_set_hasComments_field_on_insert_when_comments_field_is_null() {
        setupConfigurations();
        Log__c log = new Log__c(Comments__c = null, TransactionId__c = '1234');

        LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        log = [SELECT Id, Comments__c, HasComments__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.isNull(log.Comments__c);
        System.Assert.isFalse(log.HasComments__c);
    }

    @IsTest
    static void it_should_set_hasComments_field_on_insert_when_comments_field_is_not_null() {
        setupConfigurations();
        String exampleComment = 'some comment';
        Log__c log = new Log__c(Comments__c = exampleComment, TransactionId__c = '1234');

        LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        log = [SELECT Id, Comments__c, HasComments__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(exampleComment, log.Comments__c);
        System.Assert.isTrue(log.HasComments__c);
    }

    @IsTest
    static void it_should_set_hasComments_field_on_update_when_comments_field_is_null() {
        setupConfigurations();
        String exampleComment = 'some comment';
        Log__c log = new Log__c(Comments__c = exampleComment, TransactionId__c = '1234');
        LoggerDataStore.getDatabase().insertRecord(log);
        log = [SELECT Id, Comments__c, HasComments__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(exampleComment, log.Comments__c);
        System.Assert.isTrue(log.HasComments__c);
        log.Comments__c = null;

        LoggerDataStore.getDatabase().updateRecord(log);

        System.Assert.areEqual(
            4,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed four times - once for BEFORE_INSERT, AFTER_INSERT, BEFORE_UPDATE, and AFTER_UPDATE'
        );
        log = [SELECT Id, Comments__c, HasComments__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.isNull(log.Comments__c);
        System.Assert.isFalse(log.HasComments__c);
    }

    @IsTest
    static void it_should_set_hasComments_field_on_update_when_comments_field_is_not_null() {
        setupConfigurations();
        Log__c log = new Log__c(Comments__c = null, TransactionId__c = '1234');
        LoggerDataStore.getDatabase().insertRecord(log);
        log = [SELECT Id, Comments__c, HasComments__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.isNull(log.Comments__c);
        System.Assert.isFalse(log.HasComments__c);
        String exampleComment = 'some comment';
        log.Comments__c = exampleComment;

        LoggerDataStore.getDatabase().updateRecord(log);

        System.Assert.areEqual(
            4,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed four times - once for BEFORE_INSERT, AFTER_INSERT, BEFORE_UPDATE, and AFTER_UPDATE'
        );
        log = [SELECT Id, Comments__c, HasComments__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(exampleComment, log.Comments__c);
        System.Assert.isTrue(log.HasComments__c);
    }

    @IsTest
    static void it_should_clear_closed_status_fields_when_open() {
        setupConfigurations();
        Log__c log = new Log__c(
            ClosedBy__c = System.UserInfo.getUserId(),
            ClosedDate__c = System.now(),
            IsClosed__c = true,
            IsResolved__c = true,
            Status__c = FIRST_STATUS,
            TransactionId__c = '1234'
        );

        LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        log = [SELECT Id, ClosedBy__c, ClosedDate__c, IsClosed__c, IsResolved__c, Status__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.isNull(log.ClosedBy__c);
        System.Assert.isNull(log.ClosedDate__c);
        System.Assert.isFalse(log.IsClosed__c);
        System.Assert.isFalse(log.IsResolved__c);
    }

    @IsTest
    static void it_should_set_closed_status_fields_when_closed() {
        setupConfigurations();
        Log__c log = new Log__c(
            ClosedBy__c = null,
            ClosedDate__c = null,
            IsClosed__c = false,
            IsResolved__c = false,
            Status__c = SECOND_STATUS,
            TransactionId__c = '1234'
        );

        LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        log = [SELECT Id, ClosedBy__c, ClosedDate__c, IsClosed__c, IsResolved__c, Status__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(System.UserInfo.getUserId(), log.ClosedBy__c);
        System.Assert.areEqual(System.today(), log.ClosedDate__c.date());
        System.Assert.isTrue(log.IsClosed__c);
    }

    @IsTest
    static void it_should_set_owner_when_default_configured_with_user_id() {
        setupConfigurations();
        User currentUser = new User(Id = System.UserInfo.getUserId(), ProfileId = System.UserInfo.getProfileId());
        User expectedLogOwnerUser = LoggerMockDataCreator.createUser();
        insert expectedLogOwnerUser;
        LoggerSettings__c currentUserSettings = Logger.getUserSettings(currentUser);
        currentUserSettings.DefaultLogOwner__c = expectedLogOwnerUser.Id;
        insert currentUserSettings;
        Log__c log = new Log__c(LoggedBy__c = currentUser.Id, OwnerId = currentUser.Id, TransactionId__c = '1234');

        LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        log = [SELECT Id, OwnerId FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(expectedLogOwnerUser.Id, log.OwnerId, JSON.serializePretty(log));
    }

    @IsTest
    static void it_should_set_owner_when_default_configured_with_username() {
        setupConfigurations();
        User currentUser = new User(Id = System.UserInfo.getUserId(), ProfileId = System.UserInfo.getProfileId());
        User expectedLogOwnerUser = LoggerMockDataCreator.createUser();
        insert expectedLogOwnerUser;
        LoggerSettings__c currentUserSettings = Logger.getUserSettings(currentUser);
        currentUserSettings.DefaultLogOwner__c = expectedLogOwnerUser.Username;
        insert currentUserSettings;
        Log__c log = new Log__c(LoggedBy__c = currentUser.Id, OwnerId = currentUser.Id, TransactionId__c = '1234');

        LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        log = [SELECT Id, OwnerId FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(expectedLogOwnerUser.Id, log.OwnerId, JSON.serializePretty(log));
    }

    @IsTest
    static void it_should_set_owner_when_default_configured_with_queue_id() {
        setupConfigurations();
        User currentUser = new User(Id = System.UserInfo.getUserId(), ProfileId = System.UserInfo.getProfileId());
        Group expectedLogOwnerQueue = LoggerMockDataCreator.insertQueue('Some_Log_Queue', Schema.Log__c.SObjectType);
        LoggerSettings__c currentUserSettings = Logger.getUserSettings(currentUser);
        currentUserSettings.DefaultLogOwner__c = expectedLogOwnerQueue.Id;
        insert currentUserSettings;
        Log__c log = new Log__c(LoggedBy__c = currentUser.Id, OwnerId = currentUser.Id, TransactionId__c = '1234');

        LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        log = [SELECT Id, OwnerId FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(expectedLogOwnerQueue.Id, log.OwnerId, JSON.serializePretty(log));
    }

    @IsTest
    static void it_should_set_owner_when_default_configured_with_queue_developer_name() {
        setupConfigurations();
        User currentUser = new User(Id = System.UserInfo.getUserId(), ProfileId = System.UserInfo.getProfileId());
        Group expectedLogOwnerQueue = LoggerMockDataCreator.insertQueue('Some_Log_Queue', Schema.Log__c.SObjectType);
        LoggerSettings__c currentUserSettings = Logger.getUserSettings(currentUser);
        currentUserSettings.DefaultLogOwner__c = expectedLogOwnerQueue.DeveloperName;
        insert currentUserSettings;
        Log__c log = new Log__c(LoggedBy__c = currentUser.Id, OwnerId = currentUser.Id, TransactionId__c = '1234');

        LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        log = [SELECT Id, OwnerId FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(expectedLogOwnerQueue.Id, log.OwnerId, JSON.serializePretty(log));
    }

    @IsTest
    static void it_should_use_current_user_as_owner_when_no_default_configured() {
        setupConfigurations();
        User currentUser = new User(Id = System.UserInfo.getUserId(), ProfileId = System.UserInfo.getProfileId());
        LoggerSettings__c currentUserSettings = Logger.getUserSettings(currentUser);
        currentUserSettings.DefaultLogOwner__c = null;
        insert currentUserSettings;
        Log__c log = new Log__c(LoggedBy__c = currentUser.Id, OwnerId = currentUser.Id, TransactionId__c = '1234');

        LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        log = [SELECT Id, OwnerId FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(System.UserInfo.getUserId(), log.OwnerId, JSON.serializePretty(log));
    }

    @IsTest
    static void it_should_skip_setting_parent_log_when_it_does_not_exist() {
        String parentLogTransactionId = 'ABC-1234';
        Log__c log = new Log__c(ParentLogTransactionId__c = parentLogTransactionId, TransactionId__c = 'XYZ-5678');

        insert log;

        log = [SELECT Id, ParentLogTransactionId__c, ParentLog__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(parentLogTransactionId, log.ParentLogTransactionId__c, JSON.serializePretty(log));
        System.Assert.isNull(log.ParentLog__c, JSON.serializePretty(log));
    }

    @IsTest
    static void it_should_set_parent_log_when_it_exists() {
        String parentLogTransactionId = 'ABC-1234';
        Log__c parentLog = new Log__c(TransactionId__c = parentLogTransactionId);
        insert parentLog;
        Log__c log = new Log__c(ParentLogTransactionId__c = parentLogTransactionId, TransactionId__c = 'XYZ-5678');

        insert log;

        log = [SELECT Id, ParentLogTransactionId__c, ParentLog__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(parentLogTransactionId, log.ParentLogTransactionId__c, JSON.serializePretty(log));
        System.Assert.areEqual(parentLog.Id, log.ParentLog__c, JSON.serializePretty(log));
    }

    @IsTest
    static void it_should_keep_existing_retention_details_when_populated() {
        setupConfigurations();
        Integer defaultDaysToRetainLog = 10;
        String defaultLogPurgeAction = 'Some Action';
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultNumberOfDaysToRetainLogs__c = defaultDaysToRetainLog;
        settings.DefaultLogPurgeAction__c = defaultLogPurgeAction;
        upsert settings;
        Integer specifiedDaysToRetainLog = 50;
        Date retentionDate = System.today().addDays(specifiedDaysToRetainLog);
        String specifiedLogPurgeAction = 'A Different Action';
        Log__c log = new Log__c(
            LoggedBy__c = System.UserInfo.getUserId(),
            LogPurgeAction__c = specifiedLogPurgeAction,
            LogRetentionDate__c = retentionDate,
            TransactionId__c = '1234'
        );

        LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        log = [SELECT Id, LogPurgeAction__c, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areNotEqual(defaultDaysToRetainLog, specifiedDaysToRetainLog);
        System.Assert.areNotEqual(defaultLogPurgeAction, specifiedLogPurgeAction);
        System.Assert.areEqual(specifiedLogPurgeAction, log.LogPurgeAction__c);
        System.Assert.areEqual(retentionDate, log.LogRetentionDate__c);
    }

    @IsTest
    static void it_should_set_retention_details_when_configured_via_logger_settings() {
        setupConfigurations();
        Integer daysToRetainLog = 90;
        Date expectedRetentionDate = System.today().addDays(daysToRetainLog);
        String expectedLogPurgeAction = 'Some Action';
        Logger.getUserSettings().DefaultNumberOfDaysToRetainLogs__c = daysToRetainLog;
        Logger.getUserSettings().DefaultLogPurgeAction__c = expectedLogPurgeAction;
        upsert Logger.getUserSettings();
        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(new Log__c(LoggedBy__c = System.UserInfo.getUserId()))
            .populateRequiredFields()
            .getRecord();

        LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        log = [SELECT Id, LogPurgeAction__c, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(expectedLogPurgeAction, log.LogPurgeAction__c);
        System.Assert.areEqual(expectedRetentionDate, log.LogRetentionDate__c);
    }

    @IsTest
    static void it_should_set_retention_details_when_configured_via_logger_scenario_rules() {
        setupConfigurations();
        Integer defaultDaysToRetainLog = 1;
        Integer daysToRetainLog = 90;
        Date expectedRetentionDate = System.today().addDays(daysToRetainLog);
        Logger.getUserSettings().DefaultNumberOfDaysToRetainLogs__c = defaultDaysToRetainLog;
        upsert Logger.getUserSettings();
        LoggerScenarioRule__mdt mockScenarioRule = new LoggerScenarioRule__mdt(
            IsEnabled__c = true,
            IsLogRetentionOverrideEnabled__c = String.valueOf(true),
            Scenario__c = 'some scenario',
            NumberOfDaysToRetainLogs__c = daysToRetainLog
        );
        LoggerTestConfigurator.setMock(mockScenarioRule);
        LoggerScenario__c loggerScenario = (LoggerScenario__c) LoggerMockDataCreator.createDataBuilder(Schema.LoggerScenario__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        loggerScenario.UniqueId__c = mockScenarioRule.Scenario__c;
        LoggerDataStore.getDatabase().insertRecord(loggerScenario);
        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        log.TransactionScenario__c = loggerScenario.Id;

        LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        log = [SELECT Id, Scenario__c, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(expectedRetentionDate, log.LogRetentionDate__c);
    }

    @IsTest
    static void it_should_have_null_retention_details_when_no_retention_configured() {
        setupConfigurations();
        LoggerSettings__c settings = Logger.getUserSettings();
        insert settings;
        settings.DefaultNumberOfDaysToRetainLogs__c = null;
        settings.DefaultLogPurgeAction__c = null;
        upsert settings;
        settings = [SELECT Id, DefaultLogPurgeAction__c FROM LoggerSettings__c WHERE Id = :settings.Id];
        System.Assert.isNull(settings.DefaultLogPurgeAction__c);
        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        log.LoggedBy__c = System.UserInfo.getUserId();
        log.ProfileId__c = System.UserInfo.getProfileId();

        LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        String defaultLogPurgeActionPicklistValue = getDefaultPicklistValue(Schema.Log__c.LogPurgeAction__c);
        log = [SELECT Id, LogPurgeAction__c, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(defaultLogPurgeActionPicklistValue, log.LogPurgeAction__c);
        System.Assert.isNull(log.LogRetentionDate__c);
    }

    @IsTest
    static void it_should_set_priority_to_high_when_there_is_an_error_log_entry() {
        setupConfigurations();
        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        log.Priority__c = LOW_PRIORITY;
        LoggerDataStore.getDatabase().insertRecord(log);
        log = [SELECT Id, Priority__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(LOW_PRIORITY, log.Priority__c);

        insert LoggerMockDataCreator.createDataBuilder(new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name()))
            .populateRequiredFields()
            .getRecord();

        System.Assert.areEqual(
            4,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed four times - two times for BEFORE_INSERT/AFTER_INSERT' +
            ' and two more times for BEFORE_UPDATE/AFTER_UPDATE (triggered indirectly by the insert of a related LogEntry__c record)'
        );
        log = [SELECT Id, Priority__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(HIGH_PRIORITY, log.Priority__c);
    }

    @IsTest
    static void it_should_set_priority_to_medium_when_there_is_a_warn_log_entry() {
        setupConfigurations();
        Log__c log = new Log__c(Priority__c = LOW_PRIORITY, TransactionId__c = '1234');
        LoggerDataStore.getDatabase().insertRecord(log);
        log = [SELECT Id, Priority__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(LOW_PRIORITY, log.Priority__c);

        insert new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'WARN');

        System.Assert.areEqual(
            4,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed four times - two times for BEFORE_INSERT/AFTER_INSERT' +
            ' and two more times for BEFORE_UPDATE/AFTER_UPDATE (triggered indirectly by the insert of a related LogEntry__c record)'
        );
        log = [SELECT Id, Priority__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(MEDIUM_PRIORITY, log.Priority__c);
    }

    @IsTest
    static void it_should_grant_read_access_to_user_when_access_level_is_read() {
        setupConfigurations();
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultLogShareAccessLevel__c = 'Read';
        upsert settings;
        Log__c log = new Log__c(LoggedBy__c = System.UserInfo.getUserId(), TransactionId__c = '1234');

        LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        List<Log__Share> logShares = [SELECT AccessLevel, ParentId, RowCause, UserOrGroupId FROM Log__Share WHERE ParentId = :log.Id AND AccessLevel != 'All'];
        System.Assert.areEqual(1, logShares.size(), JSON.serializePretty(logShares));
        System.Assert.areEqual('Read', logShares.get(0).AccessLevel);
        System.Assert.areEqual(log.Id, logShares.get(0).ParentId);
        System.Assert.areEqual(Schema.Log__Share.RowCause.LoggedByUser__c, logShares.get(0).RowCause);
        System.Assert.areEqual(log.LoggedBy__c, logShares.get(0).UserOrGroupId);
    }

    @IsTest
    static void it_should_grant_edit_access_to_user_when_access_level_is_edit() {
        setupConfigurations();
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultLogShareAccessLevel__c = 'Edit';
        upsert settings;
        Log__c log = new Log__c(LoggedBy__c = System.UserInfo.getUserId(), TransactionId__c = '1234');

        LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        List<Log__Share> logShares = [SELECT AccessLevel, ParentId, RowCause, UserOrGroupId FROM Log__Share WHERE ParentId = :log.Id AND AccessLevel != 'All'];
        System.Assert.areEqual(1, logShares.size(), JSON.serializePretty(logShares));
        System.Assert.areEqual('Edit', logShares.get(0).AccessLevel);
        System.Assert.areEqual(log.Id, logShares.get(0).ParentId);
        System.Assert.areEqual(Schema.Log__Share.RowCause.LoggedByUser__c, logShares.get(0).RowCause);
        System.Assert.areEqual(log.LoggedBy__c, logShares.get(0).UserOrGroupId);
    }

    @IsTest
    static void it_should_not_grant_access_to_user_when_access_level_is_null() {
        setupConfigurations();
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultLogShareAccessLevel__c = null;
        upsert settings;
        Log__c log = new Log__c(LoggedBy__c = System.UserInfo.getUserId(), TransactionId__c = '1234');

        LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        List<Log__Share> logShares = [SELECT AccessLevel, ParentId, RowCause, UserOrGroupId FROM Log__Share WHERE ParentId = :log.Id AND AccessLevel != 'All'];
        System.Assert.areEqual(0, logShares.size(), JSON.serializePretty(logShares));
    }

    @IsTest
    static void it_should_not_grant_access_to_user_when_access_level_is_an_unknown_string() {
        setupConfigurations();
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultLogShareAccessLevel__c = 'FAKE LEVEL';
        upsert settings;
        Log__c log = new Log__c(LoggedBy__c = System.UserInfo.getUserId(), TransactionId__c = '1234');

        LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.Log__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        List<Log__Share> logShares = [SELECT AccessLevel, ParentId, RowCause, UserOrGroupId FROM Log__Share WHERE ParentId = :log.Id AND AccessLevel != 'All'];
        System.Assert.areEqual(0, logShares.size(), JSON.serializePretty(logShares));
    }

    private static String getDefaultPicklistValue(Schema.SObjectField field) {
        List<Schema.PicklistEntry> picklistEntries = field.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry picklistEntry : picklistEntries) {
            if (picklistEntry.isDefaultValue()) {
                return picklistEntry.getValue();
            }
        }
        return null;
    }

    private static void setupConfigurations() {
        LogStatus__mdt openStatus = new LogStatus__mdt(IsActive__c = true, MasterLabel = FIRST_STATUS, IsClosed__c = false, IsResolved__c = false);
        LoggerTestConfigurator.setMock(openStatus);

        LogStatus__mdt closedStatus = new LogStatus__mdt(IsActive__c = true, MasterLabel = SECOND_STATUS, IsClosed__c = true, IsResolved__c = true);
        LoggerTestConfigurator.setMock(closedStatus);
    }
}
