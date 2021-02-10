# Nebula Logger for Salesforce
[![Travis CI](https://img.shields.io/travis/jongpie/NebulaLogger/master.svg)](https://travis-ci.org/jongpie/NebulaLogger)

Designed for Salesforce admins, developers & architects. A robust logger for Apex, Flow, Process Builder & Integrations.

<a href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04t4x000000lsfpAAA">
    <img alt="Install Managed Package" src="./content/btn-install-managed-package.png">
</a>
<a href="https://githubsfdeploy.herokuapp.com">
    <img alt="Deploy Unpackaged Metadata" src="./content/btn-deploy-unmanaged-metadata.png">
</a>

## Features
1. Easily add log entries via Apex, Flow & Process Builder
2. Manage & report on logging data using the `Nebula__Log__c` and `Nebula__LogEntry__c` objects
3. Leverage `Nebula__LogEntryEvent__e` platform events for real-time monitoring & integrations
4. Enable logging and set the logging level for different users & profiles using `Nebula__LoggerSettings__c` custom hierarchy setting
5. Dynamically assign Topics to `Nebula__Log__c` and `Nebula__LogEntry__c` records for tagging/labeling your logs

## Installing

In general, using the managed package is recommended - but you can choose to either deploy the metadata from this repo to your org, or install the managed package. The metadata is the same, but there are some differences in using the 2 versions. All examples in README include the `Nebula` namespace - simple remove the namespace from the examples if you are using the unpackaged metadata.

|             | Unpackaged Metadata | 2nd Gen Managed Package |
| ----------- | ------------------- | ----------------------- |
| Namespace   | none                | `Nebula`                |
| Future Releases        | New enhancements & bugfixes will be immediately available in GitHub | Slower release cycle: new package versions will only be released once new enhancements & bugfixes have been tested and code is stabilized |
| Public Apex Methods        | Any `public` Apex methods are subject to change in the future - they can be used, but you may encounter deployment issues if future changes to `public` methods are not backwards-compatible | Only `global` methods are available in managed packages - any `global` Apex methods available in the managed package will be supported for the foreseeable future |
| Apex Debug Statements        | `System.debug()` is automatically called  | Requires adding your own calls for `System.debug()` due to Salesforce limitations with managed packages |
| Apex Stack Traces        | Automatically stored in `LogEntry__c.StackTrace__c` when calling methods like `Logger.debug('my message');` | Requires calling `parseStackTrace()` due to Salesforce limitations with managed packages. For example:<br />`Nebula.Logger.debug('my message').parseStackTrace(new DmlException().getStackTrace());` |

## Getting Started
After deploying Nebula Logger to your org, it can be used immediately by admins without any additional configuration. But you may still want to...
* Assign the permission set to users
  * `LoggerLogCreator` provides the minimum access needed for users to generate logs via Apex, Flow or Process Builder
  * `LoggerEndUser` provides access to generate logs, as well as read-only access to any log records shared with the user.
  * `LoggerLogViewer` provides view-all access (read-only) to all log records.
  * `LoggerLogAdmin` provides view-all and modify-all access to all log records.
* Customize the default settings in `Nebula__LoggerSettings__c`
  * You can customize settings at the org, profile and user levels
* Enable Salesforce Topics for the `Nebula__Log__c` and `Nebula__LogEntry__c` objects for tagging/labeling.
  * Topics on `Nebula__Log__c` can then be used as list view filters (and more).

## Logger for Apex: Quick Start
For Apex developers, the `Nebula.Logger` class has several methods that can be used as replacements for `System.debug()`.

```java
// This will generate a debug statement within developer console
System.debug('Debug statement using native Apex');

// This will create a new `Nebula__Log__c` record with multiple related `Nebula__LogEntry__c` records
Nebula.Logger.error('Add log entry using Nebula Logger with logging level == ERROR');
Nebula.Logger.warn('Add log entry using Nebula Logger with logging level == WARN');
Nebula.Logger.info('Add log entry using Nebula Logger with logging level == INFO');
Nebula.Logger.debug('Add log entry using Nebula Logger with logging level == DEBUG');
Nebula.Logger.fine('Add log entry using Nebula Logger with logging level == FINE');
Nebula.Logger.finer('Add log entry using Nebula Logger with logging level == FINER');
Nebula.Logger.finest('Add log entry using Nebula Logger with logging level == FINEST');
Nebula.Logger.saveLog();
```


This results in 1 `Nebula__Log__c` record with several related `Nebula__LogEntry__c` records.

![Apex Log Results](./content/apex-log.png)

## Logger for Flow & Process Builder: Quick Start
Within Flow & Process Builder, you can select 1 of the several Logging actions

![Flow Logger Actions](./content/flow-logger-actions.png)

In this simple example, a Flow is configured after-insert and after-update to log a Case record (using the action 'Add Log Entry for an SObject Record')

![Flow Builder: Log Case](./content/flow-builder-log-case.png)

This results in a `Nebula__Log__c` record with related `Nebula__LogEntry__c` records.

![Flow Log Results](./content/flow-log.png)

## All Together: Apex & Flow in One Log
After incorporating Logger into your Flows & Apex code (including controllers, trigger framework, etc.), you'll have a unified transaction log of all your declarative & custom code automations.

```java
Case currentCase = [SELECT Id, CaseNumber, Type, Status, IsClosed FROM Case LIMIT 1];

Nebula.Logger.info('First, log the case through Apex', currentCase);

Nebula.Logger.debug('Now, we update the case in Apex to cause our record-triggered Flow to run');
update currentCase;

Nebula.Logger.info('Last, save our log');
Nebula.Logger.saveLog();
```

This generates 1 consolidated `Nebula__Log__c`, containing `Nebula__LogEntry__c` records from both Apex and Flow

![Flow Log Results](./content/combined-apex-flow-log.png)

## Event-Driven Integrations with Platform Events
Logger is built using Salesforce's [Platform Events](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_intro.htm), an event-driven messaging architecture. External integrations can subscribe to log events using the `Nebula__LogEntryEvent__e` object - see more details at [the Platform Events Developer Guide site](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_subscribe_cometd.htm)

## Managing Logs
To help development and support teams better manage logs (and any underlying code or config issues), some fields on `Nebula__Log__c` are provided to track the owner, priority and status of a log. These fields are optional, but are helpful in critical environments (production, QA sandboxes, UAT sandboxes, etc.) for monitoring ongoing user activities.
* All editable fields on `Nebula__Log__c` can be updated via the 'Manage Log' quick action
* Additional fields, such as `Nebula__Log__c.Nebula__IsClosed__c`, `Nebula__Log__c.Nebula__IsResolved__c`, `Nebula__Log__c.Nebula__ClosedBy__c` and `Nebula__Log__c.Nebula__ClosedDate__c`, are automatically set based on changes to `Nebula__Log__c.Nebula__Status__c`.
* To customize the statuses provided, simply update the picklist values for `Nebula__Log__c.Status__c` and create/update corresponding records in the custom metadata type `Nebula__LogStatus__mdt`. This custom metadata type controls which statuses are considerd closed and resolved.

## Deleting Old Logs
Two Apex classes are provided out-of-the-box to handle automatically deleting old logs
1. `Nebula.LogBatchPurger` - this batch Apex class will delete any `Nebula__Log__c` records with `Log__c.LogRetentionDate__c <= System.today()`.
   * By default, this field is populated with "TODAY + 14 DAYS" - the number of days to retain a log can be customized in `Nebula__LoggerSettings__c`.
   * Users can also manually edit this field to change the retention date - or set it to null to prevent the log from being automatically deleted
2. `Nebula.LogBatchPurgeScheduler` - this schedulable Apex class can be schedule to run `Nebula.LogBatchPurger` on a daily or weekly basis