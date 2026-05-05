# Troubleshooting Guide

Solutions to common issues with Nebula Logger.

## Table of Contents

- [Logs Not Appearing](#logs-not-appearing)
- [Platform Event Issues](#platform-event-issues)
- [Permission Errors](#permission-errors)
- [Performance Problems](#performance-problems)
- [Tag and Scenario Issues](#tag-and-scenario-issues)
- [Integration Issues](#integration-issues)
- [Storage Problems](#storage-problems)

## Logs Not Appearing

### Symptom: No logs created after saveLog()

**Check 1: Is Logger enabled?**

```apex
// Execute anonymous:
LoggerSettings__c settings = LoggerSettings__c.getInstance();
System.debug('Is Enabled: ' + settings.IsEnabled__c);
System.debug('Logging Level: ' + settings.LoggingLevel__c);
```

**Solution:** Enable Logger
```apex
LoggerSettings__c settings = LoggerSettings__c.getInstance();
settings.IsEnabled__c = true;
upsert settings;
```

**Check 2: Is logging level too high?**

```apex
// If level is WARN, only WARN and ERROR are logged
Logger.debug('This will not appear');  // Filtered out
Logger.info('This will not appear');   // Filtered out
Logger.warn('This will appear');       // Logged
```

**Solution:** Lower logging level
```apex
LoggerSettings__c settings = LoggerSettings__c.getInstance();
settings.LoggingLevel__c = 'DEBUG';  // or 'INFO'
upsert settings;
```

**Check 3: Did you call saveLog()?**

```apex
// Wrong: Logs not saved
Logger.info('Message');
// Missing saveLog()!

// Correct: Logs saved
Logger.info('Message');
Logger.saveLog();
```

**Check 4: Check platform events**

1. Navigate to **Setup → Platform Events → LogEntryEvent**
2. Click **Event Delivery**
3. Check delivery status
4. Look for errors in **Failed Deliveries**

**Check 5: Check triggers are active**

1. Navigate to **Setup → Apex Triggers**
2. Find **LogEntryEventTrigger**
3. Verify **Status** is **Active**

**Check 6: Check debug logs**

Enable debug logs and look for:
- "Nebula Logger" messages
- Platform event publish calls
- Any Logger-related errors

### Symptom: Logs appear after long delay

**Cause:** Platform events are asynchronous

**Expected behavior:**
- Event publish: Immediate
- Event delivery: Within 1-5 seconds (typically)
- Log__c creation: Within 5-10 seconds total

**If delays exceed 1 minute:**
1. Check platform event delivery metrics
2. Look for event backlog
3. Check org performance (API usage, CPU limits)

## Platform Event Issues

### Symptom: Platform event limit exceeded

**Error:** "PLATFORM_EVENT_PUBLISH_FAILED"

**Cause:** More than 150 EventBus.publish() calls per transaction

**Solution:** Batch log entries before saving

```apex
// Wrong: Too many saveLog() calls
for (Account acc : accounts) {
    Logger.info('Processing: ' + acc.Id);
    Logger.saveLog();  // 1000 saveLog() calls!
}

// Correct: Batch entries
for (Account acc : accounts) {
    Logger.info('Processing: ' + acc.Id);
}
Logger.saveLog();  // One saveLog() call
```

## Permission Errors

### Symptom: "Insufficient privileges" error

**Cause:** User does not have Logger permissions

**Check permissions:**
1. Navigate to **Setup → Users → Permission Sets**
2. Check if **Logger End User** is assigned
3. Check object permissions on Log__c, LogEntry__c

**Solution:** Assign permission set
1. Open **Logger End User** permission set
2. **Manage Assignments**
3. Add user

## Performance Problems

### Symptom: Slow save times

**Check 1: Which save method?**

```apex
// Check current save method
LoggerSettings__c settings = LoggerSettings__c.getInstance();
System.debug('Save method: ' + settings.DefaultSaveMethod__c);
```

**Solution:** Use async method
```apex
settings.DefaultSaveMethod__c = 'EVENT_BUS';  // Async, fastest
upsert settings;
```

## Tag and Scenario Issues

### Symptom: Tags not appearing

**Check 1: Is tagging enabled?**

1. **Setup → Custom Metadata Types → Logger Parameters**
2. Find **ENABLE_TAGGING**
3. Verify Value = true

**Check 2: Did you save the log?**

```apex
Logger.info('Message').addTag('my-tag');
Logger.saveLog();  // Must call saveLog()
```

## Integration Issues

### Symptom: LWC logger not working

**Check 1: Is logger imported correctly?**

```javascript
import { getLogger } from 'c/logger';  // Correct
```

**Check 2: Did you create logger instance?**

```javascript
export default class MyComponent extends LightningElement {
    logger = getLogger();  // Must create instance
    
    handleClick() {
        this.logger.info('Clicked');
        this.logger.saveLog();
    }
}
```

## Storage Problems

### Symptom: Running out of data storage

**Check storage usage:**
```sql
SELECT COUNT() FROM Log__c;
SELECT COUNT() FROM LogEntry__c;
```

**Solution 1: Delete old logs**
```apex
// Delete logs older than 90 days
List<Log__c> oldLogs = [
    SELECT Id FROM Log__c
    WHERE CreatedDate < LAST_N_DAYS:90
];
delete oldLogs;
```

## Getting Help

If you have tried all troubleshooting steps:

1. **Check GitHub Issues** - https://github.com/jongpie/NebulaLogger/issues
2. **Check Documentation** - Review relevant guides
3. **Enable Debug Logs** - Capture full debug log
4. **Create GitHub Issue** - Include details and error messages

## Next Steps

- [Admin Guide](admin-guide.md) - Configuration reference
- [FAQ](faq.md) - Common questions
- [Performance Guide](performance.md) - Optimization
- [Best Practices](best-practices.md) - Recommended patterns
