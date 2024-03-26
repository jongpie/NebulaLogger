//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Test Utilities
 * @description Utility class used to mock any data-related operations for the database, event bus, and queueable jobs.
 *              These methods are generic, and should work in any Salesforce org.
 *              These methods can be used when writing Apex tests for plugins.
 * @see LoggerDataStore
 * @see LoggerMockDataCreator
 * @see LoggerTestConfigurator
 */
@SuppressWarnings('PMD.ApexDoc, PMD.EmptyStatementBlock')
@IsTest
public without sharing class LoggerMockDataStore {
    private static final Map<Schema.SObjectType, List<Schema.SObjectField>> SOBJECT_TYPE_TO_ALL_FIELDS = new Map<Schema.SObjectType, List<Schema.SObjectField>>();
    private static final Map<Schema.SObjectType, List<Schema.SObjectField>> SOBJECT_TYPE_TO_REQUIRED_FIELDS = new Map<Schema.SObjectType, List<Schema.SObjectField>>();
    private static final Map<Schema.SObjectType, List<Schema.SObjectField>> SOBJECT_TYPE_TO_STRING_FIELDS = new Map<Schema.SObjectType, List<Schema.SObjectField>>();

    private static final MockDatabase MOCK_DATABASE_INSTANCE = new MockDatabase();
    private static final MockEventBus MOCK_EVENT_BUS_INSTANCE = new MockEventBus();
    private static final MockJobQueue MOCK_JOB_QUEUE_INSTANCE = new MockJobQueue();

    public static MockDatabase getDatabase() {
        return MOCK_DATABASE_INSTANCE;
    }

    public static MockEventBus getEventBus() {
        return MOCK_EVENT_BUS_INSTANCE;
    }

    public static MockJobQueue getJobQueue() {
        return MOCK_JOB_QUEUE_INSTANCE;
    }

    public class MockDatabase extends LoggerDataStore.Database {
        private MockDatabase() {
        }

        public override List<Database.SaveResult> insertRecords(List<SObject> records) {
            List<Database.SaveResult> mockSaveResults = new List<Database.SaveResult>();
            if (records == null || records.isEmpty()) {
                return mockSaveResults;
            }

            // TODO call LoggerSObjectHandler instance using BEFORE_INSERT
            // TODO Set mock ID on records
            // TODO call LoggerSObjectHandler instance using AFTER_INSERT
            for (SObject record : records) {
                validateBeforeSave(record, true);
            }

            Schema.SObjectType sobjectType = records.get(0).getSObjectType();

            LoggerTriggerableContext beforeInsertInput = new LoggerTriggerableContext(sobjectType, TriggerOperation.BEFORE_INSERT, records);
            LoggerSObjectHandler beforeInsertHandler = LoggerSObjectHandler.getHandler(sobjectType);
            beforeInsertHandler?.overrideTriggerableContext(beforeInsertInput).execute();

            LoggerTriggerableContext afterInsertInput = new LoggerTriggerableContext(sobjectType, TriggerOperation.AFTER_INSERT, records);
            LoggerSObjectHandler afterInsertHandler = LoggerSObjectHandler.getHandler(sobjectType);
            afterInsertHandler?.overrideTriggerableContext(afterInsertInput).execute();

            return mockSaveResults;
        }
    }

    public class MockEventBus extends LoggerDataStore.EventBus {
        private List<SObject> publishedPlatformEvents;
        private Integer publishCount;

        private MockEventBus() {
            this.publishedPlatformEvents = new List<SObject>();
            this.publishCount = 0;
        }

        public Integer getPublishCallCount() {
            return this.publishCount;
        }

        public List<SObject> getPublishedPlatformEvents() {
            return this.publishedPlatformEvents;
        }

        public override Database.SaveResult publishRecord(SObject platformEvent) {
            return this.publishRecords(new List<SObject>{ platformEvent }).get(0);
        }

        public override List<Database.SaveResult> publishRecords(List<SObject> platformEvents) {
            this.publishCount++;
            this.publishedPlatformEvents.addAll(platformEvents);

            List<Database.SaveResult> mockSaveResults = new List<Database.SaveResult>();
            for (SObject platformEvent : platformEvents) {
                mockSaveResults.add(validateBeforeSave(platformEvent, false));
            }
            return mockSaveResults;
        }

        public void deliver() {
            if (this.publishedPlatformEvents.isEmpty()) {
                return;
            }

            Schema.SObjectType sobjectType = this.publishedPlatformEvents.get(0).getSObjectType();
            this.deliver(sobjectType);
        }

        public void deliver(Schema.SObjectType sobjectType) {
            if (sobjectType == null) {
                return;
            }

            this.deliver(LoggerSObjectHandler.getHandler(sobjectType));
        }

        public void deliver(LoggerSObjectHandler sobjectHandlerInstance) {
            LoggerTriggerableContext platformEventsTriggerContext = new LoggerTriggerableContext(
                sobjectHandlerInstance.getSObjectType(),
                TriggerOperation.AFTER_INSERT,
                this.publishedPlatformEvents
            );
            sobjectHandlerInstance?.overrideTriggerableContext(platformEventsTriggerContext).execute();
            this.publishedPlatformEvents.clear();
        }
    }

    public class MockJobQueue extends LoggerDataStore.JobQueue {
        private List<Queueable> enqueuedJobs;
        private Integer publishCount;

        private MockJobQueue() {
            this.enqueuedJobs = new List<Queueable>();
        }

        public List<Queueable> getEnqueuedJobs() {
            return this.enqueuedJobs;
        }

        public override Id enqueueJob(Queueable queueableJob) {
            this.enqueuedJobs.add(queueableJob);

            return LoggerMockDataCreator.createId(Schema.AsyncApexJob.SObjectType);
        }

        public void executeJobs() {
            for (Queueable job : this.enqueuedJobs) {
                job.execute(null); // TODO create mock instance for System.QueueableContext queueableContext
            }
        }
    }

    private static Database.SaveResult validateBeforeSave(SObject record, Boolean populateMockId) {
        // TODO Add checks to ensure:
        // 1. All required fields are populated
        // 2. All string fields are <= max field length
        // 3. Any restricted picklists have a valid value set
        Boolean recordIsValid = true;
        loadFields(record.getSObjectType());
        validateRequiredFieldsArePopulated(record);
        validateStringFieldsAreNotTooLong(record);

        if (recordIsValid && populateMockId) {
            record.Id = LoggerMockDataCreator.createId(record.getSObjectType());
        }
        return LoggerMockDataCreator.createDatabaseSaveResult(recordIsValid, record.Id);
    }

    private static void validateRequiredFieldsArePopulated(SObject record) {
        Schema.SObjectType sobjectType = record.getSObjectType();
        for (Schema.SObjectField requiredField : SOBJECT_TYPE_TO_REQUIRED_FIELDS.get(sobjectType)) {
            if (requiredField.getDescribe().getSoapType() == Schema.SoapType.BOOLEAN) {
                continue;
            }

            Boolean recordHasField = record.getPopulatedFieldsAsMap().containsKey(requiredField.getDescribe().getName());
            Boolean recordHasFieldValue = record.get(requiredField) != null;
            if (recordHasField == false || recordHasFieldValue == false) {
                SObjectException ex = new SObjectException();
                ex.setMessage('The field ' + requiredField + ' is required on record: ' + JSON.serializePretty(record));
                throw ex;
            }
        }
    }

    private static void validateStringFieldsAreNotTooLong(SObject record) {
        Schema.SObjectType sobjectType = record.getSObjectType();
        for (Schema.SObjectField stringField : SOBJECT_TYPE_TO_STRING_FIELDS.get(sobjectType)) {
            Boolean isFieldValueTooLong = ((String) record.get(stringField))?.length() > stringField.getDescribe().getLength();
            if (isFieldValueTooLong) {
                SObjectException ex = new SObjectException();
                ex.setMessage('The field value for ' + stringField + ' is too long: ' + record.get(stringField));
                throw ex;
            }
        }
    }

    private static void loadFields(Schema.SObjectType sobjectType) {
        if (SOBJECT_TYPE_TO_ALL_FIELDS.containsKey(sobjectType) && SOBJECT_TYPE_TO_REQUIRED_FIELDS.containsKey(sobjectType)) {
            return;
        }

        SOBJECT_TYPE_TO_ALL_FIELDS.put(sobjectType, new List<Schema.SObjectField>());
        SOBJECT_TYPE_TO_REQUIRED_FIELDS.put(sobjectType, new List<Schema.SObjectField>());
        SOBJECT_TYPE_TO_STRING_FIELDS.put(sobjectType, new List<Schema.SObjectField>());
        for (Schema.SObjectField field : sobjectType.getDescribe().fields.getMap().values()) {
            if (field.getDescribe().isCreateable() == false) {
                continue;
            }

            SOBJECT_TYPE_TO_ALL_FIELDS.get(sobjectType).add(field);
            if (field.getDescribe().getSoapType() == Schema.SoapType.STRING) {
                SOBJECT_TYPE_TO_STRING_FIELDS.get(sobjectType).add(field);
            }

            if (field.getDescribe().isNillable() == false) {
                // If a field is not nillable & it is createable, then it's required
                SOBJECT_TYPE_TO_REQUIRED_FIELDS.get(sobjectType).add(field);
            }
        }
    }
}
