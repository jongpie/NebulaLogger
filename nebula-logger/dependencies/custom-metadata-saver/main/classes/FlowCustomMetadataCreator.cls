//----------------------------------------------------------------------------------------------------//
// This file is part of the Custom Metadata Saver project, released under the MIT License.            //
// See LICENSE file or go to https://github.com/jongpie/CustomMetadataSaver for full license details. //
//----------------------------------------------------------------------------------------------------//

public inherited sharing class FlowCustomMetadataCreator {
    public class FlowInput {
        @InvocableVariable(required=true label='The API name of the custom metadata type')
        public String customMetadataTypeName;

        @InvocableVariable(required=true label='The label of the new custom metadata record')
        public String masterLabel;

        @InvocableVariable(required=true label='The API name of the new custom metadata record')
        public String developerName;
    }

    private FlowCustomMetadataCreator() {
        // Static only
    }

    @InvocableMethod(
        category='Custom Metadata'
        label='Creates a New Instance of a Custom Metadata Record'
        description='Provides the ability to create a new custom metadata record'
    )
    public static List<SObject> newInstance(List<FlowInput> inputs) {
        System.debug('FlowCustomMetadataCreator inputs==' + inputs);

        List<String> customMetadataRecordNames = new List<String>();
        List<SObject> customMetadataRecords = new List<SObject>();

        for (FlowInput input : inputs) {
            SObjectType sobjectType = Schema.getGlobalDescribe().get(input.customMetadataTypeName);
            SObject newCustomMetadataRecord = sobjectType.newSObject();

            newCustomMetadataRecord.put('MasterLabel', input.masterLabel);
            newCustomMetadataRecord.put('DeveloperName', input.developerName);

            String fullName = getFullName(newCustomMetadataRecord);
            customMetadataRecordNames.add(fullName);

            customMetadataRecords.add(newCustomMetadataRecord);
        }

        return customMetadataRecords;
    }

    private static String getFullName(SObject customMetadataRecord) {
        String customMetadataTypePrefix = customMetadataRecord.getSObjectType().getDescribe().getName().replace('__mdt', '');
        return customMetadataTypePrefix + '.' + customMetadataRecord.get('DeveloperName');
    }
}
