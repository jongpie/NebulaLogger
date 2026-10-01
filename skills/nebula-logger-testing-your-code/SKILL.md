---
name: nebula-logger-testing-your-code
description: Use this skill when the user wants to write Apex or LWC tests for code that calls Nebula Logger. Covers observing that the right entries were buffered, controlling logging levels inside tests, isolating tests from persisted `Log__c` / `LogEntry__c` / `LogEntryTag__c` / `LoggerScenario__c` / `LoggerTag__c` records, and Nebula Logger APIs that are safe to call from a subscriber's own test suite.
---

# Testing Code That Uses Nebula Logger

This skill is for developers whose own Apex or LWC code calls `Logger.info(...)`, `Logger.error(...)`, etc. and who want to prove in tests that the right things get logged. It only uses `global` Nebula Logger APIs, so the same techniques work whether the org has the unlocked or the managed package installed.

## The Buffer Model

Nebula Logger buffers log entries in memory during a transaction. `Logger.saveLog()` moves the buffered entries onto the save path (platform event, queueable, REST, or synchronous DML) - see [nebula-logger-instrumentation](../nebula-logger-instrumentation/SKILL.md) for the save method choice.

For tests, the buffer is the observation point: you can add entries, inspect the buffer size before `saveLog()`, then either call `saveLog()` and query the resulting records, or `flushBuffer()` to drop them without persisting. All three APIs are global.

## Assert on the Buffer Before Save

`Logger.getBufferSize()` returns the number of entries currently buffered. Use it to prove your code added the entries you expected without needing to persist them.

```apex
@IsTest
static void it_should_log_a_warning_when_credit_check_fails() {
  Account account = new Account(Name = 'Test Account');
  insert account;

  System.Test.startTest();
  new CreditCheckService().evaluate(account.Id);
  System.Test.stopTest();

  System.Assert.areEqual(1, Logger.getBufferSize(), 'Expected exactly one entry buffered');
}
```

Because `getBufferSize()` runs before `saveLog()` fires, the assertion works without waiting for the platform event to publish.

## Assert on Persisted Records After Save

When you need to assert on the message text, logging level, related record, or scenario, save the log and query the persisted records. The full set of custom objects on the log-management side is:

- `Log__c` - one record per logging transaction.
- `LogEntry__c` - one record per `Logger.info(...)` / `.error(...)` / etc. call.
- `LogEntryTag__c` - junction between `LogEntry__c` and `LoggerTag__c` when tags are applied.
- `LoggerScenario__c` - captures each unique `Logger.setScenario(...)` value used across transactions.
- `LoggerTag__c` - the tag catalog referenced by `LogEntryTag__c`.

With the default `EVENT_BUS` save method, the platform event fires during `System.Test.stopTest()`, populating all of the above.

### When You Also Need `System.Test.getEventBus().deliver()`

`System.Test.stopTest()` only delivers the platform events queued up **before** the stopTest boundary. Any `LogEntryEvent__e` records published **during** the async work that stopTest itself flushes need a follow-up call to `System.Test.getEventBus().deliver()` before `LogEntry__c` / `Log__c` records materialize. The two situations where this matters:

- **`Logger.setSaveMethod(Logger.SaveMethod.QUEUEABLE)` or `Logger.saveLog(Logger.SaveMethod.QUEUEABLE)`** - Nebula Logger's queueable-based save publishes the platform event from inside the queueable. The queueable runs during `stopTest`, but the event it publishes needs a second delivery pass.
- **Async code under test that itself logs** - A `System.Queueable`, `System.Finalizer`, or `Database.Batchable` that calls `Logger.info(...)` / `.error(...)` / `saveLog()` inside `execute` publishes its platform event from within the async context. `stopTest` runs the async job but does not deliver the platform events it produced.

```apex
@IsTest
static void it_should_log_the_error_from_a_failed_queueable() {
  System.Test.startTest();
  System.enqueueJob(new ExampleFailedQueueable());
  System.Test.stopTest();
  System.Test.getEventBus().deliver();

  List<LogEntry__c> entries = [SELECT LoggingLevel__c FROM LogEntry__c WHERE LoggingLevel__c = 'ERROR'];
  System.Assert.areEqual(1, entries.size());
}
```

For synchronous code using the default `EVENT_BUS` save method, `stopTest` alone is enough - no extra deliver call is needed.

```apex
@IsTest
static void it_should_log_the_error_message_when_credit_check_throws() {
  Account account = new Account(Name = 'Test Account');
  insert account;

  System.Test.startTest();
  System.Exception thrownException;
  try {
    new CreditCheckService().evaluate(account.Id);
    System.Assert.fail('Expected an exception');
  } catch (System.Exception ex) {
    thrownException = ex;
  }
  System.Test.stopTest();

  System.Assert.areNotEqual('Expected an exception', thrownException.getMessage(), 'The wrong exception was thrown!');
  List<LogEntry__c> entries = [
    SELECT LoggingLevel__c, Message__c, RecordId__c, ExceptionMessage__c, ExceptionType__c
    FROM LogEntry__c
  ];
  System.Assert.areEqual(1, entries.size());
  System.Assert.areEqual('ERROR', entries[0].LoggingLevel__c);
  System.Assert.areEqual(thrownException.getMessage(), entries[0].ExceptionMessage__c);
  System.Assert.areEqual(thrownException.getTypeName(), entries[0].ExceptionType__c);
}
```

## Control Whether Entries Are Persisted

By default, Nebula Logger honors `LoggerSettings__c` inside test context - if the org default has logging enabled at an appropriate level, entries persist. If your test wants to run the code under test without touching the database:

- Call `Logger.suspendSaving()` at the top of the test. Subsequent `saveLog()` calls are no-ops - no records are inserted, no platform events are published, and the buffer is left untouched.
- Call `Logger.resumeSaving()` to reverse the suspend. Every entry that accumulated in the buffer while saving was suspended is still there, so the next `saveLog()` call flushes all of them. If the intent is to discard those entries instead of persisting them, call `Logger.flushBuffer()` before resuming.
- Call `Logger.flushBuffer()` at the top of the test if you only want to prevent test-triggered entries from accumulating before your setup completes.
- Call `Logger.isSavingSuspended()` to guard against test pollution when writing shared test utilities.

```apex
@IsTest
static void it_should_not_persist_log_records_when_saving_is_suspended() {
  Logger.suspendSaving();

  new CreditCheckService().evaluate(fakeAccountId());
  Logger.saveLog();

  System.Assert.isTrue([SELECT COUNT() FROM Log__c] == 0);
}
```

## Nebula Logger's CMDT Records Are Live in Tests

Salesforce returns the org's actual custom metadata records when tests query CMDT - the platform does not roll them back like it does with sObject data. Nebula Logger takes advantage of that: the internal selector layer reads whatever `LoggerParameter__mdt`, `LogEntryDataMaskRule__mdt`, `LogEntryTagRule__mdt`, `LoggerFieldMapping__mdt`, `LoggerPlugin__mdt`, `LoggerScenarioRule__mdt`, `LoggerSObjectHandler__mdt`, and `LogStatus__mdt` records are deployed to the org, and uses them during tests exactly the way it uses them at runtime.

Practical consequences for a subscriber's own tests:

- Changing a `LoggerParameter__mdt.Value__c` in the org (e.g. flipping `QueryUserDataSynchronously` from `true` to `false`, or setting a non-Boolean value on a parameter that expects a Boolean) affects test behavior, not just runtime behavior. Tests that assumed the out-of-the-box value can start failing after a config change.
- New `LogEntryDataMaskRule__mdt` records you deploy will mask sensitive data inside tests, so an assertion against the raw message text needs to expect the masked form.
- New `LoggerPlugin__mdt` records execute in tests too. If a plugin has side effects (callouts, DML, platform events), tests need to mock or account for them.
- `LoggerScenario__mdt` records override `LoggerSettings__c` at test time the same way they do at runtime.

Treat CMDT changes as behavior changes, and rerun the relevant test suite after deploying any customization to Nebula Logger's CMDT records. Nebula Logger's internal `LoggerConfigurationSelector.useMocks()` seam is not `global`, so it isn't available for subscriber tests - the supported approach is to keep tests aware of the org's CMDT state, and use `Logger.suspendSaving()` / `flushBuffer()` when a test needs to opt out of the persistence side of things.

## LWC Test Considerations

For LWC tests using `sfdx-lwc-jest`, mock the `c/logger` module and assert that your component calls the right entry-level and passes the right message / record.

```js
// __tests__/paymentPanel.test.js
import { createElement } from 'lwc';
import PaymentPanel from 'c/paymentPanel';

const mockLogger = {
  setScenario: jest.fn(),
  info: jest.fn().mockReturnThis(),
  error: jest.fn().mockReturnThis(),
  setExceptionDetails: jest.fn().mockReturnThis(),
  saveLog: jest.fn()
};

jest.mock('c/logger', () => ({
  getLogger: () => mockLogger
}));

describe('c-payment-panel', () => {
  it('logs an INFO entry when the panel initializes', () => {
    const element = createElement('c-payment-panel', { is: PaymentPanel });
    document.body.appendChild(element);

    expect(mockLogger.setScenario).toHaveBeenCalledWith('Payment UI');
    expect(mockLogger.info).toHaveBeenCalledWith('Payment panel initialized');
    expect(mockLogger.saveLog).toHaveBeenCalled();
  });
});
```

Per the repo's testing conventions, assert on the arguments passed to the logger methods (`toHaveBeenCalledWith(...)`), not just that they were called. `toHaveBeenCalled()` alone lets regressions slip through where the message text is dropped or garbled.

## Global APIs Safe for Test Code

Only `global` APIs are supported for use from your own test code. Anything `public` is Nebula Logger's internal surface and can change without notice - see the "Supported API Surface" section in [nebula-logger-instrumentation](../nebula-logger-instrumentation/SKILL.md).

The following are all `global` and safe to call from a subscriber's test suite in either package:

- `Logger.getBufferSize()` - Inspect how many entries are buffered.
- `Logger.suspendSaving()` / `Logger.resumeSaving()` / `Logger.isSavingSuspended()` - Prevent or gate persistence.
- `Logger.flushBuffer()` - Drop buffered entries without persisting.
- `Logger.getTransactionId()` - Correlate a test's logs when asserting on persisted records.
- `Logger.setScenario(...)` / `Logger.endScenario(...)` - Set a test-specific scenario so persisted logs are easy to identify.
- Level-specific methods (`Logger.info(...)`, `Logger.error(...)`, etc.) and `Logger.saveLog()`.

## Related Skills

- [nebula-logger-instrumentation](../nebula-logger-instrumentation/SKILL.md) - The APIs being tested.
- [nebula-logger-best-practices](../nebula-logger-best-practices/SKILL.md) - Conventions the code under test should follow.
