---
title: Bundle without a dependency
description: Copy Nebula Logger's metadata into your own project instead of installing it as a separate package.
---

Nebula Logger is fully open source under the MIT license. If you want full control of what deploys - no separate package, no namespace, no upgrade coupling - you can copy the metadata directly into your own project.

## When this makes sense

- You are shipping a single deployment artifact (one unlocked package or one source-format project) and don't want a Nebula Logger dependency.
- You have policies that require every deployed artifact to be inside your own repo.
- You are willing to own the upgrade path - pulling in new Nebula Logger releases manually.

## When it doesn't

- You want automatic upgrades.
- You want the plugin framework to remain independently packageable.
- You want to consume the shipped plugins (Slack, Big Object Archiving, etc.) - those are separate packages that don't bundle cleanly.

For those cases, install the [unlocked package](/getting-started/install-unlocked/) instead.

## Steps

1. Fork or clone the [Nebula Logger repo](https://github.com/jongpie/NebulaLogger).
2. Copy the `nebula-logger/core/main/` directory into your own source-format project under whichever package directory you use.
3. Add the copied directory as a `packageDirectories` entry in your `sfdx-project.json` if you package your work as unlocked packages.
4. Deploy as normal: `sf project deploy start --source-dir <your-copied-path>`.
5. Assign the permission sets that came along with the copy: `LoggerAdmin`, `LoggerLogViewer`, `LoggerEndUser`, `LoggerLogCreator`.
6. Configure `LoggerSettings__c` at the org default level (see [Post-install setup](/getting-started/post-install-setup/)).

## Upgrading later

To pull in new Nebula Logger releases:

1. Diff your copied metadata against the `main` branch or a specific release tag of the Nebula Logger repo.
2. Cherry-pick the changes you want. Watch for renamed API elements, new custom fields, new CMDT records, and permission set additions.
3. Deploy the delta.
4. Run the Nebula Logger Apex tests to catch anything the manual copy missed.

There is no automated tooling for this - the trade-off of bundling is that upgrades become your maintenance burden.

## Where next

- [Post-install setup](/getting-started/post-install-setup/) - permissions and `LoggerSettings__c` configuration.
- [Logging Guide](/logging-guide/concepts/) - how to actually use the framework once it's deployed.
