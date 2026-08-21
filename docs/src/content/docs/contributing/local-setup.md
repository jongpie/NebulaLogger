---
title: Local development setup
description: Cloning the repo, installing dependencies, and standing up a scratch org.
---

## Prerequisites

- Node.js 22.23.2 or newer (see `engines` in [package.json](https://github.com/jongpie/NebulaLogger/blob/main/package.json)).
- npm 10.9.3 or newer.
- Salesforce CLI (`sf`) - installed automatically via the `@salesforce/cli` dev dependency, but a global install is convenient.
- A Salesforce Dev Hub org with scratch org creation enabled.

## Clone and install

```bash
git clone https://github.com/jongpie/NebulaLogger.git
cd NebulaLogger
npm install
```

The install step pulls in Salesforce CLI, sfdx-lwc-jest, Prettier, ESLint, and everything else needed to build and test.

## Create a scratch org

```bash
sf org create scratch --definition-file config/scratch-orgs/base-scratch-def.json --alias nl-dev --set-default --duration-days 7
```

Adjust the definition file for your needs - `config/scratch-orgs/` contains a few variants.

## Deploy the core

```bash
sf project deploy start --source-dir ./nebula-logger/core --target-org nl-dev
```

## Assign permission sets

```bash
sf org assign permset --name LoggerAdmin --target-org nl-dev
```

Add other permsets as needed:

- `LoggerLogEntryArchiveAdmin` for the Big Object Archiving plugin.
- `LoggerRecipesAdmin` for the recipes.
- `LoggerSlackPluginAdmin` for the Slack plugin.

## Deploy plugins (optional)

Each plugin lives under `nebula-logger/plugins/<name>/plugin/<name>`. Deploy the ones you want:

```bash
sf project deploy start --source-dir ./nebula-logger/plugins/slack/plugin/slack --target-org nl-dev
```

## Open the org

```bash
sf org open --target-org nl-dev
```

Navigate to the Logger Console app to verify the install worked.

## Where next

- [Testing](/NebulaLogger/contributing/testing/) - running the Apex, LWC, and e2e suites.
- [PR conventions](/NebulaLogger/contributing/pr-conventions/) - commit and PR style.
