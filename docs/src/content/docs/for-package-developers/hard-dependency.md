---
title: Hard dependency
description: Adding Nebula Logger as a required dependency of your own package.
---

If you want to guarantee Nebula Logger is present in every customer's org - not opt in via `CallableLogger` but hard-require it - declare Nebula Logger as a package dependency in your `sfdx-project.json`.

## When to use this

- Your product's core value depends on structured logging being available.
- Your customer support workflow assumes Nebula Logger is installed everywhere.
- You want to reference `Logger.info(...)` etc. directly in your Apex, without the `CallableLogger` indirection.

If any of those don't apply, [optional dependency via Callable](/NebulaLogger/for-package-developers/optional-dependency/) is usually better - it gives customers the choice.

## Declaring the dependency

In your `sfdx-project.json`, add a `dependencies` entry under your package directory:

```json
{
  "packageDirectories": [
    {
      "path": "force-app",
      "package": "YourPackage",
      "versionNumber": "1.0.0.NEXT",
      "dependencies": [
        {
          "package": "Nebula Logger - Core@4.19.2-0"
        }
      ]
    }
  ]
}
```

Adjust the version to whatever you tested against. Salesforce enforces the dependency at install time - customers who don't have Nebula Logger installed can't install your package until they do.

## Unlocked vs managed

- **Reference the unlocked package** if you want the plugin framework and full source visibility. This is the common choice.
- **Reference the managed package** (`Nebula` namespace) if you're distributing on AppExchange and need namespace isolation on both sides.

If you reference the managed package, prefix your Nebula Logger calls with `Nebula.` in your Apex.

## Version pinning

- **Minor version pin** (`4.19.2-0`) - install rules require the exact version. Predictable but rigid.
- **Loose pin** (`4.19.LATEST`) - install rules allow any patch. More flexible, but you take on responsibility for staying current.

Choose based on your release cadence and how much you rely on Nebula Logger internals.

## Where next

- [Optional dependency via Callable](/NebulaLogger/for-package-developers/optional-dependency/) - the alternative.
- [No dependency (bundling)](/NebulaLogger/for-package-developers/no-dependency/) - copy metadata into your project.
- [Package options](/NebulaLogger/introduction/package-options/) - unlocked vs managed vs bundled comparison.
