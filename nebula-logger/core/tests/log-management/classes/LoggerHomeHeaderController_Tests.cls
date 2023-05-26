//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerHomeHeaderController_Tests {
    @IsTest
    public static void it_returns_environment_details() {
        LoggerHomeHeaderController.Environment environment = LoggerHomeHeaderController.getEnvironmentDetails();

        System.Assert.areEqual(Logger.getVersionNumber(), environment.loggerVersionNumber);
        System.Assert.areEqual(Logger.getOrganizationApiVersion(), environment.organizationApiVersion);
    }
}
