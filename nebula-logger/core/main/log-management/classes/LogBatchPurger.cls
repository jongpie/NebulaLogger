//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Batch class used to delete old logs, based on `Log__c.LogRetentionDate__c <= :System.today()`
 * @see LogBatchPurgeScheduler
 */
@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList')
global with sharing class LogBatchPurger implements Database.Batchable<SObject>, Database.Stateful {
    @TestVisible
    private static final String NO_DELETE_ACCESS_EXCEPTION_MESSAGE = 'User does not have access to delete logs';

    @TestVisible
    private enum BatchableMethod {
        START,
        EXECUTE,
        FINISH
    }

    // Instance variables for top-level class
    @TestVisible
    private SObjectType currentSObjectType;
    @TestVisible
    private List<LoggerPlugin__mdt> pluginConfigurations;
    @TestVisible
    private Map<BatchableMethod, List<LoggerPlugin.Batchable>> methodToExecutedApexPlugins = new Map<BatchableMethod, List<LoggerPlugin.Batchable>>();
    @TestVisible
    private Map<BatchableMethod, List<Flow.Interview>> methodToExecutedFlowPlugins = new Map<BatchableMethod, List<Flow.Interview>>();

    private String originalTransactionId;
    private Integer totalProcessedRecords;

    /**
     * @description Default constructor, sets up instance of LogBatchPurger class.
     */
    global LogBatchPurger() {
        this.totalProcessedRecords = 0;
        this.pluginConfigurations = LoggerPlugin.getFilteredPluginConfigurations(
            new List<Schema.SObjectField>{ Schema.LoggerPlugin__mdt.BatchPurgerApexClass__c, Schema.LoggerPlugin__mdt.BatchPurgerFlowName__c },
            Schema.LoggerPlugin__mdt.BatchPurgerExecutionOrder__c
        );

        if (System.Test.isRunningTest() == true) {
            for (BatchableMethod method : BatchableMethod.values()) {
                this.methodToExecutedApexPlugins.put(method, new List<LoggerPlugin.Batchable>());
                this.methodToExecutedFlowPlugins.put(method, new List<Flow.Interview>());
            }
        }
    }

    /**
     * @description Required by the Database.Batchable interface.  Collects the records /
     * objects passed in to the batch instance and returns a Databae.QueryLocator reference representing
     * the current iteration.
     * @param batchableContext contains the context of the batch job
     * @return an instance of the Database.QueryLocator class
     * @throws NoAccessException when there is no delete access to Logs
     */
    global Database.QueryLocator start(Database.BatchableContext batchableContext) {
        if (Schema.Log__c.SObjectType.getDescribe().isDeletable() == false) {
            NoAccessException noDeleteAccessException = new NoAccessException();
            noDeleteAccessException.setMessage(NO_DELETE_ACCESS_EXCEPTION_MESSAGE);
            throw noDeleteAccessException;
        }

        // Each batchable method runs in a separate transaction,
        // so store the first transaction ID to later relate the other transactions
        this.originalTransactionId = Logger.getTransactionId();

        Schema.SObjectType initialSObjectType = this.getInitialSObjectType();
        LoggerBatchableContext input = new LoggerBatchableContext(batchableContext, initialSObjectType);
        this.executePlugins(BatchableMethod.START, input, null);
        this.currentSObjectType = input.sobjectType;

        if (LoggerParameter.ENABLE_SYSTEM_MESSAGES == true) {
            Logger.info('Logger - Starting LogBatchPurger job for SObject type: ' + this.currentSObjectType);
            Logger.saveLog();
        }

        return this.getQueryLocator(this.currentSObjectType);
    }

    /**
     * @description Required by the Database.Batchable interface, this method executes the logic for purging
     * log records.
     * @param batchableContext - The context of the current batch job.
     * @param logRecords - The log records to purge.
     */
    global void execute(Database.BatchableContext batchableContext, List<Log__c> logRecords) {
        // Legacy support: this batch job originally used this method, but List<SObject> is now used
        // However, the original method can't be removed from the managed package, so this is just
        // here for backwards compatability
        this.execute(batchableContext, (List<SObject>) logRecords);
    }

    /**
     * @description Required by the Database.Batchable interface, this method executes the logic for purging
     * log records.
     * @param batchableContext - The context of the current batch job.
     * @param scopeRecords - The log records to purge.
     */
    global void execute(Database.BatchableContext batchableContext, List<SObject> scopeRecords) {
        try {
            this.totalProcessedRecords += scopeRecords.size();
            LoggerBatchableContext input = new LoggerBatchableContext(batchableContext, this.currentSObjectType);
            this.executePlugins(BatchableMethod.EXECUTE, input, scopeRecords);

            this.hardDelete(scopeRecords);
            Logger.saveLog();
        } catch (Exception apexException) {
            if (LoggerParameter.ENABLE_SYSTEM_MESSAGES == true) {
                Logger.error('Logger - Error deleting logs', apexException);
            }
            Logger.saveLog();
            throw apexException;
        }
    }

    /**
     * @description Required by the Database.Batchable interface.  This method runs after all batch jobs are complete.
     * This method writes a status to the Log__c object indicating that the purge has finished.
     * @param batchableContext - The context of the batch jobs
     */
    global void finish(Database.BatchableContext batchableContext) {
        LoggerBatchableContext input = new LoggerBatchableContext(batchableContext, this.currentSObjectType);
        this.executePlugins(BatchableMethod.FINISH, input, null);

        Id nextBatchJobId;
        if (this.currentSObjectType != Schema.Log__c.SObjectType) {
            nextBatchJobId = Database.executeBatch(new LogBatchPurger());
        }

        if (LoggerParameter.ENABLE_SYSTEM_MESSAGES == true) {
            Logger.setParentLogTransactionId(this.originalTransactionId);
            Logger.info(
                new LogMessage(
                    'Logger - Finished LogBatchPurger job for {0}, {1} total log records processed',
                    this.currentSObjectType,
                    this.totalProcessedRecords
                )
            );
            if (nextBatchJobId != null) {
                Logger.info(new LogMessage('Logger - Starting a new instance of LogBatchPurger job, job ID is: {0}', nextBatchJobId));
            }
            Logger.saveLog();
        }
    }

    private void hardDelete(List<SObject> records) {
        // normally this would be an anti-pattern since most DML operations
        // are a no-op with an empty list - but emptyRecycleBin throws
        // for empty lists!
        if (records.isEmpty() == false) {
            delete records;
            Database.emptyRecycleBin(records);
        }
    }

    private Schema.SObjectType getInitialSObjectType() {
        Schema.SObjectType initialSObjectType;
        if (this.getLogEntryTagCount() > 0) {
            initialSObjectType = Schema.LogEntryTag__c.SObjectType;
        } else if (this.getLogEntryCount() > 0) {
            initialSObjectType = Schema.LogEntry__c.SObjectType;
        } else {
            initialSObjectType = Schema.Log__c.SObjectType;
        }
        return initialSObjectType;
    }

    private Integer getLogEntryTagCount() {
        return [
            SELECT COUNT()
            FROM LogEntryTag__c
            WHERE LogEntry__r.Log__r.LogRetentionDate__c <= :System.today() AND LogEntry__r.Log__r.LogRetentionDate__c != NULL
        ];
    }

    private Integer getLogEntryCount() {
        return [SELECT COUNT() FROM LogEntry__c WHERE Log__r.LogRetentionDate__c <= :System.today() AND Log__r.LogRetentionDate__c != NULL];
    }

    /**
     * @description Determines which of the 3 Logger objects (LogEntryTag__c, LogEntry__c or Log__c) should be deleted next.
     *              Records for each SObject type are deleted in separate instances of the LogBatchPurger job,
     *              starting with the lowest-level object (LogEntryTag__c). This helps to avoid running into DML limits that occurred
     *              when this job tried to delete records in multiple SObject types within 1 job
     * @param sobjectType Takes the sObjectType enum to instanciate a new log related instance.
     * @return The instance of Database.QueryLocator for the lowest-level Logger object
     */
    private Database.QueryLocator getQueryLocator(Schema.SObjectType sobjectType) {
        Database.QueryLocator queryLocator;

        switch on sobjectType.newSObject() {
            when LogEntryTag__c logEntryTag {
                queryLocator = Database.getQueryLocator(
                    [
                        SELECT Id
                        FROM LogEntryTag__c
                        WHERE LogEntry__r.Log__r.LogRetentionDate__c <= :System.today() AND LogEntry__r.Log__r.LogRetentionDate__c != NULL
                        ORDER BY LogEntry__r.Log__r.LogRetentionDate__c, LogEntry__r.Log__c
                    ]
                );
            }
            when LogEntry__c logEntry {
                queryLocator = Database.getQueryLocator(
                    [
                        SELECT Id
                        FROM LogEntry__c
                        WHERE Log__r.LogRetentionDate__c <= :System.today() AND Log__r.LogRetentionDate__c != NULL
                        ORDER BY Log__r.LogRetentionDate__c, Log__c
                    ]
                );
            }
            when Log__c log {
                queryLocator = Database.getQueryLocator(
                    [
                        SELECT Id
                        FROM Log__c
                        WHERE (LogRetentionDate__c <= :System.today() AND LogRetentionDate__c != NULL) OR TotalLogEntries__c = 0
                        ORDER BY LogRetentionDate__c
                    ]
                );
            }
        }

        return queryLocator;
    }

    private void executePlugins(BatchableMethod method, LoggerBatchableContext input, List<SObject> scopeRecords) {
        for (LoggerPlugin__mdt pluginConfiguration : this.pluginConfigurations) {
            if (String.isNotBlank(pluginConfiguration.BatchPurgerApexClass__c) == true) {
                this.executeApexPlugin(method, pluginConfiguration, input, scopeRecords);
            }
            if (String.isNotBlank(pluginConfiguration.BatchPurgerFlowName__c) == true) {
                this.executeFlowPlugin(method, pluginConfiguration, input, scopeRecords);
            }
        }
    }

    @SuppressWarnings('PMD.AvoidDebugStatements')
    private void executeApexPlugin(BatchableMethod method, LoggerPlugin__mdt pluginConfiguration, LoggerBatchableContext input, List<SObject> scopeRecords) {
        if (String.isBlank(pluginConfiguration.BatchPurgerApexClass__c) == true) {
            return;
        }

        try {
            LoggerPlugin.Batchable apexPlugin = LoggerPlugin.newBatchableInstance(pluginConfiguration.BatchPurgerApexClass__c);
            switch on method {
                when START {
                    apexPlugin.start(pluginConfiguration, input);
                }
                when EXECUTE {
                    apexPlugin.execute(pluginConfiguration, input, scopeRecords);
                }
                when FINISH {
                    apexPlugin.finish(pluginConfiguration, input);
                }
            }

            if (System.Test.isRunningTest() == true && apexPlugin != null) {
                this.methodToExecutedApexPlugins.get(method).add(apexPlugin);
            }
        } catch (TypeException ex) {
            System.debug(LoggingLevel.WARN, 'Unknown Apex class ' + pluginConfiguration.BatchPurgerApexClass__c + ', skipping plugin execution');
        }
    }

    @SuppressWarnings('PMD.AvoidDebugStatements')
    private void executeFlowPlugin(BatchableMethod method, LoggerPlugin__mdt pluginConfiguration, LoggerBatchableContext input, List<SObject> scopeRecords) {
        if (String.isBlank(pluginConfiguration.BatchPurgerFlowName__c) == true) {
            return;
        }

        try {
            Map<String, Object> flowInputs = new Map<String, Object>();
            flowInputs.put('pluginConfiguration', pluginConfiguration);
            flowInputs.put('pluginInput', input);
            if (scopeRecords != null) {
                flowInputs.put('scopeRecords', scopeRecords);
            }

            Flow.Interview flowPlugin = Flow.Interview.createInterview(pluginConfiguration.BatchPurgerFlowName__c, flowInputs);
            flowPlugin.start();

            if (System.Test.isRunningTest() == true && flowPlugin != null) {
                this.methodToExecutedFlowPlugins.get(method).add(flowPlugin);
            }
        } catch (TypeException ex) {
            System.debug(LoggingLevel.INFO, 'Unknown Flow ' + pluginConfiguration.BatchPurgerFlowName__c + ', skipping plugin execution');
        }
    }

    @TestVisible
    private Map<BatchableMethod, List<LoggerPlugin.Batchable>> getExecutedApexPlugins() {
        return this.methodToExecutedApexPlugins;
    }

    @TestVisible
    private Map<BatchableMethod, List<Flow.Interview>> getExecutedFlowPlugins() {
        return this.methodToExecutedFlowPlugins;
    }
}
