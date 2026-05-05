# Performance & Scalability Guide

Optimize Nebula Logger for high-volume production environments.

## Table of Contents

- [Performance Overview](#performance-overview)
- [Governor Limits](#governor-limits)
- [Optimization Strategies](#optimization-strategies)
- [High-Volume Scenarios](#high-volume-scenarios)
- [Monitoring & Metrics](#monitoring--metrics)
- [Troubleshooting Performance](#troubleshooting-performance)
- [Best Practices](#best-practices)

## Performance Overview

### Performance Characteristics

**Default Configuration (EVENT_BUS save method):**
- **User transaction impact:** < 5ms (publish event only)
- **Event processing:** Asynchronous, no user impact
- **Scalability:** Handles 10,000+ logs/hour
- **Governor limits:** Minimal (event publish only)

**Key Metrics:**
```
┌─────────────────────────────────────────────────────────┐
│ Operation               │ Time    │ Governor Impact    │
├─────────────────────────┼─────────┼────────────────────┤
│ Logger.info()           │ <1ms    │ Heap only          │
│ Logger.saveLog()        │ 2-5ms   │ 1 EventBus publish │
│ Event processing        │ Async   │ Separate limits    │
│ Log__c insert           │ N/A     │ Not in user txn    │
│ LogEntry__c insert      │ N/A     │ Not in user txn    │
└─────────────────────────────────────────────────────────┘
```

### Performance Goals

| Environment | Logging Volume | Response Time | Configuration |
|-------------|---------------|---------------|---------------|
| **Development** | Low (100s/day) | Not critical | DEBUG level, all features |
| **Sandbox** | Medium (1000s/day) | < 10ms | INFO level, selective logging |
| **Production** | High (10,000s+/day) | < 5ms | INFO/WARN only, optimized |

## Governor Limits

### Impact by Save Method

**EVENT_BUS (Recommended):**
```apex
Logger.info('Message');
Logger.saveLog();  // EVENT_BUS

// User Transaction Limits Used:
// - EventBus publish: 1
// - Heap: ~5-10KB per entry
// - CPU: < 5ms
// - SOQL: 0
// - DML: 0
```

**SYNCHRONOUS_DML (Not Recommended):**
```apex
Logger.info('Message');
Logger.saveLog(Logger.SaveMethod.SYNCHRONOUS_DML);

// User Transaction Limits Used:
// - DML statements: 2 (Log__c + LogEntry__c)
// - DML rows: 2
// - SOQL queries: 2-5
// - Heap: ~20-30KB per entry
// - CPU: 20-50ms
```

**QUEUEABLE:**
```apex
Logger.info('Message');
Logger.saveLog(Logger.SaveMethod.QUEUEABLE);

// User Transaction Limits Used:
// - Queueable jobs: 1
// - Heap: ~10-15KB per entry
// - CPU: 5-10ms
// - SOQL: 0
// - DML: 0 (moved to queueable)
```

### Platform Event Limits

| Limit | Value | Notes |
|-------|-------|-------|
| **Event publishes per transaction** | 150 | Each saveLog() = 1 publish |
| **Events per publish** | Unlimited | All entries in one publish |
| **Daily event limit** | Varies by edition | Check org limits |
| **Event delivery time** | < 1 second (typically) | Asynchronous |

**Monitoring event limits:**
```apex
// Check remaining event publishes
Integer remaining = Limits.getLimitPublishImmediateDML() - 
                   Limits.getPublishImmediateDML();
System.debug('Remaining event publishes: ' + remaining);
```

## Optimization Strategies

### 1. Minimize Log Volume

**Set Appropriate Log Levels:**
```apex
// ❌ Development: Everything logged
LoggerSettings__c settings = LoggerSettings__c.getInstance();
settings.LoggingLevel__c = 'DEBUG';  // Logs DEBUG, INFO, WARN, ERROR

// ✅ Production: Only important logs
settings.LoggingLevel__c = 'INFO';   // Logs INFO, WARN, ERROR only
```

**Conditional Logging:**
```apex
// Only build expensive messages if level is enabled
if (Logger.isEnabled(LoggingLevel.DEBUG)) {
    String expensiveData = JSON.serialize(largeObject);
    Logger.debug('Data: ' + expensiveData);
}
```

**Selective Logging:**
```apex
// ❌ Log everything
public void processRecords(List<Account> accounts) {
    for (Account acc : accounts) {
        Logger.debug('Processing: ' + acc.Id);  // 10,000 entries!
    }
}

// ✅ Log summary only
public void processRecords(List<Account> accounts) {
    Logger.info('Processing ' + accounts.size() + ' accounts');
    // Process...
    Logger.info('Processing complete: ' + successCount + ' succeeded');
}
```

### 2. Batch Log Entries

**Batch Multiple Entries Before Saving:**
```apex
// ✅ Good: One save for entire operation
Logger.setScenario('Batch Processing');

for (Account acc : accounts) {
    try {
        processAccount(acc);
    } catch (Exception e) {
        Logger.error('Account failed').setRecord(acc).setExceptionDetails(e);
    }
}

Logger.saveLog();  // One save for all entries

// ❌ Bad: Save in loop
for (Account acc : accounts) {
    Logger.info('Processing account');
    Logger.saveLog();  // Don't do this!
}
```

### 3. Use Async Save Methods

**Always use EVENT_BUS or QUEUEABLE:**
```apex
// ✅ Recommended: Async via events
Logger.saveLog();  // Default: EVENT_BUS

// ✅ Alternative: Async via queueable
Logger.saveLog(Logger.SaveMethod.QUEUEABLE);

// ❌ Avoid: Synchronous (blocks user)
Logger.saveLog(Logger.SaveMethod.SYNCHRONOUS_DML);
```

### 4. Optimize Log Messages

**Keep Messages Concise:**
```apex
// ❌ Expensive: Full record JSON
Logger.info('Record: ' + JSON.serialize(account));
// Creates large message, uses heap

// ✅ Efficient: Use setRecord() instead
Logger.info('Processing account').setRecord(account);
// Records stored separately, better for querying
```

**Avoid Redundant Data:**
```apex
// ❌ Redundant: Same data in message and record
Logger.info('Account ' + acc.Id + ' name: ' + acc.Name)
    .setRecord(acc);  // Already has Id and Name

// ✅ Concise: Use record context
Logger.info('Processing account').setRecord(acc);
```

### 5. Limit Tag Usage

**Use Tags Judiciously:**
```apex
// ❌ Too many tags
Logger.info('Message')
    .addTag('tag1').addTag('tag2').addTag('tag3')
    .addTag('tag4').addTag('tag5').addTag('tag6');
// Creates 6 LogEntryTag__c records

// ✅ Essential tags only
Logger.info('Message')
    .addTag('feature')
    .addTag('critical');
// Creates 2 LogEntryTag__c records
```

### 6. Disable Features in Production

**Production Configuration:**
```apex
// Disable features that add overhead
LoggerSettings__c settings = LoggerSettings__c.getInstance();
settings.IsApexSystemDebugLoggingEnabled__c = false;  // Don't duplicate to System.debug()
settings.IsJavaScriptConsoleLoggingEnabled__c = false;  // Don't duplicate to console.log()
```

## High-Volume Scenarios

### Batch Apex

**Pattern for High-Volume Batch:**
```apex
public class AccountBatch implements Database.Batchable<SObject> {
    
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        Logger.setScenario('Account Batch');
        
        Integer successCount = 0;
        Integer errorCount = 0;
        
        for (Account acc : scope) {
            try {
                processAccount(acc);
                successCount++;
            } catch (Exception e) {
                errorCount++;
                // Only log errors, not every record
                Logger.error('Account processing failed')
                    .setRecord(acc)
                    .setExceptionDetails(e);
            }
        }
        
        // Log summary, not individual records
        Logger.info('Batch chunk complete: ' + successCount + ' succeeded, ' + 
                   errorCount + ' errors');
        Logger.saveLog();
    }
    
    public void finish(Database.BatchableContext bc) {
        Logger.info('Batch job completed');
        Logger.saveLog();
    }
}
```

### Scheduled Apex

**Pattern for Scheduled Jobs:**
```apex
public class NightlyBatch implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        Datetime start = Datetime.now();
        
        Logger.setScenario('Nightly Batch');
        Logger.info('Nightly batch started');
        
        try {
            // Run batch logic
            executeBatchLogic();
            
            Long elapsedMs = Datetime.now().getTime() - start.getTime();
            Logger.info('Nightly batch completed in ' + elapsedMs + 'ms');
            
        } catch (Exception e) {
            Logger.error('Nightly batch failed')
                .setExceptionDetails(e)
                .addTag('critical')
                .addTag('requires-investigation');
        } finally {
            Logger.saveLog();
        }
    }
}
```

### Triggers (High-Volume DML)

**Pattern for High-Volume Triggers:**
```apex
public class AccountTriggerHandler {
    
    public void afterUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
        // Don't log every record!
        
        Integer significantChanges = 0;
        
        for (Account acc : newAccounts) {
            Account oldAccount = oldMap.get(acc.Id);
            
            // Only log significant changes
            if (isSignificantChange(acc, oldAccount)) {
                significantChanges++;
                Logger.info('Significant account change')
                    .setRecord(acc)
                    .addTag('account-change');
            }
        }
        
        // Summary log
        if (significantChanges > 0) {
            Logger.info('Processed ' + newAccounts.size() + ' accounts, ' + 
                       significantChanges + ' significant changes');
            Logger.saveLog();
        }
    }
    
    private Boolean isSignificantChange(Account newAcc, Account oldAcc) {
        return newAcc.Industry != oldAcc.Industry || 
               newAcc.Status__c != oldAcc.Status__c;
    }
}
```

### Integration Patterns

**Pattern for API Integrations:**
```apex
public class ExternalAPIService {
    private static final Integer MAX_RETRIES = 3;
    
    public void callExternalAPI(String endpoint) {
        Logger.setScenario('External API Integration');
        
        Integer attempt = 0;
        Boolean success = false;
        
        while (!success && attempt < MAX_RETRIES) {
            attempt++;
            Datetime start = Datetime.now();
            
            try {
                HttpResponse response = makeAPICall(endpoint);
                Long duration = Datetime.now().getTime() - start.getTime();
                
                success = true;
                
                // Log success with timing
                Logger.info('API call succeeded: ' + endpoint + 
                          ' (attempt ' + attempt + ', ' + duration + 'ms)')
                    .addTag('integration')
                    .addTag('api-success');
                
                // Warn on slow responses
                if (duration > 3000) {
                    Logger.warn('API response slow: ' + duration + 'ms')
                        .addTag('performance-warning');
                }
                
            } catch (Exception e) {
                if (attempt >= MAX_RETRIES) {
                    Logger.error('API call failed after ' + MAX_RETRIES + ' attempts')
                        .setExceptionDetails(e)
                        .addTag('integration-failure')
                        .addTag('critical');
                } else {
                    Logger.debug('API call failed, retrying... (attempt ' + attempt + ')');
                }
            }
        }
        
        Logger.saveLog();
    }
}
```

## Monitoring & Metrics

### Key Performance Indicators

**Monitor these metrics:**

1. **Daily Log Volume**
   ```sql
   SELECT COUNT() 
   FROM Log__c 
   WHERE CreatedDate = TODAY
   ```

2. **Logs by Level**
   ```sql
   SELECT LoggingLevel__c, COUNT(Id) 
   FROM LogEntry__c 
   WHERE CreatedDate = LAST_N_DAYS:7 
   GROUP BY LoggingLevel__c
   ```

3. **Average Entries Per Log**
   ```sql
   SELECT AVG(TotalLogEntries__c) 
   FROM Log__c 
   WHERE CreatedDate = LAST_N_DAYS:7
   ```

4. **Platform Event Delivery**
   - Navigate to: **Setup → Platform Events → Event Usage**
   - Monitor: Delivery success rate, backlog

### Storage Monitoring

**Track storage usage:**
```sql
-- Total logs
SELECT COUNT() FROM Log__c

-- Total log entries
SELECT COUNT() FROM LogEntry__c

-- Estimated storage (rough)
SELECT COUNT() * 10 / 1024 / 1024 AS EstimatedGB 
FROM LogEntry__c
```

**Set up storage alerts:**
- Create a report: Storage by Month
- Schedule: Monthly report email
- Alert: When exceeding threshold

### Performance Dashboard

**Create a dashboard with:**
1. **Logs Today** (metric)
2. **Errors Today** (metric)
3. **Logs by Level** (pie chart)
4. **Logs Over Time** (line chart, 30 days)
5. **Top 10 Scenarios** (bar chart)
6. **Average Entries per Log** (metric)

## Troubleshooting Performance

### Symptom: Slow User Transactions

**Check 1: Save Method**
```apex
// Verify using async save method
System.debug('Save method: ' + Logger.getUserSettings().DefaultSaveMethod__c);
// Should be EVENT_BUS or QUEUEABLE
```

**Check 2: Logging Volume**
```apex
// Check buffer size before save
Integer bufferSize = Logger.getBufferSize();
System.debug('Pending entries: ' + bufferSize);
// If > 100, consider reducing logging
```

**Check 3: Message Size**
```apex
// Check message size
for (LogEntryEvent__e event : events) {
    System.debug('Message length: ' + event.Message__c.length());
    // If > 10,000 characters, optimize
}
```

### Symptom: Platform Event Backlog

**Check Event Delivery:**
- Navigate to **Setup → Platform Events → Event Usage**
- Check **LogEntryEvent** delivery status
- Look for: Backlog, Failed deliveries

**Solutions:**
1. **Reduce logging volume** - Increase logging level
2. **Optimize event handler** - Review LogEntryEventHandler CPU time
3. **Scale up** - Contact Salesforce Support for limits increase

### Symptom: High Storage Usage

**Check Storage:**
```apex
// Query old logs
SELECT COUNT(), MIN(CreatedDate), MAX(CreatedDate)
FROM Log__c
WHERE CreatedDate < LAST_N_DAYS:90
GROUP BY CALENDAR_MONTH(CreatedDate)
```

**Solutions:**
1. **Implement retention** - Delete old logs (see [Admin Guide](admin-guide.md#data-management))
2. **Archive to Big Objects** - Use Big Object Archiving plugin
3. **Reduce log volume** - Increase logging level

### Symptom: Governor Limit Errors

**Error: "Too many DML statements"**

**Cause:** Using SYNCHRONOUS_DML save method

**Solution:**
```apex
// Change to EVENT_BUS
Logger.saveLog();  // Uses EVENT_BUS by default
```

**Error: "Too many publishPlatformEvent calls"**

**Cause:** Calling saveLog() more than 150 times per transaction

**Solution:**
```apex
// Batch entries before saving
Logger.info('Entry 1');
Logger.info('Entry 2');
Logger.info('Entry 3');
Logger.saveLog();  // One publish for all entries
```

## Best Practices

### 1. Profile Before Optimizing

**Measure first:**
```apex
Datetime start = Datetime.now();

Logger.info('Test message');
Logger.saveLog();

Long elapsed = Datetime.now().getTime() - start.getTime();
System.debug('Logger time: ' + elapsed + 'ms');
```

### 2. Set Logging Levels Per Environment

```apex
// Managed via custom metadata or settings

// Development
LoggingLevel: DEBUG
IsApexSystemDebugLoggingEnabled: true

// Sandbox
LoggingLevel: INFO
IsApexSystemDebugLoggingEnabled: true

// Production
LoggingLevel: INFO
IsApexSystemDebugLoggingEnabled: false
```

### 3. Use Scenarios to Control Volume

**Create scenario rule for verbose logging:**
```
LoggerScenarioRule__mdt
- Scenario Name: Debug Investigation
- Logging Level: DEBUG
- Is Enabled: true
```

**Usage:**
```apex
// Only set scenario when debugging
if (isDebugging) {
    Logger.setScenario('Debug Investigation');  // Enables DEBUG
}
```

### 4. Implement Retention Policies

**Delete old logs regularly:**
- Automated: Use Log Retention Rules plugin
- Manual: Scheduled batch to delete old logs
- Archive: Move old logs to Big Objects

### 5. Monitor Platform Event Usage

**Weekly checklist:**
- [ ] Check event delivery success rate
- [ ] Review event backlog
- [ ] Verify no failed deliveries
- [ ] Check daily event limit usage

### 6. Load Test Before Go-Live

**Test high-volume scenarios:**
```apex
@isTest
private class LoadTest {
    @isTest
    static void testHighVolume() {
        Test.startTest();
        
        for (Integer i = 0; i < 100; i++) {
            Logger.info('Log entry ' + i);
        }
        Logger.saveLog();
        
        Test.stopTest();
        
        // Verify no errors
        System.assertEquals(0, Limits.getDmlStatements());
        System.assertEquals(1, Limits.getPublishImmediateDML());
    }
}
```

### 7. Review Performance Regularly

**Monthly review:**
- Log volume trending
- Storage usage trending
- Error rate trending
- Performance metrics (avg entries per log)

## Performance Checklist

**Pre-Production:**
- [ ] Logging level set to INFO or WARN
- [ ] Save method is EVENT_BUS or QUEUEABLE
- [ ] System debug logging disabled
- [ ] Console logging disabled
- [ ] Retention policy implemented
- [ ] Load testing completed
- [ ] Monitoring dashboard created

**Production:**
- [ ] Monitor daily log volume
- [ ] Check platform event delivery
- [ ] Review storage usage monthly
- [ ] Delete/archive old logs
- [ ] Review error trends
- [ ] Optimize based on metrics

## Next Steps

- [Architecture Guide](architecture.md) - Understanding Logger design
- [Best Practices](best-practices.md) - General logging patterns
- [Admin Guide](admin-guide.md) - Configuration and management
- [Troubleshooting](troubleshooting.md) - Fixing issues
