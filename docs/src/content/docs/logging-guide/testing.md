---
title: Testing your instrumentation
description: Writing Apex and jest tests for code that calls Nebula Logger.
---

Both Apex and jest tests can verify your instrumentation without depending on external state. The buffer model is your observation point: add entries, inspect the buffer, then either save and query records or drop the buffer.

Everything in this page uses only `global` Nebula Logger APIs, so it works in both the unlocked and managed packages.

## The buffer

Nebula Logger buffers log entries in memory. `Logger.saveLog()` moves the buffer to the configured save path.

Three global APIs let tests observe or control the buffer without persisting:

- `Logger.getBufferSize()` - how many entries are currently buffered.
- `Logger.flushBuffer()` - drop buffered entries without persisting.
- `Logger.suspendSaving()` / `Logger.resumeSaving()` / `Logger.isSavingSuspended()` - gate persistence.

## Assert on the buffer before save

The simplest check: verify your code added the expected number of entries.

```apex
@IsTest(IsParallel=true)
private class CreditCheckService_Tests {
  @IsTest
  static void it_should_log_a_warning_when_credit_check_fails() {
    Schema.Account account = new Schema.Account(Name = 'Test Account');
    insert account;

    System.Test.startTest();
    new CreditCheckService().evaluate(account.Id);
    System.Test.stopTest();

    System.Assert.areEqual(1, Logger.getBufferSize(), 'Expected exactly one entry buffered');
  }
}
```

Because `getBufferSize()` runs before `saveLog()` fires, the assertion works without waiting for the platform event to publish.

## Assert on persisted records after save

When you need to assert on message text, level, related record, or scenario, save the log and query. With the default `EVENT_BUS` save method, the platform event publishes during `System.Test.stopTest()`.

```apex
@IsTest
static void it_should_log_the_error_message_when_credit_check_throws() {
  Schema.Account account = new Schema.Account(Name = 'Test Account');
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

## Suppressing persistence in tests

If your test wants to run the code under test without touching `Log__c` at all:

```apex
@IsTest
static void it_should_not_persist_log_records_when_saving_is_suspended() {
  Logger.suspendSaving();

  new CreditCheckService().evaluate(fakeAccountId());
  Logger.saveLog();

  System.Assert.areEqual(0, [SELECT COUNT() FROM Log__c]);
}
```

## Controlling logging level in tests

Nebula Logger honors `LoggerSettings__c` in test context. If a test needs a specific level (typically to force `FINE` / `FINEST` entries to persist), create a user-scoped setting record in test setup.

```apex
@TestSetup
static void setup() {
  LoggerSettings__c settings = new LoggerSettings__c(
    SetupOwnerId = UserInfo.getUserId(),
    IsEnabled__c = true,
    LoggingLevel__c = 'FINEST'
  );
  insert settings;
}
```

This is standard hierarchy custom setting behavior - no Nebula Logger internals required.

## LWC / jest tests

Mock the `c/logger` module and assert on what your component calls.

```js
// __tests__/paymentPanel.test.js
import { createElement } from 'lwc';
import PaymentPanel from 'c/paymentPanel';

const mockLogger = {
  setScenario: jest.fn(),
  info: jest.fn().mockReturnThis(),
  error: jest.fn().mockReturnThis(),
  setExceptionDetails: jest.fn().mockReturnThis(),
  addTag: jest.fn().mockReturnThis(),
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

**Assert on the arguments**, not just that the method was called. `expect(mock.info).toHaveBeenCalled()` alone lets regressions slip through where the message text is dropped or garbled. Use `toHaveBeenCalledWith(...)` for direct payloads, or capture `mockLogger.info.mock.calls[0][0]` for multi-field payloads.

## What's safe to call from external tests

Only `global` APIs are supported for external test code. Anything `public` is internal to Nebula Logger and can change without notice.

Safe from a subscriber's own test suite:

- `Logger.getBufferSize()`
- `Logger.suspendSaving()` / `Logger.resumeSaving()` / `Logger.isSavingSuspended()`
- `Logger.flushBuffer()`
- `Logger.getTransactionId()`
- `Logger.setScenario(...)` / `Logger.endScenario(...)`
- All level-specific methods and `Logger.saveLog()`.

**Not safe** - anything `public` (no `global` modifier). The internal test patterns in `nebula-logger/core/tests/` use non-`global` APIs and are not appropriate for use outside Nebula Logger's own codebase.

## Where next

- [Apex](/logging-guide/apex/) - the APIs being tested.
- [Lightning Web Components](/logging-guide/lwc/) - the LWC path.
