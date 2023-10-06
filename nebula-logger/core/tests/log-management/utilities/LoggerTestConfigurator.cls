//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Test Utilities
 * @description Utility class used to help with setting up Nebula Logger's configurations within a test context.
 *              These methods are specific to metadata implemented within Nebula Logger.
 *              These methods can be used when writing Apex tests for plugins.
 * @see LoggerMockDataCreator
 * @see LoggerMockDataStore
 */
@IsTest
public without sharing class LoggerTestConfigurator {
    private static final Map<String, PermissionSet> PERMISSION_SETS_BY_NAME = queryPermissionSets();

    /**
     * @description Assigns the permission set `LoggerAdmin` to the specified user ID
     * @param  userId The ID of the user that should be assigned the permission set
     */
    public static void assignAdminPermissionSet(Id userId) {
        assignPermissionSet(userId, PERMISSION_SETS_BY_NAME.get('LoggerAdmin'));
    }

    /**
     * @description Assigns the permission set `LoggerLogViewer` to the specified user ID
     * @param  userId The ID of the user that should be assigned the permission set
     */
    public static void assignLogViewerPermissionSet(Id userId) {
        assignPermissionSet(userId, PERMISSION_SETS_BY_NAME.get('LoggerLogViewer'));
    }

    /**
     * @description Assigns the permission set `LoggerEndUser` to the specified user ID
     * @param  userId The ID of the user that should be assigned the permission set
     */
    public static void assignEndUserPermissionSet(Id userId) {
        assignPermissionSet(userId, PERMISSION_SETS_BY_NAME.get('LoggerEndUser'));
    }

    /**
     * @description Assigns the permission set `LoggerLogCreator` to the specified user ID
     * @param  userId The ID of the user that should be assigned the permission set
     */
    public static void assignLogCreatorPermissionSet(Id userId) {
        assignPermissionSet(userId, PERMISSION_SETS_BY_NAME.get('LoggerLogCreator'));
    }

    /**
     * @description Returns an instance of `LoggerSObjectHandler__mdt` that has been built & configured for the specified `SObjectType`
     * @param  sobjectType The instance `SObjectType` to check for a configured instance of `LoggerSObjectHandler`
     * @return             The ``LoggerSObjectHandler__mdt` record that has been configured for the specified `SObjectType` (if any)
     */
    public static LoggerSObjectHandler__mdt getSObjectHandlerConfiguration(Schema.SObjectType sobjectType) {
        return LoggerSObjectHandler.getHandlerConfiguration(sobjectType);
    }

    /**
     * @description Loads the mock `LogEntryDataMaskRule__mdt` during test execution
     * @param  mock The mock instance of `LogEntryDataMaskRule__mdt` to load
     */
    public static void setMock(LogEntryDataMaskRule__mdt mock) {
        LogEntryEventBuilder.setMockDataMaskRule(mock);
    }

    /**
     * @description Loads the mock `LogEntryTagRule__mdt` during test execution
     * @param  mock The mock instance of `LogEntryTagRule__mdt` to load
     */
    public static void setMock(LogEntryTagRule__mdt mock) {
        LogEntryEventHandler.TAG_ASSIGNMENT_RULES.add(mock);
    }

    /**
     * @description Loads the mock `LoggerParameter__mdt` during test execution
     * @param  mock The mock instance of `LoggerParameter__mdt` to load
     */
    public static void setMock(LoggerParameter__mdt mock) {
        LoggerParameter.setMock(mock);
    }

    /**
     * @description Loads the mock `LoggerPlugin__mdt` during test execution
     * @param  mock The mock instance of `LoggerPlugin__mdt` to load
     */
    public static void setMock(LoggerPlugin__mdt mock) {
        LoggerPlugin.setMock(mock);
    }

    /**
     * @description Loads the mock `LoggerSObjectHandler__mdt` during test execution
     * @param  mock The mock instance of `LoggerSObjectHandler__mdt` to load
     */
    public static void setMock(LoggerSObjectHandler__mdt mock) {
        LoggerSObjectHandler.setMock(mock);
    }

    /**
     * @description Loads the mock `LoggerScenarioRule__mdt` during test execution
     * @param  mock The mock instance of `LoggerScenarioRule__mdt` to load
     */
    public static void setMock(LoggerScenarioRule__mdt mock) {
        LoggerScenarioRule.setMock(mock);
    }

    /**
     * @description Loads the mock `LogStatus__mdt` during test execution
     * @param  mock The mock instance of `LogStatus__mdt` to load
     */
    public static void setMock(LogStatus__mdt mock) {
        LogHandler.setMockLogStatus(mock);
    }

    /**
     * @description Creates mock instances of `LoggerSObjectHandler__mdt` for each `SObjectType` used by Nebula Logger,
     *              with `IsEnabled__c` set to `true` on each `LoggerSObjectHandler__mdt` record
     */
    public static void setupMockSObjectHandlerConfigurations() {
        setupMockSObjectHandlerConfigurations(true);
    }

    /**
     * @description Creates mock instances of `LoggerSObjectHandler__mdt` for each `SObjectType` used by Nebula Logger,
     *              with `IsEnabled__c` set  based on the provided boolean on each `LoggerSObjectHandler__mdt` record
     * @param  isEnabled The Boolean value to control if all mock `LoggerSObjectHandler__mdt` records should be enabled (`true`) or disabled (`false`)
     */
    public static void setupMockSObjectHandlerConfigurations(Boolean isEnabled) {
        Map<Schema.SObjectType, System.Type> sobjectTypeToDefaultHandlerApexClass = new Map<Schema.SObjectType, System.Type>{
            Schema.Log__c.SObjectType => LogHandler.class,
            Schema.LogEntry__c.SObjectType => LogEntryHandler.class,
            Schema.LogEntryEvent__e.SObjectType => LogEntryEventHandler.class,
            Schema.LogEntryTag__c.SObjectType => LogEntryTagHandler.class,
            Schema.LoggerScenario__c.SObjectType => LoggerScenarioHandler.class,
            Schema.LoggerTag__c.SObjectType => LoggerTagHandler.class
        };
        for (Schema.SObjectType sobjectType : sobjectTypeToDefaultHandlerApexClass.keySet()) {
            setMock(
                new LoggerSObjectHandler__mdt(
                    IsEnabled__c = isEnabled,
                    SObjectHandlerApexClass__c = sobjectTypeToDefaultHandlerApexClass.get(sobjectType).getName(),
                    SObjectType__c = sobjectType.getDescribe().getName()
                )
            );
        }
    }

    // Helper methods
    private static void assignPermissionSet(Id userId, PermissionSet permissionSet) {
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permissionSet.Id);
        insert permissionSetAssignment;
    }

    private static Map<String, PermissionSet> queryPermissionSets() {
        List<String> permissionSetNames = new List<String>{ 'LoggerAdmin', 'LoggerLogViewer', 'LoggerEndUser', 'LoggerLogCreator' };
        Map<String, PermissionSet> results = new Map<String, PermissionSet>();
        for (PermissionSet permissionSet : [SELECT Id, Name FROM PermissionSet WHERE Name IN :permissionSetNames]) {
            results.put(permissionSet.Name, permissionSet);
        }
        return results;
    }
}
