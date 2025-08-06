# Nebula Logger for Salesforce

[![Build](https://github.com/jongpie/NebulaLogger/actions/workflows/build.yml/badge.svg)](https://github.com/jongpie/NebulaLogger/actions/workflows/build.yml)
[![codecov](https://codecov.io/gh/jongpie/NebulaLogger/branch/main/graph/badge.svg?token=1DJPDRM3N4)](https://codecov.io/gh/jongpie/NebulaLogger)

The most robust observability solution for Salesforce experts. Built 100% natively on the platform, and designed to work seamlessly with Apex, Lightning Components, Flow, OmniStudio, and integrations.

## Quick Start

### Install Nebula Logger

**Unlocked Package (Recommended)** - v4.16.4
```bash
sf package install --wait 20 --security-type AdminsOnly --package 04tKe0000011MyWIAU
```

[![Install Unlocked Package in a Sandbox](./images/btn-install-unlocked-package-sandbox.png)](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tKe0000011MyWIAU)
[![Install Unlocked Package in Production](./images/btn-install-unlocked-package-production.png)](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tKe0000011MyWIAU)

**Managed Package** - v4.16.0
```bash
sf package install --wait 30 --security-type AdminsOnly --package 04t5Y0000015pGtQAI
```

[![Install Managed Package in a Sandbox](./images/btn-install-managed-package-sandbox.png)](https://test.salesforce.com/packaging/installPackage.apexp?mgd=true&p0=04t5Y0000015pGtQAI)
[![Install Managed Package in Production](./images/btn-install-managed-package-production.png)](https://login.salesforce.com/packaging/installPackage.apexp?mgd=true&p0=04t5Y0000015pGtQAI)

### Basic Usage

**Apex**
```apex
Logger.info('Hello, world!');
Logger.error('Something went wrong', someException);
Logger.saveLog();
```

**Lightning Web Components**
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

**Flow**
Use the "Add Log Entry" invocable action in your flows to log messages, records, or record collections.

**OmniStudio**
Use the `CallableLogger` class as a remote action in your omniscripts and integration procedures.

## Key Features

### ��� Unified Logging Across Platforms

Log from anywhere in your Salesforce org:

- **Apex**: Classes, triggers, and anonymous scripts
- **Lightning Components**: LWC and Aura components  
- **Flow & Process Builder**: Any Flow type that supports invocable actions
- **OmniStudio**: Omniscripts and integration procedures

### ���️ Event-Driven Architecture

Built on Salesforce Platform Events for scalability and reliability:

```
┌─────────────┐    ┌──────────────────┐    ┌─────────────┐
│   Apex      │    │ LogEntryEvent__e │    │   Log__c    │
│ Lightning   │───▶│   Platform Event │───▶│ LogEntry__c │
│   Flow      │    │                  │    │             │
│ OmniStudio  │    └──────────────────┘    └─────────────┘
└─────────────┘
```

### ��� Real-Time Monitoring

View log events as they happen with the Log Entry Event Stream:

![Log Entry Event Stream](./images/log-entry-event-stream.png)

### ���️ Scenario-Based Logging

Group and filter logs by business scenarios:

```apex
Logger.setScenario('User Registration');
Logger.info('Registration process started');
// ... your business logic ...
Logger.info('Registration process completed');
Logger.saveLog();
```

### ��� Data Masking

Automatically mask sensitive data using configurable rules:

![Data Masking Configuration](./images/tag-rule-example.png)

### ���️ Tagging System

Organize logs with dynamic tags:

```apex
Logger.error('Critical error').addTag('critical').addTag('urgent');
Logger.info('User action').addTags(new List<String>{'user-action', 'important'});
```

### ��� Lightning Console

Manage logs with the dedicated Logger Console app:

![Logger Console App](./images/logger-console-app.png)

### ��� Related Log Entries

View related logs on any record page:

![Related Log Entries](./images/relate-log-entries-lwc.png)

### ��� Flow Integration

Easily add logging to your flows:

![Flow Logger Actions](./images/flow-logger-actions.png)

### ���️ Log Management

Mass delete and retention management:

![Log Mass Delete](./images/log-mass-delete-selection.png)

## Package Comparison

| Feature | Unlocked Package | Managed Package |
|---------|------------------|-----------------|
| **Namespace** | None | `Nebula` |
| **Release Cycle** | Faster (patch versions) | Slower (minor versions) |
| **Plugin Framework** | ✅ Available | ❌ Not Available |
| **Public Methods** | Subject to change | Only `global` methods |
| **Debug Statements** | Automatic | Manual required |
| **Custom Fields** | ✅ Full support | ✅ Full support |
| **Data Masking** | ✅ Available | ✅ Available |
| **Tagging System** | ✅ Available | ✅ Available |
| **Scenario Logging** | ✅ Available | ✅ Available |

## Advanced Features

### Batch & Queueable Support

Relate logs across asynchronous jobs:

```apex
public class MyBatchable implements Database.Batchable<SObject> {
    private String parentTransactionId;
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        this.parentTransactionId = Logger.getTransactionId();
        Logger.info('Batch started');
        Logger.saveLog();
        return Database.getQueryLocator('SELECT Id FROM Account');
    }
    
    public void execute(Database.BatchableContext context, List<Account> scope) {
        Logger.setParentLogTransactionId(this.parentTransactionId);
        Logger.info('Processing ' + scope.size() + ' accounts');
        Logger.saveLog();
    }
}
```

### Custom Fields

Extend the data model with your own fields:

```apex
// Set custom field for all entries in transaction
Logger.setField(LogEntryEvent__e.CustomField__c, 'transaction value');

// Set custom field for specific entry
Logger.info('Specific entry').setField(LogEntryEvent__e.CustomField__c, 'specific value');
```

### ISV Integration

Use `CallableLogger` for optional dependencies:

```apex
// Check if Nebula Logger is available
Type nebulaLoggerType = Type.forName('Nebula', 'CallableLogger') ?? Type.forName('CallableLogger');
Callable nebulaLoggerInstance = (Callable) nebulaLoggerType?.newInstance();

if (nebulaLoggerInstance != null) {
    // Use Nebula Logger when available
    Map<String, Object> input = new Map<String, Object>{
        'loggingLevel' => System.LoggingLevel.INFO,
        'message' => 'Hello from ISV package'
    };
    nebulaLoggerInstance.call('newEntry', input);
    nebulaLoggerInstance.call('saveLog', null);
}
```

## Documentation

��� **Complete documentation is available in the [Wiki](./wiki/)**

- [Installation Guide](./wiki/installation.md)
- [Quick Start Guide](./wiki/quick-start.md)
- [Logging in Apex](./wiki/logging/apex.md)
- [Scenario-Based Logging](./wiki/features/scenarios.md)
- [Configuration Guide](./wiki/configuration.md)
- [Architecture Overview](./wiki/architecture.md)

## Support & Community

- ��� [Documentation Wiki](./wiki/)
- ��� [Report Issues](https://github.com/jongpie/NebulaLogger/issues)
- ��� [Feature Requests](https://github.com/jongpie/NebulaLogger/issues)
- ��� [Contact](mailto:jongpie@gmail.com)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Built with ❤️ for the Salesforce community**
