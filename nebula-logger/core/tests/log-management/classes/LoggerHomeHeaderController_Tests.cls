//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerHomeHeaderController_Tests {
    @IsTest
    public static void it_returns_logger_version_number() {
        System.Assert.areEqual(Logger.getVersionNumber(), LoggerHomeHeaderController.getLoggerVersionNumber());
    }

    @IsTest
    public static void it_returns_organization_api_version() {
        System.Assert.areEqual(Logger.getOrganizationApiVersion(), LoggerHomeHeaderController.getOrganizationApiVersion());
    }
}