# Key Concepts

Let's review some important concepts when building and testing features
using CumulusCI.

## Packages

CumulusCI works well with both managed package projects and org
implementations. However, packages always play a role in how projects
are built and deployed.

A _package_ is a container for something as small as an individual
component or as large as a sophisticated application. After creating a
package, you can distribute it to other Salesforce users and
organizations, including those outside your company.

_Unmanaged packages_ are typically used to distribute open-source
(non-proprietary) features or application templates to provide
developers with the basic building blocks for an application. After the
components are installed from an unmanaged package in a specific org,
it's what's known as an _org implementation_. These freshly installed
components can be edited by the owners of the implementation. The
developer who created and uploaded the unmanaged package has no control
over the installed components, and can't change or upgrade them.

_Managed packages_ are typically used by Salesforce partners to
distribute and sell applications to customers. They are proprietary code
that can be upgraded and deployed only by the developer that built them.
To ensure seamless upgrades, managed packages don't allow certain
destructive changes, such as deleting objects or fields.

In CumulusCI, packages are built and deployed via projects.

## Projects

When you work with CumulusCI, you do so inside a _project_. A project is
an individual Git repository that contains both Salesforce metadata and
CumulusCI automation (such as tasks and flows) that builds and releases
the project. If you are building multiple packages, we strongly
recommend organizing each package as a separate project in its own
repository.

```{important}
CumulusCI's standard library assumes that there is one package per
repository, so it will work best if you follow this convention.
```

It's important to note that a project doesn't have to contain a
package. For example, a project can deliver unpackaged metadata, deliver
automation but no metadata at all, or provide test data for QA. A
project can contain the entirety of a product offered to customers, or
be just one of multiple projects that combine to form a complete
product.

To sum up, although a project doesn't require a package, a package
requires a project to be built and deployed.

## Tasks and Flows

CumulusCI uses a framework of _tasks_ and _flows_ to organize the
automation that is available to each project.

Tasks are units of automation. A task can perform a deployment, load a
dataset, retrieve data from an org, install a managed package, or do
many other things. CumulusCI ships with scores of tasks in its standard
library. You can run `cci task list` to view them all.

Popular task commands include:

-   `cci task list`: Review the tasks available in a project.
-   `cci task info <name>`: Learn more about a task `<name>` and how to
    configure its options.
-   `cci task run <name> --org <org>`: Run the task `<name>` against the
    org `<org>`.

For example, the `run_tests` task executes Apex unit tests. If you have
an org called `dev`, you can run this task against it with the command
`cci task run run_tests --org dev`.

Many operations in CumulusCI, including creating new orgs, use flows.
Flows are ordered sequences of tasks (and even other flows!) that
produce a cohesive outcome, such as an org that's configured to suit a
workflow like development, QA, or product demonstration.

Popular flow commands include:

-   `cci flow list`: Review the flows available in a project.
-   `cci flow info <name>`: Learn more about the flow `<name>` and the
    tasks it contains.
-   `cci flow run <name> --org <org>`: Run the flow `<name>` against the
    org `<org>`.

For example, the `dev_org` flow sets up an org for development purposes.
If you have an org called `dev`, you can run this flow against it with
the command `cci flow run dev_org --org dev`.

Many of the most common flows you'll work with in CumulusCI are
designed to build and configure specific orgs for you. Here's a few of
the most common flows that build orgs.

-   `dev_org`: This flow builds an unmanaged org designed for
    development use. It's typically used with an org whose
    configuration is `dev` or `dev_namespaced`.
-   `qa_org`: This flow builds an unmanaged org designed for testing.
    It's typically used with an org whose configuration is `qa`.
-   `install_beta`: This flow builds a managed org with the latest beta
    release installed, for projects that build managed packages. It's
    typically used with an org whose configuration is `beta`.
-   `install_prod`: This flow builds a managed org with the latest
    release installed, for projects that build managed packages.
-   `push_upgrade_org`: This flow builds a managed org that starts
    with the latest release installed and available for all Profiles.
    It then upgrades the package dependencies and the package itself to
    their latest betas, installing upgrades for System Administrators only,
    and runs `config_qa` to set up the org for testing. This simulates
    a subscriber push upgrade for non-System Administrator users.
    It's typically used with an org whose configuration is `release`.

CumulusCI derives the library of tasks and flows available for any
project by combining its internal standard library with your
customizations in `cumulusci.yml`. Customizations can add new tasks and
flows, customize the way tasks behave, and extend, combine, and modify
flows to better suit the project's needs. We cover customization in
depth in the [](config) section.

## Project Structure

### Project Directory

The project directory is the root of your CumulusCI project. Because
each project is linked to a single GitHub repository, CumulusCI knows
which project you are working on by the current working directory of
your shell.

```{tip}
Avoid headaches by making sure you're in the correct repository for
your project before running project-specific commands. Otherwise, your
project produces an error. (**Check your repo first** when
troubleshooting in CumulusCI and potentially save yourself an extra trip
to this guide.)
```

In order to be used as a CumulusCI project, a directory must both be a
Git repository and contain a `cumulusci.yml` configuration file. We
cover how to get set up with a new or existing CumulusCI project in the
[](get-started) section.

### `cumulusci.yml`

The `cumulusci.yml` file defines a project's automation. It contains
all the customizations and configurations that pertain to your
project's lifecycle. It can encompass everything from customizing the
shapes of scratch orgs to configuring tasks and flows.

Learn more about customizing CumulusCI automation in the
[](config) section.

### `force-app` (or `src`)

The main body of the project's code and metadata lives in the default
package directory, which is the `force-app` directory for Salesforce
DX-format projects and the `src` directory for Metadata API-format
projects. `force-app` defines what's included when you release a
managed package from your CumulusCI project. (Or when you release an
unlocked package, or if you're not releasing a package at all but
running the `deploy` task to get the metadata into an org in unmanaged
form.)

### `orgs` directory

The `.json` files found in the `orgs` directory define the Salesforce DX
org configurations that are available to the project. See
[](scratch-orgs) for
more information.

### `datasets`

Each project can have one or more datasets: on-disk representations of
record data that can be inserted into Salesforce orgs, and that can also
be modified and re-captured during the evolution of the project.
Datasets are stored in the `datasets` directory. Learn more about
datasets in [](data).

### `robot`

Robot Framework provides browser automation for end-to-end testing. Each
project contains a `robot` directory, which stores the project's Robot
Framework test suites. New projects start with a simple Robot test case
that creates a Contact record.

While Robot Framework is used primarily for automated browser testing,
it can also be harnessed to help configure orgs where other strategies
and APIs are insufficient.

See [Acceptance Testing with Robot Framework](acceptance-testing-with-robot-framework) for more information.

### `unpackaged` metadata

As we touched upon earlier, a project doesn't just encompass the
contents of a managed package or a single deployment. It also includes
_unpackaged metadata_: extra bundles of Salesforce metadata that further
tailor an org or complete the product.

In a CumulusCI project, all unpackaged metadata is stored in
subdirectories within the `unpackaged` directory. Unpackaged metadata
plays multiple roles, including preparing an org for installing
packages, adding more customization after the package or application is
deployed, and customizing specific orgs that are used in the product's
development process.

Learn more in the
[](unpackaged) section.

## Project Orgs & Services

Orgs and services are external, authenticated resources that each
project uses. CumulusCI makes it easy to connect orgs and services to a
single project, or to use them across many projects.

### Orgs

Each project has its own set of orgs, including active scratch orgs,
persistent orgs like a production or packaging org, and predefined
scratch org configurations. CumulusCI securely stores org authentication
information in its keychain, making it easy to access connected orgs at
any time. The `cci org list` command shows all of the orgs connected to
a project. Orgs can also be shared across multiple projects.

Configuring orgs in CumulusCI is powerful, but comes with some
complexity. For details, see [](scratch-orgs) and
[](connected-orgs).

### Services

Services represent external resources used by CumulusCI automation, such
as access to a GitHub account or a MetaDeploy instance. Services are
usually, but not always, connected to CumulusCI across projects as part
of the global keychain. The command `cci service list` shows you which
services are connected in the context of the current project.

Global services are easy to use and share. We recommend that you use
them as much as possible. However, services can also be connected at the
project level, which means that they're scoped to a single project and
cannot be shared.

For more information on configuring services via the `cci` command line
see the [](manage-services) section.
