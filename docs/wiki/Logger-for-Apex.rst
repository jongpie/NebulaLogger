## Quick Start

For Apex developers, the `Logger` class has several methods that can be used to add entries with different logging levels. Each logging level's method has several overloads to support multiple parameters.

```java
// This will generate a debug statement within developer console
System.debug('Debug statement using native Apex');

// This will create a new `Log__c` record with multiple related `LogEntry__c` records
Logger.error('Add log entry using Nebula Logger with logging level == ERROR');
Logger.warn('Add log entry using Nebula Logger with logging level == WARN');
Logger.info('Add log entry using Nebula Logger with logging level == INFO');
Logger.debug('Add log entry using Nebula Logger with logging level == DEBUG');
Logger.fine('Add log entry using Nebula Logger with logging level == FINE');
Logger.finer('Add log entry using Nebula Logger with logging level == FINER');
Logger.finest('Add log entry using Nebula Logger with logging level == FINEST');
Logger.saveLog();
```

This results in 1 `Log__c` record with several related `LogEntry__c` records.

![Apex Log Results](./images/apex-log.png)

## Features for Apex Developers

Within Apex, there are several different methods that you can use that provide greater control over the logging system.

## Transaction Controls

Apex developers can use additional `Logger` methods to dynamically control how logs are saved during the current transaction.

- `Logger.suspendSaving()` – causes `Logger` to ignore any calls to `saveLog()` in the current transaction until `resumeSaving()` is called. Useful for reducing DML statements used by `Logger`
- `Logger.resumeSaving()` – re-enables saving after `suspendSaving()` is used
- `Logger.flushBuffer()` – discards any unsaved log entries
- `Logger.setSaveMethod(SaveMethod saveMethod)` - sets the default save method used when calling `saveLog()`. Any subsequent calls to `saveLog()` in the current transaction will use the specified save method
- `Logger.saveLog(SaveMethod saveMethod)` - saves any entries in Logger's buffer, using the specified save method for only this call. All subsequent calls to `saveLog()` will use the default save method.
- Enum `Logger.SaveMethod` - this enum can be used for both `Logger.setSaveMethod(saveMethod)` and `Logger.saveLog(saveMethod)`
  - `Logger.SaveMethod.EVENT_BUS` - The default save method, this uses the `EventBus` class to publish `LogEntryEvent__e` records. The default save method can also be controlled declaratively by updating the field `LoggerSettings__c.DefaultSaveMethod__c`
  - `Logger.SaveMethod.QUEUEABLE` - This save method will trigger `Logger` to save any pending records asynchronously using a queueable job. This is useful when you need to defer some CPU usage and other limits consumed by Logger.
  - `Logger.SaveMethod.REST` - This save method will use the current user’s session ID to make a synchronous callout to the org’s REST API. This is useful when you have other callouts being made and you need to avoid mixed DML operations.
  - `Logger.SaveMethod.SYNCHRONOUS_DML` - This save method will skip publishing the `LogEntryEvent__e` platform events, and instead immediately creates `Log__c` and `LogEntry__c` records. This is useful when you are logging from within the context of another platform event and/or you do not anticipate any exceptions to occur in the current transaction. **Note**: when using this save method, any exceptions will prevent your log entries from being saved - Salesforce will rollback any DML statements, including your log entries! Use this save method cautiously.

## Track Related Logs in Batchable and Queuable Jobs

In Salesforce, asynchronous jobs like batchable and queuable run in separate transactions - each with their own unique transaction ID. To relate these jobs back to the original log, Apex developers can use the method Logger.setParentLogTransactionId(String). `Logger` uses this value to relate child `Log__c` records, using the field `Log__c.ParentLog__c`.

This example batchable class shows how you can leverage this feature to relate all of your batch job’s logs together.

> :information_source: If you deploy this example class to your org,you can run it using `Database.executeBatch(new BatchableLoggerExample());`

```java
public with sharing class BatchableLoggerExample implements Database.Batchable<SObject>, Database.Stateful {
    private String originalTransactionId;

    public Database.QueryLocator start(Database.BatchableContext batchableContext) {
        // Each batchable method runs in a separate transaction
        // ...so store the first transaction ID to later relate the other transactions
        this.originalTransactionId = Logger.getTransactionId();

        Logger.info('Starting BatchableLoggerExample');
        Logger.saveLog();

        // Just as an example, query all accounts
        return Database.getQueryLocator([SELECT Id, Name, RecordTypeId FROM Account]);
    }

    public void execute(Database.BatchableContext batchableContext, List<Account> scope) {
        // One-time call (per transaction) to set the parent log
        Logger.setParentLogTransactionId(this.originalTransactionId);

        for (Account account : scope) {
            // Add your batch job's logic here

            // Then log the result
            Logger.info('Processed an account record', account);
        }

        Logger.saveLog();
    }

    public void finish(Database.BatchableContext batchableContext) {
        // The finish method runs in yet-another transaction, so set the parent log again
        Logger.setParentLogTransactionId(this.originalTransactionId);

        Logger.info('Finishing running BatchableLoggerExample');
        Logger.saveLog();
    }
}
```

Queueable jobs can also leverage the parent transaction ID to relate logs together. This example queueable job will run several chained instances. Each instance uses the parentLogTransactionId to relate its log back to the original instance's log.

> :information_source: If you deploy this example class to your org,you can run it using `System.enqueueJob(new QueueableLoggerExample(3));`

```java
public with sharing class QueueableLoggerExample implements Queueable {
    private Integer numberOfJobsToChain;
    private String parentLogTransactionId;

    private List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();

    // Main constructor - for demo purposes, it accepts an integer that controls how many times the job runs
    public QueueableLoggerExample(Integer numberOfJobsToChain) {
        this(numberOfJobsToChain, null);
    }

    // Second constructor, used to pass the original transaction's ID to each chained instance of the job
    // You don't have to use a constructor - a public method or property would work too.
    // There just needs to be a way to pass the value of parentLogTransactionId between instances
    public QueueableLoggerExample(Integer numberOfJobsToChain, String parentLogTransactionId) {
        this.numberOfJobsToChain = numberOfJobsToChain;
        this.parentLogTransactionId = parentLogTransactionId;
    }

    // Creates some log entries and starts a new instance of the job when applicable (based on numberOfJobsToChain)
    public void execute(System.QueueableContext queueableContext) {
        Logger.setParentLogTransactionId(this.parentLogTransactionId);

        Logger.fine('queueableContext==' + queueableContext);
        Logger.info('this.numberOfJobsToChain==' + this.numberOfJobsToChain);
        Logger.info('this.parentLogTransactionId==' + this.parentLogTransactionId);

        // Add your queueable job's logic here

        Logger.saveLog();

        --this.numberOfJobsToChain;
        if (this.numberOfJobsToChain > 0) {
            String parentLogTransactionId = this.parentLogTransactionId != null ? this.parentLogTransactionId : Logger.getTransactionId();
            System.enqueueJob(new QueueableLoggerExample(this.numberOfJobsToChain, parentLogTransactionId));
        }
    }
}
```

## Overloads for Logging Methods

Each of the logging methods in `Logger` (such as `Logger.error()`, `Logger.debug()`, and so on) has several static overloads for various parameters. These are intended to provide simple method calls for common parameters, such as:

- Log a message and a record - `Logger.error(String message, SObject record)`
- Log a message and a record ID - `Logger.error(String message, Id recordId)`
- Log a message and a save result - `Logger.error(String message, Database.SaveResult saveResult)`
- ...

To see the full list of overloads, check out the `Logger` class [documentation](https://jongpie.github.io/NebulaLogger/logger-engine/Logger).

## Using the Fluent Interface

Each of the logging methods in `Logger` returns an instance of the class `LogEntryEventBuilder`. This class provides several additional methods together to further customize each log entry - each of the builder methods can be chained together. In this example Apex, 3 log entries are created using different approaches for calling `Logger` - all 3 approaches result in identical log entries.

```java
// Get the current user so we can log it (just as an example of logging an SObject)
User currentUser = [SELECT Id, Name, Username, Email FROM User WHERE Id = :UserInfo.getUserId()];

// Using static Logger method overloads
Logger.debug('my string', currentUser);

// Using the instance of LogEntryEventBuilder
LogEntryEventBuilder builder = Logger.debug('my string');
builder.setRecord(currentUser);

// Chaining builder methods together
Logger.debug('my string').setRecord(currentUser);

// Save all of the log entries
Logger.saveLog();
```

## Using LogMessage for Dynamically-Generated Strings

The class `LogMessage` provides the ability to generate string messages on demand, using `String.format()`. This provides 2 benefits:

1. Improved CPU usage by skipping unnecessary calls to `String.format()`

   ```java
   // Without using LogMessage, String.format() is always called, even if the FINE logging level is not enabled for a user
   String formattedString = String.format('my example with input: {0}', List<Object>{'myString'});
   Logger.fine(formattedString);

   // With LogMessage, when the specified logging level (FINE) is disabled for the current user, `String.format()` is not called
   LogMessage logMessage = new LogMessage('my example with input: {0}', 'myString');
   Logger.fine(logMessage);
   ```

2. Easily build complex strings
   ```java
    // There are several constructors for LogMessage to support different numbers of parameters for the formatted string
    String unformattedMessage = 'my string with 3 inputs: {0} and then {1} and finally {2}';
    String formattedMessage = new LogMessage(unformattedMessage, 'something', 'something else', 'one more').getMessage();
    String expectedMessage = 'my string with 3 inputs: something and then something else and finally one more';
    System.assertEquals(expectedMessage, formattedMessage);
   ```

For more details, check out the `LogMessage` class [documentation](https://jongpie.github.io/NebulaLogger/logger-engine/LogMessage).
