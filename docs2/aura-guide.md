# Aura Components Guide

Complete guide to logging in Aura Components with Nebula Logger.

## Table of Contents

- [Setup](#setup)
- [Basic Usage](#basic-usage)
- [Logging Levels](#logging-levels)
- [Adding Context](#adding-context)
- [Exception Handling](#exception-handling)
- [Tagging and Scenarios](#tagging-and-scenarios)
- [Component Patterns](#component-patterns)
- [Best Practices](#best-practices)

## Setup

### Add Logger to Your Component

**YourComponent.cmp:**
```xml
<aura:component>
    <!-- Include the logger component -->
    <c:logger aura:id="logger" />
    
    <!-- Your component markup -->
    <lightning:button label="Click Me" onclick="{!c.handleClick}" />
</aura:component>
```

### Access Logger in Controller

**YourComponentController.js:**
```javascript
({
    handleClick: function(component, event, helper) {
        // Get logger reference
        var logger = component.find('logger');
        
        // Log a message
        logger.info('Button clicked');
        logger.saveLog();
    }
})
```

## Basic Usage

### Simple Logging

**Component:**
```xml
<aura:component>
    <c:logger aura:id="logger" />
    
    <lightning:button label="Log Message" onclick="{!c.logMessage}" />
</aura:component>
```

**Controller:**
```javascript
({
    logMessage: function(component, event, helper) {
        var logger = component.find('logger');
        
        logger.info('Hello from Aura Component!');
        logger.saveLog();
    }
})
```

### Method Chaining

```javascript
var logger = component.find('logger');

logger.info('User action performed')
    .addTag('user-action')
    .addTag('button-click');

logger.saveLog();
```

## Logging Levels

Seven levels available:

```javascript
var logger = component.find('logger');

logger.error('Critical error occurred');
logger.warn('Warning message');
logger.info('Informational message');
logger.debug('Debug information');
logger.fine('Fine-grained trace');
logger.finer('More detailed trace');
logger.finest('Most detailed trace');

logger.saveLog();
```

### Level Guidelines

| Level | Use Case | Example |
|-------|----------|---------|
| **error** | User-facing errors, exceptions | Form validation failed, Server error |
| **warn** | Potential issues, degraded UX | Slow response, Deprecated feature |
| **info** | User actions, important events | Button clicked, Record saved |
| **debug** | Diagnostic information | Helper called, Attribute changed |
| **fine** | Component lifecycle | Init, Render complete |
| **finer** | Detailed state | Attribute values, Event details |
| **finest** | Most granular | Every render, Every change |

## Adding Context

### Setting a Scenario

```javascript
({
    init: function(component, event, helper) {
        var logger = component.find('logger');
        
        logger.setScenario('Shopping Cart');
        logger.info('Cart component initialized');
        logger.saveLog();
    }
})
```

### Record Context

```javascript
({
    handleSave: function(component, event, helper) {
        var recordId = component.get('v.recordId');
        var logger = component.find('logger');
        
        logger.info('Saving record')
            .setRecordId(recordId);
        
        // ... save logic ...
        
        logger.saveLog();
    }
})
```

### Multiple Log Entries

```javascript
({
    processData: function(component, event, helper) {
        var logger = component.find('logger');
        var data = component.get('v.data');
        
        logger.info('Processing started: ' + data.length + ' records');
        
        // Process data
        try {
            helper.validateData(data);
            logger.info('Validation successful');
            
            helper.transformData(data);
            logger.info('Transformation successful');
            
        } catch (error) {
            logger.error('Processing failed')
                .setExceptionDetails(error)
                .addTag('critical');
        } finally {
            logger.saveLog();
        }
    }
})
```

## Exception Handling

### Basic Error Logging

```javascript
({
    handleAction: function(component, event, helper) {
        var logger = component.find('logger');
        
        try {
            // Risky operation
            var result = helper.performOperation();
            logger.info('Operation successful');
            
        } catch (error) {
            logger.error('Operation failed')
                .setExceptionDetails(error)
                .addTag('error');
        } finally {
            logger.saveLog();
        }
    }
})
```

### Server Action Error Handling

```javascript
({
    callServer: function(component, event, helper) {
        var logger = component.find('logger');
        var action = component.get('c.serverMethod');
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                logger.info('Server call succeeded')
                    .setMessage(JSON.stringify(result));
                logger.saveLog();
                
            } else if (state === 'ERROR') {
                var errors = response.getError();
                var errorMessage = errors && errors[0] && errors[0].message 
                    ? errors[0].message 
                    : 'Unknown error';
                
                logger.error('Server call failed: ' + errorMessage)
                    .setExceptionDetails({ 
                        message: errorMessage,
                        errors: errors 
                    })
                    .addTag('apex-error')
                    .addTag('critical');
                logger.saveLog();
                
                // Show toast to user
                helper.showToast('Error', errorMessage, 'error');
            }
        });
        
        $A.enqueueAction(action);
    }
})
```

### Lightning Data Service Error Handling

```javascript
({
    handleRecordLoad: function(component, event, helper) {
        var logger = component.find('logger');
        var state = event.getParam('changeType');
        
        if (state === 'LOADED') {
            logger.info('Record loaded successfully');
            logger.saveLog();
            
        } else if (state === 'ERROR') {
            var error = event.getParam('error');
            logger.error('Failed to load record')
                .setExceptionDetails(error)
                .addTag('lds-error');
            logger.saveLog();
        }
    }
})
```

## Tagging and Scenarios

### Adding Tags

```javascript
var logger = component.find('logger');

// Single tag
logger.info('User clicked button').addTag('user-action');

// Multiple tags (chained)
logger.error('Payment failed')
    .addTag('payment')
    .addTag('critical')
    .addTag('requires-investigation');

// Save all entries
logger.saveLog();
```

### Tag Examples

```javascript
// Feature tagging
logger.info('Filter applied').addTag('search-filter');

// UI interaction
logger.info('Modal opened').addTag('ui-interaction').addTag('modal');

// Error severity
logger.error('Critical failure').addTag('critical').addTag('p0');

// Team ownership
logger.warn('Deprecated API used').addTag('team-platform');
```

### Using Scenarios

```javascript
({
    handleCheckout: function(component, event, helper) {
        var logger = component.find('logger');
        
        // Set scenario for the process
        logger.setScenario('Checkout Process');
        logger.info('Checkout initiated');
        
        try {
            // Step 1: Validation
            logger.setScenario('Cart Validation');
            helper.validateCart(component);
            logger.info('Cart validated');
            
            // Step 2: Payment
            logger.setScenario('Payment Processing');
            helper.processPayment(component);
            logger.info('Payment processed');
            
            // Step 3: Order
            logger.setScenario('Order Creation');
            helper.createOrder(component);
            logger.info('Order created');
            
            logger.info('Checkout completed successfully');
            
        } catch (error) {
            logger.error('Checkout failed')
                .setExceptionDetails(error)
                .addTag('checkout-error');
        } finally {
            logger.saveLog();
        }
    }
})
```

## Component Patterns

### Component Initialization

```javascript
({
    doInit: function(component, event, helper) {
        var logger = component.find('logger');
        logger.setScenario('Component Initialization');
        logger.fine('Component initializing');
        
        try {
            // Load initial data
            helper.loadData(component);
            logger.info('Component initialized successfully');
            
        } catch (error) {
            logger.error('Initialization failed')
                .setExceptionDetails(error)
                .addTag('init-error');
        } finally {
            logger.saveLog();
        }
    }
})
```

### Event Handling

```javascript
({
    handleCustomEvent: function(component, event, helper) {
        var logger = component.find('logger');
        var eventData = event.getParam('data');
        
        logger.debug('Custom event received')
            .setMessage(JSON.stringify(eventData))
            .addTag('event-handling');
        
        // Process event
        helper.processEvent(component, eventData);
        
        logger.saveLog();
    }
})
```

### Navigation

```javascript
({
    navigateToRecord: function(component, event, helper) {
        var logger = component.find('logger');
        var recordId = component.get('v.recordId');
        
        logger.info('Navigating to record: ' + recordId)
            .setRecordId(recordId)
            .addTag('navigation');
        
        var navService = component.find('navService');
        var pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        };
        
        navService.navigate(pageReference);
        logger.saveLog();
    }
})
```

### Helper Method Logging

**Controller:**
```javascript
({
    processRecords: function(component, event, helper) {
        var logger = component.find('logger');
        
        // Pass logger to helper
        helper.processRecords(component, logger);
    }
})
```

**Helper:**
```javascript
({
    processRecords: function(component, logger) {
        logger.info('Helper: processRecords started');
        
        var records = component.get('v.records');
        
        try {
            // Process records
            for (var i = 0; i < records.length; i++) {
                this.processRecord(records[i]);
            }
            
            logger.info('Helper: processRecords completed - ' + records.length + ' records');
            logger.saveLog();
            
        } catch (error) {
            logger.error('Helper: processRecords failed')
                .setExceptionDetails(error);
            logger.saveLog();
            throw error;
        }
    },
    
    processRecord: function(record) {
        // Process individual record
    }
})
```

## Best Practices

### 1. Create Logger Reference Once

```javascript
// ✅ Good: Get logger reference in each controller method
({
    handleClick: function(component, event, helper) {
        var logger = component.find('logger');
        logger.info('Button clicked');
        logger.saveLog();
    }
})

// ❌ Bad: Don't try to store logger in component attribute
// Aura components don't maintain JavaScript object references well
```

### 2. Always Use Try-Finally

```javascript
// ✅ Good: Always save logs
({
    handleOperation: function(component, event, helper) {
        var logger = component.find('logger');
        
        try {
            helper.doSomething(component);
        } catch (error) {
            logger.error('Failed').setExceptionDetails(error);
            throw error;
        } finally {
            logger.saveLog();  // Always saves
        }
    }
})
```

### 3. Log User Actions

```javascript
// ✅ Good: Track user interactions
({
    handleButtonClick: function(component, event, helper) {
        var logger = component.find('logger');
        var buttonLabel = event.getSource().get('v.label');
        
        logger.info('User clicked: ' + buttonLabel)
            .addTag('user-action')
            .addTag('button-click');
        
        // Process action
        helper.handleAction(component);
        
        logger.saveLog();
    }
})
```

### 4. Include Context in Error Messages

```javascript
// ❌ Bad: Generic error
catch (error) {
    logger.error('Error occurred');
}

// ✅ Good: Specific error with context
catch (error) {
    var recordId = component.get('v.recordId');
    logger.error('Failed to save account: ' + recordId)
        .setRecordId(recordId)
        .setExceptionDetails(error)
        .addTag('save-error');
}
```

### 5. Pass Logger to Helper Methods

```javascript
// ✅ Good: Pass logger to helper
({
    handleAction: function(component, event, helper) {
        var logger = component.find('logger');
        helper.processData(component, logger);
    }
})

// Helper
({
    processData: function(component, logger) {
        logger.info('Processing data in helper');
        // ... logic ...
        logger.saveLog();
    }
})
```

### 6. Don't Over-Log in Render

```javascript
// ❌ Bad: Logging on every render
({
    onRender: function(component, event, helper) {
        var logger = component.find('logger');
        logger.debug('Rendering');  // Don't do this!
        logger.saveLog();
    }
})

// ✅ Good: Log state changes, not renders
({
    handleAttributeChange: function(component, event, helper) {
        var logger = component.find('logger');
        var oldValue = event.getParam('oldValue');
        var newValue = event.getParam('value');
        
        logger.debug('Attribute changed: ' + oldValue + ' -> ' + newValue);
        logger.saveLog();
    }
})
```

### 7. Use Appropriate Log Levels

```javascript
// ❌ Bad: Everything is INFO
logger.info('Method called');
logger.info('Variable x = 10');
logger.info('Loop iteration');

// ✅ Good: Use appropriate levels
logger.fine('Method called');
logger.debug('Variable x = 10');
logger.info('User submitted form');
```

### 8. Batch Logs Within Operations

```javascript
// ✅ Good: One save per operation
({
    handleMultiStep: function(component, event, helper) {
        var logger = component.find('logger');
        
        logger.info('Step 1 started');
        helper.doStep1(component);
        logger.info('Step 1 completed');
        
        logger.info('Step 2 started');
        helper.doStep2(component);
        logger.info('Step 2 completed');
        
        logger.saveLog();  // One save for all entries
    }
})

// ❌ Bad: Multiple saves
({
    handleMultiStep: function(component, event, helper) {
        var logger = component.find('logger');
        
        logger.info('Step 1 started');
        logger.saveLog();  // Don't do this
        
        logger.info('Step 2 started');
        logger.saveLog();  // Don't do this
    }
})
```

## Common Patterns

### Pattern: Record Detail Component

```xml
<!-- RecordDetail.cmp -->
<aura:component implements="flexipage:availableForRecordHome,force:hasRecordId">
    <c:logger aura:id="logger" />
    <aura:attribute name="record" type="Object" />
    <aura:attribute name="recordError" type="String" />
    
    <force:recordData aura:id="recordLoader"
                      recordId="{!v.recordId}"
                      targetRecord="{!v.record}"
                      targetError="{!v.recordError}"
                      recordUpdated="{!c.handleRecordUpdated}" />
</aura:component>
```

```javascript
// RecordDetailController.js
({
    handleRecordUpdated: function(component, event, helper) {
        var logger = component.find('logger');
        var recordError = component.get('v.recordError');
        
        if (recordError) {
            logger.error('Failed to load record')
                .setRecordId(component.get('v.recordId'))
                .setExceptionDetails({ message: recordError })
                .addTag('record-load-error');
        } else {
            logger.info('Record loaded successfully')
                .setRecordId(component.get('v.recordId'))
                .addTag('record-view');
        }
        
        logger.saveLog();
    }
})
```

### Pattern: Form Component

```xml
<!-- FormComponent.cmp -->
<aura:component>
    <c:logger aura:id="logger" />
    
    <lightning:recordEditForm objectApiName="Account"
                              onsubmit="{!c.handleSubmit}"
                              onsuccess="{!c.handleSuccess}"
                              onerror="{!c.handleError}">
        <lightning:inputField fieldName="Name" />
        <lightning:inputField fieldName="Phone" />
        <lightning:button type="submit" label="Save" />
    </lightning:recordEditForm>
</aura:component>
```

```javascript
// FormComponentController.js
({
    handleSubmit: function(component, event, helper) {
        event.preventDefault();
        var logger = component.find('logger');
        
        logger.setScenario('Form Submission');
        logger.info('Form submission started').addTag('form');
        logger.saveLog();
        
        component.find('recordEditForm').submit();
    },
    
    handleSuccess: function(component, event, helper) {
        var logger = component.find('logger');
        var recordId = event.getParam('id');
        
        logger.info('Form submitted successfully')
            .setRecordId(recordId)
            .addTag('form-success');
        logger.saveLog();
    },
    
    handleError: function(component, event, helper) {
        var logger = component.find('logger');
        var error = event.getParam('error');
        
        logger.error('Form submission failed')
            .setExceptionDetails(error)
            .addTag('form-error')
            .addTag('critical');
        logger.saveLog();
    }
})
```

## Migration from LWC

If you're familiar with LWC Logger:

| LWC | Aura | Notes |
|-----|------|-------|
| `import { getLogger }` | `component.find('logger')` | Get logger reference |
| `logger = getLogger()` | `<c:logger aura:id="logger" />` | Include in markup |
| `this.logger.info()` | `logger.info()` | Same API |
| `connectedCallback()` | `doInit: function()` | Initialization |
| Method syntax | Controller syntax | Different structure |

## Next Steps

- [LWC Guide](lwc-guide.md) - Modern Lightning Web Components
- [Best Practices](best-practices.md) - Cross-platform patterns
- [Tagging Guide](tagging-guide.md) - Organizing logs
- [Scenarios Guide](scenarios-guide.md) - Process tracking
