@IsTest
public without sharing class LoggerMockDataStore {
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
            if (records == null || records.isEmpty() == true) {
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
            if (this.publishedPlatformEvents.isEmpty() == true) {
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
        Schema.SObjectType sobjectType = record.getSObjectType();
        Boolean recordIsValid = true;
        if (recordIsValid == true && populateMockId == true) {
            record.Id = LoggerMockDataCreator.createId(record.getSObjectType());
        }
        return LoggerMockDataCreator.createDatabaseSaveResult(recordIsValid, record.Id);
    }
}
