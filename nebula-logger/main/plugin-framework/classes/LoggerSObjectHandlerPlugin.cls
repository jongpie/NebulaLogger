//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugin Framework
 * @description Abstract class used to create custom Apex plugins to execute for all trigger operations on `Log__c` or `LogEntry__c`
 */
// TODO: If possible, convert to `global` for the managed package - there are some additional platform limitations
//       and restrictions with making future changes to abstract classes & interfaces within managed packages
//       which could lead to a lot of problems, so for now/indefinitely, plugins will only work in the unlocked package
public abstract class LoggerSObjectHandlerPlugin {
    /**
     * @description All instances of `LoggerSObjectHandlerPlugin` are dynamically created, which requires a parameterless constructor
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public LoggerSObjectHandlerPlugin() {
    }

    /**
     * @description This method is the entry point for plugins to execute any custom logic.
     *              It is automatically called by the logging system for any enabled plugins.
     *              Several trigger-based parameters are provided - these parameters should be used by plugins,
     *              instead of calling the platform's static variables directly
     *              (e.g., use the provided `triggerNew` variable instead of using `Trigger.new` directly, and so on).
     * @param  triggerOperationType The enum instance of `Trigger.operationType` at the time that the handler class is created
     * @param  triggerNew           The value `Trigger.new` at the time that the handler class is created
     * @param  triggerNewMap        The value `Trigger.newMap` at the time that the handler class is created
     * @param  triggerOld           The value `Trigger.old` at the time that the handler class is created
     * @param  triggerOldMap        The value `Trigger.oldMap` at the time that the handler class is created
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public abstract void execute(
        TriggerOperation triggerOperationType,
        List<SObject> triggerNew,
        Map<Id, SObject> triggerNewMap,
        List<SObject> triggerOld,
        Map<Id, SObject> triggerOldMap
    );
}
