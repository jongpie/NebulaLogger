---
title: Aura
description: Logging from Aura components using the shipped c:logger component.
---

Nebula Logger's Aura support is an LWC wrapped in an Aura component. Embed `<c:logger>` in your markup, then access it via `component.find('logger')`.

## Basic usage

Component markup:

```html
<aura:component>
  <c:logger aura:id="logger" />
</aura:component>
```

Controller:

```javascript
({
  handleRender: function (component) {
    const logger = component.find('logger');
    logger.info('Aura component initialized');
    logger.saveLog();
  },

  logButtonClick: function (component, event) {
    const logger = component.find('logger');
    logger.info('Save button clicked').addTag('user-action');
    logger.saveLog();
  }
});
```

## Level methods and builder chaining

The API mirrors the LWC and Apex loggers. Every level method returns a builder.

```javascript
logger.error('Critical failure').setRecord(recordId);
logger.warn('Recoverable issue').addTag('recoverable');
logger.info('Business milestone');
logger.debug('Debug detail');
logger.fine('Verbose detail');
logger.finer('More verbose detail');
logger.finest('Most verbose detail');
logger.saveLog();
```

## Don't call from doInit

The `<c:logger>` component is an LWC underneath, and LWC child methods aren't yet available when Aura's `doInit` fires. Two options:

- Move the initial logging to `handleRender` (fires after the child renders).
- Wrap the `doInit` logging in a `setTimeout(..., 0)` so it runs after the render cycle.

```javascript
({
  doInit: function (component) {
    // Defer to next tick so the c:logger child is ready
    setTimeout(function () {
      const logger = component.find('logger');
      logger.info('Aura component ready');
      logger.saveLog();
    }, 0);
  }
});
```

`handleRender` is cleaner when it fits your component's lifecycle.

## Where next

- [Lightning Web Components](/NebulaLogger/logging-guide/lwc/) - the native LWC path (preferred for new development).
- [Testing your instrumentation](/NebulaLogger/logging-guide/testing/) - jest patterns.
