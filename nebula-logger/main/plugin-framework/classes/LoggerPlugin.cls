public abstract class LoggerPlugin {


    public class PluginInput {
        public TriggerOperation triggerOperationType;
        @InvocableVariable(label='Trigger Operation Name')
        public String triggerOperationTypeName;

        @InvocableVariable(label='Trigger Records')
        public List<PluginRecordInput> triggerRecords;
    }

    public class PluginRecordInput {

        @InvocableVariable(label='Trigger.new Record')
        public SObject triggerRecordNew;

        @InvocableVariable(label='Trigger.old Record')
        public SObject triggerRecordOld;





        // @InvocableVariable(label='Trigger.new')
        // public List<SObject> triggerNew;

        // @InvocableVariable(label='Trigger.newMap')
        // public Map<Id, SObject> triggerNewMap;

        // @InvocableVariable(label='Trigger.old')
        // public List<SObject> triggerOld;

        // @InvocableVariable(label='Trigger.oldMap')
        // public Map<Id, SObject> triggerOldMap;

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
        List<PluginInput> inputs
    );
}
