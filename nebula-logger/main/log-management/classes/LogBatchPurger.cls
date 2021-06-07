//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Batch class used to delete old logs, based on `Log__c.LogRetentionDate__c <= :System.today()`
 * @see LogBatchPurgeScheduler
 */
global with sharing class LogBatchPurger implements Database.Batchable<SObject>, Database.Stateful {
    private final Boolean isSystemDebuggingEnabled;

    private String originalTransactionId;
    private Integer totalProcessedRecords = 0;

    @testVisible
    // Database.emptyRecycleBin counts as a DML statement per record
    private static Integer MAX_RECORDS_DELETED = (Limits.getLimitDmlRows() / 2) - 1;
    private static Integer DELETED_COUNT = 0;

    private class LogBatchPurgerException extends Exception {
    }

    global LogBatchPurger() {
        this.isSystemDebuggingEnabled = Logger.getUserSettings()?.EnableSystemMessages__c == true;
    }

    private class LogDeleter implements System.Queueable {
        private final List<SObject> recordsToDelete;
        public LogDeleter(List<SObject> recordsToDelete) {
            this.recordsToDelete = recordsToDelete;
        }

        public void process() {
            if (DELETED_COUNT + this.recordsToDelete.size() < MAX_RECORDS_DELETED) {
                this.hardDelete(this.recordsToDelete);
                this.recordsToDelete.clear();
            } else {
                List<SObject> safeToDeleteRecords = new List<SObject>();
                while (this.recordsToDelete.size() > MAX_RECORDS_DELETED && !this.recordsToDelete.isEmpty()) {
                    for (Integer index = this.recordsToDelete.size() - 1; index >= 0; index--) {
                        safeToDeleteRecords.add(this.recordsToDelete[index]);
                        this.recordsToDelete.remove(index);
                    }
                }
                this.hardDelete(safeToDeleteRecords);
            }


            if (!this.recordsToDelete.isEmpty() && Limits.getLimitQueueableJobs() > Limits.getQueueableJobs()) {
                System.enqueueJob(this);
            }
        }

        public void execute(QueueableContext queueableContext) {
            this.process();
        }

        private void hardDelete(List<SObject> records) {
            DELETED_COUNT += records.size();
            delete records;
            Database.emptyRecycleBin(records);
        }
    }

    global Database.QueryLocator start(Database.BatchableContext batchableContext) {
        if (!Schema.Log__c.SObjectType.getDescribe().isDeletable()) {
            throw new LogBatchPurgerException('User does not have access to delete logs');
        }

        // Each batchable method runs in a separate transaction
        // ...so store the first transaction ID to later relate the other transactions
        this.originalTransactionId = Logger.getTransactionId();

        if (this.isSystemDebuggingEnabled) {
            Logger.info('Starting LogBatchPurger job');
            Logger.saveLog();
        }

        return Database.getQueryLocator(
            [SELECT Id, (SELECT Id FROM LogEntries__r) FROM Log__c WHERE LogRetentionDate__c <= :System.today() AND LogRetentionDate__c != NULL]
        );
    }

    global void execute(Database.BatchableContext batchableContext, List<Log__c> logsToDelete) {
        if (!Schema.Log__c.SObjectType.getDescribe().isDeletable()) {
            throw new LogBatchPurgerException('User does not have access to delete logs');
        }


        try {
            if (this.isSystemDebuggingEnabled) {
                Logger.setParentLogTransactionId(this.originalTransactionId);
                Logger.info(new LogMessage('Starting deletion of {0} records', logsToDelete.size()));
            }

            // Delete the child log entries first
            List<LogEntry__c> logEntriesToDelete = [SELECT Id FROM LogEntry__c WHERE Log__c IN :logsToDelete];
            new LogDeleter(logEntriesToDelete).process();

            // Now delete the parent logs
            new LogDeleter(logsToDelete).process();
            this.totalProcessedRecords += DELETED_COUNT;
        } catch (Exception apexException) {
            if (this.isSystemDebuggingEnabled) {
                Logger.error('Error deleting logs', apexException);
            }
        } finally {
            Logger.saveLog();
        }
    }

    global void finish(Database.BatchableContext batchableContext) {
        if (this.isSystemDebuggingEnabled) {
            Logger.setParentLogTransactionId(this.originalTransactionId);
            Logger.info(new LogMessage('Finished LogBatchPurger job, {0} total log records processed', this.totalProcessedRecords));
            Logger.saveLog();
        }
    }
}
