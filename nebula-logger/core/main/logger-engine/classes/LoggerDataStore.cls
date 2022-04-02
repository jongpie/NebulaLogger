//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Class used to manage any data-related operations, including database DML statements,
 *              publishing platform events via the event bus, and enqueueing queueable jobs
 */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.CyclomaticComplexity, PMD.EmptyStatementBlock, PMD.FieldDeclarationsShouldBeAtStart')
public without sharing class LoggerDataStore {
    private static Database DATABASE_INSTANCE {
        get {
            if (DATABASE_INSTANCE == null) {
                DATABASE_INSTANCE = new Database();
            }
            return DATABASE_INSTANCE;
        }
        set;
    }

    private static EventBus EVENT_BUS_INSTANCE {
        get {
            if (EVENT_BUS_INSTANCE == null) {
                EVENT_BUS_INSTANCE = new EventBus();
            }
            return EVENT_BUS_INSTANCE;
        }
        set;
    }

    private static JobQueue JOB_QUEUE_INSTANCE {
        get {
            if (JOB_QUEUE_INSTANCE == null) {
                JOB_QUEUE_INSTANCE = new JobQueue();
            }
            return JOB_QUEUE_INSTANCE;
        }
        set;
    }

    /**
     * @description The instance `LoggerDataStore.Database` used for any DML
     *              operations in the current transaction.
     * @return   The singleton instance of `LoggerDataStore.Database`
     */
    public static Database getDatabase() {
        return DATABASE_INSTANCE;
    }

    /**
     * @description The instance `LoggerDataStore.EventBus` used for publishing
     *              platform events in the current transaction.
     * @return   The singleton instance of `LoggerDataStore.EventBus`
     */
    public static EventBus getEventBus() {
        return EVENT_BUS_INSTANCE;
    }

    /**
     * @description The instance `LoggerDataStore.JobQueue` used for enqueuing
     *              any queueable jobs in the current transaction.
     * @return   The singleton instance of `LoggerDataStore.JobQueue`
     */
    public static JobQueue getJobQueue() {
        return JOB_QUEUE_INSTANCE;
    }

    @TestVisible
    private static void setMock(Database databaseInstance) {
        DATABASE_INSTANCE = databaseInstance;
    }

    @TestVisible
    private static void setMock(EventBus eventBusInstance) {
        EVENT_BUS_INSTANCE = eventBusInstance;
    }

    @TestVisible
    private static void setMock(JobQueue jobQueueInstance) {
        JOB_QUEUE_INSTANCE = jobQueueInstance;
    }

    public virtual class Database {
        protected Database() {
        }

        public virtual Database.DeleteResult deleteRecord(SObject record) {
            return this.deleteRecords(new List<SObject>{ record }).get(0);
        }

        public virtual List<Database.DeleteResult> deleteRecords(List<SObject> records) {
            return System.Database.delete(records);
        }

        public virtual Database.DeleteResult hardDeleteRecord(SObject record) {
            return this.hardDeleteRecords(new List<SObject>{ record }).get(0);
        }

        public virtual List<Database.DeleteResult> hardDeleteRecords(List<SObject> records) {
            List<Database.DeleteResult> results = this.deleteRecords(records);
            if (records.isEmpty() == false) {
                System.Database.emptyRecycleBin(records);
            }
            return results;
        }

        public virtual Database.SaveResult insertRecord(SObject record) {
            return this.insertRecords(new List<SObject>{ record }).get(0);
        }

        public virtual List<Database.SaveResult> insertRecords(List<SObject> records) {
            return System.Database.insert(records);
        }

        public virtual Database.SaveResult updateRecord(SObject record) {
            return this.updateRecords(new List<SObject>{ record }).get(0);
        }

        public virtual List<Database.SaveResult> updateRecords(List<SObject> records) {
            return System.Database.update(records);
        }

        public virtual Database.UndeleteResult undeleteRecord(SObject record) {
            return this.undeleteRecords(new List<SObject>{ record }).get(0);
        }

        public virtual List<Database.UndeleteResult> undeleteRecords(List<SObject> records) {
            return System.Database.undelete(records);
        }

        public virtual Database.UpsertResult upsertRecord(SObject record, Schema.SObjectField externalIdField) {
            return this.upsertRecords(this.castRecords(record), externalIdField).get(0);
        }

        public virtual List<Database.UpsertResult> upsertRecords(List<SObject> records, Schema.SObjectField externalIdField) {
            return System.Database.upsert(records, externalIdField);
        }

        private List<SObject> castRecords(SObject record) {
            // Salesforce will only allow upsert calls for SObjects if a declared-type list is passed in.
            // This is fine for the bulk method, where we can assume the caller is passing in an explicit list, but for a single record,
            // the only way to successfully perform the upsert is to dynamically spin up a list of the SObject's type

            String listType = 'List<' + record.getSObjectType() + '>';
            List<SObject> castRecords = (List<SObject>) Type.forName(listType).newInstance();
            castRecords.add(record);

            return castRecords;
        }
    }

    public virtual class EventBus {
        protected EventBus() {
        }

        public virtual Database.SaveResult publishRecord(SObject platformEvent) {
            return this.publishRecords(new List<SObject>{ platformEvent }).get(0);
        }

        public virtual List<Database.SaveResult> publishRecords(List<SObject> platformEvents) {
            return System.EventBus.publish(platformEvents);
        }
    }

    public virtual class JobQueue {
        protected JobQueue() {
        }

        public virtual Id enqueueJob(Queueable queueableJob) {
            return System.enqueueJob(queueableJob);
        }
    }
}
