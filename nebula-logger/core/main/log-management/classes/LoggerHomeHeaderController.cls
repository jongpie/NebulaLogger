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
     * @return   The String value of Logger.getVersionNumber()
     */
    @AuraEnabled(cacheable=true)
    public static String getLoggerVersionNumber() {
        return Logger.getVersionNumber();
    }

    /**
     * @description Returns the current API version of the organization
     * @return   The String value of Logger.getOrganizationApiVersion()
     */
    @AuraEnabled(cacheable=true)
    public static String getOrganizationApiVersion() {
        return Logger.getOrganizationApiVersion();
    }
}
