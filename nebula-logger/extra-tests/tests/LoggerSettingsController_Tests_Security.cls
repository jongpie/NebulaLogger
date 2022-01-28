//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Extra Tests
 * @description Additional integration tests for testing security checks in `LoggerSettingsController`.
 *              If an org installs Nebula Logger for all users, these tests will start failing since it relies on an existing Profile
 *              ...from within the normal tests, and each org might have additional required fields, VR, etc on the std objects
 */
@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest
private class LoggerSettingsController_Tests_Security {
    private static final String CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME = 'CanModifyLoggerSettings';
    private static final Profile STANDARD_USER_PROFILE = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

    @IsTest
    static void it_should_permit_user_to_modify_logger_settings_when_custom_permission_is_assigned() {
        User standardUser = LoggerTestUtils.createUser(STANDARD_USER_PROFILE.Id);
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
            System.assertEquals(true, FeatureManagement.checkPermission(CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME), permissionSetAssignment);
            System.assertEquals(true, LoggerSettingsController.canUserModifyLoggerSettings());
        }
    }

    @IsTest
    static void it_should_permit_user_to_modify_logger_settings_when_loggerAdmin_permission_set_is_assigned() {
        User standardUser = LoggerTestUtils.createUser(STANDARD_USER_PROFILE.Id);
        insert standardUser;
        LoggerTestUtils.assignAdminPermissionSet(standardUser.Id);

        System.runAs(standardUser) {
            System.assertEquals(true, FeatureManagement.checkPermission(CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME));
            System.assertEquals(true, LoggerSettingsController.canUserModifyLoggerSettings());
        }
    }

    @IsTest
    static void it_should_not_permit_user_to_modify_logger_settings_when_loggerLogViewer_permission_set_is_assigned() {
        User standardUser = LoggerTestUtils.createUser(STANDARD_USER_PROFILE.Id);
        insert standardUser;
        LoggerTestUtils.assignLogViewerPermissionSet(standardUser.Id);

        System.runAs(standardUser) {
            System.assertEquals(false, FeatureManagement.checkPermission(CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME));
            System.assertEquals(false, LoggerSettingsController.canUserModifyLoggerSettings());
        }
    }

    @IsTest
    static void it_should_not_permit_user_to_modify_logger_settings_when_loggerEndUser_permission_set_is_assigned() {
        User standardUser = LoggerTestUtils.createUser(STANDARD_USER_PROFILE.Id);
        insert standardUser;
        LoggerTestUtils.assignEndUserPermissionSet(standardUser.Id);

        System.runAs(standardUser) {
            System.assertEquals(false, FeatureManagement.checkPermission(CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME));
            System.assertEquals(false, LoggerSettingsController.canUserModifyLoggerSettings());
        }
    }

    @IsTest
    static void it_should_not_permit_user_to_modify_logger_settings_when_loggerLogCreator_permission_set_is_assigned() {
        User standardUser = LoggerTestUtils.createUser(STANDARD_USER_PROFILE.Id);
        insert standardUser;
        LoggerTestUtils.assignLogCreatorPermissionSet(standardUser.Id);

        System.runAs(standardUser) {
            System.assertEquals(false, FeatureManagement.checkPermission(CAN_MODIFY_LOGGER_SETTINGS_PERMISSION_NAME));
            System.assertEquals(false, LoggerSettingsController.canUserModifyLoggerSettings());
        }
    }

    @IsTest
    static void it_should_not_permit_user_to_modify_logger_settings_when_custom_permission_is_not_assigned() {
        User standardUser = LoggerTestUtils.createUser(STANDARD_USER_PROFILE.Id);
        System.runAs(standardUser) {
            System.assertEquals(false, LoggerSettingsController.canUserModifyLoggerSettings());
        }
    }
}
