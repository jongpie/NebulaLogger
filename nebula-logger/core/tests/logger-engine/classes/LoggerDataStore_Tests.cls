//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

// TODO switch to using standard object(s) available in all orgs (instead of Log__c) so this can be split off as a separate repo
// Possible objects to use: User, Group (Queue) and QueueSObject (none support undelete though), and not sure if it's possible
// to test platform events/EventBus using only standard objects
@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerDataStore_Tests {
    // Database DML tests
    @IsTest
    static void it_should_delete_record() {
        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        insert log;
        System.Assert.areEqual(1, System.Limits.getDmlStatements());
        System.Assert.areEqual(1, System.Limits.getDmlRows());

        Database.DeleteResult result = LoggerDataStore.getDatabase().deleteRecord(log);

        System.Assert.areEqual(2, System.Limits.getDmlStatements());
        System.Assert.areEqual(2, System.Limits.getDmlRows());
        System.Assert.isTrue(result.isSuccess());
        Log__c persistedLog = [SELECT Id, IsDeleted FROM Log__c WHERE Id = :log.Id ALL ROWS];
        System.Assert.isTrue(persistedLog.IsDeleted);
    }

    @IsTest
    static void it_should_delete_record_list() {
        List<Log__c> logsToDelete = new List<Log__c>();
        logsToDelete.add((Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord());
        logsToDelete.add((Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord());
        insert logsToDelete;
        System.Assert.areEqual(1, System.Limits.getDmlStatements());
        System.Assert.areEqual(2, System.Limits.getDmlRows());

        List<Database.DeleteResult> results = LoggerDataStore.getDatabase().deleteRecords(logsToDelete);

        System.Assert.areEqual(2, System.Limits.getDmlStatements());
        System.Assert.areEqual(4, System.Limits.getDmlRows());
        System.Assert.areEqual(logsToDelete.size(), results.size());
        for (Database.DeleteResult result : results) {
            System.Assert.isTrue(result.isSuccess());
        }
        List<Log__c> persistedLogs = [SELECT Id, IsDeleted FROM Log__c WHERE Id IN :logsToDelete ALL ROWS];
        System.Assert.areEqual(logsToDelete.size(), persistedLogs.size());
        for (Log__c persistedLog : persistedLogs) {
            System.Assert.isTrue(persistedLog.IsDeleted);
        }
    }

    @IsTest
    static void it_should_partially_delete_record_list_when_allOrNone_is_false() {
        List<Log__c> logsToDelete = new List<Log__c>();
        logsToDelete.add((Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord());
        logsToDelete.add((Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord());
        insert logsToDelete;
        // Delete one of the logs first to cause a failure in the delete DML statement
        delete logsToDelete.get(0);
        System.Assert.areEqual(2, System.Limits.getDmlStatements());
        System.Assert.areEqual(3, System.Limits.getDmlRows());

        List<Database.DeleteResult> results = LoggerDataStore.getDatabase().deleteRecords(logsToDelete, false);

        System.Assert.areEqual(3, System.Limits.getDmlStatements());
        System.Assert.areEqual(5, System.Limits.getDmlRows());
        System.Assert.areEqual(logsToDelete.size(), results.size());
        System.Assert.isFalse(results.get(0).isSuccess());
        System.Assert.isTrue(results.get(1).isSuccess());
        List<Log__c> persistedLogs = [SELECT Id, IsDeleted FROM Log__c WHERE Id IN :logsToDelete ALL ROWS];
        System.Assert.areEqual(logsToDelete.size(), persistedLogs.size());
        for (Log__c persistedLog : persistedLogs) {
            System.Assert.isTrue(persistedLog.IsDeleted);
        }
    }

    @IsTest
    static void it_should_hard_delete_record() {
        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        log.TransactionId__c = '999';
        insert log;
        System.Assert.areEqual(1, System.Limits.getDmlStatements());
        System.Assert.areEqual(1, System.Limits.getDmlRows());

        Database.DeleteResult result = LoggerDataStore.getDatabase().hardDeleteRecord(log);

        System.Assert.areEqual(3, System.Limits.getDmlStatements());
        System.Assert.areEqual(3, System.Limits.getDmlRows());
        System.Assert.isTrue(result.isSuccess());
        // Frustratingly, there's not a way to ensure that Database.emptyRecycleBin() was called and
        // the supposedly-hard-deleted records are still returned in SOQL, so at least verify that the
        // record has IsDeleted = true for now. This can probably be tested better with a @TestVisible property later.
        Log__c persistedLog = [SELECT Id, IsDeleted FROM Log__c WHERE Id = :log.Id ALL ROWS];
        System.Assert.isTrue(persistedLog.IsDeleted);
    }

    @IsTest
    static void it_should_hard_delete_record_list() {
        List<Log__c> logsToDelete = new List<Log__c>();
        logsToDelete.add((Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord());
        logsToDelete.add((Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord());
        insert logsToDelete;
        System.Assert.areEqual(1, System.Limits.getDmlStatements());
        System.Assert.areEqual(2, System.Limits.getDmlRows());

        List<Database.DeleteResult> results = LoggerDataStore.getDatabase().hardDeleteRecords(logsToDelete);

        System.Assert.areEqual(3, System.Limits.getDmlStatements());
        System.Assert.areEqual(6, System.Limits.getDmlRows());
        System.Assert.areEqual(logsToDelete.size(), results.size());
        for (Database.DeleteResult result : results) {
            System.Assert.isTrue(result.isSuccess());
        }
        // Frustratingly, there's not a way to ensure that Database.emptyRecycleBin() was called and
        // the supposedly-hard-deleted records are still returned in SOQL, so at least verify that the
        // record has IsDeleted = true for now. This can probably be tested better with a @TestVisible property later.
        List<Log__c> persistedLogs = [SELECT Id, IsDeleted FROM Log__c WHERE Id IN :logsToDelete ALL ROWS];
        System.Assert.areEqual(logsToDelete.size(), persistedLogs.size());
        for (Log__c persistedLog : persistedLogs) {
            System.Assert.isTrue(persistedLog.IsDeleted);
        }
    }

    @IsTest
    static void it_should_insert_record() {
        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        log.TransactionId__c = '1234';
        System.Assert.areEqual(0, System.Limits.getDmlStatements());
        System.Assert.areEqual(0, System.Limits.getDmlRows());

        Database.SaveResult result = LoggerDataStore.getDatabase().insertRecord(log);

        System.Assert.areEqual(1, System.Limits.getDmlStatements());
        System.Assert.areEqual(1, System.Limits.getDmlRows());
        System.Assert.isNotNull(log.Id);
        System.Assert.isTrue(result.isSuccess());
        Log__c persistedLog = [SELECT Id, TransactionId__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(log.TransactionId__c, persistedLog.TransactionId__c);
    }

    @IsTest
    static void it_should_insert_record_list() {
        List<Log__c> logsToInsert = new List<Log__c>();
        logsToInsert.add((Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord());
        logsToInsert.add((Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord());
        System.Assert.areEqual(0, System.Limits.getDmlStatements());
        System.Assert.areEqual(0, System.Limits.getDmlRows());

        List<Database.SaveResult> results = LoggerDataStore.getDatabase().insertRecords(logsToInsert);

        System.Assert.areEqual(1, System.Limits.getDmlStatements());
        System.Assert.areEqual(2, System.Limits.getDmlRows());
        System.Assert.areEqual(logsToInsert.size(), results.size());
        for (Database.SaveResult result : results) {
            System.Assert.isTrue(result.isSuccess());
        }
        List<Log__c> persistedLogs = [SELECT Id, TransactionId__c FROM Log__c WHERE Id IN :logsToInsert];
        System.Assert.areEqual(logsToInsert.size(), persistedLogs.size());
    }

    @IsTest
    static void it_should_partially_insert_record_list_when_allOrNone_is_false() {
        Log__c existingRecord = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        insert existingRecord;
        List<Log__c> logsToInsert = new List<Log__c>();
        logsToInsert.add((Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord());
        logsToInsert.add(existingRecord);
        System.Assert.areEqual(1, System.Limits.getDmlStatements());
        System.Assert.areEqual(1, System.Limits.getDmlRows());

        List<Database.SaveResult> results = LoggerDataStore.getDatabase().insertRecords(logsToInsert, false);

        System.Assert.areEqual(2, System.Limits.getDmlStatements());
        System.Assert.areEqual(3, System.Limits.getDmlRows());
        System.Assert.areEqual(logsToInsert.size(), results.size());
        System.Assert.isTrue(results.get(0).isSuccess());
        System.Assert.isFalse(results.get(1).isSuccess());
        List<Log__c> persistedLogs = [SELECT Id, TransactionId__c FROM Log__c WHERE Id IN :logsToInsert];
        System.Assert.areEqual(2, persistedLogs.size());
    }

    @IsTest
    static void it_should_partially_insert_record_list_when_allOrNone_is_false_in_dml_options() {
        Log__c existingRecord = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        insert existingRecord;
        List<Log__c> logsToInsert = new List<Log__c>();
        logsToInsert.add((Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord());
        logsToInsert.add(existingRecord);
        Database.DmlOptions dmlOptions = new Database.DmlOptions();
        dmlOptions.OptAllOrNone = false;
        System.Assert.areEqual(1, System.Limits.getDmlStatements());
        System.Assert.areEqual(1, System.Limits.getDmlRows());

        List<Database.SaveResult> results = LoggerDataStore.getDatabase().insertRecords(logsToInsert, dmlOptions);

        System.Assert.areEqual(2, System.Limits.getDmlStatements());
        System.Assert.areEqual(3, System.Limits.getDmlRows());
        System.Assert.areEqual(logsToInsert.size(), results.size());
        System.Assert.isTrue(results.get(0).isSuccess());
        System.Assert.isFalse(results.get(1).isSuccess());
        List<Log__c> persistedLogs = [SELECT Id, TransactionId__c FROM Log__c WHERE Id IN :logsToInsert];
        System.Assert.areEqual(2, persistedLogs.size());
    }

    @IsTest
    static void it_should_undelete_record() {
        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        insert log;
        delete log;
        log = [SELECT Id, IsDeleted FROM Log__c WHERE Id = :log.Id ALL ROWS];
        System.Assert.isTrue(log.IsDeleted);
        System.Assert.areEqual(2, System.Limits.getDmlStatements());
        System.Assert.areEqual(2, System.Limits.getDmlRows());

        Database.UndeleteResult result = LoggerDataStore.getDatabase().undeleteRecord(log);

        System.Assert.areEqual(3, System.Limits.getDmlStatements());
        System.Assert.areEqual(3, System.Limits.getDmlRows());
        System.Assert.isTrue(result.isSuccess());
        Log__c persistedLog = [SELECT Id, IsDeleted FROM Log__c WHERE Id = :log.Id ALL ROWS];
        System.Assert.isFalse(persistedLog.IsDeleted);
    }

    @IsTest
    static void it_should_undelete_records() {
        List<Log__c> logsToUndelete = new List<Log__c>();
        logsToUndelete.add((Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord());
        logsToUndelete.add((Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord());
        insert logsToUndelete;
        delete logsToUndelete;
        logsToUndelete = [SELECT Id, IsDeleted FROM Log__c WHERE Id IN :logsToUndelete ALL ROWS];
        for (Log__c deletedLog : logsToUndelete) {
            System.Assert.isTrue(deletedLog.IsDeleted);
        }
        System.Assert.areEqual(2, System.Limits.getDmlStatements());
        System.Assert.areEqual(4, System.Limits.getDmlRows());

        List<Database.UndeleteResult> results = LoggerDataStore.getDatabase().undeleteRecords(logsToUndelete);

        System.Assert.areEqual(3, System.Limits.getDmlStatements());
        System.Assert.areEqual(6, System.Limits.getDmlRows());
        System.Assert.areEqual(logsToUndelete.size(), results.size());
        for (Database.UndeleteResult result : results) {
            System.Assert.isTrue(result.isSuccess());
        }
        List<Log__c> persistedLogs = [SELECT Id, IsDeleted FROM Log__c WHERE Id IN :logsToUndelete ALL ROWS];
        System.Assert.areEqual(logsToUndelete.size(), persistedLogs.size());
        for (Log__c persistedLog : persistedLogs) {
            System.Assert.isFalse(persistedLog.IsDeleted);
        }
    }

    @IsTest
    static void it_should_partially_undelete_records_when_allOrNone_is_false() {
        List<Log__c> logsToUndelete = new List<Log__c>();
        logsToUndelete.add((Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord());
        logsToUndelete.add((Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord());
        insert logsToUndelete;
        delete logsToUndelete.get(0);
        logsToUndelete = [SELECT Id, IsDeleted FROM Log__c WHERE Id IN :logsToUndelete ALL ROWS];
        System.Assert.isTrue(logsToUndelete.get(0).IsDeleted);
        System.Assert.isFalse(logsToUndelete.get(1).IsDeleted);
        System.Assert.areEqual(2, System.Limits.getDmlStatements());
        System.Assert.areEqual(3, System.Limits.getDmlRows());

        List<Database.UndeleteResult> results = LoggerDataStore.getDatabase().undeleteRecords(logsToUndelete, false);

        System.Assert.areEqual(3, System.Limits.getDmlStatements());
        System.Assert.areEqual(5, System.Limits.getDmlRows());
        System.Assert.areEqual(logsToUndelete.size(), results.size());
        System.Assert.isTrue(results.get(0).isSuccess());
        System.Assert.isFalse(results.get(1).isSuccess());
        List<Log__c> persistedLogs = [SELECT Id, IsDeleted FROM Log__c WHERE Id IN :logsToUndelete ALL ROWS];
        System.Assert.areEqual(logsToUndelete.size(), persistedLogs.size());
        for (Log__c persistedLog : persistedLogs) {
            System.Assert.isFalse(persistedLog.IsDeleted);
        }
    }

    @IsTest
    static void it_should_update_record() {
        String originalScenario = 'Some scenario';
        String updatedScenario = 'Another, different scenario';
        List<Log__c> logsToUpdate = new List<Log__c>();
        logsToUpdate.add((Log__c) LoggerMockDataCreator.createDataBuilder(new Log__c(Scenario__c = originalScenario)).populateRequiredFields().getRecord());
        logsToUpdate.add((Log__c) LoggerMockDataCreator.createDataBuilder(new Log__c(Scenario__c = originalScenario)).populateRequiredFields().getRecord());
        insert logsToUpdate;
        logsToUpdate = [SELECT Id, Scenario__c FROM Log__c WHERE Id IN :logsToUpdate];
        for (Log__c logToUpdate : logsToUpdate) {
            System.Assert.areEqual(originalScenario, logToUpdate.Scenario__c);
            logToUpdate.Scenario__c = updatedScenario;
        }
        System.Assert.areEqual(1, System.Limits.getDmlStatements());
        System.Assert.areEqual(2, System.Limits.getDmlRows());

        List<Database.SaveResult> results = LoggerDataStore.getDatabase().updateRecords(logsToUpdate);

        System.Assert.areEqual(2, System.Limits.getDmlStatements());
        System.Assert.areEqual(4, System.Limits.getDmlRows());
        System.Assert.areEqual(logsToUpdate.size(), results.size());
        for (Database.SaveResult result : results) {
            System.Assert.isTrue(result.isSuccess());
        }
        List<Log__c> persistedLogs = [SELECT Id, Scenario__c FROM Log__c WHERE Id IN :logsToUpdate ALL ROWS];
        System.Assert.areEqual(logsToUpdate.size(), persistedLogs.size());
        for (Log__c persistedLog : persistedLogs) {
            System.Assert.areEqual(updatedScenario, persistedLog.Scenario__c);
        }
    }

    @IsTest
    static void it_should_update_record_list() {
        String originalScenario = 'Some scenario';
        String updatedScenario = 'Another, different scenario';
        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        log.Scenario__c = originalScenario;
        insert log;
        log = [SELECT Id, Scenario__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(originalScenario, log.Scenario__c);
        log.Scenario__c = updatedScenario;
        System.Assert.areEqual(1, System.Limits.getDmlStatements());
        System.Assert.areEqual(1, System.Limits.getDmlRows());

        Database.SaveResult result = LoggerDataStore.getDatabase().updateRecord(log);

        System.Assert.areEqual(2, System.Limits.getDmlStatements());
        System.Assert.areEqual(2, System.Limits.getDmlRows());
        System.Assert.isTrue(result.isSuccess());
        Log__c persistedLog = [SELECT Id, Scenario__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(updatedScenario, persistedLog.Scenario__c);
    }

    @IsTest
    static void it_should_partially_update_record_list_when_allOrNone_is_false() {
        String originalScenario = 'Some scenario';
        String updatedScenario = 'Another, different scenario';
        List<Log__c> logsToUpdate = new List<Log__c>();
        logsToUpdate.add((Log__c) LoggerMockDataCreator.createDataBuilder(new Log__c(Scenario__c = originalScenario)).populateRequiredFields().getRecord());
        insert logsToUpdate;
        logsToUpdate.add((Log__c) LoggerMockDataCreator.createDataBuilder(new Log__c(Scenario__c = originalScenario)).populateRequiredFields().getRecord());
        for (Log__c log : logsToUpdate) {
            log.Scenario__c = updatedScenario;
        }
        System.Assert.areEqual(1, System.Limits.getDmlStatements());
        System.Assert.areEqual(1, System.Limits.getDmlRows());

        List<Database.SaveResult> results = LoggerDataStore.getDatabase().updateRecords(logsToUpdate, false);

        System.Assert.areEqual(2, System.Limits.getDmlStatements());
        System.Assert.areEqual(3, System.Limits.getDmlRows());
        System.Assert.areEqual(logsToUpdate.size(), results.size());
        System.Assert.isTrue(results.get(0).isSuccess());
        System.Assert.isFalse(results.get(1).isSuccess());
        List<Log__c> persistedLogs = [SELECT Id, Scenario__c FROM Log__c WHERE Id IN :logsToUpdate];
        System.Assert.areEqual(1, persistedLogs.size());
        System.Assert.areEqual(updatedScenario, persistedLogs.get(0).Scenario__c);
    }

    @IsTest
    static void it_should_partially_update_record_list_when_allOrNone_is_false_in_dml_options() {
        String originalScenario = 'Some scenario';
        String updatedScenario = 'Another, different scenario';
        List<Log__c> logsToUpdate = new List<Log__c>();
        logsToUpdate.add((Log__c) LoggerMockDataCreator.createDataBuilder(new Log__c(Scenario__c = originalScenario)).populateRequiredFields().getRecord());
        insert logsToUpdate;
        logsToUpdate.add((Log__c) LoggerMockDataCreator.createDataBuilder(new Log__c(Scenario__c = originalScenario)).populateRequiredFields().getRecord());
        for (Log__c log : logsToUpdate) {
            log.Scenario__c = updatedScenario;
        }
        Database.DmlOptions dmlOptions = new Database.DmlOptions();
        dmlOptions.OptAllOrNone = false;
        System.Assert.areEqual(1, System.Limits.getDmlStatements());
        System.Assert.areEqual(1, System.Limits.getDmlRows());

        List<Database.SaveResult> results = LoggerDataStore.getDatabase().updateRecords(logsToUpdate, dmlOptions);

        System.Assert.areEqual(2, System.Limits.getDmlStatements());
        System.Assert.areEqual(3, System.Limits.getDmlRows());
        System.Assert.areEqual(logsToUpdate.size(), results.size());
        System.Assert.isTrue(results.get(0).isSuccess());
        System.Assert.isFalse(results.get(1).isSuccess());
        List<Log__c> persistedLogs = [SELECT Id, Scenario__c FROM Log__c WHERE Id IN :logsToUpdate];
        System.Assert.areEqual(1, persistedLogs.size());
        System.Assert.areEqual(updatedScenario, persistedLogs.get(0).Scenario__c);
    }

    @IsTest
    static void it_should_upsert_record() {
        String originalScenario = 'Some scenario';
        String updatedScenario = 'Another, different scenario';
        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        log.Scenario__c = originalScenario;
        log.TransactionId__c = '1234';
        insert log;
        log = [SELECT Id, Scenario__c, TransactionId__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(originalScenario, log.Scenario__c);
        log.Scenario__c = updatedScenario;
        Id originalLogId = log.Id;
        log.Id = null;
        System.Assert.isNull(log.Id);
        System.Assert.isNotNull(log.TransactionId__c);
        System.Assert.areEqual(1, System.Limits.getDmlStatements());
        System.Assert.areEqual(1, System.Limits.getDmlRows());

        Database.UpsertResult result = LoggerDataStore.getDatabase().upsertRecord(log, Schema.Log__c.TransactionId__c);

        System.Assert.areEqual(2, System.Limits.getDmlStatements());
        System.Assert.areEqual(2, System.Limits.getDmlRows());
        System.Assert.isFalse(result.isCreated());
        System.Assert.isTrue(result.isSuccess());
        Log__c persistedLog = [SELECT Id, Scenario__c, TransactionId__c FROM Log__c WHERE TransactionId__c = :log.TransactionId__c];
        System.Assert.areEqual(originalLogId, persistedLog.Id);
        System.Assert.areEqual(updatedScenario, persistedLog.Scenario__c);
    }

    @IsTest
    static void it_should_upsert_record_list() {
        String originalScenario = 'Some scenario';
        String updatedScenario = 'Another, different scenario';
        List<Log__c> logsToUpsert = new List<Log__c>();
        logsToUpsert.add(
            (Log__c) LoggerMockDataCreator.createDataBuilder(new Log__c(Scenario__c = originalScenario, TransactionId__c = '1234'))
                .populateRequiredFields()
                .getRecord()
        );
        logsToUpsert.add(
            (Log__c) LoggerMockDataCreator.createDataBuilder(new Log__c(Scenario__c = originalScenario, TransactionId__c = '5678'))
                .populateRequiredFields()
                .getRecord()
        );
        insert logsToUpsert;
        logsToUpsert = [SELECT Id, Scenario__c, TransactionId__c FROM Log__c WHERE Id IN :logsToUpsert];
        for (Log__c logToUpdate : logsToUpsert) {
            System.Assert.areEqual(originalScenario, logToUpdate.Scenario__c);
            logToUpdate.Scenario__c = updatedScenario;
        }
        System.Assert.areEqual(1, System.Limits.getDmlStatements());
        System.Assert.areEqual(2, System.Limits.getDmlRows());

        List<Database.UpsertResult> results = LoggerDataStore.getDatabase().upsertRecords(logsToUpsert, Schema.Log__c.TransactionId__c);

        System.Assert.areEqual(2, System.Limits.getDmlStatements());
        System.Assert.areEqual(4, System.Limits.getDmlRows());
        System.Assert.areEqual(logsToUpsert.size(), results.size());
        for (Database.UpsertResult result : results) {
            System.Assert.isTrue(result.isSuccess());
        }
        List<Log__c> persistedLogs = [SELECT Id, Scenario__c FROM Log__c WHERE Id IN :logsToUpsert];
        System.Assert.areEqual(logsToUpsert.size(), persistedLogs.size());
        for (Log__c persistedLog : persistedLogs) {
            System.Assert.areEqual(updatedScenario, persistedLog.Scenario__c);
        }
    }

    @IsTest
    static void it_should_partially_upsert_record_list_when_allOrNone_is_false() {
        String originalScenario = 'Some scenario';
        String updatedScenario = 'Another, different scenario';
        List<Log__c> logsToUpsert = new List<Log__c>();
        logsToUpsert.add(
            (Log__c) LoggerMockDataCreator.createDataBuilder(new Log__c(Scenario__c = originalScenario, TransactionId__c = '1234'))
                .populateRequiredFields()
                .getRecord()
        );
        logsToUpsert.add(
            (Log__c) LoggerMockDataCreator.createDataBuilder(new Log__c(Scenario__c = originalScenario, TransactionId__c = '5678'))
                .populateRequiredFields()
                .getRecord()
        );
        insert logsToUpsert;
        logsToUpsert = [SELECT Id, Scenario__c, TransactionId__c FROM Log__c WHERE Id IN :logsToUpsert];
        for (Log__c logToUpdate : logsToUpsert) {
            System.Assert.areEqual(originalScenario, logToUpdate.Scenario__c);
            logToUpdate.Scenario__c = updatedScenario;
        }
        logsToUpsert.get(1).TransactionId__c = null; // This will cause an error since the upsert is on TransactionId__c
        System.Assert.areEqual(1, System.Limits.getDmlStatements());
        System.Assert.areEqual(2, System.Limits.getDmlRows());

        List<Database.UpsertResult> results = LoggerDataStore.getDatabase().upsertRecords(logsToUpsert, Schema.Log__c.TransactionId__c, false);

        System.Assert.areEqual(2, System.Limits.getDmlStatements());
        System.Assert.areEqual(4, System.Limits.getDmlRows());
        System.Assert.areEqual(logsToUpsert.size(), results.size());
        System.Assert.isTrue(results.get(0).isSuccess());
        System.Assert.isFalse(results.get(1).isSuccess());
        List<Log__c> persistedLogs = [SELECT Id, Scenario__c FROM Log__c WHERE Id IN :logsToUpsert];
        System.Assert.areEqual(2, persistedLogs.size());
        System.Assert.areEqual(updatedScenario, persistedLogs.get(0).Scenario__c);
        System.Assert.areEqual(originalScenario, persistedLogs.get(1).Scenario__c);
    }

    // Event Bus tests
    @IsTest
    static void it_should_publish_platform_event_record() {
        LogEntryEvent__e logEntryEvent = (LOgEntryEvent__e) LoggerMockDataCreator.createDataBuilder(Schema.LogEntryEvent__e.SObjectType)
            .populateRequiredFields()
            .getRecord();
        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());

        Database.SaveResult result = LoggerDataStore.getEventBus().publishRecord(logEntryEvent);

        System.Assert.areEqual(1, System.Limits.getPublishImmediateDml(), result.getErrors().toString());
        System.Assert.isTrue(result.isSuccess());
    }

    @IsTest
    static void it_should_publish_platform_event_record_list() {
        List<LogEntryEvent__e> logEntryEventsToPublish = new List<LogEntryEvent__e>();
        logEntryEventsToPublish.add(
            (LogEntryEvent__e) LoggerMockDataCreator.createDataBuilder(Schema.LogEntryEvent__e.SObjectType).populateRequiredFields().getRecord()
        );
        logEntryEventsToPublish.add(
            (LogEntryEvent__e) LoggerMockDataCreator.createDataBuilder(Schema.LogEntryEvent__e.SObjectType).populateRequiredFields().getRecord()
        );
        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());

        List<Database.SaveResult> results = LoggerDataStore.getEventBus().publishRecords(logEntryEventsToPublish);

        System.Assert.areEqual(1, System.Limits.getPublishImmediateDml(), results.toString());
        System.Assert.areEqual(logEntryEventsToPublish.size(), results.size());
        for (Database.SaveResult result : results) {
            System.Assert.isTrue(result.isSuccess());
        }
    }

    // Queueable tests
    @IsTest
    static void it_should_enqueue_job() {
        System.Assert.areEqual(0, System.Limits.getQueueableJobs());

        LoggerDataStore.getJobQueue().enqueueJob(new MockQueueable());

        System.Assert.areEqual(1, System.Limits.getQueueableJobs());
    }

    // Mocking tests
    @IsTest
    static void it_should_support_overriding_database_instance() {
        MockDatabase mockDatabaseInstance = new MockDatabase();
        System.Assert.areEqual(0, mockDatabaseInstance.callCount);
        LoggerDataStore.setMock(mockDatabaseInstance);
        System.Assert.areEqual(mockDatabaseInstance, LoggerDataStore.getDatabase());

        LoggerDataStore.getDatabase().updateRecord(new User(Id = System.UserInfo.getUserId()));

        System.Assert.areEqual(1, mockDatabaseInstance.callCount);
    }

    @IsTest
    static void it_should_support_overriding_event_bus_instance() {
        MockEventBus mockEventBusInstance = new MockEventBus();
        System.Assert.areEqual(0, mockEventBusInstance.callCount);
        LoggerDataStore.setMock(mockEventBusInstance);
        System.Assert.areEqual(mockEventBusInstance, LoggerDataStore.getEventBus());

        LoggerDataStore.getEventBus().publishRecord(new User()); // Not an actual platform event, but for mocking/test purposes, User is fine

        System.Assert.areEqual(1, mockEventBusInstance.callCount);
    }

    @IsTest
    static void it_should_support_overriding_job_queue_instance() {
        MockJobQueue mockJobQueueInstance = new MockJobQueue();
        System.Assert.areEqual(0, mockJobQueueInstance.callCount);
        LoggerDataStore.setMock(mockJobQueueInstance);
        System.Assert.areEqual(mockJobQueueInstance, LoggerDataStore.getJobQueue());

        LoggerDataStore.getJobQueue().enqueueJob(new MockQueueable());

        System.Assert.areEqual(1, mockJobQueueInstance.callCount);
    }

    private class MockDatabase extends LoggerDataStore.Database {
        public Integer callCount = 0;

        public override Database.SaveResult updateRecord(SObject record) {
            this.callCount++;
            return LoggerMockDataCreator.createDatabaseSaveResult(true, record.Id);
        }
    }

    private class MockEventBus extends LoggerDataStore.EventBus {
        public Integer callCount = 0;

        public override Database.SaveResult publishRecord(SObject platformEvent) {
            this.callCount++;
            return LoggerMockDataCreator.createDatabaseSaveResult(true, platformEvent.Id);
        }
    }

    private class MockJobQueue extends LoggerDataStore.JobQueue {
        public Integer callCount = 0;

        public override Id enqueueJob(Queueable queueableJob) {
            this.callCount++;
            return LoggerMockDataCreator.createId(Schema.AsyncApexJob.SObjectType);
        }
    }

    private class MockQueueable implements Queueable {
        public Integer callCount = 0;
        public void execute(System.QueueableContext queueableContext) {
            this.callCount++;
        }
    }
}
