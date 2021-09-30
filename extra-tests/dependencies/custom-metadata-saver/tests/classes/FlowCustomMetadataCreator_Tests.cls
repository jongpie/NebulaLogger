//----------------------------------------------------------------------------------------------------//
// This file is part of the Custom Metadata Saver project, released under the MIT License.            //
// See LICENSE file or go to https://github.com/jongpie/CustomMetadataSaver for full license details. //
//----------------------------------------------------------------------------------------------------//

@isTest
private inherited sharing class FlowCustomMetadataCreator_Tests {
    @isTest
    static void it_should_create_new_cmdt_record_instance() {
        FlowCustomMetadataCreator.FlowInput input = new FlowCustomMetadataCreator.FlowInput();
        input.customMetadataTypeName = SObjectType.CustomMetadataDeployTest__mdt.getName();
        input.masterLabel = 'My new cmdt';
        input.developerName = 'My_new_cmdt';

        List<FlowCustomMetadataCreator.FlowInput> inputs = new List<FlowCustomMetadataCreator.FlowInput>{ input };

        Test.startTest();
        List<SObject> newRecords = FlowCustomMetadataCreator.newInstance(inputs);
        Test.stopTest();

        System.assertEquals(1, newRecords.size());

        CustomMetadataDeployTest__mdt trackedInstance = (CustomMetadataDeployTest__mdt) newRecords.get(0);
        System.assertEquals(input.masterLabel, trackedInstance.MasterLabel);
        System.assertEquals(input.developerName, trackedInstance.DeveloperName);
    }
}
