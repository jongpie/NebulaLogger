# Nebula Logger Overview

## What is Nebula Logger?

Nebula Logger is a comprehensive, enterprise-grade observability and logging solution built entirely on the Salesforce platform. It provides a robust alternative to `System.debug()` with powerful features for capturing, storing, managing, and analyzing logs across all Salesforce development contexts.

## Why Use Nebula Logger?

### The Problem with System.debug()

Traditional `System.debug()` statements have significant limitations:

- **Ephemeral** - Logs disappear after 24 hours
- **Limited context** - No structured data or metadata
- **Difficult to search** - No querying or filtering capabilities
- **No production visibility** - Debug logs must be enabled per user
- **No analytics** - Can't build dashboards or reports
- **Platform-specific** - Only works in Apex

### The Nebula Logger Solution

Nebula Logger addresses these limitations by providing:

✅ **Persistent Storage** - Logs stored as Salesforce records  
✅ **Rich Context** - Capture stack traces, record data, custom fields, and metadata  
✅ **Powerful Search** - Query logs like any Salesforce object  
✅ **Production Ready** - Always on, with configurable log levels  
✅ **Analytics & Reporting** - Build dashboards, reports, and alerts  
✅ **Multi-Platform** - Works in Apex, LWC, Aura, Flow, and OmniStudio  
✅ **Event-Driven** - Uses platform events for scalability  
✅ **Enterprise Features** - Data masking, tagging, scenarios, and plugins  

## Key Features

### 1. Multi-Platform Support

Log consistently across all Salesforce development platforms:

```apex
// Apex
Logger.info('Processing order').addTag('critical');
```

```javascript
// Lightning Web Component
this.logger.error('Payment failed').setExceptionDetails(error);
```

```
// Flow (via invocable actions)
Add Log Entry: "User registration completed"
```

### 2. Seven Logging Levels

Fine-grained control over log verbosity:

- **ERROR** - Critical failures requiring immediate attention
- **WARN** - Potential issues or degraded functionality
- **INFO** - Important business events
- **DEBUG** - Detailed diagnostic information
- **FINE** - Trace-level details
- **FINER** - More granular tracing
- **FINEST** - Most verbose tracing

### 3. Event-Driven Architecture

Built on Salesforce Platform Events for:

- **Scalability** - Handle high-volume logging without governor limits
- **Asynchronous processing** - Don't slow down user transactions
- **Reliability** - Platform events ensure delivery
- **Flexibility** - Multiple save methods (event bus, queueable, REST, synchronous)

### 4. Smart Organization

**Tags** - Apply multiple labels to log entries for filtering:
```apex
Logger.debug('Cache miss').addTag('performance').addTag('redis');
```

**Scenarios** - Track business processes and modules:
```apex
Logger.setScenario('Order Processing');
Logger.info('Validating inventory'); // Tagged with scenario
```

### 5. Data Protection

**Built-in data masking** for sensitive information:
- Credit card numbers
- Social Security Numbers
- Custom regex patterns
- Field-level masking rules

### 6. Extensibility

**Plugin Framework** - Extend Logger with custom functionality:
- Slack notifications
- Big Object archiving
- Custom alerting
- Integration with external systems

**Custom Fields** - Add your own fields to logs without modifying core code

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│  Your Code (Apex, LWC, Aura, Flow, OmniStudio)         │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Logger Engine (Logger.cls, LogEntryEventBuilder)      │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Platform Event (LogEntryEvent__e)                      │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Event Handler (LogEntryEventHandler)                   │
│  - Creates Log__c records                               │
│  - Creates LogEntry__c records                          │
│  - Applies tags, scenarios, plugins                     │
└─────────────────────────────────────────────────────────┘
```

## Data Model

### Core Objects

- **LogEntryEvent__e** - Platform event for publishing log entries (60+ fields)
- **Log__c** - Top-level log container (one per transaction)
- **LogEntry__c** - Individual log entries (many per Log)
- **LoggerTag__c** - Tag definitions
- **LogEntryTag__c** - Junction object (LogEntry ↔ Tag)
- **LoggerScenario__c** - Scenario/process definitions

### Configuration Objects

- **LoggerSettings__c** - Hierarchy custom settings (org/profile/user)
- **LoggerParameter__mdt** - Feature flags and global config
- **LogEntryTagRule__mdt** - Rule-based auto-tagging
- **LoggerScenarioRule__mdt** - Scenario-based behavior rules
- **LoggerPlugin__mdt** - Plugin registration
- **LogEntryDataMaskRule__mdt** - Data masking patterns

## Package Options

### Unlocked Package (Recommended)

- **No namespace** - Clean code without prefixes
- **Flexible** - Modify source code as needed
- **Modern** - Salesforce's recommended packaging format
- **Installation** - Via Salesforce CLI or package link

### Managed Package

- **Namespace** - `Nebula` namespace prefix
- **AppExchange** - Available on Salesforce AppExchange
- **Upgradeable** - Automatic upgrade path
- **Restricted** - Some features not available (e.g., Chatter Topics tagging)

## Use Cases

### Development & Debugging

Track complex execution flows during development:
```apex
Logger.setScenario('Opportunity Trigger');
Logger.debug('Before update, stage: ' + opp.StageName);
// ... business logic ...
Logger.debug('After update, stage: ' + opp.StageName);
Logger.saveLog();
```

### Production Monitoring

Monitor live systems without debug logs:
```apex
try {
    callExternalAPI();
} catch (Exception e) {
    Logger.error('API integration failed')
        .setExceptionDetails(e)
        .addTag('integration')
        .addTag('critical');
    Logger.saveLog();
}
```

### Troubleshooting Customer Issues

Capture context for support teams:
```apex
Logger.info('User performed action')
    .setField(Log__c.RelatedRecordId__c, accountId)
    .addTag('customer-' + accountId);
```

### Compliance & Auditing

Track important business events:
```apex
Logger.info('PII accessed')
    .setField(LogEntry__c.RecordId__c, contactId)
    .addTag('compliance')
    .addTag('pii-access');
```

## Performance Considerations

- **Async by default** - Logging doesn't impact transaction time
- **Batched operations** - Events processed in bulk
- **Configurable levels** - Log only what you need
- **Selective saving** - Choose when to persist logs
- **Governor-safe** - Designed to stay within Salesforce limits

## Getting Started

Ready to start using Nebula Logger? Continue to:

1. [Installation Guide](installation.md) - Install the package
2. [Quick Start Guide](quick-start.md) - Log your first entry
3. [Developer Guide](developer-guide.md) - Learn best practices
4. [Configuration Guide](configuration-reference.md) - Configure for your org

## License

Nebula Logger is open source under the MIT License.

## Community & Support

- **GitHub Repository** - [jongpie/NebulaLogger](https://github.com/jongpie/NebulaLogger)
- **Issues & Bugs** - GitHub Issues
- **Documentation** - GitHub Wiki & this documentation
- **Contributing** - Pull requests welcome!
