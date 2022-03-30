//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest
private class LoggerTriggerableContext_Tests {
    // Based on the trigger variables provided by the platform, currently only the TriggerOperations
    // BEFORE_INSERT, BEFORE_UPDATE and BEFORE_DELETE need to be tested - other operations & permutations
    // will have the same parameters as one of these three scenarios

    @IsTest
    static void it_constructs_instance_when_before_insert_operation() {
        Schema.SObjectType sobjectType = Schema.Log__c.SObjectType;
        TriggerOperation triggerOperationType = TriggerOperation.BEFORE_INSERT;
        List<Log__c> newLogs = new List<Log__c>();
        for (Integer i = 0; i < 3; i++) {
            newLogs.add((Log__c) new LoggerSObjectTestDataGenerator(sobjectType).populateRequiredFields());
        }

        LoggerTriggerableContext context = new LoggerTriggerableContext(sobjectType, triggerOperationType, newLogs, null, null);

        System.assertEquals(sobjectType, context.sobjectType);
        System.assertEquals(sobjectType.getDescribe().getName(), context.sobjectTypeName);
        System.assertEquals(triggerOperationType, context.triggerOperationType);
        System.assertEquals(newLogs, context.triggerNew);
        System.assertEquals(null, context.triggerNewMap);
        System.assertEquals(null, context.triggerOldMap);
        System.assertEquals(newLogs.size(), context.triggerRecords.size());
        for (Integer i = 0; i < newLogs.size(); i++) {
            System.assertEquals(newLogs.get(i), context.triggerRecords.get(i).triggerRecordNew);
            System.assertEquals(null, context.triggerRecords.get(i).triggerRecordOld);
        }
    }

    @IsTest
    static void it_constructs_instance_when_before_update_operation() {
        Schema.SObjectType sobjectType = Schema.Log__c.SObjectType;
        TriggerOperation triggerOperationType = TriggerOperation.BEFORE_UPDATE;
        List<Log__c> updatedLogs = new List<Log__c>();
        for (Integer i = 0; i < 3; i++) {
            Log__c log = (Log__c) new LoggerSObjectTestDataGenerator(sobjectType).populateRequiredFields();
            log.Id = LoggerTestUtils.createMockId(sobjectType);
            updatedLogs.add(log);
        }
        Map<Id, Log__c> newLogsMap = new Map<Id, Log__c>(updatedLogs.clone());
        Map<Id, Log__c> oldLogsMap = new Map<Id, Log__c>(updatedLogs.clone());

        LoggerTriggerableContext context = new LoggerTriggerableContext(sobjectType, triggerOperationType, updatedLogs, newLogsMap, oldLogsMap);

        System.assertEquals(sobjectType, context.sobjectType);
        System.assertEquals(sobjectType.getDescribe().getName(), context.sobjectTypeName);
        System.assertEquals(triggerOperationType, context.triggerOperationType);
        System.assertEquals(updatedLogs, context.triggerNew);
        System.assertEquals(newLogsMap, context.triggerNewMap);
        System.assertEquals(oldLogsMap, context.triggerOldMap);
        System.assertEquals(updatedLogs.size(), context.triggerRecords.size());
        for (Integer i = 0; i < updatedLogs.size(); i++) {
            Log__c log = updatedLogs.get(i);
            System.assertEquals(log, context.triggerRecords.get(i).triggerRecordNew);
            System.assertEquals(oldLogsMap.get(log.Id), context.triggerRecords.get(i).triggerRecordOld);
        }
    }

    @IsTest
    static void it_constructs_instance_when_before_delete_operation() {
        Schema.SObjectType sobjectType = Schema.Log__c.SObjectType;
        TriggerOperation triggerOperationType = TriggerOperation.BEFORE_DELETE;
        Map<Id, Log__c> deletedLogsMap = new Map<Id, Log__c>();
        for (Integer i = 0; i < 3; i++) {
            Log__c log = (Log__c) new LoggerSObjectTestDataGenerator(sobjectType).populateRequiredFields();
            log.Id = LoggerTestUtils.createMockId(sobjectType);
            deletedLogsMap.put(log.Id, log);
        }

        LoggerTriggerableContext context = new LoggerTriggerableContext(sobjectType, triggerOperationType, null, null, deletedLogsMap);

        System.assertEquals(sobjectType, context.sobjectType);
        System.assertEquals(sobjectType.getDescribe().getName(), context.sobjectTypeName);
        System.assertEquals(triggerOperationType, context.triggerOperationType);
        System.assertEquals(null, context.triggerNew);
        System.assertEquals(null, context.triggerNewMap);
        System.assertEquals(deletedLogsMap, context.triggerOldMap);
        System.assertEquals(deletedLogsMap.size(), context.triggerRecords.size());
        for (Integer i = 0; i < deletedLogsMap.size(); i++) {
            Log__c deletedLog = deletedLogsMap.values().get(i);
            System.assertEquals(null, context.triggerRecords.get(i).triggerRecordNew);
            System.assertEquals(deletedLog, context.triggerRecords.get(i).triggerRecordOld);
        }
    }
}
