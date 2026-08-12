# Nebula Logger Skills

This folder contains Nebula Logger's [skills.sh](https://skills.sh) catalog. Each subfolder is one skill, with a `SKILL.md` file that describes when the skill applies and what it covers. The top-level [`skills.sh.json`](../skills.sh.json) groups the skills into logical categories for the catalog page at [skills.sh/jongpie/NebulaLogger](https://skills.sh/jongpie/NebulaLogger).

## Skills

| Skill                                                                                 | Purpose                                                                                                                                                                                                                                               |
| ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [nebula-logger-install](./nebula-logger-install/SKILL.md)                             | Installing Nebula Logger, choosing between unlocked and managed packages, permission-set assignment, and initial `LoggerSettings__c` configuration.                                                                                                   |
| [nebula-logger-instrumentation](./nebula-logger-instrumentation/SKILL.md)             | Adding Nebula Logger instrumentation in Apex, LWC, Aura, Flow, and OmniStudio. Covers logging APIs, exception handling, record association, tags/scenarios, async transaction linking, and the `CallableLogger` optional-dependency pattern for ISVs. |
| [nebula-logger-console](./nebula-logger-console/SKILL.md)                             | Browsing and investigating logs in the Salesforce UI - list views, record pages, home page components, and the live log entry event stream.                                                                                                           |
| [nebula-logger-purging-and-retention](./nebula-logger-purging-and-retention/SKILL.md) | Configuring how long logs live before being purged - `LogRetentionDate__c` semantics, `LogBatchPurger` scheduling, and per-user/profile/scenario overrides.                                                                                           |
| [nebula-logger-testing-your-code](./nebula-logger-testing-your-code/SKILL.md)         | Writing Apex and LWC tests for code that calls Nebula Logger. Global-only APIs and patterns for observing entries without polluting the org.                                                                                                          |
| [nebula-logger-plugin-development](./nebula-logger-plugin-development/SKILL.md)       | Building custom plugins that extend Nebula Logger via the `LoggerPlugin.Triggerable` and `LoggerPlugin.Batchable` interfaces.                                                                                                                         |
| [nebula-logger-best-practices](./nebula-logger-best-practices/SKILL.md)               | Team-wide instrumentation standards, environment-aware logging levels, and governor-limit considerations.                                                                                                                                             |

## Supported API Surface

Every skill in this catalog references only Nebula Logger's `global` Apex surface and the exported `c/logger` LWC module. `public` classes and methods in the unlocked package are technically reachable but are Nebula Logger's internal surface and can change without a deprecation window - see the "Supported API Surface" section in [nebula-logger-instrumentation](./nebula-logger-instrumentation/SKILL.md) for the full policy.

The plugin framework in [nebula-logger-plugin-development](./nebula-logger-plugin-development/SKILL.md) is a deliberate exception: the extension points are `public` because they exist only inside the unlocked package, and plugin authors interact with them by design. Plugins should pin to a tested Nebula Logger version and re-verify on upgrades.

## Publishing

skills.sh reads this repository directly from GitHub. Landing a change on `main` publishes it - no separate submission or manual crawl trigger is needed.

## Contributing

If you spot something in a skill that no longer matches the code (a renamed field, a removed method, a stale example), please file an issue at https://github.com/jongpie/NebulaLogger/issues or open a PR. See the repo's [CONTRIBUTING.md](../CONTRIBUTING.md) for the general contribution workflow.
