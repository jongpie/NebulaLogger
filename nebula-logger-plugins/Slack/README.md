# Slack plugin for Nebula Logger

Adds a Slack integration for Nebula Logger. Any logs with log entries that meet a certain (configurable) logging level will automatically be posted to your Slack channel via an asynchronous `Queueable` job.

![Slack plugin: notification](./../../content/slack-plugin-notification.png)

---

## What's Included

This plugin includes some add-on metadata for Logger to support the Slack integration

1. Apex class `SlackLoggerPlugin` and corresponding tests in `SlackLoggerPlugin_Tests`
2. Plugin configuration details stored in Logger's CMDT objects `LoggerSObjectHandlerPlugin__mdt` and `LoggerSObjectHandlerPluginParameter__mdt`
3. Custom fields `Log__c.SendSlackNotification__c` and `Log__c.SlackNotificationDate__c`
4. Field-level security (FLS) updates for the permission sets `LoggerAdmin` and `LoggerLogViewer` to provide access to the custom Slack fields
5. Custom list views for the `Log__c` and `LoggerSObjectHandlerPluginParameter__mdt` objects
6. Remote site setting for Slack's API

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
