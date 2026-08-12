---
title: LogEntry__c
description: 'Nebula Logger customobject reference: LogEntry__c.'
---

# Log Entry

Used by Nebula Logger to represent a single log message within a transaction - log entries can be generated via Apex, Flow, Process Builder, Lightning Web Components, and Aura Components.

## API Name

`LogEntry__c`

## Fields

### Apex Class API Version

For more details, refer to https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_apexclass.htm

**API Name**

`ApexClassApiVersion__c`

**Type**

_Picklist_

#### Possible values are

- v66.0
- v65.0

---

### Apex Class Created Date

**API Name**

`ApexClassCreatedDate__c`

**Type**

_DateTime_

---

### Apex Class ID

For more details, refer to https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_apexclass.htm

**API Name**

`ApexClassId__c`

**Type**

_Text_

---

### Apex Class Last Modified Date

**API Name**

`ApexClassLastModifiedDate__c`

**Type**

_DateTime_

---

### Apex Class

**API Name**

`ApexClassName__c`

**Type**

_Text_

---

### Apex Inner Class

**API Name**

`ApexInnerClassName__c`

**Type**

_Text_

---

### Apex Method

**API Name**

`ApexMethodName__c`

**Type**

_Text_

---

### Browser Address

**API Name**

`BrowserAddress__c`

**Type**

_LongTextArea_

---

### Browser Form Factor

**API Name**

`BrowserFormFactor__c`

**Type**

_Picklist_

#### Possible values are

- Large
- Medium
- Small

---

### Browser Language

**API Name**

`BrowserLanguage__c`

**Type**

_Text_

---

### Browser Screen Resolution

**API Name**

`BrowserScreenResolution__c`

**Type**

_Text_

---

### DEPRECATED: Browser URL

**API Name**

`BrowserUrl__c`

**Type**

_Url_

---

### Browser User Agent

**API Name**

`BrowserUserAgent__c`

**Type**

_Text_

---

### Browser Window Resolution

**API Name**

`BrowserWindowResolution__c`

**Type**

_Text_

---

### Component Name

**API Name**

`ComponentApiName__c`

**Type**

_Text_

---

### Component Function

**API Name**

`ComponentFunctionName__c`

**Type**

_Text_

---

### Component Type

**API Name**

`ComponentType__c`

**Type**

_Picklist_

#### Possible values are

- Aura
- LWC

---

### Database Result Collection Size

The number of items contained in the collection of database results

**API Name**

`DatabaseResultCollectionSize__c`

**Type**

_Number_

---

### Database Result Collection Type

**API Name**

`DatabaseResultCollectionType__c`

**Type**

_Picklist_

#### Possible values are

- Single
- List

---

### Database Result JSON

**API Name**

`DatabaseResultJson__c`

**Type**

_LongTextArea_

---

### Database Result Type

**API Name**

`DatabaseResultType__c`

**Type**

_Picklist_

#### Possible values are

- Approval.LockResult
- Approval.ProcessResult
- Approval.UnlockResult
- Database.DeleteResult
- Database.EmptyRecycleBinResult
- Database.LeadConvertResult
- Database.MergeResult
- Database.SaveResult
- Database.UpsertResult
- Database.UpsertResult.Insert
- Database.UpsertResult.Update
- Database.UndeleteResult

---

### Entry Save Reason

**API Name**

`EntrySaveReason__c`

**Type**

_Picklist_

#### Possible values are

- Logging Level Met
- Save Overridden

---

### Entry Scenario

**API Name**

`EntryScenario__c`

**Type**

_Lookup_

---

### Entry Scenario

**API Name**

`EntryScenarioLink__c`

**Type**

_Text_

---

### Entry Scenario Name

**API Name**

`EntryScenarioName__c`

**Type**

_Text_

---

### Entry Scenario

**API Name**

`EntryScenarioText__c`

**Type**

_Text_

---

### Epoch Timestamp

Timestamp in milliseconds elapsed since 1 January 1970 of the log event

**API Name**

`EpochTimestamp__c`

**Type**

_Number_

---

### Event UUID

The UUID of the LogEntryEvent**e platform event that created this LogEntry**c record.

For more details, refer to https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_event_uuid.htm

**API Name**

`EventUuid__c`

**Type**

_Text_

---

### Exception Location

**API Name**

`ExceptionLocation__c`

**Type**

_Text_

---

### Exception Message

**API Name**

`ExceptionMessage__c`

**Type**

_LongTextArea_

---

### Exception Source Action Name

**API Name**

`ExceptionSourceActionName__c`

**Type**

_Text_

---

### Exception Source API Name

**API Name**

`ExceptionSourceApiName__c`

**Type**

_Text_

---

### Exception Source API Version

**API Name**

`ExceptionSourceApiVersion__c`

**Type**

_Picklist_

#### Possible values are

- v66.0
- v65.0

---

### Exception Source Created By ID

**API Name**

`ExceptionSourceCreatedById__c`

**Type**

_Text_

---

### Exception Source Created By

**API Name**

`ExceptionSourceCreatedByLink__c`

**Type**

_Text_

---

### Exception Source Created By

**API Name**

`ExceptionSourceCreatedByUsername__c`

**Type**

_Text_

---

### Exception Source Created Date

**API Name**

`ExceptionSourceCreatedDate__c`

**Type**

_DateTime_

---

### Exception Source ID

**API Name**

`ExceptionSourceId__c`

**Type**

_Text_

---

### Exception Source Last Modified By ID

**API Name**

`ExceptionSourceLastModifiedById__c`

**Type**

_Text_

---

### Exception Source Last Modified By

**API Name**

`ExceptionSourceLastModifiedByLink__c`

**Type**

_Text_

---

### Exception Source Last Modified By

**API Name**

`ExceptionSourceLastModifiedByUsername__c`

**Type**

_Text_

---

### Exception Source Last Modified Date

**API Name**

`ExceptionSourceLastModifiedDate__c`

**Type**

_DateTime_

---

### Exception Source Metadata Type

**API Name**

`ExceptionSourceMetadataType__c`

**Type**

_Picklist_

#### Possible values are

- AnonymousBlock
- ApexClass
- ApexTrigger
- AuraDefinitionBundle
- Flow
- LightningComponentBundle

---

### Exception Source Snippet

**API Name**

`ExceptionSourceSnippet__c`

**Type**

_LongTextArea_

---

### Exception Stack Trace

**API Name**

`ExceptionStackTrace__c`

**Type**

_LongTextArea_

---

### Exception Type

**API Name**

`ExceptionType__c`

**Type**

_Picklist_

#### Possible values are

- Flow.FaultError
- JavaScript.Error
- System.AsyncException
- System.CalloutException
- System.DmlException
- System.EmailException
- System.ExternalObjectException
- System.InvalidParameterValueException
- System.JSONException
- System.LimitException
- System.ListException
- System.MathException
- System.NoAccessException
- System.NoDataFoundException
- System.NoSuchElementException
- System.NullPointerException
- System.QueryException
- System.SearchException
- System.SecurityException
- System.SerializationException
- System.SObjectException
- System.StringException
- System.TypeException
- System.VisualforceException
- System.XmlException

---

### Flow Active Version ID

The ID of the active flow version.

**API Name**

`FlowActiveVersionId__c`

**Type**

_Text_

---

### Flow Description

Flow definition information, specified by the org’s admin.

**API Name**

`FlowDescription__c`

**Type**

_LongTextArea_

---

### Flow Durable ID

For more details, refer to https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_flowdefinitionview.htm

**API Name**

`FlowDurableId__c`

**Type**

_Text_

---

### Flow Label

For more details, refer to https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_flowdefinitionview.htm

**API Name**

`FlowLabel__c`

**Type**

_Text_

---

### Flow Last Modified By

For more details, refer to https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_flowdefinitionview.htm

**API Name**

`FlowLastModifiedByName__c`

**Type**

_Text_

---

### Flow Last Modified Date

For more details, refer to https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_flowdefinitionview.htm

**API Name**

`FlowLastModifiedDate__c`

**Type**

_DateTime_

---

### Flow Process Type

For more details, refer to https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_flowdefinitionview.htm

**API Name**

`FlowProcessType__c`

**Type**

_Picklist_

#### Possible values are

- Appointments
- AutoLaunchedFlow
- CheckoutFlow
- ContactRequestFlow
- CustomerLifecycle
- CustomEvent
- FieldServiceMobile
- FieldServiceWeb
- Flow
- FSCLending
- InvocableProcess
- RoutingFlow
- Survey
- SurveyEnrich
- Workflow

---

### Flow Record Trigger Type

For more details, refer to https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_flowdefinitionview.htm

**API Name**

`FlowRecordTriggerType__c`

**Type**

_Picklist_

#### Possible values are

- Create
- CreateAndUpdate
- Delete
- None
- Update
- PlatformEvent
- RecordAfterSave
- RecordBeforeSave
- Scheduled

---

### Flow Trigger Order

For more details, refer to https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_flowdefinitionview.htm

**API Name**

`FlowTriggerOrder__c`

**Type**

_Number_

---

### Flow Trigger SObject Type

**API Name**

`FlowTriggerSObjectType__c`

**Type**

_Picklist_

#### Possible values are

- Account
- Case
- Lead
- Unknown
- User

---

### Flow Trigger Type

For more details, refer to https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_flowdefinitionview.htm

**API Name**

`FlowTriggerType__c`

**Type**

_Picklist_

#### Possible values are

- PlatformEvent
- RecordAfterSave
- RecordBeforeSave
- Scheduled

---

### Flow API Version Runtime

For more details, refer to https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_flowdefinitionview.htm

**API Name**

`FlowVersionApiVersionRuntime__c`

**Type**

_Picklist_

#### Possible values are

- v66.0
- v65.0

---

### Flow Version Number

For more details, refer to https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_flowdefinitionview.htm

**API Name**

`FlowVersionNumber__c`

**Type**

_Number_

---

### Flow Run-In Mode

For more details, refer to https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_flowdefinitionview.htm

**API Name**

`FlowVersionRunInMode__c`

**Type**

_Picklist_

#### Possible values are

- DefaultMode
- SystemModeWithSharing

---

### Has Database Result

**API Name**

`HasDatabaseResult__c`

**Type**

_Checkbox_

---

### Has Database Result JSON

**API Name**

`HasDatabaseResultJson__c`

**Type**

_Checkbox_

---

### Has Exception

**API Name**

`HasException__c`

**Type**

_Checkbox_

---

### Has Exception Source Snippet

**API Name**

`HasExceptionSourceSnippet__c`

**Type**

_Checkbox_

---

### Has Exception Stack Trace

**API Name**

`HasExceptionStackTrace__c`

**Type**

_Checkbox_

---

### Has HTTP Request Body

**API Name**

`HasHttpRequestBody__c`

**Type**

_Checkbox_

---

### Has HTTP Request Header Keys

**API Name**

`HasHttpRequestHeaderKeys__c`

**Type**

_Checkbox_

---

### Has HTTP Request Headers

**API Name**

`HasHttpRequestHeaders__c`

**Type**

_Checkbox_

---

### Has HTTP Response Body

**API Name**

`HasHttpResponseBody__c`

**Type**

_Checkbox_

---

### Has HTTP Response Header Keys

**API Name**

`HasHttpResponseHeaderKeys__c`

**Type**

_Checkbox_

---

### Has HTTP Response Headers

**API Name**

`HasHttpResponseHeaders__c`

**Type**

_Checkbox_

---

### Has Inline Tags

**API Name**

`HasInlineTags__c`

**Type**

_Checkbox_

---

### Has Origin Source Snippet

**API Name**

`HasOriginSourceSnippet__c`

**Type**

_Checkbox_

---

### Has Related Record ID

**API Name**

`HasRecordId__c`

**Type**

_Checkbox_

---

### Has Related Record JSON

**API Name**

`HasRecordJson__c`

**Type**

_Checkbox_

---

### Has REST Request Body

**API Name**

`HasRestRequestBody__c`

**Type**

_Checkbox_

---

### Has REST Request Header Keys

**API Name**

`HasRestRequestHeaderKeys__c`

**Type**

_Checkbox_

---

### Has REST Request Headers

**API Name**

`HasRestRequestHeaders__c`

**Type**

_Checkbox_

---

### Has REST Response Body

**API Name**

`HasRestResponseBody__c`

**Type**

_Checkbox_

---

### Has REST Response Header Keys

**API Name**

`HasRestResponseHeaderKeys__c`

**Type**

_Checkbox_

---

### Has REST Response Headers

**API Name**

`HasRestResponseHeaders__c`

**Type**

_Checkbox_

---

### Has Stack Trace

**API Name**

`HasStackTrace__c`

**Type**

_Checkbox_

---

### HTTP Request Body

**API Name**

`HttpRequestBody__c`

**Type**

_LongTextArea_

---

### HTTP Request Body Masked

**API Name**

`HttpRequestBodyMasked__c`

**Type**

_Checkbox_

---

### HTTP Request Body Truncated

**API Name**

`HttpRequestBodyTruncated__c`

**Type**

_Checkbox_

---

### HTTP Request Compressed

**API Name**

`HttpRequestCompressed__c`

**Type**

_Checkbox_

---

### DEPRECATED: HTTP Request Endpoint

**API Name**

`HttpRequestEndpoint__c`

**Type**

_Text_

---

### HTTP Request Endpoint Address

**API Name**

`HttpRequestEndpointAddress__c`

**Type**

_LongTextArea_

---

### HTTP Request Header Keys

**API Name**

`HttpRequestHeaderKeys__c`

**Type**

_LongTextArea_

---

### HTTP Request Headers

**API Name**

`HttpRequestHeaders__c`

**Type**

_LongTextArea_

---

### HTTP Request Method

**API Name**

`HttpRequestMethod__c`

**Type**

_Picklist_

#### Possible values are

- DELETE
- GET
- HEAD
- PATCH
- POST
- PUT
- TRACE

---

### HTTP Response Body

**API Name**

`HttpResponseBody__c`

**Type**

_LongTextArea_

---

### HTTP Response Body Masked

**API Name**

`HttpResponseBodyMasked__c`

**Type**

_Checkbox_

---

### HTTP Response Body Truncated

**API Name**

`HttpResponseBodyTruncated__c`

**Type**

_Checkbox_

---

### HTTP Response Header Keys

**API Name**

`HttpResponseHeaderKeys__c`

**Type**

_LongTextArea_

---

### HTTP Response Headers

**API Name**

`HttpResponseHeaders__c`

**Type**

_LongTextArea_

---

### HTTP Response Status

**API Name**

`HttpResponseStatus__c`

**Type**

_Text_

---

### HTTP Response Status Code

**API Name**

`HttpResponseStatusCode__c`

**Type**

_Number_

---

### Impersonated By Username

**API Name**

`ImpersonatedByUsernameLink__c`

**Type**

_Text_

---

### Aggregate Queries

**API Name**

`LimitsAggregateQueries__c`

**Type**

_Text_

---

### Aggregate Queries Max

**API Name**

`LimitsAggregateQueriesMax__c`

**Type**

_Number_

---

### Aggregate Queries Used

**API Name**

`LimitsAggregateQueriesUsed__c`

**Type**

_Number_

---

### Apex Cursor Fetch Calls

**API Name**

`LimitsApexCursorFetchCalls__c`

**Type**

_Text_

---

### Apex Cursor Fetch Calls Max

**API Name**

`LimitsApexCursorFetchCallsMax__c`

**Type**

_Number_

---

### Apex Cursor Fetch Calls Used

**API Name**

`LimitsApexCursorFetchCallsUsed__c`

**Type**

_Number_

---

### Apex Cursor Rows

**API Name**

`LimitsApexCursorRows__c`

**Type**

_Text_

---

### Apex Cursor Rows Max

**API Name**

`LimitsApexCursorRowsMax__c`

**Type**

_Number_

---

### Apex Cursor Rows Used

**API Name**

`LimitsApexCursorRowsUsed__c`

**Type**

_Number_

---

### Async Calls

**API Name**

`LimitsAsyncCalls__c`

**Type**

_Text_

---

### Async Calls Max

**API Name**

`LimitsAsyncCallsMax__c`

**Type**

_Number_

---

### Async Calls Used

**API Name**

`LimitsAsyncCallsUsed__c`

**Type**

_Number_

---

### Callouts

**API Name**

`LimitsCallouts__c`

**Type**

_Text_

---

### Callouts Max

**API Name**

`LimitsCalloutsMax__c`

**Type**

_Number_

---

### Callouts Used

**API Name**

`LimitsCalloutsUsed__c`

**Type**

_Number_

---

### CPU Time

**API Name**

`LimitsCpuTime__c`

**Type**

_Text_

---

### CPU Time Max

**API Name**

`LimitsCpuTimeMax__c`

**Type**

_Number_

---

### CPU Time Used

**API Name**

`LimitsCpuTimeUsed__c`

**Type**

_Number_

---

### DML Rows

**API Name**

`LimitsDmlRows__c`

**Type**

_Text_

---

### DML Rows Max

**API Name**

`LimitsDmlRowsMax__c`

**Type**

_Number_

---

### DML Rows Used

**API Name**

`LimitsDmlRowsUsed__c`

**Type**

_Number_

---

### DML Statements

**API Name**

`LimitsDmlStatements__c`

**Type**

_Text_

---

### DML Statements Max

**API Name**

`LimitsDmlStatementsMax__c`

**Type**

_Number_

---

### DML Statements Used

**API Name**

`LimitsDmlStatementsUsed__c`

**Type**

_Number_

---

### Email Invocations

**API Name**

`LimitsEmailInvocations__c`

**Type**

_Text_

---

### Email Invocations Max

**API Name**

`LimitsEmailInvocationsMax__c`

**Type**

_Number_

---

### Email Invocations Used

**API Name**

`LimitsEmailInvocationsUsed__c`

**Type**

_Number_

---

### Future Calls

**API Name**

`LimitsFutureCalls__c`

**Type**

_Text_

---

### Future Calls Max

**API Name**

`LimitsFutureCallsMax__c`

**Type**

_Number_

---

### Future Calls Used

**API Name**

`LimitsFutureCallsUsed__c`

**Type**

_Number_

---

### Heap Size

**API Name**

`LimitsHeapSize__c`

**Type**

_Text_

---

### Heap Size Max

**API Name**

`LimitsHeapSizeMax__c`

**Type**

_Number_

---

### Heap Size Used

**API Name**

`LimitsHeapSizeUsed__c`

**Type**

_Number_

---

### Mobile Push Apex Calls

**API Name**

`LimitsMobilePushApexCalls__c`

**Type**

_Text_

---

### Mobile Push Apex Calls Max

**API Name**

`LimitsMobilePushApexCallsMax__c`

**Type**

_Number_

---

### Mobile Push Apex Calls Used

**API Name**

`LimitsMobilePushApexCallsUsed__c`

**Type**

_Number_

---

### Publish Immediate DML Statements

**API Name**

`LimitsPublishImmediateDmlStatements__c`

**Type**

_Text_

---

### Publish Immediate Statements DML Max

**API Name**

`LimitsPublishImmediateDmlStatementsMax__c`

**Type**

_Number_

---

### Publish Immediate Statements DML Used

**API Name**

`LimitsPublishImmediateDmlStatementsUsed__c`

**Type**

_Number_

---

### Queueable Jobs

**API Name**

`LimitsQueueableJobs__c`

**Type**

_Text_

---

### Queueable Jobs Max

**API Name**

`LimitsQueueableJobsMax__c`

**Type**

_Number_

---

### Queueable Jobs Used

**API Name**

`LimitsQueueableJobsUsed__c`

**Type**

_Number_

---

### SOQL Queries

**API Name**

`LimitsSoqlQueries__c`

**Type**

_Text_

---

### SOQL Queries Max

**API Name**

`LimitsSoqlQueriesMax__c`

**Type**

_Number_

---

### SOQL Queries Used

**API Name**

`LimitsSoqlQueriesUsed__c`

**Type**

_Number_

---

### SOQL Query Locator Rows

**API Name**

`LimitsSoqlQueryLocatorRows__c`

**Type**

_Text_

---

### SOQL Query Locator Rows Max

**API Name**

`LimitsSoqlQueryLocatorRowsMax__c`

**Type**

_Number_

---

### SOQL Query Locator Rows Used

**API Name**

`LimitsSoqlQueryLocatorRowsUsed__c`

**Type**

_Number_

---

### SOQL Query Rows

**API Name**

`LimitsSoqlQueryRows__c`

**Type**

_Text_

---

### SOQL Query Rows Max

**API Name**

`LimitsSoqlQueryRowsMax__c`

**Type**

_Number_

---

### SOQL Query Rows Used

**API Name**

`LimitsSoqlQueryRowsUsed__c`

**Type**

_Number_

---

### SOSL Searches

**API Name**

`LimitsSoslSearches__c`

**Type**

_Text_

---

### SOSL Searches Max

**API Name**

`LimitsSoslSearchesMax__c`

**Type**

_Number_

---

### SOSL Searches Used

**API Name**

`LimitsSoslSearchesUsed__c`

**Type**

_Number_

---

### Log

**API Name**

`Log__c`

**Type**

_MasterDetail_

---

### Username

**API Name**

`LoggedByUsernameLink__c`

**Type**

_Text_

---

### Username

**API Name**

`LoggedByUsernameText__c`

**Type**

_Text_

---

### Logging Level

**API Name**

`LoggingLevel__c`

**Type**

_Picklist_

---

### Logging Level Ordinal

**API Name**

`LoggingLevelOrdinal__c`

**Type**

_Number_

---

### DEPRECATED: Level

**API Name**

`LoggingLevelWithImage__c`

**Type**

_Text_

---

### Log Transaction ID

**API Name**

`LogTransactionId__c`

**Type**

_Text_

---

### Message

**API Name**

`Message__c`

**Type**

_LongTextArea_

---

### Message Masked

**API Name**

`MessageMasked__c`

**Type**

_Checkbox_

---

### Message Truncated

**API Name**

`MessageTruncated__c`

**Type**

_Checkbox_

---

### Origin

**API Name**

`Origin__c`

**Type**

_Text_

---

### Origin Location

**API Name**

`OriginLocation__c`

**Type**

_Text_

---

### Origin Source Action Name

**API Name**

`OriginSourceActionName__c`

**Type**

_Text_

---

### Origin Source API Name

**API Name**

`OriginSourceApiName__c`

**Type**

_Text_

---

### Origin Source API Version

**API Name**

`OriginSourceApiVersion__c`

**Type**

_Picklist_

#### Possible values are

- v66.0
- v65.0

---

### Origin Source Created By ID

**API Name**

`OriginSourceCreatedById__c`

**Type**

_Text_

---

### Origin Source Created By

**API Name**

`OriginSourceCreatedByLink__c`

**Type**

_Text_

---

### Origin Source Created By

**API Name**

`OriginSourceCreatedByUsername__c`

**Type**

_Text_

---

### Origin Source Created Date

**API Name**

`OriginSourceCreatedDate__c`

**Type**

_DateTime_

---

### Origin Source ID

**API Name**

`OriginSourceId__c`

**Type**

_Text_

---

### Origin Source Last Modified By ID

**API Name**

`OriginSourceLastModifiedById__c`

**Type**

_Text_

---

### Origin Source Last Modified By

**API Name**

`OriginSourceLastModifiedByLink__c`

**Type**

_Text_

---

### Origin Source Last Modified By

**API Name**

`OriginSourceLastModifiedByUsername__c`

**Type**

_Text_

---

### Origin Source Last Modified Date

**API Name**

`OriginSourceLastModifiedDate__c`

**Type**

_DateTime_

---

### Origin Source Metadata Type

**API Name**

`OriginSourceMetadataType__c`

**Type**

_Picklist_

#### Possible values are

- AnonymousBlock
- ApexClass
- ApexTrigger
- AuraDefinitionBundle
- Flow
- LightningComponentBundle
- OmniIntegrationProcedure
- OmniScript

---

### Origin Source Snippet

**API Name**

`OriginSourceSnippet__c`

**Type**

_LongTextArea_

---

### Origin Type

**API Name**

`OriginType__c`

**Type**

_Picklist_

#### Possible values are

- Apex
- Component
- Flow
- OmniStudio

---

### Parent Log

**API Name**

`ParentLogLink__c`

**Type**

_Text_

---

### Profile

**API Name**

`ProfileLink__c`

**Type**

_Text_

---

### Related Record Collection Size

The number of items contained in the collection of records

**API Name**

`RecordCollectionSize__c`

**Type**

_Number_

---

### Related Record Collection Type

**API Name**

`RecordCollectionType__c`

**Type**

_Picklist_

#### Possible values are

- Single
- List
- Map

---

### Related Record

**API Name**

`RecordDetailedLink__c`

**Type**

_Text_

---

### Related Record ID

**API Name**

`RecordId__c`

**Type**

_Text_

---

### Related Record JSON

JSON of the related SObject record

**API Name**

`RecordJson__c`

**Type**

_LongTextArea_

---

### Record JSON Masked

**API Name**

`RecordJsonMasked__c`

**Type**

_Checkbox_

---

### Record JSON Truncated

**API Name**

`RecordJsonTruncated__c`

**Type**

_Checkbox_

---

### Related Record

**API Name**

`RecordLink__c`

**Type**

_Text_

---

### Related Record Name

**API Name**

`RecordName__c`

**Type**

_Text_

---

### Related Record Object Classification

**API Name**

`RecordSObjectClassification__c`

**Type**

_Picklist_

#### Possible values are

- Change Event Object
- Chatter Feed Object
- Custom Metadata Type Object
- Custom Object
- Custom Setting Object
- Field History Tracking Object
- Platform Event Object
- Record Share Object
- Standard Object
- Unknown

---

### Related Record Object

**API Name**

`RecordSObjectType__c`

**Type**

_Picklist_

#### Possible values are

- Account
- Case
- Lead
- Unknown
- User

---

### Related Record Object Namespace

**API Name**

`RecordSObjectTypeNamespace__c`

**Type**

_Text_

---

### REST Request Body

**API Name**

`RestRequestBody__c`

**Type**

_LongTextArea_

---

### REST Request Body Masked

**API Name**

`RestRequestBodyMasked__c`

**Type**

_Checkbox_

---

### REST Request Body Truncated

**API Name**

`RestRequestBodyTruncated__c`

**Type**

_Checkbox_

---

### REST Request Header Keys

**API Name**

`RestRequestHeaderKeys__c`

**Type**

_LongTextArea_

---

### REST Request Headers

**API Name**

`RestRequestHeaders__c`

**Type**

_LongTextArea_

---

### REST Request Method

**API Name**

`RestRequestMethod__c`

**Type**

_Picklist_

#### Possible values are

- DELETE
- GET
- HEAD
- PATCH
- POST
- PUT
- TRACE

---

### REST Request Parameters

**API Name**

`RestRequestParameters__c`

**Type**

_LongTextArea_

---

### REST Request Remote Address

**API Name**

`RestRequestRemoteAddress__c`

**Type**

_Text_

---

### REST Request Resource Path

**API Name**

`RestRequestResourcePath__c`

**Type**

_Text_

---

### REST Request URI

**API Name**

`RestRequestUri__c`

**Type**

_Text_

---

### REST Response Body

**API Name**

`RestResponseBody__c`

**Type**

_LongTextArea_

---

### REST Response Body Masked

**API Name**

`RestResponseBodyMasked__c`

**Type**

_Checkbox_

---

### REST Response Body Truncated

**API Name**

`RestResponseBodyTruncated__c`

**Type**

_Checkbox_

---

### REST Response Header Keys

**API Name**

`RestResponseHeaderKeys__c`

**Type**

_LongTextArea_

---

### REST Response Headers

**API Name**

`RestResponseHeaders__c`

**Type**

_LongTextArea_

---

### REST Response Status Code

**API Name**

`RestResponseStatusCode__c`

**Type**

_Number_

---

### Stack Trace

**API Name**

`StackTrace__c`

**Type**

_LongTextArea_

---

### Tags

**API Name**

`Tags__c`

**Type**

_LongTextArea_

---

### Timestamp

**API Name**

`Timestamp__c`

**Type**

_DateTime_

---

### Entry

The sequential number of this log entry within the transaction

**API Name**

`TransactionEntryNumber__c`

**Type**

_Number_

---

### Trigger Operation

**API Name**

`Trigger__c`

**Type**

_Text_

---

### Trigger Is Executing

**API Name**

`TriggerIsExecuting__c`

**Type**

_Checkbox_

---

### Trigger Operation Type

**API Name**

`TriggerOperationType__c`

**Type**

_Picklist_

#### Possible values are

- AFTER_DELETE
- AFTER_INSERT
- AFTER_UNDELETE
- AFTER_UPDATE
- BEFORE_DELETE
- BEFORE_INSERT
- BEFORE_UPDATE

---

### Trigger Object

**API Name**

`TriggerSObjectType__c`

**Type**

_Picklist_

#### Possible values are

- Account
- Case
- Lead
- User

---

### Unique ID

Composite key that will hold the value of the TransactionId + TransactionEntryNumber

**API Name**

`UniqueId__c`

**Type**

_Text_

---

### Logged By Current User

**API Name**

`WasLoggedByCurrentUser__c`

**Type**

_Checkbox_
