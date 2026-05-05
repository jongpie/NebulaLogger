# Apex Developer Guide

Comprehensive guide to logging in Apex with Nebula Logger.

## Table of Contents

- [Basic Usage](#basic-usage)
- [Logging Levels](#logging-levels)
- [Adding Context](#adding-context)
- [Exception Handling](#exception-handling)
- [Tagging](#tagging)
- [Scenarios](#scenarios)
- [Advanced Features](#advanced-features)
- [Best Practices](#best-practices)
- [API Reference](#api-reference)

## Basic Usage

### Simple Logging

```apex
// Log a message
Logger.info('This is an informational message');

// Save the log
Logger.saveLog();
```

**Key points:**
- Logging is a two-step process: create entries, then save
- Multiple entries can be created before saving
- One `Log__c` record is created per transaction
- Multiple `LogEntry__c` records can belong to one `Log__c`

### Method Chaining

```apex
Logger.info('User action completed')
    .addTag('user-action')
    .addTag('audit');
Logger.saveLog();
```

Logger uses the builder pattern for fluent API calls.

## Logging Levels

Seven levels from most to least severe:

```apex
Logger.error('Critical failure');      // Level 1 - Most severe
Logger.warn('Potential issue');        // Level 2
Logger.info('Business event');         // Level 3
Logger.debug('Diagnostic info');       // Level 4
Logger.fine('Detailed trace');         // Level 5
Logger.finer('More detailed trace');   // Level 6
Logger.finest('Most verbose trace');   // Level 7 - Least severe
```

### Choosing the Right Level

| Level | When to Use | Examples |
|-------|-------------|----------|
| **ERROR** | Exceptions, failures, data loss | Payment processing failed, Integration error, Required field missing |
| **WARN** | Degraded functionality, approaching limits | API rate limit at 80%, Retry attempt 3 of 5, Deprecated method called |
| **INFO** | Important business events | Order submitted, User registered, Batch job completed |
| **DEBUG** | Diagnostic information for troubleshooting | Query returned 150 records, Cache miss, Validation passed |
| **FINE** | Entry/exit tracing | Entering method processOrder(), Loop iteration 10 of 100 |
| **FINER** | Detailed variable inspection | Variable state: { id: 123, status: 'active' } |
| **FINEST** | Most granular tracing | Every step in complex algorithm |

### Configuring Log Levels

Set minimum level in `LoggerSettings__c`:

```apex
LoggerSettings__c settings = LoggerSettings__c.getInstance();
settings.LoggingLevel__c = 'INFO'; // Only INFO and above are saved
upsert settings;
```

## Adding Context

### Record Context

Associate a log entry with a Salesforce record:

```apex
Account acc = [SELECT Id, Name FROM Account LIMIT 1];

Logger.info('Processing account')
    .setRecord(acc);  // Links to the Account record
Logger.saveLog();
```

The `LogEntry__c.RecordId__c` field stores the record ID.

### Record Collection

Log multiple records:

```apex
List<Contact> contacts = [SELECT Id, Name FROM Contact LIMIT 10];

Logger.info('Processing contacts')
    .setRecord(contacts);  // Stores JSON of record collection
Logger.saveLog();
```

### Custom Fields

Set custom fields on the log:

```apex
Logger.info('Custom field example')
    .setField(Log__c.CustomField__c, 'custom value')
    .setField(LogEntry__c.AnotherField__c, 123);
Logger.saveLog();
```

### Topics (String Tags in Field)

Store simple tags in a text field:

```apex
Logger.info('Tagged message')
    .addTags(new List<String>{'tag1', 'tag2', 'tag3'});
Logger.saveLog();
```

These are stored in `LogEntry__c.Tags__c` as comma-separated values.

## Exception Handling

### Basic Exception Logging

```apex
try {
    // Risky code
    Integer result = 10 / 0;
} catch (Exception e) {
    Logger.error('Operation failed')
        .setExceptionDetails(e);  // Captures exception type, message, stack trace
    Logger.saveLog();
}
```

### Exception Fields Captured

When you call `.setExceptionDetails(e)`, Logger captures:

- `ExceptionType__c` - Class name (e.g., 'System.MathException')
- `ExceptionMessage__c` - Exception message
- `ExceptionStackTrace__c` - Full stack trace
- `HasException__c` - Boolean flag for filtering

### Nested Try-Catch

```apex
Logger.setScenario('Order Processing');

try {
    validateOrder(order);
    
    try {
        processPayment(order);
        Logger.info('Payment processed successfully');
    } catch (PaymentException pe) {
        Logger.error('Payment failed')
            .setExceptionDetails(pe)
            .addTag('payment-failure')
            .addTag('requires-manual-review');
        throw pe;  // Re-throw after logging
    }
    
    fulfillOrder(order);
    
} catch (Exception e) {
    Logger.error('Order processing failed')
        .setExceptionDetails(e)
        .setRecord(order)
        .addTag('critical');
} finally {
    Logger.saveLog();  // Always save
}
```

## Tagging

Tags provide flexible categorization. See the [Tagging Guide](tagging-guide.md) for full details.

### Adding Tags

```apex
// Single tag
Logger.info('Important event').addTag('important');

// Multiple tags (method chaining)
Logger.error('Payment failed')
    .addTag('payment')
    .addTag('critical')
    .addTag('customer-impacting');

// Multiple tags (list)
List<String> tags = new List<String>{'tag1', 'tag2', 'tag3'};
Logger.debug('Tagged entry').addTags(tags);

Logger.saveLog();
```

### Tag Use Cases

```apex
// Feature tagging
Logger.debug('Cache hit').addTag('caching').addTag('performance');

// Priority tagging
Logger.error('Data loss detected').addTag('critical').addTag('p0');

// Team tagging
Logger.info('Integration event').addTag('team-integrations');

// Customer tagging
Logger.warn('Rate limit exceeded').addTag('customer-' + accountId);

// Environment tagging (less useful in Salesforce, but possible)
Logger.fine('Test execution').addTag('test-automation');
```

### Querying by Tag

```apex
// Find all entries with 'payment' tag
List<LogEntry__c> paymentLogs = [
    SELECT Id, Message__c, Timestamp__c
    FROM LogEntry__c
    WHERE Id IN (
        SELECT LogEntry__c
        FROM LogEntryTag__c
        WHERE Tag__r.Name = 'payment'
    )
];
```

## Scenarios

Scenarios track business processes. See the [Scenarios Guide](scenarios-guide.md) for full details.

### Setting a Scenario

```apex
// Set scenario for the transaction
Logger.setScenario('Order Processing');

Logger.info('Validating order');
// ... business logic ...
Logger.info('Order validated');

Logger.saveLog();
// Log__c.TransactionScenario__c = 'Order Processing'
// All LogEntry__c records have EntryScenario__c = 'Order Processing'
```

### Changing Scenarios Mid-Transaction

```apex
Logger.setScenario('User Authentication');
Logger.info('User logged in');

Logger.setScenario('Data Retrieval');
Logger.debug('Fetching user preferences');

Logger.setScenario('UI Rendering');
Logger.fine('Building component tree');

Logger.saveLog();
// Log__c.TransactionScenario__c = 'User Authentication' (first scenario)
// Each LogEntry__c has its respective EntryScenario__c
```

### Getting Current Scenario

```apex
String currentScenario = Logger.getScenario();
Logger.info('Current scenario: ' + currentScenario);
```

## Advanced Features

### Conditional Logging

```apex
// Log only if condition is met
if (records.size() > 1000) {
    Logger.warn('Large batch detected: ' + records.size() + ' records')
        .addTag('performance-warning');
}

// Conditional save
Boolean hasErrors = false;

for (Account acc : accounts) {
    try {
        processAccount(acc);
    } catch (Exception e) {
        hasErrors = true;
        Logger.error('Account processing failed')
            .setRecord(acc)
            .setExceptionDetails(e);
    }
}

if (hasErrors) {
    Logger.saveLog();  // Only save if there were errors
}
```

### Save Methods

Choose how logs are persisted:

```apex
// Default: Asynchronous via platform events (recommended)
Logger.saveLog();

// Queueable (when platform events are not suitable)
Logger.saveLog(Logger.SaveMethod.QUEUEABLE);

// Synchronous DML (use sparingly, impacts performance)
Logger.saveLog(Logger.SaveMethod.SYNCHRONOUS_DML);

// REST callout (for special cases)
Logger.saveLog(Logger.SaveMethod.REST);
```

### Flushing the Buffer

```apex
// Check buffer size
Integer pendingEntries = Logger.getBufferSize();
Logger.info('Pending entries: ' + pendingEntries);

// Clear buffer without saving
Logger.flushBuffer();

// Buffer is also automatically cleared after saveLog()
```

### User Settings

Access current user's Logger settings:

```apex
LoggerSettings__c userSettings = Logger.getUserSettings();
Boolean isEnabled = userSettings.IsEnabled__c;
String logLevel = userSettings.LoggingLevel__c;

Logger.info('Logger enabled: ' + isEnabled + ', level: ' + logLevel);
```

### Checking if Logger is Enabled

```apex
if (Logger.isEnabled(LoggingLevel.INFO)) {
    // Expensive operation only if INFO logging is enabled
    String complexData = buildComplexDataStructure();
    Logger.info('Complex data: ' + complexData);
}

Logger.saveLog();
```

## Best Practices

### 1. Always Use Try-Finally for saveLog()

```apex
try {
    // Your business logic
    processRecords();
} catch (Exception e) {
    Logger.error('Processing failed').setExceptionDetails(e);
    throw e;
} finally {
    Logger.saveLog();  // Always save, even if exception is thrown
}
```

### 2. Log Business Events, Not Just Errors

```apex
// ❌ Only logging errors
try {
    processOrder(order);
} catch (Exception e) {
    Logger.error('Order failed').setExceptionDetails(e);
}

// ✅ Log important business events too
Logger.info('Order processing started').setRecord(order);
try {
    processOrder(order);
    Logger.info('Order processed successfully').setRecord(order);
} catch (Exception e) {
    Logger.error('Order failed').setExceptionDetails(e).setRecord(order);
    throw e;
} finally {
    Logger.saveLog();
}
```

### 3. Use Appropriate Log Levels

```apex
// ❌ Everything is INFO
Logger.info('Entering method');
Logger.info('Variable x = 123');
Logger.info('Query returned 5 records');
Logger.info('Exiting method');

// ✅ Use appropriate levels
Logger.fine('Entering processOrder()');
Logger.debug('Query returned 5 records');
Logger.info('Order processed successfully');
Logger.fine('Exiting processOrder()');
```

### 4. Add Tags for Important Events

```apex
// ✅ Tag critical events
Logger.error('Payment gateway timeout')
    .addTag('payment')
    .addTag('critical')
    .addTag('requires-investigation');

// ✅ Tag for filtering/dashboards
Logger.info('External API called')
    .addTag('integration')
    .addTag('salesforce-to-netsuite');
```

### 5. Set Scenarios for Business Processes

```apex
// ✅ Group related operations
Logger.setScenario('Opportunity Sync');
Logger.info('Starting sync for ' + opps.size() + ' opportunities');
// ... sync logic ...
Logger.info('Sync completed');
Logger.saveLog();
```

### 6. Include Record Context

```apex
// ❌ Missing context
Logger.error('Record validation failed');

// ✅ Include record for troubleshooting
Logger.error('Record validation failed')
    .setRecord(account)
    .addTag('validation-failure');
```

### 7. Don't Over-Log in Loops

```apex
// ❌ Logs every iteration (creates 1000 log entries!)
for (Integer i = 0; i < 1000; i++) {
    Logger.debug('Processing iteration ' + i);
}

// ✅ Log summary or errors only
Logger.info('Processing ' + records.size() + ' records');
for (Account acc : accounts) {
    try {
        processAccount(acc);
    } catch (Exception e) {
        Logger.error('Failed to process account').setRecord(acc).setExceptionDetails(e);
    }
}
Logger.info('Processing completed');
Logger.saveLog();
```

### 8. Use Scenarios to Change Behavior

```apex
// Scenario rules can change Logger settings
Logger.setScenario('PII Processing');  
// LoggerScenarioRule can enable data masking automatically

Logger.info('Processing sensitive data');  // Data masking is active
Logger.saveLog();
```

## API Reference

### Logger Class

| Method | Description |
|--------|-------------|
| `error(String message)` | Create ERROR level entry |
| `warn(String message)` | Create WARN level entry |
| `info(String message)` | Create INFO level entry |
| `debug(String message)` | Create DEBUG level entry |
| `fine(String message)` | Create FINE level entry |
| `finer(String message)` | Create FINER level entry |
| `finest(String message)` | Create FINEST level entry |
| `saveLog()` | Save all pending log entries (default: EVENT_BUS) |
| `saveLog(SaveMethod)` | Save with specific save method |
| `setScenario(String)` | Set current scenario |
| `getScenario()` | Get current scenario |
| `flushBuffer()` | Clear pending entries without saving |
| `getBufferSize()` | Get count of pending entries |
| `isEnabled(LoggingLevel)` | Check if level is enabled |
| `getUserSettings()` | Get current user's settings |

### LogEntryEventBuilder Class

| Method | Description |
|--------|-------------|
| `addTag(String)` | Add a single tag |
| `addTags(List<String>)` | Add multiple tags |
| `setRecord(SObject)` | Associate with a record |
| `setRecord(List<SObject>)` | Associate with record collection |
| `setExceptionDetails(Exception)` | Capture exception info |
| `setField(Schema.SObjectField, Object)` | Set custom field value |

### Save Methods

```apex
public enum SaveMethod {
    EVENT_BUS,        // Default: publish platform event
    QUEUEABLE,        // Queueable Apex
    REST,             // REST API callout
    SYNCHRONOUS_DML   // Direct DML (use sparingly)
}
```

## Examples

See the `/recipes` directory in the repository for complete examples:
- Trigger logging patterns
- Batch Apex logging
- Scheduled Apex logging
- Integration patterns
- Complex error handling

## Next Steps

- [Tagging Guide](tagging-guide.md) - Master the tagging system
- [Scenarios Guide](scenarios-guide.md) - Track business processes
- [Best Practices](best-practices.md) - Production patterns
- [Performance Guide](performance.md) - Optimize for scale
