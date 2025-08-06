# Configuration Guide

Complete guide to configuring Nebula Logger for your Salesforce org.

## Overview

Nebula Logger uses several configuration mechanisms to provide flexible, org-specific settings:

- **LoggerSettings__c**: Custom hierarchy settings for user-specific configuration
- **LoggerParameter__mdt**: Global feature flags and system parameters
- **Custom Metadata Types**: Rules for data masking, tagging, and scenarios
- **Permission Sets**: Security and access control

## LoggerSettings__c

Custom hierarchy settings that can be configured at org, profile, and user levels.

### Key Settings

| Setting | Description | Default |
|---------|-------------|---------|
| **IsEnabled__c** | Enable/disable logging for the user | `true` |
| **LoggingLevel__c** | Minimum logging level to save | `DEBUG` |
| **IsAnonymousModeEnabled__c** | Hide user information in logs | `false` |
| **IsDataMaskingEnabled__c** | Enable automatic data masking | `true` |
| **IsSavingEnabled__c** | Enable saving logs to database | `true` |
| **DefaultScenario__c** | Default scenario for the user | `null` |
| **SystemLogMessageFormat__c** | Format for System.debug() messages | `{LOG_ENTRY_MESSAGE}` |

### Configuration Levels

#### Org Level
Set default values for all users in your org.

#### Profile Level
Override org defaults for specific profiles.

#### User Level
Override profile defaults for specific users.

### Example Configuration

```apex
// Set org-level defaults
LoggerSettings__c orgSettings = LoggerSettings__c.getOrgDefaults();
orgSettings.LoggingLevel__c = 'INFO';
orgSettings.IsDataMaskingEnabled__c = true;
upsert orgSettings;

// Set profile-level overrides
LoggerSettings__c profileSettings = LoggerSettings__c.getInstance(UserInfo.getProfileId());
profileSettings.LoggingLevel__c = 'DEBUG';
upsert profileSettings;

// Set user-level overrides
LoggerSettings__c userSettings = LoggerSettings__c.getInstance(UserInfo.getUserId());
userSettings.IsAnonymousModeEnabled__c = true;
upsert userSettings;
```

## LoggerParameter__mdt

Global feature flags and system parameters that control Nebula Logger behavior.

### Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| **EnableTagging** | Enable the tagging system | `true` |
| **EnableDataMasking** | Enable data masking features | `true` |
| **NormalizeScenarioData** | Store scenarios in LoggerScenario__c | `true` |
| **RequireScenarioUsage** | Require scenarios for logging | `false` |
| **EnableSystemMessages** | Include system messages in logs | `false` |

### Configuration

Create custom metadata records in `LoggerParameter__mdt`:

```xml
<LoggerParameter__mdt>
    <DeveloperName>EnableTagging</DeveloperName>
    <Value__c>true</Value__c>
    <Description__c>Enable the tagging system</Description__c>
</LoggerParameter__mdt>
```

## Data Masking Configuration

Configure automatic data masking using `LogEntryDataMaskRule__mdt`.

### Rule Configuration

| Field | Description |
|-------|-------------|
| **IsEnabled__c** | Enable/disable the rule |
| **SObjectType__c** | Object to apply masking to |
| **FieldName__c** | Field to mask |
| **MaskingType__c** | Type of masking (REDACT, HASH, etc.) |
| **ReplacementValue__c** | Value to use for masking |

### Example Rules

```xml
<!-- Mask email addresses -->
<LogEntryDataMaskRule__mdt>
    <DeveloperName>Mask_Email_Addresses</DeveloperName>
    <SObjectType__c>User</SObjectType__c>
    <FieldName__c>Email</FieldName__c>
    <MaskingType__c>REDACT</MaskingType__c>
    <ReplacementValue__c>***MASKED***</ReplacementValue__c>
</LogEntryDataMaskRule__mdt>

<!-- Hash sensitive IDs -->
<LogEntryDataMaskRule__mdt>
    <DeveloperName>Hash_Sensitive_Ids</DeveloperName>
    <SObjectType__c>Account</SObjectType__c>
    <FieldName__c>TaxId__c</FieldName__c>
    <MaskingType__c>HASH</MaskingType__c>
</LogEntryDataMaskRule__mdt>
```

## Tagging Configuration

Configure automatic tagging using `LogEntryTagRule__mdt`.

### Rule Configuration

| Field | Description |
|-------|-------------|
| **IsEnabled__c** | Enable/disable the rule |
| **SObjectType__c** | Object to apply tagging to |
| **FieldName__c** | Field to evaluate |
| **ComparisonType__c** | Type of comparison |
| **ComparisonValue__c** | Value to compare against |
| **Tags__c** | Tags to apply (one per line) |

### Example Rules

```xml
<!-- Tag error messages -->
<LogEntryTagRule__mdt>
    <DeveloperName>Tag_Error_Messages</DeveloperName>
    <SObjectType__c>LogEntry__c</SObjectType__c>
    <FieldName__c>LoggingLevel__c</FieldName__c>
    <ComparisonType__c>EQUALS</ComparisonType__c>
    <ComparisonValue__c>ERROR</ComparisonValue__c>
    <Tags__c>critical
urgent</Tags__c>
</LogEntryTagRule__mdt>
```

## Scenario Configuration

Configure scenario behavior using `LoggerScenarioRule__mdt`.

### Rule Configuration

| Field | Description |
|-------|-------------|
| **IsEnabled__c** | Enable/disable the rule |
| **Scenario__c** | Scenario name to match |
| **StartTime__c** | When rule becomes active |
| **EndTime__c** | When rule expires |
| **IsLoggerEnabled__c** | Override logger enabled setting |
| **LoggingLevel__c** | Override logging level |

## Permission Sets

Nebula Logger includes three permission sets:

### Logger Admin
Full access to all Logger objects and features:
- Create, read, update, delete on all Logger objects
- Access to Logger Console app
- Ability to configure settings

### Logger User
Basic logging capabilities:
- Create logs and log entries
- Read access to own logs
- Limited configuration access

### Logger Viewer
Read-only access:
- View logs and log entries
- No create/update/delete permissions

## Best Practices

### Security
- Use appropriate permission sets
- Enable data masking for sensitive data
- Consider anonymous mode for public users

### Performance
- Set appropriate logging levels
- Use scenarios to group related logs
- Configure retention policies

### Organization
- Document your configuration
- Use consistent naming conventions
- Test configuration changes in sandbox

## Related Topics

- [Installation Guide](installation.md)
- [Quick Start Guide](quick-start.md)
- [Log Management](management/console.md)
- [Troubleshooting](administration/troubleshooting.md)
