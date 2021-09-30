//----------------------------------------------------------------------------------------------------//
// This file is part of the Custom Metadata Saver project, released under the MIT License.            //
// See LICENSE file or go to https://github.com/jongpie/CustomMetadataSaver for full license details. //
//----------------------------------------------------------------------------------------------------//

@isTest
private class CustomMetadataTableController_Tests {
    @isTest
    static void it_should_return_sobject_api_name_for_custom_metadata_record() {
        CustomMetadataDeployTest__mdt customMetadataRecord = new CustomMetadataDeployTest__mdt();

        String returnedSObjectApiName = CustomMetadataTableController.getSObjectApiName(customMetadataRecord);
        System.assertEquals(customMetadataRecord.getSObjectType().getDescribe().getName(), returnedSObjectApiName);
    }

    @isTest
    static void it_should_enqueue_deployment() {
        CustomMetadataDeployTest__mdt customMetadataRecord = new CustomMetadataDeployTest__mdt(DeveloperName = 'Some_API_Name', MasterLabel = 'Some Label');

        String deploymentId = CustomMetadataTableController.deploy(new List<SObject>{ customMetadataRecord });
        System.assertEquals(CustomMetadataSaver.MOCK_DEPLOYMENT_ID, deploymentId);
    }

    @isTest
    static void it_should_get_deployment_status_when_deployment_succeeds() {
        String mockDeploymentStatus = 'Succeeded';
        DeploymentCalloutMock mock = new DeploymentCalloutMock();
        mock.setDeploymentStatus(mockDeploymentStatus);
        Test.setMock(HttpCalloutMock.class, mock);

        CustomMetadataTableController.DeploymentStatusResponse deploymentStatusResponse = CustomMetadataTableController.getDeploymentStatus(
            CustomMetadataSaver.MOCK_DEPLOYMENT_ID
        );
        System.assertEquals(CustomMetadataSaver.MOCK_DEPLOYMENT_ID, deploymentStatusResponse.id);
        System.assertEquals(mockDeploymentStatus, deploymentStatusResponse.deployResult.status);
    }

    private class DeploymentCalloutMock implements HttpCalloutMock {
        private String status;

        public void setDeploymentStatus(String status) {
            this.status = status;
        }

        public HttpResponse respond(HttpRequest httpRequest) {
            CustomMetadataTableController.DeployResult deployResult = new CustomMetadataTableController.DeployResult();
            deployResult.status = this.status;

            CustomMetadataTableController.DeploymentStatusResponse deploymentStatusResponse = new CustomMetadataTableController.DeploymentStatusResponse();
            deploymentStatusResponse.deployResult = deployResult;
            deploymentStatusResponse.id = CustomMetadataSaver.MOCK_DEPLOYMENT_ID;

            HttpResponse httpResponse = new HttpResponse();
            httpResponse.setHeader('Content-Type', 'application/json');
            httpResponse.setBody(JSON.serialize(deploymentStatusResponse));
            httpResponse.setStatusCode(200);
            return httpResponse;
        }
    }
}
