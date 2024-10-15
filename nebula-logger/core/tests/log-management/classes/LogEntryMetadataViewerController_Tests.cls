@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest
private class LogEntryMetadataViewerController_Tests {
  private static final MockLogManagementDataSelector MOCK_SELECTOR = new MockLogManagementDataSelector();
  private static final String SOURCE_METADATA_EXCEPTION = 'Exception';
  private static final String SOURCE_METADATA_ORIGIN = 'Origin';

  static {
    // Don't use the org's actual custom metadata records when running tests
    LoggerConfigurationDataSelector.useMocks();
    LogManagementDataSelector.setMock(MOCK_SELECTOR);
  }

  @IsTest
  static void it_returns_apex_class_metadata_for_log_entry_when_source_metadata_is_exception() {
    Schema.ApexClass mockExceptionApexClass = createMockApexClass('Some_Fake_Apex_Class');
    System.Assert.isNotNull(mockExceptionApexClass.Name);
    MOCK_SELECTOR.setMockApexClass(mockExceptionApexClass);
    LogEntry__c mockLogEntry = createMockLogEntry(null, mockExceptionApexClass);
    System.Assert.areEqual(mockExceptionApexClass.Name, mockLogEntry.ExceptionSourceApiName__c);
    System.Assert.isNull(mockLogEntry.OriginSourceApiName__c);
    MOCK_SELECTOR.setMockLogEntry(mockLogEntry);

    LogEntryMetadataViewerController.LogEntryMetadata logEntryMetadata = LogEntryMetadataViewerController.getMetadata(
      mockLogEntry.Id,
      SOURCE_METADATA_EXCEPTION
    );

    System.Assert.areEqual(mockExceptionApexClass.Body, logEntryMetadata.Code);
    System.Assert.isFalse(logEntryMetadata.HasCodeBeenModified);
  }

  @IsTest
  static void it_returns_apex_trigger_metadata_for_log_entry_when_source_metadata_is_exception() {
    Schema.ApexTrigger mockExceptionApexTrigger = createMockApexTrigger('Some_Fake_Apex_Trigger');
    System.Assert.isNotNull(mockExceptionApexTrigger.Name);
    MOCK_SELECTOR.setMockApexTrigger(mockExceptionApexTrigger);
    LogEntry__c mockLogEntry = createMockLogEntry(null, mockExceptionApexTrigger);
    System.Assert.areEqual(mockExceptionApexTrigger.Name, mockLogEntry.ExceptionSourceApiName__c);
    System.Assert.isNull(mockLogEntry.OriginSourceApiName__c);
    MOCK_SELECTOR.setMockLogEntry(mockLogEntry);

    LogEntryMetadataViewerController.LogEntryMetadata logEntryMetadata = LogEntryMetadataViewerController.getMetadata(
      mockLogEntry.Id,
      SOURCE_METADATA_EXCEPTION
    );

    System.Assert.areEqual(mockExceptionApexTrigger.Body, logEntryMetadata.Code);
    System.Assert.isFalse(logEntryMetadata.HasCodeBeenModified);
  }

  @IsTest
  static void it_indicates_when_exception_source_metadata_has_been_modified_after_log_entry_timestamp() {
    Schema.ApexClass mockExceptionApexClass = createMockApexClass('Some_Fake_Apex_Class');
    System.Assert.isNotNull(mockExceptionApexClass.Name);
    MOCK_SELECTOR.setMockApexClass(mockExceptionApexClass);
    LogEntry__c mockLogEntry = createMockLogEntry(null, mockExceptionApexClass);
    mockLogEntry.Timestamp__c = mockExceptionApexClass.LastModifiedDate.addDays(-1);
    System.Assert.areEqual(mockExceptionApexClass.Name, mockLogEntry.ExceptionSourceApiName__c);
    System.Assert.isNull(mockLogEntry.OriginSourceApiName__c);
    MOCK_SELECTOR.setMockLogEntry(mockLogEntry);

    LogEntryMetadataViewerController.LogEntryMetadata logEntryMetadata = LogEntryMetadataViewerController.getMetadata(
      mockLogEntry.Id,
      SOURCE_METADATA_EXCEPTION
    );

    System.Assert.areEqual(mockExceptionApexClass.Body, logEntryMetadata.Code);
    System.Assert.isTrue(logEntryMetadata.HasCodeBeenModified);
  }

  @IsTest
  static void it_returns_apex_class_metadata_for_log_entry_when_source_metadata_is_origin() {
    Schema.ApexClass mockOriginSourceApexClass = createMockApexClass('Some_Fake_Apex_Class');
    System.Assert.isNotNull(mockOriginSourceApexClass.Name);
    MOCK_SELECTOR.setMockApexClass(mockOriginSourceApexClass);
    LogEntry__c mockLogEntry = createMockLogEntry(mockOriginSourceApexClass, null);
    System.Assert.isNull(mockLogEntry.ExceptionSourceApiName__c);
    System.Assert.areEqual(mockOriginSourceApexClass.Name, mockLogEntry.OriginSourceApiName__c);
    MOCK_SELECTOR.setMockLogEntry(mockLogEntry);

    LogEntryMetadataViewerController.LogEntryMetadata logEntryMetadata = LogEntryMetadataViewerController.getMetadata(mockLogEntry.Id, SOURCE_METADATA_ORIGIN);

    System.Assert.areEqual(mockOriginSourceApexClass.Body, logEntryMetadata.Code);
    System.Assert.isFalse(logEntryMetadata.HasCodeBeenModified);
  }

  @IsTest
  static void it_indicates_when_origin_source_metadata_has_been_modified_after_log_entry_timestamp() {
    Schema.ApexClass mockOriginSourceApexClass = createMockApexClass('Some_Fake_Apex_Class');
    System.Assert.isNotNull(mockOriginSourceApexClass.Name);
    MOCK_SELECTOR.setMockApexClass(mockOriginSourceApexClass);
    LogEntry__c mockLogEntry = createMockLogEntry(mockOriginSourceApexClass, null);
    mockLogEntry.Timestamp__c = mockOriginSourceApexClass.LastModifiedDate.addDays(-1);
    System.Assert.isNull(mockLogEntry.ExceptionSourceApiName__c);
    System.Assert.areEqual(mockOriginSourceApexClass.Name, mockLogEntry.OriginSourceApiName__c);
    MOCK_SELECTOR.setMockLogEntry(mockLogEntry);

    LogEntryMetadataViewerController.LogEntryMetadata logEntryMetadata = LogEntryMetadataViewerController.getMetadata(mockLogEntry.Id, SOURCE_METADATA_ORIGIN);

    System.Assert.areEqual(mockOriginSourceApexClass.Body, logEntryMetadata.Code);
    System.Assert.isTrue(logEntryMetadata.HasCodeBeenModified);
  }

  private static LogEntry__c createMockLogEntry(Schema.ApexClass originApexClass, Schema.ApexClass exceptionApexClass) {
    LogEntry__c mockLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType).populateRequiredFields().getRecord();
    mockLogEntry.ExceptionSourceApiName__c = exceptionApexClass?.Name;
    mockLogEntry.ExceptionSourceMetadataType__c = exceptionApexClass == null ? null : LoggerStackTrace.SourceMetadataType.ApexClass.name();
    mockLogEntry.OriginSourceApiName__c = originApexClass?.Name;
    mockLogEntry.OriginSourceMetadataType__c = originApexClass == null ? null : LoggerStackTrace.SourceMetadataType.ApexClass.name();
    mockLogEntry.Timestamp__c = System.now();
    return mockLogEntry;
  }

  private static LogEntry__c createMockLogEntry(Schema.ApexTrigger originApexTrigger, Schema.ApexTrigger exceptionApexTrigger) {
    LogEntry__c mockLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType).populateRequiredFields().getRecord();
    mockLogEntry.ExceptionSourceApiName__c = exceptionApexTrigger?.Name;
    mockLogEntry.ExceptionSourceMetadataType__c = exceptionApexTrigger == null ? null : LoggerStackTrace.SourceMetadataType.ApexTrigger.name();
    mockLogEntry.OriginSourceApiName__c = originApexTrigger?.Name;
    mockLogEntry.OriginSourceMetadataType__c = originApexTrigger == null ? null : LoggerStackTrace.SourceMetadataType.ApexTrigger.name();
    mockLogEntry.Timestamp__c = System.now();
    return mockLogEntry;
  }

  private static Schema.ApexClass createMockApexClass(String mockApexClassName) {
    Schema.ApexClass mockApexClass = new Schema.ApexClass(
      Body = 'Wow, look at this code for a mock version of apex class ' + mockApexClassName,
      Name = mockApexClassName
    );
    return (Schema.ApexClass) LoggerMockDataCreator.setReadOnlyField(mockApexClass, Schema.ApexClass.LastModifiedDate, System.now().addDays(-7));
  }

  private static Schema.ApexTrigger createMockApexTrigger(String mockApexTriggerName) {
    Schema.ApexTrigger mockApexTrigger = new Schema.ApexTrigger(
      Body = 'Wow, look at this code for a mock version of apex trigger ' + mockApexTriggerName,
      Name = mockApexTriggerName
    );
    return (Schema.ApexTrigger) LoggerMockDataCreator.setReadOnlyField(mockApexTrigger, Schema.ApexTrigger.LastModifiedDate, System.now().addDays(-7));
  }

  // LogEntryMetadataViewerController uses a few queries via LogManagementDataSelector - this class mocks the query results
  private class MockLogManagementDataSelector extends LogManagementDataSelector {
    private Schema.ApexClass mockApexClass;
    private Schema.ApexTrigger mockApexTrigger;
    private LogEntry__c mockLogEntry;

    public override List<Schema.ApexClass> getApexClasses(Set<String> apexClassNames) {
      return new List<Schema.ApexClass>{ this.mockApexClass };
    }

    public override List<Schema.ApexTrigger> getApexTriggers(Set<String> apexTriggerNames) {
      return new List<Schema.ApexTrigger>{ this.mockApexTrigger };
    }

    public override LogEntry__c getLogEntryById(Id logEntryId) {
      return this.mockLogEntry;
    }

    public void setMockApexClass(Schema.ApexClass apexClass) {
      this.mockApexClass = apexClass;
    }

    public void setMockApexTrigger(Schema.ApexTrigger apexTrigger) {
      this.mockApexTrigger = apexTrigger;
    }

    public void setMockLogEntry(LogEntry__c logEntry) {
      this.mockLogEntry = logEntry;
    }
  }
}
