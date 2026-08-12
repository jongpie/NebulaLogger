---
title: Install the unlocked package
description: How to install the Nebula Logger unlocked package in a Salesforce sandbox or production org.
---

The unlocked package is the recommended install path for most teams. It has the fastest release cadence, includes the plugin framework, and exposes full source in the installed org.

Always confirm the current version on the [GitHub releases page](https://github.com/jongpie/NebulaLogger/releases) before installing - the package IDs below track the latest release at the time of writing.

## Install options

### Sandbox

```bash
sf package install --target-org <sandbox-alias> --wait 20 --security-type AdminsOnly --package 04tg7000000HNrRAAW
```

Or install via URL: [test.salesforce.com/packaging/installPackage.apexp?p0=04tg7000000HNrRAAW](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tg7000000HNrRAAW).

### Production

```bash
sf package install --target-org <prod-alias> --wait 20 --security-type AdminsOnly --package 04tg7000000HNrRAAW
```

Or install via URL: [login.salesforce.com/packaging/installPackage.apexp?p0=04tg7000000HNrRAAW](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tg7000000HNrRAAW).

## Security type

Both examples above use `--security-type AdminsOnly`. That means only users with the "Modify All Data" permission get access on install - other users need explicit permission set assignment. This is the recommended posture because Nebula Logger permissions are more nuanced than the default "install for all users" option surfaces.

If your rollout plan is different, adjust the flag to `--security-type AllUsers` at install time and revisit permission set assignment as a separate step.

## Verify the install

After install:

```bash
sf package installed list --target-org <alias>
```

You should see `Nebula Logger - Core` at the version you installed. If you don't, check the org's Setup > Installed Packages page for install errors.

## Where next

- [Post-install setup](/getting-started/post-install-setup/) - permissions, `LoggerSettings__c`, and verification.
- [Install the managed package](/getting-started/install-managed/) - if you need the namespaced version instead.
