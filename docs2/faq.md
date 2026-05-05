---
sidebar_position: 20
title: FAQ
description: Frequently Asked Questions about Nebula Logger
keywords: [faq, questions, troubleshooting, help]
---

# Frequently Asked Questions (FAQ)

Common questions and answers about Nebula Logger.

## General Questions

### What is Nebula Logger?

Nebula Logger is a native Salesforce logging solution that provides persistent, queryable logs across all Salesforce platforms (Apex, LWC, Aura, Flow, OmniStudio). Unlike `System.debug()`, logs are stored as Salesforce records with rich metadata, tagging, and search capabilities.

### Why use Nebula Logger instead of System.debug()?

**System.debug() limitations:**
- ❌ Logs expire after 24 hours
- ❌ Must enable debug logs per user
- ❌ No structured data or metadata
- ❌ Can't query or build reports
- ❌ Only works in Apex

**Nebula Logger advantages:**
- ✅ Persistent storage as Salesforce records
- ✅ Works in Apex, LWC, Aura, Flow, OmniStudio
- ✅ Rich metadata (user, stack traces, limits)
- ✅ Query, report, and build dashboards
- ✅ Event-driven (async, scalable)
- ✅ Production-ready monitoring

### Is Nebula Logger free?

Yes! Nebula Logger is **100% free and open source** under the MIT License. There are no licensing fees, no usage limits, and no premium tiers.

### Can I use Nebula Logger in production?

Absolutely! Nebula Logger is designed for production use and is used by thousands of Salesforce orgs. It's:
- Battle-tested in enterprise environments
- Async by default (no user impact)
- Governor limit-friendly
- Fully tested (90%+ coverage)

---

## Installation & Setup

### Which package should I install: Unlocked or Managed?

**Unlocked Package (Recommended):**
- ✅ Faster updates
- ✅ Full source access
- ✅ Plugin framework
- ✅ No namespace
- ⚠️ Requires manual upgrades

**Managed Package:**
- ✅ Automatic upgrades
- ✅ Salesforce AppExchange support
- ✅ ISV-friendly
- ⚠️ `Nebula` namespace required
- ⚠️ No plugin framework
- ⚠️ Slower release cycle

**Recommendation:** Use unlocked unless you specifically need managed package features.

See [Installation Guide](installation.md) for details.

### How do I upgrade to a newer version?

**Unlocked Package:**
```bash
sf package install --wait 20 --security-type AdminsOnly --package [NEW_VERSION_ID]
```

**Managed Package:**
Updates automatically or via AppExchange.

See [Installation Guide](installation.md#upgrading) for details.

### What permissions do users need?

Assign the appropriate permission set:
- **Logger End User** - Create and view own logs
- **Logger Admin** - Full access, configuration

See [Admin Guide](admin-guide.md#permission-sets) for details.

### Why aren't my logs appearing?

**Checklist:**
1. ✅ Is Logger enabled? Check `LoggerSettings__c.IsEnabled__c`
2. ✅ Is saving enabled? Check `LoggerSettings__c.IsSavingEnabled__c`
3. ✅ Did you call `Logger.saveLog()`?
4. ✅ Is log level met? Check `LoggerSettings__c.LoggingLevel__c`
5. ✅ Check debug logs for errors in `LogEntryEventHandler`
6. ✅ Check platform event monitoring for `LogEntryEvent__e`

See [Troubleshooting](troubleshooting.md#logs-not-appearing) for details.

---

## Usage Questions

### What's the difference between tags and scenarios?

| Feature | Tags | Scenarios |
|---------|------|-----------|
| **Purpose** | Categorize/filter | Track business process |
| **Cardinality** | Many per entry | One per entry |
| **Example** | "payment", "critical" | "Order Processing" |
| **Use Case** | Filtering, searching | Process tracking |

**Rule of thumb:**
- **Scenario** = "What am I doing?" (the process)
- **Tags** = "What characteristics?" (categories)

See [Tagging Guide](tagging-guide.md#tags-vs-scenarios) and [Scenarios Guide](scenarios-guide.md) for details.

### When should I use each log level?

```apex
Logger.error()   // 🔴 Production issues, exceptions, failures
Logger.warn()    // 🟡 Potential problems, deprecations
Logger.info()    // 🔵 Important business events
Logger.debug()   // ⚪ General diagnostic information
Logger.fine()    // 🔍 Detailed diagnostics
Logger.finer()   // 🔍🔍 Very detailed diagnostics
Logger.finest()  // 🔍🔍🔍 Maximum verbosity
```

**Production recommendation:** INFO for business events, WARN+ for problems.

See [Best Practices - Log Levels](best-practices.md#log-levels) for details.

### Should I log in loops?

**⚠️ Avoid logging inside tight loops** - it can exceed governor limits and create excessive records.

**Better pattern:**
```apex
// ❌ Bad: Log in loop
for (Account acc : accounts) {
    Logger.info('Processing ' + acc.Name);
}

// ✅ Good: Log summary
Logger.info('Processing ' + accounts.size() + ' accounts');
// ... process accounts ...
Logger.info('Completed processing ' + successCount + ' accounts, ' + errorCount + ' errors');
```

See [Best Practices - Performance](best-practices.md#performance) for details.

### How do I log exceptions?

```apex
try {
    // risky code
} catch (Exception e) {
    Logger.error('Payment processing failed')
        .setExceptionDetails(e)
        .setRecord(order)
        .addTag('payment-error')
        .addTag('critical');
    Logger.saveLog();
    throw e; // Re-throw or handle as needed
}
```

See [Apex Guide - Exception Handling](apex-guide.md#exception-handling) for details.

### Can I use Logger in triggers?

Yes! Logger works great in triggers:

```apex
trigger AccountTrigger on Account (before insert, after update) {
    Logger.setScenario('Account Trigger');
    
    if (Trigger.isBefore && Trigger.isInsert) {
        Logger.info('Processing ' + Trigger.new.size() + ' new accounts');
        // ... logic ...
    }
    
    Logger.saveLog();
}
```

**Best practice:** Call `saveLog()` once at the end of trigger.

See [Best Practices - Triggers](best-practices.md#triggers) for details.

---

## Architecture & Technical

### What save method should I use?

| Save Method | When to Use | Pros | Cons |
|-------------|-------------|------|------|
| **EVENT_BUS** (default) | Most cases | Async, scalable | Slight delay |
| **QUEUEABLE** | Defer CPU usage | Reduces sync limits | Uses async apex limits |
| **REST** | Mixed DML contexts | Avoids mixed DML | Uses callout limits |
| **SYNCHRONOUS_DML** | Platform events context | Immediate | Rolls back on error |

**Recommendation:** Use EVENT_BUS (default) unless you have specific requirements.

See [Architecture](architecture.md#save-methods) for details.

### How much storage does Logger use?

**Per log entry:** ~5-10 KB (varies with metadata)

**Example:**
- 10,000 logs/day = 50-100 MB/day
- 365 days = ~18-36 GB/year

**Mitigation strategies:**
- Retention policies (auto-delete old logs)
- Archive to Big Objects
- Log level filtering (INFO+ in production)

See [Cost Analysis](cost-analysis.md) and [Data Management](data-management.md) for details.

### Does Logger impact governor limits?

**Minimal impact:**
- **CPU time:** <5ms per `Logger.saveLog()` call
- **Heap:** ~50-100 KB per transaction
- **DML:** 1 platform event publish per `saveLog()`
- **SOQL:** Minimal (cached settings)

**Best practices:**
- Don't call `saveLog()` in loops
- Use appropriate log levels
- Use `Logger.suspendSaving()` for bulk operations

See [Performance](performance.md#governor-limits) for details.

### Can I customize Logger?

Yes! Multiple customization options:
- ✅ Custom fields via field mapping
- ✅ Custom metadata for configuration
- ✅ Plugin framework (Apex/Flow)
- ✅ Triggers on Log/LogEntry objects
- ✅ Custom business rules

See [Developer Guide](developer-guide.md) and [Plugin Development](plugin-development.md) for details.

---

## Security & Compliance

### Is sensitive data protected?

Yes! Built-in data masking:
- Credit card numbers (automatic)
- Social Security Numbers (automatic)
- Custom regex patterns (configurable)
- Field-level masking rules

**Example:**
```apex
Logger.info('Payment for SSN: 123-45-6789');
// Stored as: "Payment for SSN: ***-**-****"
```

See [Security](security.md#data-masking) for details.

### Is Logger GDPR compliant?

Logger provides tools for GDPR compliance:
- ✅ Data retention policies
- ✅ Log purging automation
- ✅ Data masking for PII
- ✅ User data deletion support

**Your responsibility:**
- Configure appropriate retention
- Enable data masking
- Document your logging practices

See [Security](security.md#gdpr) for details.

### Who can see logs?

**Default security model:**
- Users see only their own logs
- Sharing rules can grant broader access
- Admins see all logs

**Configurable via:**
- `LoggerSettings__c.DefaultLogShareAccessLevel__c`
- Salesforce sharing rules
- Permission sets

See [Admin Guide - Security](admin-guide.md#security) for details.

---

## Troubleshooting

### Why are my tags not appearing?

**Checklist:**
1. ✅ Did you call `addTag()` before `saveLog()`?
2. ✅ Is tagging enabled? Check `LoggerParameter__mdt: ENABLE_TAGGING`
3. ✅ Check for trigger errors on `LogEntryTag__c`
4. ✅ Verify tags in Related Lists on `LogEntry__c`

See [Troubleshooting - Tags](troubleshooting.md#tags) for details.

### Why aren't scenarios working?

**Checklist:**
1. ✅ Did you call `Logger.setScenario()` before logging?
2. ✅ Is scenario normalization enabled? Check `LoggerParameter__mdt: NORMALIZE_SCENARIO_DATA`
3. ✅ Check `Log__c.TransactionScenario__c` field
4. ✅ Check debug logs for scenario-related errors

See [Troubleshooting - Scenarios](troubleshooting.md#scenarios) for details.

### How do I troubleshoot platform event issues?

1. **Check Event Monitoring:**
   - Setup → Event Manager → Platform Events
   - Search for `LogEntryEvent__e`
   - Check publish/delivery metrics

2. **Check Triggers:**
   - Verify `LogEntryEventHandler` is active
   - Check debug logs for trigger errors
   - Verify trigger user context

3. **Check Settings:**
   - `LoggerSettings__c.IsEnabled__c = true`
   - `LoggerSettings__c.IsSavingEnabled__c = true`

See [Troubleshooting](troubleshooting.md) for details.

---

## Integration & Advanced

### Can I use Logger with managed packages?

Yes! Three options:
1. **Optional Dependency** - Use `CallableLogger` (dynamic)
2. **Hard Dependency** - Add as package dependency
3. **Bundle It** - Include Logger source in your package

See [Developer Guide - ISV Usage](developer-guide.md#isv-usage) for details.

### Can I integrate with external systems?

Yes! Common integrations:
- Slack notifications (plugin available)
- Splunk/Datadog (custom export)
- Custom webhooks (via plugin)
- Event bus subscriptions

See [Integration Guide](integration-guide.md) for details.

### Can I query logs programmatically?

Yes! Logs are standard Salesforce objects:

```apex
List<Log__c> recentErrors = [
    SELECT Id, TotalLogEntries__c, TransactionId__c
    FROM Log__c
    WHERE LoggedByUsername__c = :UserInfo.getUserName()
    AND TotalERRORs__c > 0
    ORDER BY CreatedDate DESC
    LIMIT 10
];
```

See [Advanced Patterns](advanced-patterns.md#querying-logs) for details.

---

## Migration & Alternatives

### How do I migrate from custom logging?

See [Migration Guide - Custom Logging](migrations/migrate-from-custom-logging.md) for step-by-step instructions.

### How does Logger compare to Event Monitoring?

| Feature | Logger | Event Monitoring |
|---------|--------|------------------|
| **Cost** | Free | Requires Shield |
| **Customization** | Full control | Limited |
| **Retention** | Configurable | 30 days |
| **Query** | SOQL | Event Log File API |
| **Real-time** | Yes | Delayed |

**Use both:** Event Monitoring for platform events, Logger for application logging.

See [Alternatives](alternatives.md) for complete comparison.

---

## Getting Help

### Where can I find more help?

- 📚 **Documentation** - [Complete guides](overview.md)
- 💬 **GitHub Discussions** - [Ask questions](https://github.com/jongpie/NebulaLogger/discussions)
- 🐛 **GitHub Issues** - [Report bugs](https://github.com/jongpie/NebulaLogger/issues)
- 📖 **Wiki** - [Additional resources](https://github.com/jongpie/NebulaLogger/wiki)

### How do I report a bug?

1. Check [existing issues](https://github.com/jongpie/NebulaLogger/issues)
2. Gather details (version, package type, error messages)
3. Create a [new issue](https://github.com/jongpie/NebulaLogger/issues/new) with:
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots/logs if applicable

### How do I request a feature?

1. Check [existing discussions](https://github.com/jongpie/NebulaLogger/discussions)
2. Search for similar requests
3. Create a new discussion with:
   - Use case description
   - Proposed solution
   - Why it benefits the community

---

## Quick Reference

**Common Commands:**
```apex
// Basic logging
Logger.info('Message');
Logger.saveLog();

// With context
Logger.error('Error occurred')
    .setRecord(myRecord)
    .setExceptionDetails(e)
    .addTag('critical');
Logger.saveLog();

// Scenario tracking
Logger.setScenario('My Business Process');
Logger.info('Step 1 complete');
Logger.info('Step 2 complete');
Logger.saveLog();

// Change save method
Logger.saveLog(Logger.SaveMethod.REST);
```

**Common Settings:**
```apex
// Enable/disable
LoggerSettings__c.IsEnabled__c = true;
LoggerSettings__c.IsSavingEnabled__c = true;

// Log level
LoggerSettings__c.LoggingLevel__c = 'INFO';

// Save method
LoggerSettings__c.DefaultSaveMethod__c = 'EVENT_BUS';
```

---

**Still have questions?** Check the [complete documentation](overview.md) or [ask on GitHub](https://github.com/jongpie/NebulaLogger/discussions)!
