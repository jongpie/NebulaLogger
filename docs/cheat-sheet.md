# Cheat Sheet

CumulusCI offers a great deal of functionality out of the box. This
cheat sheet is intended to provide a very brief summary of the most
important commands to start working in scratch orgs using CumulusCI,
using the basic flows and tasks supplied with the tool.

## Naming and Manipulating Orgs

CumulusCI supplies a collection of named org configurations by default.
To see what org configurations are available, run `cci org list`. You
can provide those names to any of the commands in this guide. Common
examples include `dev`, `qa`, `beta`, and `release`. Org names are
associated with a scratch org definition file stored in the project's
`orgs` directory. The definition file determines how the scratch org is
set up.

It's not necessary to name your own orgs, but you may choose to do so
if, for example, you'd like to maintain multiple orgs of the same type.

### Name a new scratch org

```console
$ cci org scratch <configuration_name> <org_name>
```

This creates a new named org that inherits its setup from the
configuration name provided.

### Get information about a scratch org

```console
$ cci org info <org_name>
```

This includes information like the org's domain, username, and password

### Open a scratch org in your web browser

```console
$ cci org browser <org_name>
```

### Set a default scratch org

```console
$ cci org default <org_name>
```

This asks CumulusCI to run all flows and tasks against the named org
unless otherwise specified. You don't have to specify a default org.
You can always direct CumulusCI to use a specific org with the `--org`
option when you run a flow or a task.

### Delete a scratch org, but leave the org name

```console
$ cci org scratch_delete <org_name>
```

Run this command to delete a scratch org so that you can rebuild it,
while using the same name.

### Remove an org name

```
$ cci org remove <org_name>
```

Note that you will not be able to remove built-in org names, but you can
remove names you created with `cci org scratch`.

### Connect to a persistent org (sandbox, Developer Edition)

```console
$ cci org connect <org_name>
```

Use the `--sandbox` option if this is a sandbox, or any org that uses
the `test.salesforce.com` login endpoint.

## Building Orgs

Every CumulusCI project includes one or more flows that build an org for
a specific purpose or workflow. These flows may be customized for the
project, or may be unique to the project. Below are a collection of the
standard org building flows that you should expect to find in any
CumulusCI project.

```{note}
This section relies on concepts introduced in the [](concepts) section of the
documentation.
```

```{note}
Each flow should be run against a named org configuration using the
`--org` option, or allowed to run against a configured default org.
```

### Flows for Building Orgs

### `qa_org`

This flow builds an unmanaged org that is designed for QA use. Should be
used with an org whose configuration is `qa`.

### `dev_org`

This flow builds an unmanaged org that is designed for development use.
Should be used with an org whose configuration is `dev` or
`dev_namespaced`

### `install_beta`

This flow builds a managed org with the latest beta release installed.
Should be used with an org whose configuration is `beta`

### `install_prod`

This flow builds a managed org with the latest release installed. Should
be used with an org whose configuration is `release`

### `push_upgrade_org`

This flow builds a managed org that starts with the latest release
installed and available for all Profiles. It then upgrades the package
dependencies and the package itself to their latest betas, installing
upgrades for System Administrators only, and runs `config_qa` to set
up the org for testing. This simulates a subscriber push upgrade for
non-System Administrator users.

Should be used with an org whose configuration is
`release`.

Your project may provide additional org-building flows. Consult the
project's automation documentation for more details.

```{caution}
We do not recommend running an org-building flow against the same
scratch org multiple times. While this may work in some situations, in
many cases it will fail and/or leave the org in an inconsistent state.
If you need to rebuild an org, delete it first. If you need to redeploy
updated code into an org, see below.
```

## Common Tasks

```{note}
Note that each task should be run against a named org configuration
using the `--org` option. If not specified, the task will run against a
configured default org.
```

### Deploy updated code into an org

```console
$ cci flow run deploy_unmanaged
```

### Execute Apex unit tests in an org

```console
$ cci task run run_tests
```

### Execute Robot browser tests

```console
$ cci task run robot
```

### Review changes to metadata in an org

```
$ cci task run list_changes
```

### Retrieve changes to local repository

```
$ cci task run retrieve_changes
```
