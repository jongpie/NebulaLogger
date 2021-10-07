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
    private final Integer batchSize;

    /**
     * @description Default constructor.  Sets initial batch size to 200.
     */
    global LogBatchPurgeScheduler() {
        this(200);
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
     * @param schedulableContext Required for the Schedulable interface, this method contains contextual information about when this instance is/was scheduled.
     */
    global void execute(SchedulableContext schedulableContext) {
        if (LoggerParameter.ENABLE_SYSTEM_MESSAGES == true) {
            LogMessage logMessage = new LogMessage('Logger - Scheduling LogBatchPurgeScheduler job, schedulableContext=={0}', schedulableContext);
            Logger.info(logMessage);
            Logger.saveLog();
        }

        Database.executebatch(new LogBatchPurger(), this.batchSize);
    }
}
