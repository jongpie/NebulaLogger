# Slack plugin for Nebula Logger

Adds a Slack integration for Nebula Logger. Any logs with 1+ ERROR or WARN log entries will automatically be posted to your Slack channel.

[![Install Unlocked Package](./../../content/btn-install-unlocked-package.png)](https://login.salesforce.com/packaging/installPackage.apexp?p0=TODO-add-package-ID)

---

## Installation Steps

1. Ensure that you have the unlocked package version of Nebula Logger installed in your org
2. Install/deploy Slack plugin package for Logger
3. Create a new app in you Slack workspace
4. Add Slack as an Auth Provider in your org
5. Add a named credential called 'Slack' in your org

---

## Setup Steps

Choose auth method: 'API_TOKEN' or 'NAMED_CREDENTIALS'

### 'API_TOKEN' Steps

1. Create remote site setting
2. Create/update logger plugin parameter

### 'NAMED_CREDENTIALS' Steps

1. Create Slack app
2. Create Auth Provider & Named Credential - See [UnofficialSF.com's article](https://unofficialsf.com/authorizing-salesforce-access-to-slack/) on how to set this up for Slack
3. Create/update logger plugin parameter
