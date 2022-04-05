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
    private static Database databaseInstance = new Database();
    private static EventBus eventBusInstance = new EventBus();
    private static JobQueue jobQueueInstance = new JobQueue();
    /**
     * @description The instance `LoggerDataStore.Database` used for any DML
     *              operations in the current transaction.
     * @return   The singleton instance of `LoggerDataStore.Database`
     */
    public static Database getDatabase() {
        return databaseInstance;
    }

    /**
     * @description The instance `LoggerDataStore.EventBus` used for publishing
     *              platform events in the current transaction.
     * @return   The singleton instance of `LoggerDataStore.EventBus`
     */
    public static EventBus getEventBus() {
        return eventBusInstance;
    }

    /**
     * @description The instance `LoggerDataStore.JobQueue` used for enqueuing
     *              any queueable jobs in the current transaction.
     * @return   The singleton instance of `LoggerDataStore.JobQueue`
     */
    public static JobQueue getJobQueue() {
        return jobQueueInstance;
    }

    @TestVisible
    private static void setMock(Database mockDatabase) {
        databaseInstance = mockDatabase;
    }

    @TestVisible
    private static void setMock(EventBus mockEventBus) {
        eventBusInstance = mockEventBus;
    }

    @TestVisible
    private static void setMock(JobQueue mockJobQueue) {
        jobQueueInstance = mockJobQueue;
    }

    public virtual class Database {
        protected Database() {
        }

        public virtual Database.DeleteResult deleteRecord(SObject record) {
            return System.Database.delete(record);
        }

        public virtual List<Database.DeleteResult> deleteRecords(List<SObject> records) {
            return System.Database.delete(records);
        }

        public virtual List<Database.DeleteResult> deleteRecords(List<SObject> records, Boolean allOrNone) {
            return System.Database.delete(records, allOrNone);
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
            return System.Database.insert(record);
        }

        public virtual List<Database.SaveResult> insertRecords(List<SObject> records) {
            return System.Database.insert(records);
        }

        public virtual List<Database.SaveResult> insertRecords(List<SObject> records, Boolean allOrNone) {
            return System.Database.insert(records, allOrNone);
        }

        public virtual List<Database.SaveResult> insertRecords(List<SObject> records, Database.DmlOptions dmlOptions) {
            return System.Database.insert(records, dmlOptions);
        }

        public virtual Database.UndeleteResult undeleteRecord(SObject record) {
            return System.Database.undelete(record);
        }

        public virtual List<Database.UndeleteResult> undeleteRecords(List<SObject> records) {
            return System.Database.undelete(records);
        }

        public virtual List<Database.UndeleteResult> undeleteRecords(List<SObject> records, Boolean allOrNone) {
            return System.Database.undelete(records, allOrNone);
        }

        public virtual Database.SaveResult updateRecord(SObject record) {
            return System.Database.update(record);
        }

        public virtual List<Database.SaveResult> updateRecords(List<SObject> records) {
            return System.Database.update(records);
        }

        public virtual List<Database.SaveResult> updateRecords(List<SObject> records, Boolean allOrNone) {
            return System.Database.update(records, allOrNone);
        }

        public virtual List<Database.SaveResult> updateRecords(List<SObject> records, Database.DmlOptions dmlOptions) {
            return System.Database.update(records, dmlOptions);
        }

        public virtual Database.UpsertResult upsertRecord(SObject record, Schema.SObjectField externalIdField) {
            return System.Database.upsert(record, externalIdField);
        }

        public virtual List<Database.UpsertResult> upsertRecords(List<SObject> records, Schema.SObjectField externalIdField) {
            return System.Database.upsert(records, externalIdField);
        }

        public virtual List<Database.UpsertResult> upsertRecords(List<SObject> records, Schema.SObjectField externalIdField, Boolean allOrNone) {
            return System.Database.upsert(records, externalIdField, allOrNone);
        }
    }

    public virtual class EventBus {
        protected EventBus() {
        }

        public virtual Database.SaveResult publishRecord(SObject platformEvent) {
            return System.EventBus.publish(platformEvent);
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
