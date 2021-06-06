//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Interface used to define custom logic to run when DML statements occur on `Log__c` or `LogEntry__c`
 */
 global interface LoggerSObjectPostProcessor {
    void execute(TriggerOperation triggerOperationType, List<SObject> loggerRecords, Map<Id, SObject> oldLoggerRecordsById);
}