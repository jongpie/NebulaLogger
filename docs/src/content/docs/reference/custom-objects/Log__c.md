---
title: Log__c
description: 'Nebula Logger customobject reference: Log__c.'
---

# Log

Used by Nebula Logger to unify all log entries generated in a single transaction

## API Name

`Log__c`

## Fields

### DEPRECATED: API Release Number

The release number for the org&#x27;s instance - determined by making a callout to status.salesforce.com

**API Name**

`ApiReleaseNumber__c`

**Type**

_Text_

---

### DEPRECATED: API Release Version

The release version for the org&#x27;s instance - determined by making a callout to status.salesforce.com

**API Name**

`ApiReleaseVersion__c`

**Type**

_Text_

---

### DEPRECATED: API Version

The Salesforce release (API version) of the environment

**API Name**

`ApiVersion__c`

**Type**

_Picklist_

#### Possible values are

- v66.0
- v65.0

---

### Async Context Child Job ID

**API Name**

`AsyncContextChildJobId__c`

**Type**

_Text_

---

### Async Context Parent Job ID

**API Name**

`AsyncContextParentJobId__c`

**Type**

_Text_

---

### Async Context Trigger ID

**API Name**

`AsyncContextTriggerId__c`

**Type**

_Text_

---

### Async Context Type

**API Name**

`AsyncContextType__c`

**Type**

_Picklist_

#### Possible values are

- Database.BatchableContext
- System.FinalizerContext
- System.QueueableContext
- System.SchedulableContext

---

### Closed By

**API Name**

`ClosedBy__c`

**Type**

_Lookup_

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

### End Time

**API Name**

`EndTime__c`

**Type**

_Summary_

---

### Has Comments

**API Name**

`HasComments__c`

**Type**

_Checkbox_

---

### Has User Federation Identifier

**API Name**

`HasLoggedByFederationIdentifier__c`

**Type**

_Checkbox_

---

### Has Organization Limits

**API Name**

`HasOrganizationLimits__c`

**Type**

_Checkbox_

---

### Impersonated By

**API Name**

`ImpersonatedBy__c`

**Type**

_Lookup_

---

### Impersonated By Username

**API Name**

`ImpersonatedByUsernameLink__c`

**Type**

_Text_

---

### Is Closed

**API Name**

`IsClosed__c`

**Type**

_Checkbox_

---

### Is Resolved

**API Name**

`IsResolved__c`

**Type**

_Checkbox_

---

### Issue

**API Name**

`Issue__c`

**Type**

_Picklist_

#### Possible values are

- Code Issue
- Config Issue
- Data Issue
- Integration Issue
- No Issue

---

### Locale

**API Name**

`Locale__c`

**Type**

_Text_

---

### Summary

**API Name**

`LogEntriesSummary__c`

**Type**

_Text_

---

### Logged By

**API Name**

`LoggedBy__c`

**Type**

_Lookup_

---

### User Federation Identifier

**API Name**

`LoggedByFederationIdentifier__c`

**Type**

_LongTextArea_

---

### Username

**API Name**

`LoggedByUsername__c`

**Type**

_Text_

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

### Logger Version Number

**API Name**

`LoggerVersionNumber__c`

**Type**

_Text_

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

_Url_

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

_Picklist_

#### Possible values are

- Application
- Remote Access 2.0
- SAML Idp Initiated SSO

---

### Logout URL

**API Name**

`LogoutUrl__c`

**Type**

_Url_

---

### Log Purge Action

**API Name**

`LogPurgeAction__c`

**Type**

_Picklist_

#### Possible values are

- Delete

---

### Log Retention Date

The date that this log can be automatically deleted by the batch job LogBatchPurger.

It defaults to 2 weeks after creation (configurable in Logger Settings), but the date can be set manually or via automation if certain logs need to be kept longer/indefinitely.

**API Name**

`LogRetentionDate__c`

**Type**

_Date_

---

### Max Log Entry Logging Level Ordinal

The highest logging level ordinal of any related log entries

**API Name**

`MaxLogEntryLoggingLevelOrdinal__c`

**Type**

_Summary_

---

### Site Network ID

The Network ID of the Community user&#x27;s site. Set with Network.getNetworkId()

**API Name**

`NetworkId__c`

**Type**

_Text_

---

### Site Login URL

**API Name**

`NetworkLoginUrl__c`

**Type**

_Url_

---

### Site Logout URL

**API Name**

`NetworkLogoutUrl__c`

**Type**

_Url_

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

_Url_

---

### Site URL Path Prefix

The UrlPathPrefix is a unique string at the end of the URL for this community. For example, in the community URL CommunitiesSubdomainName.force.com/customers, customers is the UrlPathPrefix.

**API Name**

`NetworkUrlPathPrefix__c`

**Type**

_Text_

---

### Organization API Version

The Salesforce release (API version) of the environment

**API Name**

`OrganizationApiVersion__c`

**Type**

_Picklist_

#### Possible values are

- v66.0
- v65.0

---

### Organization Domain URL

The value returned from System.URL.getOrgDomainUrl()

**API Name**

`OrganizationDomainUrl__c`

**Type**

_Url_

---

### Environment Type

**API Name**

`OrganizationEnvironmentType__c`

**Type**

_Picklist_

#### Possible values are

- Production
- Sandbox
- Scratch Org

---

### Organization ID

**API Name**

`OrganizationId__c`

**Type**

_Text_

---

### Instance Name

**API Name**

`OrganizationInstanceName__c`

**Type**

_Text_

---

### DEPRECATED: Instance Release Cycle

**API Name**

`OrganizationInstanceReleaseCycle__c`

**Type**

_Picklist_

#### Possible values are

- Preview Instance
- Non-Preview Instance
- Unknown

---

### Organization Limits

**API Name**

`OrganizationLimits__c`

**Type**

_LongTextArea_

---

### Organization Location

**API Name**

`OrganizationLocation__c`

**Type**

_Picklist_

#### Possible values are

- APAC
- EMEA
- NA

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

### Organization Release Number

The release number for the org&#x27;s instance - determined by making a callout to status.salesforce.com

**API Name**

`OrganizationReleaseNumber__c`

**Type**

_Text_

---

### Organization Release Version

The release version for the org&#x27;s instance - determined by making a callout to status.salesforce.com

**API Name**

`OrganizationReleaseVersion__c`

**Type**

_Text_

---

### Organization Type

**API Name**

`OrganizationType__c`

**Type**

_Picklist_

#### Possible values are

- Team Edition
- Professional Edition
- Enterprise Edition
- Developer Edition
- Personal Edition
- Unlimited Edition
- Contact Manager Edition
- Base Edition

---

### Parent Log

The log from the original transaction that initiated a child log - for example, batch jobs have start, execute and finish methods. All 3 are considered separate transactions. By using the parent log, logs from all 3 transactions can be linked together.

**API Name**

`ParentLog__c`

**Type**

_Lookup_

---

### Parent Log

**API Name**

`ParentLogLink__c`

**Type**

_Text_

---

### Parent Log Transaction ID

**API Name**

`ParentLogTransactionId__c`

**Type**

_Text_

---

### Parent Session ID

**API Name**

`ParentSessionId__c`

**Type**

_Text_

---

### Priority

**API Name**

`Priority__c`

**Type**

_Picklist_

#### Possible values are

- High
- Medium
- Low

---

### Profile ID

**API Name**

`ProfileId__c`

**Type**

_Text_

---

### Profile

**API Name**

`ProfileLink__c`

**Type**

_Text_

---

### Profile Name

**API Name**

`ProfileName__c`

**Type**

_Text_

---

### Request ID

**API Name**

`RequestId__c`

**Type**

_Text_

---

### DEPRECATED: Scenario

**API Name**

`Scenario__c`

**Type**

_Text_

---

### Session ID

**API Name**

`SessionId__c`

**Type**

_Text_

---

### Session Security Level

**API Name**

`SessionSecurityLevel__c`

**Type**

_Picklist_

#### Possible values are

- LOW
- STANDARD
- HIGH_ASSURANCE

---

### Session Type

**API Name**

`SessionType__c`

**Type**

_Picklist_

#### Possible values are

- Aura
- Oauth2
- UI
- Visualforce

---

### Source IP

**API Name**

`SourceIp__c`

**Type**

_Text_

---

### Start Time

**API Name**

`StartTime__c`

**Type**

_Summary_

---

### Status

**API Name**

`Status__c`

**Type**

_Picklist_

#### Possible values are

- New
- Ignored
- On Hold
- In Progress
- Done

---

### System Mode

**API Name**

`SystemMode__c`

**Type**

_Picklist_

#### Possible values are

- ANONYMOUS
- AURA
- BATCH_ACS
- BATCH_APEX
- BATCH_CHUNK_PARALLEL
- BATCH_CHUNK_SERIAL
- BULK_API
- COMMERCE_INTEGRATION
- DISCOVERABLE_LOGIN
- FUNCTION_CALLBACK
- FUTURE
- INBOUND_EMAIL_SERVIC
- INVOCABLE_ACTION
- IOT
- QUEUEABLE
- QUICK_ACTION
- REMOTE_ACTION
- REST
- RUNTEST_ASYNC
- RUNTEST_DEPLOY
- RUNTEST_SYNC
- SCHEDULED
- SOAP
- SYNCHRONOUS
- TRANSACTION_FINALIZE
- VF

---

### System Mode

**API Name**

`SystemModeSummary__c`

**Type**

_Text_

---

### Theme Displayed

**API Name**

`ThemeDisplayed__c`

**Type**

_Picklist_

#### Possible values are

- Theme1
- Theme2
- Theme3
- Theme4d
- Theme4t
- Theme4u
- PortalDefault
- Webstore

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

### Total DEBUG Entries

The total number of log entries with logging level &#x3D;&#x3D; &#x27;DEBUG&#x27;

**API Name**

`TotalDEBUGLogEntries__c`

**Type**

_Summary_

---

### Total ERROR Entries

The total number of log entries with logging level &#x3D;&#x3D; &#x27;ERROR&#x27;

**API Name**

`TotalERRORLogEntries__c`

**Type**

_Summary_

---

### Total FINE Entries

The total number of log entries with logging level &#x3D;&#x3D; &#x27;FINE&#x27;

**API Name**

`TotalFINELogEntries__c`

**Type**

_Summary_

---

### Total FINER Entries

The total number of log entries with logging level &#x3D;&#x3D; &#x27;FINER&#x27;

**API Name**

`TotalFINERLogEntries__c`

**Type**

_Summary_

---

### Total FINEST Entries

The total number of log entries with logging level &#x3D;&#x3D; &#x27;FINEST&#x27;

**API Name**

`TotalFINESTLogEntries__c`

**Type**

_Summary_

---

### Total INFO Entries

The total number of log entries with logging level &#x3D;&#x3D; &#x27;INFO&#x27;

**API Name**

`TotalINFOLogEntries__c`

**Type**

_Summary_

---

### Total CPU

**API Name**

`TotalLimitsCpuTimeUsed__c`

**Type**

_Summary_

---

### Total Entries

**API Name**

`TotalLogEntries__c`

**Type**

_Number_

---

### Total WARN Entries

The total number of log entries with logging level &#x3D;&#x3D; &#x27;WARN&#x27;

**API Name**

`TotalWARNLogEntries__c`

**Type**

_Summary_

---

### Transaction ID

**API Name**

`TransactionId__c`

**Type**

_Text_

---

### Transaction Scenario

**API Name**

`TransactionScenario__c`

**Type**

_Lookup_

---

### Transaction Scenario

**API Name**

`TransactionScenarioLink__c`

**Type**

_Text_

---

### Transaction Scenario Name

**API Name**

`TransactionScenarioName__c`

**Type**

_Text_

---

### Transaction Scenario

**API Name**

`TransactionScenarioText__c`

**Type**

_Text_

---

### User License Definition Key

https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_userlicense.htm

**API Name**

`UserLicenseDefinitionKey__c`

**Type**

_Picklist_

#### Possible values are

- AUL
- AUL_LIGHT
- AUL1
- FDC_ONE
- FDC_SUB
- Overage_Platform_Portal_User
- PID_CHATTER
- PID_CONTENT
- PID_Customer_Community
- PID_Customer_Community_Login
- PID_Customer_Portal_Basic
- PID_Customer_Portal_Standard
- PID_FDC_FREE
- PID_IDEAS
- PID_Ideas_Only_Portal
- PID_Ideas_Only_Site
- PID_KNOWLEDGE
- PID_Limited_Customer_Portal_Basic
- PID_Limited_Customer_Portal_Standard
- PID_Overage_Customer_Portal_Basic
- PID_Overage_High
- PID_Partner_Community
- PID_Partner_Community_Login
- PID_STRATEGIC_PRM
- Platform_Portal_User
- POWER_PRM
- POWER_SSP
- SFDC

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

_Picklist_

#### Possible values are

- Analytics Cloud Integration User
- Authenticated Website
- Chatter External
- Chatter Free
- Cloud Integration User
- Customer Community
- Customer Community Login
- Customer Community Plus
- Customer Community Plus Login
- Customer Portal Manager Custom
- Customer Portal Manager Standard
- External Identity
- Force.com - App Subscription
- Force.com - Free
- Gold Partner
- High Volume Customer Portal
- Identity
- Partner App Subscription
- Partner Community
- Partner Community Login
- Salesforce
- Salesforce Platform
- Silver Partner
- Work.com Only
- XOrg Proxy User

---

### User Logging Level

**API Name**

`UserLoggingLevel__c`

**Type**

_Picklist_

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

### User Role

**API Name**

`UserRoleLink__c`

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

_Picklist_

#### Possible values are

- Standard
- PowerPartner
- CSPLitePortal
- CustomerSuccess
- PowerCustomerSuccess
- CsnOnly
- AutomatedProcess
- Guest

---

### Logged By Current User

**API Name**

`WasLoggedByCurrentUser__c`

**Type**

_Checkbox_
