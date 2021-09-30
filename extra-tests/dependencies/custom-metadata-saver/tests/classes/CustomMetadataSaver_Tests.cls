//----------------------------------------------------------------------------------------------------//
// This file is part of the Custom Metadata Saver project, released under the MIT License.            //
// See LICENSE file or go to https://github.com/jongpie/CustomMetadataSaver for full license details. //
//----------------------------------------------------------------------------------------------------//

@isTest
private class CustomMetadataSaver_Tests {
    @isTest
    static void it_should_deploy_cmdt_record_for_list_of_cmdt() {
        CustomMetadataDeployTest__mdt cmdtRecord = new CustomMetadataDeployTest__mdt(
            MasterLabel = 'my test cmdt record',
            DeveloperName = 'my_test_cmdt_record',
            ExampleCheckboxField__c = true,
            ExampleDateField__c = System.today(),
            ExampleDatetimeField__c = System.now(),
            ExampleTextField__c = 'hello'
        );

        List<CustomMetadataDeployTest__mdt> cdmtRecords = new List<CustomMetadataDeployTest__mdt>{ cmdtRecord };

        System.assertEquals(1, cdmtRecords.size());

        Test.startTest();
        CustomMetadataSaver.deploy(cdmtRecords);
        Test.stopTest();

        System.assertEquals(1, CustomMetadataSaver.getDeploymentJobIds().size());
    }

    @isTest
    static void it_should_deploy_cmdt_record_for_list_of_flowInputs() {
        CustomMetadataDeployTest__mdt cmdtRecord = new CustomMetadataDeployTest__mdt(
            MasterLabel = 'my test cmdt record',
            DeveloperName = 'my_test_cmdt_record',
            ExampleCheckboxField__c = true,
            ExampleDateField__c = System.today(),
            ExampleDatetimeField__c = System.now(),
            ExampleTextField__c = 'hello'
        );

        List<CustomMetadataDeployTest__mdt> cdmtRecords = new List<CustomMetadataDeployTest__mdt>{ cmdtRecord };
        CustomMetadataSaver.FlowInput input = new CustomMetadataSaver.FlowInput();
        input.customMetadataRecords = cdmtRecords;
        input.sendEmailOnError = true;
        input.sendEmailOnSuccess = true;

        List<CustomMetadataSaver.FlowInput> inputs = new List<CustomMetadataSaver.FlowInput>();
        inputs.add(input);

        System.assertEquals(1, cdmtRecords.size());

        Test.startTest();
        CustomMetadataSaver.deploy(inputs);
        Test.stopTest();

        System.assertEquals(1, CustomMetadataSaver.getDeploymentJobIds().size());
    }

    @isTest
    static void it_should_handle_deploy_success() {
        // Instantiate the callback.
        Boolean sendEmailOnError = true;
        Boolean sendEmailOnSuccess = true;
        CustomMetadataSaver.DefaultDeployCallback callback = new CustomMetadataSaver.DefaultDeployCallback(sendEmailOnError, sendEmailOnSuccess);

        // Create test result and context objects.
        Metadata.DeployResult result = new Metadata.DeployResult();
        result.success = true;
        result.numberComponentsTotal = 5;
        result.numberComponentErrors = 0;
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();

        System.assertEquals(null, callback.success);

        Test.startTest();
        callback.handleResult(result, context);
        Test.stopTest();

        System.assertEquals(true, callback.success);
    }

    @isTest
    static void it_should_handle_deploy_error() {
        // Instantiate the callback
        Boolean sendEmailOnError = true;
        Boolean sendEmailOnSuccess = true;
        CustomMetadataSaver.DefaultDeployCallback callback = new CustomMetadataSaver.DefaultDeployCallback(sendEmailOnError, sendEmailOnSuccess);

        // Setup the deploy result and context objects
        Metadata.DeployResult result = new Metadata.DeployResult();
        result.success = false;
        result.numberComponentsTotal = 5;
        result.numberComponentErrors = 2;
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();

        System.assertEquals(null, callback.success);

        Test.startTest();
        callback.handleResult(result, context);
        Test.stopTest();

        System.assertEquals(false, callback.success);
    }
}
