//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Class used to create or update an `SObject` record with static fake data.
 *              This is useful in situations where you need to have fields populated, but the specific
 *              values used are not relevant to a particular test.
 *              This class can be used when Apex writing tests for plugins.
 * @see LoggerTestUtils
 */
@IsTest
public without sharing class LoggerSObjectTestDataGenerator {
    private static final Map<Schema.SObjectType, List<Schema.SObjectField>> SOBJECT_TYPE_TO_ALL_FIELDS = new Map<Schema.SObjectType, List<Schema.SObjectField>>();
    private static final Map<Schema.SObjectType, List<Schema.SObjectField>> SOBJECT_TYPE_TO_REQUIRED_FIELDS = new Map<Schema.SObjectType, List<Schema.SObjectField>>();

    private final Schema.SObjectType sobjectType;
    private final SObject record;

    /**
     * @description Creates a new generator instance for the specified `SObjectType`, including creating a
     *              new `SObject` record. The new `SObject` record is created with any default field values that
     *              have been configured on the `SObjectType`.
     * @param  sobjectType The `SObjectType` to use for generating a new test `SObject` record
     */
    public LoggerSObjectTestDataGenerator(Schema.SObjectType sobjectType) {
        this(sobjectType.newSObject(null, true));
    }

    /**
     * @description Creates a new generator instance for the specified `SObject` record
     * @param  record The existing test `SObject` record to populate with sample data
     */
    public LoggerSObjectTestDataGenerator(SObject record) {
        this.record = record;
        this.sobjectType = record.getSObjectType();

        this.loadFields();
    }

    /**
     * @description Sets a value on all editable fields, unless the `SObject` record already had a value specified for a field (including `null`)
     * @return   The `SObject` record, with all editable fields populated
     */
    public SObject populateAllFields() {
        this.setUnpopulatedFieldsOnRecord(SOBJECT_TYPE_TO_ALL_FIELDS.get(this.sobjectType));
        return this.record;
    }

    /**
     * @description Sets a value on all editable required fields, unless the `SObject` record already had a value specified for a field (including `null`)
     * @return   The `SObject` record, with all editable required fields populated
     */
    public SObject populateRequiredFields() {
        this.setUnpopulatedFieldsOnRecord(SOBJECT_TYPE_TO_REQUIRED_FIELDS.get(this.sobjectType));
        return this.record;
    }

    private void loadFields() {
        if (SOBJECT_TYPE_TO_ALL_FIELDS.containsKey(this.sobjectType) == true && SOBJECT_TYPE_TO_REQUIRED_FIELDS.containsKey(this.sobjectType) == true) {
            return;
        }

        SOBJECT_TYPE_TO_ALL_FIELDS.put(this.sobjectType, new List<Schema.SObjectField>());
        SOBJECT_TYPE_TO_REQUIRED_FIELDS.put(this.sobjectType, new List<Schema.SObjectField>());
        for (Schema.SObjectField field : this.sobjectType.getDescribe().fields.getMap().values()) {
            if (field.getDescribe().isCreateable() == false) {
                continue;
            }

            SOBJECT_TYPE_TO_ALL_FIELDS.get(this.sobjectType).add(field);
            if (field.getDescribe().isNillable() == false) {
                // If a field is not nillable & it is createable, then it's required
                SOBJECT_TYPE_TO_REQUIRED_FIELDS.get(this.sobjectType).add(field);
            }
        }
    }

    private void setUnpopulatedFieldsOnRecord(List<Schema.SObjectField> fields) {
        Map<String, Object> populatedFields = this.record.getPopulatedFieldsAsMap();
        for (Schema.SObjectField field : fields) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            // If a field was already populated by using the constructor 'TestDataFactory(SObject record)', then don't change it
            if (populatedFields.containsKey(fieldDescribe.getName())) {
                continue;
            }

            Object fieldValue;
            if (fieldDescribe.getDefaultValue() != null) {
                // If there is a default value setup for the field, use it
                fieldValue = fieldDescribe.getDefaultValue();
            } else {
                // Otherwise, we'll generate our own test value to use, based on the field's metadata
                fieldValue = this.getTestValue(fieldDescribe);
            }

            // If we now have a value to use, set it on the record
            if (fieldValue != null) {
                this.record.put(field, fieldValue);
            }
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
            when Boolean {
                return false;
            }
            when Combobox {
                return this.getStringValue(fieldDescribe);
            }
            when Currency {
                return (19.85).setScale(fieldDescribe.getScale());
            }
            when Date {
                return System.today();
            }
            when Datetime {
                return System.now();
            }
            when Double {
                return (3.14).setScale(fieldDescribe.getScale());
            }
            when Email {
                return 'test@example.com';
            }
            when EncryptedString {
                return this.getStringValue(fieldDescribe);
            }
            when Integer {
                return 1;
            }
            when MultiPicklist {
                return fieldDescribe.getPicklistValues().get(0).getValue();
            }
            when Percent {
                return (0.42).setScale(fieldDescribe.getScale());
            }
            when Phone {
                return '+34 999 11 22 33';
            }
            when Picklist {
                return fieldDescribe.getPicklistValues().get(0).getValue();
            }
            when String {
                return this.getStringValue(fieldDescribe);
            }
            when TextArea {
                return this.getStringValue(fieldDescribe);
            }
            when Time {
                return Time.newInstance(13, 30, 6, 20);
            }
            when Url {
                return 'https://salesforce.com';
            }
            when else {
                // Any non-supported display types will return null - test classes will need to handle setting the values
                return null;
            }
        }
    }

    private String getStringValue(Schema.DescribeFieldResult fieldDescribe) {
        String stringValue = 'Test string for ' + fieldDescribe.getType();
        Integer maxLength = fieldDescribe.getLength();

        return stringValue.left(maxLength);
    }
}
