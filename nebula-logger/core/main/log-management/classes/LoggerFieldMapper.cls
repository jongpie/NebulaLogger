//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Maps fields values from custom fields on `LogEntryEvent__e`
 *              to equivalent fields on `Log__c`, `LogEntry__c`, and `LoggerScenario__c`
 */
public without sharing class LoggerFieldMapper {
    // TODO this is a goofy data structure, revisit how CMDT records are tracked/cached to see if there's a simpler & cleaner approach
    @TestVisible
    private static final Map<Schema.SObjectType, Map<Schema.SObjectType, List<LoggerFieldMapping__mdt>>> SOURCE_SOBJECT_TYPE_TO_TARGET_FIELD_MAPPINGS = loadRecords();

    /**
     * @description Copies field values from the `sourceRecord` to the `targetRecord`, based on rules configured in `LoggerFieldMapping__mdt`
     * @param  sourceRecord The source `SObject` record containing the data to copy
     * @param  targetRecord The target `SObject` record that should have fields & field values appended
     */
    @SuppressWarnings('PMD.CyclomaticComplexity')
    public static void mapFieldValues(SObject sourceRecord, SObject targetRecord) {
        if (sourceRecord == null || targetRecord == null) {
            return;
        }

        Map<Schema.SObjectType, List<LoggerFieldMapping__mdt>> targetSObjectTypeToFieldMappings = SOURCE_SOBJECT_TYPE_TO_TARGET_FIELD_MAPPINGS.get(
            sourceRecord.getSObjectType()
        );

        if (targetSObjectTypeToFieldMappings == null) {
            return;
        }

        Schema.SObjectType targetSObjectType = targetRecord.getSObjectType();
        List<LoggerFieldMapping__mdt> fieldMappings = targetSObjectTypeToFieldMappings.get(targetSObjectType);

        if (fieldMappings == null) {
            return;
        }

        // TODO consider caching the SObjectField instances and/or DescribeFieldResult instances
        Map<String, Schema.SObjectField> targetFieldNameToField = targetRecord.getSObjectType().getDescribe().fields.getMap();

        List<LoggerFieldMapping__mdt> incompatibleFieldMappings = new List<LoggerFieldMapping__mdt>();
        for (LoggerFieldMapping__mdt fieldMapping : fieldMappings) {
            try {
                Schema.SObjectField targetField = targetFieldNameToField.get(fieldMapping.TargetField__c);
                Object sourceRecordFieldValue = sourceRecord.get(fieldMapping.SourceField__c);
                // TODO consider caching the SObjectField instances and/or DescribeFieldResult instances
                if (targetField.getDescribe().getSoapType() == Schema.SoapType.STRING) {
                    sourceRecordFieldValue = LoggerDataStore.truncateFieldValue(targetField, (String) sourceRecordFieldValue);
                }
                targetRecord.put(fieldMapping.TargetField__c, sourceRecordFieldValue);
            } catch (System.Exception ex) {
                incompatibleFieldMappings.add(fieldMapping);
            }
        }
        if (LoggerParameter.ENABLE_SYSTEM_MESSAGES && incompatibleFieldMappings.isEmpty() == false) {
            LogMessage logMessage = new LogMessage(
                'Unable to map {0} custom fields on {1} record. Target SObject record:\n\n{2}',
                incompatibleFieldMappings.size(),
                targetRecord.getSObjectType(),
                JSON.serializePretty(targetRecord)
            );
            Logger.finest(logMessage, incompatibleFieldMappings);
        }
    }

    @SuppressWarnings('PMD.ApexCrudViolation')
    private static Map<Schema.SObjectType, Map<Schema.SObjectType, List<LoggerFieldMapping__mdt>>> loadRecords() {
        // TODO decide if this query should be moved to LogManagementDataSelector
        List<LoggerFieldMapping__mdt> fieldMappings = [
            SELECT
                DeveloperName,
                IsEnabled__c,
                SourceSObjectType__r.QualifiedApiName,
                SourceField__r.QualifiedApiName,
                TargetSObjectType__r.QualifiedApiName,
                TargetField__r.QualifiedApiName
            FROM LoggerFieldMapping__mdt
            WHERE IsEnabled__c = TRUE
        ];
        Map<Schema.SObjectType, Map<Schema.SObjectType, List<LoggerFieldMapping__mdt>>> sourceSObjectTypeToTargetFieldMappings = new Map<Schema.SObjectType, Map<Schema.SObjectType, List<LoggerFieldMapping__mdt>>>();
        for (LoggerFieldMapping__mdt fieldMapping : fieldMappings) {
            // This simplifies some of the CMDT fields by avoiding the use of parent fields directly,
            // which makes downstream code & testing much easier
            LoggerFieldMapping__mdt cleanedFieldMapping = new LoggerFieldMapping__mdt(
                DeveloperName = fieldMapping.DeveloperName,
                IsEnabled__c = fieldMapping.IsEnabled__c,
                SourceSObjectType__c = fieldMapping.SourceSObjectType__r.QualifiedApiName,
                SourceField__c = fieldMapping.SourceField__r.QualifiedApiName,
                TargetSObjectType__c = fieldMapping.TargetSObjectType__r.QualifiedApiName,
                TargetField__c = fieldMapping.TargetField__r.QualifiedApiName
            );

            addFieldMapping(cleanedFieldMapping, sourceSObjectTypeToTargetFieldMappings);
        }

        return sourceSObjectTypeToTargetFieldMappings;
    }

    private static void addFieldMapping(
        LoggerFieldMapping__mdt fieldMapping,
        Map<Schema.SObjectType, Map<Schema.SObjectType, List<LoggerFieldMapping__mdt>>> sourceSObjectTypeToTargetFieldMappings
    ) {
        // TODO decide if it's worth the overhead to use SObjectType, or if String is enough.
        // Since the data originates from Entity + Field Definition fields (that enforce valid values),
        // using String might be ok.
        Schema.SObjectType sourceSObjectType = getSObjectType(fieldMapping.SourceSObjectType__c);
        Schema.SObjectType targetSObjectType = getSObjectType(fieldMapping.TargetSObjectType__c);

        if (sourceSObjectTypeToTargetFieldMappings.containsKey(sourceSObjectType) == false) {
            Map<Schema.SObjectType, List<LoggerFieldMapping__mdt>> targetSObjectTypeToFieldMapping = new Map<Schema.SObjectType, List<LoggerFieldMapping__mdt>>{
                targetSObjectType => new List<LoggerFieldMapping__mdt>{ fieldMapping }
            };
            sourceSObjectTypeToTargetFieldMappings.put(sourceSObjectType, targetSObjectTypeToFieldMapping);
        } else {
            Map<Schema.SObjectType, List<LoggerFieldMapping__mdt>> targetSObjectTypeToFieldMapping = sourceSObjectTypeToTargetFieldMappings.get(
                sourceSObjectType
            );
            if (targetSObjectTypeToFieldMapping.containsKey(targetSObjectType) == false) {
                targetSObjectTypeToFieldMapping.put(targetSObjectType, new List<LoggerFieldMapping__mdt>());
            }
            targetSObjectTypeToFieldMapping.get(targetSObjectType).add(fieldMapping);
        }
    }

    private static Schema.SObjectType getSObjectType(String sobjectApiName) {
        return ((SObject) System.Type.forName(sobjectApiName).newInstance()).getSObjectType();
    }

    private static Schema.SObjectField getSObjectField(Schema.SObjectType sobjectType, String fieldApiName) {
        return sobjectType.getDescribe().fields.getMap().get(fieldApiName);
    }

    @TestVisible
    private static void setMock(LoggerFieldMapping__mdt fieldMapping) {
        if (String.isBlank(fieldMapping.DeveloperName)) {
            throw new System.IllegalArgumentException('DeveloperName is required on `LoggerFieldMapping__mdt: \n' + JSON.serializePretty(fieldMapping));
        }

        addFieldMapping(fieldMapping, SOURCE_SOBJECT_TYPE_TO_TARGET_FIELD_MAPPINGS);
    }
}
