//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Controller class for the LWC `loggerHomeHeader`
 */
public without sharing class LoggerHomeHeaderController {
    /**
     * @description Returns the current version number of Nebula Logger
     * @return   An instance of `LoggerHomeHeaderController.Environment`
     */
    @AuraEnabled(cacheable=true)
    public static Environment getEnvironmentDetails() {
        Organization organization = LoggerEngineDataSelector.getInstance().getCachedOrganization();

        Environment environment = new Environment();
        environment.loggerNamespacePrefix = String.isNotBlank(Logger.getNamespacePrefix()) == true ? Logger.getNamespacePrefix() : '(none)';
        environment.loggerVersionNumber = Logger.getVersionNumber();
        environment.organizationApiVersion = Logger.getOrganizationApiVersion();
        environment.organizationCreatedByUsername = organization.CreatedBy.Username;
        environment.organizationDomainUrl = System.URL.getOrgDomainUrl()?.toExternalForm();
        environment.organizationFormattedCreatedDate = organization.CreatedDate.format();
        environment.organizationId = System.UserInfo.getOrganizationId();
        environment.organizationInstanceName = organization.InstanceName;
        environment.organizationName = System.UserInfo.getOrganizationName();
        environment.organizationType = organization.OrganizationType;

        Logger.StatusApiResponse statusApiResponse = Logger.callStatusApi();
        if (statusApiResponse != null) {
            environment.organizationInstanceLocation = statusApiResponse.location;
            environment.organizationMaintenanceWindow = statusApiResponse.maintenanceWindow;
            environment.organizationReleaseNumber = statusApiResponse.releaseNumber;
            environment.organizationReleaseVersion = statusApiResponse.releaseVersion;

            if (statusApiResponse.Products != null && statusApiResponse.Products.isEmpty() == false) {
                environment.organizationInstanceProducts = getInstanceProductNames(statusApiResponse);
            }
        }

        return environment;
    }

    private static String getInstanceProductNames(Logger.StatusApiResponse statusApiResponse) {
        List<String> productNames = new List<String>();
        for (Logger.StatusApiResponseProduct product : statusApiResponse.Products) {
            productNames.add(product.name);
        }
        return String.join(productNames, ', ');
    }

    @SuppressWarnings('PMD.ApexDoc, PMD.TooManyFields')
    public class Environment {
        @AuraEnabled
        public String loggerNamespacePrefix = 'Unknown';
        @AuraEnabled
        public String loggerVersionNumber = 'Unknown';
        @AuraEnabled
        public String organizationApiVersion = 'Unknown';
        @AuraEnabled
        public String organizationCreatedByUsername = 'Unknown';
        @AuraEnabled
        public String organizationDomainUrl = 'Unknown';
        @AuraEnabled
        public String organizationFormattedCreatedDate = 'Unknown';
        @AuraEnabled
        public String organizationId = 'Unknown';
        @AuraEnabled
        public String organizationInstanceLocation = 'Unknown';
        @AuraEnabled
        public String organizationInstanceName = 'Unknown';
        @AuraEnabled
        public String organizationInstanceProducts = 'Unknown';
        @AuraEnabled
        public String organizationMaintenanceWindow = 'Unknown';
        @AuraEnabled
        public String organizationName = 'Unknown';
        @AuraEnabled
        public String organizationReleaseNumber = 'Unknown';
        @AuraEnabled
        public String organizationReleaseVersion = 'Unknown';
        @AuraEnabled
        public String organizationType = 'Unknown';
    }
}
