# CLAUDE.md - Nebula Logger Development Guide for AI Assistants

## Project Overview

**Nebula Logger** is the most robust observability solution for Salesforce, built 100% natively on the Salesforce platform. It provides unified logging across Apex, Lightning Components (LWC & Aura), Flow, OmniStudio, and integrations.

- **Current Version**: v4.16.2
- **License**: MIT
- **Repository**: https://github.com/jongpie/NebulaLogger
- **API Version**: 63.0
- **Packaging**: Available as both unlocked package (no namespace) and managed package (`Nebula` namespace)

### Core Architecture

Nebula Logger uses an event-driven pub/sub messaging architecture built on platform events (`LogEntryEvent__e`). The system stores actionable observability data in 5 custom objects:

- `Log__c` - Parent log records
- `LogEntry__c` - Individual log entry records
- `LogEntryTag__c` - Junction object for tags
- `LoggerTag__c` - Tag definitions
- `LoggerScenario__c` - Scenario configurations

## Codebase Structure

### Directory Organization

```
NebulaLogger/
├── nebula-logger/
│   ├── core/                          # Core package (primary development area)
│   │   ├── main/                      # Production code
│   │   │   ├── configuration/         # Configuration classes & custom metadata
│   │   │   ├── log-management/        # Log management classes, LWCs, objects
│   │   │   └── logger-engine/         # Core logging engine (Logger, LogEntryEventBuilder)
│   │   └── tests/                     # Test classes (mirrors main structure)
│   │       ├── configuration/
│   │       ├── log-management/
│   │       └── logger-engine/
│   ├── plugins/                       # Plugin packages
│   │   ├── async-failure-additions/
│   │   ├── big-object-archiving/
│   │   ├── log-retention-rules/
│   │   ├── slack/
│   │   └── logger-admin-dashboard/
│   ├── extra-tests/                   # Additional integration tests
│   ├── recipes/                       # Example implementations
│   ├── dev/                           # Development metadata
│   └── managed-package/               # Managed package configuration
├── config/
│   ├── linters/                       # ESLint, PMD, Prettier configs
│   ├── scratch-orgs/                  # Scratch org definitions
│   └── docs/                          # Documentation generation configs
├── scripts/                           # Build & deployment scripts
├── docs/                              # Generated documentation
└── .github/workflows/                 # CI/CD pipelines
```

### Key Code Locations

- **Main Logger Class**: `nebula-logger/core/main/logger-engine/classes/Logger.cls`
- **Log Entry Builder**: `nebula-logger/core/main/logger-engine/classes/LogEntryEventBuilder.cls`
- **Logger LWC**: `nebula-logger/core/main/logger-engine/lwc/logger/`
- **Configuration**: `nebula-logger/core/main/configuration/`
- **Custom Metadata Types**: `nebula-logger/core/main/configuration/customMetadata/`
- **Test Classes**: `nebula-logger/core/tests/` (naming convention: `*_Tests.cls`)

### Module Breakdown

#### Configuration Module
- `LoggerParameter.cls` - Custom metadata parameter handling
- `LoggerCache.cls` - Platform cache management
- `LoggerFieldMapper.cls` - Field mapping for custom fields
- `LoggerPlugin.cls` - Plugin framework base
- `LoggerScenarioRule.cls` - Scenario-based logging rules

#### Logger Engine Module
- `Logger.cls` - Main logging API for Apex
- `LogEntryEventBuilder.cls` - Fluent API for building log entries
- `LogMessage.cls` - Dynamic string formatting with lazy evaluation
- `CallableLogger.cls` - Callable interface for ISV integration
- `FlowLogger.cls`, `FlowLogEntry.cls`, `FlowRecordLogEntry.cls`, `FlowCollectionLogEntry.cls` - Flow integration
- `ComponentLogger.cls` - Lightning component integration
- `logger` LWC - JavaScript logging API

#### Log Management Module
- `LogHandler.cls` - Handles Log__c record triggers
- `LogEntryHandler.cls` - Handles LogEntry__c record triggers
- `LogBatchPurger.cls` - Batch job for purging old logs
- `LoggerEmailSender.cls` - Email notification functionality
- Various UI controllers and LWCs for log management

## Development Environment Setup

### Prerequisites

```json
{
  "node": ">= 20.16.0",
  "npm": ">= 10.3.0"
}
```

### Initial Setup

1. **Clone and Install Dependencies**
   ```bash
   git clone https://github.com/jongpie/NebulaLogger.git
   cd NebulaLogger
   npm install
   ```

2. **Configure Git Hooks**
   Git hooks are automatically set up by `npm install` via Husky. The pre-commit hook runs:
   - Prettier formatting (auto-fix)
   - ESLint for LWC (auto-fix where possible)
   - PMD scanner for Apex

3. **Create a Scratch Org**
   ```bash
   # Base scratch org (recommended for most development)
   sf org create scratch --no-namespace --no-track-source --duration-days 30 \
     --definition-file ./config/scratch-orgs/base-scratch-def.json --set-default

   # Deploy metadata
   sf project deploy start --source-dir ./nebula-logger/

   # Assign permission set
   npm run permset:assign:admin
   ```

### Available Scratch Org Types

- **base-scratch-def.json** - Base configuration (default)
- **advanced-scratch-def.json** - With advanced features
- **event-monitoring-scratch-def.json** - Event monitoring enabled
- **experience-cloud-scratch-def.json** - Experience Cloud enabled
- **omnistudio-scratch-def.json** - OmniStudio enabled
- **platform-cache-scratch-def.json** - Platform cache enabled

## Testing Conventions

### Apex Testing

**Naming Convention**: `<ClassName>_Tests.cls`

**Key Patterns**:

1. **Use Mock Configuration**
   ```apex
   static {
     // Don't use the org's actual custom metadata records when running tests
     LoggerConfigurationSelector.useMocks();
   }
   ```

2. **Test Method Naming**: Use descriptive `it_should_*` pattern
   ```apex
   @IsTest
   static void it_should_return_version_number() {
     // Test implementation
   }
   ```

3. **Parallel Execution**: Tests use `@IsTest(IsParallel=true)` where possible

4. **PMD Suppressions**: Use sparingly, typically for test classes
   ```apex
   @SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
   @IsTest(IsParallel=true)
   private class MyClass_Tests {
     // ...
   }
   ```

### JavaScript/LWC Testing

- **Framework**: Jest with `@salesforce/sfdx-lwc-jest`
- **Test Location**: `__tests__/` subdirectory within each LWC folder
- **Mock Data**: Stored in `__tests__/data/` subdirectories
- **Coverage Directory**: `./test-coverage/lwc`

### Running Tests

```bash
# Run all tests (Apex + LWC)
npm test

# Apex tests only
npm run test:apex

# Apex tests without coverage
npm run test:apex:nocoverage

# LWC tests only
npm run test:lwc

# Run core test suite
npm run test:apex:suite:core
```

### Test Coverage Requirements

- **Apex**: 75%+ code coverage required for deployment
- **LWC**: Coverage tracked and reported to Codecov.io
- The pipeline runs tests both **synchronously** and **asynchronously** to validate session handling

## Code Quality & Standards

### Formatting & Linting

**Prettier Configuration** (.prettierrc):
```json
{
  "printWidth": 160,
  "tabWidth": 2,
  "singleQuote": true,
  "trailingComma": "none",
  "arrowParens": "avoid"
}
```

**PMD Rules**:
- Ruleset: `config/linters/pmd-ruleset.xml`
- Severity threshold: 3
- Excluded rules: `ApexAssertionsShouldIncludeMessage`, `AvoidLogicInTrigger`, `EagerlyLoadedDescribeSObjectResult`

**ESLint**:
- Config: `config/linters/.eslintrc.json`
- Uses `@salesforce/eslint-config-lwc` with Prettier integration

### Code Quality Commands

```bash
# Fix formatting
npm run prettier:fix

# Verify formatting
npm run prettier:verify

# Scan Apex code
npm run scan:apex

# Scan LWC code
npm run scan:lwc

# Scan all code
npm run scan

# Fix LWC issues
npm run scan:fix:lwc
```

### Apex Coding Standards

1. **File Headers**: All Apex files include MIT license header
   ```apex
   //------------------------------------------------------------------------------------------------//
   // This file is part of the Nebula Logger project, released under the MIT License.                //
   // See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
   //------------------------------------------------------------------------------------------------//
   ```

2. **Access Modifiers**:
   - Use `public` for classes/methods meant to be used within the org
   - Use `global` only for managed package API (very selective)
   - Use `@TestVisible` sparingly

3. **Documentation**:
   - ApexDocs are auto-generated from code
   - Use meaningful class and method names
   - Add JavaDoc-style comments for complex logic

4. **Naming Conventions**:
   - Classes: `PascalCase`
   - Methods: `camelCase`
   - Constants: `UPPER_SNAKE_CASE`
   - Variables: `camelCase`

## CI/CD Workflows

### Build Pipeline (.github/workflows/build.yml)

The build pipeline runs on:
- Push to `main` branch
- Pull requests (opened, synchronized, reopened)

**Pipeline Stages**:

1. **Code Quality Tests**
   - Prettier verification
   - ESLint for LWC
   - PMD for Apex
   - Package version number validation
   - Documentation verification (currently disabled)

2. **LWC Jest Tests**
   - Runs all LWC unit tests
   - Uploads coverage to Codecov.io

3. **Parallel Scratch Org Tests** (runs in parallel):
   - Base scratch org
   - Advanced scratch org
   - Event monitoring scratch org
   - Experience Cloud scratch org
   - OmniStudio scratch org
   - Platform cache scratch org

4. **Package Creation** (PR only):
   - Creates managed package beta version
   - Creates unlocked package release candidate
   - Auto-commits package version to PR

5. **Package Promotion** (main branch only):
   - Promotes package versions to released status

### Test Execution Pattern

Each scratch org test:
1. Creates scratch org with specific features
2. Validates core source with `RunLocalTests`
3. Deploys all source
4. Runs Apex tests **asynchronously** (tests without active session)
5. Runs Apex tests **synchronously** (tests with active session)
6. Deletes scratch org

### Authentication

Uses JWT-based authentication with secrets:
- `DEV_HUB_AUTH_URL`
- `DEV_HUB_BOT_USERNAME`
- `DEV_HUB_CONSUMER_KEY`
- `DEV_HUB_JWT_SERVER_KEY`

## Package Management

### Package Types

1. **Core Unlocked Package** (Recommended)
   - No namespace
   - Faster release cycle
   - All Apex methods available (public/protected)
   - Plugin framework available
   - Auto-calls `System.debug()`

2. **Managed Package**
   - `Nebula` namespace
   - Slower, more stable release cycle
   - Only global methods in API
   - No plugin framework
   - Manual `System.debug()` calls required

### Package Scripts

```bash
# Create unlocked package version
npm run package:version:create:unlocked

# Create managed package version
npm run package:version:create:managed

# Sync package version number
npm run package:version:number:fix

# Validate package version number
npm run package:version:number:verify

# Generate package manifest
npm run package:manifest:generate:core
```

### Plugin Packages

```bash
# Create plugin package versions
npm run plugin:version:create:async-failure-additions
npm run plugin:version:create:big-object
npm run plugin:version:create:log-retention-rules
npm run plugin:version:create:slack
```

## Key Development Patterns

### 1. Logger Singleton Pattern

The `Logger` class maintains transaction-scoped state:
```apex
// Static methods for transaction-level configuration
Logger.setField(Schema.SObjectField field, Object value);
Logger.setSaveMethod(SaveMethod saveMethod);

// Instance methods via builder pattern
Logger.error('message').setRecord(record).addTag('tag').saveLog();
```

### 2. Builder Pattern (Fluent API)

`LogEntryEventBuilder` uses method chaining:
```apex
Logger.error('Error occurred')
  .setRecord(myRecord)
  .addTag('critical')
  .addTags(myTagList)
  .setField(LogEntryEvent__e.CustomField__c, 'value');
```

### 3. Platform Event Architecture

- Log entries are built in memory as `LogEntryEvent__e` records
- Published to event bus via `Logger.saveLog()`
- Platform event subscribers process and create `Log__c` and `LogEntry__c` records
- Supports multiple save methods: `EVENT_BUS`, `QUEUEABLE`, `REST`, `SYNCHRONOUS_DML`

### 4. Plugin Framework

Supports Apex and Flow plugins via:
- Custom metadata type `LoggerPlugin__mdt`
- Triggerable interface: `LoggerPlugin.Triggerable`
- Plugins execute on trigger events (BEFORE_INSERT, AFTER_INSERT, etc.)

Example plugin:
```apex
public class MyPlugin implements LoggerPlugin.Triggerable {
  public void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext input) {
    if (input.sobjectType != Schema.Log__c.SObjectType) {
      return;
    }
    // Plugin logic here
  }
}
```

### 5. Configuration via Custom Metadata

Heavily uses custom metadata for configuration:
- `LoggerParameter__mdt` - Feature flags and settings
- `LoggerPlugin__mdt` - Plugin definitions
- `LoggerFieldMapping__mdt` - Custom field mappings
- `LogEntryTagRule__mdt` - Automatic tagging rules
- `LogEntryDataMaskRule__mdt` - Data masking rules
- `LogStatus__mdt` - Log status definitions
- `LoggerScenarioRule__mdt` - Scenario-based logging

### 6. Selector Pattern

Data queries are encapsulated in selector classes:
- `LoggerConfigurationSelector` - Configuration queries
- `LoggerEngineDataSelector` - Logger engine queries
- `LogManagementDataSelector` - Log management queries

### 7. Mock Framework for Testing

```apex
static {
  // Use mock configuration instead of org metadata
  LoggerConfigurationSelector.useMocks();
}
```

## Working with Documentation

### Auto-Generated Documentation

- **Apex Docs**: Generated using `@cparra/apexdocs`
- **LWC Docs**: Generated using `jsdoc-to-markdown`

```bash
# Generate and fix documentation
npm run docs:fix

# Verify docs are up-to-date
npm run docs:verify
```

### Documentation Locations

- Apex: `docs/apex/`
- LWC: `docs/lightning-components/`
- Wiki: https://github.com/jongpie/NebulaLogger/wiki

## Common Development Tasks

### Adding a New Feature

1. Create a new branch from `main`
2. Implement feature in `nebula-logger/core/main/`
3. Add tests in `nebula-logger/core/tests/`
4. Ensure all quality checks pass: `npm run scan && npm test`
5. Update package version number in `sfdx-project.json`
6. Create pull request with detailed description

### Adding Custom Fields

1. **To Platform Event** (`LogEntryEvent__e`):
   - Add field to `nebula-logger/core/main/logger-engine/objects/LogEntryEvent__e/fields/`

2. **Set in Apex**:
   ```apex
   // Transaction-level
   Logger.setField(LogEntryEvent__e.MyField__c, 'value');

   // Entry-level
   Logger.error('message').setField(LogEntryEvent__e.MyField__c, 'value');
   ```

3. **Set in JavaScript**:
   ```javascript
   // Component-level
   this.logger.setField({ MyField__c: 'value' });

   // Entry-level
   this.logger.error('message').setField({ MyField__c: 'value' });
   ```

4. **Map to Custom Object**:
   - Create equivalent field on `Log__c`, `LogEntry__c`, or `LoggerScenario__c`
   - Create `LoggerFieldMapping__mdt` record to map fields

### Working with Plugins

1. Create plugin class implementing `LoggerPlugin.Triggerable`
2. Create `LoggerPlugin__mdt` record with:
   - API name of plugin class
   - Plugin type (Apex or Flow)
   - SObject type to apply to
   - Execution order
3. Optionally add `LoggerParameter__mdt` records for configuration

### Running Specific Test Suites

The repository includes test suites in scratch org configuration:
- `LoggerCore` - Core test suite used for package validation

```bash
npm run test:apex:suite:core
```

## AI Assistant Guidelines

### When Making Changes

1. **Read Before Editing**: Always read files before modifying them
2. **Test Coverage**: Add/update tests for any code changes
3. **Follow Patterns**: Use existing patterns (builders, selectors, handlers)
4. **Documentation**: Update docs if adding public APIs
5. **Package Version**: Increment version in `sfdx-project.json` for core changes
6. **Quality Checks**: Run `npm run scan` before committing
7. **Test Locally**: Run tests locally when possible

### Understanding the Codebase

1. **Entry Points**:
   - Apex: `Logger.cls`
   - JavaScript: `logger` LWC
   - Flow: `FlowLogger.cls` and invocable classes

2. **Data Flow**:
   - Code → `LogEntryEvent__e` → Platform Event Bus → Event Trigger → `Log__c`/`LogEntry__c`

3. **Extension Points**:
   - Plugin framework for custom logic
   - Custom field mappings for org-specific fields
   - Custom metadata for configuration

### Common Pitfalls to Avoid

1. **Don't modify custom metadata in tests** - Use `LoggerConfigurationSelector.useMocks()`
2. **Don't assume namespace** - Code works with and without namespace
3. **Don't break managed package API** - Be careful with global methods
4. **Don't skip tests** - Pipeline requires all tests to pass
5. **Consider both packages** - Changes should work in unlocked AND managed packages
6. **Remember session context** - Tests run both with and without active sessions

### Debugging Tips

1. **Tail Logs**: `npm run apex:tail:log`
2. **Preview Recipes**: `npm run lwc:preview:recipes`
3. **Check Pipeline**: Review `.github/workflows/build.yml` for validation steps
4. **Use Mock Data**: Test utilities in `nebula-logger/core/tests/`

## Resources

- **Main Repository**: https://github.com/jongpie/NebulaLogger
- **Wiki**: https://github.com/jongpie/NebulaLogger/wiki
- **Apex Docs**: https://jongpie.github.io/NebulaLogger/
- **Issues**: https://github.com/jongpie/NebulaLogger/issues
- **Contributing Guide**: See `CONTRIBUTING.md`
- **Code of Conduct**: See `CODE_OF_CONDUCT.md`

## Version History

This CLAUDE.md is current as of:
- **Nebula Logger Version**: v4.16.2
- **API Version**: 63.0
- **Last Updated**: 2025-12-17

When working with future versions, verify that patterns and locations described here are still current.
