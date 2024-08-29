---
layout: default
---

## LoggerParameter class

Provides a centralized way to load parameters for SObject handlers &amp; plugins, and casts the parameters to common data types

---

### Properties

#### `CALL_STATUS_API` → `Boolean`

Indicates if Nebula Logger will make an async callout to `https://api.status.salesforce.com` to get additional details about the current org, which is then stored on the Log\_\_c record. Controlled by the custom metadata record `LoggerParameter.CallStatusApi`, or `false` as the default

#### `DEFAULT_LOG_ENTRY_RELATED_LIST_FIELD_SET` → `String`

The name of the `LogEntry__c` field set to use as the default field set when configuring the LWC `&lt;c-related-log-entries&gt;` within App Builder. Controlled by the custom metadata record `LoggerParameter.DefaultLogEntryRelatedListFieldSet`, or `Related_List_Defaults` as the default

#### `ENABLE_LOG_ENTRY_EVENT_STREAM` → `Boolean`

Indicates if Nebula Logger&apos;s LWC `logEntryEventStream` is enabled. The component uses the Emp API, which counts towards orgs&apos; daily delivery allocations for platform events. To help reduce usage of the daily allocation limit, orgs can disable the LWC. Controlled by the custom metadata record `LoggerParameter.EnableLogEntryEventStream`, or `true` as the default

#### `ENABLE_STACK_TRACE_PARSING` → `Boolean`

Indicates if Nebula Logger will parse a stack trace for each log entry, which is then used to populate fields like `LogEntry__c.StackTrace__c` and `LogEntry__c.OriginLocation__c`. Controlled by the custom metadata record `LoggerParameter.EnableStackTraceParsing`, or `true` as the default

#### `ENABLE_SYSTEM_MESSAGES` → `Boolean`

Indicates if Nebula Logger will append its own log entries about the logging system. Controlled by the custom metadata record `LoggerParameter.EnableLoggerSystemMessages`, or `false` as the default

#### `ENABLE_TAGGING` → `Boolean`

Indicates if Nebula Logger&apos;s tagging system is enabled. Controlled by the custom metadata record `LoggerParameter.EnableTagging`, or `true` as the default

#### `NORMALIZE_SCENARIO_DATA` → `Boolean`

Indicates if Nebula Logger will store scenarios in the custom object `LoggerScenario__c`, or in the fields `Log__c.TransactionScenarioName__c` &amp; `LogEntry__c.EntryScenario__c`. Controlled by the custom metadata record `LoggerParameter.NormalizeScenarioData`, or `true` as the default

#### `NORMALIZE_TAG_DATA` → `Boolean`

Indicates if Nebula Logger will store tags in the custom objects `LoggerTag__c` &amp; `LogEntryTag__c`, or in the field `LogEntry__c.Tags__c`. Controlled by the custom metadata record `LoggerParameter.NormalizeTagData`, or `true` as the default

#### `PLATFORM_CACHE_PARTITION_NAME` → `String`

The name of the Platform Cache partition to use for caching (when platform cache is enabled). Controlled by the custom metadata record `LoggerParameter.PlatformCachePartitionName`, or `LoggerCache` as the default

#### `QUERY_APEX_CLASS_DATA` → `Boolean`

Controls if Nebula Logger queries `Schema.ApexClass` data. When set to `false`, any `Schema.ApexClass` fields on `LogEntryEvent__e` and `Log__c` will not be populated Controlled by the custom metadata record `LoggerParameter.QueryApexClassData`, or `true` as the default

#### `QUERY_APEX_TRIGGER_DATA` → `Boolean`

Controls if Nebula Logger queries `Schema.ApexTrigger` data. When set to `false`, any `Schema.ApexTrigger` fields on `LogEntryEvent__e` and `Log__c` will not be populated Controlled by the custom metadata record `LoggerParameter.QueryApexTriggerData`, or `true` as the default

#### `QUERY_AUTH_SESSION_DATA` → `Boolean`

Controls if Nebula Logger queries `Schema.AuthSession` data. When set to `false`, any `Schema.AuthSession` fields on `LogEntryEvent__e` and `Log__c` will not be populated Controlled by the custom metadata record `LoggerParameter.QueryAuthSessionData`, or `true` as the default

#### `QUERY_AUTH_SESSION_DATA_SYNCHRONOUSLY` → `Boolean`

Controls if Nebula Logger queries `Schema.AuthSession` data synchronously &amp; populated on `LogEntryEvent__e` records. When set to `false`, any `Schema.AuthSession` fields on `LogEntryEvent__e` will not be populated - the data will instead be queried asynchronously and populated on any resulting `Log__c` records. Controlled by the custom metadata record `LoggerParameter.QueryAuthSessionDataSynchronously`, or `true` as the default

#### `QUERY_FLOW_DEFINITION_VIEW_DATA` → `Boolean`

Controls if Nebula Logger queries `Schema.FlowDefinitionView` data. When set to `false`, any `Schema.FlowDefinitionView` fields on `LogEntryEvent__e` and `Log__c` will not be populated Controlled by the custom metadata record `LoggerParameter.QueryFlowDefinitionViewData`, or `true` as the default

#### `QUERY_NETWORK_DATA` → `Boolean`

Controls if Nebula Logger queries `Schema.Network` data. When set to `false`, any `Schema.Network` fields on `LogEntryEvent__e` and `Log__c` will not be populated Controlled by the custom metadata record `LoggerParameter.QueryNetworkData`, or `true` as the default

#### `QUERY_NETWORK_DATA_SYNCHRONOUSLY` → `Boolean`

Controls if Nebula Logger queries `Schema.Network` data is queried synchronously &amp; populated on `LogEntryEvent__e` records. When set to `false`, any `Schema.Network` fields on `LogEntryEvent__e` will not be populated - the data will instead be queried asynchronously and populated on any resulting `Log__c` records. Controlled by the custom metadata record `LoggerParameter.QueryNetworkDataSynchronously`, or `true` as the default

#### `QUERY_ORGANIZATION_DATA` → `Boolean`

Controls if Nebula Logger queries `Schema.Organization` data. When set to `false`, any `Schema.Organization` fields on `LogEntryEvent__e` and `Log__c` will not be populated Controlled by the custom metadata record `LoggerParameter.QueryOrganizationData`, or `true` as the default

#### `QUERY_ORGANIZATION_DATA_SYNCHRONOUSLY` → `Boolean`

Indicates if Nebula Logger queries `Schema.Organization` data is queried synchronously &amp; populated on `LogEntryEvent__e` records. When set to `false`, any `Schema.Organization` fields on `LogEntryEvent__e` will not be populated - the data will instead be queried asynchronously and populated on any resulting `Log__c` records. Controlled by the custom metadata record `LoggerParameter.QueryOrganizationDataSynchronously`, or `true` as the default

#### `QUERY_RELATED_RECORD_DATA` → `Boolean`

Controls if Nebula Logger queries data for records synthetically related to a `LogEntry__c` via `LogEntry__c.RecordId__c`. When set to `false`, any fields on `LogEntry__c` related to `LogEntry__c.RecordId__c` not be populated Controlled by the custom metadata record `LoggerParameter.QueryRelatedRecordData`, or `true` as the default

#### `QUERY_USER_DATA` → `Boolean`

Controls if Nebula Logger queries `Schema.User` data. When set to `false`, any `Schema.User` fields on `LogEntryEvent__e` and `Log__c` will not be populated Controlled by the custom metadata record `LoggerParameter.QueryUserData`, or `true` as the default

#### `QUERY_USER_DATA_SYNCHRONOUSLY` → `Boolean`

Indicates if Nebula Logger queries `Schema.User` data is queried synchronously &amp; populated on `LogEntryEvent__e` records. When set to `false`, any `Schema.User` fields on `LogEntryEvent__e` that rely on querying will not be populated - the data will instead be queried asynchronously and populated on any resulting `Log__c` records. Controlled by the custom metadata record `LoggerParameter.QueryUserDataSynchronously`, or `true` as the default

#### `REQUIRE_SCENARIO_USAGE` → `Boolean`

Indicates if Nebula Logger will enforce scenario-based logging to be used. When set to `false`, specifying a scenario is completely optional. When set to `true`, a scenario is required to be set before any logging can occur. If a logging method is called &amp;amp; the current scenario is null/blank, then Nebula Logger will throw a runtime exception. Controlled by the custom metadata record `LoggerParameter.RequireScenarioUsage`, or `false` as the default

#### `SEND_ERROR_EMAIL_NOTIFICATIONS` → `Boolean`

Indicates if Nebula Logger will send an error email notification if any internal exceptions occur. Controlled by the custom metadata record `LoggerParameter.SendErrorEmailNotifications`, or `true` as the default

#### `STORE_HEAP_SIZE_LIMIT` → `Boolean`

Indicates if Nebula Logger will store the transaction heap limits on `LogEntry__c`, retrieved from the class `System.Limits`. Controlled by the custom metadata record `LoggerParameter.StoreApexHeapSizeLimit`, or `true` as the default. Relies on `LoggerParameter.StoreTransactionLimits` to be true, as well.

#### `STORE_HTTP_REQUEST_HEADER_VALUES` → `Boolean`

Indicates if Nebula Logger will store the header values when logging an instance of `System.HttpRequest`. Controlled by the custom metadata record `LoggerParameter.StoreHttpRequestHeaderValues`, or `true` as the default. Regardless of how this parameter is configured, Nebula Logger will still log the header keys of any instance of `System.HttpRequest` that is logged - this parameter only controls if the header values are stored.

#### `STORE_HTTP_RESPONSE_HEADER_VALUES` → `Boolean`

Indicates if Nebula Logger will store the header values when logging an instance of `System.HttpRequest`. Controlled by the custom metadata record `LoggerParameter.StoreHttpResponseHeaderValues`, or `true` as the default. Regardless of how this parameter is configured, Nebula Logger will still log the header keys of any instance of `System.HttpResponse` that is logged - this parameter only controls if the header values are stored.

#### `STORE_ORGANIZATION_LIMITS` → `Boolean`

Indicates if Nebula Logger will store the organization limits on `Log__c`, retrieved from the class `System.OrgLimits`. Controlled by the custom metadata record `LoggerParameter.StoreOrganizationLimits`, or `true` as the default.

#### `STORE_REST_REQUEST_HEADER_VALUES` → `Boolean`

Indicates if Nebula Logger will store the header values when logging an instance of `System.RestRequest`. Controlled by the custom metadata record `LoggerParameter.StoreRestRequestHeaderValues`, or `true` as the default. Regardless of how this parameter is configured, Nebula Logger will still log the header keys of any instance of `System.RestRequest` that is logged - this parameter only controls if the header values are stored.

#### `STORE_REST_RESPONSE_HEADER_VALUES` → `Boolean`

Indicates if Nebula Logger will store the header values when logging an instance of `System.RestResponse`. Controlled by the custom metadata record `LoggerParameter.StoreRestResponseHeaderValues`, or `true` as the default. Regardless of how this parameter is configured, Nebula Logger will still log the header keys of any instance of `System.RestResponse` that is logged - this parameter only controls if the header values are stored.

#### `STORE_TRANSACTION_LIMITS` → `Boolean`

Indicates if Nebula Logger will store the transaction limits on `LogEntry__c`, retrieved from the class `System.Limits`. Controlled by the custom metadata record `LoggerParameter.StoreTransactionLimits`, or `true` as the default.

#### `SYSTEM_DEBUG_MESSAGE_FORMAT` → `String`

The merge-field syntax to use when calling System.debug(). Controlled by the custom metadata record `LoggerParameter.SystebugMessageFormat`, or `{OriginLocation__c}\n{Message__c}` as the default

#### `USE_FIRST_SCENARIO_FOR_TRANSACTION` → `Boolean`

Indicates if `Logger.setScenario(String)` uses the first specified value (when `true`), or the last specified value (when `false`) Controlled by the custom metadata record `LoggerParameter.UseFirstSpecifiedScenario`, or `true` as the default

#### `USE_PLATFORM_CACHE` → `Boolean`

Indicates if Platform Cache is used to cache organization &amp; session data in the cache partition `LoggerCache` Controlled by the custom metadata record `LoggerParameter.UsePlatformCache`, or `true` as the default

#### `USE_TOPICS_FOR_TAGS` → `Boolean`

Indicates if Logger&apos;s tagging will use `Schema.Topic` and `Schema.TopicAssignment` for storing tags (when `true`), or uses Nebula Logger&apos;s custom objects `LoggerTag__c` and `LogEntryTag__c` (when `false`) Controlled by the custom metadata record `LoggerParameter.UseTopicsForTags`, or `false` as the default

---

### Methods

#### `getBoolean(String parameterDeveloperName, Boolean defaultValue)` → `Boolean`

Returns the configured value of the field `Value__c` as a `Boolean`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

Boolean

**Description**

The `Boolean` value configured in the matching instance of `LoggerParameter_t`

#### `getBooleanList(String parameterDeveloperName, List<Boolean> defaultValue)` → `List<Boolean>`

Returns the configured value of the field `Value__c` as a `List&lt;Boolean&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

List&lt;Boolean&gt;

**Description**

The `List&lt;Boolean&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getDate(String parameterDeveloperName, Date defaultValue)` → `Date`

Returns the configured value of the field `Value__c` as a `Date`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

Date

**Description**

The `Date` value configured in the matching instance of `LoggerParameter_t`

#### `getDateList(String parameterDeveloperName, List<Date> defaultValue)` → `List<Date>`

Returns the configured value of the field `Value__c` as a `List&lt;Date&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

List&lt;Date&gt;

**Description**

The `List&lt;Date&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getDatetime(String parameterDeveloperName, Datetime defaultValue)` → `Datetime`

Returns the configured value of the field `Value__c` as a `Datetime`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

Datetime

**Description**

The `Datetime` value configured in the matching instance of `LoggerParameter_t`

#### `getDatetimeList(String parameterDeveloperName, List<Datetime> defaultValue)` → `List<Datetime>`

Returns the configured value of the field `Value__c` as a `List&lt;Datetime&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

List&lt;Datetime&gt;

**Description**

The `List&lt;Datetime&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getDecimal(String parameterDeveloperName, Decimal defaultValue)` → `Decimal`

Returns the configured value of the field `Value__c` as a `Decimal`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

Decimal

**Description**

The `Decimal` value configured in the matching instance of `LoggerParameter_t`

#### `getDecimalList(String parameterDeveloperName, List<Decimal> defaultValue)` → `List<Decimal>`

Returns the configured value of the field `Value__c` as a `List&lt;Decimal&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

List&lt;Decimal&gt;

**Description**

The `List&lt;Decimal&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getDouble(String parameterDeveloperName, Double defaultValue)` → `Double`

Returns the configured value of the field `Value__c` as a `Double`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

Double

**Description**

The `Double` value configured in the matching instance of `LoggerParameter_t`

#### `getDoubleList(String parameterDeveloperName, List<Double> defaultValue)` → `List<Double>`

Returns the configured value of the field `Value__c` as a `List&lt;Double&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

List&lt;Double&gt;

**Description**

The `List&lt;Double&gt;` value configured in the matching instance of LLoggerParameter_t`

#### `getId(String parameterDeveloperName, Id defaultValue)` → `Id`

Returns the configured value of the field `Value__c` as a `Id`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

Id

**Description**

The `Id` value configured in the matching instance of `LoggerParameter_t`

#### `getIdList(String parameterDeveloperName, List<Id> defaultValue)` → `List<Id>`

Returns the configured value of the field `Value__c` as a `List&lt;Id&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

List&lt;Id&gt;

**Description**

The `List&lt;Id&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getInteger(String parameterDeveloperName, Integer defaultValue)` → `Integer`

Returns the configured value of the field `Value__c` as a `Integer`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

Integer

**Description**

The `Integer` value configured in the matching instance of `LoggerParameter_t`

#### `getIntegerList(String parameterDeveloperName, List<Integer> defaultValue)` → `List<Integer>`

Returns the configured value of the field `Value__c` as a `List&lt;Integer&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

List&lt;Integer&gt;

**Description**

The `List&lt;Integer&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getLong(String parameterDeveloperName, Long defaultValue)` → `Long`

Returns the configured value of the field `Value__c` as a `Long`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

Long

**Description**

The `Long` value configured in the matching instance of `LoggerParameter_t`

#### `getLongList(String parameterDeveloperName, List<Long> defaultValue)` → `List<Long>`

Returns the configured value of the field `Value__c` as a `List&lt;Long&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

List&lt;Long&gt;

**Description**

The `List&lt;Long&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getSObject(String parameterDeveloperName, SObject defaultValue)` → `SObject`

Returns the configured value of the field `Value__c` as a `SObject`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

SObject

**Description**

The `SObject` value configured in the matching instance of `LoggerParameter_t`

#### `getSObjectList(String parameterDeveloperName, List<SObject> defaultValue)` → `List<SObject>`

Returns the configured value of the field `Value__c` as a `List&lt;SObject&gt;`

##### Parameters

| Param                    | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `parameterDeveloperName` | The developer name of the instance of `LoggerParameter_t` |
| `defaultValue`           | A default value to return instead of null                 |

##### Return

**Type**

List&lt;SObject&gt;

**Description**

The `List&lt;SObject&gt;` value configured in the matching instance of `LoggerParameter_t`

#### `getString(String parameterDeveloperName, String defaultValue)` → `String`

This method returns the actual parameter if it exists, or if it&apos;s empty returns the default value.

##### Parameters

| Param                    | Description                                                        |
| ------------------------ | ------------------------------------------------------------------ |
| `parameterDeveloperName` | The parameter to return if it exists.                              |
| `defaultValue`           | The default value to return when the parameter doesn&apos;t exist. |

##### Return

**Type**

String

**Description**

A string that&apos;s retrieved using the parameter if it&apos;s not empty, otherwise the string is defaulted to defaultValue.

#### `getStringList(String parameterDeveloperName, List<String> defaultValue)` → `List<String>`

This method returns the value of the parameter if it exists (cast as a list of strings), or if it&apos;s empty returns the default list.

##### Parameters

| Param                    | Description                                                               |
| ------------------------ | ------------------------------------------------------------------------- |
| `parameterDeveloperName` | The parameter of the list to return if it exists.                         |
| `defaultValue`           | The default list to return when the parameter / value doesn&apos;t exist. |

##### Return

**Type**

List&lt;String&gt;

**Description**

A list that&apos;s retrieved using the parameter if it&apos;s not null, otherwise the default list is returned.

#### `matchOnPrefix(String developerNamePrefix)` → `List<LoggerParameter_t>`

matchOnPrefix description

##### Parameters

| Param                 | Description                                                                                 |
| --------------------- | ------------------------------------------------------------------------------------------- |
| `developerNamePrefix` | A prefix that has been used in the `DeveloperName` for multiple `LoggerParameter_t` records |

##### Return

**Type**

List&lt;LoggerParameter_t&gt;

**Description**

The list of matching `LoggerParameter_t` records

---
