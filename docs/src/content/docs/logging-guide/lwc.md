---
title: Lightning Web Components
description: Logging from LWCs using the c/logger module.
---

Import `getLogger` from the `c/logger` module and call it once per component instance. The returned logger exposes the same conceptual API as the Apex `Logger` class - level methods, chainable enrichment, `saveLog()` - adapted for browser-side use.

## Basic usage

```js
import { LightningElement } from 'lwc';
import { getLogger } from 'c/logger';

export default class PaymentPanel extends LightningElement {
  logger = getLogger();

  connectedCallback() {
    this.logger.setScenario('Payment UI');
    this.logger.info('Payment panel initialized');
    this.logger.saveLog();
  }

  async handleSave() {
    try {
      this.logger.debug('Submitting payment request');
      // async work
      this.logger.info('Payment submitted');
    } catch (error) {
      this.logger.error('Payment submit failed').setExceptionDetails(error);
    } finally {
      await this.logger.saveLog();
    }
  }
}
```

## Level methods

Every level available in Apex is available on the LWC logger. Each returns a builder that supports enrichment chaining.

```js
this.logger.error('Critical failure');
this.logger.warn('Recoverable issue');
this.logger.info('Business milestone');
this.logger.debug('Debug detail');
this.logger.fine('Verbose detail');
this.logger.finer('More verbose');
this.logger.finest('Most verbose');
```

## Builder methods

Off the level call, chain any of:

- `.setRecord(recordOrId)` - attach a record or ID.
- `.setExceptionDetails(error)` - attach a JavaScript `Error` (message, stack, name).
- `.setScenario(scenarioName)` - scenario for this specific entry (usually you'd call `logger.setScenario(...)` at the transaction level instead).
- `.addTag(tagName)` - add a tag.

```js
this.logger.error('Payment submit failed').setRecord(this.accountId).setExceptionDetails(error).addTag('payment').addTag('checkout');
```

## saveLog is async

`saveLog()` returns a Promise. Await it when subsequent code depends on the save being complete - for example, in a `finally` block before returning from an async handler:

```js
async handleSave() {
  try {
    // work
  } catch (error) {
    this.logger.error('Save failed').setExceptionDetails(error);
  } finally {
    await this.logger.saveLog();
  }
}
```

If you don't await it, the save still happens - but the network round-trip may not complete before your component tears down.

## Reuse one logger per component

`getLogger()` returns a scoped logger instance. Call it once as a class field and reuse across handlers - do not call it on every log statement.

```js
// Good
export default class PaymentPanel extends LightningElement {
  logger = getLogger();
  // ...
}

// Wrong - creates a new scoped instance per call
handleClick() {
  getLogger().info('Clicked');
  getLogger().saveLog();
}
```

Each `getLogger()` scope has its own buffer. Creating one per call fragments buffered entries across multiple `saveLog()` calls and creates unnecessary `Log__c` records.

## Testing

For jest tests, mock the `c/logger` module:

```js
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
```

Assert on the arguments passed to logger methods (`toHaveBeenCalledWith(...)`), not just that they were called. `toHaveBeenCalled()` alone lets regressions slip through where the message text is dropped or garbled. See [Testing your instrumentation](/NebulaLogger/logging-guide/testing/) for the full pattern.

## Where next

- [Aura](/NebulaLogger/logging-guide/aura/) - the equivalent for Aura components.
- [Testing your instrumentation](/NebulaLogger/logging-guide/testing/) - jest mocking patterns.
- [`logger` LWC reference](/NebulaLogger/reference/lwc/logger/) - the exported API.
- [`logEntryBuilder` LWC reference](/NebulaLogger/reference/lwc/logentrybuilder/) - the builder returned by level methods.
