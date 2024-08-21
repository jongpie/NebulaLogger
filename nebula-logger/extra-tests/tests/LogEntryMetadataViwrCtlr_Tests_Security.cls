//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

// The class being tested - LogEntryMetadataViewerController - has a very long name
// This test class name is slightly different from the typical naming convention used
// in Nebula Logger, because the name would be too long 😭
@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=false)
private class LogEntryMetadataViwrCtlr_Tests_Security {
  private static final String CAN_VIEW_LOG_ENTRY_METADATA_PERMISSION_NAME = 'CanViewLogEntryMetadata';
  private static final MockLogManagementDataSelector MOCK_SELECTOR = new MockLogManagementDataSelector();
  private static final Schema.Profile MINIMUM_ACCESS_PROFILE = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce'];

  static {
    LogManagementDataSelector.setMock(MOCK_SELECTOR);
  }

  @IsTest
  static void it_should_return_queried_exception_metadata_when_custom_permission_is_assigned() {
    Schema.User minimumAccessUser = LoggerMockDataCreator.createUser(MINIMUM_ACCESS_PROFILE.Id);
    insert minimumAccessUser;
    Schema.PermissionSet permissionSet = new Schema.PermissionSet(Name = 'CustomPermissionEnabled', Label = 'Custom Permisison Enabled');
    insert permissionSet;
    SetupEntityAccess setupEntityAccess = new SetupEntityAccess(
      ParentId = permissionSet.Id,
      SetupEntityId = [SELECT Id FROM CustomPermission WHERE DeveloperName = :CAN_VIEW_LOG_ENTRY_METADATA_PERMISSION_NAME]
      .Id
    );
    Schema.PermissionSetAssignment permissionSetAssignment = new Schema.PermissionSetAssignment(
      AssigneeId = minimumAccessUser.Id,
      PermissionSetId = permissionSet.Id
    );
    insert new List<SObject>{ setupEntityAccess, permissionSetAssignment };
    String sourceMetadata = 'Exception';
    Schema.ApexClass mockApexClass = new Schema.ApexClass(Body = 'hello, world', Name = 'SomeApexClassName');
    MOCK_SELECTOR.setMockApexClass(mockApexClass);
    LogEntry__c mockLogEntry = new LogEntry__c(
      ExceptionSourceApiName__c = mockApexClass.Name,
      ExceptionSourceMetadataType__c = 'ApexClass',
      Id = LoggerMockDataCreator.createId(LogEntry__c.SObjectType)
    );
    MOCK_SELECTOR.setMockLogEntry(mockLogEntry);
    LogEntryMetadataViewerController.LogEntryMetadata returnedMetadata;

    System.runAs(minimumAccessUser) {
      System.Assert.isFalse(Schema.ApexClass.SObjectType.getDescribe().isAccessible());
      System.Assert.isTrue(System.FeatureManagement.checkPermission(CAN_VIEW_LOG_ENTRY_METADATA_PERMISSION_NAME));
      returnedMetadata = LogEntryMetadataViewerController.getMetadata(mockLogEntry.Id, sourceMetadata);
    }

    System.Assert.areEqual(mockApexClass.Body, returnedMetadata.Code);
  }

  @IsTest
  static void it_should_return_queried_origin_metadata_when_custom_permission_is_assigned() {
    Schema.User minimumAccessUser = LoggerMockDataCreator.createUser(MINIMUM_ACCESS_PROFILE.Id);
    insert minimumAccessUser;
    Schema.PermissionSet permissionSet = new Schema.PermissionSet(Name = 'CustomPermissionEnabled', Label = 'Custom Permisison Enabled');
    insert permissionSet;
    SetupEntityAccess setupEntityAccess = new SetupEntityAccess(
      ParentId = permissionSet.Id,
      SetupEntityId = [SELECT Id FROM CustomPermission WHERE DeveloperName = :CAN_VIEW_LOG_ENTRY_METADATA_PERMISSION_NAME]
      .Id
    );
    Schema.PermissionSetAssignment permissionSetAssignment = new Schema.PermissionSetAssignment(
      AssigneeId = minimumAccessUser.Id,
      PermissionSetId = permissionSet.Id
    );
    insert new List<SObject>{ setupEntityAccess, permissionSetAssignment };
    String sourceMetadata = 'Origin';
    Schema.ApexClass mockApexClass = new Schema.ApexClass(Body = 'hello, world', Name = 'SomeApexClassName');
    MOCK_SELECTOR.setMockApexClass(mockApexClass);
    LogEntry__c mockLogEntry = new LogEntry__c(
      Id = LoggerMockDataCreator.createId(LogEntry__c.SObjectType),
      OriginSourceApiName__c = mockApexClass.Name,
      OriginSourceMetadataType__c = 'ApexClass'
    );
    MOCK_SELECTOR.setMockLogEntry(mockLogEntry);
    LogEntryMetadataViewerController.LogEntryMetadata returnedMetadata;

    System.runAs(minimumAccessUser) {
      System.Assert.isFalse(Schema.ApexClass.SObjectType.getDescribe().isAccessible());
      System.Assert.isTrue(System.FeatureManagement.checkPermission(CAN_VIEW_LOG_ENTRY_METADATA_PERMISSION_NAME));
      returnedMetadata = LogEntryMetadataViewerController.getMetadata(mockLogEntry.Id, sourceMetadata);
    }

    System.Assert.areEqual(mockApexClass.Body, returnedMetadata.Code);
  }

  @IsTest
  static void it_should_not_return_queried_exception_metadata_when_custom_permission_is_not_assigned() {
    Schema.User minimumAccessUser = LoggerMockDataCreator.createUser(MINIMUM_ACCESS_PROFILE.Id);
    insert minimumAccessUser;
    String sourceMetadata = 'Exception';
    Schema.ApexClass mockApexClass = new Schema.ApexClass(Body = 'hello, world', Name = 'SomeApexClassName');
    MOCK_SELECTOR.setMockApexClass(mockApexClass);
    LogEntry__c mockLogEntry = new LogEntry__c(
      ExceptionSourceApiName__c = mockApexClass.Name,
      ExceptionSourceMetadataType__c = 'ApexClass',
      Id = LoggerMockDataCreator.createId(LogEntry__c.SObjectType)
    );
    MOCK_SELECTOR.setMockLogEntry(mockLogEntry);
    LogEntryMetadataViewerController.LogEntryMetadata returnedMetadata;

    System.runAs(minimumAccessUser) {
      System.Assert.isFalse(Schema.ApexClass.SObjectType.getDescribe().isAccessible());
      System.Assert.isFalse(System.FeatureManagement.checkPermission(CAN_VIEW_LOG_ENTRY_METADATA_PERMISSION_NAME));
      returnedMetadata = LogEntryMetadataViewerController.getMetadata(mockLogEntry.Id, sourceMetadata);
    }

    System.Assert.isNull(returnedMetadata.Code);
  }

  @IsTest
  static void it_should_not_return_queried_origin_metadata_when_custom_permission_is_not_assigned() {
    Schema.User minimumAccessUser = LoggerMockDataCreator.createUser(MINIMUM_ACCESS_PROFILE.Id);
    insert minimumAccessUser;
    String sourceMetadata = 'Origin';
    Schema.ApexClass mockApexClass = new Schema.ApexClass(Body = 'hello, world', Name = 'SomeApexClassName');
    MOCK_SELECTOR.setMockApexClass(mockApexClass);
    LogEntry__c mockLogEntry = new LogEntry__c(
      Id = LoggerMockDataCreator.createId(LogEntry__c.SObjectType),
      OriginSourceApiName__c = mockApexClass.Name,
      OriginSourceMetadataType__c = 'ApexClass'
    );
    MOCK_SELECTOR.setMockLogEntry(mockLogEntry);
    LogEntryMetadataViewerController.LogEntryMetadata returnedMetadata;

    System.runAs(minimumAccessUser) {
      System.Assert.isFalse(Schema.ApexClass.SObjectType.getDescribe().isAccessible());
      System.Assert.isFalse(System.FeatureManagement.checkPermission(CAN_VIEW_LOG_ENTRY_METADATA_PERMISSION_NAME));
      returnedMetadata = LogEntryMetadataViewerController.getMetadata(mockLogEntry.Id, sourceMetadata);
    }

    System.Assert.isNull(returnedMetadata.Code);
  }

  @IsTest
  static void it_should_return_queried_metadata_when_loggerAdmin_permission_set_is_assigned() {
    Schema.User minimumAccessUser = LoggerMockDataCreator.createUser(MINIMUM_ACCESS_PROFILE.Id);
    insert minimumAccessUser;
    LoggerTestConfigurator.assignAdminPermissionSet(minimumAccessUser.Id);
    String sourceMetadata = 'Exception';
    Schema.ApexClass mockApexClass = new Schema.ApexClass(Body = 'hello, world', Name = 'SomeApexClassName');
    MOCK_SELECTOR.setMockApexClass(mockApexClass);
    LogEntry__c mockLogEntry = new LogEntry__c(
      ExceptionSourceApiName__c = mockApexClass.Name,
      ExceptionSourceMetadataType__c = 'ApexClass',
      Id = LoggerMockDataCreator.createId(LogEntry__c.SObjectType)
    );
    MOCK_SELECTOR.setMockLogEntry(mockLogEntry);
    LogEntryMetadataViewerController.LogEntryMetadata returnedMetadata;

    System.runAs(minimumAccessUser) {
      System.Assert.isFalse(Schema.ApexClass.SObjectType.getDescribe().isAccessible());
      System.Assert.isTrue(System.FeatureManagement.checkPermission(CAN_VIEW_LOG_ENTRY_METADATA_PERMISSION_NAME));
      returnedMetadata = LogEntryMetadataViewerController.getMetadata(mockLogEntry.Id, sourceMetadata);
    }

    System.Assert.areEqual(mockApexClass.Body, returnedMetadata.Code);
  }

  @IsTest
  static void it_should_not_return_queried_origin_metadata_when_loggerLogViewer_permission_set_is_assigned() {
    Schema.User minimumAccessUser = LoggerMockDataCreator.createUser(MINIMUM_ACCESS_PROFILE.Id);
    insert minimumAccessUser;
    LoggerTestConfigurator.assignLogViewerPermissionSet(minimumAccessUser.Id);
    String sourceMetadata = 'Origin';
    Schema.ApexClass mockApexClass = new Schema.ApexClass(Body = 'hello, world', Name = 'SomeApexClassName');
    MOCK_SELECTOR.setMockApexClass(mockApexClass);
    LogEntry__c mockLogEntry = new LogEntry__c(
      Id = LoggerMockDataCreator.createId(LogEntry__c.SObjectType),
      OriginSourceApiName__c = mockApexClass.Name,
      OriginSourceMetadataType__c = 'ApexClass'
    );
    MOCK_SELECTOR.setMockLogEntry(mockLogEntry);
    LogEntryMetadataViewerController.LogEntryMetadata returnedMetadata;

    System.runAs(minimumAccessUser) {
      System.Assert.isFalse(Schema.ApexClass.SObjectType.getDescribe().isAccessible());
      System.Assert.isFalse(System.FeatureManagement.checkPermission(CAN_VIEW_LOG_ENTRY_METADATA_PERMISSION_NAME));
      returnedMetadata = LogEntryMetadataViewerController.getMetadata(mockLogEntry.Id, sourceMetadata);
    }

    System.Assert.isNull(returnedMetadata.Code);
  }

  @IsTest
  static void it_should_not_return_queried_origin_metadata_when_loggerEndUser_permission_set_is_assigned() {
    Schema.User minimumAccessUser = LoggerMockDataCreator.createUser(MINIMUM_ACCESS_PROFILE.Id);
    insert minimumAccessUser;
    LoggerTestConfigurator.assignEndUserPermissionSet(minimumAccessUser.Id);
    String sourceMetadata = 'Origin';
    Schema.ApexClass mockApexClass = new Schema.ApexClass(Body = 'hello, world', Name = 'SomeApexClassName');
    MOCK_SELECTOR.setMockApexClass(mockApexClass);
    LogEntry__c mockLogEntry = new LogEntry__c(
      Id = LoggerMockDataCreator.createId(LogEntry__c.SObjectType),
      OriginSourceApiName__c = mockApexClass.Name,
      OriginSourceMetadataType__c = 'ApexClass'
    );
    MOCK_SELECTOR.setMockLogEntry(mockLogEntry);
    LogEntryMetadataViewerController.LogEntryMetadata returnedMetadata;

    System.runAs(minimumAccessUser) {
      System.Assert.isFalse(Schema.ApexClass.SObjectType.getDescribe().isAccessible());
      System.Assert.isFalse(System.FeatureManagement.checkPermission(CAN_VIEW_LOG_ENTRY_METADATA_PERMISSION_NAME));
      returnedMetadata = LogEntryMetadataViewerController.getMetadata(mockLogEntry.Id, sourceMetadata);
    }

    System.Assert.isNull(returnedMetadata.Code);
  }

  @IsTest
  static void it_should_not_return_queried_origin_metadata_when_loggerLogCreator_permission_set_is_assigned() {
    Schema.User minimumAccessUser = LoggerMockDataCreator.createUser(MINIMUM_ACCESS_PROFILE.Id);
    insert minimumAccessUser;
    LoggerTestConfigurator.assignLogCreatorPermissionSet(minimumAccessUser.Id);
    String sourceMetadata = 'Origin';
    Schema.ApexClass mockApexClass = new Schema.ApexClass(Body = 'hello, world', Name = 'SomeApexClassName');
    MOCK_SELECTOR.setMockApexClass(mockApexClass);
    LogEntry__c mockLogEntry = new LogEntry__c(
      Id = LoggerMockDataCreator.createId(LogEntry__c.SObjectType),
      OriginSourceApiName__c = mockApexClass.Name,
      OriginSourceMetadataType__c = 'ApexClass'
    );
    MOCK_SELECTOR.setMockLogEntry(mockLogEntry);
    LogEntryMetadataViewerController.LogEntryMetadata returnedMetadata;

    System.runAs(minimumAccessUser) {
      System.Assert.isFalse(Schema.ApexClass.SObjectType.getDescribe().isAccessible());
      System.Assert.isFalse(System.FeatureManagement.checkPermission(CAN_VIEW_LOG_ENTRY_METADATA_PERMISSION_NAME));
      returnedMetadata = LogEntryMetadataViewerController.getMetadata(mockLogEntry.Id, sourceMetadata);
    }

    System.Assert.isNull(returnedMetadata.Code);
  }

  private class MockLogManagementDataSelector extends LogManagementDataSelector {
    private Schema.ApexClass mockApexClass;
    private LogEntry__c mockLogEntry;

    public override List<Schema.ApexClass> getApexClasses(Set<String> apexClassNames) {
      return new List<Schema.ApexClass>{ this.mockApexClass };
    }

    public override LogEntry__c getLogEntryById(Id logEntryId) {
      return this.mockLogEntry;
    }

    public void setMockApexClass(Schema.ApexClass apexClass) {
      this.mockApexClass = apexClass;
    }

    public void setMockLogEntry(LogEntry__c logEntry) {
      this.mockLogEntry = logEntry;
    }
  }
}
