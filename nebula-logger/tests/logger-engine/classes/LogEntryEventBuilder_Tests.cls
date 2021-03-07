//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@isTest
private class LogEntryEventBuilder_Tests {
    private static Organization getOrganization() {
        return [SELECT Id, Name, InstanceName, IsSandbox, NamespacePrefix, OrganizationType, TrialExpirationDate FROM Organization];
    }

    private static String getOrganizationEnvironmentType(Organization organization) {
        String orgEnvironmentType;
        if (organization.IsSandbox == true && organization.TrialExpirationDate != null) {
            orgEnvironmentType = 'Scratch Org';
        } else if (organization.IsSandbox == true) {
            orgEnvironmentType = 'Sandbox';
        } else {
            orgEnvironmentType = 'Production';
        }
        return orgEnvironmentType;
    }

    private static SObject getNetwork() {
        if (Network.getNetworkId() == null) {
            return null;
        }

        String networkApiName = 'Network';
        // Networks (communities) may not be enabled in the org (no Network object), so run everything dynamically
        Boolean networksEnabled = Schema.getGlobalDescribe().containsKey(networkApiName);

        if (!networksEnabled) {
            return null;
        }

        String queryString = 'SELECT Id, Name, UrlPathPrefix FROM Network WHERE Id = :Network.getNetworkId()';

        return Database.query(queryString);
    }

    private static User getUser() {
        return [
            SELECT Id, Profile.Name, Profile.UserLicenseId, Profile.UserLicense.LicenseDefinitionKey, Profile.UserLicense.Name, Username, UserRole.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
    }

    @isTest
    static void it_should_short_circuit_when_not_enabled() {
        Boolean shouldSave = false;
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.DEBUG, shouldSave);

        System.assertEquals(null, builder.getLogEntryEvent());
        System.assertEquals(null, builder.setMessage('test').getLogEntryEvent());
        System.assertEquals(null, builder.setExceptionDetails(new IllegalArgumentException('test')).getLogEntryEvent());
        System.assertEquals(null, builder.setRecordId(new Account()).getLogEntryEvent());
        System.assertEquals(null, builder.setRecordId('005000000000001').getLogEntryEvent());
        System.assertEquals(null, builder.setTopics(new List<String>{ '', ' ' }).getLogEntryEvent());
    }

    @isTest
    static void it_should_short_circuit_when_enabled_logging_level_above_called_level() {
        Boolean shouldSave = false;
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.FINE, shouldSave);

        System.assertEquals(null, builder.getLogEntryEvent());
    }

    @isTest
    static void it_should_not_short_circuit_when_enabledl() {
        Boolean shouldSave = true;
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.FINE, shouldSave);

        System.assertNotEquals(null, builder.getLogEntryEvent());
    }

    @isTest
    static void it_should_set_message_fields_for_logMessage() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Message__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);

        Test.startTest();

        LogMessage logMessage = new LogMessage('The time is {0}', System.now());
        builder.setMessage(logMessage);

        Test.stopTest();

        System.assertEquals(logMessage.getMessage(), builder.getLogEntryEvent().Message__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);
    }

    @isTest
    static void it_should_set_message_fields_for_string() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Message__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);

        Test.startTest();

        String message = 'The time is ' + String.valueOf(System.now());
        builder.setMessage(message);

        Test.stopTest();

        System.assertEquals(message, builder.getLogEntryEvent().Message__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);
    }

    @isTest
    static void it_should_truncate_a_long_message() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Message__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);

        Integer messageFieldMaxLength = Schema.LogEntryEvent__e.Message__c.getDescribe().getLength();

        String randomMessage = 'The time is ' + String.valueOf(System.now());
        String longMessage = '';
        while (longMessage.length() <= messageFieldMaxLength) {
            longMessage += randomMessage;
        }
        System.assert(longMessage.length() > messageFieldMaxLength);

        Test.startTest();

        builder.setMessage(longMessage);

        Test.stopTest();

        String expectedTruncatedMessage = longMessage.left(messageFieldMaxLength);
        System.assertEquals(expectedTruncatedMessage, builder.getLogEntryEvent().Message__c);
        System.assertEquals(true, builder.getLogEntryEvent().MessageTruncated__c);
    }

    @isTest
    static void it_should_set_exception_fields_for_dmlException() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, builder.getLogEntryEvent().ExceptionType__c);

        Test.startTest();

        DmlException dmlException = new DmlException('Test DML exception');
        builder.setExceptionDetails(dmlException);

        Test.stopTest();

        System.assertEquals(dmlException.getMessage(), builder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(dmlException.getTypeName(), builder.getLogEntryEvent().ExceptionType__c);
    }

    @isTest
    static void it_should_set_dml_result_fields_for_deleteResult_without_errors() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        Database.DeleteResult deleteResult = Database.delete(log, false);
        System.assertEquals(true, deleteResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDmlResult(deleteResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals(null, logEntryEvent.DmlResultErrors__c);
        System.assertEquals(Database.DeleteResult.class.getName(), logEntryEvent.DmlResultType__c);
    }

    @isTest
    static void it_should_set_dml_result_fields_for_deleteResult_with_errors() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        // Delete the log twice to trigger a DeleteResult error
        delete log;

        Database.DeleteResult deleteResult = Database.delete(log, false);
        System.assertEquals(false, deleteResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDmlResult(deleteResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals(Json.serializePretty(deleteResult.getErrors()), logEntryEvent.DmlResultErrors__c);
        System.assertEquals(Database.DeleteResult.class.getName(), logEntryEvent.DmlResultType__c);
    }

    // TODO only some standard objects can be merged - need to find a way to either mock or trigger a merge result that works in all orgs
    // @isTest
    // static void it_should_set_dml_result_fields_for_merge_result_with_errors() {
    //     Database.MergeResult mergeResult = Database.merge(new Account(Name='Expcted'), new Account(Name='Failure'), false);
    //     System.assertEquals(false, mergeResult.isSuccess());

    //     LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

    //     Test.startTest();
    //     builder.setDmlResult(mergeResult);
    //     Test.stopTest();

    //     LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

    //     System.assertEquals(Json.serializePretty(mergeResult.getErrors()), logEntryEvent.DmlResultErrors__c);
    //     System.assertEquals(Database.MergeResult.class.getName(), logEntryEvent.DmlResultType__c);
    // }

    @isTest
    static void it_should_set_dml_result_fields_for_successful_saveResult() {
        Database.SaveResult saveResult = Database.insert(new Log__c(TransactionId__c = '1234'), false);
        System.assertEquals(true, saveResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDmlResult(saveResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals(null, logEntryEvent.DmlResultErrors__c);
        System.assertEquals(Database.SaveResult.class.getName(), logEntryEvent.DmlResultType__c);
    }

    @isTest
    static void it_should_set_dml_result_fields_for_failed_saveResult() {
        Database.SaveResult saveResult = Database.insert(new Account(), false);
        System.assertEquals(false, saveResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDmlResult(saveResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals(Json.serializePretty(saveResult.getErrors()), logEntryEvent.DmlResultErrors__c);
        System.assertEquals(Database.SaveResult.class.getName(), logEntryEvent.DmlResultType__c);
    }

    @isTest
    static void it_should_set_dml_result_fields_for_successful_undeleteResult() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        delete log;

        Database.UndeleteResult undeleteResult = Database.undelete(log.Id, false);
        System.assertEquals(true, undeleteResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDmlResult(undeleteResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals(null, logEntryEvent.DmlResultErrors__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), logEntryEvent.DmlResultType__c);
    }

    @isTest
    static void it_should_set_dml_result_fields_for_failed_undeleteResult() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        delete log;
        // Hard delete to (later) cause an undelete error
        Database.emptyRecycleBin(log);

        Database.UndeleteResult undeleteResult = Database.undelete(log.Id, false);
        System.assertEquals(false, undeleteResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDmlResult(undeleteResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals(Json.serializePretty(undeleteResult.getErrors()), logEntryEvent.DmlResultErrors__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), logEntryEvent.DmlResultType__c);
    }

    @isTest
    static void it_should_set_dml_result_fields_for_successful_upsertResult_when_insert() {
        // UpsertResult for a new record insert
        Database.UpsertResult upsertResult = Database.upsert(new Log__c(TransactionId__c = '1234'), false);
        System.assertEquals(true, upsertResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDmlResult(upsertResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals(null, logEntryEvent.DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', logEntryEvent.DmlResultType__c);
    }

    @isTest
    static void it_should_set_dml_result_fields_for_failed_upsertResult_when_insert() {
        // UpsertResult for a new record insert
        Database.UpsertResult upsertResult = Database.upsert(new Account(), false);
        System.assertEquals(false, upsertResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDmlResult(upsertResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals(Json.serializePretty(upsertResult.getErrors()), logEntryEvent.DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', logEntryEvent.DmlResultType__c);
    }

    @isTest
    static void it_should_set_dml_result_fields_for_successful_upsertResult_when_update() {
        // UpsertResult for an existing record update
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        log.TransactionId__c = '9876';

        Database.UpsertResult upsertResult = Database.upsert(log, false);
        System.assertEquals(true, upsertResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDmlResult(upsertResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals(null, logEntryEvent.DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', logEntryEvent.DmlResultType__c);
    }

    @isTest
    static void it_should_set_dml_result_fields_for_failed_upsertResult_when_update() {
        // UpsertResult for an existing record update
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        // Use a log entry this time to handle the upsert scenario
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, Name = 'Test Log Entry');
        insert logEntry;

        // Set name field to a value too long for the field
        Integer maxFieldLength = Schema.LogEntry__c.Name.getDescribe().getLength();
        logEntry.Name = '0'.repeat(maxFieldLength + 10);

        Database.UpsertResult upsertResult = Database.upsert(logEntry, false);
        System.assertEquals(false, upsertResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        Test.startTest();
        builder.setDmlResult(upsertResult);
        Test.stopTest();

        LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

        System.assertEquals(Json.serializePretty(upsertResult.getErrors()), logEntryEvent.DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', logEntryEvent.DmlResultType__c);
    }

    @isTest
    static void it_should_set_record_fields_for_recordId_when_standard_object() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Test.startTest();

        Id currentUserId = UserInfo.getUserId();
        builder.setRecordId(currentUserId);

        Test.stopTest();

        System.assertEquals(currentUserId, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Standard Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals('User', builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);
    }

    @isTest
    static void it_should_set_record_fields_for_recordId_when_custom_object() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Test.startTest();

        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        builder.setRecordId(log.Id);

        Test.stopTest();

        System.assertEquals(log.Id, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Custom Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(Log__c.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @isTest
    static void it_should_set_record_fields_for_recordId_when_custom_metadata_type() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Test.startTest();

        LogStatus__mdt status = [SELECT Id, MasterLabel, DeveloperName FROM LogStatus__mdt LIMIT 1];
        builder.setRecordId(status.Id);

        Test.stopTest();

        System.assertEquals(status.Id, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Custom Metadata Type Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(LogStatus__mdt.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @isTest
    static void it_should_set_record_fields_for_record_when_standard_object() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Test.startTest();

        User currentUser = [SELECT Id, Name, ProfileId, Profile.Name, IsActive FROM User WHERE Id = :UserInfo.getUserId()];
        builder.setRecordId(currentUser);

        Test.stopTest();

        System.assertEquals(currentUser.Id, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(currentUser), builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Standard Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals('User', builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);
    }

    @isTest
    static void it_should_set_record_fields_for_record_when_custom_object() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Test.startTest();

        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        builder.setRecordId(log);

        Test.stopTest();

        System.assertEquals(log.Id, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(log), builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Custom Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(Log__c.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @isTest
    static void it_should_set_record_fields_for_record_when_custom_metadata_type() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Test.startTest();

        LogStatus__mdt status = [SELECT Id, MasterLabel, DeveloperName FROM LogStatus__mdt LIMIT 1];
        builder.setRecordId(status);

        Test.stopTest();

        System.assertEquals(status.Id, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(status), builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Custom Metadata Type Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(LogStatus__mdt.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @isTest
    static void it_should_set_topics_string_for_list_of_topics() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Topics__c);

        Test.startTest();

        List<String> topics = new List<String>{ 'some-topic', 'another One', 'here\'s one more!' };
        builder.setTopics(topics);

        Test.stopTest();

        String expectedTopicsString = String.escapeSingleQuotes(String.join(topics, ','));
        System.assertEquals(expectedTopicsString, builder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_deduplicate_topics() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Topics__c);

        Test.startTest();

        List<String> topics = new List<String>{ 'duplicate-topic', 'duplicate-topic', 'another One' };
        builder.setTopics(topics);

        Test.stopTest();

        String expectedTopicsString = 'duplicate-topic,another One';
        System.assertEquals(expectedTopicsString, builder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_set_stack_trace_and_origin_location_for_stack_trace_string() {
        DmlException stackTraceHandler = new DmlException();

        Boolean shouldSave = true;
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.FINE, shouldSave);
        builder.getLogEntryEvent().OriginLocation__c = null;
        builder.getLogEntryEvent().StackTrace__c = null;

        Test.startTest();
        builder.parseStackTrace(stackTraceHandler.getStackTraceString());
        Test.stopTest();

        String expectedOriginLocation = stackTraceHandler.getStackTraceString().split('\n').get(0).substringBefore(':').substringAfter('Class.');
        String expectedStackTrace = stackTraceHandler.getStackTraceString();

        System.assertNotEquals(null, builder.getLogEntryEvent().OriginLocation__c);
        System.assertEquals(expectedOriginLocation, builder.getLogEntryEvent().OriginLocation__c);
        System.assertNotEquals(null, builder.getLogEntryEvent().StackTrace__c);
        System.assertEquals(expectedStackTrace, builder.getLogEntryEvent().StackTrace__c);
    }

    @isTest
    static void it_should_not_set_stack_trace_and_origin_location_for_invalid_stack_trace_string() {
        final String invalidStackTrace = '()';

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        // Clear out any auto-set values
        builder.getLogEntryEvent().OriginLocation__c = null;
        builder.getLogEntryEvent().StackTrace__c = null;

        Test.startTest();
        builder.parseStackTrace(invalidStackTrace);
        Test.stopTest();

        System.assertEquals(null, builder.getLogEntryEvent().OriginLocation__c);
        System.assertEquals(null, builder.getLogEntryEvent().StackTrace__c);
    }

    @isTest
    static void it_should_return_value_of_shouldSave_when_true() {
        Test.startTest();
        Boolean shouldSave = true;
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, shouldSave);
        Test.stopTest();

        System.assertEquals(shouldSave, builder.shouldSave());
    }

    @isTest
    static void it_should_return_value_of_shouldSave_when_false() {
        Test.startTest();
        Boolean shouldSave = false;
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, shouldSave);
        Test.stopTest();

        System.assertEquals(shouldSave, builder.shouldSave());
    }

    @isTest
    static void it_should_set_detailed_fields() {
        Test.startTest();
        Boolean shouldSave = true;
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, shouldSave);
        Test.stopTest();

        // Get expected data
        Organization organization = getOrganization();
        String organizationEnvironmentType = getOrganizationEnvironmentType(organization);
        SObject networkSite = getNetwork();
        User user = getUser();

        // Verify organization fields
        System.assertEquals(Url.getOrgDomainUrl().toExternalForm(), builder.getLogEntryEvent().OrganizationDomainUrl__c);
        System.assertEquals(organizationEnvironmentType, builder.getLogEntryEvent().OrganizationEnvironmentType__c);
        System.assertEquals(organization.Id, builder.getLogEntryEvent().OrganizationId__c);
        System.assertEquals(organization.InstanceName, builder.getLogEntryEvent().OrganizationInstanceName__c);
        System.assertEquals(organization.Name, builder.getLogEntryEvent().OrganizationName__c);
        System.assertEquals(organization.NamespacePrefix, builder.getLogEntryEvent().OrganizationNamespacePrefix__c);
        System.assertEquals(organization.OrganizationType, builder.getLogEntryEvent().OrganizationType__c);

        // Verify user fields
        System.assertEquals(USER.Username, builder.getLogEntryEvent().LoggedByUsername__c);
        System.assertEquals(USER.Profile.Name, builder.getLogEntryEvent().ProfileName__c);
        System.assertEquals(USER.Profile.UserLicense.LicenseDefinitionKey, builder.getLogEntryEvent().UserLicenseDefinitionKey__c);
        System.assertEquals(USER.Profile.UserLicenseId, builder.getLogEntryEvent().UserLicenseId__c);
        System.assertEquals(USER.Profile.UserLicense.Name, builder.getLogEntryEvent().UserLicenseName__c);
        System.assertEquals(USER.UserRole?.Name, builder.getLogEntryEvent().UserRoleName__c);
    }
}
