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
  static void it_converts_auth_session_record_to_proxy_from_database() {
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
      LIMIT 1
    ];
    if (authSessionRecords.isEmpty()) {
      // Since the Schema.AuthSession object cannot be mocked, the test can only run as an integration test
      // No need to fail the test if there isn't a Schema.AuthSession record available via querying
      return;
    }
    Schema.AuthSession authSessionRecord = authSessionRecords.get(0);

    LoggerSObjectProxy.AuthSession authSessionProxy = new LoggerSObjectProxy.AuthSession(authSessionRecord);

    System.Assert.areEqual(authSessionRecord.Id, authSessionProxy.Id);
    System.Assert.areEqual(authSessionRecord.LoginHistory.Application, authSessionProxy.LoginHistory.Application);
    System.Assert.areEqual(authSessionRecord.LoginHistory.Browser, authSessionProxy.LoginHistory.Browser);
    System.Assert.areEqual(authSessionRecord.LoginHistory.Platform, authSessionProxy.LoginHistory.Platform);
    System.Assert.areEqual(authSessionRecord.LoginHistory.UserId, authSessionProxy.LoginHistory.UserId);
    System.Assert.areEqual(authSessionRecord.LoginHistoryId, authSessionProxy.LoginHistoryId);
    System.Assert.areEqual(authSessionRecord.LoginType, authSessionProxy.LoginType);
    System.Assert.areEqual(authSessionRecord.LogoutUrl, authSessionProxy.LogoutUrl);
    System.Assert.areEqual(authSessionRecord.ParentId, authSessionProxy.ParentId);
    System.Assert.areEqual(authSessionRecord.SessionSecurityLevel, authSessionProxy.SessionSecurityLevel);
    System.Assert.areEqual(authSessionRecord.SessionType, authSessionProxy.SessionType);
    System.Assert.areEqual(authSessionRecord.SourceIp, authSessionProxy.SourceIp);
    System.Assert.areEqual(authSessionRecord.UsersId, authSessionProxy.UsersId);
  }

  @IsTest
  static void it_converts_auth_session_record_to_proxy_from_stub_record_with_no_fields_set() {
    // Given the platform limitations with populating fields on an AuthSession record,
    // this test verifies that safe navigator is used for parent fields that may not be set/returned,
    // like authSessionRecord.LoginHistory.Application. This ensures a empty AuthSession SObject
    // can be used as a stub in other tests that want a minimalistic way to provide a stub.
    Schema.AuthSession authSessionRecord = new Schema.AuthSession();

    LoggerSObjectProxy.AuthSession authSessionProxy = new LoggerSObjectProxy.AuthSession(authSessionRecord);

    System.Assert.isNotNull(authSessionProxy);
    System.Assert.isNull(authSessionProxy.Id);
    System.Assert.isNull(authSessionProxy.LoginHistory.Application);
    System.Assert.isNull(authSessionProxy.LoginHistory.Browser);
    System.Assert.isNull(authSessionProxy.LoginHistory.Platform);
    System.Assert.isNull(authSessionProxy.LoginHistory.UserId);
    System.Assert.isNull(authSessionProxy.LoginHistoryId);
    System.Assert.isNull(authSessionProxy.LoginType);
    System.Assert.isNull(authSessionProxy.LogoutUrl);
    System.Assert.isNull(authSessionProxy.ParentId);
    System.Assert.isNull(authSessionProxy.SessionSecurityLevel);
    System.Assert.isNull(authSessionProxy.SessionType);
    System.Assert.isNull(authSessionProxy.SourceIp);
    System.Assert.isNull(authSessionProxy.UsersId);
  }

  @IsTest
  static void it_converts_auth_session_record_to_proxy_from_mock_record_with_no_fields_set() {
    // This verifies that safe navigator is used for parent fields that may not be set/returned,
    // like authSessionRecord.LoginHistory.Application. This ensures a empty AuthSession SObject
    // can be used as a stub in other tests that want a minimalistic way to provide a stub, given
    // the platform limitations with populating fields on an AuthSession record

    System.Assert.fail('TODO!');
    // Use AUTH_SESSION_FIELD_NAMES AND LOGIN_HISTORY_FIELD_NAMES + 2 corresponding
  }

  @IsTest
  static void it_converts_login_history_record_to_proxy() {
    List<Schema.LoginHistory> loginHistoryRecords = [
      SELECT Application, Browser, Platform, UserId
      FROM LoginHistory
      LIMIT 1
    ];
    if (loginHistoryRecords.isEmpty()) {
      // Since the LoginHistory object cannot be mocked, the test can only run as an integration test
      // No need to fail the test if there isn't a LoginHistory record available via querying
      return;
    }
    Schema.LoginHistory loginHistoryRecord = loginHistoryRecords.get(0);

    LoggerSObjectProxy.LoginHistory loginHistoryProxy = new LoggerSObjectProxy.LoginHistory(loginHistoryRecord);

    System.Assert.areEqual(loginHistoryRecord.Application, loginHistoryProxy.Application);
    System.Assert.areEqual(loginHistoryRecord.Browser, loginHistoryProxy.Browser);
    System.Assert.areEqual(loginHistoryRecord.Platform, loginHistoryProxy.Platform);
    System.Assert.areEqual(loginHistoryRecord.UserId, loginHistoryProxy.UserId);
  }

  @IsTest
  static void it_converts_network_record_to_proxy_when_using_stub_account_record() {
    // Since Schema.Network doesn't exist in all orgs, verify that another SObject & its fields can be substituted
    LoggerSObjectProxy.NETWORK_FIELD_NAMES.urlPathPrefixField = Schema.Account.Description.toString();
    SObject stubNetworkRecord = new Schema.Account();
    stubNetworkRecord.put(LoggerSObjectProxy.NETWORK_FIELD_NAMES.idField, LoggerMockDataCreator.createId(stubNetworkRecord.getSObjectType()));
    stubNetworkRecord.put(LoggerSObjectProxy.NETWORK_FIELD_NAMES.nameField, 'Mock Network Record');
    stubNetworkRecord.put(LoggerSObjectProxy.NETWORK_FIELD_NAMES.urlPathPrefixField, 'this-is-called-a-prefix-even-though-it-comes-at-the-end-of-the-base-url');

    LoggerSObjectProxy.Network networkProxy = new LoggerSObjectProxy.Network(stubNetworkRecord);

    System.Assert.areEqual((Id) LoggerSObjectProxy.NETWORK_FIELD_NAMES.idField, networkProxy.Id);
    System.Assert.areEqual((String) LoggerSObjectProxy.NETWORK_FIELD_NAMES.nameField, networkProxy.Name);
    System.Assert.areEqual((String) LoggerSObjectProxy.NETWORK_FIELD_NAMES.urlPathPrefixField, networkProxy.UrlPathPrefix);
  }

  @IsTest
  static void it_converts_network_record_to_proxy_when_experience_cloud_enabled() {
    // No need to fail the test if it's running in an org that does not have Experience Cloud enabled
    if (IS_EXPERIENCE_CLOUD_ENABLED == false) {
      return;
    }
    SObject mockNetworkRecord = (SObject) (System.Type.forName('Schema.Network').newInstance());
    mockNetworkRecord.put(LoggerSObjectProxy.NETWORK_FIELD_NAMES.idField, LoggerMockDataCreator.createId(mockNetworkRecord.getSObjectType()));
    mockNetworkRecord.put(LoggerSObjectProxy.NETWORK_FIELD_NAMES.nameField, 'Mock Network Record');
    mockNetworkRecord.put(LoggerSObjectProxy.NETWORK_FIELD_NAMES.urlPathPrefixField, 'this-is-called-a-prefix-even-though-it-comes-at-the-end-of-the-base-url');

    LoggerSObjectProxy.Network networkProxy = new LoggerSObjectProxy.Network(mockNetworkRecord);

    System.Assert.areEqual((Id) mockNetworkRecord.get(LoggerSObjectProxy.NETWORK_FIELD_NAMES.idField), networkProxy.Id);
    System.Assert.areEqual((String) mockNetworkRecord.get(LoggerSObjectProxy.NETWORK_FIELD_NAMES.nameField), networkProxy.Name);
    System.Assert.areEqual((String) mockNetworkRecord.get(LoggerSObjectProxy.NETWORK_FIELD_NAMES.urlPathPrefixField), networkProxy.UrlPathPrefix);
  }

  @IsTest
  static void it_converts_omni_process_record_to_proxy_when_using_stub_account_record() {
    // Since Schema.OmniProcess doesn't exist in all orgs, verify that another SObject & its fields can be substituted
    Schema.User currentUser = new Schema.User(Id = System.UserInfo.getUserId(), Username = System.UserInfo.getUsername());
    // Some audit fields, like CreatedById, can't be set on an SObject, so start with a Map
    Map<String, Object> mockOmniProcessUntyped = new Map<String, Object>{
      'attributes' => new Map<String, Object>{ 'type' => Schema.Account.SObjectType.toString() }
    };
    mockOmniProcessUntyped.put(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.createdByIdField, currentUser.Id);
    // mockOmniProcessUntyped.put(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.createdByField, currentUser);
    mockOmniProcessUntyped.put(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.createdDateField, System.now().addDays(-7));
    mockOmniProcessUntyped.put(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.lastModifiedByIdField, currentUser.Id);
    // mockOmniProcessUntyped.put(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.lastModifiedByField, currentUser);
    mockOmniProcessUntyped.put(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.lastModifiedDateField, System.now().addDays(-1));
    mockOmniProcessUntyped.put(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.omniProcessTypeField, 'Integration Procedure');
    mockOmniProcessUntyped.put(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.uniqueNameField, 'Mock_OmniScript_English_1');
    SObject mockOmniProcessRecord = (SObject) System.JSON.deserialize(System.JSON.serialize(mockOmniProcessUntyped), SObject.class);
    mockOmniProcessRecord.put(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.idField, LoggerMockDataCreator.createId(mockOmniProcessRecord.getSObjectType()));

    LoggerSObjectProxy.OmniProcess omniProcessProxy = new LoggerSObjectProxy.OmniProcess(mockOmniProcessRecord);

    // System.Assert.areEqual((Schema.User) mockOmniProcessRecord.get(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.createdByField), omniProcessProxy.CreatedBy);
    System.Assert.areEqual((String) mockOmniProcessRecord.get(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.createdByIdField), omniProcessProxy.CreatedById);
    System.Assert.areEqual((Datetime) mockOmniProcessRecord.get(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.createdDateField), omniProcessProxy.CreatedDate);
    System.Assert.areEqual((Id) mockOmniProcessRecord.get(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.idField), omniProcessProxy.Id);
    // System.Assert.areEqual((Schema.User) mockOmniProcessRecord.get(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.lastModifiedByField), omniProcessProxy.LastModifiedBy);
    System.Assert.areEqual(
      (String) mockOmniProcessRecord.get(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.lastModifiedByIdField),
      omniProcessProxy.LastModifiedById
    );
    System.Assert.areEqual(
      (Datetime) mockOmniProcessRecord.get(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.lastModifiedDateField),
      omniProcessProxy.LastModifiedDate
    );
    System.Assert.areEqual(
      (String) mockOmniProcessRecord.get(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.omniProcessTypeField),
      omniProcessProxy.OmniProcessType
    );
    System.Assert.areEqual((String) mockOmniProcessRecord.get(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.uniqueNameField), omniProcessProxy.UniqueName);
  }

  @IsTest
  static void it_converts_omni_process_record_to_proxy_when_omnistudio_enabled() {
    System.Assert.fail('TODO');
    // No need to fail the test if it's running in an org that does not have OmniStudio enabled
    if (IS_OMNISTUDIO_ENABLED == false) {
      return;
    }
    Schema.User currentUser = new Schema.User(Id = System.UserInfo.getUserId(), Username = System.UserInfo.getUsername());
    // Some audit fields, like CreatedById, can't be set on an SObject, so start with a Map
    Map<String, Object> mockOmniProcessUntyped = new Map<String, Object>{ 'attributes' => new Map<String, Object>{ 'type' => 'OmniProcess' } };
    mockOmniProcessUntyped.put(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.createdByIdField, currentUser.Id);
    // mockOmniProcessUntyped.put(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.createdByField, currentUser);
    mockOmniProcessUntyped.put(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.createdDateField, System.now().addDays(-7));
    mockOmniProcessUntyped.put(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.lastModifiedByIdField, currentUser.Id);
    // mockOmniProcessUntyped.put(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.lastModifiedByField, currentUser);
    mockOmniProcessUntyped.put(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.lastModifiedDateField, System.now().addDays(-1));
    mockOmniProcessUntyped.put(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.omniProcessTypeField, 'Integration Procedure');
    mockOmniProcessUntyped.put(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.uniqueNameField, 'Mock_OmniScript_English_1');
    SObject mockOmniProcessRecord = (SObject) System.JSON.deserialize(System.JSON.serialize(mockOmniProcessUntyped), SObject.class);
    mockOmniProcessRecord.put(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.idField, LoggerMockDataCreator.createId(mockOmniProcessRecord.getSObjectType()));

    LoggerSObjectProxy.OmniProcess omniProcessProxy = new LoggerSObjectProxy.OmniProcess(mockOmniProcessRecord);

    // System.Assert.areEqual((Schema.User) mockOmniProcessRecord.get(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.createdByField), omniProcessProxy.CreatedBy);
    System.Assert.areEqual((String) mockOmniProcessRecord.get(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.createdByIdField), omniProcessProxy.CreatedById);
    System.Assert.areEqual((Datetime) mockOmniProcessRecord.get(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.createdDateField), omniProcessProxy.CreatedDate);
    System.Assert.areEqual((Id) mockOmniProcessRecord.get(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.idField), omniProcessProxy.Id);
    // System.Assert.areEqual((Schema.User) mockOmniProcessRecord.get(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.lastModifiedByField), omniProcessProxy.LastModifiedBy);
    System.Assert.areEqual(
      (String) mockOmniProcessRecord.get(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.lastModifiedByIdField),
      omniProcessProxy.LastModifiedById
    );
    System.Assert.areEqual(
      (Datetime) mockOmniProcessRecord.get(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.lastModifiedDateField),
      omniProcessProxy.LastModifiedDate
    );
    System.Assert.areEqual(
      (String) mockOmniProcessRecord.get(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.omniProcessTypeField),
      omniProcessProxy.OmniProcessType
    );
    System.Assert.areEqual((String) mockOmniProcessRecord.get(LoggerSObjectProxy.OMNI_PROCESS_FIELD_NAMES.uniqueNameField), omniProcessProxy.UniqueName);
  }
}
