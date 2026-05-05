# Logger Scenarios Guide

Complete guide to tracking business processes and execution contexts with Logger Scenarios.

## Overview

Scenarios identify **what business process or context** is currently executing. They help you group related log entries and understand the flow of execution through your application.

### Scenarios vs Tags

| Feature | Scenarios | Tags |
|---------|-----------|------|
| **Purpose** | Track business process/context | Categorize and filter |
| **Cardinality** | One per log entry | Many per log entry |
| **Relationship** | Lookup field | Many-to-many junction |
| **Behavior Impact** | Can change Logger settings | Metadata only |
| **Example** | "Order Processing", "User Registration" | "payment", "critical", "api-error" |

**Rule of thumb:**
- **Scenario** = "What am I doing?" (the business process)
- **Tags** = "What characteristics does this have?" (categorization)

See [Tagging Guide](tagging-guide.md) for more on tags.

## How Scenarios Work

### Data Model

**LoggerScenario__c** - Unique scenario records
- Name: "Order Processing"
- UniqueId__c: Used for upsert (same as Name)
- TotalLogEntries__c: Rollup count

**Scenario Fields on Logs:**
- `Log__c.TransactionScenario__c` → LoggerScenario__c (lookup)
- `LogEntry__c.EntryScenario__c` → LoggerScenario__c (lookup)

### Transaction vs Entry Scenarios

Scenarios work at two levels:

**Transaction Scenario** (`Log__c.TransactionScenario__c`)
- The **first** scenario set in a transaction
- Applies to the entire `Log__c` record
- Represents the main business process

**Entry Scenario** (`LogEntry__c.EntryScenario__c`)
- The **current** scenario when each entry is logged
- Can change during transaction execution
- Represents the specific step or sub-process

### Example

```apex
Logger.setScenario('Order Processing');  // First scenario
Logger.info('Starting order processing');  // EntryScenario = 'Order Processing'

Logger.setScenario('Payment Validation');  // Change scenario
Logger.debug('Validating payment method');  // EntryScenario = 'Payment Validation'

Logger.setScenario('Inventory Check');     // Change again
Logger.debug('Checking inventory levels'); // EntryScenario = 'Inventory Check'

Logger.saveLog();
// Result:
// - Log__c.TransactionScenario__c = 'Order Processing' (first scenario)
// - LogEntry__c #1: EntryScenario__c = 'Order Processing'
// - LogEntry__c #2: EntryScenario__c = 'Payment Validation'
// - LogEntry__c #3: EntryScenario__c = 'Inventory Check'
```

## Setting Scenarios

### In Apex

**Basic usage:**
```apex
Logger.setScenario('User Registration');
Logger.info('User registration started');
Logger.saveLog();
```

**Multi-step process:**
```apex
public void processOrder(Order__c order) {
    Logger.setScenario('Order Processing');
    Logger.info('Order processing started').setRecord(order);
    
    try {
        // Step 1: Validation
        Logger.setScenario('Order Validation');
        validateOrder(order);
        Logger.info('Order validation completed');
        
        // Step 2: Payment
        Logger.setScenario('Payment Processing');
        processPayment(order);
        Logger.info('Payment processing completed');
        
        // Step 3: Fulfillment
        Logger.setScenario('Order Fulfillment');
        fulfillOrder(order);
        Logger.info('Order fulfillment completed');
        
    } catch (Exception e) {
        Logger.error('Order processing failed')
            .setExceptionDetails(e)
            .setRecord(order);
    } finally {
        Logger.saveLog();
    }
}
```

**Getting current scenario:**
```apex
String currentScenario = Logger.getScenario();
Logger.info('Current scenario: ' + currentScenario);
```

### In Lightning Web Components

```javascript
import { LightningElement } from 'lwc';
import { getLogger } from 'c/logger';

export default class CheckoutComponent extends LightningElement {
    logger = getLogger();

    async handleCheckout() {
        this.logger.setScenario('Checkout Process');
        this.logger.info('Checkout initiated');

        try {
            this.logger.setScenario('Cart Validation');
            await this.validateCart();
            
            this.logger.setScenario('Payment Processing');
            await this.processPayment();
            
            this.logger.setScenario('Order Creation');
            await this.createOrder();
            
            this.logger.info('Checkout completed successfully');
        } catch (error) {
            this.logger.error('Checkout failed')
                .setExceptionDetails(error);
        } finally {
            this.logger.saveLog();
        }
    }
}
```

### In Aura Components

```javascript
var logger = component.find('logger');

logger.setScenario('Data Loading');
logger.info('Loading data for component');

// ... load data ...

logger.saveLog();
```

### In Flow

1. Add the **Set Scenario** action (if available in your Flow version)
2. Or use the **Add Log Entry** action with a specific naming convention
3. Use consistent scenario names across your flows

**Note:** Flow support for scenarios may vary by Logger version.

## Scenario Naming Conventions

### Recommended Patterns

**✅ Use Title Case:**
```apex
Logger.setScenario('Order Processing');     // Good
Logger.setScenario('order processing');     // Avoid
Logger.setScenario('ORDER_PROCESSING');     // Avoid
```

**✅ Be Specific but Not Too Specific:**
```apex
// Good - describes the business process
Logger.setScenario('User Registration');
Logger.setScenario('Opportunity Sync');
Logger.setScenario('Invoice Generation');

// Too generic - not useful
Logger.setScenario('Processing');
Logger.setScenario('Update');

// Too specific - creates too many scenarios
Logger.setScenario('Opportunity Sync - Account ABC123');
Logger.setScenario('Invoice Generation - Invoice INV-0001');
```

**✅ Use Noun Phrases:**
```apex
Logger.setScenario('Payment Processing');       // Good
Logger.setScenario('Data Migration');           // Good
Logger.setScenario('Process Payment');          // Less clear
Logger.setScenario('Migrating Data');           // Less clear
```

**✅ Be Consistent:**
```apex
// Pick one style and stick with it
Logger.setScenario('Order Processing');
Logger.setScenario('Payment Processing');
Logger.setScenario('Inventory Management');

// Don't mix styles
Logger.setScenario('Order Processing');
Logger.setScenario('Process Payment');          // Inconsistent
Logger.setScenario('Managing Inventory');       // Inconsistent
```

### Categories of Scenarios

**Business Processes:**
```apex
Logger.setScenario('Quote Generation');
Logger.setScenario('Contract Renewal');
Logger.setScenario('Lead Conversion');
Logger.setScenario('Opportunity Closure');
```

**User Workflows:**
```apex
Logger.setScenario('User Onboarding');
Logger.setScenario('Password Reset');
Logger.setScenario('Profile Update');
Logger.setScenario('Preference Management');
```

**Integration Processes:**
```apex
Logger.setScenario('Salesforce to NetSuite Sync');
Logger.setScenario('External API Integration');
Logger.setScenario('Data Import');
Logger.setScenario('Data Export');
```

**Batch Operations:**
```apex
Logger.setScenario('Account Cleanup Batch');
Logger.setScenario('Invoice Generation Batch');
Logger.setScenario('Daily Sync Batch');
```

**System Processes:**
```apex
Logger.setScenario('Scheduled Job Execution');
Logger.setScenario('Trigger Processing');
Logger.setScenario('Async Processing');
```

## Scenario Rules

Scenario rules (`LoggerScenarioRule__mdt`) change Logger behavior based on the current scenario.

### Use Cases for Scenario Rules

1. **Enable data masking for sensitive processes**
2. **Change logging levels for specific scenarios**
3. **Enable anonymous mode for privacy**
4. **Control where logs are stored**

### Example 1: Enable Data Masking for PII

**Setup → Custom Metadata Types → Logger Scenario Rules → New**

```
Label: PII Processing Rule
Scenario Name: PII Processing
Is Data Masking Enabled: TRUE
Is Anonymous Mode Enabled: TRUE
Is Enabled: ✓
```

**Usage:**
```apex
Logger.setScenario('PII Processing');  // Automatically enables data masking
Logger.info('Processing sensitive customer data');
Logger.saveLog();
```

### Example 2: Verbose Logging for Troubleshooting

```
Label: Debug Scenario
Scenario Name: Troubleshooting Investigation
Logging Level: DEBUG
Is Apex System Debug Logging Enabled: TRUE
Is Enabled: ✓
```

**Usage:**
```apex
Logger.setScenario('Troubleshooting Investigation');  // Enables DEBUG level
Logger.debug('Detailed diagnostic information');      // Now logged
Logger.finest('Very detailed trace');                 // Still filtered out
Logger.saveLog();
```

### Example 3: Store Integration Logs Separately

```
Label: Integration Logs
Scenario Name: External API Integration
Platform Event Storage Location: BIG_OBJECT
Is Enabled: ✓
```

**Usage:**
```apex
Logger.setScenario('External API Integration');  // Logs go to Big Object
Logger.info('API call initiated');
Logger.saveLog();
```

### Scenario Rule Fields

| Field | Description | Example |
|-------|-------------|---------|
| **Scenario Name** | Exact scenario name to match | "PII Processing" |
| **Is Logger Enabled** | Enable/disable Logger | TRUE/FALSE |
| **Is Anonymous Mode Enabled** | Hide user info | TRUE/FALSE |
| **Is Apex System Debug Logging Enabled** | Also write to System.debug() | TRUE/FALSE |
| **Is Data Masking Enabled** | Enable data masking | TRUE/FALSE |
| **Is JavaScript Console Logging Enabled** | LWC console.log() | TRUE/FALSE |
| **Logging Level** | Minimum level to log | ERROR/WARN/INFO/DEBUG/FINE |
| **Platform Event Storage Location** | Where to store logs | CUSTOM_OBJECTS/BIG_OBJECTS |

## Querying by Scenario

### Find Logs by Transaction Scenario

```apex
// All logs for 'Order Processing'
List<Log__c> orderLogs = [
    SELECT Id, TransactionScenario__r.Name, StartTime__c, TotalLogEntries__c
    FROM Log__c
    WHERE TransactionScenario__r.Name = 'Order Processing'
    AND StartTime__c = LAST_N_DAYS:7
    ORDER BY StartTime__c DESC
];
```

### Find Log Entries by Entry Scenario

```apex
// All entries for 'Payment Processing' scenario
List<LogEntry__c> paymentEntries = [
    SELECT Id, Message__c, Timestamp__c, LoggingLevel__c
    FROM LogEntry__c
    WHERE EntryScenario__r.Name = 'Payment Processing'
    AND Timestamp__c = THIS_WEEK
    ORDER BY Timestamp__c DESC
];
```

### Count Logs by Scenario

```apex
// Top scenarios by volume
AggregateResult[] results = [
    SELECT TransactionScenario__r.Name scenario, COUNT(Id) logCount
    FROM Log__c
    WHERE CreatedDate = LAST_N_DAYS:30
    GROUP BY TransactionScenario__r.Name
    ORDER BY COUNT(Id) DESC
    LIMIT 10
];

for (AggregateResult ar : results) {
    System.debug(ar.get('scenario') + ': ' + ar.get('logCount'));
}
```

### Find Errors in a Scenario

```apex
// All errors in 'Opportunity Sync' scenario
List<LogEntry__c> syncErrors = [
    SELECT Id, Message__c, ExceptionMessage__c, Timestamp__c
    FROM LogEntry__c
    WHERE EntryScenario__r.Name = 'Opportunity Sync'
    AND LoggingLevel__c = 'ERROR'
    AND Timestamp__c = TODAY
];
```

## Scenario Management

### Viewing Scenarios

Navigate to **App Launcher → Logger Console → Logger Scenarios**

Each scenario shows:
- Name
- Total logs (rollup)
- Total log entries (rollup)
- Created date
- Last modified date

### Editing Scenarios

You can add descriptions to scenarios:

1. Open a LoggerScenario__c record
2. Edit custom fields (if you've added any)
3. Add a Description field to document the scenario's purpose
4. Save

### Deleting Scenarios

**⚠️ Warning:** Deleting a LoggerScenario__c removes the lookup relationship from Log__c and LogEntry__c records.

Only delete scenarios that are:
- Test/development scenarios
- No longer in use
- Typos/mistakes

**Alternative:** Instead of deleting, add a Description like "DEPRECATED - no longer used"

### Renaming Scenarios

To rename a scenario (e.g., fix a typo):

```apex
// Update the LoggerScenario__c record
LoggerScenario__c scenario = [
    SELECT Id, Name 
    FROM LoggerScenario__c 
    WHERE Name = 'Oppertunity Sync'  // Typo
    LIMIT 1
];

scenario.Name = 'Opportunity Sync';  // Fixed
update scenario;

// Historical logs will now show the corrected name
```

## Best Practices

### 1. Set Scenario Early

```apex
// ✅ Good: Set at the beginning
public void processOrder(Order__c order) {
    Logger.setScenario('Order Processing');  // Set first
    Logger.info('Starting order processing');
    // ... business logic ...
    Logger.saveLog();
}

// ❌ Bad: Set too late or not at all
public void processOrder(Order__c order) {
    Logger.info('Starting order processing');  // No scenario yet
    Logger.setScenario('Order Processing');    // Too late
    Logger.saveLog();
}
```

### 2. Use Scenarios to Trace Multi-Step Processes

```apex
Logger.setScenario('Data Migration');
Logger.info('Migration started: ' + records.size() + ' records');

Logger.setScenario('Data Validation');
Integer validCount = validateRecords(records);
Logger.info('Validation complete: ' + validCount + ' valid');

Logger.setScenario('Data Transformation');
transformRecords(records);
Logger.info('Transformation complete');

Logger.setScenario('Data Load');
insertRecords(records);
Logger.info('Load complete');

Logger.saveLog();
// Can now trace the entire migration flow
```

### 3. Combine with Tags

```apex
Logger.setScenario('Payment Processing');  // What process
Logger.info('Payment initiated')
    .setRecord(payment)
    .addTag('payment')      // What feature
    .addTag('stripe')       // What system
    .addTag('user-action'); // What type

// Scenario = process context
// Tags = categorization dimensions
```

### 4. Document Your Scenarios

Create a wiki page listing approved scenarios:

```markdown
# Logger Scenarios

## Business Processes
- **Order Processing** - End-to-end order processing workflow
- **Quote Generation** - CPQ quote generation process
- **Contract Renewal** - Contract renewal workflow

## Integrations
- **Salesforce to NetSuite Sync** - SF → NS data sync
- **External API Integration** - General API integrations
- **Data Import** - Bulk data imports
```

### 5. Use Scenario Rules for Governance

```apex
// Define rule: "Payment Processing" requires data masking
// In code:
Logger.setScenario('Payment Processing');  // Data masking auto-enabled
Logger.info('Credit card: ' + cc);         // Automatically masked
```

### 6. Don't Over-Use Scenarios

```apex
// ❌ Bad: Changing scenario too frequently
Logger.setScenario('Method1');
Logger.info('In method 1');
Logger.setScenario('Method2');
Logger.info('In method 2');
Logger.setScenario('Method3');
Logger.info('In method 3');

// ✅ Good: One scenario per business process
Logger.setScenario('Order Processing');
Logger.info('Step 1: Validation');
Logger.info('Step 2: Payment');
Logger.info('Step 3: Fulfillment');
```

### 7. Query by Scenario in Reports

Create reports grouped by scenario:

**Report: Logs by Scenario (Last 7 Days)**
```
Report Type: Logs
Group By: Transaction Scenario
Filters: Created Date = LAST_N_DAYS:7
Summary: Count of Logs
Columns: Scenario Name, Log Count, Error Count
```

## Common Patterns

### Pattern 1: Multi-Phase Process

```apex
public void syncOpportunities(List<Opportunity> opps) {
    Logger.setScenario('Opportunity Sync');
    Logger.info('Sync started: ' + opps.size() + ' opportunities');
    
    Logger.setScenario('Opportunity Validation');
    List<Opportunity> validOpps = validateOpportunities(opps);
    Logger.info('Validation complete: ' + validOpps.size() + ' valid');
    
    Logger.setScenario('Opportunity Export');
    exportToNetSuite(validOpps);
    Logger.info('Export complete');
    
    Logger.saveLog();
}
```

### Pattern 2: Nested Scenarios

```apex
public void processLargeFile() {
    Logger.setScenario('File Processing');
    Logger.info('File processing started');
    
    Logger.setScenario('File Parsing');
    List<Record> records = parseFile();
    Logger.info('Parsed ' + records.size() + ' records');
    
    for (Record rec : records) {
        Logger.setScenario('Record Validation');  // Per-record scenario
        if (validateRecord(rec)) {
            Logger.setScenario('Record Processing');
            processRecord(rec);
        }
    }
    
    Logger.setScenario('File Processing');  // Back to main scenario
    Logger.info('File processing complete');
    Logger.saveLog();
}
```

### Pattern 3: Conditional Scenarios

```apex
public void smartProcess(SObject record) {
    // Set scenario based on record type
    if (record.getSObjectType() == Account.SObjectType) {
        Logger.setScenario('Account Processing');
    } else if (record.getSObjectType() == Opportunity.SObjectType) {
        Logger.setScenario('Opportunity Processing');
    } else {
        Logger.setScenario('Generic Record Processing');
    }
    
    Logger.info('Processing: ' + record.Id);
    // ... process record ...
    Logger.saveLog();
}
```

## Troubleshooting

### Scenario Not Appearing

**Check 1:** Verify the scenario was set before logging:
```apex
Logger.setScenario('Test Scenario');  // Must come first
Logger.info('Test message');
Logger.saveLog();
```

**Check 2:** Check LoggerParameter__mdt `NORMALIZE_SCENARIO_DATA`:
- Navigate to **Setup → Custom Metadata Types → Logger Parameters**
- Find `NORMALIZE_SCENARIO_DATA`
- Ensure it's set to `true`

**Check 3:** Query the LoggerScenario__c object:
```apex
List<LoggerScenario__c> scenarios = [SELECT Id, Name FROM LoggerScenario__c];
System.debug('Scenarios: ' + scenarios);
```

### Scenario Rule Not Applying

**Check 1:** Verify exact scenario name match:
- Scenario rules match on exact `Name`
- Case-sensitive
- Must be character-for-character identical

**Check 2:** Verify rule is enabled:
- **Setup → Custom Metadata Types → Logger Scenario Rules**
- Check **Is Enabled** checkbox

**Check 3:** Check debug logs:
```apex
Logger.setScenario('PII Processing');
System.debug('Current settings: ' + Logger.getUserSettings());
```

## Next Steps

- [Tagging Guide](tagging-guide.md) - Categorizing logs with tags
- [Best Practices](best-practices.md) - General logging patterns
- [Configuration Reference](configuration-reference.md) - Scenario rule options
- [Admin Guide](admin-guide.md) - Configuring scenarios
