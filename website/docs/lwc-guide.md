# Lightning Web Components Guide

Complete guide to logging in Lightning Web Components with Nebula Logger.

## Table of Contents

- [Setup](#setup)
- [Basic Usage](#basic-usage)
- [Logging Levels](#logging-levels)
- [Adding Context](#adding-context)
- [Exception Handling](#exception-handling)
- [Tagging and Scenarios](#tagging-and-scenarios)
- [Advanced Patterns](#advanced-patterns)
- [Best Practices](#best-practices)

## Setup

### Import the Logger

```javascript
import { LightningElement } from 'lwc';
import { getLogger } from 'c/logger';

export default class YourComponent extends LightningElement {
    // Create logger instance (once per component)
    logger = getLogger();
    
    connectedCallback() {
        this.logger.info('Component initialized');
    }
}
```

**Key points:**
- Call `getLogger()` once per component (typically as a class property)
- Logger instance is tied to the component lifecycle
- Always call `saveLog()` to persist entries

### Component Metadata

No special metadata required - Logger works in any LWC.

## Basic Usage

### Simple Logging

```javascript
import { LightningElement } from 'lwc';
import { getLogger } from 'c/logger';

export default class SimpleLogging extends LightningElement {
    logger = getLogger();

    connectedCallback() {
        this.logger.info('Component loaded');
        this.logger.saveLog();
    }
}
```

### Method Chaining

```javascript
handleClick() {
    this.logger.info('Button clicked')
        .addTag('user-interaction')
        .addTag('button-click');
    this.logger.saveLog();
}
```

## Logging Levels

Seven levels available:

```javascript
this.logger.error('Critical error occurred');
this.logger.warn('Warning message');
this.logger.info('Informational message');
this.logger.debug('Debug information');
this.logger.fine('Fine-grained trace');
this.logger.finer('More detailed trace');
this.logger.finest('Most detailed trace');
```

### Level Guidelines

| Level | Use Case | Example |
|-------|----------|---------|
| **error** | User-facing errors, exceptions | Form validation failed, API error |
| **warn** | Potential issues, degraded UX | Slow API response, deprecated feature used |
| **info** | User actions, important events | Button clicked, form submitted, data loaded |
| **debug** | Diagnostic information | Wire adapter fired, computed property changed |
| **fine** | Component lifecycle events | Connected, disconnected, rendered |
| **finer** | Detailed state inspection | Property values, event details |
| **finest** | Most granular tracing | Every render cycle, every reactive change |

## Adding Context

### Setting a Scenario

```javascript
import { LightningElement } from 'lwc';
import { getLogger } from 'c/logger';

export default class ScenarioExample extends LightningElement {
    logger = getLogger();

    async connectedCallback() {
        this.logger.setScenario('Shopping Cart');
        this.logger.info('Cart component initialized');
        await this.loadCartData();
    }

    async loadCartData() {
        this.logger.debug('Loading cart data');
        // ... load data ...
        this.logger.info('Cart data loaded');
        this.logger.saveLog();
    }
}
```

### Record Context

```javascript
import { LightningElement, api } from 'lwc';
import { getLogger } from 'c/logger';

export default class RecordComponent extends LightningElement {
    @api recordId;
    logger = getLogger();

    handleSave() {
        this.logger.info('Saving record changes')
            .setRecordId(this.recordId);
        
        // ... save logic ...
        
        this.logger.saveLog();
    }
}
```

### Custom Message

Add structured data to your log:

```javascript
handleError(error) {
    const errorDetails = {
        code: error.code,
        message: error.message,
        timestamp: new Date().toISOString()
    };
    
    this.logger.error('Operation failed')
        .setMessage(JSON.stringify(errorDetails));
    
    this.logger.saveLog();
}
```

## Exception Handling

### Basic Error Logging

```javascript
async handleDataLoad() {
    try {
        const data = await fetchData();
        this.logger.info('Data loaded successfully');
    } catch (error) {
        this.logger.error('Data load failed')
            .setExceptionDetails(error)
            .addTag('data-error');
    } finally {
        this.logger.saveLog();
    }
}
```

### Wire Adapter Error Handling

```javascript
import { wire } from 'lwc';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';

@wire(getAccounts)
wiredAccounts({ error, data }) {
    if (data) {
        this.accounts = data;
        this.logger.debug('Accounts loaded: ' + data.length);
    } else if (error) {
        this.logger.error('Failed to load accounts')
            .setExceptionDetails(error)
            .addTag('wire-error');
        this.logger.saveLog();
    }
}
```

### Imperative Apex Error Handling

```javascript
import { LightningElement } from 'lwc';
import { getLogger } from 'c/logger';
import saveRecord from '@salesforce/apex/RecordController.saveRecord';

export default class ApexExample extends LightningElement {
    logger = getLogger();

    async handleSave() {
        try {
            const result = await saveRecord({ recordData: this.data });
            this.logger.info('Record saved successfully').setRecordId(result.Id);
            this.logger.saveLog();
        } catch (error) {
            this.logger.error('Save failed')
                .setExceptionDetails(error)
                .addTag('apex-error')
                .addTag('critical');
            this.logger.saveLog();
            
            // Show error to user
            this.showToast('Error', error.body.message, 'error');
        }
    }
}
```

### JavaScript Exception Handling

```javascript
handleComplexOperation() {
    try {
        // Complex logic that might throw
        const result = this.calculateSomething();
        this.logger.debug('Calculation result: ' + result);
    } catch (error) {
        // Capture JavaScript exception
        this.logger.error('Calculation failed')
            .setExceptionDetails({
                message: error.message,
                stack: error.stack,
                name: error.name
            })
            .addTag('javascript-error');
    } finally {
        this.logger.saveLog();
    }
}
```

## Tagging and Scenarios

### Adding Tags

```javascript
// Single tag
this.logger.info('User clicked button').addTag('user-action');

// Multiple tags (chained)
this.logger.error('Payment failed')
    .addTag('payment')
    .addTag('critical')
    .addTag('requires-investigation');

// Multiple tags (array)
this.logger.debug('Search performed')
    .addTags(['search', 'user-interaction', 'analytics']);

this.logger.saveLog();
```

### Tag Examples by Category

```javascript
// Feature tagging
this.logger.info('Filter applied').addTag('search-filter');

// User action tagging
this.logger.info('Modal opened').addTag('ui-interaction');

// Error severity tagging
this.logger.error('Critical failure').addTag('critical').addTag('p0');

// Team tagging
this.logger.warn('Deprecated API used').addTag('team-platform');

// Customer tagging
this.logger.info('Premium feature used').addTag('premium-customer');
```

### Using Scenarios

```javascript
import { LightningElement } from 'lwc';
import { getLogger } from 'c/logger';

export default class MultiStepProcess extends LightningElement {
    logger = getLogger();

    async handleCheckout() {
        // Step 1: Validation
        this.logger.setScenario('Checkout Validation');
        this.logger.info('Validating cart items');
        await this.validateCart();

        // Step 2: Payment
        this.logger.setScenario('Payment Processing');
        this.logger.info('Processing payment');
        await this.processPayment();

        // Step 3: Fulfillment
        this.logger.setScenario('Order Fulfillment');
        this.logger.info('Creating order');
        await this.createOrder();

        this.logger.saveLog();
    }
}
```

## Advanced Patterns

### Lifecycle Logging

```javascript
import { LightningElement } from 'lwc';
import { getLogger } from 'c/logger';

export default class LifecycleComponent extends LightningElement {
    logger = getLogger();

    constructor() {
        super();
        this.logger.finest('Constructor called');
    }

    connectedCallback() {
        this.logger.fine('Component connected to DOM');
        this.initialize();
    }

    disconnectedCallback() {
        this.logger.fine('Component disconnected from DOM');
        this.cleanup();
        this.logger.saveLog();
    }

    renderedCallback() {
        this.logger.finest('Component rendered');
    }

    errorCallback(error, stack) {
        this.logger.error('Component error boundary triggered')
            .setExceptionDetails({ message: error.message, stack })
            .addTag('error-boundary');
        this.logger.saveLog();
    }
}
```

### Navigation Logging

```javascript
import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getLogger } from 'c/logger';

export default class NavigationComponent extends NavigationMixin(LightningElement) {
    logger = getLogger();

    handleNavigate() {
        this.logger.info('Navigating to record page')
            .setRecordId(this.recordId)
            .addTag('navigation');
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });

        this.logger.saveLog();
    }
}
```

### Event Logging

```javascript
import { LightningElement } from 'lwc';
import { getLogger } from 'c/logger';

export default class EventComponent extends LightningElement {
    logger = getLogger();

    handleCustomEvent(event) {
        const eventData = {
            type: event.type,
            detail: event.detail,
            timestamp: new Date().toISOString()
        };

        this.logger.debug('Custom event received')
            .setMessage(JSON.stringify(eventData))
            .addTag('event-handling');
        
        // Process event...
        
        this.logger.saveLog();
    }

    fireCustomEvent() {
        this.logger.debug('Firing custom event').addTag('event-dispatching');
        
        const event = new CustomEvent('customaction', {
            detail: { action: 'save', recordId: this.recordId }
        });
        
        this.dispatchEvent(event);
        this.logger.saveLog();
    }
}
```

### Performance Tracking

```javascript
import { LightningElement } from 'lwc';
import { getLogger } from 'c/logger';

export default class PerformanceTracking extends LightningElement {
    logger = getLogger();

    async handleOperation() {
        const startTime = performance.now();
        
        this.logger.debug('Starting expensive operation');

        try {
            await this.expensiveOperation();
            
            const endTime = performance.now();
            const duration = endTime - startTime;

            this.logger.info(`Operation completed in ${duration.toFixed(2)}ms`)
                .addTag('performance');
            
            if (duration > 1000) {
                this.logger.warn('Operation exceeded performance threshold')
                    .addTag('performance-warning');
            }
        } catch (error) {
            this.logger.error('Operation failed')
                .setExceptionDetails(error);
        } finally {
            this.logger.saveLog();
        }
    }
}
```

### Async/Await Pattern

```javascript
import { LightningElement } from 'lwc';
import { getLogger } from 'c/logger';
import getData from '@salesforce/apex/DataController.getData';

export default class AsyncComponent extends LightningElement {
    logger = getLogger();

    async connectedCallback() {
        this.logger.setScenario('Data Loading');
        this.logger.info('Component initializing');

        try {
            const data = await this.loadData();
            this.logger.info('Data loaded: ' + data.length + ' records');
            
            await this.processData(data);
            this.logger.info('Data processing complete');
        } catch (error) {
            this.logger.error('Initialization failed')
                .setExceptionDetails(error)
                .addTag('critical');
        } finally {
            this.logger.saveLog();
        }
    }

    async loadData() {
        this.logger.debug('Calling Apex getData()');
        const data = await getData();
        this.logger.debug('Apex returned ' + data.length + ' records');
        return data;
    }
}
```

## Best Practices

### 1. Create Logger Once Per Component

```javascript
// ✅ Good: Create once as class property
export default class MyComponent extends LightningElement {
    logger = getLogger();
}

// ❌ Bad: Creating logger in every method
export default class MyComponent extends LightningElement {
    handleClick() {
        const logger = getLogger();  // Don't do this!
        logger.info('Clicked');
    }
}
```

### 2. Always Use Try-Finally with saveLog()

```javascript
// ✅ Good: Always save, even if error occurs
async handleOperation() {
    try {
        await this.doSomething();
    } catch (error) {
        this.logger.error('Failed').setExceptionDetails(error);
        throw error;
    } finally {
        this.logger.saveLog();  // Always saves
    }
}
```

### 3. Log User Interactions

```javascript
// ✅ Good: Track important user actions
handleSubmit() {
    this.logger.info('Form submitted')
        .setMessage(JSON.stringify(this.formData))
        .addTag('user-action')
        .addTag('form-submission');
    this.logger.saveLog();
}
```

### 4. Use Appropriate Log Levels

```javascript
// ❌ Bad: Everything is INFO
this.logger.info('Component rendering');
this.logger.info('Property changed');
this.logger.info('Method called');

// ✅ Good: Use appropriate levels
this.logger.finest('Component rendering');
this.logger.debug('Property changed: ' + this.property);
this.logger.info('User submitted form');
```

### 5. Don't Log in Render Cycle

```javascript
// ❌ Bad: Logging in getter (called every render)
get displayValue() {
    this.logger.debug('Getting display value');  // Don't do this!
    return this.value.toUpperCase();
}

// ✅ Good: Log state changes, not getters
@api
set value(val) {
    this._value = val;
    this.logger.debug('Value changed to: ' + val);
}
```

### 6. Include Context for Errors

```javascript
// ❌ Bad: Generic error without context
catch (error) {
    this.logger.error('Error occurred');
}

// ✅ Good: Include exception details and context
catch (error) {
    this.logger.error('Failed to save account')
        .setExceptionDetails(error)
        .setRecordId(this.accountId)
        .addTag('apex-error')
        .addTag('account-save');
}
```

### 7. Batch Logs, Don't Over-Save

```javascript
// ❌ Bad: Saving after every entry
handleClick() {
    this.logger.info('Step 1');
    this.logger.saveLog();
    this.logger.info('Step 2');
    this.logger.saveLog();
    this.logger.info('Step 3');
    this.logger.saveLog();
}

// ✅ Good: Save once for the entire operation
handleClick() {
    this.logger.info('Step 1');
    this.logger.info('Step 2');
    this.logger.info('Step 3');
    this.logger.saveLog();  // One save for all entries
}
```

### 8. Use Scenarios for Multi-Step Processes

```javascript
// ✅ Good: Track business process flow
async handleWizard() {
    this.logger.setScenario('User Onboarding');
    
    this.logger.info('Step 1: Profile setup');
    await this.setupProfile();
    
    this.logger.info('Step 2: Preferences');
    await this.setPreferences();
    
    this.logger.info('Step 3: Confirmation');
    await this.sendConfirmation();
    
    this.logger.saveLog();
}
```

## Common Patterns

### Pattern: Record Detail Component

```javascript
import { LightningElement, api, wire } from 'lwc';
import { getLogger } from 'c/logger';
import { getRecord } from 'lightning/uiRecordApi';

export default class RecordDetail extends LightningElement {
    @api recordId;
    logger = getLogger();

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.logger.info('Record loaded')
                .setRecordId(this.recordId)
                .addTag('record-view');
            this.logger.saveLog();
        } else if (error) {
            this.logger.error('Failed to load record')
                .setRecordId(this.recordId)
                .setExceptionDetails(error)
                .addTag('record-load-error');
            this.logger.saveLog();
        }
    }
}
```

### Pattern: Form Component

```javascript
import { LightningElement } from 'lwc';
import { getLogger } from 'c/logger';

export default class FormComponent extends LightningElement {
    logger = getLogger();

    handleSubmit(event) {
        event.preventDefault();
        this.logger.setScenario('Form Submission');
        
        const fields = event.detail.fields;
        this.logger.info('Form submission started')
            .setMessage(JSON.stringify(fields))
            .addTag('form');

        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess(event) {
        const recordId = event.detail.id;
        this.logger.info('Form submitted successfully')
            .setRecordId(recordId)
            .addTag('form-success');
        this.logger.saveLog();
    }

    handleError(event) {
        this.logger.error('Form submission failed')
            .setExceptionDetails(event.detail)
            .addTag('form-error')
            .addTag('critical');
        this.logger.saveLog();
    }
}
```

## Testing

### Mock Logger for Jest Tests

```javascript
// __tests__/yourComponent.test.js
import { createElement } from 'lwc';
import YourComponent from 'c/yourComponent';

// Mock the logger
jest.mock('c/logger', () => ({
    getLogger: jest.fn(() => ({
        info: jest.fn().mockReturnThis(),
        error: jest.fn().mockReturnThis(),
        addTag: jest.fn().mockReturnThis(),
        setScenario: jest.fn().mockReturnThis(),
        saveLog: jest.fn()
    }))
}));

describe('c-your-component', () => {
    it('logs component initialization', () => {
        const element = createElement('c-your-component', {
            is: YourComponent
        });
        document.body.appendChild(element);

        // Verify logger was called
        // Add assertions based on your mock
    });
});
```

## Next Steps

- [Aura Components Guide](aura-guide.md) - Logging in Aura components
- [Best Practices](best-practices.md) - Cross-platform logging patterns
- [Tagging Guide](tagging-guide.md) - Advanced tagging strategies
- [Scenarios Guide](scenarios-guide.md) - Business process tracking
