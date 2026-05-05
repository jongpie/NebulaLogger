# Flow Guide

Complete guide to logging in Salesforce Flows and Process Builder with Nebula Logger.

## Table of Contents

- [Overview](#overview)
- [Available Actions](#available-actions)
- [Basic Usage](#basic-usage)
- [Logging Patterns](#logging-patterns)
- [Tagging](#tagging)
- [Scenarios](#scenarios)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

Nebula Logger provides invocable actions for use in Flow Builder and Process Builder, allowing you to capture logs without writing code.

### Benefits

- **No-code logging** - Add logging to flows without Apex
- **Debug production flows** - See what's happening in live flows
- **Track flow execution** - Understand flow paths and decisions
- **Capture errors** - Log flow faults and exceptions
- **Business context** - Track important business events

## Available Actions

Nebula Logger provides four invocable actions:

| Action | Class | Purpose |
|--------|-------|---------|
| **Add Log Entry** | `FlowLogEntry` | Log a simple message |
| **Add Log Entry for an SObject Record** | `FlowRecordLogEntry` | Log with a single record |
| **Add Log Entry for an SObject Record Collection** | `FlowCollectionLogEntry` | Log with multiple records |
| **Save Log** | `Logger` | Save all pending log entries |

### Action Details

**Add Log Entry**
- Basic logging action
- Accepts: Message, Logging Level, Tags, Scenario
- Use for: General flow milestones, decisions, errors

**Add Log Entry for an SObject Record**
- Logs with single record context
- Accepts: All basic fields + Record
- Use for: Record-specific operations

**Add Log Entry for an SObject Record Collection**
- Logs with multiple records
- Accepts: All basic fields + Record Collection
- Use for: Loop operations, bulk processing

**Save Log**
- Persists all log entries
- No inputs required
- Use at: End of flow, after errors, key milestones

## Basic Usage

### Simple Flow Logging

1. **Open Flow Builder**
   - Create or edit a flow

2. **Add "Add Log Entry" Action**
   - Click **+** to add an element
   - Select **Action**
   - Search for "Add Log Entry"
   - Select **Add Log Entry**

3. **Configure the Action**
   - **Label:** "Log Flow Start"
   - **Logging Level:** INFO
   - **Message:** "Order processing flow started"
   - **Tags:** (optional) "order-processing,flow"
   - **Scenario:** (optional) "Order Processing"

4. **Add "Save Log" Action**
   - Add another action
   - Search for "Save Log"
   - Select **Save Log**
   - **Label:** "Save Logs"

5. **Activate and Test**
   - Save and activate the flow
   - Run the flow
   - Check Logger Console for the log entry

### Flow with Record Context

**Scenario:** Log when an opportunity is updated

1. **Create Record-Triggered Flow**
   - Object: Opportunity
   - Trigger: Record is updated
   - Entry Conditions: Stage is changed

2. **Add "Add Log Entry for an SObject Record"**
   - **Label:** "Log Stage Change"
   - **Logging Level:** INFO
   - **Message:** Formula: `"Opportunity stage changed to " & {!$Record.StageName}`
   - **Record:** `{!$Record}`
   - **Tags:** "opportunity,stage-change"
   - **Scenario:** "Opportunity Management"

3. **Add "Save Log"**
   - Place at the end of the flow

4. **Result:**
   - Log created with opportunity record linked
   - Can query logs by opportunity ID
   - Full record details captured

## Logging Patterns

### Pattern 1: Log Flow Milestones

```
┌─────────────────────────────────────────────┐
│ Start                                       │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ Add Log Entry                               │
│ - Message: "Flow started"                   │
│ - Level: INFO                               │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ Get Records (Accounts)                      │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ Add Log Entry                               │
│ - Message: "Retrieved " & {!AccountCount} & │
│            " accounts"                      │
│ - Level: DEBUG                              │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ Loop through Accounts                       │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ Add Log Entry                               │
│ - Message: "Processing complete"            │
│ - Level: INFO                               │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ Save Log                                    │
└─────────────────────────────────────────────┘
```

### Pattern 2: Log Decision Branches

```
┌─────────────────────────────────────────────┐
│ Decision: Amount > 100000                   │
└────────┬────────────────────────┬───────────┘
         │                        │
    YES  │                        │  NO
         ▼                        ▼
┌────────────────────┐   ┌────────────────────┐
│ Add Log Entry      │   │ Add Log Entry      │
│ - Message:         │   │ - Message:         │
│   "High value"     │   │   "Standard value" │
│ - Level: INFO      │   │ - Level: DEBUG     │
│ - Tags: high-value │   │ - Tags: standard   │
└────────┬───────────┘   └────────┬───────────┘
         │                        │
         └────────┬───────────────┘
                  ▼
         ┌────────────────────┐
         │ Save Log           │
         └────────────────────┘
```

### Pattern 3: Log Errors with Fault Path

```
┌─────────────────────────────────────────────┐
│ Create Records                              │
└────────┬────────────────────────┬───────────┘
         │                        │
    SUCCESS                     FAULT
         │                        │
         ▼                        ▼
┌────────────────────┐   ┌────────────────────┐
│ Add Log Entry      │   │ Add Log Entry      │
│ - Message:         │   │ - Message:         │
│   "Records created"│   │   "Create failed:  │
│ - Level: INFO      │   │    {!$Flow.FaultMessage}│
│ - Tags: success    │   │ - Level: ERROR     │
└────────┬───────────┘   │ - Tags: error,     │
         │               │         critical   │
         │               └────────┬───────────┘
         │                        │
         └────────┬───────────────┘
                  ▼
         ┌────────────────────┐
         │ Save Log           │
         └────────────────────┘
```

### Pattern 4: Loop with Logging

```
┌─────────────────────────────────────────────┐
│ Get Records (Contacts)                      │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ Add Log Entry                               │
│ - Message: "Processing " & {!ContactCount}  │
│            " contacts"                      │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ Loop through Contacts                       │
└────────────┬────────────────────────────────┘
             │ (For each)
             ▼
┌─────────────────────────────────────────────┐
│ Update Record                               │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ Add Log Entry for an SObject Record         │
│ - Message: "Updated contact"                │
│ - Record: {!CurrentContact}                 │
└────────────┬────────────────────────────────┘
             │
             ▼ (After loop)
┌─────────────────────────────────────────────┐
│ Add Log Entry                               │
│ - Message: "Loop complete"                  │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ Save Log                                    │
└─────────────────────────────────────────────┘
```

## Tagging

### Adding Tags in Flow

Tags help categorize and filter log entries.

**Single Tag:**
```
Add Log Entry
- Message: "Payment processed"
- Tags: payment
```

**Multiple Tags (comma-separated):**
```
Add Log Entry
- Message: "Critical error occurred"
- Tags: error,critical,requires-investigation
```

**Tags from Formula:**
```
Add Log Entry
- Message: "Order processed"
- Tags: Formula: "order,team-" & {!$Record.Owner.Team__c}
Result: "order,team-sales"
```

### Tag Use Cases

**Feature Tags:**
```
- Tags: payment
- Tags: inventory
- Tags: authentication
```

**Priority Tags:**
```
- Tags: critical
- Tags: high-priority
- Tags: informational
```

**Process Tags:**
```
- Tags: nightly-batch
- Tags: scheduled-flow
- Tags: auto-update
```

**Team Tags:**
```
- Tags: team-sales
- Tags: team-support
- Tags: team-operations
```

## Scenarios

### Setting Scenarios

Scenarios identify the business process being executed.

**Basic Scenario:**
```
Add Log Entry
- Message: "Order validation started"
- Scenario: Order Processing
```

**Scenario per Stage:**
```
Flow Stage 1:
- Scenario: Order Validation

Flow Stage 2:
- Scenario: Payment Processing

Flow Stage 3:
- Scenario: Order Fulfillment
```

**Scenario from Variable:**
```
Add Log Entry
- Message: "Processing record"
- Scenario: Formula: "Batch Processing - " & {!BatchName}
```

### Scenario Naming

Use consistent scenario names:

✅ **Good:**
- "Order Processing"
- "Lead Conversion"
- "Contract Renewal"

❌ **Avoid:**
- "order processing" (lowercase)
- "Process-Order" (inconsistent format)
- "Order Processing for Account 001..." (too specific)

## Best Practices

### 1. Log Flow Entry and Exit

```
[Start]
    ↓
[Add Log Entry: "Flow started"]
    ↓
[Your flow logic]
    ↓
[Add Log Entry: "Flow completed"]
    ↓
[Save Log]
```

### 2. Log Important Decisions

```
[Decision: Opportunity Amount > $100,000]
    ↓
  YES → [Add Log Entry: "High-value opportunity" + Tag: high-value]
    ↓
   NO → [Add Log Entry: "Standard opportunity" + Tag: standard]
    ↓
[Save Log]
```

### 3. Always Log Errors in Fault Paths

```
[Create/Update Records]
    ↓
  FAULT → [Add Log Entry]
          - Message: "Error: {!$Flow.FaultMessage}"
          - Level: ERROR
          - Tags: error,critical
          ↓
          [Save Log]
```

### 4. Use Appropriate Logging Levels

| Level | When to Use in Flows |
|-------|---------------------|
| **ERROR** | Fault paths, validation failures |
| **WARN** | Potential issues, unusual conditions |
| **INFO** | Flow milestones, successful operations |
| **DEBUG** | Detailed diagnostic information |

### 5. Save Logs at Key Points

Save logs:
- ✅ At the end of the flow
- ✅ After error handling
- ✅ After important operations
- ❌ Not inside loops (save after loop completes)

### 6. Use Record Context When Available

```
✅ Good: Add Log Entry for an SObject Record
- Message: "Account updated"
- Record: {!$Record}

❌ Less useful: Add Log Entry
- Message: "Account " & {!$Record.Id} & " updated"
```

### 7. Don't Over-Log in Loops

```
❌ Bad:
Loop through 1000 records
    → Add Log Entry (creates 1000 entries!)
    → Save Log (1000 times!)

✅ Good:
Loop through 1000 records
    → Process records
After Loop
    → Add Log Entry: "Processed 1000 records"
    → Save Log (once)
```

### 8. Include Useful Context in Messages

```
❌ Generic:
- Message: "Flow completed"

✅ Specific:
- Message: "Order processing completed: " & 
           {!SuccessCount} & " succeeded, " & 
           {!FailureCount} & " failed"
```

## Flow Examples

### Example 1: Record-Triggered Flow (Before Save)

**Use Case:** Validate opportunity before save

```
Trigger: Opportunity, Before Save

[Start]
    ↓
[Add Log Entry]
    - Message: "Validating opportunity: {!$Record.Name}"
    - Level: DEBUG
    - Scenario: Opportunity Validation
    ↓
[Decision: Stage = Closed Won AND Amount = null]
    ↓
  YES → [Add Log Entry]
        - Message: "Validation failed: Amount required for Closed Won"
        - Level: ERROR
        - Tags: validation-error,opportunity
        ↓
        [Create Record: Add error to opportunity]
    ↓
   NO → [Add Log Entry]
        - Message: "Validation passed"
        - Level: DEBUG
    ↓
[Save Log]
```

### Example 2: Screen Flow

**Use Case:** User submits a case through a screen flow

```
[Screen: Case Details]
    ↓
[Add Log Entry]
    - Message: "User submitted case: {!CaseSubject}"
    - Level: INFO
    - Tags: user-action,case-creation
    - Scenario: Case Submission
    ↓
[Create Record: Case]
    ↓
    FAULT → [Add Log Entry]
            - Message: "Case creation failed: {!$Flow.FaultMessage}"
            - Level: ERROR
            - Tags: error,critical,case-creation
            ↓
            [Save Log]
            ↓
            [Screen: Error Message]
    ↓
  SUCCESS → [Add Log Entry for an SObject Record]
            - Message: "Case created successfully"
            - Level: INFO
            - Record: {!NewCase}
            - Tags: success,case-creation
            ↓
            [Save Log]
            ↓
            [Screen: Success Message]
```

### Example 3: Scheduled Flow

**Use Case:** Nightly batch update

```
Scheduled: Daily at 2:00 AM

[Start]
    ↓
[Add Log Entry]
    - Message: "Nightly account update batch started"
    - Level: INFO
    - Tags: scheduled-flow,batch,account-update
    - Scenario: Nightly Batch Processing
    ↓
[Get Records: Accounts WHERE LastModifiedDate != TODAY]
    ↓
[Add Log Entry]
    - Message: "Retrieved {!AccountCount} accounts to update"
    - Level: INFO
    ↓
[Loop: For Each Account]
    ↓
    [Update Record: Account]
        ↓
        FAULT → [Assignment: Increment FailureCount]
    ↓
[Add Log Entry]
    - Message: "Batch complete: {!SuccessCount} succeeded, 
                {!FailureCount} failed"
    - Level: INFO
    - Tags: batch-complete
    ↓
[Decision: FailureCount > 0]
    ↓
  YES → [Add Log Entry]
        - Message: "Batch had failures"
        - Level: WARN
        - Tags: batch-warning
    ↓
[Save Log]
```

### Example 4: Auto-Launched Flow (Invoked from Apex)

**Use Case:** Process Builder replacement

```
Invoked by: Process Builder or Apex

[Start]
    ↓
[Add Log Entry]
    - Message: "Contract renewal flow invoked for {!$Record.Name}"
    - Level: INFO
    - Scenario: Contract Renewal
    ↓
[Get Records: Related Opportunities]
    ↓
[Decision: Has Active Opportunities]
    ↓
  YES → [Add Log Entry]
        - Message: "Found {!OppCount} active opportunities"
        - Level: INFO
        ↓
        [Create Record: Renewal Opportunity]
        ↓
        [Add Log Entry for an SObject Record]
        - Message: "Renewal opportunity created"
        - Record: {!NewOpportunity}
        - Tags: renewal,opportunity-creation
    ↓
   NO → [Add Log Entry]
        - Message: "No active opportunities found"
        - Level: WARN
        - Tags: renewal,no-opportunities
    ↓
[Save Log]
```

## Troubleshooting

### Logs Not Appearing

**Check 1: Did you add "Save Log" action?**
- Logs are buffered until Save Log is called
- Add Save Log at the end of your flow

**Check 2: Is Logger enabled?**
- Check LoggerSettings__c.IsEnabled__c = true

**Check 3: Check debug logs**
- Look for "Nebula Logger" in debug logs
- Check for platform event publish errors

### Flow Errors

**Error: "Action not found"**
- Logger may not be installed correctly
- Verify installation in Setup → Installed Packages

**Error: "Required input is missing"**
- Some fields like Message and Logging Level are required
- Ensure all required fields have values

### Performance Issues

**Symptom: Flow is slow**
- Don't log inside loops
- Batch log entries and save once
- Use DEBUG level sparingly

## Advanced Usage

### Dynamic Logging Levels

Use a formula to set logging level:

```
Add Log Entry
- Logging Level: Formula:
  IF({!$Record.Amount} > 100000, "INFO", "DEBUG")
```

### Conditional Logging

Only log if condition is met:

```
[Decision: Amount > 50000]
    ↓
  YES → [Add Log Entry: "High-value deal"]
    ↓
   NO → (Skip logging)
```

### Combining with Apex

Call an Apex action that uses Logger, then save in Flow:

```
[Apex Action: ProcessRecords]
    ↓
[Add Log Entry: "Apex processing complete"]
    ↓
[Save Log]
```

## Next Steps

- [Best Practices](best-practices.md) - Production patterns
- [Tagging Guide](tagging-guide.md) - Organize your logs
- [Scenarios Guide](scenarios-guide.md) - Track processes
- [Admin Guide](admin-guide.md) - Configure Logger
