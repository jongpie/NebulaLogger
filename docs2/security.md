---
sidebar_position: 14
title: Security
description: Security model, data protection, and compliance guide
keywords: [security, gdpr, compliance, data masking, privacy]
---

# Security Guide

Complete security, data protection, and compliance guide for Nebula Logger.

## Security Model

### Organization-Wide Defaults

**Default Settings:**
- `Log__c`: Private
- `LogEntry__c`: Controlled by Parent
- `LoggerTag__c`: Public Read Only
- `LogEntryTag__c`: Controlled by Parent
- `LoggerScenario__c`: Public Read Only

### Sharing Model

**Who Can See Logs?**

By default:
- ✅ Users see their own logs
- ✅ Users with "View All Data" see all logs
- ✅ System Administrators see all logs
- ❌ Users cannot see other users' logs

**Configurable Sharing:**
```apex
// Via LoggerSettings__c
LoggerSettings__c.DefaultLogShareAccessLevel__c = 'Read'; // or 'Edit'
```

**Custom Sharing Rules:**
- Create sharing rules on `Log__c` for broader access
- Share logs with roles, groups, or territories
- Use Apex sharing for programmatic sharing

---

## Permission Sets

### Logger End User

**Grants:**
- ✅ Create logs and log entries
- ✅ Read own logs
- ✅ Edit own logs (before processing)
- ✅ Delete own logs (configurable)
- ✅ Read tags and scenarios
- ✅ Create tags via logging

**Does NOT Grant:**
- ❌ Read other users' logs
- ❌ Modify LoggerSettings__c
- ❌ Configure custom metadata
- ❌ Access admin features

**Assign to:** All users who need to create logs

---

### Logger Admin

**Grants (includes all End User permissions plus):**
- ✅ Read all logs
- ✅ Modify LoggerSettings__c
- ✅ Configure custom metadata
- ✅ Manage tags and scenarios
- ✅ Configure data masking rules
- ✅ Access admin dashboards
- ✅ Purge logs

**Assign to:** Logger administrators only

---

## Data Protection

### Data Masking

Automatic protection for sensitive data.

#### Built-in Masking Rules

**Credit Cards:**
- Pattern: `\d{4}[ -]?\d{4}[ -]?\d{4}[ -]?\d{4}`
- Replacement: `**** **** **** ****`
- Example: `4111 1111 1111 1111` → `**** **** **** ****`

**Social Security Numbers:**
- Pattern: `\d{3}-\d{2}-\d{4}`
- Replacement: `***-**-****`
- Example: `123-45-6789` → `***-**-****`

**Email Addresses:**
- Pattern: `[\w.-]+@[\w.-]+\.\w+`
- Replacement: `***@***.***`
- Example: `user@example.com` → `***@***.***`

#### Custom Masking Rules

Configure via `LogEntryDataMaskRule__mdt`:

```apex
// Fields:
- DeveloperName: Rule identifier
- IsEnabled__c: true/false
- RegularExpressionPattern__c: Regex pattern
- ReplacementText__c: Masked value
```

**Example:**
```
DeveloperName: API_Key
RegularExpressionPattern__c: api_key_[a-zA-Z0-9]{32}
ReplacementText__c: api_key_REDACTED
```

#### Field-Level Masking

Mask specific SObject fields:

```apex
// In LoggerParameter__mdt
MaskFieldsInData__c = true

// Fields are automatically masked in record JSON
Logger.info('Processing account')
    .setRecord(account); // Sensitive fields masked
```

#### Disable Masking (Not Recommended)

```apex
LoggerSettings__c settings = LoggerSettings__c.getInstance();
settings.IsDataMaskingEnabled__c = false;
upsert settings;
```

---

## GDPR Compliance

### Right to Access

Users can query their own logs:

```apex
List<Log__c> myLogs = [
    SELECT Id, CreatedDate, TotalLogEntries__c
    FROM Log__c
    WHERE LoggedByUsername__c = :UserInfo.getUserName()
    ORDER BY CreatedDate DESC
];
```

### Right to Erasure ("Right to be Forgotten")

#### Manual Deletion

```apex
// Delete specific user's logs
List<Log__c> logsToDelete = [
    SELECT Id 
    FROM Log__c 
    WHERE LoggedByUsername__c = 'user@example.com'
];
delete logsToDelete;
```

#### Automated Deletion

Configure retention policies:

```apex
LoggerSettings__c.DefaultNumberOfDaysToRetainLogs__c = 90;
```

Use the included purge mechanism:
- Scheduled batch job
- Configurable retention period
- Soft delete option
- Hard delete option

See [Data Management](data-management.md) for details.

### Right to Portability

Export logs via:
- Data Export Service
- Dataloader
- Workbench
- Custom export solution

### Data Processing Agreements

**Your responsibilities:**
1. Document logging practices
2. Include in privacy policy
3. Obtain consent where required
4. Configure appropriate retention
5. Implement deletion processes

**Nebula Logger provides:**
- ✅ Data masking tools
- ✅ Retention automation
- ✅ Deletion capabilities
- ✅ Export-friendly data model

---

## Compliance Frameworks

### SOC 2

**Controls Supported:**
- **Logging and Monitoring** - Comprehensive audit trail
- **Change Management** - Log all changes
- **Incident Response** - Error tracking
- **Access Control** - User-based logging

**Implementation:**
```apex
// Log all security events
Logger.setScenario('Security Audit');
Logger.warn('Failed login attempt for user: ' + username)
    .addTag('security')
    .addTag('authentication');
Logger.saveLog();
```

### HIPAA

**PHI Protection:**
- ✅ Enable data masking
- ✅ Configure retention policies
- ✅ Implement access controls
- ✅ Enable audit trails

**Best Practices:**
```apex
// Mask PHI in logs
LoggerSettings__c.IsDataMaskingEnabled__c = true;

// Avoid logging PHI directly
Logger.info('Patient record updated: ' + patientId); // ID only
// DON'T: Logger.info('Patient name: ' + patient.Name); // PHI!
```

### PCI DSS

**Requirements:**
- ✅ Mask credit card numbers (automatic)
- ✅ Log access to cardholder data
- ✅ Implement retention policies
- ✅ Restrict access to logs

**Example:**
```apex
Logger.info('Payment processed')
    .addTag('pci-audit')
    .addTag('payment');
Logger.saveLog();
```

---

## Field-Level Security

### Respect FLS

Logger respects Salesforce Field-Level Security:

```apex
// If user can't see Account.AnnualRevenue
Account acc = [SELECT Id, Name, AnnualRevenue FROM Account LIMIT 1];
Logger.info('Processing account').setRecord(acc);
// AnnualRevenue will not be captured if user lacks FLS
```

### Strip Inaccessible Fields

Enable in settings:

```apex
LoggerSettings__c.IsRecordFieldStrippingEnabled__c = true;
```

---

## Object-Level Security

### Permissions Required

**To Log:**
- Create on `LogEntryEvent__e` (granted via permission set)

**To View Logs:**
- Read on `Log__c`, `LogEntry__c`, `LogEntryTag__c`

**To Manage:**
- Full CRUD on all objects (Logger Admin only)

---

## API Security

### Session ID Protection

Logger does not store session IDs by default.

**If you need session tracking:**
```apex
// Enable cautiously
LoggerParameter__mdt: QUERY_AUTH_SESSION_DATA = true
```

**⚠️ Warning:** Session IDs are sensitive credentials!

### API Callout Logging

**Mask sensitive headers:**

```apex
HttpRequest req = new HttpRequest();
req.setHeader('Authorization', 'Bearer ' + apiKey);

// Log request (authorization header will be masked)
Logger.info('API callout to ' + req.getEndpoint());
Logger.saveLog();
```

---

## Anonymous Mode

Log without user context (useful for public sites):

```apex
LoggerSettings__c.IsAnonymousModeEnabled__c = true;
```

**Effect:**
- Logs created without user attribution
- Useful for Experience Cloud public access
- Less audit trail detail

**Use Cases:**
- Public websites
- Unauthenticated APIs
- Guest user contexts

---

## Security Best Practices

### 1. Enable Data Masking

```apex
LoggerSettings__c.IsDataMaskingEnabled__c = true;
```

### 2. Configure Retention Policies

```apex
LoggerSettings__c.DefaultNumberOfDaysToRetainLogs__c = 90; // or per your policy
```

### 3. Limit Log Access

- Assign Logger End User to regular users only
- Reserve Logger Admin for administrators
- Use sharing rules sparingly

### 4. Avoid Logging Sensitive Data

```apex
// ❌ Bad: Logging sensitive data
Logger.info('User SSN: ' + user.SSN__c);

// ✅ Good: Log IDs only
Logger.info('User record updated: ' + user.Id);

// ✅ Good: Use data masking
Logger.info('Processing sensitive data: ' + sensitiveValue); // Auto-masked
```

### 5. Monitor Log Access

```apex
// Create audit trail for log access
SELECT Id, CreatedBy.Name, CreatedDate, Action
FROM Log__c
WHERE Action = 'View'
ORDER BY CreatedDate DESC
```

### 6. Regular Security Reviews

- Review masking rules quarterly
- Audit log access patterns
- Update retention policies
- Test deletion processes

---

## Threat Model

### Threats Mitigated

- ✅ **Data leakage** - Data masking
- ✅ **Unauthorized access** - Sharing model
- ✅ **Data retention** - Automated purging
- ✅ **Compliance violations** - Configurable controls

### Residual Risks

- ⚠️ **Over-logging** - User discretion required
- ⚠️ **Masked data inference** - Patterns may reveal info
- ⚠️ **Admin access** - Admins see all logs

---

## Incident Response

### Security Event Logging

```apex
Logger.setScenario('Security Incident');
Logger.error('Unauthorized access attempt')
    .addTag('security')
    .addTag('incident')
    .addTag('critical');
Logger.saveLog();
```

### Log Monitoring

Set up alerts for:
- Multiple failed logins
- Unauthorized access attempts
- Data export activities
- Unusual log volumes

See [Monitoring Guide](monitoring-guide.md) for alert setup.

---

## Vulnerability Reporting

### Report Security Issues

**Do NOT open public GitHub issues for security vulnerabilities!**

Instead:
1. Use [GitHub Security Advisories](https://github.com/jongpie/NebulaLogger/security/advisories)
2. Or email the maintainer directly
3. Include:
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Response Timeline

- **Acknowledgment:** Within 48 hours
- **Assessment:** Within 1 week
- **Fix (if confirmed):** ASAP for supported versions
- **Public disclosure:** After fix is available

---

## Security Checklist

Before going to production:

- [ ] Data masking enabled
- [ ] Retention policy configured
- [ ] Permission sets assigned correctly
- [ ] Sharing rules reviewed
- [ ] Field-level security tested
- [ ] Anonymous mode configured (if needed)
- [ ] Security event logging implemented
- [ ] Log access monitoring enabled
- [ ] Incident response plan documented
- [ ] Compliance requirements mapped

---

## See Also

- [Admin Guide](admin-guide.md) - Configuration details
- [Data Management](data-management.md) - Retention and purging
- [Best Practices](best-practices.md) - Security patterns
- [Compliance](https://github.com/jongpie/NebulaLogger/wiki/Compliance) - Detailed compliance guides
