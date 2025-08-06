# Scenario-Based Logging

Scenario-based logging allows you to group and filter logs by business scenarios, making it easier to track related activities across your application.

## Overview

Scenarios are used to identify modules or groupings of logs for the current transaction. They help organize logs by business context, making debugging and monitoring more effective.

## Basic Usage

### Setting a Scenario

```apex
Logger.setScenario('User Registration');
Logger.info('Registration process started');
// ... your business logic ...
Logger.info('Registration process completed');
Logger.saveLog();
```

### Getting Current Scenario

```apex
String currentScenario = Logger.getScenario();
System.debug('Current scenario: ' + currentScenario);
```

### Ending a Scenario

```apex
Logger.setScenario('First Scenario');
Logger.info('First scenario log');
Logger.setScenario('Second Scenario');
Logger.info('Second scenario log');
Logger.endScenario('Second Scenario');
// Now back to 'First Scenario'
```

## Scenario Rules

You can configure automatic scenario behavior using `LoggerScenarioRule__mdt` custom metadata:

### Configuration Options

- **IsEnabled__c**: Enable/disable the rule
- **Scenario__c**: The scenario name to match
- **StartTime__c**: When the rule becomes active
- **EndTime__c**: When the rule expires
- **IsLoggerEnabled__c**: Override logger enabled setting
- **IsAnonymousModeEnabled__c**: Override anonymous mode
- **IsDataMaskingEnabled__c**: Override data masking
- **IsSavingEnabled__c**: Override saving enabled
- **SaveMethod__c**: Override save method
- **UserLoggingLevel__c**: Override logging level

### Example Rule

Create a rule for "High Priority" scenarios that:
- Enables data masking
- Sets logging level to ERROR
- Uses synchronous DML for immediate saving

## Data Storage

Scenarios are stored in two ways:

### Normalized Storage (Default)

When `LoggerParameter.NormalizeScenarioData` is `true`:
- Scenarios are stored in the `LoggerScenario__c` object
- `Log__c.TransactionScenario__c` references `LoggerScenario__c`
- `LogEntry__c.EntryScenario__c` references `LoggerScenario__c`

### Text Storage

When `LoggerParameter.NormalizeScenarioData` is `false`:
- Scenarios are stored as text in `Log__c.TransactionScenarioName__c`
- Scenarios are stored as text in `LogEntry__c.EntryScenarioName__c`

## Best Practices

### Naming Conventions

Use descriptive, hierarchical scenario names:
```
User Management
├── User Registration
├── User Profile Update
└── User Deactivation

Order Processing
├── Order Creation
├── Payment Processing
└── Order Fulfillment
```

### Scenario Lifecycle

1. **Set scenario early** in your transaction
2. **Use consistent naming** across your application
3. **End scenarios** when appropriate to revert to previous state
4. **Document scenarios** for team understanding

### Performance Considerations

- Scenarios are cached per transaction
- Use meaningful but concise names
- Avoid dynamic scenario names that change frequently

## Examples

### User Registration Flow

```apex
Logger.setScenario('User Registration');
Logger.info('Starting user registration for: ' + userEmail);

try {
    // Create user account
    Logger.info('Creating user account');
    User newUser = createUser(userData);
    
    // Send welcome email
    Logger.setScenario('User Registration - Welcome Email');
    Logger.info('Sending welcome email');
    sendWelcomeEmail(newUser);
    Logger.endScenario('User Registration - Welcome Email');
    
    Logger.info('User registration completed successfully');
} catch (Exception e) {
    Logger.error('User registration failed', e);
} finally {
    Logger.saveLog();
}
```

### Batch Processing

```apex
public class AccountProcessor implements Database.Batchable<SObject> {
    private String parentScenario;
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        this.parentScenario = Logger.getScenario();
        Logger.setScenario('Account Processing - Start');
        Logger.info('Starting account processing batch');
        Logger.saveLog();
        return Database.getQueryLocator('SELECT Id FROM Account');
    }
    
    public void execute(Database.BatchableContext context, List<Account> scope) {
        Logger.setParentLogTransactionId(this.parentScenario);
        Logger.setScenario('Account Processing - Execute');
        
        for (Account acc : scope) {
            Logger.info('Processing account: ' + acc.Id);
            // Process account
        }
        
        Logger.saveLog();
    }
    
    public void finish(Database.BatchableContext context) {
        Logger.setParentLogTransactionId(this.parentScenario);
        Logger.setScenario('Account Processing - Finish');
        Logger.info('Account processing batch completed');
        Logger.saveLog();
    }
}
```

## Related Topics

- [Logging in Apex](logging/apex.md)
- [Configuration](configuration.md)
- [Data Model](data-model.md)
- [Log Management](management/console.md)
