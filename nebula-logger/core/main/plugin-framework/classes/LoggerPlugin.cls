//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugin Framework
 * @description Abstract class used to create custom Apex & Flow plugins
 */
public abstract class LoggerPlugin {
    /**
     * @description This method is the entry point for plugins to execute any custom logic.
     *              It is automatically called by the logging system for any enabled plugins.
     * @param  input The instance of `LoggerPlugin.PluginInput`, provided by the logging system
     */
    public abstract void execute(PluginInput input);

    /**
     * @description Class used by the logging system to provide context & record details to logger plugins
     */
    public class PluginInput {
        public TriggerOperation triggerOperationType;
        public List<SObject> triggerNew;
        public Map<Id, SObject> triggerNewMap;
        public List<SObject> triggerOld;
        public Map<Id, SObject> triggerOldMap;

        @InvocableVariable(label='Trigger Operation Name')
        public String triggerOperationTypeName;

        @InvocableVariable(label='Trigger Records')
        public List<PluginRecordInput> triggerRecords;
    }

    /**
     * @description Class used by the logging system to provide record details to logger plugins
     */
    public class PluginRecordInput {
        @InvocableVariable(label='Trigger.new Record')
        public SObject triggerRecordNew;

        @InvocableVariable(label='Trigger.old Record')
        public SObject triggerRecordOld;
    }
}
