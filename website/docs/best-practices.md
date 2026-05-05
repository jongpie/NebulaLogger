# Best Practices

Production-ready patterns and recommendations for using Nebula Logger effectively.

## Table of Contents

- [General Principles](#general-principles)
- [When to Log](#when-to-log)
- [What to Log](#what-to-log)
- [Log Levels](#log-levels)
- [Performance](#performance)
- [Security](#security)
- [Organization](#organization)
- [Production Patterns](#production-patterns)
- [Anti-Patterns](#anti-patterns)

## General Principles

### 1. Log with Purpose

Every log entry should have a clear purpose:

```apex
// ❌ Meaningless logs
Logger.debug('here');
Logger.info('test');
Logger.debug('x = ' + x);

// ✅ Purposeful logs
Logger.info('Order processing started for orderId: ' + orderId);
Logger.debug('Cache miss for key: ' + cacheKey + ', fetching from database');
Logger.error('Payment gateway timeout after 3 retry attempts');
```

### 2. Include Context

Logs are useless without context:

```apex
// ❌ No context
Logger.error('Validation failed');

// ✅ Rich context
Logger.error('Account validation failed: missing required field')
    .setRecord(account)
    .addTag('validation-error')
    .addTag('account-creation');
```

### 3. Think About Your Future Self

Write logs that will help you troubleshoot issues 6 months from now:

```apex
// ❌ Unclear
Logger.info('Done');

// ✅ Clear and actionable
Logger.info('Account sync completed: ' + successCount + ' synced, ' + 
    failureCount + ' failed. Total time: ' + elapsedTime + 'ms')
    .addTag('integration')
    .addTag('netsuite-sync');
```

## When to Log

### Always Log

✅ **Exceptions and Errors**
```apex
catch (Exception e) {
    Logger.error('Critical operation failed')
        .setExceptionDetails(e)
        .setRecord(record);
    Logger.saveLog();
}
```

✅ **Important Business Events**
```apex
Logger.info('Order placed: orderId=' + order.Id + ', total=' + order.Total__c)
    .setRecord(order)
    .addTag('business-event');
```

✅ **Integration Points**
```apex
Logger.info('Calling external API: ' + endpoint)
    .addTag('integration')
    .addTag('external-api');
```

✅ **Security Events**
```apex
Logger.warn('Unauthorized access attempt to restricted data')
    .addTag('security')
    .addTag('requires-review');
```

✅ **Data Quality Issues**
```apex
Logger.warn('Duplicate record detected for email: ' + email)
    .addTag('data-quality')
    .addTag('duplicate');
```

### Consider Logging

⚠️ **State Changes**
```apex
if (account.Status__c != oldStatus) {
    Logger.info('Account status changed: ' + oldStatus + ' -> ' + account.Status__c)
        .setRecord(account);
}
```

⚠️ **Performance Issues**
```apex
if (elapsedTime > 5000) {
    Logger.warn('Slow query detected: ' + elapsedTime + 'ms')
        .addTag('performance')
        .addTag('slow-query');
}
```

⚠️ **Fallback/Retry Logic**
```apex
Logger.info('Primary service unavailable, falling back to secondary')
    .addTag('fallback')
    .addTag('resilience');
```

### Don't Log

❌ **Inside Loops (Usually)**
```apex
// ❌ Creates 10,000 log entries!
for (Account acc : accounts) {
    Logger.debug('Processing account: ' + acc.Id);
}

// ✅ Log summary instead
Logger.info('Processing ' + accounts.size() + ' accounts');
```

❌ **Sensitive Data (Without Masking)**
```apex
// ❌ Logging PII
Logger.debug('SSN: ' + ssn);  // Don't do this!

// ✅ Enable data masking or don't log
Logger.debug('Processing user with masked SSN');
```

❌ **In Getter Methods**
```apex
// ❌ Called on every access
public String getName() {
    Logger.debug('getName called');  // Don't do this!
    return this.name;
}
```

❌ **Routine Success Cases**
```apex
// ❌ Too noisy for production
Logger.info('Method started');
Logger.info('Validation passed');
Logger.info('Query executed');
Logger.info('Method ended');

// ✅ Log meaningful milestones
Logger.info('Order processing completed successfully');
```

## What to Log

### Essential Information

1. **What happened** - Clear description
2. **When** - Timestamp (automatic)
3. **Where** - Context (class, method, line - automatic in Apex)
4. **Who** - User (automatic)
5. **Why** - Business context (scenario, tags)
6. **Related data** - Record IDs, key values

### Good Examples

```apex
// Business event with full context
Logger.info('Payment processed successfully')
    .setRecord(payment)
    .setField(LogEntry__c.RelatedRecordId__c, orderId)
    .addTag('payment')
    .addTag('stripe');

// Error with actionable information
Logger.error('API rate limit exceeded: 1000 requests/hour')
    .addTag('integration')
    .addTag('rate-limit')
    .addTag('requires-throttling');

// State transition
Logger.info('Opportunity stage changed: ' + oldStage + ' -> ' + newStage +
    ', probability: ' + opp.Probability + '%')
    .setRecord(opp)
    .addTag('opportunity')
    .addTag('stage-change');
```

## Log Levels

### Level Selection Guide

| Level | Production Volume | Use For |
|-------|------------------|---------|
| **ERROR** | Always on | Exceptions, failures, data loss |
| **WARN** | Always on | Degraded functionality, approaching limits |
| **INFO** | Default | Business events, important milestones |
| **DEBUG** | Troubleshooting only | Diagnostic information |
| **FINE/FINER/FINEST** | Never in production | Development/debugging only |

### Production Configuration

```apex
// In production, set user-level logging to INFO
LoggerSettings__c settings = LoggerSettings__c.getInstance();
settings.LoggingLevel__c = 'INFO';
upsert settings;

// For specific users debugging issues, temporarily enable DEBUG
LoggerSettings__c debugSettings = LoggerSettings__c.getInstance(problemUserId);
debugSettings.LoggingLevel__c = 'DEBUG';
upsert debugSettings;
```

### Level Examples

```apex
// ERROR - Something is broken
Logger.error('Payment gateway returned 500 error')
    .addTag('critical')
    .addTag('payment');

// WARN - Something might be wrong
Logger.warn('API response time: 4.5s (threshold: 5s)')
    .addTag('performance')
    .addTag('approaching-limit');

// INFO - Important business event
Logger.info('User completed onboarding')
    .addTag('onboarding')
    .addTag('milestone');

// DEBUG - Diagnostic information
Logger.debug('Cache hit rate: 85%, size: 1200 items')
    .addTag('performance')
    .addTag('cache');

// FINE - Trace-level detail
Logger.fine('Entering method processOrder(), recordId=' + recordId);
```

## Performance

### 1. Batch Log Entries

```apex
// ✅ Good: One save for entire operation
Logger.setScenario('Batch Processing');
Logger.info('Starting batch of ' + records.size() + ' records');

for (Account acc : accounts) {
    try {
        processAccount(acc);
    } catch (Exception e) {
        Logger.error('Account processing failed')
            .setRecord(acc)
            .setExceptionDetails(e);
    }
}

Logger.info('Batch completed: ' + successCount + ' succeeded, ' + failureCount + ' failed');
Logger.saveLog();  // One save at the end

// ❌ Bad: Saving in loop
for (Account acc : accounts) {
    Logger.info('Processing account');
    Logger.saveLog();  // Don't do this!
}
```

### 2. Use Appropriate Save Methods

```apex
// Default: Async via platform events (best for most cases)
Logger.saveLog();

// Queueable: When platform events aren't suitable
Logger.saveLog(Logger.SaveMethod.QUEUEABLE);

// Synchronous DML: Only when you MUST have immediate persistence
// WARNING: Impacts transaction performance
Logger.saveLog(Logger.SaveMethod.SYNCHRONOUS_DML);
```

### 3. Conditional Logging

```apex
// Only build expensive log messages if level is enabled
if (Logger.isEnabled(LoggingLevel.DEBUG)) {
    String expensiveData = buildComplexDebugOutput();  // Only runs if DEBUG enabled
    Logger.debug('Complex data: ' + expensiveData);
}

// Don't waste cycles on disabled levels
if (Logger.isEnabled(LoggingLevel.FINE)) {
    Logger.fine('Variable state: ' + JSON.serialize(largeObject));
}
```

### 4. Avoid Logging in Tight Loops

```apex
// ❌ Bad: Logging every iteration
for (Integer i = 0; i < 10000; i++) {
    Logger.debug('Iteration ' + i);  // Creates 10,000 entries!
}

// ✅ Good: Log summary or errors only
Integer processed = 0;
Integer failed = 0;

for (Account acc : accounts) {
    try {
        processAccount(acc);
        processed++;
    } catch (Exception e) {
        failed++;
        Logger.error('Failed to process account').setRecord(acc).setExceptionDetails(e);
    }
}

Logger.info('Processed ' + processed + ' accounts, ' + failed + ' failures');
```

### 5. Set Appropriate Log Levels per Environment

```apex
// In production: INFO and above
// In sandbox: DEBUG and above
// In dev: FINE and above

// Use custom metadata or hierarchy settings to control per environment
```

## Security

### 1. Enable Data Masking

Configure data masking rules for sensitive information:

```apex
// Built-in rules mask:
// - Credit card numbers
// - Social Security Numbers
// - Custom patterns

// Enable in settings
LoggerSettings__c settings = LoggerSettings__c.getInstance();
settings.IsDataMaskingEnabled__c = true;
upsert settings;
```

### 2. Don't Log Sensitive Data

```apex
// ❌ Bad: Logging sensitive information
Logger.debug('User SSN: ' + ssn);
Logger.debug('Credit card: ' + ccNumber);
Logger.debug('Password: ' + password);  // Never!

// ✅ Good: Log masked or omitted sensitive data
Logger.debug('Processing payment for user with masked SSN');
Logger.info('User authenticated successfully');  // Don't log credentials
```

### 3. Use Appropriate Field-Level Security

Ensure Logger custom objects respect your security model:

- Set appropriate OWD on `Log__c`, `LogEntry__c`, `LoggerTag__c`
- Use sharing rules if needed
- Assign permission sets carefully
- Consider using criteria-based sharing for sensitive logs

### 4. Tag Sensitive Logs

```apex
Logger.info('Accessed PII for compliance review')
    .setRecord(record)
    .addTag('pii')
    .addTag('sensitive')
    .addTag('compliance');
```

### 5. Implement Log Retention

Use the Log Retention Rules plugin to automatically delete old logs:

```apex
// Example: Delete DEBUG logs after 7 days
// Delete INFO logs after 30 days
// Delete ERROR logs after 90 days
```

## Organization

### 1. Use Scenarios Consistently

Define scenarios for your business processes:

```apex
// ✅ Good: Consistent scenario names
Logger.setScenario('Order Processing');
Logger.setScenario('User Registration');
Logger.setScenario('Inventory Sync');
Logger.setScenario('Payment Processing');

// ❌ Bad: Inconsistent naming
Logger.setScenario('order processing');  // lowercase
Logger.setScenario('ORDER_PROCESSING');  // different format
Logger.setScenario('Process Order');     // different wording
```

### 2. Establish Tagging Conventions

Create a taxonomy of tags:

```apex
// System tags
.addTag('integration')
.addTag('batch')
.addTag('scheduled')

// Severity tags
.addTag('critical')
.addTag('requires-investigation')
.addTag('informational')

// Feature tags
.addTag('payment')
.addTag('inventory')
.addTag('authentication')

// Team tags
.addTag('team-platform')
.addTag('team-integrations')
```

### 3. Document Your Standards

Create a wiki page or doc with:

- Approved scenario names
- Tag taxonomy
- When to use which log level
- When to save logs
- Team-specific conventions

### 4. Use Tagging Rules

Configure `LogEntryTagRule__mdt` for automatic tagging:

```
// Auto-tag any entry with "payment" in the message
Field: Message__c
Comparison: CONTAINS
Value: payment
Tags: payment, financial
```

## Production Patterns

### Pattern 1: Try-Catch-Finally

```apex
public void processOrder(Order__c order) {
    Logger.setScenario('Order Processing');
    
    try {
        Logger.info('Processing order: ' + order.Id).setRecord(order);
        
        validateOrder(order);
        calculateTotals(order);
        submitOrder(order);
        
        Logger.info('Order processed successfully').setRecord(order);
        
    } catch (Exception e) {
        Logger.error('Order processing failed')
            .setRecord(order)
            .setExceptionDetails(e)
            .addTag('critical')
            .addTag('order-failure');
        throw e;  // Re-throw after logging
        
    } finally {
        Logger.saveLog();  // Always save, success or failure
    }
}
```

### Pattern 2: Integration Logging

```apex
public class ExternalAPIService {
    
    public APIResponse callAPI(APIRequest request) {
        Logger.setScenario('External API Integration');
        
        Datetime startTime = Datetime.now();
        Logger.info('API call started: ' + request.endpoint)
            .addTag('integration')
            .addTag('external-api');
        
        try {
            HttpResponse response = http.send(request);
            
            Long elapsedTime = Datetime.now().getTime() - startTime.getTime();
            
            Logger.info('API call completed: status=' + response.getStatusCode() + 
                ', time=' + elapsedTime + 'ms')
                .addTag('integration')
                .addTag('api-success');
            
            if (elapsedTime > 3000) {
                Logger.warn('API call exceeded performance threshold')
                    .addTag('performance-warning');
            }
            
            Logger.saveLog();
            return parseResponse(response);
            
        } catch (Exception e) {
            Logger.error('API call failed: ' + request.endpoint)
                .setExceptionDetails(e)
                .addTag('integration-failure')
                .addTag('critical');
            Logger.saveLog();
            throw e;
        }
    }
}
```

### Pattern 3: Batch Apex Logging

```apex
public class AccountBatch implements Database.Batchable<SObject> {
    
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        Logger.setScenario('Account Batch Processing');
        
        Integer successCount = 0;
        Integer failureCount = 0;
        
        for (Account acc : scope) {
            try {
                processAccount(acc);
                successCount++;
            } catch (Exception e) {
                failureCount++;
                Logger.error('Failed to process account')
                    .setRecord(acc)
                    .setExceptionDetails(e)
                    .addTag('batch-failure');
            }
        }
        
        Logger.info('Batch chunk completed: ' + successCount + ' succeeded, ' + 
            failureCount + ' failed');
        Logger.saveLog();
    }
}
```

### Pattern 4: Trigger Logging

```apex
public class AccountTriggerHandler {
    
    public void beforeUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
        Logger.setScenario('Account Trigger - Before Update');
        
        for (Account acc : newAccounts) {
            Account oldAccount = oldMap.get(acc.Id);
            
            // Log important state changes
            if (acc.Status__c != oldAccount.Status__c) {
                Logger.info('Account status changed: ' + oldAccount.Status__c + 
                    ' -> ' + acc.Status__c)
                    .setRecord(acc)
                    .addTag('status-change');
            }
        }
        
        Logger.saveLog();
    }
}
```

## Anti-Patterns

### ❌ Anti-Pattern 1: Logging Everything

```apex
// ❌ Too much noise
Logger.debug('Entering method');
Logger.debug('Variable x = ' + x);
Logger.debug('Query executed');
Logger.debug('Loop started');
Logger.debug('Loop iteration 1');
Logger.debug('Loop iteration 2');
// ... creates thousands of useless entries

// ✅ Log what matters
Logger.info('Processing ' + records.size() + ' records');
// ... process records ...
Logger.info('Processing completed');
```

### ❌ Anti-Pattern 2: Generic Error Messages

```apex
// ❌ Useless error message
catch (Exception e) {
    Logger.error('Error occurred');
}

// ✅ Specific, actionable error message
catch (Exception e) {
    Logger.error('Failed to sync opportunity to NetSuite: ' + opp.Id)
        .setRecord(opp)
        .setExceptionDetails(e)
        .addTag('integration-failure')
        .addTag('netsuite');
}
```

### ❌ Anti-Pattern 3: Logging Without Context

```apex
// ❌ No context
Logger.error('Update failed');

// ✅ Rich context
Logger.error('Failed to update account: missing required field Email')
    .setRecord(account)
    .addTag('validation-error');
```

### ❌ Anti-Pattern 4: Forgetting to Save

```apex
// ❌ Logs never persisted!
public void doSomething() {
    Logger.info('Doing something');
    Logger.debug('Still doing something');
    Logger.info('Done');
    // Forgot to call saveLog()!
}

// ✅ Always save
public void doSomething() {
    try {
        Logger.info('Doing something');
        performOperation();
    } finally {
        Logger.saveLog();  // Always save
    }
}
```

### ❌ Anti-Pattern 5: Logging in Constructors (Sometimes)

```apex
// ❌ Can cause issues in some contexts
public class MyClass {
    public MyClass() {
        Logger.info('Constructor called');  // Be careful with this
        Logger.saveLog();
    }
}

// ✅ Log in methods instead
public class MyClass {
    public void initialize() {
        Logger.info('Initializing MyClass');
        Logger.saveLog();
    }
}
```

## Team Practices

### Code Review Checklist

- [ ] Appropriate log level used?
- [ ] Exception details captured?
- [ ] Tags added for filtering?
- [ ] Scenario set for business context?
- [ ] `saveLog()` called in finally block?
- [ ] No sensitive data logged?
- [ ] Performance impact considered?
- [ ] Follows team conventions?

### Monitoring

Set up dashboards to monitor:
- ERROR count trending
- High-volume tags
- Slow operations (via performance tags)
- Integration failures
- User-facing errors

### Incident Response

When investigating incidents:
1. Query logs by timeframe
2. Filter by scenario or tag
3. Look for ERROR entries
4. Check related records
5. Review stack traces
6. Identify patterns

## Next Steps

- [Performance Guide](performance.md) - Optimize Logger for scale
- [Security Guide](security.md) - Secure your logs
- [Troubleshooting](troubleshooting.md) - Fix common issues
- [Admin Guide](admin-guide.md) - Configure Logger
