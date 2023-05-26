//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerEngineDataSelector_Tests {
    @IsTest
    static void it_loads_mock_instance() {
        MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
        System.Assert.areNotEqual(mockSelector, LoggerEngineDataSelector.getInstance());

        LoggerEngineDataSelector.setMock(mockSelector);

        System.Assert.areEqual(mockSelector, LoggerEngineDataSelector.getInstance());
    }

    @IsTest
    static void it_returns_cached_auth_session_proxy() {
        List<AuthSession> sessions = [
            SELECT
                Id,
                LoginType,
                LoginHistoryId,
                LoginHistory.Application,
                LoginHistory.Browser,
                LoginHistory.Platform,
                LogoutUrl,
                SessionSecurityLevel,
                SessionType,
                SourceIp
            FROM AuthSession
            WHERE UsersId = :System.UserInfo.getUserId() AND IsCurrent = TRUE AND ParentId = NULL
        ];
        LoggerSObjectProxy.AuthSession expectedAuthSessionProxy = sessions.isEmpty() ? null : new LoggerSObjectProxy.AuthSession(sessions.get(0));
        System.Assert.areEqual(1, System.Limits.getQueries());

        LoggerSObjectProxy.AuthSession returnedAuthSessionProxy = LoggerEngineDataSelector.getInstance().getCachedAuthSessionProxy();

        System.Assert.areEqual(2, System.Limits.getQueries());
        LoggerEngineDataSelector.getInstance().getCachedAuthSessionProxy();
        System.Assert.areEqual(2, System.Limits.getQueries(), 'Query results should have been cached');
        System.Assert.areEqual(expectedAuthSessionProxy, returnedAuthSessionProxy);
    }

    @IsTest
    static void it_returns_null_when_querying_auth_session_is_disabled() {
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryAuthSessionData', Value__c = String.valueOf(false)));
        System.Assert.isFalse(LoggerParameter.QUERY_AUTH_SESSION_DATA);

        LoggerSObjectProxy.AuthSession returnedAuthSessionProxy = LoggerEngineDataSelector.getInstance().getCachedAuthSessionProxy();

        System.Assert.areEqual(0, System.Limits.getQueries());
        System.Assert.isNull(returnedAuthSessionProxy);
    }

    @IsTest
    static void it_does_not_query_auth_session_when_disabled_via_logger_parameter() {
        MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
        LoggerEngineDataSelector.setMock(mockSelector);
        System.Assert.areEqual(mockSelector, LoggerEngineDataSelector.getInstance());
        System.Assert.areEqual(0, mockSelector.getCachedAuthSessionQueryCount());
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryAuthSessionData', Value__c = String.valueOf(false)));

        LoggerSObjectProxy.AuthSession returnedAuthSessionProxy = LoggerEngineDataSelector.getInstance().getCachedAuthSessionProxy();

        System.Assert.areEqual(0, mockSelector.getCachedAuthSessionQueryCount());
        System.Assert.isNull(returnedAuthSessionProxy);
    }

    @IsTest
    static void it_returns_cached_sobject_handlers() {
        List<LoggerSObjectHandler__mdt> expectedSObjectHandlers = [
            SELECT IsEnabled__c, SObjectHandlerApexClass__c, SObjectType__r.QualifiedApiName, SObjectTypeOverride__c
            FROM LoggerSObjectHandler__mdt
            WHERE IsEnabled__c = TRUE
        ];
        System.Assert.areEqual(0, System.Limits.getQueries());

        List<LoggerSObjectHandler__mdt> returnedSObjectHandlers = LoggerEngineDataSelector.getInstance().getCachedLoggerSObjectHandlers();

        // The specific query used for LoggerSObjectHandler__mdt shouldn't count towards the SOQL query limits,
        // so 0 queries are expected here
        System.Assert.areEqual(0, System.Limits.getQueries());
        LoggerEngineDataSelector.getInstance().getCachedLoggerSObjectHandlers();
        System.Assert.areEqual(0, System.Limits.getQueries(), 'Query results should have been cached');
        System.Assert.areEqual(expectedSObjectHandlers, returnedSObjectHandlers);
    }

    @IsTest
    static void it_returns_cached_organization() {
        Organization expectedOrganization = [
            SELECT
                Id,
                CreatedById,
                CreatedBy.Name,
                CreatedBy.Username,
                CreatedDate,
                InstanceName,
                IsSandbox,
                Name,
                NamespacePrefix,
                OrganizationType,
                TrialExpirationDate
            FROM Organization
        ];
        MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
        LoggerEngineDataSelector.setMock(mockSelector);
        System.Assert.areEqual(mockSelector, LoggerEngineDataSelector.getInstance());
        System.Assert.areEqual(0, mockSelector.getCachedOrganizationQueryCount());

        Organization returnedOrganization = LoggerEngineDataSelector.getInstance().getCachedOrganization();

        System.Assert.areEqual(1, mockSelector.getCachedOrganizationQueryCount());
        LoggerEngineDataSelector.getInstance().getCachedOrganization();
        System.Assert.areEqual(1, mockSelector.getCachedOrganizationQueryCount(), 'Query results should have been cached');
        System.Assert.areEqual(expectedOrganization, returnedOrganization);
    }

    @IsTest
    static void it_does_not_query_organization_when_disabled_via_logger_parameter() {
        MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
        System.Assert.areNotEqual(mockSelector, LoggerEngineDataSelector.getInstance());
        System.Assert.areEqual(0, mockSelector.getCachedOrganizationQueryCount());
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryOrganizationData', Value__c = String.valueOf(false)));

        Organization returnedOrganization = LoggerEngineDataSelector.getInstance().getCachedOrganization();

        System.Assert.areEqual(0, mockSelector.getCachedOrganizationQueryCount());
        System.Assert.isNull(returnedOrganization);
    }

    @IsTest
    static void it_returns_cached_tag_assignment_rules() {
        List<LogEntryTagRule__mdt> expectedTagAssignmentRules = [
            SELECT Id, SObjectField__r.QualifiedApiName, ComparisonType__c, ComparisonValue__c, Tags__c
            FROM LogEntryTagRule__mdt
            WHERE IsEnabled__c = TRUE AND SObjectType__r.DeveloperName = 'LogEntry'
        ];
        System.Assert.areEqual(1, System.Limits.getQueries());

        List<LogEntryTagRule__mdt> returnedTagAssignmentRules = LoggerEngineDataSelector.getInstance().getCachedTagAssignmentRules();

        System.Assert.areEqual(2, System.Limits.getQueries());
        LoggerEngineDataSelector.getInstance().getCachedTagAssignmentRules();
        System.Assert.areEqual(2, System.Limits.getQueries(), 'Query results should have been cached');
        System.Assert.areEqual(expectedTagAssignmentRules, returnedTagAssignmentRules);
    }

    @IsTest
    static void it_returns_cached_user() {
        User expectedUser = [
            SELECT Id, Profile.Name, Profile.UserLicenseId, Profile.UserLicense.LicenseDefinitionKey, Profile.UserLicense.Name, Username, UserRole.Name
            FROM User
            WHERE Id = :System.UserInfo.getUserId()
        ];
        System.Assert.areEqual(1, System.Limits.getQueries());

        User returnedUser = LoggerEngineDataSelector.getInstance().getCachedUser();

        System.Assert.areEqual(2, System.Limits.getQueries());
        LoggerEngineDataSelector.getInstance().getCachedUser();
        System.Assert.areEqual(2, System.Limits.getQueries(), 'Query results should have been cached');
        System.Assert.areEqual(expectedUser, returnedUser);
    }

    @IsTest
    static void it_returns_null_when_querying_user_is_disabled() {
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryUserData', Value__c = String.valueOf(false)));
        System.Assert.isFalse(LoggerParameter.QUERY_USER_DATA);

        User returnedUser = LoggerEngineDataSelector.getInstance().getCachedUser();

        System.Assert.areEqual(0, System.Limits.getQueries());
        System.Assert.isNull(returnedUser);
    }

    private class MockLoggerEngineDataSelector extends LoggerEngineDataSelector {
        private Integer authSessionQueryCount = 0;
        private Integer organizationQueryCount = 0;

        public override LoggerSObjectProxy.AuthSession getCachedAuthSessionProxy() {
            Integer originalQueryCount = System.Limits.getQueries();
            LoggerSObjectProxy.AuthSession result = super.getCachedAuthSessionProxy();
            if (System.Limits.getQueries() != originalQueryCount) {
                authSessionQueryCount = System.Limits.getQueries() - originalQueryCount;
            }
            return result;
        }

        public Integer getCachedAuthSessionQueryCount() {
            return authSessionQueryCount;
        }

        public override Organization getCachedOrganization() {
            Integer originalQueryCount = System.Limits.getQueries();
            Organization result = super.getCachedOrganization();
            if (System.Limits.getQueries() != originalQueryCount) {
                organizationQueryCount = System.Limits.getQueries() - originalQueryCount;
            }
            return result;
        }

        public Integer getCachedOrganizationQueryCount() {
            return organizationQueryCount;
        }
    }
}
