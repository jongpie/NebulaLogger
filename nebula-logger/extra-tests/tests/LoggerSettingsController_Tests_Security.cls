//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=false)
private class LoggerSettingsController_Tests_Security {
    private static final String CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME = 'CanModifyLoggerSettings';
    private static final Schema.Profile STANDARD_USER_PROFILE = [SELECT Id FROM Profile WHERE Name IN ('Standard User', 'Usuario estándar')];

    @IsTest
    static void it_should_permit_user_to_modify_logger_settings_when_custom_permission_is_assigned() {
        Schema.User standardUser = LoggerMockDataCreator.createUser(STANDARD_USER_PROFILE.Id);
        insert standardUser;
        PermissionSet permissionSet = new PermissionSet(Name = 'CustomPermissionEnabled', Label = 'Custom Permisison Enabled');
        insert permissionSet;
        SetupEntityAccess setupEntityAccess = new SetupEntityAccess(
            ParentId = permissionSet.Id,
            SetupEntityId = [SELECT Id FROM CustomPermission WHERE DeveloperName = :CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME]
            .Id
        );
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(AssigneeId = standardUser.Id, PermissionSetId = permissionSet.Id);
        insert new List<SObject>{ setupEntityAccess, permissionSetAssignment };

        System.runAs(standardUser) {
            System.Assert.isTrue(
                System.FeatureManagement.checkPermission(CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME),
                System.JSON.serializePretty(permissionSetAssignment)
            );
            System.Assert.isTrue(LoggerSettingsController.canUserModifyLoggerSettings());
        }
    }

    @IsTest
    static void it_should_permit_user_to_modify_logger_settings_when_loggerAdmin_permission_set_is_assigned() {
        Schema.User standardUser = LoggerMockDataCreator.createUser(STANDARD_USER_PROFILE.Id);
        insert standardUser;
        LoggerTestConfigurator.assignAdminPermissionSet(standardUser.Id);

        System.runAs(standardUser) {
            System.Assert.isTrue(System.FeatureManagement.checkPermission(CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME));
            System.Assert.isTrue(LoggerSettingsController.canUserModifyLoggerSettings());
        }
    }

    @IsTest
    static void it_should_not_permit_user_to_modify_logger_settings_when_loggerLogViewer_permission_set_is_assigned() {
        Schema.User standardUser = LoggerMockDataCreator.createUser(STANDARD_USER_PROFILE.Id);
        insert standardUser;
        LoggerTestConfigurator.assignLogViewerPermissionSet(standardUser.Id);

        System.runAs(standardUser) {
            System.Assert.isFalse(System.FeatureManagement.checkPermission(CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME));
            System.Assert.isFalse(LoggerSettingsController.canUserModifyLoggerSettings());
        }
    }

    @IsTest
    static void it_should_not_permit_user_to_modify_logger_settings_when_loggerEndUser_permission_set_is_assigned() {
        Schema.User standardUser = LoggerMockDataCreator.createUser(STANDARD_USER_PROFILE.Id);
        insert standardUser;
        LoggerTestConfigurator.assignEndUserPermissionSet(standardUser.Id);

        System.runAs(standardUser) {
            System.Assert.isFalse(System.FeatureManagement.checkPermission(CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME));
            System.Assert.isFalse(LoggerSettingsController.canUserModifyLoggerSettings());
        }
    }

    @IsTest
    static void it_should_not_permit_user_to_modify_logger_settings_when_loggerLogCreator_permission_set_is_assigned() {
        Schema.User standardUser = LoggerMockDataCreator.createUser(STANDARD_USER_PROFILE.Id);
        insert standardUser;
        LoggerTestConfigurator.assignLogCreatorPermissionSet(standardUser.Id);

        System.runAs(standardUser) {
            System.Assert.isFalse(System.FeatureManagement.checkPermission(CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME));
            System.Assert.isFalse(LoggerSettingsController.canUserModifyLoggerSettings());
        }
    }

    @IsTest
    static void it_should_not_permit_user_to_modify_logger_settings_when_custom_permission_is_not_assigned() {
        Schema.User standardUser = LoggerMockDataCreator.createUser(STANDARD_USER_PROFILE.Id);
        System.runAs(standardUser) {
            System.Assert.isFalse(LoggerSettingsController.canUserModifyLoggerSettings());
        }
    }
}
