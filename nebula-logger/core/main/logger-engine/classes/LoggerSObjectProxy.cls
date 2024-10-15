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
@SuppressWarnings('PMD.ExcessivePublicCount, PMD.PropertyNamingConventions')
public without sharing class LoggerSObjectProxy {
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
  }
}
