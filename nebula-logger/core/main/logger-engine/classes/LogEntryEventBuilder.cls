//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Builder class that generates each `LogEntryEvent__e` record
 * @see Logger
 */
@SuppressWarnings(
  'PMD.AvoidGlobalModifier, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessiveClassLength, PMD.ExcessivePublicCount, PMD.NcssTypeCount, PMD.PropertyNamingConventions, PMD.StdCyclomaticComplexity'
)
global with sharing class LogEntryEventBuilder {
  public static final String ENTRY_SAVE_REASON_LOGGING_LEVEL_MET = 'Logging Level Met';
  public static final String ENTRY_SAVE_REASON_OVERRIDE = 'Save Overridden';

  private static final Map<String, String> CACHED_SOBJECT_NAME_TO_CLASSIFICATION = new Map<String, String>();
  private static final Schema.User CURRENT_USER = new Schema.User(Id = System.UserInfo.getUserId(), ProfileId = System.UserInfo.getProfileId());
  private static final String HTTP_HEADER_FORMAT = '{0}: {1}';
  private static final String NEW_LINE_DELIMITER = '\n';

  private static String cachedOrganizationEnvironmentType;

  @TestVisible
  private static Id networkId = System.Network.getNetworkId();

  private final LogEntryEvent__e logEntryEvent;
  private final System.LoggingLevel entryLoggingLevel;
  private final String organizationEnvironmentType;
  private final LoggerSettings__c userSettings;

  @TestVisible
  private String debugMessage = '';
  private Boolean detailsAreSet = false;
  private Boolean shouldSave;
  private Set<String> tags = new Set<String>();
  private Boolean tagDetailsAreSet = true;

  private static final LoggerSObjectProxy.AuthSession CACHED_AUTH_SESSION_PROXY {
    get {
      if (CACHED_AUTH_SESSION_PROXY == null) {
        CACHED_AUTH_SESSION_PROXY = LoggerEngineDataSelector.getInstance().getCachedAuthSessionProxy();
      }
      return CACHED_AUTH_SESSION_PROXY;
    }
    set;
  }

  private static final Map<String, LogEntryDataMaskRule__mdt> CACHED_DATA_MASK_RULES {
    get {
      if (CACHED_DATA_MASK_RULES == null) {
        CACHED_DATA_MASK_RULES = loadDataMaskRules();
      }
      return CACHED_DATA_MASK_RULES;
    }
    set;
  }

  private static final LoggerSObjectProxy.Network CACHED_NETWORK_PROXY {
    get {
      if (CACHED_NETWORK_PROXY == null) {
        CACHED_NETWORK_PROXY = LoggerEngineDataSelector.getInstance().getCachedNetworkProxy(networkId);
      }
      return CACHED_NETWORK_PROXY;
    }
    set;
  }

  private static final Schema.Organization CACHED_ORGANIZATION {
    get {
      if (CACHED_ORGANIZATION == null) {
        CACHED_ORGANIZATION = LoggerEngineDataSelector.getInstance().getCachedOrganization();
      }
      return CACHED_ORGANIZATION;
    }
    set;
  }

  private static final TransactionLimits CACHED_TRANSACTION_LIMITS {
    get {
      if (CACHED_TRANSACTION_LIMITS == null) {
        CACHED_TRANSACTION_LIMITS = new TransactionLimits();
      }
      return CACHED_TRANSACTION_LIMITS;
    }
    set;
  }

  private static final Schema.User CACHED_USER {
    get {
      if (CACHED_USER == null) {
        CACHED_USER = LoggerEngineDataSelector.getInstance().getCachedUser();
      }
      return CACHED_USER;
    }
    set;
  }

  private static final String NAMESPACE_PREFIX {
    get {
      if (NAMESPACE_PREFIX == null) {
        NAMESPACE_PREFIX = getNamespacePrefix();
      }
      return NAMESPACE_PREFIX;
    }
    set;
  }

  private static final Map<String, String> SOBJECT_SUFFIX_TO_CLASSIFICATION {
    get {
      if (SOBJECT_SUFFIX_TO_CLASSIFICATION == null) {
        SOBJECT_SUFFIX_TO_CLASSIFICATION = getSObjectSuffixToClassification();
      }
      return SOBJECT_SUFFIX_TO_CLASSIFICATION;
    }
    set;
  }

  /**
   * @description Used by `Logger` to instantiate a new instance of `LogEntryEventBuilder`
   * @param  userSettings      The instance of `LoggerSettings__c` for the current to use to control any feature flags
   * @param  entryLoggingLevel The `LoggingLevel` value to use for the log entry
   * @param  shouldSave        Indicates if the builder's instance of `LogEntryEvent__e` should be saved
   */
  @SuppressWarnings('PMD.NcssConstructorCount')
  public LogEntryEventBuilder(LoggerSettings__c userSettings, System.LoggingLevel entryLoggingLevel, Boolean shouldSave) {
    this.shouldSave = shouldSave;
    if (this.shouldSave()) {
      this.userSettings = userSettings;
      this.entryLoggingLevel = entryLoggingLevel;

      this.logEntryEvent = getLogEntryEventTemplate(entryLoggingLevel);
      this.setSaveReason();
      this.setTimestamp(System.now());
    }
  }

  /**
   * @description Sets the log entry event's message field
   * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
   * @return            The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setMessage(LogMessage logMessage) {
    if (this.shouldSave() == false && System.Test.isRunningTest() == false || logMessage == null) {
      return this;
    }

    return this.setMessage(logMessage.getMessage());
  }

  /**
   * @description Sets the log entry event's message field
   * @param  message The string to use to set the entry's message field
   * @return         The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setMessage(String message) {
    // To help with debugging unit tests, always run System.debug statement in a test context
    if ((this.shouldSave() || System.Test.isRunningTest()) && this.logEntryEvent != null) {
      TextFieldValueCleaner textCleaner = new TextFieldValueCleaner(this.userSettings, Schema.LogEntryEvent__e.Message__c, message);

      this.logEntryEvent.Message__c = textCleaner.textValue;
      this.logEntryEvent.MessageMasked__c = textCleaner.wasMasked;
      this.logEntryEvent.MessageTruncated__c = textCleaner.wasTruncated;
      this.logToApexDebug(message);
    }
    return this;
  }

  /**
   * @description Sets the log entry event's exception fields
   * @param  apexException The instance of an `System.Exception` to use.
   * @return               The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setExceptionDetails(System.Exception apexException) {
    if (this.shouldSave() == false || apexException == null) {
      return this;
    }

    this.logEntryEvent.ExceptionMessage__c = LoggerDataStore.truncateFieldValue(Schema.LogEntryEvent__e.ExceptionMessage__c, apexException.getMessage());
    this.logEntryEvent.ExceptionType__c = apexException.getTypeName();

    LoggerStackTrace exceptionStackTrace = new LoggerStackTrace(apexException);
    this.logEntryEvent.ExceptionLocation__c = exceptionStackTrace.Location;
    this.logEntryEvent.ExceptionSourceActionName__c = exceptionStackTrace.Source?.ActionName;
    this.logEntryEvent.ExceptionSourceApiName__c = exceptionStackTrace.Source?.ApiName;
    this.logEntryEvent.ExceptionSourceMetadataType__c = exceptionStackTrace.Source?.MetadataType.name();
    this.logEntryEvent.ExceptionStackTrace__c = LoggerDataStore.truncateFieldValue(
      Schema.LogEntryEvent__e.ExceptionStackTrace__c,
      exceptionStackTrace.ParsedStackTraceString
    );

    return this;
  }

  // Approval-result builder methods. All of these methods re-use the DatabaseResult* fields,
  // since these are still sort of DML results, and at least at this time, it's not worth introducing
  // brand new fields just for approval results.

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  lockResult The instance of `Approval.LockResult` to log
   * @return            The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setApprovalResult(Approval.LockResult lockResult) {
    return this.setDatabaseDetails(new List<Approval.LockResult>{ lockResult }, Approval.LockResult.class, lockResult?.getId());
  }

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  processResult The instance of `Approval.ProcessResult` to log
   * @return               The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setApprovalResult(Approval.ProcessResult processResult) {
    return this.setDatabaseDetails(new List<Approval.ProcessResult>{ processResult }, Approval.ProcessResult.class, processResult?.getEntityId());
  }

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  unlockResult The instance of `Approval.UnlockResult` to log
   * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setApprovalResult(Approval.UnlockResult unlockResult) {
    return this.setDatabaseDetails(new List<Approval.UnlockResult>{ unlockResult }, Approval.UnlockResult.class, unlockResult?.getId());
  }

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  lockResults The list of `Approval.LockResult` instances to log
   * @return             The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setApprovalResult(List<Approval.LockResult> lockResults) {
    return this.setDatabaseDetails(lockResults, Approval.LockResult.class, null);
  }

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  processResults The list of `Approval.ProcessResult` instances to log
   * @return                The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setApprovalResult(List<Approval.ProcessResult> processResults) {
    return this.setDatabaseDetails(processResults, Approval.ProcessResult.class, null);
  }

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  unlockResults The list of `Approval.UnlockResult` instances to log
   * @return               The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setApprovalResult(List<Approval.UnlockResult> unlockResults) {
    return this.setDatabaseDetails(unlockResults, Approval.UnlockResult.class, null);
  }

  // DML-result builder methods. All* of the Result classes behave the same (*except Upsert)
  // but Salesforce didn't bother to use an interface for the classes, so instead - overloads!

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  deleteResult The instance of `Database.DeleteResult` to log
   * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setDatabaseResult(Database.DeleteResult deleteResult) {
    return this.setDatabaseDetails(new List<Database.DeleteResult>{ deleteResult }, Database.DeleteResult.class, deleteResult?.getId());
  }

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  emptyRecycleBinResult The instance of `Database.EmptyRecycleBinResult` to log
   * @return                       The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setDatabaseResult(Database.EmptyRecycleBinResult emptyRecycleBinResult) {
    return this.setDatabaseDetails(
      new List<Database.EmptyRecycleBinResult>{ emptyRecycleBinResult },
      Database.EmptyRecycleBinResult.class,
      emptyRecycleBinResult?.getId()
    );
  }

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
   * @return                   The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setDatabaseResult(Database.LeadConvertResult leadConvertResult) {
    return this.setDatabaseDetails(new List<Database.LeadConvertResult>{ leadConvertResult }, Database.LeadConvertResult.class, leadConvertResult?.getLeadId());
  }

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  mergeResult The instance of `Database.MergeResult` to log
   * @return             The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setDatabaseResult(Database.MergeResult mergeResult) {
    return this.setDatabaseDetails(new List<Database.MergeResult>{ mergeResult }, Database.MergeResult.class, mergeResult?.getId());
  }

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  saveResult The instance of `Database.SaveResult` to log
   * @return            The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setDatabaseResult(Database.SaveResult saveResult) {
    return this.setDatabaseDetails(new List<Database.SaveResult>{ saveResult }, Database.SaveResult.class, saveResult?.getId());
  }

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  upsertResult The instance of `Database.UpsertResult` to log
   * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setDatabaseResult(Database.UpsertResult upsertResult) {
    this.setDatabaseDetails(new List<Database.UpsertResult>{ upsertResult }, Database.UpsertResult.class, upsertResult?.getId());
    if (upsertResult != null) {
      String subtype = upsertResult.isCreated() ? 'Insert' : 'Update';
      this.logEntryEvent.DatabaseResultType__c += '.' + subtype;
    }
    return this;
  }

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  undeleteResult The instance of `Database.UndeleteResult` to log
   * @return                The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setDatabaseResult(Database.UndeleteResult undeleteResult) {
    return this.setDatabaseDetails(new List<Database.UndeleteResult>{ undeleteResult }, Database.UndeleteResult.class, undeleteResult?.getId());
  }

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  deleteResults The list of `Database.DeleteResult` instances to log
   * @return               The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setDatabaseResult(List<Database.DeleteResult> deleteResults) {
    return this.setDatabaseDetails(deleteResults, Database.DeleteResult.class, null);
  }

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  emptyRecycleBinResults The list of `Database.EmptyRecycleBinResult` instances to log
   * @return                        The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setDatabaseResult(List<Database.EmptyRecycleBinResult> emptyRecycleBinResults) {
    return this.setDatabaseDetails(emptyRecycleBinResults, Database.EmptyRecycleBinResult.class, null);
  }

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  leadConvertResults The list of `Database.LeadConvertResult`s to log
   * @return                    The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setDatabaseResult(List<Database.LeadConvertResult> leadConvertResults) {
    return this.setDatabaseDetails(leadConvertResults, Database.LeadConvertResult.class, null);
  }

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  mergeResults The list of `Database.MergeResult` instances to log
   * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setDatabaseResult(List<Database.MergeResult> mergeResults) {
    return this.setDatabaseDetails(mergeResults, Database.MergeResult.class, null);
  }

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  saveResults The list of `Database.SaveResult` instances to log
   * @return             The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setDatabaseResult(List<Database.SaveResult> saveResults) {
    return this.setDatabaseDetails(saveResults, Database.SaveResult.class, null);
  }

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  upsertResults The list of `Database.UpsertResult` instances to log
   * @return               The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setDatabaseResult(List<Database.UpsertResult> upsertResults) {
    return this.setDatabaseDetails(upsertResults, Database.UpsertResult.class, null);
  }

  /**
   * @description Sets the log entry event's database operation result fields
   * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
   * @return                 The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setDatabaseResult(List<Database.UndeleteResult> undeleteResults) {
    return this.setDatabaseDetails(undeleteResults, Database.UndeleteResult.class, null);
  }

  /**
   * @description Deprecated - use `setRecord(Id recordId)` instead
   * @param recordId The id of the record to set.
   * @return An instance of LogEntryEventBuilder with a record associated wit recordId.
   */
  global LogEntryEventBuilder setRecordId(Id recordId) {
    return this.setRecord(recordId);
  }

  /**
   * @description Deprecated - use `setRecord(SObject record)` instead
   * @param record the record to set.
   * @return An instance of LogEntryEventBuilder with the given record.
   */
  global LogEntryEventBuilder setRecordId(SObject record) {
    return this.setRecord(record);
  }

  /**
   * @description Sets the log entry event's record fields
   * @param  recordId The ID of the SObject record related to the entry
   * @return          The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setRecord(Id recordId) {
    if (this.shouldSave() == false || String.isBlank(recordId)) {
      return this;
    }

    this.logEntryEvent.RecordCollectionSize__c = 1;
    this.logEntryEvent.RecordCollectionType__c = 'Single';
    this.logEntryEvent.RecordId__c = recordId;
    try {
      Schema.SObjectType sobjectType = recordId?.getSObjectType();
      this.logEntryEvent.RecordSObjectClassification__c = getSObjectClassification(sobjectType);
      this.logEntryEvent.RecordSObjectType__c = sobjectType.toString();
    } catch (System.SObjectException sobjectException) {
      // Some SObject Types are considered template objects, such as CaseComment, AccountHistory,
      // ContactHistory, etc, so calling Id.getSObjectType() does not work for some types of record IDs
      if (sobjectException.getMessage().contains('Cannot locate Apex Type') == false) {
        throw sobjectException;
      }
    }
    return this;
  }

  /**
   * @description Sets the log entry event's record fields
   * @param  record The `SObject` record related to the entry. The JSON of the record is automatically added to the entry
   * @return        The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setRecord(SObject record) {
    if (this.shouldSave() == false) {
      return this;
    }

    this.logEntryEvent.RecordCollectionSize__c = 1;
    this.logEntryEvent.RecordCollectionType__c = 'Single';

    TextFieldValueCleaner textCleaner = new TextFieldValueCleaner(
      this.userSettings,
      Schema.LogEntryEvent__e.RecordJson__c,
      getJson(record, this.userSettings.IsRecordFieldStrippingEnabled__c)
    );
    this.logEntryEvent.RecordJson__c = textCleaner.textValue;
    this.logEntryEvent.RecordJsonMasked__c = textCleaner.wasMasked;
    this.logEntryEvent.RecordJsonTruncated__c = textCleaner.wasMasked;

    if (record == null) {
      this.logEntryEvent.RecordSObjectClassification__c = 'Unknown';
      this.logEntryEvent.RecordSObjectType__c = 'Unknown';
    } else {
      this.logEntryEvent.RecordId__c = record.Id;
      this.logEntryEvent.RecordSObjectClassification__c = getSObjectClassification(record.getSObjectType());
      this.logEntryEvent.RecordSObjectType__c = record.getSObjectType().toString();
      this.logEntryEvent.RecordSObjectTypeNamespace__c = getSObjectTypeNamespace(record.getSObjectType());
    }

    return this;
  }

  /**
   * @description Sets the log entry event's record fields
   * @param  records The list of `SObject` records related to the entry. The JSON of the list is automatically added to the entry
   * @return         The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setRecord(List<SObject> records) {
    if (this.shouldSave() == false) {
      return this;
    }

    this.logEntryEvent.RecordCollectionSize__c = records?.size();
    this.logEntryEvent.RecordCollectionType__c = 'List';

    TextFieldValueCleaner textCleaner = new TextFieldValueCleaner(
      this.userSettings,
      Schema.LogEntryEvent__e.RecordJson__c,
      getJson(records, this.userSettings.IsRecordFieldStrippingEnabled__c)
    );
    this.logEntryEvent.RecordJson__c = textCleaner.textValue;
    this.logEntryEvent.RecordJsonMasked__c = textCleaner.wasMasked;
    this.logEntryEvent.RecordJsonTruncated__c = textCleaner.wasTruncated;

    Schema.SObjectType sobjectType = records?.getSObjectType();
    if (sobjectType == null) {
      this.logEntryEvent.RecordSObjectClassification__c = 'Unknown';
      this.logEntryEvent.RecordSObjectType__c = 'Unknown';
    } else {
      this.logEntryEvent.RecordSObjectClassification__c = getSObjectClassification(sobjectType);
      this.logEntryEvent.RecordSObjectType__c = sobjectType.toString();
      this.logEntryEvent.RecordSObjectTypeNamespace__c = getSObjectTypeNamespace(sobjectType);
    }

    return this;
  }

  /**
   * @description Sets the log entry event's record fields
   * @param  recordIdToRecord The map of `SObject` records related to the entry. The JSON of the map is automatically added to the entry
   * @return                  The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setRecord(Map<Id, SObject> recordIdToRecord) {
    if (this.shouldSave() == false) {
      return this;
    }

    this.logEntryEvent.RecordCollectionSize__c = recordIdToRecord?.size();
    this.logEntryEvent.RecordCollectionType__c = 'Map';

    TextFieldValueCleaner textCleaner = new TextFieldValueCleaner(
      this.userSettings,
      Schema.LogEntryEvent__e.RecordJson__c,
      getJson(recordIdToRecord, this.userSettings.IsRecordFieldStrippingEnabled__c)
    );
    this.logEntryEvent.RecordJson__c = textCleaner.textValue;
    this.logEntryEvent.RecordJsonMasked__c = textCleaner.wasMasked;
    this.logEntryEvent.RecordJsonTruncated__c = textCleaner.wasTruncated;

    List<SObject> recordsList = recordIdToRecord?.values();
    Schema.SObjectType sobjectType = recordIdToRecord?.size() > 0 ? recordsList.get(0)?.getSObjectType() : null;
    if (sobjectType == null) {
      this.logEntryEvent.RecordSObjectClassification__c = 'Unknown';
      this.logEntryEvent.RecordSObjectType__c = 'Unknown';
    } else {
      this.logEntryEvent.RecordSObjectClassification__c = getSObjectClassification(sobjectType);
      this.logEntryEvent.RecordSObjectType__c = sobjectType.toString();
      this.logEntryEvent.RecordSObjectTypeNamespace__c = getSObjectTypeNamespace(sobjectType);
    }

    return this;
  }

  /**
   * @description Sets the log entry event's record fields
   * @param  recordIds The Set of `SObject` records ids related to the entry. Will be converted to list and the JSON of the list is automatically added to the entry
   * @return            The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setRecord(System.Iterable<Id> recordIds) {
    if (this.shouldSave() == false) {
      return this;
    }

    List<SObject> records;
    if (recordIds != null) {
      records = new List<SObject>();
      for (Id recordId : recordIds) {
        records.add(recordId.getSObjectType().newSObject(recordId));
      }
    }

    return this.setRecord(records);
  }

  /**
   * @description Sets the log entry event's HTTP Request fields
   * @param  request The instance of `HttpRequest` to log
   * @return         The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setHttpRequestDetails(System.HttpRequest request) {
    return this.setHttpRequestDetails(request, new List<String>());
  }

  /**
   * @description Sets the log entry event's HTTP Request fields
   * @param  request The instance of `HttpRequest` to log
   * @param  headersToLog An instance of `List<String>` containing the header keys to log
   * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setHttpRequestDetails(System.HttpRequest request, List<String> headersToLog) {
    if (this.shouldSave() == false || request == null) {
      return this;
    }

    String formattedHeaderKeysString;
    String formattedHeadersString;
    if (headersToLog != null & headersToLog.isEmpty() == false) {
      formattedHeaderKeysString = String.join(headersToLog, NEW_LINE_DELIMITER);
      if (LoggerParameter.STORE_HTTP_REQUEST_HEADER_VALUES) {
        List<String> headers = new List<String>();
        for (String headerKey : headersToLog) {
          headers.add(String.format(HTTP_HEADER_FORMAT, new List<String>{ headerKey, request.getHeader(headerKey) }));
        }
        formattedHeadersString = String.join(headers, NEW_LINE_DELIMITER);
      }
    }

    TextFieldValueCleaner textCleaner = new TextFieldValueCleaner(this.userSettings, Schema.LogEntryEvent__e.HttpRequestBody__c, request.getBody());

    this.logEntryEvent.HttpRequestBody__c = textCleaner.textValue;
    this.logEntryEvent.HttpRequestBodyMasked__c = textCleaner.wasMasked;
    this.logEntryEvent.HttpRequestBodyTruncated__c = textCleaner.wasTruncated;
    this.logEntryEvent.HttpRequestCompressed__c = request.getCompressed();
    this.logEntryEvent.HttpRequestEndpoint__c = LoggerDataStore.truncateFieldValue(Schema.LogEntryEvent__e.HttpRequestEndpoint__c, request.getEndpoint());
    this.logEntryEvent.HttpRequestEndpointAddress__c = LoggerDataStore.truncateFieldValue(
      Schema.LogEntryEvent__e.HttpRequestEndpointAddress__c,
      request.getEndpoint()
    );
    this.logEntryEvent.HttpRequestHeaderKeys__c = formattedHeaderKeysString;
    this.logEntryEvent.HttpRequestHeaders__c = LoggerDataStore.truncateFieldValue(Schema.LogEntryEvent__e.HttpRequestHeaders__c, formattedHeadersString);
    this.logEntryEvent.HttpRequestMethod__c = request.getMethod();
    return this;
  }

  /**
   * @description Sets the log entry event's HTTP Response fields
   * @param  response The instance of `HttpResponse` to log
   * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setHttpResponseDetails(System.HttpResponse response) {
    if (this.shouldSave() == false || response == null) {
      return this;
    }

    String formattedHeadersString;
    if (LoggerParameter.STORE_HTTP_RESPONSE_HEADER_VALUES) {
      List<String> headers = new List<String>();
      for (String headerKey : response.getHeaderKeys()) {
        headers.add(String.format(HTTP_HEADER_FORMAT, new List<String>{ headerKey, response.getHeader(headerKey) }));
      }
      formattedHeadersString = String.join(headers, NEW_LINE_DELIMITER);
    }

    TextFieldValueCleaner textCleaner = new TextFieldValueCleaner(this.userSettings, Schema.LogEntryEvent__e.HttpResponseBody__c, response.getBody());

    this.logEntryEvent.HttpResponseBody__c = textCleaner.textValue;
    this.logEntryEvent.HttpResponseBodyMasked__c = textCleaner.wasMasked;
    this.logEntryEvent.HttpResponseBodyTruncated__c = textCleaner.wasTruncated;
    this.logEntryEvent.HttpResponseHeaderKeys__c = String.join(response.getHeaderKeys(), NEW_LINE_DELIMITER);
    this.logEntryEvent.HttpResponseHeaders__c = LoggerDataStore.truncateFieldValue(Schema.LogEntryEvent__e.HttpResponseHeaders__c, formattedHeadersString);
    this.logEntryEvent.HttpResponseStatus__c = response.getStatus();
    this.logEntryEvent.HttpResponseStatusCode__c = response.getStatusCode();
    return this;
  }

  /**
   * @description Sets the log entry event's REST Request fields
   * @param  request The instance of `System.RestRequest` to log
   * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setRestRequestDetails(System.RestRequest request) {
    if (this.shouldSave() == false || request == null) {
      return this;
    }

    String formattedHeaderKeysString;
    String formattedHeadersString;
    if (request.headers != null) {
      formattedHeaderKeysString = String.join(request.headers.keySet(), NEW_LINE_DELIMITER);
      if (LoggerParameter.STORE_REST_REQUEST_HEADER_VALUES) {
        List<String> headers = new List<String>();
        for (String headerKey : request.headers.keySet()) {
          headers.add(String.format(HTTP_HEADER_FORMAT, new List<String>{ headerKey, request.headers.get(headerKey) }));
        }
        formattedHeadersString = String.join(headers, NEW_LINE_DELIMITER);
      }
    }
    String formattedParametersString;
    if (request.params != null) {
      List<String> parameters = new List<String>();
      for (String headerKey : request.params.keySet()) {
        parameters.add(String.format(HTTP_HEADER_FORMAT, new List<String>{ headerKey, request.params.get(headerKey) }));
      }
      formattedParametersString = String.join(parameters, NEW_LINE_DELIMITER);
    }

    TextFieldValueCleaner textCleaner = new TextFieldValueCleaner(
      this.userSettings,
      Schema.LogEntryEvent__e.RestRequestBody__c,
      request.requestBody?.toString()
    );

    this.logEntryEvent.RestRequestBody__c = textCleaner.textValue;
    this.logEntryEvent.RestRequestBodyMasked__c = textCleaner.wasMasked;
    this.logEntryEvent.RestRequestBodyTruncated__c = textCleaner.wasTruncated;
    this.logEntryEvent.RestRequestHeaderKeys__c = formattedHeaderKeysString;
    this.logEntryEvent.RestRequestHeaders__c = LoggerDataStore.truncateFieldValue(Schema.LogEntryEvent__e.RestRequestHeaders__c, formattedHeadersString);
    this.logEntryEvent.RestRequestMethod__c = request.httpMethod;
    this.logEntryEvent.RestRequestParameters__c = formattedParametersString;
    this.logEntryEvent.RestRequestRemoteAddress__c = request.remoteAddress;
    this.logEntryEvent.RestRequestResourcePath__c = request.resourcePath;
    this.logEntryEvent.RestRequestUri__c = request.requestURI;
    return this;
  }

  /**
   * @description Sets the log entry event's REST Response fields
   * @param  response The instance of `System.RestResponse` to log
   * @return          The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setRestResponseDetails(System.RestResponse response) {
    if (this.shouldSave() == false || response == null) {
      return this;
    }

    String formattedHeaderKeysString;
    String formattedHeadersString;
    if (response.headers != null) {
      formattedHeaderKeysString = String.join(response.headers.keySet(), NEW_LINE_DELIMITER);
      if (LoggerParameter.STORE_REST_RESPONSE_HEADER_VALUES) {
        List<String> headers = new List<String>();
        for (String headerKey : response.headers.keySet()) {
          headers.add(String.format(HTTP_HEADER_FORMAT, new List<String>{ headerKey, response.headers.get(headerKey) }));
        }
        formattedHeadersString = String.join(headers, NEW_LINE_DELIMITER);
      }
    }

    TextFieldValueCleaner textCleaner = new TextFieldValueCleaner(
      this.userSettings,
      Schema.LogEntryEvent__e.RestResponseBody__c,
      response.responseBody?.toString()
    );

    this.logEntryEvent.RestResponseBody__c = textCleaner.textValue;
    this.logEntryEvent.RestResponseBodyMasked__c = textCleaner.wasMasked;
    this.logEntryEvent.RestResponseBodyTruncated__c = textCleaner.wasTruncated;
    this.logEntryEvent.RestResponseHeaderKeys__c = formattedHeaderKeysString;
    this.logEntryEvent.RestResponseHeaders__c = LoggerDataStore.truncateFieldValue(Schema.LogEntryEvent__e.RestResponseHeaders__c, formattedHeadersString);
    this.logEntryEvent.RestResponseStatusCode__c = response.statusCode;
    return this;
  }

  /**
   * @description Sets a field value on the builder's `LogEntryEvent__e` record
   * @param  field      The `Schema.SObjectField` token of the field to populate
   *                    on the builder's `LogEntryEvent__e` record
   * @param  fieldValue The `Object` value to populate in the provided field
   * @return The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder setField(Schema.SObjectField field, Object fieldValue) {
    if (this.shouldSave() == false) {
      return this;
    }

    return this.setField(new Map<Schema.SObjectField, Object>{ field => fieldValue });
  }

  /**
   * @description Sets multiple field values on the builder's `LogEntryEvent__e` record
   * @param  fieldToValue An instance of `Map<Schema.SObjectField, Object>` containing the
   *                      the fields & values to populate on the builder's `LogEntryEvent__e` record
   * @return The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  @SuppressWarnings('PMD.AvoidDebugStatements')
  global LogEntryEventBuilder setField(Map<Schema.SObjectField, Object> fieldToValue) {
    if (this.shouldSave() == false || fieldToValue == null) {
      return this;
    }

    for (Schema.SObjectField field : fieldToValue.keySet()) {
      Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
      Object value = fieldToValue.get(field);
      if (fieldDescribe.getSoapType() == Schema.SoapType.STRING) {
        value = LoggerDataStore.truncateFieldValue(field, (String) value);
      }
      try {
        this.logEntryEvent.put(field, value);
      } catch (System.Exception ex) {
        LogMessage logMessage = new LogMessage('Could not set field {0} with value {1}', field, value);
        System.debug(System.LoggingLevel.WARN, logMessage.getMessage());
      }
    }

    return this;
  }

  /**
   * @description Appends the tag to the existing list of tags
   * @param tag The string to use as a tag for the current entry
   * @return The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder addTag(String tag) {
    if (this.shouldSave() == false || String.isBlank(tag)) {
      return this;
    }

    this.tags.add(tag);
    this.tagDetailsAreSet = false;
    return this;
  }

  /**
   * @description Appends the tag to the existing list of tags
   * @param tags The list of strings to use as tags for the current entry
   * @return The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global LogEntryEventBuilder addTags(List<String> tags) {
    if (tags == null || tags.isEmpty()) {
      return this;
    }

    for (String tag : tags) {
      this.addTag(tag);
    }
    return this;
  }

  /**
   * @description Deprecated - use `addTags(List<String> tags)` instead.
   *              This method will be removed in a future release
   * @param tags A list of tags
   * @return An instance of LogEntryEventBuilder with the given topics / tags.
   */
  public LogEntryEventBuilder setTopics(List<String> tags) {
    return this.addTags(tags);
  }

  /**
   * @description Parses the provided stack trace and sets the log entry's origin & stack trace fields
   * @param stackTraceString The Apex stack trace string to parse
   * @return The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  @SuppressWarnings('PMD.NcssMethodCount')
  global LogEntryEventBuilder parseStackTrace(String stackTraceString) {
    if (this.shouldSave() == false || LoggerParameter.ENABLE_STACK_TRACE_PARSING == false) {
      return this;
    }

    return this.parseStackTrace(new LoggerStackTrace(stackTraceString));
  }

  /**
   * @description Determines if this instance of `LogEntryEventBuilder` should be saved the next time that `Logger.saveLog()` is called
   * @return A boolean set to true if the log entries should be saved.
   */
  public Boolean shouldSave() {
    return this.shouldSave;
  }

  /**
   * @description **This is only intended to be used internally by Nebula Logger, and is subject to change.**
   * @param loggingContext Variables specific to the current Logger state
   * Sets information only available from the `Logger` class.
   */
  public void setLoggingContext(LoggingContext loggingContext) {
    this.logEntryEvent.ApiVersion__c = loggingContext.organizationApiVersion;
    this.logEntryEvent.EntryScenario__c = loggingContext.currentEntryScenario;
    this.logEntryEvent.LoggerVersionNumber__c = loggingContext.loggerVersionNumber;
    this.logEntryEvent.OrganizationApiVersion__c = loggingContext.organizationApiVersion;
    this.logEntryEvent.OrganizationDomainUrl__c = loggingContext.organizationDomainUrl;
    this.logEntryEvent.RequestId__c = loggingContext.requestId;
    this.logEntryEvent.SystemMode__c = loggingContext.systemMode?.name();
    this.logEntryEvent.TransactionEntryNumber__c = loggingContext.entryNumber;
    this.logEntryEvent.TransactionId__c = loggingContext.transactionId;
    this.logEntryEvent.UserLoggingLevel__c = loggingContext.userLoggingLevel.name();
    this.logEntryEvent.UserLoggingLevelOrdinal__c = loggingContext.userLoggingLevel.ordinal();
  }

  /**
   * @description **This is only intended to be used internally by Nebula Logger, and is subject to change.**
   * @param timestamp Datetime instance to set timestamp fields on this.logEntryEvent
   * @return The same instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  public LogEntryEventBuilder setTimestamp(Datetime timestamp) {
    // Salesforce does not provide precise datetimes in Apex triggers for platform events
    // Set the string value of timestamp to a second field as a workaround
    // See https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_api_considerations.htm
    this.logEntryEvent.EpochTimestamp__c = timestamp.getTime();
    this.logEntryEvent.Timestamp__c = timestamp;
    this.logEntryEvent.TimestampString__c = '' + this.logEntryEvent.EpochTimestamp__c;

    return this;
  }

  /**
   * @description Returns the `LogEntryEvent__e` record for this instance of LogEntryEventBuilder
   * @return The `LogEntryEvent__e` record
   */
  global LogEntryEvent__e getLogEntryEvent() {
    if (this.shouldSave() == false) {
      return null;
    }

    // Lazy-loading of some details to help minimize Apex heap size usage until needed
    if (this.detailsAreSet == false) {
      if (this.userSettings.IsAnonymousModeEnabled__c == false) {
        setUserInfoDetails(this.logEntryEvent);
        setQueriedAuthSessionDetails(this.logEntryEvent, this.userSettings);
        setQueriedUserDetails(this.logEntryEvent, this.userSettings);
      }
      setQueriedNetworkDetails(this.logEntryEvent, this.userSettings);
      setQueriedOrganizationDetails(this.logEntryEvent, this.userSettings);
      this.detailsAreSet = true;
    }

    // getLogEntryEvent() and addTag() could both be called multiple times
    // for the same instance of LogEntryBuilder, so tags are set (if needed)
    // each time getLogEntryEvent() is called, whereas methods executed above (using Boolean
    // this.detailsAreSet) only need to be run once
    if (this.tagDetailsAreSet == false) {
      this.setTagsDetails();
      this.tagDetailsAreSet = true;
    }

    return this.logEntryEvent;
  }

  private void setSaveReason() {
    System.LoggingLevel userLoggingLevel = System.LoggingLevel.valueOf(this.userSettings.LoggingLevel__c);
    Boolean isEntryLoggingLevelEnabled = this.entryLoggingLevel.ordinal() >= userLoggingLevel.ordinal();

    this.logEntryEvent.EntrySaveReason__c = isEntryLoggingLevelEnabled ? ENTRY_SAVE_REASON_LOGGING_LEVEL_MET : ENTRY_SAVE_REASON_OVERRIDE;
  }

  @SuppressWarnings('PMD.AvoidDebugStatements')
  private void logToApexDebug(String message) {
    if (this.userSettings.IsApexSystemDebugLoggingEnabled__c == false) {
      return;
    }

    String template = LoggerParameter.SYSTEM_DEBUG_MESSAGE_FORMAT?.unescapeJava();
    if (String.isNotBlank(template)) {
      List<String> possibleReplacements = template.split('\\{');
      for (String possibleReplacement : possibleReplacements) {
        if (String.isBlank(possibleReplacement)) {
          continue;
        }

        String logEntryFieldName = possibleReplacement.substringBefore('}');
        Object logEntryFieldValue = this.logEntryEvent.get(logEntryFieldName);
        if (logEntryFieldValue == null) {
          logEntryFieldValue = '(null)';
        }
        template = template.replace('{' + logEntryFieldName + '}', String.valueOf(logEntryFieldValue));
      }
      this.debugMessage = template;
    } else {
      this.debugMessage = message;
    }

    // One of a few limited places in the codebase (except tests) that should use System.debug()
    // The rest of the codebase should use a method in Logger.cls
    System.debug(this.entryLoggingLevel, this.debugMessage);
  }

  private LogEntryEventBuilder parseStackTrace(LoggerStackTrace originStackTrace) {
    if (this.shouldSave() == false || LoggerParameter.ENABLE_STACK_TRACE_PARSING == false) {
      return this;
    }

    this.logEntryEvent.OriginLocation__c = originStackTrace.Location;
    this.logEntryEvent.OriginSourceActionName__c = originStackTrace.Source?.ActionName;
    this.logEntryEvent.OriginSourceApiName__c = originStackTrace.Source?.ApiName;
    this.logEntryEvent.OriginSourceMetadataType__c = originStackTrace.Source?.MetadataType.name();
    this.logEntryEvent.StackTrace__c = LoggerDataStore.truncateFieldValue(Schema.LogEntryEvent__e.StackTrace__c, originStackTrace.ParsedStackTraceString);
    return this;
  }

  private LogEntryEventBuilder setDatabaseDetails(List<Object> databaseResults, System.Type resultType, Id possibleRecordId) {
    if (this.shouldSave() == false) {
      return this;
    }

    this.logEntryEvent.DatabaseResultCollectionSize__c = databaseResults.size();
    this.logEntryEvent.DatabaseResultCollectionType__c = this.logEntryEvent.DatabaseResultCollectionSize__c == 1 ? 'Single' : 'List';
    String serializedResult = System.JSON.serializePretty(this.logEntryEvent.DatabaseResultCollectionSize__c == 1 ? databaseResults.get(0) : databaseResults);
    this.logEntryEvent.DatabaseResultJson__c = LoggerDataStore.truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, serializedResult);
    this.logEntryEvent.DatabaseResultType__c = resultType.getName();

    return this.setRecordId(possibleRecordId);
  }

  private void setTagsDetails() {
    if (this.tags.isEmpty() || this.tagDetailsAreSet) {
      return;
    }

    List<String> sortedTags = new List<String>(this.tags);
    sortedTags.sort();
    this.logEntryEvent.Tags__c = LoggerDataStore.truncateFieldValue(
      Schema.LogEntryEvent__e.Tags__c,
      String.escapeSingleQuotes(String.join(sortedTags, NEW_LINE_DELIMITER))
    );
  }

  private static LogEntryEvent__e getLogEntryEventTemplate(System.LoggingLevel entryLoggingLevel) {
    LogEntryEvent__e logEntryEventTemplate = new LogEntryEvent__e(
      LoggingLevel__c = entryLoggingLevel.name(),
      LoggingLevelOrdinal__c = entryLoggingLevel.ordinal(),
      OriginType__c = 'Apex',
      TriggerIsExecuting__c = Trigger.isExecuting,
      TriggerOperationType__c = Trigger.operationType?.name(),
      TriggerSObjectType__c = Trigger.new?.getSObjectType().toString()
    );

    if (LoggerParameter.STORE_TRANSACTION_LIMITS) {
      logEntryEventTemplate.LimitsAggregateQueriesMax__c = CACHED_TRANSACTION_LIMITS.aggregateQueriesMax;
      logEntryEventTemplate.LimitsApexCursorFetchCallsMax__c = CACHED_TRANSACTION_LIMITS.apexCursorFetchCallsMax;
      logEntryEventTemplate.LimitsApexCursorRowsMax__c = CACHED_TRANSACTION_LIMITS.apexCursorRowsMax;
      logEntryEventTemplate.LimitsAsyncCallsMax__c = CACHED_TRANSACTION_LIMITS.asyncCallsMax;
      logEntryEventTemplate.LimitsCalloutsMax__c = CACHED_TRANSACTION_LIMITS.calloutsMax;
      logEntryEventTemplate.LimitsCpuTimeMax__c = CACHED_TRANSACTION_LIMITS.cpuTimeMax;
      logEntryEventTemplate.LimitsDmlRowsMax__c = CACHED_TRANSACTION_LIMITS.dmlRowsMax;
      logEntryEventTemplate.LimitsDmlStatementsMax__c = CACHED_TRANSACTION_LIMITS.dmlStatementsMax;
      logEntryEventTemplate.LimitsEmailInvocationsMax__c = CACHED_TRANSACTION_LIMITS.emailInvocationsMax;
      logEntryEventTemplate.LimitsFutureCallsMax__c = CACHED_TRANSACTION_LIMITS.futureCallsMax;
      logEntryEventTemplate.LimitsHeapSizeMax__c = CACHED_TRANSACTION_LIMITS.heapSizeMax;
      logEntryEventTemplate.LimitsMobilePushApexCallsMax__c = CACHED_TRANSACTION_LIMITS.mobilePushApexCallsMax;
      logEntryEventTemplate.LimitsPublishImmediateDmlStatementsMax__c = CACHED_TRANSACTION_LIMITS.publishImmediateDmlStatementsMax;
      logEntryEventTemplate.LimitsQueueableJobsMax__c = CACHED_TRANSACTION_LIMITS.queueableJobsMax;
      logEntryEventTemplate.LimitsSoqlQueriesMax__c = CACHED_TRANSACTION_LIMITS.soqlQueriesMax;
      logEntryEventTemplate.LimitsSoqlQueryLocatorRowsMax__c = CACHED_TRANSACTION_LIMITS.soqlQueryLocatorRowsMax;
      logEntryEventTemplate.LimitsSoqlQueryRowsMax__c = CACHED_TRANSACTION_LIMITS.soqlQueryRowsMax;
      logEntryEventTemplate.LimitsSoslSearchesMax__c = CACHED_TRANSACTION_LIMITS.soslSearchesMax;

      logEntryEventTemplate.LimitsAggregateQueriesUsed__c = System.Limits.getAggregateQueries();
      logEntryEventTemplate.LimitsApexCursorFetchCallsUsed__c = System.Limits.getFetchCallsOnApexCursor();
      logEntryEventTemplate.LimitsApexCursorRowsUsed__c = System.Limits.getApexCursorRows();
      logEntryEventTemplate.LimitsAsyncCallsUsed__c = System.Limits.getAsyncCalls();
      logEntryEventTemplate.LimitsCalloutsUsed__c = System.Limits.getCallouts();
      logEntryEventTemplate.LimitsCpuTimeUsed__c = System.Limits.getCpuTime();
      logEntryEventTemplate.LimitsDmlRowsUsed__c = System.Limits.getDmlRows();
      logEntryEventTemplate.LimitsDmlStatementsUsed__c = System.Limits.getDmlStatements();
      logEntryEventTemplate.LimitsEmailInvocationsUsed__c = System.Limits.getEmailInvocations();
      logEntryEventTemplate.LimitsFutureCallsUsed__c = System.Limits.getFutureCalls();
      logEntryEventTemplate.LimitsMobilePushApexCallsUsed__c = System.Limits.getMobilePushApexCalls();
      logEntryEventTemplate.LimitsPublishImmediateDmlStatementsUsed__c = System.Limits.getPublishImmediateDML();
      logEntryEventTemplate.LimitsQueueableJobsUsed__c = System.Limits.getQueueableJobs();
      logEntryEventTemplate.LimitsSoqlQueriesUsed__c = System.Limits.getQueries();
      logEntryEventTemplate.LimitsSoqlQueryLocatorRowsUsed__c = System.Limits.getQueryLocatorRows();
      logEntryEventTemplate.LimitsSoqlQueryRowsUsed__c = System.Limits.getQueryRows();
      logEntryEventTemplate.LimitsSoslSearchesUsed__c = System.Limits.getSoslQueries();

      // this is the most CPU-intensive Limits call BY FAR, so we gate it behind its own LoggerParameter record
      if (LoggerParameter.STORE_HEAP_SIZE_LIMIT) {
        logEntryEventTemplate.LimitsHeapSizeUsed__c = System.Limits.getHeapSize();
      }
    }

    return logEntryEventTemplate;
  }

  private static void setQueriedAuthSessionDetails(LogEntryEvent__e logEntryEvent, LoggerSettings__c userSettings) {
    if (userSettings.IsEnabled__c == false || LoggerParameter.QUERY_AUTH_SESSION_DATA_SYNCHRONOUSLY == false) {
      return;
    }

    if (CACHED_AUTH_SESSION_PROXY == null) {
      return;
    }

    logEntryEvent.LoginApplication__c = CACHED_AUTH_SESSION_PROXY.LoginHistory?.Application;
    logEntryEvent.LoginBrowser__c = CACHED_AUTH_SESSION_PROXY.LoginHistory?.Browser;
    logEntryEvent.LoginHistoryId__c = CACHED_AUTH_SESSION_PROXY.LoginHistoryId;
    logEntryEvent.LoginPlatform__c = CACHED_AUTH_SESSION_PROXY.LoginHistory?.Platform;
    logEntryEvent.LoginType__c = CACHED_AUTH_SESSION_PROXY.LoginType;
    logEntryEvent.LogoutUrl__c = CACHED_AUTH_SESSION_PROXY.LogoutUrl;
    logEntryEvent.ParentSessionId__c = CACHED_AUTH_SESSION_PROXY.ParentId;
    logEntryEvent.SessionId__c = CACHED_AUTH_SESSION_PROXY.Id;
    logEntryEvent.SessionSecurityLevel__c = CACHED_AUTH_SESSION_PROXY.SessionSecurityLevel;
    logEntryEvent.SessionType__c = CACHED_AUTH_SESSION_PROXY.SessionType;
    logEntryEvent.SourceIp__c = CACHED_AUTH_SESSION_PROXY.SourceIp;

    if (CACHED_AUTH_SESSION_PROXY.LoginHistory?.UserId != CURRENT_USER.Id) {
      logEntryEvent.ImpersonatedById__c = CACHED_AUTH_SESSION_PROXY.LoginHistory?.UserId;
    }
  }

  private static void setQueriedNetworkDetails(LogEntryEvent__e logEntryEvent, LoggerSettings__c userSettings) {
    if (userSettings.IsEnabled__c == false || LoggerParameter.QUERY_NETWORK_DATA_SYNCHRONOUSLY == false || String.isBlank(networkId)) {
      return;
    }

    logEntryEvent.NetworkId__c = networkId;
    if (CACHED_NETWORK_PROXY == null) {
      return;
    }

    logEntryEvent.NetworkLoginUrl__c = System.Network.getLoginUrl(CACHED_NETWORK_PROXY.Id);
    logEntryEvent.NetworkLogoutUrl__c = System.Network.getLogoutUrl(CACHED_NETWORK_PROXY.Id);
    logEntryEvent.NetworkName__c = CACHED_NETWORK_PROXY.Name;
    logEntryEvent.NetworkSelfRegistrationUrl__c = System.Network.getSelfRegUrl(CACHED_NETWORK_PROXY.Id);
    logEntryEvent.NetworkUrlPathPrefix__c = CACHED_NETWORK_PROXY.UrlPathPrefix;
  }

  private static void setQueriedOrganizationDetails(LogEntryEvent__e logEntryEvent, LoggerSettings__c userSettings) {
    if (userSettings.IsEnabled__c == false || LoggerParameter.QUERY_ORGANIZATION_DATA_SYNCHRONOUSLY == false) {
      return;
    }

    if (CACHED_ORGANIZATION == null) {
      return;
    }

    logEntryEvent.OrganizationEnvironmentType__c = getOrganizationEnvironmentType(userSettings);
    logEntryEvent.OrganizationId__c = CACHED_ORGANIZATION?.Id;
    logEntryEvent.OrganizationInstanceName__c = CACHED_ORGANIZATION?.InstanceName;
    logEntryEvent.OrganizationName__c = CACHED_ORGANIZATION?.Name;
    logEntryEvent.OrganizationNamespacePrefix__c = CACHED_ORGANIZATION?.NamespacePrefix;
    logEntryEvent.OrganizationType__c = CACHED_ORGANIZATION?.OrganizationType;
  }

  private static void setQueriedUserDetails(LogEntryEvent__e logEntryEvent, LoggerSettings__c userSettings) {
    if (userSettings.IsEnabled__c == false || LoggerParameter.QUERY_USER_DATA_SYNCHRONOUSLY == false) {
      return;
    }

    if (CACHED_USER == null) {
      return;
    }

    logEntryEvent.LoggedByFederationIdentifier__c = CACHED_USER.FederationIdentifier;
    logEntryEvent.ProfileName__c = CACHED_USER.Profile.Name;
    logEntryEvent.UserLicenseDefinitionKey__c = CACHED_USER.Profile.UserLicense.LicenseDefinitionKey;
    logEntryEvent.UserLicenseId__c = CACHED_USER.Profile.UserLicenseId;
    logEntryEvent.UserLicenseName__c = CACHED_USER.Profile.UserLicense.Name;
    logEntryEvent.UserRoleName__c = CACHED_USER.UserRole?.Name;
  }

  private static void setUserInfoDetails(LogEntryEvent__e templateLogEntryEvent) {
    templateLogEntryEvent.Locale__c = System.UserInfo.getLocale();
    templateLogEntryEvent.LoggedById__c = System.UserInfo.getUserId();
    templateLogEntryEvent.LoggedByUsername__c = System.UserInfo.getUsername();
    templateLogEntryEvent.ProfileId__c = System.UserInfo.getProfileId();
    templateLogEntryEvent.ThemeDisplayed__c = System.UserInfo.getUiThemeDisplayed();
    templateLogEntryEvent.TimeZoneId__c = System.UserInfo.getTimeZone().getId();
    templateLogEntryEvent.TimeZoneName__c = System.UserInfo.getTimeZone().getDisplayName();
    templateLogEntryEvent.UserRoleId__c = System.UserInfo.getUserRoleId();
    templateLogEntryEvent.UserType__c = System.UserInfo.getUserType();
  }

  // Private static helper methods
  @TestVisible
  private static void setMockDataMaskRule(LogEntryDataMaskRule__mdt dataMaskRule) {
    CACHED_DATA_MASK_RULES.put(dataMaskRule.DeveloperName, dataMaskRule);
  }

  private static String applyDataMaskRules(Boolean isDataMaskingEnabled, String dataInput) {
    if (isDataMaskingEnabled == false || String.isBlank(dataInput)) {
      return dataInput;
    }

    for (LogEntryDataMaskRule__mdt dataMaskRule : CACHED_DATA_MASK_RULES.values()) {
      if (dataMaskRule.IsEnabled__c) {
        dataInput = dataInput.replaceAll(dataMaskRule.SensitiveDataRegEx__c, dataMaskRule.ReplacementRegEx__c);
      }
    }
    return dataInput;
  }

  private static String getJson(SObject record, Boolean isRecordFieldStrippingEnabled) {
    List<SObject> records = new List<SObject>{ record };
    records = isRecordFieldStrippingEnabled == false ? records : stripInaccessible(records);

    if (records == null) {
      return null;
    }

    SObject strippedRecord = records.get(0);
    return System.JSON.serializePretty(strippedRecord);
  }

  private static String getJson(List<SObject> records, Boolean isRecordFieldStrippingEnabled) {
    records = isRecordFieldStrippingEnabled == false ? records : stripInaccessible(records);
    return System.JSON.serializePretty(records);
  }

  private static String getJson(Map<Id, SObject> recordIdToRecord, Boolean isRecordFieldStrippingEnabled) {
    if (recordIdToRecord == null) {
      return null;
    }

    // In Apex, a Map<Id, SObject> with a null ID value will break during serialization,
    // so convert it to a Map<String, SObject> first
    Map<String, SObject> strippedRecordIdToRecord = new Map<String, SObject>();
    for (Id recordId : recordIdToRecord.keySet()) {
      SObject record = recordIdToRecord.get(recordId);
      // Record field-stripping isn't done by reference, so the record has to be reassigned
      record = isRecordFieldStrippingEnabled == false ? record : stripInaccessible(record);
      String recordIdString = recordId == null ? '' : recordId;
      strippedRecordIdToRecord.put(recordIdString, record);
    }
    return System.JSON.serializePretty(strippedRecordIdToRecord);
  }

  private static String getOrganizationEnvironmentType(LoggerSettings__c userSettings) {
    if (cachedOrganizationEnvironmentType != null) {
      return cachedOrganizationEnvironmentType;
    }

    if (userSettings.IsEnabled__c == false || LoggerParameter.QUERY_ORGANIZATION_DATA_SYNCHRONOUSLY == false) {
      return '';
    }

    Schema.Organization cachedOrganization = LoggerEngineDataSelector.getInstance().getCachedOrganization();
    String cachedOrganizationEnvironmentType;
    if (cachedOrganization == null) {
      cachedOrganizationEnvironmentType = '';
    } else if (cachedOrganization.IsSandbox && cachedOrganization.TrialExpirationDate != null) {
      cachedOrganizationEnvironmentType = 'Scratch Org';
    } else if (cachedOrganization.IsSandbox) {
      cachedOrganizationEnvironmentType = 'Sandbox';
    } else {
      cachedOrganizationEnvironmentType = 'Production';
    }
    return cachedOrganizationEnvironmentType;
  }

  private static String getNamespacePrefix() {
    String className = LogEntryEventBuilder.class.getName();
    String namespacePrefix = className.contains('.') ? className.substringBefore('.') : '';

    return namespacePrefix;
  }

  private static String getSObjectClassification(Schema.SObjectType sobjectType) {
    String sobjectName = sobjectType.toString();

    // Check the map to see if we've already determined the classification for this SObject type
    if (CACHED_SOBJECT_NAME_TO_CLASSIFICATION.containsKey(sobjectName)) {
      return CACHED_SOBJECT_NAME_TO_CLASSIFICATION.get(sobjectName);
    }

    String sobjectClassification;

    // Custom settings and custom objects both end in '__c', so explicitly check if it's a custom setting
    if (sobjectType.getDescribe().isCustomSetting()) {
      sobjectClassification = 'Custom Setting Object';
    }

    for (String sobjectSuffix : SOBJECT_SUFFIX_TO_CLASSIFICATION.keySet()) {
      if (String.isBlank(sobjectClassification) && sobjectName.endsWith(sobjectSuffix)) {
        sobjectClassification = SOBJECT_SUFFIX_TO_CLASSIFICATION.get(sobjectSuffix);
        break;
      }
    }

    // Finally, if we still don't have a classification, assume it's a standard object
    if (String.isBlank(sobjectClassification) && sobjectType.getDescribe().isCustom() == false) {
      sobjectClassification = 'Standard Object';
    }

    // Cache the results in case there are other entries related to the same SObject Type
    CACHED_SOBJECT_NAME_TO_CLASSIFICATION.put(sobjectName, sobjectClassification);

    return sobjectClassification;
  }

  private static Map<String, String> getSObjectSuffixToClassification() {
    // TODO add sample metadata for external object + picklist value + test
    // Example: MyExternalObject__x
    // '__x' => 'External Object'

    return new Map<String, String>{
      // Example: MyBigObject__b
      '__b' => 'Big Object',
      // Example: Log__c
      '__c' => 'Custom Object',
      // Example: LogEntryEvent__e
      '__e' => 'Platform Event Object',
      // Example: LogStatus__mdt
      '__mdt' => 'Custom Metadata Type Object',
      // Examples: AccountChangeEvent and Log__ChangeEvent
      'ChangeEvent' => 'Change Event Object',
      // Examples: AccountFeed and Log__Feed
      'Feed' => 'Chatter Feed Object',
      // Examples: AccountHistory and Log__History
      'History' => 'Field History Tracking Object',
      // Examples: AccountShare and Log__Share
      'Share' => 'Record Share Object'
    };
  }

  private static String getSObjectTypeNamespace(Schema.SObjectType sobjectType) {
    String sobjectFullName = sobjectType.toString();
    String sobjectLocalName = sobjectType.getDescribe().getLocalName();

    // Remove the trailing '__' if present
    String namespace = sobjectFullName.replace(sobjectLocalName, '').replace('__', '');
    if (String.isBlank(namespace)) {
      namespace = null;
    }
    return namespace;
  }

  // TODO need to revisit Visualforce logic, re-add fields to either Log__c or LogEntry__c, etc.
  /* private static String getVisualforcePageName() {
        String visualforcePageName = ApexPages.currentPage()?.getUrl();
        if (visualforcePageName != null && visualforcePageName.contains('?')) {
            visualforcePageName = visualforcePageName.substringBetween('apex/', '?');
        } else if (visualforcePageName != null) {
            visualforcePageName = visualforcePageName.substringAfter('apex/');
        }

        return visualforcePageName;
    } */

  private static Boolean isValidStackTrace(String stackTraceString) {
    if (String.isBlank(stackTraceString) || stackTraceString == '()' || stackTraceString == '(' + NAMESPACE_PREFIX + ')') {
      return false;
    }

    return true;
  }

  private static Map<String, LogEntryDataMaskRule__mdt> loadDataMaskRules() {
    Map<String, LogEntryDataMaskRule__mdt> activeDataMaskRules = new Map<String, LogEntryDataMaskRule__mdt>();
    for (LogEntryDataMaskRule__mdt dataMaskRule : LoggerConfigurationSelector.getInstance().getLogEntryDataMaskRules()) {
      if (dataMaskRule.IsEnabled__c) {
        activeDataMaskRules.put(dataMaskRule.DeveloperName, dataMaskRule);
      }
    }
    if (System.Test.isRunningTest()) {
      // Tests shouldn't rely on the actual CMDT rules in the org
      // Clear the org's loaded records during tests, and mock via setMockDataMaskRule()
      activeDataMaskRules.clear();
    }
    return activeDataMaskRules;
  }

  private static SObject stripInaccessible(SObject record) {
    return stripInaccessible(new List<SObject>{ record }).get(0);
  }

  private static List<SObject> stripInaccessible(List<SObject> records) {
    if (records == null || records.isEmpty() || records.get(0).getSObjectType() == Schema.AggregateResult.SObjectType) {
      return records;
    }

    System.SObjectAccessDecision securityDecision = System.Security.stripInaccessible(System.AccessType.READABLE, records, false);
    return securityDecision.getRecords();
  }

  @SuppressWarnings('PMD.ApexDoc')
  public class LoggingContext {
    public String currentEntryScenario;
    public String loggerVersionNumber;
    public String organizationApiVersion;
    public String organizationDomainUrl;
    public String requestId;
    public Integer entryNumber = 0;
    public System.Quiddity systemMode;
    public String transactionId;
    public System.LoggingLevel userLoggingLevel;

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public LoggingContext(
      String loggerVersionNumber,
      String organizationApiVersion,
      String organizationDomainUrl,
      String requestId,
      System.Quiddity systemMode,
      String transactionId
    ) {
      this.loggerVersionNumber = loggerVersionNumber;
      this.organizationApiVersion = organizationApiVersion;
      this.organizationDomainUrl = organizationDomainUrl;
      this.requestId = requestId;
      this.systemMode = systemMode;
      this.transactionId = transactionId;
    }
  }

  @SuppressWarnings('PMD.ApexDoc')
  private class TextFieldValueCleaner {
    public final Schema.SObjectField textField;
    public final String textValue;
    public final Boolean isDataMaskingEnabled;
    public final Boolean wasMasked;
    public final Boolean wasTruncated;

    public TextFieldValueCleaner(LoggerSettings__c settings, Schema.SObjectField textField, String originalTextValue) {
      this.textField = textField;
      this.isDataMaskingEnabled = settings.IsDataMaskingEnabled__c;
      this.wasTruncated = String.isBlank(originalTextValue) ? false : originalTextValue.length() > textField.getDescribe().getLength();

      String cleanedValue = LoggerDataStore.truncateFieldValue(this.textField, originalTextValue);
      if (this.isDataMaskingEnabled) {
        String maskedValue = this.applyDataMaskRules(cleanedValue);
        this.wasMasked = cleanedValue != maskedValue;
        // Some data masking rules could increase the string length (like adding dashes to SSN: '444119999' --> 'XXX-XX-9999'),
        // so truncate again just to be sure that it will fit.
        cleanedValue = LoggerDataStore.truncateFieldValue(this.textField, maskedValue);
      } else {
        this.wasMasked = false;
      }

      this.textValue = cleanedValue;
    }

    private String applyDataMaskRules(String textValueToMask) {
      if (String.isBlank(textValueToMask)) {
        return textValueToMask;
      }

      String maskedTextValue = textValueToMask;
      for (LogEntryDataMaskRule__mdt dataMaskRule : CACHED_DATA_MASK_RULES.values()) {
        if (dataMaskRule.IsEnabled__c) {
          maskedTextValue = maskedTextValue.replaceAll(dataMaskRule.SensitiveDataRegEx__c, dataMaskRule.ReplacementRegEx__c);
        }
      }

      return maskedTextValue;
    }
  }

  @SuppressWarnings('PMD.ApexDoc, PMD.TooManyFields')
  private class TransactionLimits {
    public final Integer aggregateQueriesMax = System.Limits.getLimitAggregateQueries();
    public final Integer apexCursorFetchCallsMax = System.Limits.getLimitFetchCallsOnApexCursor();
    public final Integer apexCursorRowsMax = System.Limits.getLimitApexCursorRows();
    public final Integer asyncCallsMax = System.Limits.getLimitAsyncCalls();
    public final Integer calloutsMax = System.Limits.getLimitCallouts();
    public final Integer cpuTimeMax = System.Limits.getLimitCpuTime();
    public final Integer dmlRowsMax = System.Limits.getLimitDmlRows();
    public final Integer dmlStatementsMax = System.Limits.getLimitDmlStatements();
    public final Integer emailInvocationsMax = System.Limits.getLimitEmailInvocations();
    public final Integer futureCallsMax = System.Limits.getLimitFutureCalls();
    public final Integer heapSizeMax = System.Limits.getLimitHeapSize();
    public final Integer mobilePushApexCallsMax = System.Limits.getLimitMobilePushApexCalls();
    public final Integer publishImmediateDmlStatementsMax = System.Limits.getLimitPublishImmediateDML();
    public final Integer queueableJobsMax = System.Limits.getLimitQueueableJobs();
    public final Integer soqlQueriesMax = System.Limits.getLimitQueries();
    public final Integer soqlQueryLocatorRowsMax = System.Limits.getLimitQueryLocatorRows();
    public final Integer soqlQueryRowsMax = System.Limits.getLimitQueryRows();
    public final Integer soslSearchesMax = System.Limits.getLimitSoslQueries();
  }
}
