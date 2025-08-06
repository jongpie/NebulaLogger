# Quick Start Guide

Get up and running with Nebula Logger in minutes.

## Basic Apex Logging

```apex
// Simple logging
Logger.info('Hello, world!');
Logger.error('Something went wrong', someException);
Logger.saveLog();
```

## Lightning Web Components

```javascript
import { getLogger } from 'c/logger';

export default class MyComponent extends LightningElement {
  logger = getLogger();

  connectedCallback() {
    this.logger.info('Component initialized');
    this.logger.saveLog();
  }
}
```

## Flow Integration

1. Add the "Add Log Entry" invocable action to your flow
2. Configure the message and logging level
3. Add "Save Log" action to persist the logs

## Scenario-Based Logging

```apex
Logger.setScenario('User Registration');
Logger.info('User registration started');
// ... your business logic ...
Logger.info('User registration completed');
Logger.saveLog();
```

## Next Steps

- [Logging in Apex](logging/apex.md) - Complete Apex guide
- [Configuration](configuration.md) - Setup and configuration
- [Features](features/scenarios.md) - Advanced features
