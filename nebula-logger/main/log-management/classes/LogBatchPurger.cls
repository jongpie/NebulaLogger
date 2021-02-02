/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
global with sharing class LogBatchPurger implements Database.Batchable<SObject>, Database.Stateful {
    private String originalTransactionId;
    private Integer totalProcessedRecords = 0;

    global Database.QueryLocator start(Database.BatchableContext batchableContext) {
        // Each batchable method runs in a separate transaction
        // ...so store the first transaction ID to later relate the other transactions
        this.originalTransactionId = Logger.getTransactionId();

        if (LoggerSettings__c.getInstance().EnableSystemMessages__c) {
            Logger.info('Starting LogBatchPurger job');
            Logger.saveLog();
        }

        return Database.getQueryLocator(
            [
                SELECT Id, (SELECT Id FROM LogEntries__r)
                FROM Log__c
                WHERE LogRetentionDate__c <= :System.today() AND LogRetentionDate__c != NULL
            ]
        );
    }

    global void execute(Database.BatchableContext batchableContext, List<Log__c> scope) {
        this.totalProcessedRecords += scope.size();

        try {
            if (LoggerSettings__c.getInstance().EnableSystemMessages__c) {
                Logger.setParentLogTransactionId(this.originalTransactionId);
                Logger.info(new LogMessage('Starting deletion of {0} records', scope.size()));
            }

            List<SObject> recordsToDelete = new List<SObject>();
            for (Log__c log : scope) {
                recordsToDelete.addAll(log.LogEntries__r);
                recordsToDelete.add(log);
            }

            delete recordsToDelete;
            Database.emptyRecycleBin(recordsToDelete);
        } catch (Exception apexException) {
            if (LoggerSettings__c.getInstance().EnableSystemMessages__c) {
                Logger.error('Error deleting logs', apexException);
            }
        } finally {
            if (LoggerSettings__c.getInstance().EnableSystemMessages__c) {
                Logger.saveLog();
            }
        }
    }

    global void finish(Database.BatchableContext batchableContext) {
        if (LoggerSettings__c.getInstance().EnableSystemMessages__c) {
            Logger.setParentLogTransactionId(this.originalTransactionId);
            Logger.info(
                new LogMessage(
                    'Finished LogBatchPurger job, {0} total log records processed',
                    this.totalProcessedRecords
                )
            );
            Logger.saveLog();
        }
    }
}
