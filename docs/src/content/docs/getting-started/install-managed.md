---
title: Install the managed package
description: How to install the Nebula Logger managed package (namespace Nebula) in a Salesforce sandbox or production org.
---

The managed package installs under the `Nebula` namespace. Choose it only when you need namespace isolation - for AppExchange delivery or org policies that require it. Otherwise install the [unlocked package](/NebulaLogger/getting-started/install-unlocked/) instead.

Always confirm the current version on the [GitHub releases page](https://github.com/jongpie/NebulaLogger/releases) before installing.

## Install options

### Sandbox

```bash
sf package install --target-org <sandbox-alias> --wait 30 --security-type AdminsOnly --package 04tg7000000GZbJAAW
```

Or install via URL: [test.salesforce.com/packaging/installPackage.apexp?mgd=true&p0=04tg7000000GZbJAAW](https://test.salesforce.com/packaging/installPackage.apexp?mgd=true&p0=04tg7000000GZbJAAW).

### Production

```bash
sf package install --target-org <prod-alias> --wait 30 --security-type AdminsOnly --package 04tg7000000GZbJAAW
```

Or install via URL: [login.salesforce.com/packaging/installPackage.apexp?mgd=true&p0=04tg7000000GZbJAAW](https://login.salesforce.com/packaging/installPackage.apexp?mgd=true&p0=04tg7000000GZbJAAW).

## Namespace-prefixed identifiers

All Apex calls that reference Nebula Logger classes need the `Nebula.` prefix in the managed package:

```apex
Nebula.Logger.info('Hello from the managed package');
Nebula.Logger.saveLog();
```

Custom objects, custom metadata types, and permission set names also carry the prefix (`Nebula__Log__c`, `Nebula__LoggerSettings__c`, `Nebula__LoggerAdmin`).

## What's not available in the managed package

- The **plugin framework** is not exposed. The bundled plugins (Slack, Big Object Archiving, Log Retention Rules, Logger Admin Dashboard, Async Failure Additions) do not install alongside the managed package, and you cannot write your own plugins against it. If you need plugins, install the unlocked package instead.
- The API surface is limited to classes and members marked `global` in the source. Anything `public` is inaccessible.

All logging APIs and configuration surfaces documented on this site are `global`, so they work in both packages.

## Verify the install

```bash
sf package installed list --target-org <alias>
```

You should see the managed package listed with the `Nebula` namespace prefix.

## Uninstalling

Uninstall from Setup > Installed Packages > **Uninstall** next to the Nebula Logger row. Salesforce will warn you about dependencies and confirm before removing metadata and data.

Uninstalling deletes every `Nebula__Log__c`, `Nebula__LogEntry__c`, `Nebula__LoggerScenario__c`, `Nebula__LoggerTag__c`, and `Nebula__LogEntryTag__c` record along with the metadata. Export anything you want to keep first.

## Where next

- [Post-install setup](/NebulaLogger/getting-started/post-install-setup/) - permissions, `LoggerSettings__c`, and verification.
- [Package options](/NebulaLogger/introduction/package-options/) - unlocked vs managed vs bundled comparison.
