---
name: nebula-logger-testing-your-code
description: Use this skill when the user wants to write Apex or LWC tests for code that calls Nebula Logger. Covers observing that the right entries were buffered, controlling logging levels inside tests, isolating tests from persisted `Log__c` / `LogEntry__c` records, and Nebula Logger APIs that are safe to call from a subscriber's own test suite.
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

When you need to assert on the message text, logging level, related record, or scenario, save the log and query `Log__c` / `LogEntry__c`. With the default `EVENT_BUS` save method, the platform event fires during `System.Test.stopTest()`.

```apex
@IsTest
static void it_should_log_the_error_message_when_credit_check_throws() {
  Account account = new Account(Name = 'Test Account');
  insert account;

  System.Test.startTest();
  try {
    new CreditCheckService().evaluate(account.Id);
    System.Assert.fail('Expected an exception');
  } catch (System.Exception ex) {
    // Expected
  }
  System.Test.stopTest();

  List<LogEntry__c> entries = [
    SELECT LoggingLevel__c, Message__c, RecordId__c
    FROM LogEntry__c
    ORDER BY TransactionEntryNumber__c
  ];
  System.Assert.areEqual(1, entries.size());
  System.Assert.areEqual('ERROR', entries[0].LoggingLevel__c);
  System.Assert.areEqual(account.Id, entries[0].RecordId__c);
}
```

## Control Whether Entries Are Persisted

By default, Nebula Logger honors `LoggerSettings__c` inside test context - if the org default has logging enabled at an appropriate level, entries persist. If your test wants to run the code under test without touching the database:

- Call `Logger.suspendSaving()` at the top of the test. `saveLog()` still moves entries out of the buffer, but no records are inserted and no platform events are published.
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

## Non-Goals for This Skill

- **Testing Nebula Logger itself**: The conventions inside `nebula-logger/core/tests/` are Nebula Logger's own internal testing style. They rely on non-`global` APIs (which are unsupported for external use - see the "Supported API Surface" section in [nebula-logger-instrumentation](../nebula-logger-instrumentation/SKILL.md)) and are not the right pattern for tests in a subscriber codebase.
- **Test-time configuration overrides**: If tests need a specific `LoggerSettings__c.LoggingLevel__c`, create a `LoggerSettings__c` record inside the test with `insert new LoggerSettings__c(SetupOwnerId = UserInfo.getUserId(), IsEnabled__c = true, LoggingLevel__c = 'FINEST');` in the test setup. This is standard hierarchy custom setting behavior and does not require any Nebula Logger internals.

## Related Skills

- [nebula-logger-instrumentation](../nebula-logger-instrumentation/SKILL.md) - The APIs being tested.
- [nebula-logger-best-practices](../nebula-logger-best-practices/SKILL.md) - Conventions the code under test should follow.
