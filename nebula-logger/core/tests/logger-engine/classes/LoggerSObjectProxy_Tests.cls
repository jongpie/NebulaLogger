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
                LoginType,
                LoginHistoryId,
                LoginHistory.Application,
                LoginHistory.Browser,
                LoginHistory.Platform,
                LoginHistory.UserId,
                LogoutUrl,
                SessionSecurityLevel,
                SessionType,
                SourceIp,
                UsersId
            FROM AuthSession
            LIMIT 1
        ];
        if (authSessionRecords.isEmpty() == true) {
            // Since the AuthSession object cannot be mocked, the test can only run as an integration test
            // No need to fail the test if there isn't a AuthSession record available via quqerying
            return;
        }
        AuthSession authSessionRecord = authSessionRecords.get(0);

        LoggerSObjectProxy.AuthSession authSessionProxy = new LoggerSObjectProxy.AuthSession(authSessionRecord);

        System.assertEquals(authSessionRecord.Id, authSessionProxy.Id);
        System.assertEquals(authSessionRecord.LoginType, authSessionProxy.LoginType);
        System.assertEquals(authSessionRecord.LoginHistoryId, authSessionProxy.LoginHistoryId);
        System.assertEquals(authSessionRecord.LoginHistory.Application, authSessionProxy.LoginHistory.Application);
        System.assertEquals(authSessionRecord.LoginHistory.Browser, authSessionProxy.LoginHistory.Browser);
        System.assertEquals(authSessionRecord.LoginHistory.Platform, authSessionProxy.LoginHistory.Platform);
        System.assertEquals(authSessionRecord.LoginHistory.UserId, authSessionProxy.LoginHistory.UserId);
        System.assertEquals(authSessionRecord.LogoutUrl, authSessionProxy.LogoutUrl);
        System.assertEquals(authSessionRecord.SessionSecurityLevel, authSessionProxy.SessionSecurityLevel);
        System.assertEquals(authSessionRecord.SessionType, authSessionProxy.SessionType);
        System.assertEquals(authSessionRecord.SourceIp, authSessionProxy.SourceIp);
        System.assertEquals(authSessionRecord.UsersId, authSessionProxy.UsersId);
    }

    @IsTest
    static void it_converts_login_history_record_to_proxy() {
        List<LoginHistory> loginHistoryRecords = [
            SELECT Application, Browser, Platform, UserId
            FROM LoginHistory
            LIMIT 1
        ];
        if (loginHistoryRecords.isEmpty() == true) {
            // Since the LoginHistory object cannot be mocked, the test can only run as an integration test
            // No need to fail the test if there isn't a LoginHistory record available via quqerying
            return;
        }
        LoginHistory loginHistoryRecord = loginHistoryRecords.get(0);

        LoggerSObjectProxy.LoginHistory loginHistoryProxy = new LoggerSObjectProxy.LoginHistory(loginHistoryRecord);

        System.assertEquals(loginHistoryRecord.Application, loginHistoryProxy.Application);
        System.assertEquals(loginHistoryRecord.Browser, loginHistoryProxy.Browser);
        System.assertEquals(loginHistoryRecord.Platform, loginHistoryProxy.Platform);
        System.assertEquals(loginHistoryRecord.UserId, loginHistoryProxy.UserId);
    }

    @IsTest
    static void it_converts_network_record_to_proxy() {
        // No need to fail the test if it's running in an org that does not have Experience Cloud enabled
        if (IS_EXPERIENCE_CLOUD_ENABLED == false) {
            return;
        }

        SObject networkRecord = Database.query('SELECT Id, Name, UrlPathPrefix FROM Network LIMIT 1');

        LoggerSObjectProxy.Network networkProxy = new LoggerSObjectProxy.Network(networkRecord);

        System.assertEquals((Id) networkRecord.get('Id'), networkProxy.Id);
        System.assertEquals((String) networkRecord.get('Name'), networkProxy.Name);
        System.assertEquals((String) networkRecord.get('UrlPathPrefix'), networkProxy.UrlPathPrefix);
    }
}
