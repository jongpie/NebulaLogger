//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group log-management
 * @description Schedulable class used to schedule the batch job LogBatchPurger
 * @see LogBatchPurger
 */
global with sharing class LogBatchPurgeScheduler implements System.Schedulable {
    global void execute(SchedulableContext schedulableContext) {
        Database.executebatch(new LogBatchPurger());
    }
}
