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

  @SuppressWarnings('PMD.ApexDoc')
  public class FieldPath {
    private List<Schema.SObjectField> fieldChain;
    private Schema.DescribeFieldResult fieldDescribe;
    private String fieldPathError;
    private String formattedFieldPath;
    private String originalFieldPath;
    private Schema.SObjectType sobjectType;

    public FieldPath(Schema.SObjectType sobjectType, String fieldPath) {
      this.sobjectType = sobjectType;
      this.originalFieldPath = fieldPath;

      try {
        // this.fieldChain = this.getFieldChain(sobjectType, fieldPath);
        this.setFieldPathDetails(sobjectType, fieldPath);
        this.fieldDescribe = this.getLastFieldDescribe();
      } catch (Exception ex) {
        this.fieldPathError = ex.getMessage();
      }
    }

    public Boolean isValid() {
      return String.isBlank(this.fieldPathError);
    }

    public String getError() {
      return this.fieldPathError;
    }

    public String getFormattedFieldPath() {
      return this.formattedFieldPath;
    }

    public Schema.SObjectField getField() {
      return this.fieldChain[this.fieldChain.size() - 1];
    }

    public Object getValue(SObject record) {
      Schema.SObjectType parentSObjectType = this.sobjectType;
      SObject parentRecord = record;

      for (Schema.SObjectField field : this.fieldChain) {
        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
        if (fieldDescribe.getSoapType() != Schema.SoapType.ID) {
          return parentRecord.get(fieldDescribe.getName());
        } else {
          parentSObjectType = fieldDescribe.getReferenceTo().get(0);

          SObject newParentRecord = parentRecord.getSObject(field);
          if (newParentRecord == null) {
            return null;
          } else {
            parentRecord = newParentRecord;
          }
        }
      }

      return null;
    }

    private List<Schema.SObjectField> getFieldChain(Schema.SObjectType sobjectType, String fieldPath) {
      return null;
    }

    private void setFieldPathDetails(Schema.SObjectType sobjectType, String fieldPath) {
      Schema.SObjectType currentSObjectType = sobjectType;

      List<Schema.SObjectField> fields = new List<Schema.SObjectField>();
      List<String> fieldPathPieces = fieldPath.split('\\.');
      List<String> cleansedFieldPathPieces = new List<String>();
      Integer lastFieldIndex = fieldPathPieces.size() <= 1 ? 0 : fieldPathPieces.size() - 1;

      for (Integer i = 0; i < fieldPathPieces.size(); i++) {
        String fieldPathPiece = fieldPathPieces[i];
        Boolean isRelationshipPiece = true;

        String fieldApiName;
        if (i == lastFieldIndex) {
          fieldApiName = fieldPathPiece;
          isRelationshipPiece = false;
        } else if (fieldPathPiece.endsWith('__r')) {
          fieldApiName = fieldPathPiece.replace('__r', '__c');
        } else {
          fieldApiName = fieldPathPiece + 'Id';
        }

        Schema.SObjectField field = currentSObjectType.getDescribe().fields.getMap().get(fieldApiName);

        if (field == null) {
          throw new System.IllegalArgumentException(
            'Invalid field path \'' + fieldPath + '\', could not find field ' + fieldApiName + ' on ' + currentSObjectType
          );
        }

        String cleansedFieldPathPiece = isRelationshipPiece ? field.getDescribe().getRelationshipName() : field.toString();
        cleansedFieldPathPieces.add(cleansedFieldPathPiece);

        // TODO add support for polymorphic fields
        if (i < lastFieldIndex) {
          currentSObjectType = field.getDescribe().getReferenceTo().get(0);
        }

        fields.add(field);
      }
      this.formattedFieldPath = String.join(cleansedFieldPathPieces, '.');

      // return fields;
      this.fieldChain = fields;
    }

    private Schema.DescribeFieldResult getLastFieldDescribe() {
      Integer lastFieldIndex = this.fieldChain.size() - 1;
      return this.fieldChain[lastFieldIndex].getDescribe();
    }
  }
}
