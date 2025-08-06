# Logging in Apex

Complete guide to using Nebula Logger in Apex classes, triggers, and anonymous scripts.

## Basic Logging

### Simple Messages

```apex
Logger.info('Hello, world!');
Logger.error('Something went wrong');
Logger.warn('Warning message');
Logger.debug('Debug information');
Logger.saveLog();
```

### Logging with Exceptions

```apex
try {
    // Your code here
} catch (Exception e) {
    Logger.error('An error occurred', e);
    Logger.saveLog();
}
```

### Logging with Records

```apex
Account acc = [SELECT Id, Name FROM Account LIMIT 1];
Logger.info('Processing account', acc);
Logger.saveLog();
```

## Logging Levels

Nebula Logger supports all standard Salesforce logging levels:

- **ERROR**: Critical errors that need immediate attention
- **WARN**: Warning conditions that should be monitored
- **INFO**: General information about application flow
- **DEBUG**: Detailed debugging information
- **FINE**: Fine-grained debugging information
- **FINER**: Finer-grained debugging information
- **FINEST**: Finest-grained debugging information

## Transaction Controls

### Suspend/Resume Saving

```apex
Logger.suspendSaving(); // Ignore saveLog() calls
// ... your code ...
Logger.resumeSaving();  // Re-enable saving
Logger.saveLog();       // Now this will work
```

### Flush Buffer

```apex
Logger.info('This will be saved');
Logger.flushBuffer();   // Discard unsaved entries
Logger.info('This will also be saved');
Logger.saveLog();       // Only saves the second entry
```

### Save Methods

```apex
// Use event bus (default)
Logger.saveLog(Logger.SaveMethod.EVENT_BUS);

// Use queueable (async)
Logger.saveLog(Logger.SaveMethod.QUEUEABLE);

// Use REST API
Logger.saveLog(Logger.SaveMethod.REST);

// Use synchronous DML
Logger.saveLog(Logger.SaveMethod.SYNCHRONOUS_DML);
```

## Scenario-Based Logging

### Setting Scenarios

```apex
Logger.setScenario('User Registration');
Logger.info('Registration started');
// ... your code ...
Logger.info('Registration completed');
Logger.saveLog();
```

### Nested Scenarios

```apex
Logger.setScenario('Main Process');
Logger.info('Main process started');

Logger.setScenario('Sub Process');
Logger.info('Sub process started');
Logger.endScenario('Sub Process');

Logger.info('Main process continued');
Logger.saveLog();
```

## Advanced Features

### Using LogMessage

```apex
// Efficient string formatting
LogMessage message = new LogMessage('Processing user {0} with role {1}', userId, userRole);
Logger.info(message);
Logger.saveLog();
```

### Custom Fields

```apex
// Set field for all entries in transaction
Logger.setField(LogEntryEvent__e.CustomField__c, 'transaction value');

// Set field for specific entry
Logger.info('Specific entry').setField(LogEntryEvent__e.CustomField__c, 'specific value');
Logger.saveLog();
```

### Tagging

```apex
Logger.info('Important message').addTag('important');
Logger.error('Critical error').addTags(new List<String>{'critical', 'urgent'});
Logger.saveLog();
```

## Batch and Queueable Jobs

### Relating Logs Across Jobs

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
    
    public void finish(Database.BatchableContext context) {
        Logger.setParentLogTransactionId(this.parentTransactionId);
        Logger.info('Batch completed');
        Logger.saveLog();
    }
}
```

## Best Practices

### Performance

- Use appropriate logging levels
- Avoid logging in loops when possible
- Use `LogMessage` for expensive string formatting
- Consider using `suspendSaving()` for high-volume operations

### Organization

- Use scenarios to group related logs
- Add meaningful tags for filtering
- Include relevant record IDs in messages
- Use consistent naming conventions

### Error Handling

```apex
try {
    // Your business logic
} catch (DmlException e) {
    Logger.error('Database operation failed', e);
    Logger.saveLog();
    throw e; // Re-throw if needed
} catch (Exception e) {
    Logger.error('Unexpected error', e);
    Logger.saveLog();
    throw e;
}
```

## Related Topics

- [Scenario-Based Logging](features/scenarios.md)
- [Tagging System](features/tagging.md)
- [Custom Fields](features/custom-fields.md)
- [Configuration](configuration.md)
