//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @description This test class contains several integration tests that are designed to mimic
 *              how Apex developers may want to test Nebula Logger when it's been integrated into
 *              their codebase. They are intended to be simple, lightweight tests to confirm that
 *              Nebula Logger is working within a larger codebase.
 *
 *              These tests treat Nebula Logger as a blackbox - they do not (and should not)
 *              make use of any `@TestVisible` variables or methods, and the org's
 *              custom metadata type records should all be loaded (which can help identify issues
 *              due to problematic configurations). There is also some overlap with the tests
 *              in Logger_Tests, but Logger_Tests utilizies mocks, `@TestVisible` variables, methods, etc.
 */
@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class NebulaLogger_E2E_Tests {
  @IsTest
  // static void it_uses_expected_default_settings_when_organization_is_production() {
  static void it_uses_expected_default_settings() {
    System.Assert.areEqual(0, [SELECT COUNT() FROM LoggerSettings__c]);
    LoggerSettings__c expectedSettings = (LoggerSettings__c) LoggerSettings__c.SObjectType.newSObject(null, true);
    expectedSettings.SetupOwnerId = System.UserInfo.getUserId();

    LoggerSettings__c returnedSettings = Logger.getUserSettings();

    System.Assert.areEqual(expectedSettings, returnedSettings);
    System.Assert.isNull(returnedSettings.DefaultLogOwner__c);
    System.Assert.areEqual('Delete', returnedSettings.DefaultLogPurgeAction__c);
    System.Assert.areEqual('Read', returnedSettings.DefaultLogShareAccessLevel__c);
    System.Assert.areEqual(14, returnedSettings.DefaultNumberOfDaysToRetainLogs__c);
    System.Assert.areEqual('CUSTOM_OBJECTS', returnedSettings.DefaultPlatformEventStorageLocation__c);
    System.Assert.areEqual('EVENT_BUS', returnedSettings.DefaultSaveMethod__c);
    System.Assert.isNull(returnedSettings.DefaultScenario__c);
    System.Assert.isFalse(returnedSettings.IsAnonymousModeEnabled__c);
    System.Assert.isTrue(returnedSettings.IsApexSystemDebugLoggingEnabled__c);
    System.Assert.isTrue(returnedSettings.IsDataMaskingEnabled__c);
    System.Assert.isTrue(returnedSettings.IsEnabled__c);
    System.Assert.isTrue(returnedSettings.IsJavaScriptConsoleLoggingEnabled__c);
    System.Assert.isFalse(returnedSettings.IsRecordFieldStrippingEnabled__c);
    System.Assert.isTrue(returnedSettings.IsSavingEnabled__c);
    System.Assert.areEqual(System.LoggingLevel.FINEST.name(), returnedSettings.LoggingLevel__c);
    System.Assert.areEqual(System.UserInfo.getUserId(), returnedSettings.SetupOwnerId);
  }

  @IsTest
  static void it_saves_with_default_settings() {
    System.Assert.areEqual(0, [SELECT COUNT() FROM Log__c]);
    String message = 'Some random FINEST entry';
    Logger.finest(message);

    System.Test.startTest();
    Logger.saveLog();
    System.Test.stopTest();

    System.Assert.areEqual(1, [SELECT COUNT() FROM Log__c]);
    LogEntry__c matchingLogEntry = findMatchingLogEntry(message);
    System.Assert.isNotNull(matchingLogEntry);
  }

  @IsTest
  static void it_saves_via_event_bus() {
    System.Assert.areEqual(0, [SELECT COUNT() FROM Log__c]);
    String message = 'Some random FINEST entry';
    Logger.finest(message);

    System.Test.startTest();
    Logger.saveLog(Logger.SaveMethod.EVENT_BUS);
    System.Test.stopTest();

    System.Assert.areEqual(1, [SELECT COUNT() FROM Log__c]);
    LogEntry__c matchingLogEntry = findMatchingLogEntry(message);
    System.Assert.isNotNull(matchingLogEntry);
  }

  @IsTest
  static void it_saves_via_queueable() {
    System.Assert.areEqual(0, [SELECT COUNT() FROM Log__c]);
    String message = 'Some random FINEST entry';
    Logger.finest(message);

    System.Test.startTest();
    Logger.saveLog(Logger.SaveMethod.QUEUEABLE);
    System.Test.stopTest();

    System.Assert.areEqual(1, [SELECT COUNT() FROM Log__c]);
    LogEntry__c matchingLogEntry = findMatchingLogEntry(message);
    System.Assert.isNotNull(matchingLogEntry);
  }

  @IsTest
  static void it_saves_via_rest_callout() {
    System.Assert.areEqual(0, [SELECT COUNT() FROM Log__c]);
    MockHttpCallout mockCallout = new MockHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, mockCallout);
    String message = 'Some random FINEST entry';
    LogEntryEventBuilder builder = Logger.finest(message);

    Logger.saveLog(Logger.SaveMethod.REST);

    // Since this save method relies on a standard API endpoint to create the data, there won't be any records in Log__c or LogEntry__c
    // So instead, the callout is tested
    String expectedEndpoint = System.URL.getOrgDomainUrl().toExternalForm() + '/services/data/' + getOrganizationApiVersion() + '/composite/sobjects';
    System.Assert.areEqual(expectedEndpoint, mockCallout.request.getEndpoint());
    Map<String, Object> untypedRequestBody = (Map<String, Object>) System.JSON.deserializeUntyped(mockCallout.request.getBody());
    Boolean requestAllOrNone = (Boolean) untypedRequestBody.get('allOrNone');
    System.Assert.isTrue(requestAllOrNone);
    List<LogEntryEvent__e> requestRecords = (List<LogEntryEvent__e>) System.JSON.deserialize(
      System.JSON.serialize(untypedRequestBody.get('records')),
      List<LogEntryEvent__e>.class
    );
    System.Assert.areEqual(1, requestRecords.size());
    System.Assert.areEqual(message, builder.getLogEntryEvent().Message__c);
    System.Assert.areEqual(message, requestRecords.get(0).Message__c);
  }

  // FIXME this test currently fails because custom metadata types (including LoggerSObjectHandler__mdt)
  // aren't loaded during a test context, which prevents LogEntryEventHandler from running in a BEFORE_INSERT context
  // In a future release, Nebula Logger should be updated to always load custom metadata records - Nebula Logger's own
  // tests can then be responsible for clearing any loaded records (or providing stubs) for tests that shouldn't rely
  // on the org's version of the custom metadata type records
  // Related issue: https://github.com/jongpie/NebulaLogger/issues/457
  // @IsTest
  // static void it_saves_via_synchronous_dml() {
  //     System.Assert.areEqual(0, [SELECT COUNT() FROM Log__c]);
  //     String message = 'Some random FINEST entry';
  //     Logger.finest(message);

  //     Logger.saveLog(Logger.SaveMethod.SYNCHRONOUS_DML);

  //     System.Assert.areEqual(1, [SELECT COUNT() FROM Log__c]);
  //     LogEntry__c matchingLogEntry = findMatchingLogEntry(message);
  //     System.Assert.isNotNull(matchingLogEntry);
  // }

  private static LogEntry__c findMatchingLogEntry(String message) {
    LogEntry__c matchingLogEntry;
    for (LogEntry__c logEntry : [SELECT Id, Message__c FROM LogEntry__c]) {
      if (logEntry.Message__c == message) {
        matchingLogEntry = logEntry;
        break;
      }
    }
    return matchingLogEntry;
  }

  private static String getOrganizationApiVersion() {
    // Small hack to determine the org's current API version (since Apex doesn't natively provide it)
    // Serializing any SObject w/ an ID will include the API version
    // So, use System.UserInfo.getUserId() to create the current user's record without querying
    // Then parse the JSON to get the API version
    // Expected JSON: {"attributes":{"type":"Schema.User","url":"/services/data/v53.0/sobjects/Schema.User/005J000000AugnYIAR"}
    String userJson = System.JSON.serialize(new Schema.User(Id = System.UserInfo.getUserId()));
    return userJson.substringAfter('/data/').substringBefore('/sobjects/User');
  }

  private static SObject setReadOnlyField(SObject record, Map<Schema.SObjectField, Object> changesToFields) {
    String serializedRecord = System.JSON.serialize(record);
    Map<String, Object> deserializedRecordMap = (Map<String, Object>) System.JSON.deserializeUntyped(serializedRecord);

    // Loop through the deserialized record map and put the field & value
    // Since it's a map, if the field already exists on the SObject, it's updated (or added if it wasn't there already)
    for (Schema.SObjectField sobjectField : changesToFields.keySet()) {
      String fieldName = sobjectField.getDescribe().getName();
      deserializedRecordMap.put(fieldName, changesToFields.get(sobjectField));
    }

    serializedRecord = System.JSON.serialize(deserializedRecordMap);
    return (SObject) System.JSON.deserialize(serializedRecord, SObject.class);
  }

  @SuppressWarnings('PMD.ApexDoc, PMD.EmptyStatementBlock')
  public class MockHttpCallout implements System.HttpCalloutMock {
    public System.HttpRequest request { get; private set; }
    public System.HttpResponse response { get; private set; }
    public String responseBody { get; private set; }
    public Integer statusCode { get; private set; }

    public MockHttpCallout setResponseBody(String responseBody) {
      this.responseBody = responseBody;
      return this;
    }

    public MockHttpCallout setStatusCode(Integer statusCode) {
      this.statusCode = statusCode;
      return this;
    }

    public System.HttpResponse respond(System.HttpRequest request) {
      this.request = request;

      this.response = new System.HttpResponse();
      if (String.isNotBlank(this.responseBody)) {
        response.setBody(this.responseBody);
      }
      response.setStatusCode(this.statusCode);
      return response;
    }
  }
}
