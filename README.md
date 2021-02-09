# Nebula Logger for Salesforce
[![Travis CI](https://img.shields.io/travis/jongpie/NebulaLogger/master.svg)](https://travis-ci.org/jongpie/NebulaLogger)

Designed for Salesforce admins, developers & architects. A robust logger for Apex, Flow, Process Builder & Integrations.

## Features
1. Easily add log entries via Apex, Flow & Process Builder
2. Manage & report on logging data using the `Log__c` and `LogEntry__c` objects
3. Leverage `LogEntryEvent__e` platform events for real-time monitoring & integrations
4. Easily enable logging & change the logging level for different users & profiles using `LoggerSettings__c` custom hierarchy setting


## Installing
You can either deploy the metadata from this repo to your org, or install the managed package. The metadata is the same, but there are some differences in using the 2 versions

|             | Unpackaged Metadata | 2nd Gen Managed Package |
| ----------- | ------------------- | ----------------------- |
| Namespace   | none                | `Nebula`                |
| Apex Stack Traces        | Automatically stored in `LogEntry__c.StackTrace__c` | Requires calling `parseStackTrace()` due to Salesforce limitations with managed packages |
| Installing  | [Deploy Unpackaged Metadata](https://githubsfdeploy.herokuapp.com) | [Install Managed Package](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t4x000000lsfpAAA)             |


## Getting Started
After deploying Nebula Logger to your org, it can be used immediately by admins without any additional configuration. But you may still want to...
* Assign the permission set `LoggerLogCreator` or `LoggerEndUser` to any users that will generate logs via Apex, Flow or Process Builder. `LoggerEndUser` also provides read access to any `Log__c` records shared with the user.
* Assign the permission sets `LoggerLogAdmin` or `LoggerLogViewer` to power users
* Customize the default settings in `LoggerSettings__c`

## Logger for Apex: Quick Start
For Apex developers, the `Logger` class has several methods that can be used as replacements for `System.debug()`.

```java
// This will generate a debug statement within developer console
System.debug('Debug statement using native Apex');

// This will create a new `Log__c` record with multiple related `LogEntry__c` records
Logger.error('Add log entry using Nebula Logger with loging level == ERROR');
Logger.warn('Add log entry using Nebula Logger with loging level == WARN');
Logger.info('Add log entry using Nebula Logger with loging level == INFO');
Logger.debug('Add log entry using Nebula Logger with loging level == DEBUG');
Logger.fine('Add log entry using Nebula Logger with loging level == FINE');
Logger.finer('Add log entry using Nebula Logger with loging level == FINER');
Logger.finest('Add log entry using Nebula Logger with loging level == FINEST');
Logger.saveLog();
```


This results in 1 `Log__c` record with several related `LogEntry__c` records.

![Apex Log Results](./content/apex-log.png)

## Logger for Flow & Process Builder: Quick Start
Within Flow & Process Builder, you can select 1 of the several Logging actions

![Flow Logger Actions](./content/flow-logger-actions.png)

In this simple example, a Flow is configured after-insert and after-update to log a Case record (using the action 'Add Log Entry for an SObject Record')

![Flow Builder: Log Case](./content/flow-builder-log-case.png)

This results in a `Log__c` record with related `LogEntry__c` records.

![Flow Log Results](./content/flow-log.png)

## All Together: Apex & Flow in 1 Log
After incorporating Logger into your Flows & Apex code (including controllers, trigger framework, etc.), you'll have a unified transaction log of all you declarative & custom code automations.

```java
Case currentCase = [SELECT Id, CaseNumber, Type, Status, IsClosed FROM Case LIMIT 1];

Logger.info('First, log the case through Apex', currentCase);

Logger.debug('Now, we update the case in Apex to cause our record-triggered Flow to run');
update currentCase;

Logger.info('Last, save our log');
Logger.saveLog();
```

This generates 1 consolidated `Log__c`, containing `LogEntry__c` records from both Apex and Flow

![Flow Log Results](./content/combined-apex-flow-log.png)

## Event-Driven Integrations with Platform Events
Logger is built using Salesforce's [Platform Events](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_intro.htm), an event-driven messaging architecture. External integrations can subscribe to log events using the `LogEntryEvent__e` object - see more details at [the Platform Events Developer Guide site](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_subscribe_cometd.htm)

## Managing Logs
To help development and support teams better manage logs (and any underlying code or config issues), some fields on `Log__c` are provided to track the owner, priority and status of a log. These fields are optional, but are helpful in critical environments (production, QA sandboxes, UAT sandboxes, etc.) for monitoring ongoing user activities.
* All editable fields on `Log__c` can be updated via the 'Manage Log' quick action
* Additional fields, such as `Log__c.IsClosed__c`, `Log__c.ClosedBy__c` and `Log__c.ClosedDate__c`, are automatically set based on changes to `Log__c.Status__c`.
* To customize the statuses provided, simply update the picklist values for `Log__c.Status__c` and create/update corresponding records in the custom metadata type `LogStatus__mdt`. This custom metadata type controls which statuses are considerd closed and resolved.

## Deleting Old Logs
Two Apex classes are provided out-of-the-box to handle automatically deleting old logs
1. `LogBatchPurger` - this batch Apex class will delete any `Log__c` records with `Log__c.LogRetentionDate__c <= System.today()`.
   * By default, this field is populated with "TODAY + 14 DAYS" - the number of days to retain a log can be customized in `LoggerSettings__c`.
   * Users can also manually edit this field to change the retention date - or set it to null to prevent the log from being automatically deleted
2. `LogBatchPurgeScheduler` - this schedulable Apex class can be schedule to run `LogBatchPurger` on a daily or weekly basis