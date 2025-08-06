# Architecture Overview

Nebula Logger is built on Salesforce's native platform capabilities, using an event-driven architecture for scalability and reliability.

## High-Level Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Log Sources   │    │  Platform Event  │    │   Data Storage  │
│                 │    │                  │    │                 │
│ • Apex         │───▶│ LogEntryEvent__e │───▶│ • Log__c        │
│ • Lightning    │    │                  │    │ • LogEntry__c   │
│ • Flow         │    │                  │    │ • LoggerTag__c  │
│ • OmniStudio   │    │                  │    │ • LogEntryTag__c│
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Core Components

### 1. Log Sources

Nebula Logger supports logging from multiple Salesforce technologies:

- **Apex**: Classes, triggers, and anonymous scripts
- **Lightning Components**: LWC and Aura components
- **Flow**: Any Flow type that supports invocable actions
- **OmniStudio**: Omniscripts and integration procedures

### 2. Platform Events

The `LogEntryEvent__e` platform event is the central messaging hub:

- **Asynchronous**: Events are processed asynchronously
- **Scalable**: Handles high-volume logging without blocking
- **Reliable**: Built-in retry and error handling
- **Flexible**: Supports custom fields and extensions

### 3. Data Objects

Five custom objects store the logging data:

#### Log__c
- Represents a logging transaction
- Contains transaction-level metadata
- Links to related LogEntry__c records

#### LogEntry__c
- Individual log entries
- Contains message, level, and context
- Links to Log__c and optional LoggerScenario__c

#### LoggerScenario__c
- Represents business scenarios
- Used for grouping and filtering logs
- Optional normalization of scenario data

#### LoggerTag__c
- Represents tags/labels
- Used for organizing and filtering logs

#### LogEntryTag__c
- Junction object linking LogEntry__c to LoggerTag__c
- Enables many-to-many relationships

## Data Flow

### 1. Log Creation
```apex
Logger.info('Hello, world!');
Logger.saveLog();
```

### 2. Event Publishing
- LogEntryEvent__e records are created
- Events are published to the platform event bus
- Processing continues immediately (non-blocking)

### 3. Event Processing
- Platform event triggers process the events
- Data is transformed and validated
- Related records are created/updated

### 4. Data Storage
- Log__c and LogEntry__c records are created
- Tags and scenarios are processed
- Data masking is applied

## Save Methods

Nebula Logger supports multiple save methods for different use cases:

### EVENT_BUS (Default)
- Uses platform events
- Asynchronous processing
- Best for most use cases

### QUEUEABLE
- Uses queueable jobs
- Asynchronous processing
- Good for high-volume scenarios

### REST
- Uses REST API callouts
- Synchronous processing
- Useful when other callouts are involved

### SYNCHRONOUS_DML
- Direct DML operations
- Synchronous processing
- Use with caution (affects transaction)

## Plugin Framework

The plugin framework allows extending Nebula Logger functionality:

### Plugin Types
- **Apex Plugins**: Custom Apex classes
- **Flow Plugins**: Auto-launched flows

### Plugin Hooks
- BEFORE_INSERT, BEFORE_UPDATE
- AFTER_INSERT, AFTER_UPDATE
- BEFORE_DELETE, AFTER_DELETE

### Plugin Configuration
- LoggerPlugin__mdt: Plugin metadata
- LoggerParameter__mdt: Plugin parameters

## Security Model

### Object-Level Security
- Standard Salesforce object permissions
- Profile and permission set controls

### Record-Level Security
- Sharing rules and ownership
- Field-level security

### Data Masking
- Automatic masking of sensitive data
- Configurable masking rules
- Support for multiple masking types

## Performance Considerations

### Event-Driven Design
- Non-blocking log creation
- Asynchronous processing
- Scalable to high volumes

### Caching
- Settings cached per transaction
- Metadata cached at startup
- Efficient memory usage

### Batch Processing
- Support for large data volumes
- Configurable batch sizes
- Automatic cleanup processes

## Integration Points

### External Systems
- Platform events can be consumed by external systems
- REST API for external access
- Streaming API for real-time monitoring

### Salesforce Features
- Lightning components for UI
- Flow for automation
- Reports and dashboards
- Chatter integration

## Monitoring and Observability

### Real-Time Monitoring
- Log Entry Event Stream
- Live event processing
- Real-time dashboards

### Historical Analysis
- Log retention policies
- Batch processing for cleanup
- Archive to Big Objects (plugin)

### Alerting
- Error monitoring
- Performance metrics
- Custom alerting (plugins)

## Related Topics

- [Data Model](data-model.md)
- [Configuration](configuration.md)
- [Plugin Framework](features/plugins.md)
- [Performance](administration/performance.md)
