# Manage Scratch Orgs

Scratch orgs are temporary Salesforce orgs that can be quickly set up
"from scratch," and which last for no more than 30 days. There are
several reasons why scratch orgs are encouraged for development and
testing over sandboxes or Developer Edition orgs. Scratch orgs:

-   Provide a repeatable starting point without the challenge of
    managing persistent orgs' state over time.
-   Are scalable and ensure that individual, customized environments are
    available to everyone in the development lifecycle.
-   Facilitate a fully source-driven development process built around
    best practices.

CumulusCI offers tools for working with all types of Salesforce orgs,
but provides the most value when working with scratch orgs. CumulusCI
automation helps realize the promise of scratch orgs as low cost,
repeatable, source-driven environments for every phase of the product
lifecycle.

This section focuses on managing scratch orgs in a CumulusCI project. To
learn about managing persistent orgs, such as sandboxes, production
orgs, and packaging orgs, visit the
[](connected-orgs) section.

## What Is an Org in CumulusCI?

An org in CumulusCI's keychain starts out as a named configuration,
tailored for a specific purpose within the lifecycle of the project
(such as development, QA, beta testing, and so on). CumulusCI creates
and uses scratch orgs based on these configurations on demand. In fact,
a scratch org is only generated the first time you use the scratch org.
When it's expired or been deleted, a new one can be created again with
the same configuration.

CumulusCI offers tools that make it easy to discover predefined org
configurations, create scratch orgs based on those configurations, and
define new orgs and new configurations.

## Set Up the Salesforce CLI

Scratch orgs in CumulusCI allow teams to be confident that the orgs they
develop and test in are as close to their production environments as
possible. We recommend working with scratch orgs created by Salesforce
DX.

See the [](set-up-sfdx) section for instructions.

## Predefined Orgs

CumulusCI comes with predefined org configurations. Every project's
keychain starts with these configurations ready and available to be
turned into a live scratch org.

| Org       | Role                                                                | Definition File     | Lifespan |
| --------- | ------------------------------------------------------------------- | ------------------- | -------- |
| `dev`     | Development workflows                                               | `orgs/dev.json`     | 7 days   |
| `qa`      | Testing workflows                                                   | `orgs/dev.json`     | 7 days   |
| `feature` | Continuous integration                                              | `orgs/dev.json`     | 1 day    |
| `beta`    | Continuous integration<br><br>Hands-on testing                      | `orgs/beta.json`    | 1 day    |
| `release` | Continuous integration<br><br>Hands-on testing<br><br>Product demos | `orgs/release.json` | 1 day    |

To see the predefined orgs in your project:

```console
$ cci org list
```

If your project has customized org configurations, your listing can
include more configurations than shown in the previous table, and your
project's versions of the standard configurations can be different.

## Create a Scratch Org

To create a scratch org from a configuration, use it as the target of a
command, task, or flow. CumulusCI automatically initializes orgs when
they're first used.

You can create a scratch org from the `dev` configuration and review
information about the created org with:

```console
$ cci org info dev
```

When the org is created, it's associated with the name `dev` in the
CumulusCI keychain and can be used with other commands until it expires.
When an org expires or is removed, its associated configuration is left
in place, and can be recreated whenever needed.

It's possible to create new orgs in the keychain that inherit their
configuration from a built-in org.

Here we create a new org that uses the same configuration as the
built-in org `dev` and has the alias `myDevOrg`:

```
$ cci org scratch dev myDevOrg
```

Verify that there is now an org with the name of `<org_name>` that is
associated with the `dev` configuration by running `cci org list`.

You can have as many named orgs as you wish, or none at all. Many
CumulusCI users work only with built-in orgs.

#### Scratch Org Limits

Each scratch org you create is counted against limits in your Dev Hub.
Scratch orgs count against an _active_ scratch org limit, which controls
how many orgs can exist at the same time, and a _daily_ scratch org
limit, which controls how many total orgs can be created per day.

Scratch org limits are based on your Dev Hub's edition and your
Salesforce contract. To review limits and consumption, run the command:

```console
$ sfdx force:limits:api:display -u <username>
```

`<username>` is your Dev Hub username. The limit names are
`ActiveScratchOrgs` and `DailyScratchOrgs`.

## List Orgs

When inside a project repository, run `cci org list` to see all the orgs
you have configured or connected.

(set-a-default-org)=

## Set a Default Org

When you run a task or flow that performs work on an org, specify the
org with the `--org` option.

```console
$ cci flow run dev_org --org dev
```

To run many commands against the same org, set a default.

```console
$ cci org default dev
$ cci flow run dev_org
```

Alternately, set a default org when creating a new named configuration
by passing the `--default` flag.

```console
$ cci org scratch dev <org_name> --default
```

To remove the existing default org:

```console
$ cci org default dev --unset
```

## Open Orgs in the Browser

Run `cci org browser <org_name>` to log into any org in the keychain in
a new browser tab.

## Delete Scratch Orgs

If an org defined in the keychain has created a scratch org, you can
delete the scratch org but leave the configuration in the keychain to
reuse it later.

```console
$ cci org scratch_delete <org_name>
```

Using `scratch_delete` doesn't remove the org `<org_name>` from your
org list. This default behavior lets you easily recreate scratch orgs
from a stored, standardized configuration.

To permanently remove an org from the org list, and also delete the
associated scratch org:

```console
$ cci org remove <org_name>
```

It's not necessary to explicitly remove or delete expired orgs.
CumulusCI recreates an expired org the first time you attempt to use it.
To clean up expired orgs from the keychain:

```console
$ cci org prune
```

## Configure Predefined Orgs

Projects can customize the set of configurations available out of the
box, and add further predefined orgs to meet project-specific needs.

An org configuration has a name, such as `dev` or `qa`, and is defined
by options set in the `cumulusci.yml` file as well as in the contents of
a specific `.json` scratch org definition file in the `orgs` directory.
For orgs like `dev` and `qa` that are predefined for all projects, the
configuration is located in the CumulusCI standard library, but can be
customized by projects in the `cumulusci.yml` file.

When developing a managed package project, it is often useful to test
inside of a namespaced scratch org. Many projects configure an org
called `dev_namespaced`, a developer org that has a namespace. This org
is defined under the `orgs__scratch` section in the `cumulusci.yml`
file.

```yaml
orgs:
    scratch:
        dev_namespaced:
            config_file: orgs/dev.json
            days: 7
            namespaced: True
```

This org uses the same scratch org definition file as the `dev` org, but
has a different configuration in the `cumulusci.yml` file, resulting in
a different org shape and a different use case. The key facets of the
org shape that are defined in the `cumulusci.yml` file are whether or
not the org has a namespace, and the length of the org's lifespan.

Org definition files stored in the `orgs` directory are configured as
specified in the [Salesforce DX Developer
Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_scratch-orgs_def_file.htm).

Many projects never add a new org definition `.json` file, and instead
add specific features and settings to the files shipped with CumulusCI.
However, new definitions can be added and referenced under the
`orgs__scratch` section of the `cumulusci.yml` file to establish org
configurations that are completely customized for a project.

## Import an Org from the Salesforce CLI

CumulusCI can import existing orgs from the Salesforce CLI keychain.

```console
$ cci org import <sfdx_alias> <cci_alias>
```

For `sfdx_alias`, specify the alias or username of the org in the
Salesforce CLI keychain. For `cci_alias`, provide the name to use in
CumulusCI's keychain.

```{important}
CumulusCI cannot automatically refresh orgs imported from Salesforce CLI
when they expire.
```

## Use a Non-Default Dev Hub

By default, CumulusCI creates scratch orgs using the DevHub org
configured as the `defaultdevhubusername` in `sfdx`. Switch to a
different DevHub org within a project by configuring the `devhub`
service.

```console
$ cci service connect devhub mydevhub --project
Username: <DevHub username>
devhub is now configured for this project.
```
