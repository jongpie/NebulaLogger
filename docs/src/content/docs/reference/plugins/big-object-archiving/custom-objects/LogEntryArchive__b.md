---
title: LogEntryArchive__b
description: >-
  Nebula Logger big-object-archiving plugin customobject (public API):
  LogEntryArchive__b.
---

# Log Entry Archive

Big Object representation of Logger data, used as an alternative to the platform event LogEntryEvent**e, as well as a way to archive Logger data stored in Log**c, LogEntry**, and LogEntryTag**c

## API Name

`LogEntryArchive__b`

## Fields

### API Release Number

The release number for the org&#x27;s instance - determined by making a callout to status.salesforce.com

**API Name**

`ApiReleaseNumber__c`

**Type**

_Text_

---

### API Release Version

The release version for the org&#x27;s instance - determined by making a callout to status.salesforce.com

**API Name**

`ApiReleaseVersion__c`

**Type**

_Text_

---

### API Version

**API Name**

`ApiVersion__c`

**Type**

_Text_

---

### Archived By ID

**API Name**

`ArchivedById__c`

**Type**

_Text_

---

### Archived By Username

**API Name**

`ArchivedByUsername__c`

**Type**

_Text_

---

### Archived Date

**API Name**

`ArchivedDate__c`

**Type**

_DateTime_

---

### Archive Retention Date

Reserved for future use

**API Name**

`ArchiveRetentionDate__c`

**Type**

_DateTime_

---

### Closed By ID

**API Name**

`ClosedById__c`

**Type**

_Text_

---

### Closed By Username

**API Name**

`ClosedByUsername__c`

**Type**

_Text_

---

### Closed Date

**API Name**

`ClosedDate__c`

**Type**

_DateTime_

---

### Comments

**API Name**

`Comments__c`

**Type**

_LongTextArea_

---

### Component Type

**API Name**

`ComponentType__c`

**Type**

_Text_

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

_Text_

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

### Exception Message

**API Name**

`ExceptionMessage__c`

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

_Text_

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

_Text_

---

### HTTP Request Is Compressed

**API Name**

`HttpRequestCompressed__c`

**Type**

_Text_

---

### HTTP Request Endpoint

**API Name**

`HttpRequestEndpoint__c`

**Type**

_Text_

---

### HTTP Request Method

**API Name**

`HttpRequestMethod__c`

**Type**

_Text_

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

_Text_

---

### HTTP Response Header Keys

**API Name**

`HttpResponseHeaderKeys__c`

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

### Is Closed

**API Name**

`IsClosed__c`

**Type**

_Text_

---

### Is Resolved

**API Name**

`IsResolved__c`

**Type**

_Text_

---

### Issue

**API Name**

`Issue__c`

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

### Limits AggregateQueryMax\_

**API Name**

`LimitsAggregateQueryMax__c`

**Type**

_Number_

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

### Locale

**API Name**

`Locale__c`

**Type**

_Text_

---

### Log Name

**API Name**

`LogEntryName__c`

**Type**

_Text_

---

### Logged By ID

**API Name**

`LoggedById__c`

**Type**

_Text_

---

### Username

**API Name**

`LoggedByUsername__c`

**Type**

_Text_

---

### Logger Version Number

**API Name**

`LoggerVersionNumber__c`

**Type**

_Text_

---

### Logging Level

**Required**

**API Name**

`LoggingLevel__c`

**Type**

_Text_

---

### Logging Level Ordinal

**Required**

**API Name**

`LoggingLevelOrdinal__c`

**Type**

_Number_

---

### Login Application

**API Name**

`LoginApplication__c`

**Type**

_Text_

---

### Login Browser

**API Name**

`LoginBrowser__c`

**Type**

_Text_

---

### DEPRECATED: Login Domain

**API Name**

`LoginDomain__c`

**Type**

_Text_

---

### Login History ID

**API Name**

`LoginHistoryId__c`

**Type**

_Text_

---

### Login Platform

**API Name**

`LoginPlatform__c`

**Type**

_Text_

---

### Login Type

**API Name**

`LoginType__c`

**Type**

_Text_

---

### Log Name

**API Name**

`LogName__c`

**Type**

_Text_

---

### Logout URL

**API Name**

`LogoutUrl__c`

**Type**

_Text_

---

### Log Purge Action

**API Name**

`LogPurgeAction__c`

**Type**

_Text_

---

### Log Retention Date

The date that this log can be automatically deleted by the batch job LogBatchPurger.

It defaults to 2 weeks after creation (configurable in Logger Settings), but the date can be set manually or via automation if certain logs need to be kept longer/indefinitely.

**API Name**

`LogRetentionDate__c`

**Type**

_DateTime_

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

_Text_

---

### Message Truncated

**API Name**

`MessageTruncated__c`

**Type**

_Text_

---

### Network ID

**API Name**

`NetworkId__c`

**Type**

_Text_

---

### Site Login URL

**API Name**

`NetworkLoginUrl__c`

**Type**

_Text_

---

### Site Logout URL

**API Name**

`NetworkLogoutUrl__c`

**Type**

_Text_

---

### Site Name

The name of the user&#x27;s Community site (based on NetworkId).

**API Name**

`NetworkName__c`

**Type**

_Text_

---

### Site Self Registration URL

**API Name**

`NetworkSelfRegistrationUrl__c`

**Type**

_Text_

---

### Site URL Path Prefix

The UrlPathPrefix is a unique string at the end of the URL for this community. For example, in the community URL CommunitiesSubdomainName.force.com/customers, customers is the UrlPathPrefix.

**API Name**

`NetworkUrlPathPrefix__c`

**Type**

_Text_

---

### Organization Domain URL

The value returned from System.URL.getOrgDomainUrl()

**API Name**

`OrganizationDomainUrl__c`

**Type**

_Text_

---

### Organization Environment Type

**API Name**

`OrganizationEnvironmentType__c`

**Type**

_Text_

---

### Organization ID

**API Name**

`OrganizationId__c`

**Type**

_Text_

---

### Organization Instance Name

**API Name**

`OrganizationInstanceName__c`

**Type**

_Text_

---

### DEPRECATED: Instance Release Cycle

**API Name**

`OrganizationInstanceReleaseCycle__c`

**Type**

_Text_

---

### Organization Name

**API Name**

`OrganizationName__c`

**Type**

_Text_

---

### Organization Namespace Prefix

**API Name**

`OrganizationNamespacePrefix__c`

**Type**

_Text_

---

### Organization Type

**API Name**

`OrganizationType__c`

**Type**

_Text_

---

### Origin Location

**API Name**

`OriginLocation__c`

**Type**

_Text_

---

### Origin Type

**API Name**

`OriginType__c`

**Type**

_Text_

---

### Parent Log Transaction ID

**API Name**

`ParentLogTransactionId__c`

**Type**

_Text_

---

### Priority

**API Name**

`Priority__c`

**Type**

_Text_

---

### Profile ID

**API Name**

`ProfileId__c`

**Type**

_Text_

---

### Profile Name

**API Name**

`ProfileName__c`

**Type**

_Text_

---

### Related Record Collection Size

The number of items contained in the collection of database results

**API Name**

`RecordCollectionSize__c`

**Type**

_Number_

---

### Related Record Collection Type

**API Name**

`RecordCollectionType__c`

**Type**

_Text_

---

### Related Record ID

The ID of the record associated with a particular log entry. This is used for addRecordDebugEntry &amp; addRecordExceptionEntry methods

**API Name**

`RecordId__c`

**Type**

_Text_

---

### Related Record JSON

**API Name**

`RecordJson__c`

**Type**

_LongTextArea_

---

### Record JSON Masked

**API Name**

`RecordJsonMasked__c`

**Type**

_Text_

---

### Related Record Name

**API Name**

`RecordName__c`

**Type**

_Text_

---

### Related Record SObject Classification

**API Name**

`RecordSObjectClassification__c`

**Type**

_Text_

---

### Related Record SObject Type

**API Name**

`RecordSObjectType__c`

**Type**

_Text_

---

### Related Record Object Namespace

**API Name**

`RecordSObjectTypeNamespace__c`

**Type**

_Text_

---

### Scenario

**API Name**

`Scenario__c`

**Type**

_Text_

---

### SessionId

**API Name**

`SessionId__c`

**Type**

_Text_

---

### Session Security Level

**API Name**

`SessionSecurityLevel__c`

**Type**

_Text_

---

### Session Type

**API Name**

`SessionType__c`

**Type**

_Text_

---

### Source IP

**API Name**

`SourceIp__c`

**Type**

_Text_

---

### Stack Trace

**API Name**

`StackTrace__c`

**Type**

_LongTextArea_

---

### Status

**API Name**

`Status__c`

**Type**

_Text_

---

### System Mode

**API Name**

`SystemMode__c`

**Type**

_Text_

---

### Tags

**API Name**

`Tags__c`

**Type**

_LongTextArea_

---

### Theme Displayed

**API Name**

`ThemeDisplayed__c`

**Type**

_Text_

---

### Timestamp

**Required**

**API Name**

`Timestamp__c`

**Type**

_DateTime_

---

### Timestamp String

This field is used to circumvent a platform limitation - platform event datetimes are not accurately transferred to Apex triggers. This field stores a string version of the timestamp, which is then converted back to a datetime in Apex triggers.

**API Name**

`TimestampString__c`

**Type**

_Text_

---

### Time Zone ID

**API Name**

`TimeZoneId__c`

**Type**

_Text_

---

### Time Zone Name

**API Name**

`TimeZoneName__c`

**Type**

_Text_

---

### Entry

**Required**

The sequential number of this log entry within the transaction

**API Name**

`TransactionEntryNumber__c`

**Type**

_Number_

---

### Transaction ID

**Required**

**API Name**

`TransactionId__c`

**Type**

_Text_

---

### Trigger Is Executing

**API Name**

`TriggerIsExecuting__c`

**Type**

_Text_

---

### Trigger Operation Type

**API Name**

`TriggerOperationType__c`

**Type**

_Text_

---

### Trigger SObject Type

**API Name**

`TriggerSObjectType__c`

**Type**

_Text_

---

### User License Definition Key

https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_userlicense.htm

**API Name**

`UserLicenseDefinitionKey__c`

**Type**

_Text_

---

### User License ID

**API Name**

`UserLicenseId__c`

**Type**

_Text_

---

### User License Name

**API Name**

`UserLicenseName__c`

**Type**

_Text_

---

### User Logging Level

**API Name**

`UserLoggingLevel__c`

**Type**

_Text_

---

### User Logging Level Ordinal

**API Name**

`UserLoggingLevelOrdinal__c`

**Type**

_Number_

---

### User Role ID

**API Name**

`UserRoleId__c`

**Type**

_Text_

---

### User Role Name

**API Name**

`UserRoleName__c`

**Type**

_Text_

---

### User Type

**API Name**

`UserType__c`

**Type**

_Text_
