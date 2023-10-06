//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Schedulable class used to schedule the batch job `LogBatchPurger`
 * @see LogBatchPurger
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class LogBatchPurgeScheduler implements System.Schedulable {
    @TestVisible
    private static final String SCHEDULER_SYSTEM_MESSAGE_TEMPLATE = 'Logger - Scheduling LogBatchPurgeScheduler job, schedulableContext=={0}';

    @TestVisible
    private Integer batchSize;

    /**
     * @description Default constructor.  Sets initial batch size to 200.
     */
    global LogBatchPurgeScheduler() {
        this(LogBatchPurger.getDefaultBatchSize());
    }

    /**
     * @description Construct that accepts the batch size as a parameter.
     * @param batchSize - The size of the records per batch job / instance.  Max is 5000. Minium is 1.
     */
    global LogBatchPurgeScheduler(Integer batchSize) {
        this.batchSize = batchSize;
    }

    /**
     * @description Required by the Database.Schedulable interface, this method kicks off the LogBatchPurger batch class
     * on a scheduled basis.
     * @param schedulableContext The instance of `System.SchedulableContext` provided by the platform at runtime
     */
    global void execute(System.SchedulableContext schedulableContext) {
        Logger.setAsyncContext(schedulableContext);
        if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
            LogMessage logMessage = new LogMessage(SCHEDULER_SYSTEM_MESSAGE_TEMPLATE, schedulableContext);
            Logger.info(logMessage);
            Logger.saveLog();
        }

        if (this.batchSize == null) {
            this.batchSize = LogBatchPurger.getDefaultBatchSize();
        }

        Database.executebatch(new LogBatchPurger().setChainedBatchSize(this.batchSize), this.batchSize);
    }
}
