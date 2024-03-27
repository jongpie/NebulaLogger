//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.MethodNamingConventions, PMD.PropertyNamingConventions')
@IsTest(IsParallel=true)
private class LoggerFieldMapper_Tests {
    static {
        LoggerFieldMapper.SOURCE_SOBJECT_TYPE_TO_TARGET_FIELD_MAPPINGS.clear();
    }

    @IsTest
    static void it_safely_returns_when_no_field_mappings_are_configured() {
        LogEntryEvent__e logEntryEvent = new LogEntryEvent__e(Message__c = 'Some value');
        LogEntry__c logEntry = new LogEntry__c();

        LoggerFieldMapper.mapFieldValues(logEntryEvent, logEntry);

        System.Assert.isTrue(logEntry.getPopulatedFieldsAsMap().isEmpty(), System.JSON.serialize(logEntry));
    }

    @IsTest
    static void it_maps_field_value_when_configured() {
        LoggerFieldMapper.setMock(
            new LoggerFieldMapping__mdt(
                DeveloperName = 'SomeDevName',
                IsEnabled__c = true,
                SourceSObjectType__c = Schema.LogEntryEvent__e.SObjectType.getDescribe().getName(),
                SourceField__c = Schema.LogEntryEvent__e.Message__c.getDescribe().getName(),
                TargetSObjectType__c = Schema.LogEntry__c.SObjectType.getDescribe().getName(),
                TargetField__c = Schema.LogEntry__c.Message__c.getDescribe().getName()
            )
        );
        LogEntryEvent__e logEntryEvent = new LogEntryEvent__e(Message__c = 'Some value');
        LogEntry__c logEntry = new LogEntry__c();

        LoggerFieldMapper.mapFieldValues(logEntryEvent, logEntry);

        System.Assert.isTrue(
            logEntry.getPopulatedFieldsAsMap().containsKey(Schema.LogEntry__c.Message__c.getDescribe().getName()),
            System.JSON.serialize(logEntry)
        );
        System.Assert.areEqual(logEntryEvent.Message__c, logEntry.Message__c);
    }
}
