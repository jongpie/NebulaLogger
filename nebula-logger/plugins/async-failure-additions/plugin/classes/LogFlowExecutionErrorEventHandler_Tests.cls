//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LogFlowExecutionErrorEventHandler_Tests {
  @IsTest
  static void it_does_not_log_when_plugin_parameter_disabled() {
    setLoggerParamEnabled(false);

    System.Test.startTest();
    LogFlowExecutionErrorEventHandler.logErrors(new List<Schema.FlowExecutionErrorEvent>{ new Schema.FlowExecutionErrorEvent() });
    System.Test.stopTest();

    System.Assert.areEqual(0, [SELECT COUNT() FROM Log__c]);
  }

  @IsTest
  static void it_logs_when_enabled() {
    setLoggerParamEnabled(true);
    Schema.FlowExecutionErrorEvent flowExecutionErrorEvent = new Schema.FlowExecutionErrorEvent();
    flowExecutionErrorEvent.EventDate = System.now().addSeconds(-5);
    flowExecutionErrorEvent.ElementApiName = 'test_exception_element';
    flowExecutionErrorEvent.FlowApiName = 'Testing_FlowExecutionErrorEvent';
    flowExecutionErrorEvent.FlowVersionNumber = 1;
    flowExecutionErrorEvent.Username = System.UserInfo.getUsername();

    System.runAs(new Schema.User(Id = [SELECT Id FROM User WHERE Alias = 'autoproc'].Id)) {
      System.Test.startTest();
      LogFlowExecutionErrorEventHandler.logErrors(new List<Schema.FlowExecutionErrorEvent>{ flowExecutionErrorEvent });
      System.Test.stopTest();
    }

    LogEntry__c entry = [
      SELECT
        Log__r.LoggedBy__c,
        Log__r.LoggedByUsername__c,
        Log__r.LoginApplication__c,
        Log__r.LoginBrowser__c,
        Log__r.LoginHistoryId__c,
        Log__r.LoginPlatform__c,
        Log__r.LoginType__c,
        Log__r.LogoutUrl__c,
        Log__r.NetworkId__c,
        Log__r.ProfileId__c,
        Log__r.ProfileName__c,
        Log__r.SessionId__c,
        Log__r.SessionSecurityLevel__c,
        Log__r.SessionType__c,
        Log__r.SourceIp__c,
        Log__r.TimeZoneId__c,
        Log__r.TimeZoneName__c,
        LoggingLevel__c,
        Message__c,
        Origin__c,
        OriginLocation__c,
        OriginType__c,
        RecordId__c,
        Timestamp__c
      FROM LogEntry__c
    ];
    // LogEntry__c related asserts
    System.Assert.areEqual(System.LoggingLevel.ERROR.name(), entry.LoggingLevel__c, 'Logging level should be set correctly');
    System.Assert.areEqual(
      String.format(
        LogFlowExecutionErrorEventHandler.LOG_STRING,
        new List<String>{ flowExecutionErrorEvent.ElementApiName, flowExecutionErrorEvent.FlowVersionNumber.format() }
      ),
      entry.Message__c,
      'Log message should be formatted correctly'
    );
    System.Assert.areEqual(flowExecutionErrorEvent.FlowApiName, entry.OriginLocation__c, 'OriginLocation__c should be set correctly');
    System.Assert.areEqual('Flow', entry.OriginType__c, 'OriginType__c should be set to Flow');
    System.Assert.areEqual(flowExecutionErrorEvent.EventDate, entry.Timestamp__c, 'Should take timestamp from flow error event');

    // Log__c related asserts
    Schema.User currentUser = [
      SELECT
        Id,
        ProfileId,
        Profile.Name,
        Profile.UserLicenseId,
        Profile.UserLicense.LicenseDefinitionKey,
        Profile.UserLicense.Name,
        Username,
        UserRoleId,
        UserRole.Name,
        UserType
      FROM User
      WHERE Id = :System.UserInfo.getUserId()
    ];
    Log__c log = entry.Log__r;
    System.Assert.areEqual(currentUser.Id, log.LoggedBy__c, 'Should not use autoproc user Id');
    System.Assert.areEqual(currentUser.Username, log.LoggedByUsername__c, 'Username should match');
    System.Assert.areEqual(currentUser.ProfileId, log.ProfileId__c, 'Should not use autoproc user ProfileId');
    System.Assert.areEqual(currentUser.Profile.Name, log.ProfileName__c, 'Should not use autoproc user Profile name');
    System.Assert.isNull(log.LoginApplication__c, 'LoginApplication__c should have been cleared');
    System.Assert.isNull(log.LoginBrowser__c, 'LoginBrowser__c should have been cleared');
    System.Assert.isNull(log.LoginHistoryId__c, 'LoginHistoryId__c should have been cleared');
    System.Assert.isNull(log.LoginPlatform__c, 'LoginPlatform__c should have been cleared');
    System.Assert.isNull(log.LoginType__c, 'LoginType__c should have been cleared');
    System.Assert.isNull(log.LogoutUrl__c, 'LogoutUrl__c should have been cleared');
    System.Assert.isNull(log.NetworkId__c, 'NetworkId__c should have been cleared');
    System.Assert.isNull(log.SessionId__c, 'SessionId__c Should have been cleared');
    System.Assert.isNull(log.SessionSecurityLevel__c, 'SessionSecurityLevel__c should have been cleared');
    System.Assert.isNull(log.SessionType__c, 'SessionType__c should have been cleared');
    System.Assert.isNull(log.SourceIp__c, 'SourceIp__c should have been cleared');
    System.Assert.areEqual(System.UserInfo.getTimeZone().getId(), log.TimeZoneId__c, 'Timezone Id should be set correctly');
    System.Assert.areEqual(System.UserInfo.getTimeZone().getDisplayName(), log.TimeZoneName__c, 'Timezone name should be set correctly');
  }

  static void setLoggerParamEnabled(Boolean value) {
    LoggerParameter__mdt mockParam = new LoggerParameter__mdt(
      DeveloperName = LogFlowExecutionErrorEventHandler.PARAMETER_DEV_NAME,
      Value__c = String.valueOf(value)
    );
    LoggerParameter.setMock(mockParam);
  }
}
