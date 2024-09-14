//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Provides a centralized way to load parameters for SObject handlers & plugins,
 *              and casts the parameters to common data types
 */
@SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessivePublicCount, PMD.PropertyNamingConventions')
public class LoggerParameter {
  // During tests, always load this CMDT record
  // so that tests use the same format when calling System.debug()
  private static final String SYSTEM_DEBUG_MESSAGE_FORMAT_PARAMETER = 'SystemDebugMessageFormat';
  private static final Set<String> PARAMETERS_TO_LOAD_DURING_TESTS = new Set<String>{ SYSTEM_DEBUG_MESSAGE_FORMAT_PARAMETER };

  /**
   * @description Indicates if Nebula Logger will make an async callout to `https://api.status.salesforce.com`
   *              to get additional details about the current org, which is then stored on the Log__c record.
   *              Controlled by the custom metadata record `LoggerParameter.CallStatusApi`, or `false` as the default
   */
  public static final Boolean CALL_STATUS_API {
    get {
      if (CALL_STATUS_API == null) {
        CALL_STATUS_API = getBoolean('CallStatusApi', false);
      }
      return CALL_STATUS_API;
    }
    private set;
  }

  /**
   * @description The name of the `LogEntry__c` field set to use as the default field set when configuring
   *              the LWC `<c-related-log-entries>` within App Builder.
   *              Controlled by the custom metadata record `LoggerParameter.DefaultLogEntryRelatedListFieldSet`,
   *              or `Related_List_Defaults` as the default
   */
  public static final String DEFAULT_LOG_ENTRY_RELATED_LIST_FIELD_SET {
    get {
      if (DEFAULT_LOG_ENTRY_RELATED_LIST_FIELD_SET == null) {
        String configuredValue = getString('DefaultLogEntryRelatedListFieldSet', 'Related_List_Defaults');
        DEFAULT_LOG_ENTRY_RELATED_LIST_FIELD_SET = String.isNotBlank(configuredValue) ? configuredValue : '';
      }
      return DEFAULT_LOG_ENTRY_RELATED_LIST_FIELD_SET;
    }
    private set;
  }

  /**
   * @description Indicates if Nebula Logger's LWC `logEntryEventStream` is enabled. The component uses
   *              the Emp API, which counts towards orgs' daily delivery allocations for platform events.
   *              To help reduce usage of the daily allocation limit, orgs can disable the LWC.
   *              Controlled by the custom metadata record `LoggerParameter.EnableLogEntryEventStream`,
   *              or `true` as the default
   */
  public static final Boolean ENABLE_LOG_ENTRY_EVENT_STREAM {
    get {
      if (ENABLE_LOG_ENTRY_EVENT_STREAM == null) {
        ENABLE_LOG_ENTRY_EVENT_STREAM = getBoolean('EnableLogEntryEventStream', true);
      }
      return ENABLE_LOG_ENTRY_EVENT_STREAM;
    }
    private set;
  }

  /**
   * @description Indicates if Nebula Logger will parse a stack trace for each log entry, which is then used to populate
   *              fields like `LogEntry__c.StackTrace__c` and `LogEntry__c.OriginLocation__c`.
   *              Controlled by the custom metadata record `LoggerParameter.EnableStackTraceParsing`, or `true` as the default
   */
  public static final Boolean ENABLE_STACK_TRACE_PARSING {
    get {
      if (ENABLE_STACK_TRACE_PARSING == null) {
        ENABLE_STACK_TRACE_PARSING = getBoolean('EnableStackTraceParsing', true);
      }
      return ENABLE_STACK_TRACE_PARSING;
    }
    private set;
  }

  /**
   * @description Indicates if Nebula Logger will append its own log entries about the logging system.
   *              Controlled by the custom metadata record `LoggerParameter.EnableLoggerSystemMessages`, or `false` as the default
   */
  public static final Boolean ENABLE_SYSTEM_MESSAGES {
    get {
      if (ENABLE_SYSTEM_MESSAGES == null) {
        ENABLE_SYSTEM_MESSAGES = getBoolean('EnableLoggerSystemMessages', false);
      }
      return ENABLE_SYSTEM_MESSAGES;
    }
    private set;
  }

  /**
   * @description Indicates if Nebula Logger's tagging system is enabled.
   *              Controlled by the custom metadata record `LoggerParameter.EnableTagging`, or `true` as the default
   */
  public static final Boolean ENABLE_TAGGING {
    get {
      if (ENABLE_TAGGING == null) {
        ENABLE_TAGGING = getBoolean('EnableTagging', true);
      }
      return ENABLE_TAGGING;
    }
    private set;
  }

  /**
   * @description Indicates if Nebula Logger will store scenarios in the custom object `LoggerScenario__c`,
   *              or in the fields `Log__c.TransactionScenarioName__c` & `LogEntry__c.EntryScenario__c`.
   *              Controlled by the custom metadata record `LoggerParameter.NormalizeScenarioData`, or `true` as the default
   */
  public static final Boolean NORMALIZE_SCENARIO_DATA {
    get {
      if (NORMALIZE_SCENARIO_DATA == null) {
        NORMALIZE_SCENARIO_DATA = getBoolean('NormalizeScenarioData', true);
      }
      return NORMALIZE_SCENARIO_DATA;
    }
    private set;
  }

  /**
   * @description Indicates if Nebula Logger will store tags in the custom objects `LoggerTag__c` & `LogEntryTag__c`,
   *              or in the field `LogEntry__c.Tags__c`.
   *              Controlled by the custom metadata record `LoggerParameter.NormalizeTagData`, or `true` as the default
   */
  public static final Boolean NORMALIZE_TAG_DATA {
    get {
      if (NORMALIZE_TAG_DATA == null) {
        NORMALIZE_TAG_DATA = getBoolean('NormalizeTagData', true);
      }
      return NORMALIZE_TAG_DATA;
    }
    private set;
  }

  /**
   * @description The name of the Platform Cache partition to use for caching (when platform cache is enabled).
   *              Controlled by the custom metadata record `LoggerParameter.PlatformCachePartitionName`, or `LoggerCache` as the default
   */
  public static final String PLATFORM_CACHE_PARTITION_NAME {
    get {
      if (PLATFORM_CACHE_PARTITION_NAME == null) {
        PLATFORM_CACHE_PARTITION_NAME = getString('PlatformCachePartitionName', 'LoggerCache');
      }
      return PLATFORM_CACHE_PARTITION_NAME;
    }
    private set;
  }

  /**
   * @description Controls if Nebula Logger queries `Schema.ApexClass` data.
   *              When set to `false`, any `Schema.ApexClass` fields on `LogEntryEvent__e` and `Log__c` will not be populated
   *              Controlled by the custom metadata record `LoggerParameter.QueryApexClassData`, or `true` as the default
   */
  public static final Boolean QUERY_APEX_CLASS_DATA {
    get {
      if (QUERY_APEX_CLASS_DATA == null) {
        QUERY_APEX_CLASS_DATA = getBoolean('QueryApexClassData', true);
      }
      return QUERY_APEX_CLASS_DATA;
    }
    private set;
  }

  /**
   * @description Controls if Nebula Logger queries `Schema.ApexTrigger` data.
   *              When set to `false`, any `Schema.ApexTrigger` fields on `LogEntryEvent__e` and `Log__c` will not be populated
   *              Controlled by the custom metadata record `LoggerParameter.QueryApexTriggerData`, or `true` as the default
   */
  public static final Boolean QUERY_APEX_TRIGGER_DATA {
    get {
      if (QUERY_APEX_TRIGGER_DATA == null) {
        QUERY_APEX_TRIGGER_DATA = getBoolean('QueryApexTriggerData', true);
      }
      return QUERY_APEX_TRIGGER_DATA;
    }
    private set;
  }

  /**
   * @description Controls if Nebula Logger queries `Schema.AuthSession` data.
   *              When set to `false`, any `Schema.AuthSession` fields on `LogEntryEvent__e` and `Log__c` will not be populated
   *              Controlled by the custom metadata record `LoggerParameter.QueryAuthSessionData`, or `true` as the default
   */
  public static final Boolean QUERY_AUTH_SESSION_DATA {
    get {
      if (QUERY_AUTH_SESSION_DATA == null) {
        QUERY_AUTH_SESSION_DATA = getBoolean('QueryAuthSessionData', true);
      }
      return QUERY_AUTH_SESSION_DATA;
    }
    private set;
  }

  /**
   * @description Controls if Nebula Logger queries `Schema.AuthSession` data synchronously & populated on `LogEntryEvent__e` records.
   *              When set to `false`, any `Schema.AuthSession` fields on `LogEntryEvent__e` will not be populated - the data will instead be queried
   *              asynchronously and populated on any resulting `Log__c` records.
   *              Controlled by the custom metadata record `LoggerParameter.QueryAuthSessionDataSynchronously`, or `true` as the default
   */
  public static final Boolean QUERY_AUTH_SESSION_DATA_SYNCHRONOUSLY {
    get {
      if (QUERY_AUTH_SESSION_DATA_SYNCHRONOUSLY == null) {
        QUERY_AUTH_SESSION_DATA_SYNCHRONOUSLY = getBoolean('QueryAuthSessionDataSynchronously', true);
      }
      return QUERY_AUTH_SESSION_DATA_SYNCHRONOUSLY;
    }
    private set;
  }

  /**
   * @description Controls if Nebula Logger queries `Schema.FlowDefinitionView` data.
   *              When set to `false`, any `Schema.FlowDefinitionView` fields on `LogEntryEvent__e` and `Log__c` will not be populated
   *              Controlled by the custom metadata record `LoggerParameter.QueryFlowDefinitionViewData`, or `true` as the default
   */
  public static final Boolean QUERY_FLOW_DEFINITION_VIEW_DATA {
    get {
      if (QUERY_FLOW_DEFINITION_VIEW_DATA == null) {
        QUERY_FLOW_DEFINITION_VIEW_DATA = getBoolean('QueryFlowDefinitionViewData', true);
      }
      return QUERY_FLOW_DEFINITION_VIEW_DATA;
    }
    private set;
  }

  /**
   * @description Controls if Nebula Logger queries `Schema.OmniProcess` data.
   *              When set to `false`, any `Schema.OmniProcess` fields on `LogEntry__c` will not be populated
   *              Controlled by the custom metadata record `LoggerParameter.QueryOmniProcessData`, or `true` as the default
   */
  public static final Boolean QUERY_OMNI_PROCESS_DATA {
    get {
      if (QUERY_OMNI_PROCESS_DATA == null) {
        QUERY_OMNI_PROCESS_DATA = getBoolean('QueryOmniProcessData', true);
      }
      return QUERY_OMNI_PROCESS_DATA;
    }
    private set;
  }

  /**
   * @description Controls if Nebula Logger queries `Schema.Network` data.
   *              When set to `false`, any `Schema.Network` fields on `LogEntryEvent__e` and `Log__c` will not be populated
   *              Controlled by the custom metadata record `LoggerParameter.QueryNetworkData`, or `true` as the default
   */
  public static final Boolean QUERY_NETWORK_DATA {
    get {
      if (QUERY_NETWORK_DATA == null) {
        QUERY_NETWORK_DATA = getBoolean('QueryNetworkData', true);
      }
      return QUERY_NETWORK_DATA;
    }
    private set;
  }

  /**
   * @description Controls if Nebula Logger queries `Schema.Network` data is queried synchronously & populated on `LogEntryEvent__e` records.
   *              When set to `false`, any `Schema.Network` fields on `LogEntryEvent__e` will not be populated - the data will instead be queried
   *              asynchronously and populated on any resulting `Log__c` records.
   *              Controlled by the custom metadata record `LoggerParameter.QueryNetworkDataSynchronously`, or `true` as the default
   */
  public static final Boolean QUERY_NETWORK_DATA_SYNCHRONOUSLY {
    get {
      if (QUERY_NETWORK_DATA_SYNCHRONOUSLY == null) {
        QUERY_NETWORK_DATA_SYNCHRONOUSLY = getBoolean('QueryNetworkDataSynchronously', true);
      }
      return QUERY_NETWORK_DATA_SYNCHRONOUSLY;
    }
    private set;
  }

  /**
   * @description Controls if Nebula Logger queries `Schema.Organization` data.
   *              When set to `false`, any `Schema.Organization` fields on `LogEntryEvent__e` and `Log__c` will not be populated
   *              Controlled by the custom metadata record `LoggerParameter.QueryOrganizationData`, or `true` as the default
   */
  public static final Boolean QUERY_ORGANIZATION_DATA {
    get {
      if (QUERY_ORGANIZATION_DATA == null) {
        QUERY_ORGANIZATION_DATA = getBoolean('QueryOrganizationData', true);
      }
      return QUERY_ORGANIZATION_DATA;
    }
    private set;
  }

  /**
   * @description Indicates if Nebula Logger queries `Schema.Organization` data is queried synchronously & populated on `LogEntryEvent__e` records.
   *              When set to `false`, any `Schema.Organization` fields on `LogEntryEvent__e` will not be populated - the data will instead be queried
   *              asynchronously and populated on any resulting `Log__c` records.
   *              Controlled by the custom metadata record `LoggerParameter.QueryOrganizationDataSynchronously`, or `true` as the default
   */
  public static final Boolean QUERY_ORGANIZATION_DATA_SYNCHRONOUSLY {
    get {
      if (QUERY_ORGANIZATION_DATA_SYNCHRONOUSLY == null) {
        QUERY_ORGANIZATION_DATA_SYNCHRONOUSLY = getBoolean('QueryOrganizationDataSynchronously', true);
      }
      return QUERY_ORGANIZATION_DATA_SYNCHRONOUSLY;
    }
    private set;
  }

  /**
   * @description Controls if Nebula Logger queries data for records synthetically related to a `LogEntry__c` via `LogEntry__c.RecordId__c`.
   *              When set to `false`, any fields on `LogEntry__c` related to `LogEntry__c.RecordId__c` not be populated
   *              Controlled by the custom metadata record `LoggerParameter.QueryRelatedRecordData`, or `true` as the default
   */
  public static final Boolean QUERY_RELATED_RECORD_DATA {
    get {
      if (QUERY_RELATED_RECORD_DATA == null) {
        QUERY_RELATED_RECORD_DATA = getBoolean('QueryRelatedRecordData', true);
      }
      return QUERY_RELATED_RECORD_DATA;
    }
    private set;
  }

  /**
   * @description Controls if Nebula Logger queries `Schema.User` data.
   *              When set to `false`, any `Schema.User` fields on `LogEntryEvent__e` and `Log__c` will not be populated
   *              Controlled by the custom metadata record `LoggerParameter.QueryUserData`, or `true` as the default
   */
  public static final Boolean QUERY_USER_DATA {
    get {
      if (QUERY_USER_DATA == null) {
        QUERY_USER_DATA = getBoolean('QueryUserData', true);
      }
      return QUERY_USER_DATA;
    }
    private set;
  }

  /**
   * @description Indicates if Nebula Logger queries `Schema.User` data is queried synchronously & populated on `LogEntryEvent__e` records.
   *              When set to `false`, any `Schema.User` fields on `LogEntryEvent__e` that rely on querying will not be populated - the data
   *              will instead be queried asynchronously and populated on any resulting `Log__c` records.
   *              Controlled by the custom metadata record `LoggerParameter.QueryUserDataSynchronously`, or `true` as the default
   */
  public static final Boolean QUERY_USER_DATA_SYNCHRONOUSLY {
    get {
      if (QUERY_USER_DATA_SYNCHRONOUSLY == null) {
        QUERY_USER_DATA_SYNCHRONOUSLY = getBoolean('QueryUserDataSynchronously', true);
      }
      return QUERY_USER_DATA_SYNCHRONOUSLY;
    }
    private set;
  }

  /**
   * @description Indicates if Nebula Logger will enforce scenario-based logging to be used.
   *              When set to `false`, specifying a scenario is completely optional.
   *              When set to `true`, a scenario is required to be set before any logging can occur.
   *              If a logging method is called &amp; the current scenario is null/blank, then Nebula Logger will throw a runtime exception.
   *              Controlled by the custom metadata record `LoggerParameter.RequireScenarioUsage`, or `false` as the default
   */
  public static final Boolean REQUIRE_SCENARIO_USAGE {
    get {
      if (REQUIRE_SCENARIO_USAGE == null) {
        // Most features in Nebula Logger are enabled (true) by default,
        // but this one is intentionally set to false by default - not
        // all orgs want or need to use scenario-based logging
        REQUIRE_SCENARIO_USAGE = getBoolean('RequireScenarioUsage', false);
      }
      return REQUIRE_SCENARIO_USAGE;
    }
    private set;
  }

  /**
   * @description Indicates if Nebula Logger will send an error email notification if any internal exceptions occur.
   *              Controlled by the custom metadata record `LoggerParameter.SendErrorEmailNotifications`, or `true` as the default
   */
  public static final Boolean SEND_ERROR_EMAIL_NOTIFICATIONS {
    get {
      if (SEND_ERROR_EMAIL_NOTIFICATIONS == null) {
        SEND_ERROR_EMAIL_NOTIFICATIONS = getBoolean('SendErrorEmailNotifications', true);
      }
      return SEND_ERROR_EMAIL_NOTIFICATIONS;
    }
    private set;
  }

  /**
   * @description Indicates if Nebula Logger will store the transaction heap limits on `LogEntry__c`, retrieved from the class `System.Limits`.
   *              Controlled by the custom metadata record `LoggerParameter.StoreApexHeapSizeLimit`, or `true` as the default.
   *              Relies on `LoggerParameter.StoreTransactionLimits` to be true, as well.
   */
  public static final Boolean STORE_HEAP_SIZE_LIMIT {
    get {
      if (STORE_HEAP_SIZE_LIMIT == null) {
        STORE_HEAP_SIZE_LIMIT = getBoolean('StoreHeapSizeLimit', true);
      }
      return STORE_HEAP_SIZE_LIMIT;
    }
    private set;
  }

  /**
   * @description Indicates if Nebula Logger will store the header values when logging an instance of `System.HttpRequest`.
   *              Controlled by the custom metadata record `LoggerParameter.StoreHttpRequestHeaderValues`, or `true` as the default.
   *              Regardless of how this parameter is configured, Nebula Logger will still log the specified list of header keys of any instance of
   *              `System.HttpRequest` that is logged - this parameter only controls if the header values are stored.
   */
  public static final Boolean STORE_HTTP_REQUEST_HEADER_VALUES {
    get {
      if (STORE_HTTP_REQUEST_HEADER_VALUES == null) {
        STORE_HTTP_REQUEST_HEADER_VALUES = getBoolean('StoreHttpRequestHeaderValues', true);
      }
      return STORE_HTTP_REQUEST_HEADER_VALUES;
    }
    private set;
  }

  /**
   * @description Indicates if Nebula Logger will store the header values when logging an instance of `System.HttpResponse`.
   *              Controlled by the custom metadata record `LoggerParameter.StoreHttpResponseHeaderValues`, or `true` as the default.
   *              Regardless of how this parameter is configured, Nebula Logger will still log the header keys of any instance of
   *              `System.HttpResponse` that is logged - this parameter only controls if the header values are stored.
   */
  public static final Boolean STORE_HTTP_RESPONSE_HEADER_VALUES {
    get {
      if (STORE_HTTP_RESPONSE_HEADER_VALUES == null) {
        STORE_HTTP_RESPONSE_HEADER_VALUES = getBoolean('StoreHttpResponseHeaderValues', true);
      }
      return STORE_HTTP_RESPONSE_HEADER_VALUES;
    }
    private set;
  }

  /**
   * @description Indicates if Nebula Logger will store the organization limits on `Log__c`, retrieved from the class `System.OrgLimits`.
   *              Controlled by the custom metadata record `LoggerParameter.StoreOrganizationLimits`, or `true` as the default.
   */
  public static final Boolean STORE_ORGANIZATION_LIMITS {
    get {
      if (STORE_ORGANIZATION_LIMITS == null) {
        STORE_ORGANIZATION_LIMITS = getBoolean('StoreOrganizationLimits', true);
      }
      return STORE_ORGANIZATION_LIMITS;
    }
    private set;
  }

  /**
   * @description Indicates if Nebula Logger will store the header values when logging an instance of `System.RestRequest`.
   *              Controlled by the custom metadata record `LoggerParameter.StoreRestRequestHeaderValues`, or `true` as the default.
   *              Regardless of how this parameter is configured, Nebula Logger will still log the header keys of any instance of
   *              `System.RestRequest` that is logged - this parameter only controls if the header values are stored.
   */
  public static final Boolean STORE_REST_REQUEST_HEADER_VALUES {
    get {
      if (STORE_REST_REQUEST_HEADER_VALUES == null) {
        STORE_REST_REQUEST_HEADER_VALUES = getBoolean('StoreRestRequestHeaderValues', true);
      }
      return STORE_REST_REQUEST_HEADER_VALUES;
    }
    private set;
  }

  /**
   * @description Indicates if Nebula Logger will store the header values when logging an instance of `System.RestResponse`.
   *              Controlled by the custom metadata record `LoggerParameter.StoreRestResponseHeaderValues`, or `true` as the default.
   *              Regardless of how this parameter is configured, Nebula Logger will still log the header keys of any instance of
   *              `System.RestResponse` that is logged - this parameter only controls if the header values are stored.
   */
  public static final Boolean STORE_REST_RESPONSE_HEADER_VALUES {
    get {
      if (STORE_REST_RESPONSE_HEADER_VALUES == null) {
        STORE_REST_RESPONSE_HEADER_VALUES = getBoolean('StoreRestResponseHeaderValues', true);
      }
      return STORE_REST_RESPONSE_HEADER_VALUES;
    }
    private set;
  }

  /**
   * @description Indicates if Nebula Logger will store the transaction limits on `LogEntry__c`, retrieved from the class `System.Limits`.
   *              Controlled by the custom metadata record `LoggerParameter.StoreTransactionLimits`, or `true` as the default.
   */
  public static final Boolean STORE_TRANSACTION_LIMITS {
    get {
      if (STORE_TRANSACTION_LIMITS == null) {
        STORE_TRANSACTION_LIMITS = getBoolean('StoreTransactionLimits', true);
      }
      return STORE_TRANSACTION_LIMITS;
    }
    private set;
  }

  /**
   * @description The merge-field syntax to use when calling System.debug().
   *              Controlled by the custom metadata record `LoggerParameter.SystemDebugMessageFormat`, or `{OriginLocation__c}\n{Message__c}` as the default
   */
  public static final String SYSTEM_DEBUG_MESSAGE_FORMAT {
    get {
      if (SYSTEM_DEBUG_MESSAGE_FORMAT == null) {
        SYSTEM_DEBUG_MESSAGE_FORMAT = getString(SYSTEM_DEBUG_MESSAGE_FORMAT_PARAMETER, '{OriginLocation__c}\n{Message__c}');
      }
      return SYSTEM_DEBUG_MESSAGE_FORMAT;
    }
    private set;
  }

  /**
   * @description Indicates if `Logger.setScenario(String)` uses the first specified value (when `true`), or the last specified value (when `false`)
   *              Controlled by the custom metadata record `LoggerParameter.UseFirstSpecifiedScenario`, or `true` as the default
   */
  public static final Boolean USE_FIRST_SCENARIO_FOR_TRANSACTION {
    get {
      if (USE_FIRST_SCENARIO_FOR_TRANSACTION == null) {
        USE_FIRST_SCENARIO_FOR_TRANSACTION = getBoolean('UseFirstSpecifiedScenario', true);
      }
      return USE_FIRST_SCENARIO_FOR_TRANSACTION;
    }
    private set;
  }

  /**
   * @description Indicates if Platform Cache is used to cache organization & session data in the cache partition `LoggerCache`
   *              Controlled by the custom metadata record `LoggerParameter.UsePlatformCache`, or `true` as the default
   */
  public static final Boolean USE_PLATFORM_CACHE {
    get {
      if (USE_PLATFORM_CACHE == null) {
        USE_PLATFORM_CACHE = getBoolean('UsePlatformCache', true);
      }
      return USE_PLATFORM_CACHE;
    }
    private set;
  }

  /**
   * @description Indicates if Logger's tagging will use `Schema.Topic` and `Schema.TopicAssignment` for storing tags (when `true`),
   *              or uses Nebula Logger's custom objects `LoggerTag__c` and `LogEntryTag__c` (when `false`)
   *              Controlled by the custom metadata record `LoggerParameter.UseTopicsForTags`, or `false` as the default
   */
  public static final Boolean USE_TOPICS_FOR_TAGS {
    get {
      if (USE_TOPICS_FOR_TAGS == null) {
        USE_TOPICS_FOR_TAGS = getBoolean('UseTopicsForTags', false);
      }
      return USE_TOPICS_FOR_TAGS;
    }
    private set;
  }

  private static final Map<String, LoggerParameter__mdt> DEVELOPER_NAME_TO_RECORD {
    get {
      if (DEVELOPER_NAME_TO_RECORD == null) {
        DEVELOPER_NAME_TO_RECORD = loadRecords();
      }
      return DEVELOPER_NAME_TO_RECORD;
    }
    private set;
  }

  /**
   * @description Returns the configured value of the field `Value__c` as a `Boolean`
   * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
   * @param  defaultValue           A default value to return instead of null
   * @return                        The `Boolean` value configured in the matching instance of `LoggerParameter__mdt`
   *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
   */
  public static Boolean getBoolean(String parameterDeveloperName, Boolean defaultValue) {
    Boolean parameterValue = (Boolean) castParameterValue(parameterDeveloperName, Boolean.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description Returns the configured value of the field `Value__c` as a `List<Boolean>`
   * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
   * @param  defaultValue           A default value to return instead of null
   * @return                        The `List<Boolean>` value configured in the matching instance of `LoggerParameter__mdt`
   *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
   */
  public static List<Boolean> getBooleanList(String parameterDeveloperName, List<Boolean> defaultValue) {
    List<Boolean> parameterValue = (List<Boolean>) castParameterValue(parameterDeveloperName, List<Boolean>.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description Returns the configured value of the field `Value__c` as a `Date`
   * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
   * @param  defaultValue           A default value to return instead of null
   * @return                        The `Date` value configured in the matching instance of `LoggerParameter__mdt`
   *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
   */
  public static Date getDate(String parameterDeveloperName, Date defaultValue) {
    Date parameterValue = (Date) castParameterValue(parameterDeveloperName, Date.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description Returns the configured value of the field `Value__c` as a `List<Date>`
   * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
   * @param  defaultValue           A default value to return instead of null
   * @return                        The `List<Date>` value configured in the matching instance of `LoggerParameter__mdt`
   *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
   */
  public static List<Date> getDateList(String parameterDeveloperName, List<Date> defaultValue) {
    List<Date> parameterValue = (List<Date>) castParameterValue(parameterDeveloperName, List<Date>.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description Returns the configured value of the field `Value__c` as a `Datetime`
   * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
   * @param  defaultValue           A default value to return instead of null
   * @return                        The `Datetime` value configured in the matching instance of `LoggerParameter__mdt`
   *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
   */
  public static Datetime getDatetime(String parameterDeveloperName, Datetime defaultValue) {
    Datetime parameterValue = (Datetime) castParameterValue(parameterDeveloperName, Datetime.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description Returns the configured value of the field `Value__c` as a `List<Datetime>`
   * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
   * @param  defaultValue           A default value to return instead of null
   * @return                        The `List<Datetime>` value configured in the matching instance of  `LoggerParameter__mdt`
   *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
   */
  public static List<Datetime> getDatetimeList(String parameterDeveloperName, List<Datetime> defaultValue) {
    List<Datetime> parameterValue = (List<Datetime>) castParameterValue(parameterDeveloperName, List<Datetime>.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description Returns the configured value of the field `Value__c` as a `Decimal`
   * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
   * @param  defaultValue           A default value to return instead of null
   * @return                        The `Decimal` value configured in the matching instance of `LoggerParameter__mdt`
   *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
   */
  public static Decimal getDecimal(String parameterDeveloperName, Decimal defaultValue) {
    Decimal parameterValue = (Decimal) castParameterValue(parameterDeveloperName, Decimal.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description Returns the configured value of the field `Value__c` as a `List<Decimal>`
   * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
   * @param  defaultValue           A default value to return instead of null
   * @return                        The `List<Decimal>` value configured in the matching instance of `LoggerParameter__mdt`
   *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
   */
  public static List<Decimal> getDecimalList(String parameterDeveloperName, List<Decimal> defaultValue) {
    List<Decimal> parameterValue = (List<Decimal>) castParameterValue(parameterDeveloperName, List<Decimal>.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description Returns the configured value of the field `Value__c` as a `Double`
   * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
   * @param  defaultValue           A default value to return instead of null
   * @return                        The `Double` value configured in the matching instance of `LoggerParameter__mdt`
   *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
   */
  public static Double getDouble(String parameterDeveloperName, Double defaultValue) {
    Double parameterValue = (Double) castParameterValue(parameterDeveloperName, Double.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description Returns the configured value of the field `Value__c` as a `List<Double>`
   * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
   * @param  defaultValue           A default value to return instead of null
   * @return                        The `List<Double>` value configured in the matching instance of LLoggerParameter__mdt`
   *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
   */
  public static List<Double> getDoubleList(String parameterDeveloperName, List<Double> defaultValue) {
    List<Double> parameterValue = (List<Double>) castParameterValue(parameterDeveloperName, List<Double>.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description Returns the configured value of the field `Value__c` as a `Id`
   * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
   * @param  defaultValue           A default value to return instead of null
   * @return                        The `Id` value configured in the matching instance of `LoggerParameter__mdt`
   *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
   */
  public static Id getId(String parameterDeveloperName, Id defaultValue) {
    Id parameterValue = (Id) castParameterValue(parameterDeveloperName, Id.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description Returns the configured value of the field `Value__c` as a `List<Id>`
   * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
   * @param  defaultValue           A default value to return instead of null
   * @return                        The `List<Id>` value configured in the matching instance of `LoggerParameter__mdt`
   *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
   */
  public static List<Id> getIdList(String parameterDeveloperName, List<Id> defaultValue) {
    List<Id> parameterValue = (List<Id>) castParameterValue(parameterDeveloperName, List<Id>.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description Returns the configured value of the field `Value__c` as a `Integer`
   * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
   * @param  defaultValue           A default value to return instead of null
   * @return                        The `Integer` value configured in the matching instance of `LoggerParameter__mdt`
   *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
   */
  public static Integer getInteger(String parameterDeveloperName, Integer defaultValue) {
    Integer parameterValue = (Integer) castParameterValue(parameterDeveloperName, Integer.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description Returns the configured value of the field `Value__c` as a `List<Integer>`
   * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
   * @param  defaultValue           A default value to return instead of null
   * @return                        The `List<Integer>` value configured in the matching instance of `LoggerParameter__mdt`
   *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
   */
  public static List<Integer> getIntegerList(String parameterDeveloperName, List<Integer> defaultValue) {
    List<Integer> parameterValue = (List<Integer>) castParameterValue(parameterDeveloperName, List<Integer>.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description Returns the configured value of the field `Value__c` as a `Long`
   * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
   * @param  defaultValue           A default value to return instead of null
   * @return                        The `Long` value configured in the matching instance of `LoggerParameter__mdt`
   *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
   */
  public static Long getLong(String parameterDeveloperName, Long defaultValue) {
    Long parameterValue = (Long) castParameterValue(parameterDeveloperName, Long.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description Returns the configured value of the field `Value__c` as a `List<Long>`
   * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
   * @param  defaultValue           A default value to return instead of null
   * @return                        The `List<Long>` value configured in the matching instance of `LoggerParameter__mdt`
   *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
   */
  public static List<Long> getLongList(String parameterDeveloperName, List<Long> defaultValue) {
    List<Long> parameterValue = (List<Long>) castParameterValue(parameterDeveloperName, List<Long>.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description Returns the configured value of the field `Value__c` as a `SObject`
   * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
   * @param  defaultValue           A default value to return instead of null
   * @return                        The `SObject` value configured in the matching instance of `LoggerParameter__mdt`
   *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
   */
  public static SObject getSObject(String parameterDeveloperName, SObject defaultValue) {
    SObject parameterValue = (SObject) castParameterValue(parameterDeveloperName, SObject.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description Returns the configured value of the field `Value__c` as a `List<SObject>`
   * @param  parameterDeveloperName The developer name of the instance of `LoggerParameter__mdt`
   * @param  defaultValue           A default value to return instead of null
   * @return                        The `List<SObject>` value configured in the matching instance of `LoggerParameter__mdt`
   *                                Returns the supplied `defaultValue` when no matching parameter is found, or the parameter value is null
   */
  public static List<SObject> getSObjectList(String parameterDeveloperName, List<SObject> defaultValue) {
    List<SObject> parameterValue = (List<SObject>) castParameterValue(parameterDeveloperName, List<SObject>.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description This method returns the actual parameter if it exists, or if it's empty returns the default value.
   * @param parameterDeveloperName The parameter to return if it exists.
   * @param defaultValue The default value to return when the parameter doesn't exist.
   * @return A string that's retrieved using the parameter if it's not empty, otherwise the string is defaulted to defaultValue.
   */
  public static String getString(String parameterDeveloperName, String defaultValue) {
    // Since the Value__c field is already a String, this method skips using the method castParameterValue
    String parameterValue = loadParameterValue(parameterDeveloperName);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description This method returns the value of the parameter if it exists (cast as a list of strings), or if it's empty returns the default list.
   * @param parameterDeveloperName The parameter of the list to return if it exists.
   * @param defaultValue The default list to return when the parameter / value doesn't exist.
   * @return A list that's retrieved using the parameter if it's not null, otherwise the default list is returned.
   */
  public static List<String> getStringList(String parameterDeveloperName, List<String> defaultValue) {
    List<String> parameterValue = (List<String>) castParameterValue(parameterDeveloperName, List<String>.class);
    return parameterValue != null ? parameterValue : defaultValue;
  }

  /**
   * @description matchOnPrefix description
   * @param  developerNamePrefix A prefix that has been used in the `DeveloperName` for multiple `LoggerParameter__mdt` records
   * @return                     The list of matching `LoggerParameter__mdt` records
   */
  public static List<LoggerParameter__mdt> matchOnPrefix(String developerNamePrefix) {
    List<LoggerParameter__mdt> matchingParameters = new List<LoggerParameter__mdt>();
    for (String parameterDeveloperName : DEVELOPER_NAME_TO_RECORD.keySet()) {
      if (parameterDeveloperName.startsWith(developerNamePrefix)) {
        matchingParameters.add(DEVELOPER_NAME_TO_RECORD.get(parameterDeveloperName));
      }
    }
    return matchingParameters;
  }

  @TestVisible
  private static void setMock(LoggerParameter__mdt parameter) {
    if (String.isBlank(parameter.DeveloperName)) {
      throw new System.IllegalArgumentException('DeveloperName is required on `LoggerParameter__mdt: \n' + System.JSON.serializePretty(parameter));
    }

    DEVELOPER_NAME_TO_RECORD.put(parameter.DeveloperName, parameter);
  }

  private static Map<String, LoggerParameter__mdt> loadRecords() {
    Map<String, LoggerParameter__mdt> parameters = LoggerParameter__mdt.getAll().clone();
    if (System.Test.isRunningTest()) {
      // Keep a copy of any records that *should* be loaded during tests
      // Currently, only the record `SystemDebugMessageFormat` has a use case for this functionality,
      // but others can be easily added if other use cases are found
      Map<String, LoggerParameter__mdt> parametersToLoadDuringTests = new Map<String, LoggerParameter__mdt>();
      for (String testContextParameterName : PARAMETERS_TO_LOAD_DURING_TESTS) {
        if (parameters.containsKey(testContextParameterName)) {
          parametersToLoadDuringTests.put(testContextParameterName, parameters.get(testContextParameterName));
        }
      }
      parameters.clear();
      parameters.putAll(parametersToLoadDuringTests);
    }
    return parameters;
  }

  private static Object castParameterValue(String parameterDeveloperName, System.Type dataType) {
    String parameterValue = loadParameterValue(parameterDeveloperName);
    if (parameterValue == null) {
      return null;
    } else {
      return System.JSON.deserialize(parameterValue, dataType);
    }
  }

  private static String loadParameterValue(String parameterDeveloperName) {
    return DEVELOPER_NAME_TO_RECORD.get(parameterDeveloperName)?.Value__c;
  }
}
