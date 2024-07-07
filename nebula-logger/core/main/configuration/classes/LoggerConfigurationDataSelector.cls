//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Selector class used for all queries that are specific to the configuration layer
 */
public without sharing virtual class LoggerConfigurationDataSelector {
    private static LoggerConfigurationDataSelector instance = new LoggerConfigurationDataSelector();

    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    private LoggerConfigurationDataSelector() {
    }

    /**
     * @description The instance `LoggerConfigurationDataSelector` used for any querying specific to the configuration layer
     * @return   The singleton instance of `LoggerConfigurationDataSelector`
     */
    public static LoggerConfigurationDataSelector getInstance() {
        return instance;
    }

    // TODO decide if LoggerSettings__c should be here (I don't think so)
    public virtual List<LogEntryDataMaskRule__mdt> getLogEntryDataMaskRules() {
        return LogEntryDataMaskRule__mdt.getAll().values();
    }

    public virtual List<LogEntryTagRule__mdt> getLogEntryTagRules() {
        return LogEntryTagRule__mdt.getAll().values();
    }

    // public virtual List<LoggerFieldMapping__mdt> getLoggerFieldMappings() {
    //     return [
    //         SELECT
    //             DeveloperName,
    //             IsEnabled__c,
    //             SourceSObjectType__r.QualifiedApiName,
    //             SourceField__r.QualifiedApiName,
    //             TargetSObjectType__r.QualifiedApiName,
    //             TargetField__r.QualifiedApiName
    //         FROM LoggerFieldMapping__mdt
    //         WHERE IsEnabled__c = TRUE
    //     ];
    // }

    public virtual List<LoggerParameter__mdt> getLoggerParameters() {
        return LoggerParameter__mdt.getAll().values();
    }

    public virtual List<LoggerPlugin__mdt> getLoggerPlugins() {
        return LoggerPlugin__mdt.getAll().values();
    }

    public virtual List<LoggerScenarioRule__mdt> getLoggerScenarioRules() {
        return LoggerScenarioRule__mdt.getAll().values();
    }

    public virtual List<LoggerSObjectHandler__mdt> getLoggerSObjectHandlers() {
        return LoggerSObjectHandler__mdt.getAll().values();
    }

    public virtual List<LogStatus__mdt> getLogStatuses() {
        return LogStatus__mdt.getAll().values();
    }

    @TestVisible
    private static void setMock(LoggerConfigurationDataSelector mockSelectorInstance) {
        instance = mockSelectorInstance;
    }
}
