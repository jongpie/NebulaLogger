//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerSObjectProxy_Tests {
  private static final Boolean IS_EXPERIENCE_CLOUD_ENABLED = System.Type.forName('Schema.Network') != null;
  private static final Boolean IS_OMNISTUDIO_ENABLED = System.Type.forName('Schema.OmniProcess') != null;

  @IsTest
  static void it_supports_constructing_proxy_classes() {
    // This test is a bit silly, it's primarily here because the other tests uses JSON.deserialize(),
    // which doesn't provided code coverage
    LoggerSObjectProxy.AuthSession authSessionProxy = new LoggerSObjectProxy.AuthSession();
    LoggerSObjectProxy.LoginHistory loginHistoryProxy = new LoggerSObjectProxy.LoginHistory();
    LoggerSObjectProxy.Network networkProxy = new LoggerSObjectProxy.Network();
    LoggerSObjectProxy.OmniProcess omniProcessProxy = new LoggerSObjectProxy.OmniProcess();

    System.Assert.areEqual(System.JSON.serializePretty(authSessionProxy), authSessionProxy.serialize());
    System.Assert.areEqual(System.JSON.serializePretty(loginHistoryProxy), loginHistoryProxy.serialize());
    System.Assert.areEqual(System.JSON.serializePretty(networkProxy), networkProxy.serialize());
    System.Assert.areEqual(System.JSON.serializePretty(omniProcessProxy), omniProcessProxy.serialize());
  }

  @IsTest
  static void it_correctly_deserializes_auth_session_records_to_proxies() {
    List<Schema.AuthSession> authSessionRecords = [
      SELECT
        Id,
        LoginHistory.Application,
        LoginHistory.Browser,
        LoginHistory.Platform,
        LoginHistory.UserId,
        LoginHistoryId,
        LoginType,
        LogoutUrl,
        ParentId,
        SessionSecurityLevel,
        SessionType,
        SourceIp,
        UsersId
      FROM AuthSession
      LIMIT 3
    ];

    List<LoggerSObjectProxy.AuthSession> authSessionProxies = (List<LoggerSObjectProxy.AuthSession>) System.JSON.deserialize(
      System.JSON.serialize(authSessionRecords),
      List<LoggerSObjectProxy.AuthSession>.class
    );

    System.Assert.areEqual(authSessionRecords.size(), authSessionProxies.size());
    for (Integer i = 0; i < authSessionRecords.size(); i++) {
      Schema.AuthSession authSessionRecord = authSessionRecords.get(i);
      LoggerSObjectProxy.AuthSession authSessionProxy = authSessionProxies.get(i);
      System.Assert.areEqual(authSessionRecord.LoginHistory?.Application, authSessionProxy.LoginHistory?.Application);
      System.Assert.areEqual(authSessionRecord.LoginHistory?.Browser, authSessionProxy.LoginHistory?.Browser);
      System.Assert.areEqual(authSessionRecord.LoginHistory?.Platform, authSessionProxy.LoginHistory?.Platform);
      System.Assert.areEqual(authSessionRecord.LoginHistory?.UserId, authSessionProxy.LoginHistory?.UserId);
      System.Assert.areEqual(authSessionRecord.LoginHistoryId, authSessionProxy.LoginHistoryId);
      System.Assert.areEqual(authSessionRecord.LoginType, authSessionProxy.LoginType);
      System.Assert.areEqual(authSessionRecord.LogoutUrl, authSessionProxy.LogoutUrl);
      System.Assert.areEqual(authSessionRecord.ParentId, authSessionProxy.ParentId);
      System.Assert.areEqual(authSessionRecord.SessionSecurityLevel, authSessionProxy.SessionSecurityLevel);
      System.Assert.areEqual(authSessionRecord.SessionType, authSessionProxy.SessionType);
      System.Assert.areEqual(authSessionRecord.SourceIp, authSessionProxy.SourceIp);
      System.Assert.areEqual(authSessionRecord.UsersId, authSessionProxy.UsersId);
    }
  }

  @IsTest
  static void it_correctly_deserializes_login_history_records_to_proxies() {
    List<Schema.LoginHistory> loginHistoryRecords = [
      SELECT Application, Browser, Platform, UserId
      FROM LoginHistory
      LIMIT 3
    ];

    List<LoggerSObjectProxy.LoginHistory> loginHistoryProxies = (List<LoggerSObjectProxy.LoginHistory>) System.JSON.deserialize(
      System.JSON.serialize(loginHistoryRecords),
      List<LoggerSObjectProxy.LoginHistory>.class
    );

    System.Assert.areEqual(loginHistoryRecords.size(), loginHistoryProxies.size());
    for (Integer i = 0; i < loginHistoryRecords.size(); i++) {
      Schema.LoginHistory loginHistoryRecord = loginHistoryRecords.get(i);
      LoggerSObjectProxy.LoginHistory loginHistoryProxy = loginHistoryProxies.get(i);
      System.Assert.areEqual(loginHistoryRecord.Application, loginHistoryProxy.Application);
      System.Assert.areEqual(loginHistoryRecord.Browser, loginHistoryProxy.Browser);
      System.Assert.areEqual(loginHistoryRecord.Platform, loginHistoryProxy.Platform);
      System.Assert.areEqual(loginHistoryRecord.UserId, loginHistoryProxy.UserId);
    }
  }

  @IsTest
  static void it_correctly_deserializes_network_records_to_proxies_when_experience_cloud_enabled() {
    // No need to fail the test if it's running in an org that does not have Experience Cloud enabled
    if (IS_EXPERIENCE_CLOUD_ENABLED == false) {
      return;
    }
    List<SObject> networkRecords = System.Database.query('SELECT Id, Name, UrlPathPrefix FROM Network LIMIT 3');

    List<LoggerSObjectProxy.Network> networkProxies = (List<LoggerSObjectProxy.Network>) System.JSON.deserialize(
      System.JSON.serialize(networkRecords),
      List<LoggerSObjectProxy.Network>.class
    );

    System.Assert.areEqual(networkRecords.size(), networkProxies.size());
    for (Integer i = 0; i < networkRecords.size(); i++) {
      SObject networkRecord = networkRecords.get(i);
      LoggerSObjectProxy.Network networkProxy = networkProxies.get(i);
      System.Assert.areEqual(networkRecord.get('Id'), networkProxy.Id);
      System.Assert.areEqual(networkRecord.get('Name'), networkProxy.Name);
      System.Assert.areEqual(networkRecord.get('UrlPathPrefix'), networkProxy.UrlPathPrefix);
    }
  }

  @IsTest
  static void it_deserializes_omni_process_record_to_proxy_from_database_when_omnistudio_enabled() {
    // No need to fail the test if it's running in an org that does not have OmniStudio enabled
    if (IS_OMNISTUDIO_ENABLED == false) {
      return;
    }
    List<SObject> omniProcessRecords = System.Database.query(
      'SELECT SELECT CreatedBy.Username, CreatedById, CreatedDate, Id, IsIntegrationProcedure, LastModifiedBy.Username,' +
        ' LastModifiedById, LastModifiedDate, OmniProcessType, UniqueName' +
        ' FROM OmniProcess LIMIT 3'
    );

    List<LoggerSObjectProxy.OmniProcess> omniProcessProxies = (List<LoggerSObjectProxy.OmniProcess>) System.JSON.deserialize(
      System.JSON.serialize(omniProcessRecords),
      List<LoggerSObjectProxy.OmniProcess>.class
    );

    System.Assert.areEqual(omniProcessRecords.size(), omniProcessProxies.size());
    for (Integer i = 0; i < omniProcessRecords.size(); i++) {
      SObject omniProcessRecord = omniProcessRecords.get(i);
      LoggerSObjectProxy.OmniProcess omniProcessProxy = omniProcessProxies.get(i);
      System.Assert.areEqual(omniProcessRecord.get('CreatedById'), omniProcessProxy.CreatedById);
      System.Assert.areEqual(omniProcessRecord.getSObject('CreatedBy'), omniProcessProxy.CreatedBy);
      System.Assert.areEqual(omniProcessRecord.get('CreatedDate'), omniProcessProxy.CreatedDate);
      System.Assert.areEqual(omniProcessRecord.get('Id'), omniProcessProxy.Id);
      System.Assert.areEqual(omniProcessRecord.get('LastModifiedById'), omniProcessProxy.LastModifiedById);
      System.Assert.areEqual(omniProcessRecord.getSObject('LastModifiedBy'), omniProcessProxy.LastModifiedBy);
      System.Assert.areEqual(omniProcessRecord.get('LastModifiedDate'), omniProcessProxy.LastModifiedDate);
      System.Assert.areEqual(omniProcessRecord.get('OmniProcessType'), omniProcessProxy.OmniProcessType);
      System.Assert.areEqual(omniProcessRecord.get('UniqueName'), omniProcessProxy.UniqueName);
    }
  }
}
