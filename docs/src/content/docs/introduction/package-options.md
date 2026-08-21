---
title: Package options
description: Choosing between the unlocked package, managed package, and bundling Nebula Logger's metadata directly.
---

Nebula Logger ships as both an unlocked and a managed package, with the same core metadata. A third option is to bundle the metadata into your own project without a package boundary. The right choice depends on release cadence, namespace, and plugin support.

## Comparison

| Area               | Unlocked                   | Managed                                                   | Bundled                                      |
| ------------------ | -------------------------- | --------------------------------------------------------- | -------------------------------------------- |
| Namespace          | None                       | `Nebula`                                                  | None (you own it)                            |
| Release cadence    | Faster patch cadence       | Slower, stabilized cadence (~3 managed releases per year) | Whatever you pull in                         |
| Source visibility  | Full source in org         | Packaged global API surface only                          | Full source                                  |
| Plugin framework   | Available                  | Not currently available                                   | Available                                    |
| Feature coverage   | All features, latest fixes | Subset - trails the unlocked package                      | Whatever you copied                          |
| Distribution model | GitHub-first OSS           | AppExchange-friendly                                      | You ship it in your own package              |
| Best for           | Most teams                 | ISVs whose customers need namespace isolation             | Teams that need full control of what deploys |

## Unlocked package (recommended)

Start here unless you have a hard reason not to. The unlocked package:

- Has faster patch cadence - new fixes and enhancements land quickly.
- Exposes full source in the installed org.
- Includes the plugin framework, so all the shipped plugins and any you write yourself work.
- Is the reference implementation - if a feature exists in Nebula Logger, it exists here first.

Install steps: see [Install the unlocked package](/NebulaLogger/getting-started/install-unlocked/).

## Managed package

Choose the managed package only when you need namespace isolation:

- You are shipping an AppExchange product whose customers need every custom object and class isolated behind a namespace.
- Your org has policies that require namespaced installations for compliance.

Tradeoffs:

- Slower release cadence than the unlocked package.
- No plugin framework - the trigger and batch extension points are not exposed in the managed package.
- API surface is only the classes and members marked `global`. Anything `public` in the source is not accessible from your code.

All Nebula Logger APIs referenced in this documentation are `global`, so they are available in both packages. Prefix them with `Nebula.` in the managed package (`Nebula.Logger.info(...)`).

Install steps: see [Install the managed package](/NebulaLogger/getting-started/install-managed/).

## Bundle without a package

If you need full control over what deploys and are willing to own the upgrade path, copy the metadata into your own project.

- Full source, no namespace, no plugin package boundary.
- You are responsible for pulling in updates - no automatic upgrade path.
- Ideal for teams that want to ship a single deployment artifact.

Install steps: see [Bundle without a dependency](/NebulaLogger/getting-started/bundle-without-dependency/).

## For ISVs and package developers

If you are building your own package and want to _optionally_ use Nebula Logger when it's installed in a customer's org - without forcing customers to install it - use `CallableLogger`. Your package compiles and installs cleanly whether Nebula Logger is present or not. See [Optional dependency via Callable](/NebulaLogger/for-package-developers/optional-dependency/).

## Where next

- [Install the unlocked package](/NebulaLogger/getting-started/install-unlocked/) - the recommended path.
- [Install the managed package](/NebulaLogger/getting-started/install-managed/) - namespaced install.
- [Bundle without a dependency](/NebulaLogger/getting-started/bundle-without-dependency/) - copy metadata into your project.
