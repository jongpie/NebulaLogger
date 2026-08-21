---
title: No dependency (bundling)
description: Copy Nebula Logger's metadata into your own package instead of taking a dependency.
---

Nebula Logger is MIT-licensed. If you want to ship your own package without a separate Nebula Logger install step - and are willing to own the upgrade path - bundle the metadata directly into your project.

## Trade-offs

| Approach                       | Pro                                                                             | Con                                                             |
| ------------------------------ | ------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| Optional dependency (Callable) | No coupling; customers choose whether to install.                               | Logging is only available in orgs that installed Nebula Logger. |
| Hard dependency                | Customers get logging automatically; you can reference Logger classes directly. | Your package install fails when Nebula Logger isn't installed.  |
| Bundling                       | Single deployment artifact; no install-time coupling.                           | You own upgrades manually; no automatic updates.                |

Choose bundling when you specifically need a single artifact and can absorb the maintenance cost. Otherwise, one of the other two options is easier.

## Steps

1. Fork or clone the [Nebula Logger repo](https://github.com/jongpie/NebulaLogger).
2. Copy the `nebula-logger/core/main/` directory into your own source-format project under whichever package directory you use.
3. Add the copied directory as a `packageDirectories` entry in your `sfdx-project.json`.
4. Deploy as normal: `sf project deploy start --source-dir <your-copied-path>`.
5. Assign the shipped permission sets (`LoggerAdmin`, `LoggerLogViewer`, `LoggerEndUser`, `LoggerLogCreator`).
6. Configure `LoggerSettings__c` at the org default level (see [Post-install setup](/NebulaLogger/getting-started/post-install-setup/)).

## Upgrading

To pull in new Nebula Logger releases:

1. Diff your copied metadata against the `main` branch or a specific release tag.
2. Cherry-pick the changes you want. Watch for renamed API elements, new custom fields, new CMDT records, and permission set additions.
3. Deploy the delta.
4. Run the Nebula Logger Apex tests to catch anything the manual copy missed.

There is no automated tooling for this. The trade-off of bundling is that upgrades become your maintenance burden.

## Namespace considerations

The `nebula-logger/core/main/` directory is written for the unlocked (no-namespace) package. If your own package has a namespace, the copied metadata inherits that namespace. Update any hardcoded references to `Nebula.` in your own code accordingly.

## Where next

- [Optional dependency via Callable](/NebulaLogger/for-package-developers/optional-dependency/) - if you can accept optional logging.
- [Hard dependency](/NebulaLogger/for-package-developers/hard-dependency/) - if you want automatic upgrades.
- [Getting Started - Bundle without a dependency](/NebulaLogger/getting-started/bundle-without-dependency/) - the same content from the getting-started view.
