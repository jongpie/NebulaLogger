//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group log-management
 * @description Batch class used to delete old logs, based on `Log__c.LogRetentionDate__c <= :System.today()`
 * @see LogBatchPurgeScheduler
 */
global with sharing class LogBatchPurger implements Database.Batchable<SObject>, Database.Stateful {
    private String originalTransactionId;
    private Integer totalProcessedRecords = 0;

    private class LogBatchPurgerException extends Exception {
    }

    global Database.QueryLocator start(Database.BatchableContext batchableContext) {
        if (!Schema.Log__c.SObjectType.getDescribe().isDeletable()) {
            throw new LogBatchPurgerException('User does not have access to delete logs');
        }

        // Each batchable method runs in a separate transaction
        // ...so store the first transaction ID to later relate the other transactions
        this.originalTransactionId = Logger.getTransactionId();

        if (Logger.getUserSettings().EnableSystemMessages__c == true) {
            Logger.info('Starting LogBatchPurger job');
            Logger.saveLog();
        }

        return Database.getQueryLocator(
            [SELECT Id, (SELECT Id FROM LogEntries__r) FROM Log__c WHERE LogRetentionDate__c <= :System.today() AND LogRetentionDate__c != NULL]
        );
    }

    global void execute(Database.BatchableContext batchableContext, List<Log__c> scope) {
        if (!Schema.Log__c.SObjectType.getDescribe().isDeletable()) {
            throw new LogBatchPurgerException('User does not have access to delete logs');
        }

        this.totalProcessedRecords += scope.size();

        try {
            if (Logger.getUserSettings().EnableSystemMessages__c == true) {
                Logger.setParentLogTransactionId(this.originalTransactionId);
                Logger.info(new LogMessage('Starting deletion of {0} records', scope.size()));
            }

            List<Log__c> logsToDelete = new List<Log__c>();
            List<LogEntry__c> logEntriesToDelete = new List<LogEntry__c>();
            for (Log__c log : scope) {
                logEntriesToDelete.addAll(log.LogEntries__r);
                logsToDelete.add(log);
            }

            List<SObject> recordsToDelete = new List<SObject>();
            // not obvious coupling - the LogEntry__c records must be deleted first
            // to avoid System.DmlException: ENTITY_IS_DELETED on the corresponding Log__c records
            // we also avoid the need to sort but still avoid the potential for a DML chunking error
            // by correct separating the records of different SObject types from one another
            recordsToDelete.addAll(logEntriesToDelete);
            recordsToDelete.addAll(logsToDelete);

            delete recordsToDelete;
            Database.emptyRecycleBin(recordsToDelete);
        } catch (Exception apexException) {
            if (Logger.getUserSettings().EnableSystemMessages__c == true) {
                Logger.error('Error deleting logs', apexException);
            }
        } finally {
            if (Logger.getUserSettings().EnableSystemMessages__c == true) {
                Logger.saveLog();
            }
        }
    }

    global void finish(Database.BatchableContext batchableContext) {
        if (Logger.getUserSettings().EnableSystemMessages__c == true) {
            Logger.setParentLogTransactionId(this.originalTransactionId);
            Logger.info(new LogMessage('Finished LogBatchPurger job, {0} total log records processed', this.totalProcessedRecords));
            Logger.saveLog();
        }
    }
}
