# Develop a Project

A general overview on how to develop a Salesforce project with
CumulusCI.

## Set Up a Dev Org

The `dev_org` flow creates an org to develop on by moving all metadata
(managed and unmanaged) into the org, and configuring it to be ready for
development.

```{tip}
Run `cci flow info dev_org` for a full list of the `dev_org` flow steps.
```

To run the `dev_org` flow against the project's
[default org](set-a-default-org):

```console
$ cci flow run dev_org
```

To run the `dev_org` flow against a specific org, use the `--org`
option. The following runs the `dev_org` flow against the org named
`dev`.

```console
$ cci flow run dev_org --org dev
```

Open the new `dev` org to begin development.

```console
$ cci org browser dev
```

## List Changes

To see what components have changed in a target org use the
[](list-changes) task:

```console
$ cci task run list_changes --org dev
```

```{admonition} Wizard Note
This functionality relies on Salesforce's [source
tracking](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_setup_enable_source_tracking_sandboxes.htm)
feature, which is currently available only in Scratch Orgs, Developer
Sandboxes, and Developer Pro Sandboxes.
```

For more information, see [List and Retrieve
Options](list-and-retrieve-options).

(retrieve-changes)=

## Retrieve Changes

The [](retrieve-changes) task supports both
Salesforce DX and Metadata API-format source code. It utilizes the
[SourceMember](https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/tooling_api_objects_sourcemember.htm)
`sObject` to detect what has changed in an org, and also gives you
discretion regarding which components are retrieved when compared to the
[](dx-pull) task.

To retrieve _all_ changes in an org:

```console
$ cci task run retrieve_changes --org dev
```

For information on retrieving specific subsets of changes, see [List and
Retrieve Options](list-and-retrieve-options).

### `--path`

Manual tracking of component versions offers the possibility of
retrieving one set of changes into directory A, and retrieving a
different set of changes into directory B. By default, changes are
retrieved into the `src` directory when using Metadata API source
format, or the default package directory (`force-app`) when using
Salesforce DX source format.

To retrieve metadata into a _different_ location use the `--path`
option:

```console
$ cci task run retrieve_changes --org dev --path your/unique/path
```

(list-and-retrieve-options)=

## List and Retrieve Options

When developing in an org, the changes you're most interested in are
sometimes mixed with other changes that aren't relevant to what you're
doing.

For example, changing metadata like Custom Objects and Custom Fields
often results in changes to Page Layouts and Profiles that you don't
wish to review or retrieve.

It's a common workflow in CumulusCI to use the `list_changes` task,
combined with the options featured in this subsection, to narrow the
scope of changes in the org to the exact elements you desire to retrieve
in your project. When the correct set of metadata is listed, run the
`retrieve_changes` task to bring those changes into the repository.

### `--include` & `--exclude`

When retrieving metadata from an org, CumulusCI represents each
component name as the combination of its type (such as a `Profile`,
`CustomObject`, or `ApexClass`) and its API name:
`MemberType: MemberName`. An `ApexClass` named `MyTestClass` would be
represented as `ApexClass: MyTestClass`.

The `--include` and `--exclude` options lets you pass multiple [regular
expressions](https://en.wikipedia.org/wiki/Regular_expression) to match
against the names of changed components. This metadata is either
included or excluded depending on which option the regular expression is
passed. Multiple regular expressions can be passed in a comma-separated
list.

The following lists all modified metadata that ends in "Test" and
"Data" in the default org.

```console
$ cci task run list_changes --include "Test$,Data$"
```

Since the metadata string that CumulusCI processes also includes the
`MemberType`, use exclusions and inclusions that filter whole types of
metadata.

The following will list all changes _except for_ those with a type of
`Profile`.

```console
$ cci task run list_changes --exclude "^Profile: "
```

### `--types`

To list or retrieve changed metadata of the same type, use the `--types`
option along with the [metadata
type](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_types_list.htm)
to retrieve.

The following retrieves all changed `ApexClass` and `ApexComponent`
entities in the default org.

```console
$ cci task run retrieve_changes --types ApexClass,ApexComponent
```

## Push Changes

Developers often use an editor or IDE like Visual Studio Code to modify
code and metadata stored in the repository. After making changes in an
editor, push these changes from your project's local repository to the
target org.

If your project uses the Salesforce DX source format, use the
[](dx-push) task.

```console
$ cci task run dx_push
```

If your project uses the Metadata API source format, use the
[](deploy) task:

```console
$ cci task run deploy
```

The `deploy` task has _many_ options for handling a number of different
scenarios. For a comprehensive list of options, see the
[](deploy) task reference.

## Run Apex Tests

CumulusCI can execute Apex tests in an org with the `run_tests` task,
and optionally report on test outcomes and code coverage. Failed tests
can also be retried automatically.

```console
$ cci task run run_tests --org <org_name>
```

The `run_tests` task has _many_ options for running tests. For a
comprehensive list of options and examples, see the
[](run-tests) task reference.

## Set Up a QA Org

The `qa_org` flow sets up org environments where quality engineers test
features quickly and easily. `qa_org` runs the specialized `config_qa`
flow after deploying the project's unmanaged metadata to the org.

The following runs the `qa_org` flow against the `qa` org.

```console
$ cci flow run qa_org --org qa
```

### Create QA Configurations

Out of the box, and even in some active projects, the `config_dev` and
`config_qa` flows are the same. Many teams have a requirement for
additional configurations to be deployed when performing QA, but not
when developing a new feature.

At Salesforce.org, our product teams often modify the `config_qa` flow
to deploy configurations that pertain to large optional features in a
package. These configurations are subsequently tested by the product's
Robot Framework test suites.

To retrieve your own QA configurations, spin up a new org:

```
$ cci flow run qa_org
```

Make the necessary changes, and run:

```
$ cci task run retrieve_qa_config
```

This task defaults to retrieving this metadata under
`unpackaged/config/qa`.

```{tip}
The configuration metadata can also be stored in a different location by
using the `--path` option.
```

To delete the org\...

```console
$ cci org remove qa
```

Then re-create it\...

```console
$ cci flow run qa_org --org qa
```

Then run the `deploy_qa_config` to deploy the previously retrieved
configurations to the org.

```console
$ cci task run deploy_qa_config --org qa
```

To require that the `qa_org` flow always runs this task, add a
`deploy_qa_config` task step under the `flows__config_qa` section of the
`cumulusci.yml` file.

```yaml
config_qa:
    steps:
        3:
            task: deploy_qa_config
```

Now `config_qa` (which is included in the `qa_org` flow) executes the
`deploy_qa_config` task as the third step in the flow.

## Manage Dependencies

CumulusCI is built to automate the complexities of dependency management
for projects that extend, customize, or compose other projects. CumulusCI
currently handles these main types of dependencies for projects.

-   **GitHub Repository**: Dynamically resolve a product release, and
    its own dependencies, from a CumulusCI project on GitHub.
-   **Packages**: Require a specific version of a managed package or
    unlocked package.
-   **Unmanaged Metadata**: Require the deployment of unmanaged
    metadata.

Dependencies are listed in the `project__dependencies` section of
`cumulusci.yml`

```yaml
project:
    dependencies:
```

The `update_dependencies` task handles deploying dependencies to a
target org, and is included in all flows designed to deploy or install
to an org, such as `dev_org`, `qa_org`, `install_prod`, and others.

To run the `update_dependencies` task manually:

```console
$ cci task run update_dependencies
```

### GitHub Repository Dependencies

GitHub repository dependencies create a dynamic dependency between the
current project and another CumulusCI project on GitHub. This is an
example of listing Salesforce.org's
[EDA](https://github.com/SalesforceFoundation/EDA) product as a
dependency.

```yaml
project:
    dependencies:
        - github: https://github.com/SalesforceFoundation/EDA
```

When `update_dependencies` runs, these steps are taken against the
referenced repository.

-   Look for the `cumulusci.yml` file and parse if found.

-   Determine if the project has subfolders under `unpackaged/pre`. If
    found, deploy them first, in alphabetical order.

-   Determine if the project specifies any dependencies in the
    `cumulusci.yml` file. If found, recursively resolve those
    dependencies and any dependencies belonging to them.

-   Determine whether to install the project as as a managed package or unmanaged metadata:

    : - If the project has a namespace configured in the
    `cumulusci.yml` file, treat the project as a managed package
    unless the `unmanaged` option is set to `True` in the
    dependency. - If the project has a namespace and is _not_ configured as
    unmanaged, use the GitHub API to locate the latest managed
    release of the project and install it.

-   If the project is an unmanaged dependency, the main source directory
    is deployed as unmanaged metadata.

-   Determine if the project has subfolders under `unpackaged/post`. If
    found, deploy them next, in alphabetical order. Namespace tokens are
    replaced with `<namespace>__` if the project is being installed as a
    managed package, or an empty string otherwise.

#### Reference Unmanaged Projects

If the referenced repository does not have a namespace configured, or if
the dependency specifies the `unmanaged` option as `True`, the
repository is treated as unmanaged.

Here is a project with Salesforce.org's
[EDA](https://github.com/SalesforceFoundation/EDA) package listed as an
unmanaged dependency:

```yaml
project:
    dependencies:
        - github: https://github.com/SalesforceFoundation/EDA
          unmanaged: True
```

The EDA repository is configured for a namespace, but the dependency
specifies `unmanaged: True`, so EDA deploys as unmanaged metadata.

CumulusCI only supports unmanaged repositories in Metadata API source
format at present.

#### Reference a Specific Tag

To reference a specific version of the product other than the most
recent commit on the main branch (for unmanaged projects) or the most
recent production release (for managed packages), use the `tag` option
to specify a tag from the target repository. This option is useful for
testing against specific package versions, pinning a dependency to a
version rather than using the latest release, and recreating org
environments for debugging.

```yaml
project:
    dependencies:
        - github: https://github.com/SalesforceFoundation/EDA
          tag: rel/1.105
```

The EDA repository's tag `rel/1.105` is used instead of the latest
production release of EDA (1.111, for this example).

#### Skip `unpackaged/*` in Reference Repositories

If the referenced repository has unpackaged metadata under
`unpackaged/pre` or `unpackaged/post`, use the `skip` option to skip
deploying that metadata with the dependency.

```yaml
project:
    dependencies:
        - github: https://github.com/SalesforceFoundation/EDA
          skip: unpackaged/post/course_connection_record_types
```

### Package Dependencies

Managed package and unlocked package dependencies are rather simple.
Under the `project__dependencies` section of the `cumulusci.yml` file,
specify the namespace of the target package, and the required version
number, or specify the package version id.

```yaml
project:
    dependencies:
        - namespace: npe01
          version: 3.6
        - version_id: 04t000000000001
```

Package dependencies can include any package, whether or not it is built
as a CumulusCI project. Dependencies on managed packages may be
specified using the namespace and version or the version id.
Dependencies on unlocked packages should use the version id.

### Package Install Keys (Passwords)

Some packages are protected by an install key, which must be present in
order to install the package. CumulusCI dependencies can use the
`password_env_name` key to instruct CumulusCI to retrieve the package
install key from an environment variable. This key is available on both
package version dependencies and on GitHub dependencies:

```yaml
project:
    dependencies:
        - namespace: my_namespace
          version: 3.6
          password_env_name: INSTALL_KEY
        - github: https://github.com/MyOrg/MyRepo
          password_env_name: MY_REPO_KEY
```

### Unmanaged Metadata Dependencies

Specify unmanaged metadata to be deployed by specifying a `zip_url` or a
`github` URL, and, optionally, `subfolder`, `namespace_inject`,
`namespace_strip`, and `unmanaged` under the `project__dependencies`
section of the cumulusci.yml file.

```yaml
project:
    dependencies:
        - zip_url: https://SOME_HOST/metadata.zip
        - github: https://github.com/SalesforceFoundation/EDA
          subfolder: unpackaged/post/course_connection_record_types
          ref: 0cabfe
```

When the `update_dependencies` task runs, it downloads the zip file or
GitHub subdirectory and deploys it via the Metadata API. The zip file
must contain valid metadata for use with a deploy, including a
`package.xml` file in the root.

Unmanaged metadata dependencies from GitHub may optionally specify the
`ref` to download. If they do not, unmanaged GitHub dependencies are
resolved like other GitHub references. See [Controlling GitHub
Dependency Resolution](controlling-github-dependency-resolution) for
more details on resolution of dynamic dependencies.

```{note}
In versions of CumulusCI prior to 3.33.0, unmanaged GitHub dependencies
always deployed the most recent commit on the default branch.
```

#### Specify a Subfolder

Use the `subfolder` option to specify a subfolder of the zip file or
GitHub repository to use for the deployment.

```{tip}
This option is handy when referring to metadata stored in a GitHub
repository.
```

When `update_dependencies` runs, it still downloads the zip from
`zip_url`, but then builds a new zip containing only the content of
`subfolder`, starting inside `subfolder` as the zip's root.

#### Inject Namespace Prefixes

CumulusCI has support for tokenizing references to a package's
namespace prefix in code. When tokenized, all occurrences of the
namespace prefix, are replaced with `%%%NAMESPACE%%%` inside of files
and `___NAMESPACE___` in file names. The `namespace_inject` option
instructs CumulusCI to replace these tokens with the specified namespace
before deploying the unpackaged dependency.

For more on this topic see [](namespace-injection).

(pinning-github-dependencies)=

### Pinning GitHub Dependencies

By default, CumulusCI resolves dynamic GitHub dependencies to the latest
available releases. In some cases, this may be undesirable. You can use
dependency pinning to control how dependencies are resolved, including
transitive dependencies referenced by your own direct dependencies.

Use the `project__dependency_pins` section of your `cumulusci.yml` to
establish pins. Each pin includes the keys `github`, which must match
the URL of the repo you wish to pin, and a `tag` to which you wish to
pin the dependency. Here's an example that pins NPSP and its transitive
dependencies to specific versions:

```yaml
project:
    dependencies:
        - github: https://github.com/SalesforceFoundation/NPSP
    dependency_pins:
        - github: https://github.com/SalesforceFoundation/NPSP
          tag: rel/3.219
        - github: https://github.com/SalesforceFoundation/Contacts_and_Organizations
          tag: rel/3.19
        - github: https://github.com/SalesforceFoundation/Households
          tag: rel/3.16
        - github: https://github.com/SalesforceFoundation/Recurring_Donations
          tag: rel/3.22
        - github: https://github.com/SalesforceFoundation/Relationships
          tag: rel/3.12
        - github: https://github.com/SalesforceFoundation/Affiliations
          tag: rel/3.10
```

Pins affect resolution of managed package versions and any unmanaged dependencies
included in the target repositories.

If CumulusCI encounters a conflict with an existing tag or other specifier
while attempting to pin dependencies, like this:

```yaml
project:
    dependencies:
        - github: https://github.com/SalesforceFoundation/NPSP
          tag: rel/3.220
    dependency_pins:
        - github: https://github.com/SalesforceFoundation/NPSP
          tag: rel/3.219
```

it will stop and require you to resolve the conflict by removing either the pin
or the dependency specification.

We recommend using pins only when referencing external products whose development
process or release schedule you do not control, such as NPSP and EDA.
In most cases, it's preferable for dependencies within a product suite to remain
unpinned to support ongoing development.

(controlling-github-dependency-resolution)=

### Controlling GitHub Dependency Resolution

CumulusCI converts dynamic dependencies specified via GitHub
repositories into specific package versions and commit references by
applying one or more _resolvers_. You can customize the resolvers that
CumulusCI applies to control when it will use beta managed packages or
second-generation feature test packages, or to intervene more deeply in
the dependency resolution process.

CumulusCI organizes resolvers into _resolution strategies_, which are
named, ordered lists of resolvers to apply. When CumulusCI applies a
resolution strategy to a dependency, it applies each resolver from top
to bottom until a resolver succeeds in resolving the dependency.

Four resolution strategies are provided in the CumulusCI standard
library:

> -   `latest_release`, which will attempt to resolve to the latest
>     managed release of a managed package project.
> -   `include_beta`, which will attempt to resolve to the latest beta,
>     if any, or managed release of a managed package project.
> -   `commit_status`, which will resolve to second-generation package
>     betas created on feature branches, if any, or the main branch,
>     before falling back to managed package releases. This strategy
>     is used only in the `qa_org_2gp` and `ci_feature_2gp` flows.
> -   `unlocked`, which will resolve to unlocked package betas
>     created on feature branches, if any, or the main branch.
>     This strategy does _not_ fall back to managed package releases,
>     and is used in the `qa_org_unlocked` flow.
>     The complete list of steps taken by each resolution strategy is given
>     below.

Each flow that resolves dependencies selects a resolution strategy that
meets its needs. Two aliases, `production`, and `preproduction`, are
defined for this purpose, because in many cases a development flow like
`dev_org` or `install_beta` will want to utilize a _different_
resolution strategy than a production flow like `ci_master` or
`install_prod`.

By default, both `production` and `preproduction` use the
`latest_release` resolution strategy. To opt to have development flows
use beta versions of managed package dependencies, you can switch the
`preproduction` alias to point to the `include_beta` resolution
strategy:

    project:
        dependency_resolutions:
            preproduction: include_beta
            production: latest_release

After this change, flows like `dev_org` will install beta releases of
dependencies, if present.

#### Resolution Strategy Details

The standard resolution strategies execute the following steps to
resolve a dependency:

**latest_release**:

This resolution strategy is suitable for any build for products that
wish to consume production releases of their dependencies during
development and testing. It is also suitable for production flows (such
as `install_prod` or a MetaDeploy installer flow) for all products.

-   If a `tag` is present, use the commit for that tag, and any package
    version found there. (Resolver: `tag`)
-   Identify the most recent production package release via the GitHub
    Releases section. If located, use that package and commit.
    (Resolver: `latest_release`)
-   Use the most recent commit on the repository's main branch as an
    unmanaged dependency. (Resolver: `unmanaged`)

**include_beta**:

This resolution strategy is suitable for any pre-production build for
products that wish to consume beta releases of their dependencies during
development and testing.

-   If a `tag` is present, use the commit for that tag, and any package
    version found there. (Resolver: `tag`)
-   Identify the most recent beta package release via the GitHub
    Releases section. If located, use that package and commit.
    (Resolver: `latest_beta`)
-   Identify the most recent production package release via the GitHub
    Releases section. If located, use that package and commit.
    (Resolver: `latest_release`)
-   Use the most recent commit on the repository's main branch as an
    unmanaged dependency. (Resolver: `unmanaged`)

**commit_status**:

This resolution strategy is suitable for feature builds on products that
utilize a release branch model and build second-generation package betas
(using the `build_feature_test_package` flow) on each commit.

> -   If a `tag` is present, use the commit for that tag, and any
>     package version found there. (Resolver: `tag`)
> -   If the current branch is a release branch (`feature/NNN`, where
>     `feature/` is the feature branch prefix and `NNN` is any integer)
>     or a child branch of a release branch, locate a branch with the
>     same name in the dependency repository. If a commit status
>     contains a beta package Id for any of the first five commits on
>     that branch, use that commit and package. (Resolver:
>     `commit_status_exact_branch`)
> -   If the current branch is a release branch (`feature/NNN`, where
>     `feature/` is the feature branch prefix and `NNN` is any integer)
>     or a child branch of a release branch, locate a matching release
>     branch (`feature/NNN`) in the dependency repository. If a commit
>     status contains a beta package Id for any of the first five
>     commits on that branch, use that commit and package. (Resolver:
>     `commit_status_release_branch`)
> -   If the current branch is a release branch (`feature/NNN`, where
>     `feature/` is the feature branch prefix and `NNN` is any integer)
>     or a child branch of a release branch, locate a branch for either
>     of the two previous releases (e.g., `feature/230` in this
>     repository would search `feature/229` and `feature/228`) in the
>     dependency repository. If a commit status contains a beta package
>     Id for any of the first five commits on that branch, use that
>     commit and package. (Resolver:
>     `commit_status_previous_release_branch`)
> -   If a commit status contains a beta package Id for any of the first
>     five commits on the default branch, use that commit and package.
>     (Resolver: `commit_status_default_branch`)
> -   Identify the most recent beta package release via the GitHub
>     Releases section. If located, use that package and commit.
>     (Resolver: `latest_beta`)
> -   Identify the most recent production package release via the GitHub
>     Releases section. If located, use that package and commit.
>     (Resolver: `latest_release`)
> -   Use the most recent commit on the repository's main branch as an
>     unmanaged dependency. (Resolver: `unmanaged`)

**unlocked**:

This resolution strategy is suitable for feature builds on products that
utilize a release branch model and build unlocked package betas
(using the `build_unlocked_test_package` flow) on each commit. It is
also suitable for use cases where a persistent org and Unlocked
Package versions are used for ongoing QA.

> -   If the current branch is a release branch (`feature/NNN`, where
>     `feature/` is the feature branch prefix and `NNN` is any integer)
>     or a child branch of a release branch, locate a branch with the
>     same name in the dependency repository. If a commit status
>     contains a beta package Id for any of the first five commits on
>     that branch, use that commit and package. (Resolver:
>     `unlocked_exact_branch`)
> -   If the current branch is a release branch (`feature/NNN`, where
>     `feature/` is the feature branch prefix and `NNN` is any integer)
>     or a child branch of a release branch, locate a matching release
>     branch (`feature/NNN`) in the dependency repository. If a commit
>     status contains a beta package Id for any of the first five
>     commits on that branch, use that commit and package. (Resolver:
>     `unlocked_release_branch`)
> -   If the current branch is a release branch (`feature/NNN`, where
>     `feature/` is the feature branch prefix and `NNN` is any integer)
>     or a child branch of a release branch, locate a branch for either
>     of the two previous releases (e.g., `feature/230` in this
>     repository would search `feature/229` and `feature/228`) in the
>     dependency repository. If a commit status contains a beta package
>     Id for any of the first five commits on that branch, use that
>     commit and package. (Resolver:
>     `unlocked_previous_release_branch`)
> -   If a commit status contains a beta package Id for any of the first
>     five commits on the default branch, use that commit and package.
>     (Resolver: `unlocked_default_branch`)

#### Customizing Resolution Strategies

Projects that require deep control of how dependencies are resolved can
create custom resolution strategies.

To add a resolution strategy, add a list of the resolvers desired to the
section `project__dependency_resolutions__resolution_strategies` in
`cumulusci.yml`. For example:

    dependency_resolutions:
        production: releases_only
        resolution_strategies:
            releases_only:
                - latest_release

would create a new resolution strategy called `releases_only` that
_only_ can resolve to a production release. (Dependencies without a
production release would cause a failure). It also assigns the alias
`production` to point to `releases_only`, meaning that standard flows
like `install_prod` would use this resolution strategy.

Customizing resolution strategies is an advanced topic. The
out-of-the-box resolution strategies provided with CumulusCI will cover
the needs of most projects. However, this capability is available for
projects that need it.

### Automatic Cleaning of `meta.xml` Files on Deploy

To let CumulusCI fully manage the project's dependencies, the `deploy`
task (and other tasks based on `cumulusci.tasks.salesforce.Deploy`, or
subclasses of it) automatically removes the `<packageVersion>` element
and its children from all `meta.xml` files in the deployed metadata.
Removing these elements does not affect the files on the filesystem.

This feature supports CumulusCI's automatic dependency resolution by
avoiding a need for projects to manually update XML files to reflect
current dependency package versions.

```{note}
If the metadata being deployed references namespaced metadata that does
not exist in the currently installed package, the deployment throws an
error as expected.
```

```{note}
The automatic cleaning of `meta.xml` files can be disabled by setting
the `clean_meta_xml` option to `False`.
```

Developers can also use the `meta_xml_dependencies` task to update the
`meta.xml` files locally using the versions from CumulusCI's calculated
project dependencies.

## Use Tasks and Flows from a Different Project

Dependency handling is used in a very specific context: to install
dependency packages or metadata bundles in a `dependencies` flow that is
a component of some other flow.

CumulusCI also makes it possible to use automation (tasks and flows)
from another CumulusCI project. This feature supports many use cases,
including:

-   Applying configuration from a dependency project, rather than just
    installing the package.
-   Running Robot Framework tests that are defined in a dependency.

For more information, see [](tasks-and-flows-from-a-different-project).
