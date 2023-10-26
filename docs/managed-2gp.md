# Release a Second-Generation Managed Package

This section outlines how to release second-generation (2GP) Salesforce
managed package projects. Salesforce.org's Release Engineering team
practices [CumulusCI Flow](cumulusci-flow), which incorporates all of these steps.

## Prerequisites

This section assumes:

-   [CumulusCI is installed](get-started) on your computer.
-   A Salesforce managed package project has been [configured](work-on-an-existing-cumulusci-project)
    for use with CumulusCI.
-   Your Dev Hub has the required features enabled: [Enable DevHub
    Features in Your
    Org](https://developer.salesforce.com/docs/atlas.en-us.packagingGuide.meta/packagingGuide/sfdx_setup_enable_devhub.htm)
    and [Enable Unlocked and Second-Generation Managed Packaging](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_setup_enable_secondgen_pkg.htm).
-   A namespace org has been [created and linked to the active Dev
    Hub](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_dev2gp_create_namespace.htm).

## Create a Beta Version

CumulusCI uses the `dependencies` section of your `cumulusci.yml` file
to define your 2GP project's dependencies. CumulusCI uses GitHub
releases to identify the ancestor id and new version number for the beta
package version. By default, the new beta version will increment the
minor version number from the most recent GitHub release.

Because Salesforce requires package version Ids (`04txxxxxxxxxxxx`) for
2GP package dependencies, dependencies with 1GP releases created _before
CumulusCI 3.34.0_ must be installed in an org to make those Ids
available. If your project has such dependencies, start by running

```console
$ cci flow run dependencies --org dev
```

If you are using CumulusCI 3.43.0 or later, your project uses
dependencies specified as a `version_id`, 2GP dependencies, or
dependencies whose releases were created by CumulusCI 3.34.0 or later,
you do not need to execute this step. Current versions of CumulusCI
automatically store and consume the package version Id in GitHub
releases.

When you're ready, and your org is prepared, to upload a package
version, run the command

```console
$ cci flow run release_2gp_beta --org dev
```

```{important}
The org supplied to `release_2gp_beta` has two purposes. One is to look
up the Ids of dependency packages (see above). The other is to provide
the configuration for the _build org_ used to upload the 2GP package
version. CumulusCI will use the scratch org definition file used to
create the specified org (`dev` here) to create the build org, which
defines the features and settings available during package upload.

You may wish to define a separate scratch org configuration just for
package uploads to ensure only your required features are present.
```

The `release_2gp_beta` flow executes these tasks:

-   Uploads a new beta version of the managed package.
-   Creates a new GitHub release tag for the new beta version. Extension
    packages that also use CumulusCI require this release tag to find
    the latest version when this repository is listed as a dependency.
-   [Generates Release Notes](github-release-notes).
-   Syncs feature branches with the `main` branch, which automatically
    integrates the latest changes from `main`. For more information see
    [](auto-merging).

```{tip}
To list each step in the `release_2gp_beta` flow, run
`cci flow info release_2gp_beta`.
```

### Customizing Package Uploads

2GP package uploads are performed by the `create_package_version` task.
If the built-in configuration used by `release_2gp_beta` does not suit
the needs of your project - for example, if you want to increment
version numbers differently, or build a package with the Skip Validation
option - you can customize the options for that task in
`release_2gp_beta` or invoke the task directly.

To learn more about the available options, run

```console
$ cci task info create_package_version
```

### Handling Unpackaged Metadata

CumulusCI projects can include _unpackaged metadata_ in directories like
`unpackaged/pre` and `unpackaged/post`. These directories are deployed
when CumulusCI creates a scratch org, and are installed in the packaging
org when CumulusCI creates 1GP package versions.However,
second-generation packaging does not have a packaging org, and does not
allow interactive access to the build org.

CumulusCI offers two modes of handling unpackaged metadata owned by
dependencies when building a second-generation package.

The default behavior is to ignore unpackaged metadata. If unpackaged
metadata is intended to satisfy install-time dependencies of packages,
this requires that those dependencies be met in other ways, such as by
configuring the scratch org definition. For examples of how to satisfy
the install-time dependencies for NPSP and EDA without using unpackaged
metadata, see
[Extending NPSP and EDA with Second-Generation Packaging](npsp-eda-2gp).

The other option is to have CumulusCI automatically create unlocked
packages containing unpackaged metadata from dependency projects. For
example, if your project depended on the repository `Food-Bank`, which
contained the unpackaged metadata directories

-   `unpackaged/pre/record_types`
-   `unpackaged/pre/setup`

CumulusCI would automatically, while uploading a version of your
package, upload unlocked package versions containing the current content
of those unpackaged directories.

The unlocked package route is generally suitable for testing only, where
it may be convenient when working with complex legacy projects that
include lots of unpackaged metadata. However, it's generally _not_
suitable for use when building production packages, because your
packages would have to be distributed along with those unlocked
packages. For this reason, this behavior is off by default. If you would
like to use it, configure your `cumulusci.yml` to set the option
`create_unlocked_dependency_packages` on the `create_package_version`
task.

## Test a Beta Version

The `ci_beta` flow installs the latest beta version of the project in a
scratch org, and runs Apex tests against it.

```console
$ cci flow run ci_beta --org beta
```

This flow is intended to be run whenever a beta release is created.

## Promote a Production Version

To be installed in a production org, an 2GP package version must be
[promoted](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_unlocked_pkg_create_pkg_ver_promote.htm)
to mark it as released.

To promote a production release of your managed package project:

```
$ cci flow run release_2gp_production --org packaging
```

Unlike first-generation packages, promoting a second-generation package
doesn't upload a new version. Instead, it promotes the most recent beta
version (found in the project's GitHub releases) to production status.
Then, CumulusCI creates a new, production GitHub release, and aggregates
release notes for that release.

You can also promote a package using its `04t` package Id, without using
the GitHub release operations:

```console
$ cci task run promote_package_version --version_id 04t000000000000 --promote_dependencies True
```

Alternatively, you can use the `sfdx force:package:version:promote`
command to promote a 2GP package. Note that using this command will also
not perform any release operations in GitHub.

### Promote Dependencies

If additional unlocked packages were created to hold unpackaged
dependencies, they must be promoted as well. To promote dependencies
automatically use `--promote_dependencies True` with the
`promote_package_version` task, or customize the
`release_2gp_production` flow to include that option.

```console
$ cci task run promote_package_version --version_id 04t000000000000 --promote_dependencies True
```

Test a Production Version -------------------

To test the new package version:

```
$ cci flow run ci_release --org release
```

The `ci_release` flow installs the latest production release version and
runs the Apex tests from the managed package on a scratch org.
