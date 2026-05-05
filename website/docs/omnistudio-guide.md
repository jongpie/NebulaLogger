# OmniStudio Guide

Complete guide to logging in Salesforce OmniStudio (OmniScripts, Integration Procedures, DataRaptors, FlexCards) with Nebula Logger.

## Table of Contents

- [Overview](#overview)
- [OmniScript Logging](#omniscript-logging)
- [Integration Procedure Logging](#integration-procedure-logging)
- [DataRaptor Logging](#dataraptor-logging)
- [FlexCard Logging](#flexcard-logging)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

Nebula Logger can be integrated with OmniStudio tools to provide observability for:
- OmniScript user interactions
- Integration Procedure executions
- DataRaptor transforms
- FlexCard actions

### Integration Methods

| OmniStudio Tool | Integration Method |
|----------------|-------------------|
| **OmniScript** | Custom LWC action, Formula fields, Apex Remote Action |
| **Integration Procedure** | Apex action step |
| **DataRaptor** | Post-processing Apex |
| **FlexCard** | Custom LWC action, State changes |

## OmniScript Logging

### Method 1: Custom LWC Component (Recommended)

Create a custom LWC that wraps Logger for use in OmniScripts.

**loggerOmniAction.js:**
```javascript
import { LightningElement, api } from 'lwc';
import { getLogger } from 'c/logger';
import { OmniscriptBaseMixin } from 'vlocity_cmt/omniscriptBaseMixin';

export default class LoggerOmniAction extends OmniscriptBaseMixin(LightningElement) {
    @api loggingLevel = 'INFO';
    @api message;
    @api tags;
    @api scenario;
    
    logger = getLogger();
    
    connectedCallback() {
        this.logMessage();
    }
    
    logMessage() {
        try {
            // Set scenario if provided
            if (this.scenario) {
                this.logger.setScenario(this.scenario);
            }
            
            // Create log entry
            let logEntry;
            switch(this.loggingLevel.toUpperCase()) {
                case 'ERROR':
                    logEntry = this.logger.error(this.message);
                    break;
                case 'WARN':
                    logEntry = this.logger.warn(this.message);
                    break;
                case 'DEBUG':
                    logEntry = this.logger.debug(this.message);
                    break;
                case 'INFO':
                default:
                    logEntry = this.logger.info(this.message);
            }
            
            // Add tags if provided
            if (this.tags) {
                const tagArray = this.tags.split(',').map(t => t.trim());
                logEntry.addTags(tagArray);
            }
            
            // Save the log
            this.logger.saveLog();
            
            // Notify OmniScript
            this.omniApplyCallResp({ success: true });
            
        } catch (error) {
            console.error('Logger error:', error);
            this.omniApplyCallResp({ success: false, error: error.message });
        }
    }
}
```

**loggerOmniAction.html:**
```html
<template>
    <!-- Hidden component, logs on load -->
</template>
```

**loggerOmniAction.js-meta.xml:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__FlowScreen</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__FlowScreen">
            <property name="loggingLevel" type="String" label="Logging Level" 
                      description="ERROR, WARN, INFO, DEBUG" default="INFO"/>
            <property name="message" type="String" label="Message" 
                      description="The log message" required="true"/>
            <property name="tags" type="String" label="Tags" 
                      description="Comma-separated tags"/>
            <property name="scenario" type="String" label="Scenario" 
                      description="Business scenario name"/>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

**Usage in OmniScript:**

1. Add a Custom Lightning Web Component element
2. Select `c:loggerOmniAction`
3. Configure properties:
   - **Logging Level:** `INFO`
   - **Message:** `%ScriptName% step completed`
   - **Tags:** `omniscript,user-action`
   - **Scenario:** `Customer Onboarding`

### Method 2: Formula Field with Apex

Create a Formula field that calls Apex via Remote Action.

**OmniScriptLoggerHelper.cls:**
```apex
global class OmniScriptLoggerHelper {
    
    @RemoteAction
    global static void logMessage(String level, String message, String tags, String scenario) {
        // Set scenario
        if (String.isNotBlank(scenario)) {
            Logger.setScenario(scenario);
        }
        
        // Create log entry
        LogEntryEventBuilder entry;
        switch on level.toUpperCase() {
            when 'ERROR' {
                entry = Logger.error(message);
            }
            when 'WARN' {
                entry = Logger.warn(message);
            }
            when 'DEBUG' {
                entry = Logger.debug(message);
            }
            when else {
                entry = Logger.info(message);
            }
        }
        
        // Add tags
        if (String.isNotBlank(tags)) {
            List<String> tagList = tags.split(',');
            entry.addTags(tagList);
        }
        
        // Add OmniScript context
        entry.addTag('omniscript');
        
        // Save log
        Logger.saveLog();
    }
}
```

**Usage in OmniScript:**
1. Add a Formula element
2. Formula: `REMOTEACTION('OmniScriptLoggerHelper', 'logMessage', 'INFO', 'Step completed', 'omniscript', 'Customer Onboarding')`

### Method 3: Integration Procedure Step

Call an Apex class from an Integration Procedure.

**Add Apex Action Step:**
1. Element Type: Apex
2. Class: `OmniScriptLoggerHelper`
3. Method: `logMessage`
4. Input Map:
   ```json
   {
     "level": "INFO",
     "message": "Integration step completed",
     "tags": "integration,omnistudio",
     "scenario": "Data Integration"
   }
   ```

## Integration Procedure Logging

### Pattern 1: Log at Start and End

```
┌─────────────────────────────────────┐
│ Start                               │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│ Apex: Log Start                     │
│ - Message: "IP started"             │
│ - Level: INFO                       │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│ HTTP Action: Call External API      │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│ DataRaptor Transform                │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│ Apex: Log End                       │
│ - Message: "IP completed"           │
│ - Level: INFO                       │
└─────────────────────────────────────┘
```

### Pattern 2: Log Each Step

Create a reusable IP logger:

**LoggerIP.cls:**
```apex
global class LoggerIP implements vlocity_cmt.VlocityOpenInterface {
    
    global Boolean invokeMethod(
        String methodName, 
        Map<String, Object> input,
        Map<String, Object> output,
        Map<String, Object> options
    ) {
        if (methodName == 'logEntry') {
            return logEntry(input, output, options);
        }
        return false;
    }
    
    private Boolean logEntry(
        Map<String, Object> input,
        Map<String, Object> output,
        Map<String, Object> options
    ) {
        try {
            String level = (String) input.get('level');
            String message = (String) input.get('message');
            String tags = (String) input.get('tags');
            String scenario = (String) input.get('scenario');
            
            // Set scenario
            if (String.isNotBlank(scenario)) {
                Logger.setScenario(scenario);
            }
            
            // Create log entry
            LogEntryEventBuilder entry;
            if (level == 'ERROR') {
                entry = Logger.error(message);
            } else if (level == 'WARN') {
                entry = Logger.warn(message);
            } else if (level == 'DEBUG') {
                entry = Logger.debug(message);
            } else {
                entry = Logger.info(message);
            }
            
            // Add tags
            if (String.isNotBlank(tags)) {
                entry.addTags(tags.split(','));
            }
            entry.addTag('integration-procedure');
            
            // Save
            Logger.saveLog();
            
            output.put('success', true);
            return true;
            
        } catch (Exception e) {
            output.put('success', false);
            output.put('error', e.getMessage());
            return false;
        }
    }
}
```

**Usage in Integration Procedure:**
1. Add Apex Action step
2. Class: `LoggerIP`
3. Method: `logEntry`
4. Input:
   ```json
   {
     "level": "INFO",
     "message": "%CurrentStep% completed",
     "tags": "integration,api-call",
     "scenario": "External Integration"
   }
   ```

### Pattern 3: Error Handling

```
┌─────────────────────────────────────┐
│ HTTP Action: Call API               │
└─────────┬───────────────────────────┘
          │
          ├─ Success ─┐
          │           ▼
          │       ┌─────────────────────┐
          │       │ Apex: Log Success   │
          │       │ - Level: INFO       │
          │       └─────────────────────┘
          │
          └─ Error ───┐
                      ▼
                  ┌─────────────────────┐
                  │ Apex: Log Error     │
                  │ - Level: ERROR      │
                  │ - Message: %Error%  │
                  │ - Tags: critical    │
                  └─────────────────────┘
```

## DataRaptor Logging

### Post-Processing with Apex

Call an Apex class after DataRaptor execution:

**DataRaptorLogger.cls:**
```apex
global class DataRaptorLogger {
    
    @InvocableMethod(label='Log DataRaptor Execution')
    global static void logExecution(List<LogInput> inputs) {
        for (LogInput input : inputs) {
            Logger.setScenario('DataRaptor Execution');
            
            Logger.info('DataRaptor executed: ' + input.dataRaptorName)
                .addTag('dataraptor')
                .addTag(input.dataRaptorType);
            
            if (input.recordCount != null) {
                Logger.debug('Records processed: ' + input.recordCount);
            }
            
            Logger.saveLog();
        }
    }
    
    global class LogInput {
        @InvocableVariable(required=true)
        global String dataRaptorName;
        
        @InvocableVariable
        global String dataRaptorType;
        
        @InvocableVariable
        global Integer recordCount;
    }
}
```

**Usage:**
Create a Process Builder or Flow that triggers after DataRaptor execution.

## FlexCard Logging

### Custom Action Logging

Create a custom FlexCard action that logs:

**flexCardLogger.js:**
```javascript
import { LightningElement, api } from 'lwc';
import { getLogger } from 'c/logger';
import { FlexCardMixin } from 'vlocity_cmt/flexCardMixin';

export default class FlexCardLogger extends FlexCardMixin(LightningElement) {
    @api actionName;
    @api recordId;
    
    logger = getLogger();
    
    handleAction(event) {
        this.logger.setScenario('FlexCard Action');
        
        this.logger.info('FlexCard action: ' + this.actionName)
            .setRecordId(this.recordId)
            .addTag('flexcard')
            .addTag('user-action');
        
        this.logger.saveLog();
        
        // Trigger next action in FlexCard
        this.dispatchEvent(new CustomEvent('action', {
            detail: { success: true }
        }));
    }
}
```

### State Change Logging

Log when FlexCard state changes:

```javascript
import { LightningElement, track } from 'lwc';
import { getLogger } from 'c/logger';

export default class FlexCardWithLogging extends LightningElement {
    @track currentState = 'default';
    logger = getLogger();
    
    handleStateChange(event) {
        const newState = event.detail.state;
        
        this.logger.info('FlexCard state changed: ' + 
                        this.currentState + ' → ' + newState)
            .addTag('flexcard')
            .addTag('state-change');
        
        this.currentState = newState;
        this.logger.saveLog();
    }
}
```

## Best Practices

### 1. Use Consistent Scenarios

```apex
// ✅ Good: Consistent scenario naming
Logger.setScenario('Customer Onboarding');  // OmniScript
Logger.setScenario('Customer Onboarding');  // Integration Procedure
Logger.setScenario('Customer Onboarding');  // DataRaptor

// ❌ Bad: Inconsistent naming
Logger.setScenario('customer onboarding');
Logger.setScenario('Onboarding - Customer');
Logger.setScenario('CustOnboard');
```

### 2. Tag by OmniStudio Tool

```apex
// Always tag with the tool type
Logger.info('Step completed')
    .addTag('omniscript')  // or 'integration-procedure', 'dataraptor', 'flexcard'
    .addTag('feature-name');
```

### 3. Log User Actions in OmniScripts

```javascript
// Log important user interactions
this.logger.info('User clicked Next on Step 3')
    .addTag('omniscript')
    .addTag('user-action')
    .addTag('step-navigation');
```

### 4. Log Integration Procedure External Calls

```apex
// Before API call
Logger.info('Calling external API: ' + endpoint)
    .addTag('integration-procedure')
    .addTag('external-api')
    .addTag('pre-call');

// After API call
Logger.info('API call completed: ' + statusCode)
    .addTag('integration-procedure')
    .addTag('external-api')
    .addTag('post-call');

Logger.saveLog();
```

### 5. Log DataRaptor Transforms

```apex
// Log data transformation
Logger.info('DataRaptor transform: ' + records.size() + ' records')
    .addTag('dataraptor')
    .addTag('transform');
```

### 6. Include Error Context

```apex
// Log errors with full context
Logger.error('OmniScript failed at Step 5: Payment Processing')
    .setField(Log__c.RelatedRecordId__c, recordId)
    .addTag('omniscript')
    .addTag('error')
    .addTag('payment-failure')
    .addTag('critical');
```

### 7. Don't Over-Log

```apex
// ❌ Bad: Logging every minor step
Logger.info('Entered method');
Logger.debug('Variable x = 10');
Logger.info('Exiting method');

// ✅ Good: Log milestones
Logger.info('OmniScript step completed: Customer Information');
Logger.info('Integration Procedure completed successfully');
```

## Common Patterns

### Pattern: OmniScript with Error Handling

```
[Step 1: Customer Info]
    → Log: "Step 1 started"
    → Validate input
    → Log: "Step 1 completed"
    ↓
[Step 2: Payment Info]
    → Log: "Step 2 started"
    → Validate payment
    → IF ERROR:
        → Log ERROR: "Payment validation failed"
        → Show error message
    → ELSE:
        → Log: "Step 2 completed"
    ↓
[Step 3: Confirmation]
    → Log: "Submitting order"
    → Submit order
    → IF ERROR:
        → Log ERROR: "Order submission failed"
    → ELSE:
        → Log: "Order submitted successfully"
```

### Pattern: Integration Procedure with Retries

```apex
public class IPWithRetry {
    public void execute() {
        Logger.setScenario('External API Integration');
        Integer retryCount = 0;
        Integer maxRetries = 3;
        Boolean success = false;
        
        while (!success && retryCount < maxRetries) {
            try {
                Logger.info('API call attempt ' + (retryCount + 1))
                    .addTag('integration-procedure')
                    .addTag('retry-attempt');
                
                callExternalAPI();
                success = true;
                
                Logger.info('API call succeeded on attempt ' + (retryCount + 1))
                    .addTag('integration-procedure')
                    .addTag('success');
                
            } catch (Exception e) {
                retryCount++;
                
                if (retryCount >= maxRetries) {
                    Logger.error('API call failed after ' + maxRetries + ' attempts')
                        .setExceptionDetails(e)
                        .addTag('integration-procedure')
                        .addTag('critical')
                        .addTag('max-retries-exceeded');
                } else {
                    Logger.warn('API call failed, retrying...')
                        .setExceptionDetails(e)
                        .addTag('integration-procedure')
                        .addTag('retry');
                }
            }
        }
        
        Logger.saveLog();
    }
}
```

## Troubleshooting

### OmniScript Logs Not Appearing

**Check 1:** Is the Custom LWC component activated?
- Verify the LWC is deployed and accessible

**Check 2:** Are you calling `saveLog()`?
- Logger buffers entries until saved

**Check 3:** Check browser console
- Look for JavaScript errors
- Check for Logger-related messages

### Integration Procedure Issues

**Check 1:** Is the Apex class available?
- Verify class is deployed
- Check class is global/public as needed

**Check 2:** Check IP debug mode
- Enable debug mode in Integration Procedure
- Review execution logs

**Check 3:** Verify input mapping
- Ensure input parameters are mapped correctly
- Check for null values

### Performance Concerns

**Symptom:** OmniScript is slow

**Solution:**
- Don't log on every render
- Batch log entries
- Use INFO level or higher in production
- Save logs at end of process, not each step

## Next Steps

- [Flow Guide](flow-guide.md) - Similar declarative logging
- [Best Practices](best-practices.md) - General patterns
- [LWC Guide](lwc-guide.md) - LWC-specific logging
- [Apex Guide](apex-guide.md) - Apex integration
