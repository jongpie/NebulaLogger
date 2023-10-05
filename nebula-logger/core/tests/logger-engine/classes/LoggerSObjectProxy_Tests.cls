//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerSObjectProxy_Tests {
    private static final Boolean IS_EXPERIENCE_CLOUD_ENABLED = System.Type.forName('NetworkMember') != null;

    @IsTest
    static void it_converts_auth_session_record_to_proxy() {
        List<AuthSession> authSessionRecords = [
            SELECT
                Id,
                LoginHistory.Application,
                LoginHistory.Browser,
                LoginHistory.Platform,
                LoginHistory.UserId,
                LoginHistoryId,
                LoginType,
                LogoutUrl,
                SessionSecurityLevel,
                SessionType,
                SourceIp,
                UsersId
            FROM AuthSession
            LIMIT 1
        ];
        if (authSessionRecords.isEmpty()) {
            // Since the AuthSession object cannot be mocked, the test can only run as an integration test
            // No need to fail the test if there isn't a AuthSession record available via querying
            return;
        }
        AuthSession authSessionRecord = authSessionRecords.get(0);

        LoggerSObjectProxy.AuthSession authSessionProxy = new LoggerSObjectProxy.AuthSession(authSessionRecord);

        System.Assert.areEqual(authSessionRecord.Id, authSessionProxy.Id);
        System.Assert.areEqual(authSessionRecord.LoginType, authSessionProxy.LoginType);
        System.Assert.areEqual(authSessionRecord.LoginHistoryId, authSessionProxy.LoginHistoryId);
        System.Assert.areEqual(authSessionRecord.LoginHistory.Application, authSessionProxy.LoginHistory.Application);
        System.Assert.areEqual(authSessionRecord.LoginHistory.Browser, authSessionProxy.LoginHistory.Browser);
        System.Assert.areEqual(authSessionRecord.LoginHistory.Platform, authSessionProxy.LoginHistory.Platform);
        System.Assert.areEqual(authSessionRecord.LoginHistory.UserId, authSessionProxy.LoginHistory.UserId);
        System.Assert.areEqual(authSessionRecord.LogoutUrl, authSessionProxy.LogoutUrl);
        System.Assert.areEqual(authSessionRecord.SessionSecurityLevel, authSessionProxy.SessionSecurityLevel);
        System.Assert.areEqual(authSessionRecord.SessionType, authSessionProxy.SessionType);
        System.Assert.areEqual(authSessionRecord.SourceIp, authSessionProxy.SourceIp);
        System.Assert.areEqual(authSessionRecord.UsersId, authSessionProxy.UsersId);
    }

    @IsTest
    static void it_converts_login_history_record_to_proxy() {
        List<LoginHistory> loginHistoryRecords = [
            SELECT Application, Browser, Platform, UserId
            FROM LoginHistory
            LIMIT 1
        ];
        if (loginHistoryRecords.isEmpty()) {
            // Since the LoginHistory object cannot be mocked, the test can only run as an integration test
            // No need to fail the test if there isn't a LoginHistory record available via querying
            return;
        }
        LoginHistory loginHistoryRecord = loginHistoryRecords.get(0);

        LoggerSObjectProxy.LoginHistory loginHistoryProxy = new LoggerSObjectProxy.LoginHistory(loginHistoryRecord);

        System.Assert.areEqual(loginHistoryRecord.Application, loginHistoryProxy.Application);
        System.Assert.areEqual(loginHistoryRecord.Browser, loginHistoryProxy.Browser);
        System.Assert.areEqual(loginHistoryRecord.Platform, loginHistoryProxy.Platform);
        System.Assert.areEqual(loginHistoryRecord.UserId, loginHistoryProxy.UserId);
    }

    @IsTest
    static void it_converts_network_record_to_proxy() {
        // No need to fail the test if it's running in an org that does not have Experience Cloud enabled
        if (IS_EXPERIENCE_CLOUD_ENABLED == false) {
            return;
        }
        String idFieldName = 'Id';
        String nameFieldName = 'Name';
        String urlPathPrefixFieldName = 'UrlPathPrefix';
        SObject mockNetworkRecord = (SObject) (System.Type.forName('Schema.Network').newInstance());
        mockNetworkRecord.put(idFieldName, LoggerMockDataCreator.createId(mockNetworkRecord.getSObjectType()));
        mockNetworkRecord.put(nameFieldName, 'Mock Network Record');
        mockNetworkRecord.put(urlPathPrefixFieldName, 'this-is-called-a-prefix-even-though-it-comes-at-the-end-of-the-base-url');

        LoggerSObjectProxy.Network networkProxy = new LoggerSObjectProxy.Network(mockNetworkRecord);

        System.Assert.areEqual((Id) mockNetworkRecord.get(idFieldName), networkProxy.Id);
        System.Assert.areEqual((String) mockNetworkRecord.get(nameFieldName), networkProxy.Name);
        System.Assert.areEqual((String) mockNetworkRecord.get(urlPathPrefixFieldName), networkProxy.UrlPathPrefix);
    }
}
