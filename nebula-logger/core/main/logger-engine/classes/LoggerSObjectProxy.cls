//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Proxy class used as a middle layer between some problematic SObject Types and the rest of Nebula Logger's codebase.
 *              Each inner class maps to a corresponding `SObjectType` that is difficult to work with Apex for some reason or another,
 *              such as not being mockable or creatable, or not existing in all orgs.
 */
@SuppressWarnings('PMD.ExcessivePublicCount')
public without sharing class LoggerSObjectProxy {
  @TestVisible
  private static final AuthSessionFieldNames AUTH_SESSION_FIELD_NAMES {
    get {
      if (AUTH_SESSION_FIELD_NAMES == null) {
        AUTH_SESSION_FIELD_NAMES = new AuthSessionFieldNames();
      }
      return AUTH_SESSION_FIELD_NAMES;
    }
    private set;
  }
  @TestVisible
  private static final LoginHistoryFieldNames LOGIN_HISTORY_FIELD_NAMES {
    get {
      if (LOGIN_HISTORY_FIELD_NAMES == null) {
        LOGIN_HISTORY_FIELD_NAMES = new LoginHistoryFieldNames();
      }
      return LOGIN_HISTORY_FIELD_NAMES;
    }
    private set;
  }
  @TestVisible
  private static final NetworkFieldNames NETWORK_FIELD_NAMES {
    get {
      if (NETWORK_FIELD_NAMES == null) {
        NETWORK_FIELD_NAMES = new NetworkFieldNames();
      }
      return NETWORK_FIELD_NAMES;
    }
    private set;
  }
  @TestVisible
  private static final OmniProcessFieldNames OMNI_PROCESS_FIELD_NAMES {
    get {
      if (OMNI_PROCESS_FIELD_NAMES == null) {
        OMNI_PROCESS_FIELD_NAMES = new OmniProcessFieldNames();
      }
      return OMNI_PROCESS_FIELD_NAMES;
    }
    private set;
  }

  /**
   * @description All `Schema.AuthSession` SObjects are read-only in Apex, which makes them more difficult to work with, and impossible
   *              to mock field values directly during unit tests - even using tricks like System.JSON.deserialize() do not work. The `LoggerSObjectProxy.AuthSession`
   *              class acts as a substitute for a `Schema.AuthSession` record to provide the abilility to mock the data during unit & integration tests.
   */
  @SuppressWarnings('PMD.FieldNamingConventions, PMD.VariableNamingConventions')
  public class AuthSession {
    public Id Id;
    public String LoginType;
    public Id LoginHistoryId;
    public LoginHistory LoginHistory;
    public String LogoutUrl;
    public Id ParentId;
    public String SessionSecurityLevel;
    public String SessionType;
    public String SourceIp;
    public Id UsersId;

    @SuppressWarnings('PMD.ApexDoc')
    public AuthSession(Schema.AuthSession authSessionRecord) {
      this(authSessionRecord, new LoginHistory(authSessionRecord?.LoginHistory));
    }

    public AuthSession(Schema.AuthSession authSessionRecord, LoginHistory loginHistoryProxy) {
      if (authSessionRecord != null) {
        this.Id = authSessionRecord.Id;
        this.LoginHistory = loginHistoryProxy;
        this.LoginHistoryId = authSessionRecord.LoginHistoryId;
        this.LoginType = authSessionRecord.LoginType;
        this.LogoutUrl = authSessionRecord.LogoutUrl;
        this.ParentId = authSessionRecord.ParentId;
        this.SessionSecurityLevel = authSessionRecord.SessionSecurityLevel;
        this.SessionType = authSessionRecord.SessionType;
        this.SourceIp = authSessionRecord.SourceIp;
        this.UsersId = authSessionRecord.UsersId;
      }
    }
  }

  /**
   * @description All `Schema.LoginHistory` SObjects are read-only in Apex, which makes them more difficult to work with, and impossible
   *              to mock field values directly during unit tests - even using tricks like System.JSON.deserialize() do not work. The `LoggerSObjectProxy.LoginHistory`
   *              class acts as a substitute for a `Schema.LoginHistory` record to provide the abilility to mock the data during unit & integration tests.
   */
  @SuppressWarnings('PMD.FieldNamingConventions, PMD.VariableNamingConventions')
  public class LoginHistory {
    public String Application;
    public String Browser;
    public String Platform;
    public Id UserId;

    @SuppressWarnings('PMD.ApexDoc')
    public LoginHistory(Schema.LoginHistory loginHistoryRecord) {
      if (loginHistoryRecord != null) {
        this.Application = loginHistoryRecord.Application;
        this.Browser = loginHistoryRecord.Browser;
        this.Platform = loginHistoryRecord.Platform;
        this.UserId = loginHistoryRecord.UserId;
      }
    }
  }

  /**
   * @description Not all orgs have the SObject `Schema.Network` - it is only present in orgs that have enabled Experience Cloud Sites (communities/networks),
   *              so `Schema.Network` has to be referenced dynamically, including using hardcoded `String` values for field API names. The
   *              `LoggerSObjectProxy.Network` class acts as a substitute for a `Schema.Network` record so that the rest of the codebase can rely on
   *              strongly-typed references to fields (properties).
   */
  @SuppressWarnings('PMD.FieldNamingConventions, PMD.VariableNamingConventions')
  public class Network {
    public String Id;
    public String Name;
    public String UrlPathPrefix;

    @SuppressWarnings('PMD.ApexDoc')
    public Network(SObject networkRecord) {
      if (networkRecord != null) {
        this.Id = (String) networkRecord.get(NETWORK_FIELD_NAMES.idField);
        this.Name = (String) networkRecord.get(NETWORK_FIELD_NAMES.nameField);
        this.UrlPathPrefix = (String) networkRecord.get(NETWORK_FIELD_NAMES.urlPathPrefixField);
      }
    }
  }

  /**
   * @description Not all orgs have the SObject `Schema.OmniProcess` - it is only present in orgs that have enabled OmniStudio,
   *              so `Schema.OmniProcess` has to be referenced dynamically, including using hardcoded `String` values for field API names. The
   *              `LoggerSObjectProxy.OmniProcess` class acts as a substitute for a `Schema.OmniProcess` record so that the rest of the codebase can rely on
   *              strongly-typed references to fields (properties).
   */
  @SuppressWarnings('PMD.FieldNamingConventions, PMD.VariableNamingConventions')
  public class OmniProcess {
    public Id CreatedById;
    public Schema.User CreatedBy;
    public Datetime CreatedDate;
    public String Id;
    public Id LastModifiedById;
    public Schema.User LastModifiedBy;
    public Datetime LastModifiedDate;
    public String OmniProcessType;
    public String UniqueName;

    @SuppressWarnings('PMD.ApexDoc')
    public OmniProcess(SObject omniProcess) {
      if (omniProcess != null) {
        this.CreatedById = (String) omniProcess.get(OMNI_PROCESS_FIELD_NAMES.createdByIdField);
        // TODO convert to use OMNI_PROCESS_FIELD_NAMES
        this.CreatedBy = (Schema.User) omniProcess.getSObject('CreatedBy');
        this.CreatedDate = (Datetime) omniProcess.get(OMNI_PROCESS_FIELD_NAMES.createdDateField);
        this.Id = (String) omniProcess.get(OMNI_PROCESS_FIELD_NAMES.idField);
        this.LastModifiedById = (String) omniProcess.get(OMNI_PROCESS_FIELD_NAMES.lastModifiedByIdField);
        // TODO convert to use OMNI_PROCESS_FIELD_NAMES
        this.LastModifiedBy = (Schema.User) omniProcess.getSObject('LastModifiedBy');
        this.LastModifiedDate = (Datetime) omniProcess.get(OMNI_PROCESS_FIELD_NAMES.lastModifiedDateField);
        this.OmniProcessType = (String) omniProcess.get(OMNI_PROCESS_FIELD_NAMES.omniProcessTypeField);
        this.UniqueName = (String) omniProcess.get(OMNI_PROCESS_FIELD_NAMES.uniqueNameField);
      }
    }
  }

  private class AuthSessionFieldNames {
    public String idField = 'Id';
    public String loginTypeField = 'LoginType';
    public String loginHistoryIdField = 'LoginHistoryId';
    public String loginHistoryField = 'LoginHistory';
    public String logoutUrlField = 'LogoutUrl';
    public String parentIdField = 'ParentId';
    public String sessionSecurityLevelField = 'SessionSecurityLevel';
    public String sessionTypeField = 'SessionType';
    public String sourceIpField = 'SourceIp';
    public String usersIdField = 'UsersId';
  }

  private class LoginHistoryFieldNames {
    public String applicationField = 'Application';
    public String browserField = 'Browser';
    public String platformField = 'Platform';
    public String userIdField = 'UserId';
  }

  private class NetworkFieldNames {
    public String idField = 'Id';
    public String nameField = 'Name';
    public String urlPathPrefixField = 'UrlPathPrefix';
  }

  private class OmniProcessFieldNames {
    public String createdByIdField = 'CreatedById';
    public String createdByField = 'CreatedBy';
    public String createdDateField = 'CreatedDate';
    public String idField = 'Id';
    public String lastModifiedByIdField = 'LastModifiedById';
    public String lastModifiedByField = 'LastModifiedBy';
    public String lastModifiedDateField = 'LastModifiedDate';
    public String omniProcessTypeField = 'OmniProcessType';
    public String uniqueNameField = 'UniqueName';
  }
}
