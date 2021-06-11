//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Abstract class used by trigger handlers for shared logic
 */
public abstract class LoggerSObjectHandler {
    @testVisible
    private static Map<SObjectType, LoggerSObjectHandler__mdt> configurationsBySObjectType;
    @testVisible
    private static Map<SObjectType, List<LoggerSObjectHandlerPlugin__mdt>> pluginsBySObjectType;

    static {
        // When using CMDT's getAll(), it does not return relationship fields for EntityDefinition fields or child CMDT objects...
        // ... so instead query the LoggerSObjectHandler__mdt CMDT object
        List<LoggerSObjectHandler__mdt> configurations = [
            SELECT
                Id,
                IsEnabled__c,
                SObjectType__r.QualifiedApiName,
                (
                    SELECT Id, PluginType__c, PluginApiName__c
                    FROM LoggerSObjectHandlerPlugins__r
                    WHERE IsEnabled__c = TRUE
                    ORDER BY ExecutionOrder__c NULLS LAST, DeveloperName
                )
            FROM LoggerSObjectHandler__mdt
        ];

        configurationsBySObjectType = new Map<SObjectType, LoggerSObjectHandler__mdt>();
        pluginsBySObjectType = new Map<SObjectType, List<LoggerSObjectHandlerPlugin__mdt>>();
        for (LoggerSObjectHandler__mdt config : configurations) {
            // CMDT entity-definition relationship fields are weird, so skip some headaches by copying the Qualified API name
            config.SObjectType__c = config.SObjectType__r.QualifiedApiName;

            // Schema.getGlobalDescribe() is the worst, so don't use it
            SObjectType sobjectType = ((SObject) Type.forName(config.SObjectType__c).newInstance()).getSObjectType();

            configurationsBySObjectType.put(sobjectType, config);
            pluginsBySObjectType.put(sobjectType, config?.LoggerSObjectHandlerPlugins__r);
        }

        if (Test.isRunningTest() == true) {
            // Test shouldn't rely on the actual CMDT rules in the org - clear the loaded values, and defaults will be used
            configurationsBySObjectType.clear();
            pluginsBySObjectType.clear();
        }
    }

    @testVisible
    protected TriggerOperation triggerOperationType;
    @testVisible
    protected List<SObject> records;
    @testVisible
    protected Map<Id, SObject> recordsById;
    @testVisible
    protected List<SObject> oldRecords;
    @testVisible
    protected Map<Id, SObject> oldRecordsById;

    private LoggerSObjectHandler__mdt handlerConfiguration;
    private List<LoggerSObjectHandlerPlugin__mdt> plugins;

    public LoggerSObjectHandler() {
        this.setConfigurations();

        if (this.handlerConfiguration.IsEnabled__c == true) {
            this.records = Trigger.new;
            this.recordsById = Trigger.newMap;
            this.oldRecords = Trigger.old;
            this.oldRecordsById = Trigger.oldMap;
            this.triggerOperationType = Trigger.operationType;
        }
    }

    /**
     * @description Returns the SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public abstract SObjectType getSObjectType();

    protected Boolean isEnabled() {
        return this.handlerConfiguration.IsEnabled__c;
    }

    protected void executePlugins() {
        if (this.records == null || this.plugins == null || this.plugins.isEmpty()) {
            return;
        }

        for (LoggerSObjectHandlerPlugin__mdt pluginConfiguration : this.plugins) {
            switch on pluginConfiguration.PluginType__c {
                when 'Apex' {
                    this.executePluginApexClass(pluginConfiguration.PluginApiName__c);
                }
                when 'Flow' {
                    this.executePluginFlow(pluginConfiguration.PluginApiName__c);
                }
            }
        }
    }

    private void setConfigurations() {
        this.handlerConfiguration = configurationsBySObjectType.get(this.getSObjectType());
        this.plugins = pluginsBySObjectType.get(this.getSObjectType());

        if (this.handlerConfiguration == null) {
            // If no config exists in the org, then load some in-memory defaults
            this.handlerConfiguration = new LoggerSObjectHandler__mdt(
                IsEnabled__c = true,
                SObjectType__c = this.getSObjectType().getDescribe().getName()
            );

            configurationsBySObjectType.put(this.getSObjectType(), this.handlerConfiguration);
        }
    }

    private void executePluginApexClass(String apexClassName) {
        LoggerSObjectHandlerPlugin apexPlugin = (LoggerSObjectHandlerPlugin) Type.forName(apexClassName).newInstance();
        apexPlugin.execute(this.triggerOperationType, this.records, this.recordsById, this.oldRecords, this.oldRecordsById);
    }

    private void executePluginFlow(String flowApiName) {
        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('triggerOperationType', this.triggerOperationType?.name());
        flowInputs.put('records', this.records);
        flowInputs.put('oldRecords', this.oldRecordsById?.values());

        Flow.Interview flowPlugin = Flow.Interview.createInterview(flowApiName, flowInputs);
        flowPlugin.start();
    }
}
