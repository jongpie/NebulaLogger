# Release a First-Generation Managed Package

This section outlines how to release first-generation (1GP) Salesforce
managed package projects. Salesforce.org's Release Engineering team
practices [CumulusCI Flow](cumulusci-flow), which incorporates all of these steps.

## Prerequisites

This section assumes:

-   [CumulusCI is installed](get-started) on your computer.
-   A Salesforce managed package project has been [configured](work-on-an-existing-cumulusci-project)
    for use with CumulusCI.
-   A packaging org [is connected](connected-orgs) to CumulusCI under the name of `packaging`.

To verify this setup and display information about the connected
packaging org:

```console
$ cci org info packaging
```

```{note}
The packaging org can be listed under an alias. For a complete list of
orgs connected to CumulusCI, run `cci org list`.
```

If your project has been configured for use with CumulusCI,
`cci org info` lists the project's namespace under `package__namespace`
in the output.

### Create a Managed Package Project

If you haven't created a managed package project, follow these steps:

-   Create a Developer Edition Org. ([Sign up for one
    here.](https://developer.salesforce.com/signup))
-   [Create a managed
    package](https://developer.salesforce.com/docs/atlas.en-us.packagingGuide.meta/packagingGuide/packaging_uploading.htm).
-   [Assign a
    namespace](https://developer.salesforce.com/docs/atlas.en-us.packagingGuide.meta/packagingGuide/isv2_3_quickstart.htm).
-   Configure the namespace in CumulusCI.

## Deploy to a Packaging Org

CumulusCI deploys metadata to a `packaging` org with the `ci_master`
flow.

```{warning}
The `ci_master` flow runs the
[](uninstall-packaged-incremental) task,
which deletes any metadata from the package in the target org that's
not in the repository.
```

```console
$ cci flow run ci_master --org packaging
```

The `ci_master` flow executes these tasks in the target org.

-   Updates any project dependencies
-   Deploys any unpackaged metadata located in the `pre` directory
-   Deploys packaged metadata
-   Deploys destructive changes to remove metadata in the target org
    that is no longer in the local repository
-   Runs the `config_packaging` flow, which by default consists only of
    the [](update-admin-profile) task.

```{tip}
To list each step in the `ci_master` flow, run
`cci flow info ci_master`.
```

CumulusCI separates uploading metadata to the packaging org and
releasing a beta version of the package into the `ci_master` and
`release_beta` flows, respectively. This separation offers discretion to
run additional checks against the org, if necessary, between deploy and
release steps.

## Create a Beta Version

The `release_beta` flow groups the common tasks that must be executed
for the release of a new beta version of a project.

```console
$ cci flow run release_beta --org packaging
```

This flow _always_ runs against the project's `packaging` org, where
it:

-   Uploads a new beta version of the managed package.
-   Creates a new GitHub release tag for the new beta version. Extension
    packages that also use CumulusCI require this release tag to find
    the latest version when this repository is listed as a dependency.
-   [Generates Release Notes](github-release-notes).
-   Syncs feature branches with the `main` branch, which automatically
    integrates the latest changes from `main`. For more information see
    [](auto-merging).

```{important}
This flow assumes that the package contents were already deployed using
the `ci_master` flow. It does _not_ include a step to deploy them.
```

To create a new beta version for your project without the bells and
whistles, use the `upload_beta` task:

```console
$ cci task run upload_beta --org packaging --name package_version
```

## Test a Beta Version

The `ci_beta` flow installs the latest beta version of the project in a
scratch org, and runs Apex tests against it.

```console
$ cci flow run ci_beta --org beta
```

This flow is intended to be run whenever a beta release is created.

## Upload and Test a Final Version

To upload a production release of your managed package project:

```
$ cci flow run release_production --org packaging
```

Similar to `release_beta`, this task uploads a new production version of
your package, creates a release tag in GitHub, and aggregates release
notes for the new version.

```{important}
This flow assumes that the package contents have previously been
deployed using the `ci_master` flow.
```

To upload the new production version without creating the GitHub tag and
generating release notes:

```
$ cci task run upload_production --name v1.2.1
```

To test the new package version:

```
$ cci flow run ci_release --org release
```

The `ci_release` flow installs the latest production release version,
and runs the Apex tests from the managed package on a scratch org.
