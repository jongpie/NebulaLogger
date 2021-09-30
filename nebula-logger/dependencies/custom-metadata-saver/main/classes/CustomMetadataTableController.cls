//----------------------------------------------------------------------------------------------------//
// This file is part of the Custom Metadata Saver project, released under the MIT License.            //
// See LICENSE file or go to https://github.com/jongpie/CustomMetadataSaver for full license details. //
//----------------------------------------------------------------------------------------------------//

public without sharing class CustomMetadataTableController {
    private static String BASE_URL = System.Url.getOrgDomainUrl().toExternalForm() + '/services/data/v52.0';

    @AuraEnabled
    public static String getSObjectApiName(SObject customMetadataRecord) {
        System.debug(LoggingLevel.INFO, 'CustomMetadataTableController.getSObjectApiName(' + customMetadataRecord + ')');
        return customMetadataRecord.getSObjectType().getDescribe().getName();
    }

    // @AuraEnabled(cacheable=true)
    // public static List<PicklistOption> getPicklistOptions(String sobjectApiName, String fieldApiName) {
    //     System.debug(LoggingLevel.INFO, 'CustomMetadataTableController.getPicklistOptions(' + sobjectApiName + ',' + fieldApiName + ')');

    //     // Schema.PicklistEntry can't be returned by @AuraEnabled methods, so use an inner class PicklistOption instead
    //     Schema.SObjectType sobjectType = ((SObject) Type.forName(sobjectApiName).newInstance()).getSObjectType();
    //     List<Schema.PicklistEntry> schemaPicklistEntries = sobjectType.getDescribe().fields.getMap().get(fieldApiName).getDescribe().getPicklistValues();
    //     List<PicklistOption> picklistOptions = new List<PicklistOption>();
    //     for (Schema.PicklistEntry schemaPicklistEntry : schemaPicklistEntries) {
    //         PicklistOption picklistOption = new PicklistOption();
    //         picklistOption.label = schemaPicklistEntry.label;
    //         picklistOption.value = schemaPicklistEntry.value;

    //         picklistOptions.add(picklistOption);
    //     }
    //     return picklistOptions;
    // }

    @AuraEnabled
    public static String deploy(List<SObject> customMetadataRecords) {
        System.debug(LoggingLevel.INFO, 'CustomMetadataTableController.deploy(customMetadataRecords)==' + customMetadataRecords);
        return CustomMetadataSaver.deploy(customMetadataRecords);
    }

    @AuraEnabled
    public static DeploymentStatusResponse getDeploymentStatus(String deploymentJobId) {
        System.debug(LoggingLevel.INFO, 'deploymentJobId==' + deploymentJobId);

        final String deploymentStatusUrl = BASE_URL + '/metadata/deployRequest/' + deploymentJobId + '?includeDetails=true';

        HttpRequest request = new HttpRequest();
        request.setEndpoint(deploymentStatusUrl);
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        request.setHeader('Content-Type', 'application/json; charset=utf-8');
        request.setMethod('GET');

        HttpResponse response = new Http().send(request);
        DeploymentStatusResponse deploymentStatusResponse = (DeploymentStatusResponse) JSON.deserialize(response.getBody(), DeploymentStatusResponse.class);
        System.debug(LoggingLevel.INFO, 'deploymentStatusResponse==' + deploymentStatusResponse);
        return deploymentStatusResponse;
    }

    // DTO for picklist options since Schema.PicklistEntry isn't supported for aura-enabled methods
    // public class PicklistOption {
    //     @AuraEnabled
    //     public String label;
    //     @AuraEnabled
    //     public String value;
    // }

    // DTOs based on the REST API's response for deployments
    // https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_rest_deploy_checkstatus.htm
    public class DeploymentStatusResponse {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String url;
        @AuraEnabled
        public DeployResult deployResult;
    }

    public class DeployResult {
        @AuraEnabled
        public String status;
        @AuraEnabled
        public Integer numberComponentsDeployed;
        @AuraEnabled
        public Integer numberComponentsTotal;
        @AuraEnabled
        public Integer numberComponentErrors;
        @AuraEnabled
        public DeployResultDetails details;
    }

    public class DeployResultDetails {
        @AuraEnabled
        public List<ComponentResultDetail> allComponentMessages;
        @AuraEnabled
        public List<ComponentResultDetail> componentFailures;
        @AuraEnabled
        public List<ComponentResultDetail> componentSuccesses;
    }

    public class ComponentResultDetail {
        @AuraEnabled
        public String componentType;
        @AuraEnabled
        public String fullName;
        @AuraEnabled
        public String problem;
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public Boolean warning;
        @AuraEnabled
        public Boolean created;
        @AuraEnabled
        public Boolean changed;
        @AuraEnabled
        public Boolean deleted;
        @AuraEnabled
        public Integer lineNumber;
        @AuraEnabled
        public Integer columnNumber;
        @AuraEnabled
        public Boolean requiresProductionTestRun;
        @AuraEnabled
        public Boolean knownPackagingProblem;
        @AuraEnabled
        public Boolean forPackageManifestFile;
        @AuraEnabled
        public String problemType;
    }
}
