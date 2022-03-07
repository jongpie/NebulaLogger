//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Provides details to LWCs about Logger's `SObjects`, using `@AuraEnabled` properties
 */
public without sharing class LoggerSObjectMetadata {
    /**
     * @description Provides schema details about the the platform event object `LogEntryEvent__e`
     * @return   An instance of `LoggerSObjectMetadata.SObjectSchema` for the platform event `LogEntryEvent__e`
     */
    @AuraEnabled(cacheable=true)
    public static SObjectSchema getLogEntryEventSchema() {
        return buildSObjectSchema(Schema.LogEntryEvent__e.SObjectType.getDescribe());
    }

    /**
     * @description Provides schema details about the the custom settings object `LoggerSettings__c`
     * @return   An instance of `LoggerSObjectMetadata.SObjectSchema` for the platform event `LoggerSettings__c`
     */
    @AuraEnabled(cacheable=true)
    public static SObjectSchema getLoggerSettingsSchema() {
        return buildSObjectSchema(Schema.LoggerSettings__c.SObjectType.getDescribe());
    }

    private static SObjectSchema buildSObjectSchema(Schema.DescribeSObjectResult describe) {
        SObjectSchema schema = new SObjectSchema();
        schema.apiName = describe.getName();
        schema.localApiName = describe.getLocalName();
        schema.label = describe.getLabel();
        schema.labelPlural = describe.getLabelPlural();
        schema.namespacePrefix = describe.getLocalName() == describe.getName() ? '' : describe.getName().removeEnd(describe.getLocalName());

        schema.fields = new Map<String, FieldSchema>();
        for (Schema.SObjectField field : describe.fields.getMap().values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            schema.fields.put(fieldDescribe.getLocalName(), buildFieldSchema(fieldDescribe));
        }
        return schema;
    }

    private static FieldSchema buildFieldSchema(Schema.DescribeFieldResult fieldDescribe) {
        FieldSchema schema = new FieldSchema();
        schema.apiName = fieldDescribe.getName();
        schema.localApiName = fieldDescribe.getLocalName();
        schema.inlineHelpText = fieldDescribe.getInlineHelpText();
        schema.label = fieldDescribe.getLabel();
        schema.type = fieldDescribe.getType().name().toLowerCase();

        return schema;
    }

    /**
     * @description Inner class for `SObject` details to LWCs, using `@AuraEnabled` properties
     */
    public class SObjectSchema {
        @AuraEnabled
        public String apiName;

        @AuraEnabled
        public String localApiName;

        @AuraEnabled
        public String namespacePrefix;

        @AuraEnabled
        public String label;

        @AuraEnabled
        public String labelPlural;

        @AuraEnabled
        public Map<String, FieldSchema> fields;
    }

    /**
     * @description Inner class for `SObjectField` details to LWCs, using `@AuraEnabled` properties
     */
    public class FieldSchema {
        @AuraEnabled
        public String apiName;

        @AuraEnabled
        public String localApiName;

        @AuraEnabled
        public String inlineHelpText;

        @AuraEnabled
        public String label;

        @AuraEnabled
        public String type;
    }
}
