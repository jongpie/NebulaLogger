/******************************************************************************************************
* This file is part of the Smart Test Data Factory project, released under the MIT License.           *
* See LICENSE file or go to https://github.com/jongpie/SmartTestDataFactory for full license details. *
******************************************************************************************************/
@isTest
public class TestDataFactory {

    private final Schema.SObjectType sobjectType;
    private final List<Schema.SObjectField> requiredFields;

    private SObject record;

    public TestDataFactory(Schema.SObjectType sobjectType) {
        this(sobjectType.newSObject());
    }

    public TestDataFactory(SObject record) {
        this.record      = record;
        this.sobjectType = record.getSObjectType();

        this.requiredFields = this.getRequiredFields();
    }

    public SObject populateRequiredFields() {
        this.setRequiredFieldsOnRecord();
        return this.record;
    }

    private List<Schema.SObjectField> getRequiredFields() {
        List<SObjectField> requiredFields = new List<SObjectField>();
        for(Schema.SObjectField field : this.sobjectType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

            // Guard clauses for fields that aren't required
            if(fieldDescribe.isNillable() == true) continue;
            if(fieldDescribe.isCreateable() == false) continue;

            // If a field is not nillable & it is createable, then it's required
            requiredFields.add(field);
        }

        return requiredFields;
    }

    private void setRequiredFieldsOnRecord() {
        Map<String, Object> populatedFields = this.record.getPopulatedFieldsAsMap();
        for(Schema.SObjectField field : this.requiredFields) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            // If a field was already populated by using the constructor 'TestDataFactory(SObject record)', then don't change it
            if(populatedFields.containsKey(fieldDescribe.getName())) continue;

            Object fieldValue;
            if(fieldDescribe.getDefaultValue() != null) {
                // If there is a default value setup for the field, use it
                fieldValue = fieldDescribe.getDefaultValue();
            } else {
                // Otherwise, we'll generate our own test value to use, based on the field's metadata
                fieldValue = this.getTestValue(fieldDescribe);
            }

            // If we now have a value to use, set it on the record
            if(fieldValue != null) this.record.put(field, fieldValue);
        }
    }

    private Object getTestValue(Schema.DescribeFieldResult fieldDescribe) {
        // Since Apex does not support case statements, we use several ugly IF-ELSE statements
        // Some more complex data types, like ID & Reference, require other objects to be created
        // This implementation delegates that responsibility to the test classes since DML is required to get a valid ID,
        // but the logic below could be updated to support creating parent objects if needed

        // Unsupported display types have been commented-out below
        /*
            Schema.DisplayType.Address, Schema.DisplayType.AnyType, Schema.DisplayType.Base64,
            Schema.DisplayType.DataCategoryGroupReference, Schema.DisplayType.Id, Schema.DisplayType.Reference
        */
        switch on fieldDescribe.getType() {
            when Boolean         { return false; }
            when Combobox        { return this.getStringValue(fieldDescribe); }
            when Currency        { return 19.85; }
            when Date            { return System.today(); }
            when DateTime        { return System.now(); }
            when Double          { return 3.14; }
            when Email           { return 'test@example.com'; }
            when EncryptedString { return this.getStringValue(fieldDescribe); }
            when Integer         { return 1; }
            when MultiPicklist   { return fieldDescribe.getPicklistValues()[0].getValue(); }
            when Percent         { return 0.42; }
            when Phone           { return '+34 999 11 22 33'; }
            when Picklist        { return fieldDescribe.getPicklistValues()[0].getValue(); }
            when String          { return this.getStringValue(fieldDescribe); }
            when TextArea        { return this.getStringValue(fieldDescribe); }
            when Time            { return Time.newInstance(13, 30, 6, 20); }
            when Url             { return 'https://salesforce.com'; }
            when else            { return null; } // Any non-supported display types will return null - test classes will need to handle setting the values
        }
    }

    private String getStringValue(Schema.DescribeFieldResult fieldDescribe) {
        String strValue   = 'Test string for ' + fieldDescribe.getType();
        Integer maxLength = fieldDescribe.getLength();

        return strValue.length() <= maxLength ? strValue : strValue.left(maxLength);
    }

}