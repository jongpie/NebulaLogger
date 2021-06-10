//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@isTest
private class LogEntryHandler_Tests {

    public class LogEntryPostProcessorTest implements LoggerSObjectPostProcessor {
        public void execute(TriggerOperation triggerOperationType, List<SObject> logs, Map<Id, SObject> oldLogsById) {
            if (triggerOperationType == TriggerOperation.BEFORE_INSERT) {
                for (LogEntry__c logEntry : (List<LogEntry__c>) logs) {
                    // The specific field changed doesn't really matter - we just want to ensure that whatever...
                    // ...logic implement in the instance of LoggerSObjectPostProcessor is executed
                    logEntry.Message__c = 'Some String';
                }
            }
        }
    }

    private static LoggerSObjectHandlerConfiguration__mdt getMockConfiguration() {
        Schema.SObjectType sobjectType = Schema.LogEntry__c.SObjectType;
        return new LoggerSObjectHandlerConfiguration__mdt(IsEnabled__c = true, SObjectType__c = sobjectType.getDescribe().getName());
    }

    @testSetup
    static void setupData() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        Test.setCreatedDate(log.Id, System.now().addDays(-8));
    }

    @isTest
    static void it_should_return_the_logEntry_sobjectType() {
        Test.startTest();
        System.assertEquals(Schema.LogEntry__c.SObjectType, new LogEntryHandler().getSObjectType());
        Test.stopTest();
    }

    @isTest
    static void it_should_load_a_default_config_when_no_config_present() {
        String currentUserJson = JSON.serialize(new User(Id = UserInfo.getUserId()));

        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordJson__c = currentUserJson);

        Test.startTest();

        // Clear any CMDT records that have been loaded from the database
        LoggerSObjectHandler.configurationsBySObjectType.clear();
        LoggerSObjectHandlerConfiguration__mdt configuration = LoggerSObjectHandler.configurationsBySObjectType.get(Schema.LogEntry__c.SObjectType);
        System.assertEquals(null, configuration);

        insert logEntry;

        // Verify that a default config has been loaded w/ IsEnabled__c = true
        configuration = LoggerSObjectHandler.configurationsBySObjectType.get(Schema.LogEntry__c.SObjectType);
        System.assertNotEquals(null, configuration);
        System.assertEquals(null, configuration.Id);
        System.assertEquals(true, configuration.IsEnabled__c);

        Test.stopTest();

        // Assumption: the default config should have been loaded with IsEnabled__c = true, resulting in logEntry.HasRecordJson__c should have been auto-set to true...
        // ...so if it's still false, it indicates that the handler did not execute
        logEntry = [SELECT Id, HasRecordJson__c, RecordJson__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertNotEquals(null, logEntry.RecordJson__c);
        System.assertEquals(true, logEntry.HasRecordJson__c);
    }

    @isTest
    static void it_should_not_run_handler_when_disabled_via_configuration() {
        String currentUserJson = JSON.serialize(new User(Id = UserInfo.getUserId()));

        LoggerSObjectHandlerConfiguration__mdt logEntryHandlerConfiguration = getMockConfiguration();
        logEntryHandlerConfiguration.IsEnabled__c = false;

        Map<SObjectType, LoggerSObjectHandlerConfiguration__mdt> configurationsBySObjectType = new Map<SObjectType, LoggerSObjectHandlerConfiguration__mdt>{
            Schema.LogEntry__c.SObjectType => logEntryHandlerConfiguration
        };

        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordJson__c = currentUserJson);

        Test.startTest();

        // Use the mock configurations
        LoggerSObjectHandler.configurationsBySObjectType = configurationsBySObjectType;

        insert logEntry;

        Test.stopTest();

        // Assumption: if the handler had executed, then logEntry.HasRecordJson__c should have been auto-set to true...
        // ...so if it's still false, it indicates that the handler did not execute
        logEntry = [SELECT Id, HasRecordJson__c, RecordJson__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertNotEquals(null, logEntry.RecordJson__c);
        System.assertEquals(false, logEntry.HasRecordJson__c);
    }

    @isTest
    static void it_should_save_log_entry_without_related_record_id() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = null);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [SELECT Id, RecordId__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(null, logEntry.RecordId__c);
    }

    @isTest
    static void it_should_populate_related_record_fields_on_log_entry_with_related_user_record_id() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        User currentUser = [SELECT Id, Username FROM User WHERE Id = :UserInfo.getUserId()];

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = currentUser.Id);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [SELECT Id, RecordId__c, RecordName__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(currentUser.Id, logEntry.RecordId__c);
        System.assertEquals(currentUser.Username, logEntry.RecordName__c);
    }

    @isTest
    static void it_should_populate_related_record_fields_on_log_entry_with_related_profile_record_id() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        Profile currentProfile = [SELECT Id, Name, Description FROM Profile WHERE Id = :UserInfo.getProfileId()];

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = currentProfile.Id);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [SELECT Id, RecordId__c, RecordName__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(currentProfile.Id, logEntry.RecordId__c);
        System.assertEquals(currentProfile.Name, logEntry.RecordName__c);
    }

    @isTest
    static void it_should_set_hasRecordJson_to_true_when_populated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        String recordJson = '{}';
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordJson__c = recordJson);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [SELECT Id, HasRecordJson__c, RecordJson__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(logEntry.HasRecordJson__c);
        System.assertEquals(recordJson, logEntry.RecordJson__c);
    }

    @isTest
    static void it_should_set_hasRecordJson_to_true_when_updated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordJson__c = null);
        insert logEntry;
        logEntry = [SELECT Id, RecordJson__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(null, logEntry.RecordJson__c);

        Test.startTest();

        String recordJson = '{}';
        logEntry.RecordJson__c = recordJson;
        update logEntry;

        Test.stopTest();

        logEntry = [SELECT Id, HasRecordJson__c, RecordJson__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(logEntry.HasRecordJson__c);
        System.assertEquals(recordJson, logEntry.RecordJson__c);
    }

    @isTest
    static void it_should_set_hasExceptionStackTrace_to_false_when_null() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, ExceptionStackTrace__c = null);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [SELECT Id, HasExceptionStackTrace__c, ExceptionStackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(!logEntry.HasExceptionStackTrace__c);
        System.assertEquals(null, logEntry.ExceptionStackTrace__c);
    }

    @isTest
    static void it_should_set_hasExceptionStackTrace_to_true_when_populated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        String stackTrace = 'something';
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, ExceptionStackTrace__c = stackTrace);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [SELECT Id, HasExceptionStackTrace__c, ExceptionStackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(logEntry.HasExceptionStackTrace__c);
        System.assertEquals(stackTrace, logEntry.ExceptionStackTrace__c);
    }

    @isTest
    static void it_should_set_hasExceptionStackTrace_to_true_when_updated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, ExceptionStackTrace__c = null);
        insert logEntry;
        logEntry = [SELECT Id, ExceptionStackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(null, logEntry.ExceptionStackTrace__c);

        Test.startTest();

        String stackTrace = 'something';
        logEntry.ExceptionStackTrace__c = stackTrace;
        update logEntry;

        Test.stopTest();

        logEntry = [SELECT Id, HasExceptionStackTrace__c, ExceptionStackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(logEntry.HasExceptionStackTrace__c);
        System.assertEquals(stackTrace, logEntry.ExceptionStackTrace__c);
    }

    @isTest
    static void it_should_set_hasStackTrace_to_false_when_null() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, StackTrace__c = null);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [SELECT Id, HasStackTrace__c, StackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(!logEntry.HasStackTrace__c);
        System.assertEquals(null, logEntry.StackTrace__c);
    }

    @isTest
    static void it_should_set_hasStackTrace_to_true_when_populated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        String stackTrace = 'something';
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, StackTrace__c = stackTrace);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [SELECT Id, HasStackTrace__c, StackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(logEntry.HasStackTrace__c);
        System.assertEquals(stackTrace, logEntry.StackTrace__c);
    }

    @isTest
    static void it_should_set_hasStackTrace_to_true_when_updated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, StackTrace__c = null);
        insert logEntry;
        logEntry = [SELECT Id, StackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(null, logEntry.StackTrace__c);

        Test.startTest();

        String stackTrace = 'something';
        logEntry.StackTrace__c = stackTrace;
        update logEntry;

        Test.stopTest();

        logEntry = [SELECT Id, HasStackTrace__c, StackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(logEntry.HasStackTrace__c);
        System.assertEquals(stackTrace, logEntry.StackTrace__c);
    }

    @isTest
    static void it_should_run_apex_post_processor_when_configured() {
        String expectedMessage = 'Some String';

        LoggerSObjectPostProcessor__mdt postProcessor = new LoggerSObjectPostProcessor__mdt(
            PostProcessorType__c = 'Apex',
            PostProcessorApiName__c = LogEntryPostProcessorTest.class.getName()
        );
        Map<SObjectType, List<LoggerSObjectPostProcessor__mdt>> postProcessorsBySObjectType = new Map<SObjectType, List<LoggerSObjectPostProcessor__mdt>>{
            Schema.LogEntry__c.SObjectType => new List<LoggerSObjectPostProcessor__mdt>{ postProcessor }
        };

        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        Test.startTest();

        // Use the mock configurations
        LoggerSObjectHandler.postProcessorsBySObjectType = postProcessorsBySObjectType;

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, Message__c = 'qwerty');
        insert logEntry;

        logEntry = [SELECT Id, Message__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(expectedMessage, logEntry.Message__c);

        Test.stopTest();
    }
}
