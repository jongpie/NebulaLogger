# Administrator Guide

Complete guide for Salesforce administrators configuring and managing Nebula Logger.

## Table of Contents

- [Installation](#installation)
- [Initial Configuration](#initial-configuration)
- [User Access](#user-access)
- [Logger Settings](#logger-settings)
- [Custom Metadata Configuration](#custom-metadata-configuration)
- [Data Management](#data-management)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

## Installation

See the [Installation Guide](installation.md) for detailed installation instructions.

### Post-Installation Steps

1. **Assign Permission Sets**
   - Navigate to **Setup → Users → Permission Sets**
   - Assign **Logger End User** to all users who should log
   - Assign **Logger Admin** to administrators

2. **Verify Installation**
   - Open **App Launcher → Logger Console**
   - Check that all tabs are visible (Logs, Log Entries, Logger Tags, Logger Scenarios)
   - Run a test log: Execute Anonymous Apex
   ```apex
   Logger.info('Installation test');
   Logger.saveLog();
   ```
   - Verify the log appears in the Logs tab

3. **Review Default Settings**
   - Navigate to **Setup → Custom Settings → Logger Settings**
   - Review organization defaults

## Initial Configuration

### 1. Organization-Level Settings

Navigate to **Setup → Custom Settings → Logger Settings → Manage**

Click **New** to create organization-level defaults:

| Setting | Recommended Value | Description |
|---------|------------------|-------------|
| **Is Enabled** | ✅ Checked | Enables logging org-wide |
| **Logging Level** | INFO | Minimum level to log (ERROR/WARN/INFO/DEBUG/FINE/FINER/FINEST) |
| **Is Apex System Debug Logging Enabled** | ✅ Checked | Also writes to System.debug() |
| **Is Anonymous Mode Enabled** | ❌ Unchecked | Anonymizes user information (for privacy) |
| **Is Data Masking Enabled** | ✅ Checked | Masks sensitive data (SSN, credit cards) |
| **Default Save Method** | EVENT_BUS | How logs are saved (EVENT_BUS/QUEUEABLE/REST/SYNCHRONOUS_DML) |

### 2. Profile-Level Settings

Override org defaults for specific profiles:

1. Click **New** from the Hierarchy Settings page
2. Select **Profile**
3. Choose a profile (e.g., System Administrator)
4. Override specific settings
5. Save

**Example:** Enable DEBUG logging for admins:
- Profile: System Administrator
- Logging Level: DEBUG

### 3. User-Level Settings

Override for individual users (useful for troubleshooting):

1. Click **New** from the Hierarchy Settings page
2. Select **User**
3. Choose a user
4. Override specific settings (e.g., enable DEBUG level)
5. Save

**Pro Tip:** Use user-level settings temporarily when helping users troubleshoot issues.

## User Access

### Permission Sets

**Logger End User**
- Read access to Logger objects
- Ability to create logs
- View their own logs

**Logger Admin**
- All End User permissions
- Modify all logs
- Configure Logger settings
- Manage custom metadata
- Delete logs

### Object Permissions

| Object | End User | Admin |
|--------|----------|-------|
| Log__c | Read (own records) | CRUD (all records) |
| LogEntry__c | Read (via Log__c) | CRUD (all records) |
| LoggerTag__c | Read | CRUD |
| LogEntryTag__c | Read | CRUD |
| LoggerScenario__c | Read | CRUD |

### Sharing Settings

**Organization-Wide Defaults:**
- Log__c: Private (users see only their own logs)
- LoggerTag__c: Public Read Only
- LoggerScenario__c: Public Read Only

**Sharing Rules (Optional):**

Create sharing rules to give teams access to related logs:

1. **Support Team Rule**
   - Share logs tagged with "customer-issue" with Support queue
   - Criteria: LogEntryTag__c.Tag__r.Name = "customer-issue"

2. **Integration Team Rule**
   - Share logs with scenario "Integration Error" with Integration team
   - Criteria: Log__c.TransactionScenario__r.Name CONTAINS "Integration"

## Logger Settings

### Hierarchy Settings (LoggerSettings__c)

Configured via **Setup → Custom Settings → Logger Settings**

#### Core Settings

**Is Enabled** (`IsEnabled__c`)
- Globally enable/disable logging
- When disabled, no logs are created
- Use this for emergency "kill switch"

**Logging Level** (`LoggingLevel__c`)
- Minimum level to log: ERROR, WARN, INFO, DEBUG, FINE, FINER, FINEST
- More verbose = more logs = more storage
- Production recommendation: INFO
- Troubleshooting: DEBUG

**Default Save Method** (`DefaultSaveMethod__c`)
- EVENT_BUS (default): Async via platform events
- QUEUEABLE: Async via queueable Apex
- REST: REST API callout
- SYNCHRONOUS_DML: Immediate DML (impacts performance)

#### Feature Flags

**Is Anonymous Mode Enabled** (`IsAnonymousModeEnabled__c`)
- Hides user information from logs
- Use for privacy-sensitive scenarios
- Logs show "Anonymous" instead of user details

**Is Apex System Debug Logging Enabled** (`IsApexSystemDebugLoggingEnabled__c`)
- Also writes log entries to System.debug()
- Useful for seeing logs in debug logs
- Disable in high-volume scenarios

**Is Console Logging Enabled** (`IsJavaScriptConsoleLoggingEnabled__c`)
- LWC/Aura logs also written to browser console
- Useful for development
- Disable in production

**Is Data Masking Enabled** (`IsDataMaskingEnabled__c`)
- Enables data masking rules
- Masks credit cards, SSNs, custom patterns
- **Always enable in production**

#### Additional Settings

**Default Scenario** (`DefaultScenario__c`)
- Set a default scenario if none specified
- Example: "General Application"

**Send Error Email Notifications** (`SendErrorEmailNotifications__c`)
- Email admins when Logger itself encounters errors
- Notification Email Addresses: comma-separated list

### Custom Metadata Configuration

#### Logger Parameters (LoggerParameter__mdt)

Navigate to **Setup → Custom Metadata Types → Logger Parameters**

Key parameters to configure:

**ENABLE_TAGGING**
- Enable/disable tagging system
- Default: true

**NORMALIZE_SCENARIO_DATA**
- Auto-create LoggerScenario__c records
- Default: true

**REQUIRE_SCENARIO_USAGE**
- Force developers to set a scenario
- Default: false
- Set to true to enforce scenario usage

**USE_FIRST_SCENARIO_FOR_TRANSACTION**
- First scenario becomes TransactionScenario
- Default: true

**STORAGE_LOCATION**
- Where to store logs: CUSTOM_OBJECTS, BIG_OBJECTS, etc.
- Default: CUSTOM_OBJECTS

#### Tag Rules (LogEntryTagRule__mdt)

Auto-apply tags based on field values.

**Example 1: Tag payment-related logs**
1. Navigate to **Setup → Custom Metadata Types → Log Entry Tag Rules**
2. Click **New**
3. Configure:
   - Label: Payment Tag Rule
   - Logger SObject: Log Entry
   - Field: Message__c
   - Comparison Type: CONTAINS
   - Comparison Value: payment
   - Tags: payment, financial (one per line)
   - Is Enabled: ✅ Checked
4. Save

**Example 2: Tag errors**
1. Click **New**
2. Configure:
   - Label: Error Tag Rule
   - Logger SObject: Log Entry
   - Field: LoggingLevel__c
   - Comparison Type: EQUALS
   - Comparison Value: ERROR
   - Tags: error, requires-attention
   - Is Enabled: ✅ Checked
3. Save

#### Scenario Rules (LoggerScenarioRule__mdt)

Change Logger behavior based on scenario.

**Example: Enable data masking for PII scenarios**
1. Navigate to **Setup → Custom Metadata Types → Logger Scenario Rules**
2. Click **New**
3. Configure:
   - Label: PII Processing Rule
   - Scenario Name: PII Processing
   - Is Data Masking Enabled: TRUE
   - Is Anonymous Mode Enabled: TRUE
4. Save

Now when developers use:
```apex
Logger.setScenario('PII Processing');
```
Data masking and anonymous mode are automatically enabled.

#### Data Mask Rules (LogEntryDataMaskRule__mdt)

Built-in rules include:
- Credit card numbers
- Social Security Numbers
- Email addresses

**Add Custom Mask Rule:**
1. Navigate to **Setup → Custom Metadata Types → Log Entry Data Mask Rules**
2. Click **New**
3. Configure:
   - Label: Phone Number Masking
   - Regex Pattern: `\d{3}-\d{3}-\d{4}`
   - Replacement String: `XXX-XXX-XXXX`
   - Is Enabled: ✅ Checked
4. Save

## Data Management

### Storage Considerations

Each log entry includes:
- Log message (up to 131,072 characters)
- Stack trace
- Exception details
- Record JSON
- Metadata (user, timestamp, class, method, line)

**Estimate storage:**
- Average log entry: 5-10 KB
- 10,000 logs/day = 50-100 MB/day = 1.5-3 GB/month
- Monitor storage via **Setup → System Overview**

### Log Retention

Implement retention policies to manage storage:

#### Option 1: Logger Retention Plugin

Install the **Log Retention Rules** plugin (available in unlocked package):

1. Define retention rules by log level:
   - FINEST/FINER/FINE: 7 days
   - DEBUG: 14 days
   - INFO: 30 days
   - WARN: 60 days
   - ERROR: 90 days

2. Schedule batch job to delete old logs

#### Option 2: Manual Deletion

Create a scheduled batch class:

```apex
global class LogCleanupBatch implements Database.Batchable<SObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Delete logs older than 90 days
        return Database.getQueryLocator([
            SELECT Id FROM Log__c 
            WHERE CreatedDate < :Date.today().addDays(-90)
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<Log__c> scope) {
        delete scope;
    }
    
    global void finish(Database.BatchableContext bc) {
        // Schedule next run
    }
}
```

Schedule:
```apex
LogCleanupBatch batch = new LogCleanupBatch();
Database.executeBatch(batch, 200);
```

#### Option 3: Big Object Archiving

Use the **Big Object Archiving** plugin to archive old logs to Big Objects:
- Keeps historical data
- Reduces custom object storage
- Queryable via SOQL

### Bulk Delete Logs

Use the **Log Batch Purge** component:

1. Open **Logger Console**
2. Click **Log Batch Purge** tab
3. Select criteria:
   - Date range
   - Logging level
   - Scenario
4. Click **Delete**

**⚠️ Warning:** Deleted logs cannot be recovered. Always test with a small batch first.

## Monitoring

### Reports and Dashboards

#### Recommended Reports

**1. Error Log Report**
```
Report Type: Log Entries
Filters:
  - Logging Level = ERROR
  - Created Date = THIS_MONTH
Columns: Timestamp, Message, User, Origin Location, Exception Message
```

**2. Logs by Scenario**
```
Report Type: Logs
Group By: Transaction Scenario
Filters: Created Date = THIS_WEEK
Summary: Count of Logs
```

**3. Top Tags**
```
Report Type: Log Entry Tags
Group By: Logger Tag Name
Summary: Count of Log Entry Tags
Filters: Created Date = LAST_N_DAYS:30
```

**4. Logs by User**
```
Report Type: Logs
Group By: Logged By
Filters: Created Date = TODAY
Summary: Count of Logs
```

#### Sample Dashboard

Create a dashboard with:
- **Errors This Week** (metric)
- **Logs by Level** (pie chart)
- **Logs Over Time** (line chart)
- **Top 10 Scenarios** (horizontal bar)
- **Top 10 Tags** (horizontal bar)
- **Recent Errors** (table)

### Alerts

Create alerts for critical conditions:

**Process Builder Alert: Critical Errors**
1. Object: Log Entry
2. Criteria: Logging Level = ERROR AND Tags CONTAINS "critical"
3. Action: Send email to admin team

**Flow Alert: High Volume Logging**
1. Schedule: Daily
2. Query: Count Log__c WHERE CreatedDate = TODAY
3. Decision: Count > 10,000
4. Action: Send alert email

### Health Check

Regular health check tasks:

**Weekly:**
- [ ] Review error logs
- [ ] Check storage usage
- [ ] Verify retention is running

**Monthly:**
- [ ] Review tag usage
- [ ] Audit scenario names
- [ ] Check user adoption
- [ ] Verify data masking is working

**Quarterly:**
- [ ] Review retention policies
- [ ] Update tag rules
- [ ] Train new users
- [ ] Review performance

## Troubleshooting

### Logs Not Appearing

**Check 1: Is Logger Enabled?**
```apex
LoggerSettings__c settings = LoggerSettings__c.getInstance();
System.debug('Logger Enabled: ' + settings.IsEnabled__c);
System.debug('Logging Level: ' + settings.LoggingLevel__c);
```

**Check 2: Platform Events**
- Navigate to **Setup → Platform Events → LogEntryEvent**
- Check **Event Delivery** metrics
- Verify events are being published and delivered

**Check 3: User Permissions**
- Verify user has **Logger End User** permission set
- Check object permissions on Log__c and LogEntry__c

**Check 4: Triggers Enabled**
- Verify LogEntryEventTrigger is active
- Check for trigger errors in debug logs

### Performance Issues

**Symptom: Slow save times**

**Solution 1:** Use async save method (default)
```apex
Logger.saveLog();  // EVENT_BUS is async
```

**Solution 2:** Reduce logging level
- Change from DEBUG to INFO in production
- Use DEBUG only for troubleshooting

**Solution 3:** Batch log entries
```apex
// Don't save in loops
for (Account acc : accounts) {
    Logger.debug('Processing: ' + acc.Id);
    // Don't call saveLog() here!
}
Logger.saveLog();  // Save once after loop
```

### Storage Warnings

**Symptom: Running out of data storage**

**Solution 1:** Implement retention
- Delete old logs (see [Data Management](#data-management))

**Solution 2:** Reduce logging volume
- Increase minimum logging level
- Disable DEBUG/FINE logging in production

**Solution 3:** Archive to Big Objects
- Install Big Object Archiving plugin
- Move old logs to Big Objects

### Tag Rules Not Working

**Check 1:** Verify rule is enabled
- Navigate to **Setup → Custom Metadata Types → Log Entry Tag Rules**
- Check **Is Enabled** checkbox

**Check 2:** Test comparison logic
- Verify field name is correct
- Test regex pattern if using MATCHES_REGEX
- Check for case sensitivity

**Check 3:** Review trigger execution
- Enable debug logs
- Look for "Nebula Logger" debug statements
- Verify TagEngine is executing

## Best Practices for Admins

### 1. Start Restrictive, Relax Later

- Start with INFO level logging
- Enable DEBUG only for troubleshooting
- Use user-level overrides for specific users

### 2. Monitor Storage Regularly

- Set up storage alerts
- Implement retention policies early
- Archive to Big Objects if needed

### 3. Standardize Scenarios and Tags

- Create a wiki page with approved scenarios
- Define tag taxonomy
- Train developers on conventions

### 4. Use Scenario Rules for Governance

- Enable data masking for PII scenarios
- Control logging levels per scenario
- Enforce anonymous mode when needed

### 5. Regular Cleanup

- Schedule regular log deletion
- Review and clean up unused tags
- Archive old scenarios

### 6. Security First

- Always enable data masking in production
- Review logs for sensitive data exposure
- Set appropriate sharing rules
- Audit log access regularly

## Next Steps

- [Configuration Reference](configuration-reference.md) - Complete settings reference
- [Security Guide](security.md) - Securing your logs
- [Troubleshooting](troubleshooting.md) - Detailed troubleshooting
- [Performance Guide](performance.md) - Optimization strategies
