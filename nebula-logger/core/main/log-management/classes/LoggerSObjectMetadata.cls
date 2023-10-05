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
     * @description Provides schema details about the specified `SObjectType`
     * @param  sobjectApiName The API name of the `SObjectType` to convert to an instance of `LoggerSObjectMetadata.SObjectSchema`
     * @return   An instance of `LoggerSObjectMetadata.SObjectSchema` for the specified `SObjectType`
     */
    @AuraEnabled(cacheable=true)
    public static SObjectSchema getSchemaForName(String sobjectApiName) {
        String namespacePrefix = getNamespacePrefix();
        String qualifiedApiName = String.isBlank(namespacePrefix) ? sobjectApiName : namespacePrefix + '__' + sobjectApiName;
        System.Type apexType = System.Type.forName(qualifiedApiName) != null ? System.Type.forName(qualifiedApiName) : System.Type.forName(sobjectApiName);
        Schema.SObjectType sobjectType = ((SObject) apexType.newInstance()).getSObjectType();
        return getSchema(sobjectType);
    }

    /**
     * @description Provides schema details about the specified `SObjectType`
     * @param  sobjectType The instance of `SObjectType` to convert to an instance of `LoggerSObjectMetadata.SObjectSchema`
     * @return   An instance of `LoggerSObjectMetadata.SObjectSchema` for the specified `SObjectType`
     */
    public static SObjectSchema getSchema(Schema.SObjectType sobjectType) {
        Schema.DescribeSObjectResult describe = sobjectType.getDescribe();

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

    private static String getNamespacePrefix() {
        String className = LoggerSObjectMetadata.class.getName();
        String namespacePrefix = className.contains('.') ? className.substringBefore('.') : '';

        return namespacePrefix;
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
