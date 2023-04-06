//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @description Test class for LoggerSObjectHandler, the trigger-handler framework used by Nebula Logger.
 *              To demonstrate that the framework is standalone/would work with any SObject, these test methods
 *              all use mock implementations of the handler, using the `User` SObject
 */
@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerSObjectHandler_Tests {
    private static final String FAKE_PROFILE_NAME = 'Some String';

    @IsTest
    static void it_should_return_configured_sobject_handler() {
        Schema.SObjectType sobjectType = new MockSObjectHandler().getSObjectType();
        LoggerSObjectHandler.setMock(
            new LoggerSObjectHandler__mdt(
                IsEnabled__c = true,
                SObjectHandlerApexClass__c = MockSObjectHandler.class.getName(),
                SObjectType__c = sobjectType.getDescribe().getName()
            )
        );

        LoggerSObjectHandler configuredInstance = LoggerSObjectHandler.getHandler(sobjectType);

        System.Assert.isInstanceOfType(
            configuredInstance,
            MockSObjectHandler.class,
            'The returned handler should be an instance of the configured class, MockSObjectHandler'
        );
    }

    @IsTest
    static void it_should_return_handler_via_override() {
        Schema.SObjectType sobjectType = new MockSObjectHandler().getSObjectType();
        LoggerSObjectHandler.setMock(
            new LoggerSObjectHandler__mdt(
                IsEnabled__c = true,
                SObjectHandlerApexClass__c = MockSObjectHandler.class.getName(),
                SObjectTypeOverride__c = sobjectType.getDescribe().getName()
            )
        );

        LoggerSObjectHandler configuredInstance = LoggerSObjectHandler.getHandler(sobjectType);

        System.Assert.isInstanceOfType(
            configuredInstance,
            MockSObjectHandler.class,
            'The handler returned via override should be an instance of the configured class, MockSObjectHandler'
        );
    }

    @IsTest
    static void it_should_return_default_sobject_handler_implementation_when_no_configuration_provided() {
        Schema.SObjectType sobjectType = new MockDefaultImplementationSObjectHandler().getSObjectType();
        LoggerSObjectHandler defaultImplementation = new MockDefaultImplementationSObjectHandler();

        LoggerSObjectHandler configuredInstance = LoggerSObjectHandler.getHandler(sobjectType, defaultImplementation);

        System.Assert.isInstanceOfType(
            configuredInstance,
            MockDefaultImplementationSObjectHandler.class,
            'The returned handler should be an instance of the default implementation class, MockDefaultImplementationSObjectHandler'
        );
    }

    @IsTest
    static void it_should_override_triggerable_context() {
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.User.SObjectType);
        LoggerTriggerableContext originalContext = mockHandler.input;
        LoggerTriggerableContext customContext = new LoggerTriggerableContext(
            Schema.User.SObjectType,
            TriggerOperation.BEFORE_INSERT,
            new List<User>{ new User(Id = System.UserInfo.getUserId(), Email = System.UserInfo.getUserEmail()) }
        );
        System.Assert.areNotEqual(originalContext, customContext);

        mockHandler.overrideTriggerableContext(customContext);

        System.Assert.areNotEqual(originalContext, mockHandler.input);
        System.Assert.areEqual(customContext, mockHandler.input);
    }

    @IsTest
    static void it_should_not_run_when_disabled_via_logger_parameter() {
        User mockUser = (User) LoggerMockDataCreator.createUser();
        mockUser.Id = LoggerMockDataCreator.createId(Schema.User.SObjectType);
        List<SObject> records = new List<User>{ mockUser };
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.User.SObjectType);
        mockHandler.handlerConfiguration = new LoggerSObjectHandler__mdt(IsEnabled__c = false);
        mockHandler.triggerOperationType = TriggerOperation.BEFORE_INSERT;
        mockHandler.triggerNew = records;
        mockHandler.triggerNewMap = null;
        mockHandler.triggerOldMap = null;

        mockHandler.execute();

        System.Assert.areEqual(0, mockHandler.executionCount, mockHandler.toString());
    }

    @IsTest
    static void it_should_not_run_when_disabled_via_private_method() {
        User mockUser = (User) LoggerMockDataCreator.createUser();
        mockUser.Id = LoggerMockDataCreator.createId(Schema.User.SObjectType);
        List<SObject> records = new List<User>{ mockUser };
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.User.SObjectType);
        mockHandler.handlerConfiguration = new LoggerSObjectHandler__mdt(IsEnabled__c = true);
        mockHandler.triggerOperationType = TriggerOperation.BEFORE_INSERT;
        mockHandler.triggerNew = records;
        mockHandler.triggerNewMap = null;
        mockHandler.triggerOldMap = null;

        LoggerSObjectHandler.shouldExecute(false);
        mockHandler.execute();

        System.Assert.areEqual(0, mockHandler.executionCount, mockHandler.toString());
    }

    @IsTest
    static void it_should_run_before_insert_method() {
        User mockUser = (User) LoggerMockDataCreator.createUser();
        mockUser.Id = LoggerMockDataCreator.createId(Schema.User.SObjectType);
        List<SObject> records = new List<User>{ mockUser };
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.User.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.BEFORE_INSERT;
        mockHandler.triggerNew = records;
        mockHandler.triggerNewMap = null;
        mockHandler.triggerOldMap = null;

        mockHandler.execute();

        System.Assert.areEqual(1, mockHandler.executionCount);
        System.Assert.areEqual(TriggerOperation.BEFORE_INSERT, mockHandler.executedTriggerOperationType);
        System.Assert.areEqual(mockHandler.triggerNew, mockHandler.executedTriggerNew);
        System.Assert.isNull(mockHandler.executedTriggerNewMap);
        System.Assert.isNull(mockHandler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_run_before_update_method() {
        User mockUser = (User) LoggerMockDataCreator.createUser();
        mockUser.Id = LoggerMockDataCreator.createId(Schema.User.SObjectType);
        List<SObject> records = new List<User>{ mockUser };
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.User.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.BEFORE_UPDATE;
        mockHandler.triggerNew = null;
        mockHandler.triggerNewMap = new Map<Id, SObject>(records);
        mockHandler.triggerOldMap = new Map<Id, SObject>(records);

        mockHandler.execute();

        System.Assert.areEqual(1, mockHandler.executionCount);
        System.Assert.areEqual(TriggerOperation.BEFORE_UPDATE, mockHandler.executedTriggerOperationType);
        System.Assert.isNull(mockHandler.executedTriggerNew);
        System.Assert.areEqual(mockHandler.triggerNewMap, mockHandler.executedTriggerNewMap);
        System.Assert.areEqual(mockHandler.triggerOldMap, mockHandler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_run_before_delete_method() {
        User mockUser = (User) LoggerMockDataCreator.createUser();
        mockUser.Id = LoggerMockDataCreator.createId(Schema.User.SObjectType);
        List<SObject> records = new List<User>{ mockUser };
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.User.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.BEFORE_DELETE;
        mockHandler.triggerNew = null;
        mockHandler.triggerNewMap = new Map<Id, SObject>(records);
        mockHandler.triggerOldMap = null;

        mockHandler.execute();

        System.Assert.areEqual(1, mockHandler.executionCount);
        System.Assert.areEqual(TriggerOperation.BEFORE_DELETE, mockHandler.executedTriggerOperationType);
        System.Assert.isNull(mockHandler.executedTriggerNew);
        System.Assert.areEqual(mockHandler.triggerNewMap, mockHandler.executedTriggerNewMap);
        System.Assert.isNull(mockHandler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_run_after_insert_methods() {
        // To handle AFTER_INSERT on LogEntryEvent__e, LoggerSObjectHandler has 2 methods - one with
        // a list of SObject records (triggerNew), and another with a map of SObject records (triggerNewMap)
        User mockUser = (User) LoggerMockDataCreator.createUser();
        mockUser.Id = LoggerMockDataCreator.createId(Schema.User.SObjectType);
        List<SObject> records = new List<User>{ mockUser };
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.User.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.AFTER_INSERT;
        mockHandler.triggerNew = records;
        mockHandler.triggerNewMap = new Map<Id, SObject>(records);
        mockHandler.triggerOldMap = null;

        mockHandler.execute();

        System.Assert.areEqual(2, mockHandler.executionCount);
        System.Assert.areEqual(TriggerOperation.AFTER_INSERT, mockHandler.executedTriggerOperationType);
        System.Assert.areEqual(mockHandler.triggerNew, mockHandler.executedTriggerNew);
        System.Assert.areEqual(mockHandler.triggerNewMap, mockHandler.executedTriggerNewMap);
        System.Assert.isNull(mockHandler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_run_after_update_method() {
        User mockUser = (User) LoggerMockDataCreator.createUser();
        mockUser.Id = LoggerMockDataCreator.createId(Schema.User.SObjectType);
        List<SObject> records = new List<User>{ mockUser };
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.User.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.AFTER_UPDATE;
        mockHandler.triggerNew = null;
        mockHandler.triggerNewMap = new Map<Id, SObject>(records);
        mockHandler.triggerOldMap = new Map<Id, SObject>(records);

        mockHandler.execute();

        System.Assert.areEqual(1, mockHandler.executionCount);
        System.Assert.areEqual(TriggerOperation.AFTER_UPDATE, mockHandler.executedTriggerOperationType);
        System.Assert.isNull(mockHandler.executedTriggerNew);
        System.Assert.areEqual(mockHandler.triggerNewMap, mockHandler.executedTriggerNewMap);
        System.Assert.areEqual(mockHandler.triggerOldMap, mockHandler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_run_after_delete_method() {
        User mockUser = (User) LoggerMockDataCreator.createUser();
        mockUser.Id = LoggerMockDataCreator.createId(Schema.User.SObjectType);
        List<SObject> records = new List<User>{ mockUser };
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.User.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.AFTER_DELETE;
        mockHandler.triggerNew = null;
        mockHandler.triggerNewMap = new Map<Id, SObject>(records);
        mockHandler.triggerOldMap = null;

        mockHandler.execute();

        System.Assert.areEqual(1, mockHandler.executionCount);
        System.Assert.areEqual(TriggerOperation.AFTER_DELETE, mockHandler.executedTriggerOperationType);
        System.Assert.isNull(mockHandler.executedTriggerNew);
        System.Assert.areEqual(mockHandler.triggerNewMap, mockHandler.executedTriggerNewMap);
        System.Assert.isNull(mockHandler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_run_after_undelete_method() {
        User mockUser = (User) LoggerMockDataCreator.createUser();
        mockUser.Id = LoggerMockDataCreator.createId(Schema.User.SObjectType);
        List<SObject> records = new List<User>{ mockUser };
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.User.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.AFTER_UNDELETE;
        mockHandler.triggerNew = null;
        mockHandler.triggerNewMap = new Map<Id, SObject>(records);
        mockHandler.triggerOldMap = null;

        mockHandler.execute();

        System.Assert.areEqual(1, mockHandler.executionCount);
        System.Assert.areEqual(TriggerOperation.AFTER_UNDELETE, mockHandler.executedTriggerOperationType);
        System.Assert.isNull(mockHandler.executedTriggerNew);
        System.Assert.areEqual(mockHandler.triggerNewMap, mockHandler.executedTriggerNewMap);
        System.Assert.isNull(mockHandler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_gracefully_skip_non_existent_apex_plugin() {
        User mockUser = (User) LoggerMockDataCreator.createUser();
        mockUser.Id = LoggerMockDataCreator.createId(Schema.User.SObjectType);
        List<SObject> records = new List<User>{ mockUser };
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.User.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.BEFORE_INSERT;
        mockHandler.triggerNew = records;
        mockHandler.triggerNewMap = null;
        mockHandler.triggerOldMap = null;
        LoggerPlugin__mdt pluginConfiguration = new LoggerPlugin__mdt(
            DeveloperName = 'Mock_Plugin',
            IsEnabled__c = true,
            SObjectHandlerApexClass__c = 'Some_Fake_Apex_Class'
        );
        mockHandler.getPluginConfigurations().add(pluginConfiguration);

        mockHandler.execute();

        System.Assert.areEqual(1, mockHandler.executionCount);
        System.Assert.areEqual(1, mockHandler.getPluginConfigurations().size(), mockHandler.getPluginConfigurations().toString());
        System.Assert.areEqual(0, mockHandler.getExecutedApexPlugins().size(), mockHandler.getExecutedApexPlugins().toString());
    }

    @IsTest
    static void it_should_execute_apex_plugin() {
        User mockUser = (User) LoggerMockDataCreator.createUser();
        mockUser.Id = LoggerMockDataCreator.createId(Schema.User.SObjectType);
        List<SObject> records = new List<User>{ mockUser };
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.User.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.BEFORE_INSERT;
        mockHandler.triggerNew = records;
        mockHandler.triggerNewMap = null;
        mockHandler.triggerOldMap = null;
        LoggerPlugin__mdt mockPluginConfiguration = new LoggerPlugin__mdt(
            DeveloperName = 'ExampleApexPlugin',
            IsEnabled__c = true,
            SObjectHandlerApexClass__c = MockTriggerablePlugin.class.getName()
        );
        mockHandler.getPluginConfigurations().add(mockPluginConfiguration);

        mockHandler.execute();

        System.Assert.areEqual(1, mockHandler.executionCount);
        System.Assert.areEqual(1, mockHandler.getPluginConfigurations().size(), mockHandler.getPluginConfigurations().toString());
        System.Assert.areEqual(1, mockHandler.getExecutedApexPlugins().size(), mockHandler.getExecutedApexPlugins().toString());
        MockTriggerablePlugin executedApexPlugin = (MockTriggerablePlugin) mockHandler.getExecutedApexPlugins().get(0);
        System.Assert.areEqual(mockPluginConfiguration, executedApexPlugin.configuration);
        System.Assert.areEqual(mockHandler.input, executedApexPlugin.input);
    }

    @IsTest
    static void it_should_gracefully_skip_non_existent_flow_plugin() {
        User mockUser = (User) LoggerMockDataCreator.createUser();
        mockUser.Id = LoggerMockDataCreator.createId(Schema.User.SObjectType);
        List<SObject> records = new List<User>{ mockUser };
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.User.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.BEFORE_INSERT;
        mockHandler.triggerNew = records;
        mockHandler.triggerNewMap = null;
        mockHandler.triggerOldMap = null;
        LoggerPlugin__mdt pluginConfiguration = new LoggerPlugin__mdt(
            DeveloperName = 'Mock_Plugin',
            IsEnabled__c = true,
            SObjectHandlerFlowName__c = 'Some_Fake_Flow'
        );
        mockHandler.getPluginConfigurations().add(pluginConfiguration);

        mockHandler.execute();

        System.Assert.areEqual(1, mockHandler.executionCount);
        System.Assert.areEqual(1, mockHandler.getPluginConfigurations().size(), mockHandler.getPluginConfigurations().toString());
        System.Assert.areEqual(0, mockHandler.getExecutedApexPlugins().size(), mockHandler.getExecutedApexPlugins().toString());
    }

    public class MockDefaultImplementationSObjectHandler extends LoggerSObjectHandler {
        public override Schema.SObjectType getSObjectType() {
            return Schema.User.SObjectType;
        }
    }

    public class MockSObjectHandler extends LoggerSObjectHandler {
        public Integer executionCount = 0;
        public TriggerOperation executedTriggerOperationType;
        public List<SObject> executedTriggerNew;
        public Map<Id, SObject> executedTriggerNewMap;
        public Map<Id, SObject> executedTriggerOldMap;

        private Schema.SObjectType sobjectType;

        public MockSObjectHandler() {
            this.sobjectType = Schema.User.SObjectType;
        }

        public MockSObjectHandler(Schema.SObjectType sobjectType) {
            this.sobjectType = sobjectType;
        }

        public override Schema.SObjectType getSObjectType() {
            return this.sobjectType;
        }

        protected override void executeBeforeInsert(List<SObject> triggerNew) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.BEFORE_INSERT;
            this.executedTriggerNew = triggerNew;
            super.executeBeforeInsert(triggerNew);
        }

        protected override void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.BEFORE_UPDATE;
            this.executedTriggerNewMap = triggerNewMap;
            this.executedTriggerOldMap = triggerOldMap;
            super.executeBeforeUpdate(triggerNewMap, triggerOldMap);
        }

        protected override void executeBeforeDelete(Map<Id, SObject> triggerNewMap) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.BEFORE_DELETE;
            this.executedTriggerNewMap = triggerNewMap;
            super.executeBeforeDelete(triggerNewMap);
        }

        protected override void executeAfterInsert(List<SObject> triggerNew) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.AFTER_INSERT;
            this.executedTriggerNew = triggerNew;
            super.executeAfterInsert(triggerNew);
        }

        protected override void executeAfterInsert(Map<Id, SObject> triggerNewMap) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.AFTER_INSERT;
            this.executedTriggerNewMap = triggerNewMap;
            super.executeAfterInsert(triggerNewMap);
        }

        protected override void executeAfterUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.AFTER_UPDATE;
            this.executedTriggerNewMap = triggerNewMap;
            this.executedTriggerOldMap = triggerOldMap;
            super.executeAfterUpdate(triggerNewMap, triggerOldMap);
        }

        protected override void executeAfterDelete(Map<Id, SObject> triggerNewMap) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.AFTER_DELETE;
            this.executedTriggerNewMap = triggerNewMap;
            super.executeAfterDelete(triggerNewMap);
        }

        protected override void executeAfterUndelete(Map<Id, SObject> triggerNewMap) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.AFTER_UNDELETE;
            this.executedTriggerNewMap = triggerNewMap;
            super.executeAfterUndelete(triggerNewMap);
        }
    }

    public class MockTriggerablePlugin implements LoggerPlugin.Triggerable {
        public Boolean hasExecuted { get; private set; }
        public LoggerPlugin__mdt configuration { get; private set; }
        public LoggerTriggerableContext input { get; private set; }

        public void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext input) {
            this.hasExecuted = true;
            this.configuration = configuration;
            this.input = input;
        }
    }
}
