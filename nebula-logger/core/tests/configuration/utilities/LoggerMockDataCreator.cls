//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Test Utilities
 * @description Utility class used to help with generating mock data when writing Apex tests for Nebula Logger.
 *              These methods are generic, and should work in any Salesforce org.
 *              These methods can be used when writing Apex tests for plugins.
 * @see LoggerMockDataStore
 * @see LoggerTestConfigurator
 */
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.ExcessivePublicCount, PMD.MethodNamingConventions, PMD.PropertyNamingConventions')
@IsTest
public class LoggerMockDataCreator {
    private static final Map<Schema.SObjectType, List<Schema.SObjectField>> SOBJECT_TYPE_TO_ALL_FIELDS = new Map<Schema.SObjectType, List<Schema.SObjectField>>();
    private static final Map<Schema.SObjectType, List<Schema.SObjectField>> SOBJECT_TYPE_TO_REQUIRED_FIELDS = new Map<Schema.SObjectType, List<Schema.SObjectField>>();
    private static final Map<Schema.SObjectType, Integer> SOBJECT_TYPE_TO_MOCK_ID_COUNT = new Map<Schema.SObjectType, Integer>();

    private static Organization cachedOrganization;
    private static Integer userMockUsernameCount = 0;

    /**
     * @description Instances of `AggregateResult` can not be created directly in Apex.
     *              This method uses a workaround to generate a mock, although it will not have any fields or aggregate values populated on the object.
     * @return   The mock instance of `AggregateResult`
     */
    public static AggregateResult createAggregateResult() {
        Map<String, Object> emptyAggregateKeyValues = new Map<String, Object>();
        return (AggregateResult) JSON.deserialize(JSON.serialize(emptyAggregateKeyValues), AggregateResult.class);
    }

    /**
     * @description Creates a mock instance of `Database.LeadConvertResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests). A fake
     *              record ID is automatically included.
     * @param  isSuccess Indicates if the generated mock should have `isSuccess`
     * @return   The mock instance of `Database.LeadConvertResult`
     */
    public static Database.LeadConvertResult createDatabaseLeadConvertResult(Boolean isSuccess) {
        return createDatabaseLeadConvertResult(isSuccess, createId(Schema.Lead.SObjectType));
    }

    /**
     * @description Creates a mock instance of `Database.LeadConvertResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests)
     * @param  isSuccess Indicates if the generated mock should have `isSuccess`
     * @param  recordId  The record ID to use within the mock result
     * @return   The mock instance of `Database.LeadConvertResult`
     */
    public static Database.LeadConvertResult createDatabaseLeadConvertResult(Boolean isSuccess, Id recordId) {
        if (isSuccess) {
            return (Database.LeadConvertResult) JSON.deserialize('{"success": true, "leadid": "' + recordId + '"}', Database.LeadConvertResult.class);
        } else {
            return (Database.LeadConvertResult) JSON.deserialize(
                '{"success":false, "leadid": "' +
                    recordId +
                    '", "errors":[{"message": "convertedStatus is required...", "statusCode": "REQUIRED_FIELD_MISSING"}]}',
                Database.LeadConvertResult.class
            );
        }
    }

    /**
     * @description Creates a mock instance of `Database.DeleteResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests). A fake
     *              record ID is automatically included.
     * @param  isSuccess Indicates if the generated mock should have `isSuccess`
     * @return   The mock instance of `Database.DeleteResult`
     */
    public static Database.DeleteResult createDatabaseDeleteResult(Boolean isSuccess) {
        return createDatabaseDeleteResult(isSuccess, createId(Schema.Account.SObjectType));
    }

    /**
     * @description Creates a mock instance of `Database.DeleteResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests)
     * @param  isSuccess Indicates if the generated mock should have `isSuccess`
     * @param  recordId  The record ID to use within the mock result
     * @return   The mock instance of `Database.DeleteResult`
     */
    public static Database.DeleteResult createDatabaseDeleteResult(Boolean isSuccess, Id recordId) {
        if (isSuccess) {
            return (Database.DeleteResult) JSON.deserialize('{"success": true, "id": "' + recordId + '"}', Database.DeleteResult.class);
        } else {
            return (Database.DeleteResult) JSON.deserialize(
                '{"success":false, "id": "' + recordId + '", "errors":[{"message": "Could not delete...", "statusCode": "DELETE_FAILED"}]}',
                Database.DeleteResult.class
            );
        }
    }

    /**
     * @description Creates a mock instance of `Database.MergeResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests). A fake
     *              record ID is automatically included.
     * @param  isSuccess Indicates if the generated mock should have `isSuccess`
     * @return   The mock instance of `Database.MergeResult`
     */
    public static Database.MergeResult createDatabaseMergeResult(Boolean isSuccess) {
        return createDatabaseMergeResult(isSuccess, createId(Schema.Account.SObjectType));
    }

    /**
     * @description Creates a mock instance of `Database.MergeResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests)
     * @param  isSuccess Indicates if the generated mock should have `isSuccess`
     * @param  recordId  The record ID to use within the mock result
     * @return   The mock instance of `Database.MergeResult`
     */
    public static Database.MergeResult createDatabaseMergeResult(Boolean isSuccess, Id recordId) {
        if (isSuccess) {
            return (Database.MergeResult) JSON.deserialize('{"success": true, "id": "' + recordId + '"}', Database.MergeResult.class);
        } else {
            return (Database.MergeResult) JSON.deserialize(
                '{"success":false,"errors":[{"message": "Could not merge...", "statusCode": "MERGE_FAILED"}]}',
                Database.MergeResult.class
            );
        }
    }

    /**
     * @description Creates a mock instance of `Database.SaveResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests). A fake
     *              record ID is automatically included.
     * @param  isSuccess Indicates if the generated mock should have `isSuccess`
     * @return   The mock instance of `Database.SaveResult`
     */
    public static Database.SaveResult createDatabaseSaveResult(Boolean isSuccess) {
        return createDatabaseSaveResult(isSuccess, createId(Schema.Account.SObjectType));
    }

    /**
     * @description Creates a mock instance of `Database.SaveResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests)
     * @param  isSuccess Indicates if the generated mock should have `isSuccess`
     * @param  recordId  The record ID to use within the mock result
     * @return   The mock instance of `Database.SaveResult`
     */
    public static Database.SaveResult createDatabaseSaveResult(Boolean isSuccess, Id recordId) {
        if (isSuccess) {
            return (Database.SaveResult) JSON.deserialize('{"success": true, "id": "' + recordId + '"}', Database.SaveResult.class);
        } else {
            return (Database.SaveResult) JSON.deserialize(
                '{"success":false,"errors":[{"message": "Could not save...", "statusCode": "FIELD_CUSTOM_VALIDATION_EXCEPTION", "fields": ["Name"]}]}',
                Database.SaveResult.class
            );
        }
    }

    /**
     * @description Creates a mock instance of `Database.UndeleteResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests). A fake
     *              record ID is automatically included.
     * @param  isSuccess Indicates if the generated mock should have `isSuccess`
     * @return   The mock instance of `Database.UndeleteResult`
     */
    public static Database.UndeleteResult createDatabaseUndeleteResult(Boolean isSuccess) {
        return createDatabaseUndeleteResult(isSuccess, createId(Schema.Account.SObjectType));
    }

    /**
     * @description Creates a mock instance of `Database.UndeleteResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests)
     * @param  isSuccess Indicates if the generated mock should have `isSuccess`
     * @param  recordId  The record ID to use within the mock result
     * @return   The mock instance of `Database.UndeleteResult`
     */
    public static Database.UndeleteResult createDatabaseUndeleteResult(Boolean isSuccess, Id recordId) {
        if (isSuccess) {
            return (Database.UndeleteResult) JSON.deserialize('{"success": true, "id": "' + recordId + '"}', Database.UndeleteResult.class);
        } else {
            return (Database.UndeleteResult) JSON.deserialize(
                '{"success":false,"errors":[{"message": "Could not undelete...", "statusCode": "FIELD_CUSTOM_VALIDATION_EXCEPTION", "fields": ["Name"]}]}',
                Database.UndeleteResult.class
            );
        }
    }

    /**
     * @description Creates a mock instance of `Database.UpsertResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests). A fake
     *              record ID is automatically included.
     * @param  isSuccess Indicates if the generated mock should have `isSuccess`
     * @param  isCreated Indicates if the generated mock should have `isCreated`
     * @return   The mock instance of `Database.UpsertResult`
     */
    public static Database.UpsertResult createDatabaseUpsertResult(Boolean isSuccess, Boolean isCreated) {
        return createDatabaseUpsertResult(isSuccess, isCreated, createId(Schema.Account.SObjectType));
    }

    /**
     * @description Creates a mock instance of `Database.UpsertResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests)
     * @param  isSuccess Indicates if the generated mock should have `isSuccess`
     * @param  isCreated Indicates if the generated mock should have `isCreated`
     * @param  recordId  The record ID to use within the mock result
     * @return   The mock instance of `Database.UpsertResult`
     */
    public static Database.UpsertResult createDatabaseUpsertResult(Boolean isSuccess, Boolean isCreated, Id recordId) {
        if (isSuccess) {
            return (Database.UpsertResult) JSON.deserialize(
                '{"success": ' + isSuccess + ', "created": ' + isCreated + ', "id": "' + recordId + '"}',
                Database.UpsertResult.class
            );
        } else {
            return (Database.UpsertResult) JSON.deserialize(
                '{"success":false, "created":' +
                    isCreated +
                    ', "errors":[{"message": "Could not upsert...", "statusCode": "FIELD_CUSTOM_VALIDATION_EXCEPTION", "fields": ["Name"]}]}',
                Database.UpsertResult.class
            );
        }
    }

    /**
     * @description Generates an instance of the class `MockHttpCallout` that implements the interface `System.HttpCalloutMock`.
     *              This can be used when testing batch jobs.
     * @return      The instance of `MockHttpCallout`
     */
    public static MockHttpCallout createHttpCallout() {
        return new MockHttpCallout();
    }

    /**
     * @description Generates an instance of `HttpRequest`. This can be used when testing logging capabilities for instances of `HttpRequest`.
     * @return      The instance of `HttpRequest`
     */
    public static System.HttpRequest createHttpRequest() {
        System.HttpRequest request = new System.HttpRequest();
        request.setBody('Hello, world!');
        request.setCompressed(true);
        request.setEndpoint('https://fake.salesforce.com');
        request.setMethod('GET');
        return request;
    }

    /**
     * @description Generates an instance of `HttpResponse`. This can be used when testing logging capabilities for instances of `HttpResponse`.
     * @return      The instance of `HttpResponse`
     */
    public static System.HttpResponse createHttpResponse() {
        System.HttpResponse response = new System.HttpResponse();
        response.setBody('Hello, world!');
        response.setHeader('someKey', 'some string value');
        response.setHeader('anotherKey', 'an amazing example value, wow');
        response.setStatus('STATUS_GOOD_JOB_YOU_DID_IT');
        response.setStatusCode(201);
        return response;
    }

    /**
     * @description Generates a mock record ID for the provided SObject Type
     * @param  sobjectType The SObject Type for the generated mock record ID
     * @return   The mock record ID for the specified SObject Type
     */
    public static String createId(Schema.SObjectType sobjectType) {
        Integer recordIdNumber = 1;
        if (SOBJECT_TYPE_TO_MOCK_ID_COUNT.containsKey(sobjectType)) {
            recordIdNumber = SOBJECT_TYPE_TO_MOCK_ID_COUNT.get(sobjectType);
        }
        String recordIdSuffix = String.valueOf(recordIdNumber++);
        SOBJECT_TYPE_TO_MOCK_ID_COUNT.put(sobjectType, recordIdNumber);

        String recordIdKeyPrefix = sobjectType.getDescribe().getKeyPrefix();
        Integer idFieldLength = sobjectType.getDescribe().fields.getMap().get('Id').getDescribe().getLength();
        Integer recordIdCenterLength = idFieldLength - recordIdKeyPrefix.length() - recordIdSuffix.length();
        return recordIdKeyPrefix + '0'.repeat(recordIdCenterLength) + recordIdSuffix;
    }

    /**
     * @description Creates a new builder instance for the specified `SObjectType`, including creating a
     *              new `SObject` record. The new `SObject` record is created with any default field values that
     *              have been configured on the `SObjectType`.
     * @param  sobjectType The `SObjectType` to use for generating a new test `SObject` record
     * @return             A new instance of `SObjectTestDataBuilder` for the specified `SObjectType`
     */
    public static SObjectTestDataBuilder createDataBuilder(Schema.SObjectType sobjectType) {
        return new SObjectTestDataBuilder(sobjectType);
    }

    /**
     * @description Creates a new builder instance for the specified `SObject` record
     * @param  record The existing test `SObject` record to populate with sample data
     * @return        A new instance of `SObjectTestDataBuilder` for the specified `SObject`
     */
    public static SObjectTestDataBuilder createDataBuilder(SObject record) {
        return new SObjectTestDataBuilder(record);
    }

    /**
     * @description Creates a `User` record for testing purposes, using the current user's profile
     * @return   The generated `User` record - it is not automatically inserted into the database.
     */
    public static User createUser() {
        return createUser(System.UserInfo.getProfileId());
    }

    /**
     * @description Creates a `User` record for testing purposes, using the specified profile ID
     * @param  profileId The `Profile` ID to use for the created `User`
     * @return   The generated `User` record - it is not automatically inserted into the database.
     */
    public static User createUser(Id profileId) {
        return new User(
            Alias = 'user_xyz',
            Email = 'user_xyz@test.com.net.org',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            LastName = 'Test Userson',
            LocaleSidKey = 'en_US',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = Logger.getTransactionId() + (userMockUsernameCount++) + '@test.com'
        );
    }

    /**
     * @description Queries for the `Organization` record for the current environment.
     * @return   The matching `Organization` record
     */
    public static Organization getOrganization() {
        // TODO Switch to creating mock instance of Organization with sensible defaults that tests can then update as needed for different scenarios
        if (cachedOrganization == null) {
            cachedOrganization = [SELECT Id, Name, InstanceName, IsSandbox, NamespacePrefix, OrganizationType, TrialExpirationDate FROM Organization];
        }
        return cachedOrganization;
    }

    /**
     * @description Returns the current environment's type - Scratch Org, Sandbox, or Production.
     * @return   The environment type
     */
    public static String getOrganizationEnvironmentType() {
        Organization organization = getOrganization();

        String orgEnvironmentType;
        if (organization.IsSandbox && organization.TrialExpirationDate != null) {
            orgEnvironmentType = 'Scratch Org';
        } else if (organization.IsSandbox) {
            orgEnvironmentType = 'Sandbox';
        } else {
            orgEnvironmentType = 'Production';
        }
        return orgEnvironmentType;
    }

    /**
     * @description Returns the current user
     * @return   The matching `User` record
     */
    public static User getUser() {
        return getUser(System.UserInfo.getUserId());
    }

    /**
     * @description Returns the specified user
     * @param  userId The ID of the `User` record to query
     * @return   The matching `User` record
     */
    public static User getUser(Id userId) {
        return [
            SELECT Id, Profile.Name, Profile.UserLicenseId, Profile.UserLicense.LicenseDefinitionKey, Profile.UserLicense.Name, Username, UserRole.Name
            FROM User
            WHERE Id = :userId
        ];
    }

    /**
     * @description Creates and inserts a `Group` record for testing queues, using the specified SObject Type
     * @param  queueDeveloperName The developer name to use for the new queue (stored in `Group.DeveloperName`)
     * @param  sobjectType        The `SObjectType` that the queue should be able to own (stored in `QueueSObject.SObjectType`)
     * @return                    The inserted `Group` record - it is automatically inserted into the database, as well as 1 child `QueueSObject` record.
     */
    public static Group insertQueue(String queueDeveloperName, Schema.SObjectType sobjectType) {
        Group queue = new Group(DeveloperName = queueDeveloperName, Name = queueDeveloperName, Type = 'Queue');
        insert queue;

        // To avoid a MIXED_DML_OPERATION exception, use System.runs() for inserting the QueueSObject record
        System.runAs(new User(Id = System.UserInfo.getUserId())) {
            QueueSObject queueSObject = new QueueSObject(QueueId = queue.Id, SObjectType = sobjectType.getDescribe().getName());
            insert queueSObject;
        }

        return queue;
    }

    /**
     * @description Sets a value for read-only fields that typically cannot be directly set on some SObjects
     * @param  record The `SObject` record to update
     * @param  field  The `Schema.SObjectField` for the field to update
     * @param  value  The field value to populate on the provied `SObject` record
     * @return        A new copy of the original `SObject` record that has the specified read-only field populated
     */
    public static SObject setReadOnlyField(SObject record, Schema.SObjectField field, Object value) {
        return setReadOnlyField(record, new Map<Schema.SObjectField, Object>{ field => value });
    }

    /**
     * @description Sets values for read-only fields that typically cannot be directly set on some SObjects
     * @param  record          record description
     * @param  changesToFields An instance of `Map<Schema.SObjectField, Object> containing the read-only fields and corresponding
     *                         field values to populate on the provied `SObject` record
     * @return                 A new copy of the original `SObject` record that has the specified read-only fields populated
     */
    public static SObject setReadOnlyField(SObject record, Map<Schema.SObjectField, Object> changesToFields) {
        String serializedRecord = JSON.serialize(record);
        Map<String, Object> deserializedRecordMap = (Map<String, Object>) JSON.deserializeUntyped(serializedRecord);

        // Loop through the deserialized record map and put the field & value
        // Since it's a map, if the field already exists on the SObject, it's updated (or added if it wasn't there already)
        for (Schema.SObjectField sobjectField : changesToFields.keySet()) {
            String fieldName = sobjectField.getDescribe().getName();
            deserializedRecordMap.put(fieldName, changesToFields.get(sobjectField));
        }

        serializedRecord = JSON.serialize(deserializedRecordMap);
        return (SObject) JSON.deserialize(serializedRecord, SObject.class);
    }

    @SuppressWarnings('PMD.ApexDoc')
    public class MockBatchableContext implements Database.BatchableContext {
        private Id childJobId;
        private Id jobId;

        public MockBatchableContext() {
            this.jobId = createId(Schema.AsyncApexJob.SObjectType);
            this.childJobId = createId(Schema.AsyncApexJob.SObjectType);
        }

        public MockBatchableContext(Id jobId) {
            this(jobId, null);
        }

        public MockBatchableContext(Id jobId, Id childJobId) {
            this.jobId = jobId;
            this.childJobId = childJobId;
        }

        public Id getJobId() {
            return this.jobId;
        }

        public Id getChildJobId() {
            return this.childJobId;
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public class MockFinalizerContext implements System.FinalizerContext {
        private Id asyncApexJobId;

        public MockFinalizerContext() {
            this.asyncApexJobId = createId(Schema.AsyncApexJob.SObjectType);
        }

        public MockFinalizerContext(Id asyncApexJobId) {
            this.asyncApexJobId = asyncApexJobId;
        }

        public Id getAsyncApexJobId() {
            return this.asyncApexJobId;
        }

        public Exception getException() {
            return null;
        }

        public System.ParentJobResult getResult() {
            return System.ParentJobResult.SUCCESS;
        }

        public Id getRequestId() {
            return System.Request.getCurrent().getRequestId();
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public class MockQueueableContext implements System.QueueableContext {
        private Id jobId;

        public MockQueueableContext() {
            this.jobId = createId(Schema.AsyncApexJob.SObjectType);
        }

        public MockQueueableContext(Id jobId) {
            this.jobId = jobId;
        }

        public Id getJobId() {
            return this.jobId;
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    public class MockSchedulableContext implements System.SchedulableContext {
        private Id triggerId;

        public MockSchedulableContext() {
            this.triggerId = createId(Schema.CronTrigger.SObjectType);
        }

        public MockSchedulableContext(Id triggerId) {
            this.triggerId = triggerId;
        }

        public Id getTriggerId() {
            return this.triggerId;
        }
    }

    @SuppressWarnings('PMD.ApexDoc, PMD.EmptyStatementBlock')
    public class MockHttpCallout implements System.HttpCalloutMock {
        public System.HttpRequest request { get; private set; }
        public System.HttpResponse response { get; private set; }
        public String responseBody { get; private set; }
        public Integer statusCode { get; private set; }
        public String statusMessage { get; private set; }

        public MockHttpCallout() {
        }

        public MockHttpCallout setResponseBody(String responseBody) {
            this.responseBody = responseBody;
            return this;
        }

        public MockHttpCallout setStatusCode(Integer statusCode) {
            this.statusCode = statusCode;
            return this;
        }

        public MockHttpCallout setStatus(String statusMessage) {
            this.statusMessage = statusMessage;
            return this;
        }

        public System.HttpResponse respond(System.HttpRequest request) {
            this.request = request;

            this.response = new System.HttpResponse();
            if (String.isNotBlank(this.responseBody)) {
                response.setBody(this.responseBody);
            }
            response.setStatusCode(this.statusCode);
            if (String.isNotBlank(this.statusMessage)) {
                response.setStatus(this.statusMessage);
            }
            return response;
        }
    }

    /**
     * @description Class used to create or update an `SObject` record with static fake data.
     *              This is useful in situations where you need to have fields populated, but the specific
     *              values used are not relevant to a particular test method.
     *              This class can be used when Apex writing tests for plugins.
     */
    public without sharing class SObjectTestDataBuilder {
        private final Schema.SObjectType sobjectType;
        private final SObject record;

        /**
         * @description Creates a new builder instance for the specified `SObjectType`, including creating a
         *              new `SObject` record. The new `SObject` record is created with any default field values that
         *              have been configured on the `SObjectType`.
         * @param  sobjectType The `SObjectType` to use for generating a new test `SObject` record
         */
        private SObjectTestDataBuilder(Schema.SObjectType sobjectType) {
            this(sobjectType.newSObject(null, true));
        }

        /**
         * @description Creates a new builder instance for the specified `SObject` record
         * @param  record The existing test `SObject` record to populate with sample data
         */
        private SObjectTestDataBuilder(SObject record) {
            this.record = record;
            this.sobjectType = record.getSObjectType();

            this.loadFields();
        }

        /**
         * @description Generates a mock record ID for the builder's `SObject` record
         * @return      The same instance of `SObjectTestDataBuilder`, useful for chaining methods
         */
        public SObjectTestDataBuilder populateMockId() {
            this.record.Id = createId(this.sobjectType);
            return this;
        }

        /**
         * @description Sets a value on all editable fields, unless the `SObject` record already had a value specified for a field (including `null`)
         * @return   The `SObject` record, with all editable fields populated
         */
        public SObjectTestDataBuilder populateAllFields() {
            this.setUnpopulatedFieldsOnRecord(SOBJECT_TYPE_TO_ALL_FIELDS.get(this.sobjectType));
            return this;
        }

        /**
         * @description Sets a value on all editable required fields, unless the `SObject` record already had a value specified for a field (including `null`)
         * @return   The `SObject` record, with all editable required fields populated
         */
        public SObjectTestDataBuilder populateRequiredFields() {
            this.setUnpopulatedFieldsOnRecord(SOBJECT_TYPE_TO_REQUIRED_FIELDS.get(this.sobjectType));
            return this;
        }

        /**
         * @description Returns the builder's `SObject` record with fields populated based on
         *              which builder methods have been called
         * @return   The builder's `SObject` record that was either provided by the calling code, or generated
         *           by the builder (depending on which constructor was used for `SObjectTestDataBuilder`)
         */
        public SObject getRecord() {
            return this.record;
        }

        private void loadFields() {
            if (SOBJECT_TYPE_TO_ALL_FIELDS.containsKey(this.sobjectType) && SOBJECT_TYPE_TO_REQUIRED_FIELDS.containsKey(this.sobjectType)) {
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
                when Long {
                    return 1234567890L;
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

            return stringValue.left(maxLength).trim();
        }
    }
}
