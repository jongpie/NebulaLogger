# Installation Guide

Step-by-step guide to installing Nebula Logger in your Salesforce org.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation Methods](#installation-methods)
- [Unlocked Package Installation](#unlocked-package-installation)
- [Managed Package Installation](#managed-package-installation)
- [Source Code Installation](#source-code-installation)
- [Post-Installation Steps](#post-installation-steps)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Upgrading](#upgrading)

## Prerequisites

### Org Requirements

- **Salesforce Edition:** Enterprise, Unlimited, Performance, or Developer Edition
- **API Version:** 65.0 or higher (Winter '26)
- **Platform Events:** Must be enabled (enabled by default in most editions)
- **My Domain:** Required (highly recommended)

### User Requirements

- **System Administrator** profile or equivalent permissions
- Ability to install packages
- Modify All Data permission (for post-installation configuration)

### Storage Considerations

Estimate storage needs:
- **Per log entry:** 5-10 KB average
- **10,000 entries:** ~50-100 MB
- **1 million entries:** ~5-10 GB

Ensure adequate data storage before installation.

## Installation Methods

Choose one of three installation methods:

| Method | Pros | Cons | Best For |
|--------|------|------|----------|
| **Unlocked Package** ✅ | No namespace, flexible, modern | Requires Salesforce CLI | Most orgs (recommended) |
| **Managed Package** | AppExchange, easy install, automatic upgrades | Namespace prefix, some limitations | Production orgs, ISVs |
| **Source Code** | Full customization | Manual deployment, no upgrade path | Advanced users, contributors |

## Unlocked Package Installation

### Method 1: Installation Link (Easiest)

1. **Get the Installation Link**
   - Visit the [Nebula Logger GitHub Releases](https://github.com/jongpie/NebulaLogger/releases)
   - Find the latest release
   - Copy the **Unlocked Package Installation URL**

2. **Install the Package**
   - Paste the URL into your browser
   - Log in to your Salesforce org
   - Choose **Install for All Users** (recommended)
   - Click **Install**
   - Wait for installation to complete (2-5 minutes)

3. **Approve Third-Party Access** (if prompted)
   - Click **Continue**
   - Click **Done**

### Method 2: Salesforce CLI

**Prerequisites:**
- [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli) installed
- Authenticated to your target org

**Steps:**

1. **Authenticate to Your Org**
   ```bash
   sf org login web --alias my-org
   ```

2. **Install the Package**
   ```bash
   sf package install --package 04t5Y000001Mk0MQAS --target-org my-org --wait 10
   ```
   
   Replace the package ID with the latest version from the [releases page](https://github.com/jongpie/NebulaLogger/releases).

3. **Wait for Installation**
   ```
   Installing package... done
   ```

### Method 3: Visual Studio Code

If using VS Code with Salesforce Extensions:

1. Open Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`)
2. Type: **SFDX: Install Package**
3. Enter the package version ID: `04t5Y000001Mk0MQAS`
4. Select your target org
5. Wait for installation

## Managed Package Installation

### AppExchange Installation

1. **Visit AppExchange**
   - Go to [Salesforce AppExchange](https://appexchange.salesforce.com/)
   - Search for "Nebula Logger"
   - Click **Get It Now**

2. **Choose Installation Type**
   - Select **Install in Production** or **Install in Sandbox**
   - Log in to your org

3. **Configure Installation**
   - Choose **Install for All Users**
   - Click **Install**
   - Accept security review
   - Approve third-party API access

4. **Wait for Completion**
   - Installation takes 2-5 minutes
   - You'll receive an email when complete

### Managed Package Differences

The managed package includes:
- `Nebula` namespace prefix on all objects and classes
- Example: `Nebula__Log__c`, `Nebula.Logger`
- Some features limited (e.g., Chatter Topics tagging)
- Automatic upgrade notifications

**Code example with namespace:**
```apex
Nebula.Logger.info('Hello from managed package');
Nebula.Logger.saveLog();
```

## Source Code Installation

For contributors or advanced users who want full control.

### Prerequisites

- [Git](https://git-scm.com/) installed
- [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli) installed
- [Node.js](https://nodejs.org/) 20.16.0+ and npm 10.3.0+
- Authenticated to your target org

### Steps

1. **Clone the Repository**
   ```bash
   git clone https://github.com/jongpie/NebulaLogger.git
   cd NebulaLogger
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Authenticate to Your Org**
   ```bash
   sf org login web --alias my-org --set-default
   ```

4. **Deploy the Source**
   ```bash
   sf project deploy start --source-dir nebula-logger/core/main
   ```

5. **Deploy Additional Components** (optional)
   ```bash
   # Install plugins (optional)
   sf project deploy start --source-dir nebula-logger/plugins/slack
   sf project deploy start --source-dir nebula-logger/plugins/big-object-archiving
   ```

6. **Run Tests** (recommended)
   ```bash
   npm run test:apex
   ```

## Post-Installation Steps

Complete these steps after installation:

### 1. Assign Permission Sets

**For All Users:**
1. Navigate to **Setup → Users → Permission Sets**
2. Open **Logger End User**
3. Click **Manage Assignments**
4. Click **Add Assignments**
5. Select users who should log
6. Click **Assign**

**For Administrators:**
1. Open **Logger Admin** permission set
2. Click **Manage Assignments**
3. Assign to admin users

### 2. Configure Organization Settings

1. Navigate to **Setup → Custom Settings → Logger Settings**
2. Click **Manage**
3. Click **New** (for Organization Default)
4. Configure settings:

| Setting | Recommended Value |
|---------|------------------|
| Is Enabled | ✅ Checked |
| Logging Level | INFO |
| Is Apex System Debug Logging Enabled | ✅ Checked |
| Is Data Masking Enabled | ✅ Checked |
| Default Save Method | EVENT_BUS |

5. Click **Save**

### 3. Add Logger Console to App Launcher

1. Navigate to **Setup → App Manager**
2. Find **Logger Console**
3. Click **Edit**
4. Under **App Options**, check **Show in Lightning Experience**
5. Under **User Profiles**, add relevant profiles
6. Click **Save**

### 4. Create Report Folder (Optional)

1. Navigate to **Reports** tab
2. Create a new folder: **Logger Reports**
3. Share with appropriate users

### 5. Configure Retention Policy (Recommended)

See [Data Management](admin-guide.md#data-management) for retention strategies.

## Verification

### Test Basic Logging

1. **Open Developer Console**
   - Click gear icon → Developer Console

2. **Execute Anonymous Apex**
   ```apex
   Logger.info('Installation test successful!');
   Logger.saveLog();
   ```

3. **Verify Log Created**
   - Navigate to **App Launcher → Logger Console**
   - Click **Logs** tab
   - Verify you see a new log record
   - Open the log and verify it has a log entry

### Test LWC Logging (Optional)

Create a test LWC component:

**testLogger.js:**
```javascript
import { LightningElement } from 'lwc';
import { getLogger } from 'c/logger';

export default class TestLogger extends LightningElement {
    logger = getLogger();

    connectedCallback() {
        this.logger.info('LWC Logger test successful!');
        this.logger.saveLog();
    }
}
```

### Run All Tests (Optional)

For source installations:

```bash
npm run test
```

This runs:
- Apex tests
- LWC Jest tests
- Code quality checks

## Troubleshooting

### Installation Fails

**Error: "This package can't be installed"**

**Cause:** Org doesn't meet requirements

**Solution:**
1. Ensure My Domain is deployed
2. Check API version (must be 65.0+)
3. Verify org edition (Enterprise+ or Developer)

**Error: "Maximum number of packages exceeded"**

**Cause:** Too many packages installed

**Solution:**
1. Uninstall unused packages
2. Contact Salesforce Support to increase limit

### Logs Not Appearing

**Check 1:** Is Logger enabled?
```apex
LoggerSettings__c settings = LoggerSettings__c.getInstance();
System.debug('Logger Enabled: ' + settings.IsEnabled__c);
```

**Check 2:** Do users have permissions?
- Verify **Logger End User** permission set is assigned
- Check object permissions on Log__c and LogEntry__c

**Check 3:** Are platform events working?
- Navigate to **Setup → Platform Events → LogEntryEvent**
- Check delivery status
- Look for errors

**Check 4:** Are triggers active?
- Navigate to **Setup → Apex Triggers**
- Find **LogEntryEventTrigger**
- Verify it's active

### Permission Errors

**Error: "Insufficient privileges"**

**Solution:**
1. Assign **Logger End User** permission set
2. Or manually grant permissions:
   - Read on Log__c, LogEntry__c
   - Create on Log__c, LogEntry__c
   - Read on LoggerTag__c, LoggerScenario__c

### Platform Event Errors

**Error: "Platform event limit exceeded"**

**Solution:**
1. Check daily platform event limit
2. Reduce logging volume
3. Increase logging level (INFO → WARN → ERROR)

### Storage Warnings

**Warning: "Data storage at 80%"**

**Solution:**
1. Implement log retention (see [Admin Guide](admin-guide.md#data-management))
2. Delete old logs
3. Increase storage allocation

## Upgrading

### Unlocked Package Upgrade

1. **Check Current Version**
   - Navigate to **Setup → Installed Packages**
   - Note your current version

2. **Install New Version**
   - Use the same installation method as original install
   - Install the new package version ID
   - Choose **Upgrade**

3. **Review Release Notes**
   - Check [GitHub Releases](https://github.com/jongpie/NebulaLogger/releases)
   - Review breaking changes
   - Test in sandbox first

### Managed Package Upgrade

1. **Check for Updates**
   - Navigate to **Setup → Installed Packages**
   - Click **Nebula Logger**
   - Click **Check for Updates**

2. **Install Update**
   - Click **Install Update**
   - Choose **Install for All Users**
   - Click **Install**

3. **Wait for Completion**
   - Upgrades typically take 2-5 minutes
   - You'll receive an email confirmation

### Source Code Upgrade

1. **Pull Latest Changes**
   ```bash
   git pull origin main
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Deploy Changes**
   ```bash
   sf project deploy start --source-dir nebula-logger/core/main
   ```

4. **Run Tests**
   ```bash
   npm run test:apex
   ```

### Post-Upgrade Steps

After any upgrade:

1. **Test in Sandbox First**
   - Always test upgrades in a sandbox
   - Run your test suite
   - Verify custom integrations still work

2. **Review Settings**
   - Check LoggerSettings__c for new fields
   - Review LoggerParameter__mdt for new parameters

3. **Update Custom Code**
   - If there are breaking changes, update your code
   - Re-run tests

4. **Train Users**
   - Communicate new features
   - Update internal documentation

## Plugin Installation

Install optional plugins for extended functionality:

### Available Plugins

- **Slack Integration** - Send logs to Slack channels
- **Big Object Archiving** - Archive old logs to Big Objects
- **Async Failure Additions** - Enhanced async context logging
- **Log Retention Rules** - Automated log cleanup
- **Alerting System** - Configure alerts on log patterns

### Installing Plugins

**Via Unlocked Package:**
```bash
sf package install --package <plugin-package-id> --target-org my-org
```

**Via Source:**
```bash
sf project deploy start --source-dir nebula-logger/plugins/slack
```

See individual plugin READMEs for configuration details.

## Next Steps

Now that Logger is installed:

1. [Quick Start Guide](quick-start.md) - Log your first entry
2. [Admin Guide](admin-guide.md) - Configure Logger for your org
3. [Apex Guide](apex-guide.md) - Learn Apex logging
4. [LWC Guide](lwc-guide.md) - Learn LWC logging
5. [Best Practices](best-practices.md) - Production-ready patterns

## Support

- **Documentation:** This documentation site
- **GitHub Issues:** [Report bugs and request features](https://github.com/jongpie/NebulaLogger/issues)
- **GitHub Discussions:** [Ask questions and share ideas](https://github.com/jongpie/NebulaLogger/discussions)
- **Wiki:** [Additional guides and examples](https://github.com/jongpie/NebulaLogger/wiki)
