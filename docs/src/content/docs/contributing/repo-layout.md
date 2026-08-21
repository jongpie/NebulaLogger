---
title: Repo layout
description: Where things live in the NebulaLogger repository.
---

The [NebulaLogger](https://github.com/jongpie/NebulaLogger) repository is a monorepo containing the core package, five plugins, recipes, docs, and build tooling.

## Top-level layout

| Path                             | Purpose                                                                                                 |
| -------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `nebula-logger/core/`            | The main unlocked/managed package. Anything in `main/` ships to end users; `tests/` is Apex tests only. |
| `nebula-logger/plugins/`         | Optional add-on packages. Each is self-contained under its own folder.                                  |
| `nebula-logger/managed-package/` | Metadata that only ships in the managed package build.                                                  |
| `nebula-logger/recipes/`         | Runnable examples that demonstrate the API.                                                             |
| `docs/`                          | Astro Starlight source for this documentation site.                                                     |
| `skills/`                        | Nebula Logger AI agent skills.                                                                          |
| `scripts/build/`                 | Repo automation for CI / packaging.                                                                     |
| `scripts/dev/`                   | Developer tooling scripts.                                                                              |
| `config/`                        | Config files for the various tools (jest, scratch org definitions, etc.).                               |
| `CLAUDE.md`                      | Contributor guide for AI coding agents. Human contributors should skim it too.                          |
| `CONTRIBUTING.md`                | Human-oriented contributor guide.                                                                       |

## Inside `nebula-logger/core/main/`

The core package's source, organized by functional area:

| Path              | Contents                                                                                         |
| ----------------- | ------------------------------------------------------------------------------------------------ |
| `configuration/`  | CMDT types, LWCs, and Apex classes for the configuration surface (`LoggerParameter__mdt`, etc.). |
| `logger-engine/`  | The core logging APIs - `Logger`, `LogEntryEventBuilder`, `CallableLogger`, LWC `logger` module. |
| `log-management/` | The console app, custom objects (`Log__c`, `LogEntry__c`), triggers, and management LWCs.        |

Each functional area has its own subdirectories for `classes/`, `lwc/`, `objects/`, `permissionsets/`, etc.

## Inside `nebula-logger/plugins/`

Each plugin lives under its own folder with a consistent internal layout:

```
nebula-logger/plugins/<name>/
  plugin/
    <name>/
      classes/               # Apex classes (impl + tests)
      customMetadata/        # LoggerPlugin.<Name>.md-meta.xml
      objects/               # Any plugin-specific custom objects/fields
      permissionsets/        # <Name>PluginAdmin.permissionset-meta.xml
  tests/                     # Additional test artifacts (test suite, test permsets)
  README.md
```

Current plugins:

- `async-failure-additions/`
- `big-object-archiving/`
- `logger-admin-dashboard/`
- `log-retention-rules/`
- `slack/`

## Where next

- [Local development setup](/NebulaLogger/contributing/local-setup/) - clone, install, run tests.
- [Testing](/NebulaLogger/contributing/testing/) - Apex, LWC, and e2e test suites.
- [PR conventions](/NebulaLogger/contributing/pr-conventions/) - commit and PR style.
