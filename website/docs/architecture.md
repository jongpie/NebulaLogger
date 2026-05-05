# Architecture Guide

Deep dive into Nebula Logger's architecture, design patterns, and technical implementation.

## Table of Contents

- [High-Level Architecture](#high-level-architecture)
- [Data Model](#data-model)
- [Event-Driven Design](#event-driven-design)
- [Processing Pipeline](#processing-pipeline)
- [Configuration System](#configuration-system)
- [Plugin Framework](#plugin-framework)
- [Save Methods](#save-methods)
- [Design Patterns](#design-patterns)
- [Performance Architecture](#performance-architecture)

## High-Level Architecture

### Component Layers

```
┌──────────────────────────────────────────────────────────────────┐
│  Application Layer (Your Code)                                   │
│  Apex, LWC, Aura, Flow, OmniStudio                              │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│  Logger Engine Layer                                             │
│  - Logger.cls (static methods)                                   │
│  - LogEntryEventBuilder.cls (fluent API)                        │
│  - ComponentLogger.cls (LWC/Aura)                               │
│  - FlowLogger.cls (Flow invocable)                              │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│  Event Bus Layer                                                 │
│  - LogEntryEvent__e (Platform Event)                            │
│  - EventBus.publish() (asynchronous)                            │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│  Event Processing Layer                                          │
│  - LogEntryEventHandler.cls (trigger handler)                   │
│  - LogHandler.cls (Log__c trigger)                              │
│  - LogEntryHandler.cls (LogEntry__c trigger)                    │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│  Data Layer                                                      │
│  - Log__c (transaction container)                                │
│  - LogEntry__c (individual entries)                             │
│  - LoggerTag__c, LogEntryTag__c (tagging)                       │
│  - LoggerScenario__c (business context)                         │
└──────────────────────────────────────────────────────────────────┘
```

### Key Design Principles

1. **Asynchronous by Default** - Don't impact user transactions
2. **Event-Driven** - Decouple logging from processing
3. **Extensible** - Plugin framework for customization
4. **Configurable** - Metadata-driven behavior
5. **Performance-First** - Minimize governor limit impact
6. **Multi-Platform** - Support all Salesforce development contexts

## Data Model

### Core Objects

```
┌─────────────────────────────────────────────────────────────────┐
│                         LogEntryEvent__e                         │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ Platform Event (60+ fields)                               │  │
│  │ - Message__c (text 131,072)                               │  │
│  │ - LoggingLevel__c (picklist)                              │  │
│  │ - TransactionId__c (unique per transaction)               │  │
│  │ - Timestamp__c (datetime)                                 │  │
│  │ - OriginLocation__c (class.method:line)                   │  │
│  │ - ExceptionType__c, ExceptionMessage__c, StackTrace__c    │  │
│  │ - RecordId__c, RecordJson__c (record context)            │  │
│  │ - Tags__c (comma-separated)                               │  │
│  │ - EntryScenario__c, TransactionScenario__c               │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────┬───────────────────────────────────┘
                              │ (triggers after publish)
                              ▼
         ┌────────────────────────────────────────┐
         │           LogEntryEventHandler         │
         │  - Creates Log__c (1 per transaction)  │
         │  - Creates LogEntry__c (many)          │
         │  - Applies tagging rules                │
         │  - Executes plugins                     │
         └────────────┬───────────────────────────┘
                      │
         ┌────────────┴────────────┐
         ▼                         ▼
┌─────────────────┐       ┌─────────────────┐
│    Log__c       │       │  LogEntry__c    │
│ ┌─────────────┐ │       │ ┌─────────────┐ │
│ │ Transaction │ │       │ │ Individual  │ │
│ │ Container   │ │◀──────│ │ Log Entry   │ │
│ │             │ │ 1:M   │ │             │ │
│ │ - Owner     │ │       │ │ - Message   │ │
│ │ - Scenario  │ │       │ │ - Level     │ │
│ │ - StartTime │ │       │ │ - Timestamp │ │
│ │ - EndTime   │ │       │ │ - Origin    │ │
│ └─────────────┘ │       │ │ - Exception │ │
└─────────────────┘       │ │ - RecordId  │ │
                          │ └─────────────┘ │
                          └────────┬────────┘
                                   │ M:M
                                   ▼
                          ┌────────────────┐
                          │ LogEntryTag__c │
                          │  (Junction)    │
                          └────────┬───────┘
                                   │
                                   ▼
                          ┌────────────────┐
                          │ LoggerTag__c   │
                          │ - Name (unique)│
                          │ - Description  │
                          └────────────────┘
```

### Supporting Objects

**LoggerScenario__c** - Business process tracking
- Name: Scenario name (unique)
- UniqueId__c: External ID
- Related Lists: Logs, LogEntries

**LoggerSettings__c** - Hierarchy custom settings
- IsEnabled__c: Master on/off switch
- LoggingLevel__c: Minimum level
- DefaultSaveMethod__c: How to persist
- IsDataMaskingEnabled__c: PII protection

**Custom Metadata Types:**
- LoggerParameter__mdt: Feature flags
- LogEntryTagRule__mdt: Auto-tagging rules
- LoggerScenarioRule__mdt: Scenario-based behavior
- LogEntryDataMaskRule__mdt: Data masking patterns
- LoggerPlugin__mdt: Plugin registration

## Event-Driven Design

### Why Platform Events?

Traditional synchronous logging impacts performance:

```apex
// ❌ Synchronous: Adds to transaction time
Logger.info('Message');
Logger.saveLog();  // DML in main transaction
// User waits for insert to complete
```

Platform events enable asynchronous processing:

```apex
// ✅ Asynchronous: No transaction impact
Logger.info('Message');
Logger.saveLog();  // Publishes event, returns immediately
// Event processing happens separately
```

### Event Flow

```
┌──────────────────────────────────────────────────────────┐
│  User Transaction (Apex, Flow, LWC)                      │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Logger.info('Message 1');                          │  │
│  │ Logger.debug('Message 2');                         │  │
│  │ Logger.error('Message 3');                         │  │
│  │ Logger.saveLog(); ──────────┐                      │  │
│  └─────────────────────────────│──────────────────────┘  │
│                                 │                         │
│  Transaction completes ◄────────┘                        │
└──────────────────────────────────────────────────────────┘
                                  │
                                  │ Publishes events
                                  │
┌─────────────────────────────────▼─────────────────────────┐
│  Platform Event Bus                                       │
│  - Reliable delivery                                      │
│  - At-least-once semantics                               │
│  - Retry on failure                                       │
└─────────────────────────────────┬─────────────────────────┘
                                  │
                                  │ Triggers after publish
                                  │
┌─────────────────────────────────▼─────────────────────────┐
│  Event Handler (Separate Transaction)                     │
│  - No governor limits from user transaction               │
│  - Processes all events in batch                          │
│  - Creates Log__c and LogEntry__c records                │
│  - Runs plugins                                           │
└───────────────────────────────────────────────────────────┘
```

### Event Processing Guarantees

Platform events provide:
- **At-least-once delivery** - Events may be delivered multiple times
- **Replay buffer** - 24-hour event replay window
- **Idempotency** - TransactionId prevents duplicate Log__c records
- **Ordering** - Events processed in publish order (per trigger execution)

## Processing Pipeline

### LogEntryEventHandler Pipeline

```apex
trigger LogEntryEventTrigger on LogEntryEvent__e (after insert) {
    new LogEntryEventHandler(Trigger.new).execute();
}
```

**Handler execution flow:**

```
┌────────────────────────────────────────────────────────────────┐
│ 1. Initialize                                                  │
│    - Collect all LogEntryEvent__e records                     │
│    - Group by TransactionId__c                                │
└─────────────────────────────────┬──────────────────────────────┘
                                  │
┌─────────────────────────────────▼──────────────────────────────┐
│ 2. Upsert LoggerScenarios                                      │
│    - Extract unique scenarios from events                      │
│    - Upsert LoggerScenario__c records                         │
└─────────────────────────────────┬──────────────────────────────┘
                                  │
┌─────────────────────────────────▼──────────────────────────────┐
│ 3. Upsert Logs                                                 │
│    - One Log__c per TransactionId__c                          │
│    - Set TransactionScenario__c (first scenario)              │
│    - Aggregate metadata (user, org, API version)              │
└─────────────────────────────────┬──────────────────────────────┘
                                  │
┌─────────────────────────────────▼──────────────────────────────┐
│ 4. Insert LogEntries                                           │
│    - One LogEntry__c per LogEntryEvent__e                     │
│    - Link to Log__c via TransactionId__c                      │
│    - Set EntryScenario__c                                     │
│    - Apply data masking                                        │
└─────────────────────────────────┬──────────────────────────────┘
                                  │
┌─────────────────────────────────▼──────────────────────────────┐
│ 5. Apply Tagging                                               │
│    - Execute LogEntryTagRule__mdt rules                       │
│    - Extract tags from LogEntryEvent__e.Tags__c               │
│    - Upsert LoggerTag__c records                              │
│    - Insert LogEntryTag__c junction records                   │
└─────────────────────────────────┬──────────────────────────────┘
                                  │
┌─────────────────────────────────▼──────────────────────────────┐
│ 6. Execute Plugins                                             │
│    - Query LoggerPlugin__mdt (IsEnabled = true)               │
│    - Instantiate plugin classes                               │
│    - Execute plugin logic (BEFORE_INSERT, AFTER_INSERT, etc.) │
└─────────────────────────────────┬──────────────────────────────┘
                                  │
┌─────────────────────────────────▼──────────────────────────────┐
│ 7. Update Rollup Fields                                        │
│    - Log__c.TotalLogEntries__c                                │
│    - LoggerTag__c.TotalLogEntries__c                          │
└────────────────────────────────────────────────────────────────┘
```

## Configuration System

### Hierarchy Settings

```
Organization Default (LoggerSettings__c)
    ↓
Profile Default (LoggerSettings__c)
    ↓
User Default (LoggerSettings__c)
```

**Precedence:** User > Profile > Org

**Usage:**
```apex
LoggerSettings__c settings = Logger.getUserSettings();
// Automatically resolves hierarchy
```

### Custom Metadata Parameters

**LoggerParameter__mdt** controls behavior:

```
ENABLE_TAGGING = true/false
NORMALIZE_SCENARIO_DATA = true/false
REQUIRE_SCENARIO_USAGE = true/false
USE_FIRST_SCENARIO_FOR_TRANSACTION = true/false
STORAGE_LOCATION = CUSTOM_OBJECTS/BIG_OBJECTS
```

**Code access:**
```apex
if (LoggerParameter.ENABLE_TAGGING) {
    // Tagging logic
}
```

### Scenario Rules

**LoggerScenarioRule__mdt** changes behavior per scenario:

```apex
// When scenario is set, rules auto-apply
Logger.setScenario('PII Processing');
// LoggerScenarioRule__mdt automatically:
// - Enables data masking
// - Enables anonymous mode
// - Changes logging level
```

## Plugin Framework

### Plugin Interface

```apex
public interface Triggerable {
    void execute(
        TriggerOperation triggerOperationType,
        List<SObject> triggerNew,
        Map<Id, SObject> triggerNewMap,
        List<SObject> triggerOld,
        Map<Id, SObject> triggerOldMap
    );
}
```

### Plugin Registration

**LoggerPlugin__mdt:**
- DeveloperName: UniquePluginName
- SObjectType__c: Log__c or LogEntry__c
- PluginApiName__c: MyPlugin.MyClass
- TriggerOperation__c: BEFORE_INSERT, AFTER_INSERT, etc.
- IsEnabled__c: true/false

### Plugin Execution

```apex
// In LogHandler or LogEntryHandler
for (LoggerPlugin__mdt pluginConfig : getEnabledPlugins()) {
    Type pluginType = Type.forName(pluginConfig.PluginApiName__c);
    LoggerPlugin.Triggerable plugin = 
        (LoggerPlugin.Triggerable) pluginType.newInstance();
    
    plugin.execute(
        TriggerOperation.AFTER_INSERT,
        Trigger.new,
        Trigger.newMap,
        null,
        null
    );
}
```

### Built-In Plugins

- **Slack Integration** - Post logs to Slack
- **Big Object Archiving** - Archive old logs
- **Async Failure Additions** - Capture async context
- **Log Retention Rules** - Auto-delete old logs
- **Alerting System** - Send alerts on patterns

## Save Methods

### EVENT_BUS (Default)

```apex
Logger.saveLog();  // Uses EVENT_BUS
```

**Flow:**
1. Publishes LogEntryEvent__e
2. Returns immediately
3. Event handler processes asynchronously

**Pros:**
- No transaction time impact
- Scalable (event-driven)
- Reliable (platform events)

**Cons:**
- Not immediate (eventual consistency)
- Cannot query logs in same transaction

### QUEUEABLE

```apex
Logger.saveLog(Logger.SaveMethod.QUEUEABLE);
```

**Flow:**
1. Enqueues a queueable job
2. Job creates Log__c and LogEntry__c directly
3. No platform events used

**Pros:**
- Asynchronous (doesn't block user)
- Can chain queueable jobs

**Cons:**
- Subject to queueable limits
- No event replay buffer

### SYNCHRONOUS_DML

```apex
Logger.saveLog(Logger.SaveMethod.SYNCHRONOUS_DML);
```

**Flow:**
1. Directly inserts Log__c and LogEntry__c
2. Happens in current transaction
3. User waits for DML to complete

**Pros:**
- Immediate visibility
- Can query in same transaction
- Useful for testing

**Cons:**
- **Impacts performance**
- **Uses DML governor limits**
- **Not recommended for production**

### REST

```apex
Logger.saveLog(Logger.SaveMethod.REST);
```

**Flow:**
1. Makes HTTP callout to Salesforce REST API
2. API creates records in separate transaction

**Pros:**
- Doesn't use DML limits
- Asynchronous

**Cons:**
- Requires Remote Site Settings
- Uses callout limits
- Complex error handling

## Design Patterns

### Singleton Pattern

```apex
public class Logger {
    private static Logger instance;
    
    private Logger() {
        // Private constructor
    }
    
    public static Logger getInstance() {
        if (instance == null) {
            instance = new Logger();
        }
        return instance;
    }
}
```

### Builder Pattern

```apex
Logger.info('Message')
    .addTag('tag1')
    .addTag('tag2')
    .setRecord(record);
// Each method returns LogEntryEventBuilder
```

**Implementation:**
```apex
public class LogEntryEventBuilder {
    private LogEntryEvent__e logEntryEvent;
    
    public LogEntryEventBuilder addTag(String tag) {
        // Add tag logic
        return this;  // Return self for chaining
    }
    
    public LogEntryEvent__e getLogEntryEvent() {
        return this.logEntryEvent;
    }
}
```

### Selector Pattern

```apex
public class LoggerEngineDataSelector {
    public List<LoggerScenario__c> getScenarios(Set<String> names) {
        return [
            SELECT Id, Name, UniqueId__c
            FROM LoggerScenario__c
            WHERE Name IN :names
        ];
    }
}
```

Centralizes SOQL queries for:
- Testability (mock selectors)
- Maintainability (queries in one place)
- Reusability (shared queries)

### Trigger Handler Pattern

```apex
public abstract class TriggerHandler {
    public void execute() {
        if (Trigger.isBefore && Trigger.isInsert) {
            beforeInsert();
        }
        // ... other trigger contexts
    }
    
    protected virtual void beforeInsert() {}
    protected virtual void afterInsert() {}
    // ... other methods
}

public class LogEntryEventHandler extends TriggerHandler {
    protected override void afterInsert() {
        // Process events
    }
}
```

## Performance Architecture

### Governor Limit Strategy

**Heap Size:**
- Use streaming for large data
- Clear collections after processing
- Don't store entire record collections in memory

**SOQL Queries:**
- Bulkify all operations
- Use selective queries (WHERE clauses)
- Cache metadata queries

**DML Statements:**
- Batch all DML operations
- Use Database.insert(list) not insert individually
- Leverage platform events for async

**CPU Time:**
- Minimize regex operations
- Cache expensive calculations
- Use platform event processing for heavy work

### Bulk Processing

All Logger operations are bulkified:

```apex
// Single log entry
Logger.info('Message 1');
Logger.info('Message 2');
Logger.info('Message 3');
Logger.saveLog();
// Publishes 3 events in one EventBus.publish() call

// Event handler processes in bulk
for (LogEntryEvent__e event : Trigger.new) {
    // Accumulate all events
}
// One insert for all Log__c
// One insert for all LogEntry__c
// One insert for all LogEntryTag__c
```

### Caching Strategy

```apex
// Cache metadata
private static Map<String, LoggerScenarioRule__mdt> scenarioRuleCache;

// Cache expensive queries
private static LoggerSettings__c userSettingsCache;

// Cache platform cache for cross-transaction data
Cache.Org.put('LoggerScenarios', scenarios, 3600);
```

## Next Steps

- [Performance Guide](performance.md) - Optimization strategies
- [Plugin Development](plugin-development.md) - Build custom plugins
- [Developer Guide](developer-guide.md) - Development patterns
- [API Reference](api-reference.md) - Complete API docs
