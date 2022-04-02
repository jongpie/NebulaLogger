@IsTest
private class LoggerDataStore_Tests {
    // Database DML tests
    @IsTest
    static void it_should_delete_record() {
        Log__c log = (Log__c) LoggerMockCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        insert log;

        Database.DeleteResult result = LoggerDataStore.getDatabase().deleteRecord(log);

        System.assertEquals(true, result.isSuccess());
        Log__c persistedLog = [SELECT Id, IsDeleted FROM Log__c WHERE Id = :log.Id ALL ROWS];
        System.assertEquals(true, persistedLog.IsDeleted);
    }

    @IsTest
    static void it_should_hard_delete_record() {
        Log__c log = (Log__c) LoggerMockCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        log.TransactionId__c = '999';
        insert log;

        Database.DeleteResult result = LoggerDataStore.getDatabase().hardDeleteRecord(log);

        System.assertEquals(true, result.isSuccess());
        // Frustratingly, there's not a way to ensure that Database.emptyRecycleBin() was called and
        // the supposedly-hard-deleted records are still returned in SOQL, so at least verify that the
        // record has IsDeleted = true for now. This can probably be tested better with a @TestVisible property later.
        Log__c persistedLog = [SELECT Id, IsDeleted FROM Log__c WHERE Id = :log.Id ALL ROWS];
        System.assertEquals(true, persistedLog.IsDeleted);
    }

    @IsTest
    static void it_should_insert_record() {
        Log__c log = (Log__c) LoggerMockCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        System.assertEquals(null, log.Id);
        log.TransactionId__c = '1234';

        Database.SaveResult result = LoggerDataStore.getDatabase().insertRecord(log);

        System.assertNotEquals(null, log.Id);
        System.assertEquals(true, result.isSuccess());
        Log__c persistedLog = [SELECT Id, TransactionId__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(log.TransactionId__c, persistedLog.TransactionId__c);
    }

    @IsTest
    static void it_should_undelete_record() {
        Log__c log = (Log__c) LoggerMockCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        insert log;
        delete log;
        log = [SELECT Id, IsDeleted FROM Log__c WHERE Id = :log.Id ALL ROWS];
        System.assertEquals(true, log.IsDeleted);

        Database.UndeleteResult result = LoggerDataStore.getDatabase().undeleteRecord(log);

        System.assertEquals(true, result.isSuccess());
        Log__c persistedLog = [SELECT Id, IsDeleted FROM Log__c WHERE Id = :log.Id ALL ROWS];
        System.assertEquals(false, persistedLog.IsDeleted);
    }

    @IsTest
    static void it_should_update_record() {
        String originalScenario = 'Some scenario';
        String updatedScenario = 'Another, different scenario';
        Log__c log = (Log__c) LoggerMockCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        log.Scenario__c = originalScenario;
        insert log;
        log = [SELECT Id, Scenario__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(originalScenario, log.Scenario__c);
        log.Scenario__c = updatedScenario;

        Database.SaveResult result = LoggerDataStore.getDatabase().updateRecord(log);

        System.assertEquals(true, result.isSuccess());
        Log__c persistedLog = [SELECT Id, Scenario__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(updatedScenario, persistedLog.Scenario__c);
    }

    @IsTest
    static void it_should_upsert_record() {
        String originalScenario = 'Some scenario';
        String updatedScenario = 'Another, different scenario';
        Log__c log = (Log__c) LoggerMockCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        log.Scenario__c = originalScenario;
        log.TransactionId__c = '1234';
        insert log;
        log = [SELECT Id, Scenario__c, TransactionId__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(originalScenario, log.Scenario__c);
        log.Scenario__c = updatedScenario;
        Id originalLogId = log.Id;
        log.Id = null;
        System.assertEquals(null, log.Id);
        System.assertNotEquals(null, log.TransactionId__c);

        Database.UpsertResult result = LoggerDataStore.getDatabase().upsertRecord(log, Schema.Log__c.TransactionId__c);

        System.assertEquals(false, result.isCreated());
        System.assertEquals(true, result.isSuccess());
        Log__c persistedLog = [SELECT Id, Scenario__c, TransactionId__c FROM Log__c WHERE TransactionId__c = :log.TransactionId__c];
        System.assertEquals(originalLogId, persistedLog.Id);
        System.assertEquals(updatedScenario, persistedLog.Scenario__c);
    }

    // Event Bus tests
    @IsTest
    static void it_should_publish_record() {
        System.assertEquals(0, Limits.getPublishImmediateDml());
        LogEntryEvent__e logEntryEvent = (LOgEntryEvent__e) LoggerMockCreator.createDataBuilder(Schema.LogEntryEvent__e.SObjectType)
            .populateRequiredFields()
            .getRecord();
        Test.startTest();

        Database.SaveResult result = LoggerDataStore.getEventBus().publishRecord(logEntryEvent);

        System.assertEquals(true, result.isSuccess());
        // TODO fix asserts for Limits.getPublishImmediateDml()
        // System.assertEquals(1, Limits.getPublishImmediateDml(), result);
        // Test.getEventBus().deliver();
        // Test.stopTest();
        // System.assertEquals(1, Limits.getDmlStatements(), result);
    }

    // Queueable tests
    @IsTest
    static void it_should_enqueue_job() {
        System.assertEquals(0, Limits.getQueueableJobs());

        LoggerDataStore.getJobQueue().enqueueJob(new MockQueueable());

        System.assertEquals(1, Limits.getQueueableJobs());
    }

    private class MockQueueable implements Queueable {
        public void execute(System.QueueableContext queueableContext) {
            System.debug('Executing mock queueable class');
        }
    }
}
