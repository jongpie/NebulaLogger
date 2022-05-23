//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerEngineDataSelector_Tests {
    @IsTest
    static void it_returns_cached_auth_session() {
        // AuthSession is always null in a test context, which makes this object/method more difficult to test
        AuthSession expectedAuthSession = null;
        System.assertEquals(0, Limits.getQueries());

        AuthSession returnedAuthSession = LoggerEngineDataSelector.getInstance().getCachedAuthSession();

        System.assertEquals(1, Limits.getQueries());
        LoggerEngineDataSelector.getInstance().getCachedAuthSession();
        System.assertEquals(1, Limits.getQueries(), 'Query results should have been cached');
        System.assertEquals(expectedAuthSession, returnedAuthSession);
    }

    @IsTest
    static void it_returns_cached_sobject_handlers() {
        List<LoggerSObjectHandler__mdt> expectedSObjectHandlers = [
            SELECT IsEnabled__c, SObjectHandlerApexClass__c, SObjectType__r.QualifiedApiName, SObjectTypeOverride__c
            FROM LoggerSObjectHandler__mdt
            WHERE IsEnabled__c = TRUE
        ];
        System.assertEquals(0, Limits.getQueries());

        List<LoggerSObjectHandler__mdt> returnedSObjectHandlers = LoggerEngineDataSelector.getInstance().getCachedLoggerSObjectHandlers();

        // The specific query used for LoggerSObjectHandler__mdt shouldn't count towards the SOQL query limits,
        // so 0 queries are expected here
        System.assertEquals(0, Limits.getQueries());
        LoggerEngineDataSelector.getInstance().getCachedLoggerSObjectHandlers();
        System.assertEquals(0, Limits.getQueries(), 'Query results should have been cached');
        System.assertEquals(expectedSObjectHandlers, returnedSObjectHandlers);
    }

    @IsTest
    static void it_returns_cached_network() {
        // By default, the current user (in the pipeline's scratch org) will not have a Network ID
        // TODO create an integration test class that verifies the actual Network is returned when the user is associated with the site
        Id expectedNetworkId = Network.getNetworkId();
        System.assertEquals(0, Limits.getQueries());
        Integer expectedQueryCount = expectedNetworkId == null ? 0 : 1;

        SObject returnedNetworkSite = LoggerEngineDataSelector.getInstance().getCachedNetwork();

        System.assertEquals(expectedQueryCount, Limits.getQueries());
        LoggerEngineDataSelector.getInstance().getCachedNetwork();
        System.assertEquals(expectedQueryCount, Limits.getQueries(), 'Query results should have been cached');
        System.assertEquals(expectedNetworkId, returnedNetworkSite?.Id);
    }

    @IsTest
    static void it_returns_cached_organization() {
        Organization expectedOrganization = [
            SELECT Id, InstanceName, IsSandbox, Name, NamespacePrefix, OrganizationType, TrialExpirationDate
            FROM Organization
        ];
        System.assertEquals(1, Limits.getQueries());

        Organization returnedOrganization = LoggerEngineDataSelector.getInstance().getCachedOrganization();

        System.assertEquals(2, Limits.getQueries());
        LoggerEngineDataSelector.getInstance().getCachedOrganization();
        System.assertEquals(2, Limits.getQueries(), 'Query results should have been cached');
        System.assertEquals(expectedOrganization, returnedOrganization);
    }

    @IsTest
    static void it_returns_cached_tag_assignment_rules() {
        List<LogEntryTagRule__mdt> expectedTagAssignmentRules = [
            SELECT Id, SObjectField__r.QualifiedApiName, ComparisonType__c, ComparisonValue__c, Tags__c
            FROM LogEntryTagRule__mdt
            WHERE IsEnabled__c = TRUE AND SObjectType__r.DeveloperName = 'LogEntry'
        ];
        System.assertEquals(1, Limits.getQueries());

        List<LogEntryTagRule__mdt> returnedTagAssignmentRules = LoggerEngineDataSelector.getInstance().getCachedTagAssignmentRules();

        System.assertEquals(2, Limits.getQueries());
        LoggerEngineDataSelector.getInstance().getCachedTagAssignmentRules();
        System.assertEquals(2, Limits.getQueries(), 'Query results should have been cached');
        System.assertEquals(expectedTagAssignmentRules, returnedTagAssignmentRules);
    }

    @IsTest
    static void it_returns_cached_user() {
        User expectedUser = [
            SELECT Id, Profile.Name, Profile.UserLicenseId, Profile.UserLicense.LicenseDefinitionKey, Profile.UserLicense.Name, Username, UserRole.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
        System.assertEquals(1, Limits.getQueries());

        User returnedUser = LoggerEngineDataSelector.getInstance().getCachedUser();

        System.assertEquals(2, Limits.getQueries());
        LoggerEngineDataSelector.getInstance().getCachedUser();
        System.assertEquals(2, Limits.getQueries(), 'Query results should have been cached');
        System.assertEquals(expectedUser, returnedUser);
    }
}
