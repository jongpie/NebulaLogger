//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Controller class for the LWC `loggerHomePageHeader`
 */
public without sharing class LoggerHomeHeaderController {
    /**
     * @description Returns the current version number of Nebula Logger
     * @return   An instance of `LoggerHomeHeaderController.Environment`
     */
    @AuraEnabled(cacheable=true)
    public static Environment getEnvironmentDetails() {
        Environment environment = new Environment();
        environment.loggerVersionNumber = Logger.getVersionNumber();
        environment.organizationApiVersion = Logger.getOrganizationApiVersion();

        return environment;
    }

    @SuppressWarnings('PMD.ApexDoc')
    public class Environment {
        @AuraEnabled
        public String loggerVersionNumber;
        @AuraEnabled
        public String organizationApiVersion;
    }
}
