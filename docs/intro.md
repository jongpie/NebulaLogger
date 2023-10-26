# Introduction

CumulusCI helps development teams build great applications on the
Salesforce platform by automating org setup, testing, and deployment.

## Automation with CumulusCI

If your product development lifecycle and release process is anything
like ours at Salesforce.org, it's complex. You're managing multiple
packages, dependencies, orgs, and release versions. Not to mention
managing org metadata and all the setup operations that need to run in
the right sequence, before or after a package is installed, to create a
properly configured org.

For example, Nonprofit Success Pack (NPSP) is one of Salesforce.org's
flagship open source products. NPSP is a large, complex application with
many different components. It consists of six managed packages (five
dependencies plus itself) with multiple dependency relationships. Using
automation, all five dependent packages are deployed in the right
sequence; the unpackaged record types for the Account and Opportunity
objects are delivered; and the final configurations to make the
customers' experience better, such as setting up Global Actions and
delivering translations, are performed. Biweekly NPSP releases are easy
for new customers to install, with all the right configuration and
without requiring end users to work through a lengthy setup guide.

The CumulusCI suite of tools is part of the not-so-secret sauce that
makes it possible for Salesforce.org to build and release products at
high volume, velocity, and quality. CumulusCI automation runs throughout
the Salesforce development lifecycle, starting from feature branches
through the delivery of the latest release.

-   The CumulusCI command-line interface, `cci`, runs single-action
    tasks and multiple-action flows for development and testing.
-   MetaCI uses CumulusCI flows to build Salesforce managed packages
    from GitHub repositories.
-   MetaDeploy automates setup and configuration of customer orgs.

You can use the very same automation used internally by Salesforce.org
to quickly:

-   Build sophisticated orgs with dependencies automatically installed.
-   Load and retrieve sample datasets to make your orgs feel like a
    production environment.
-   Apply transformations to existing metadata to tailor orgs to your
    specific requirements.
-   Run builds in continuous integration systems.
-   Create end-to-end browser tests and set up automation using [Robot
    Framework](https://robotframework.org/).

The automation defined using CumulusCI is portable. It's stored in a
version control repository and can be run from your local command line,
from a continuous integration system, or from a customer-facing
installer. CumulusCI can run automation on scratch orgs created using
the Salesforce CLI, or on persistent orgs like sandboxes, production
orgs, and Developer Edition orgs.

Finally, by way of introduction, CumulusCI is more than just a set of
tools. It represents our holistic approach to product development.
Rather than focusing on just the [Org Development
Model](https://trailhead.salesforce.com/en/content/learn/modules/org-development-model)
or the [Package Development
Model](https://trailhead.salesforce.com/en/content/learn/modules/sfdx_dev_model),
Salesforce.org has implemented its own _Product Delivery Model_ using
CumulusCI.

## The Product Delivery Model

The Product Delivery Model focuses on the customer experience, not on
the technical artifacts you're delivering. When building a product,
there are detailed technical considerations for whether an individual
component is best distributed within a package, or as additional
unpackaged metadata, or as setup automation that runs before or after a
package is installed. It's not uncommon for managed packages that
don't use the Product Delivery Model to require customers to perform
manual configuration steps that can take hours, or even days, to
complete. The Product Delivery Model lets teams develop configurations
directly into automated workflows, making it possible to deliver a
first-class, fully configured product to the customer.

CumulusCI automation, which makes it easy to create products that span
multiple package repositories and include complex setup operations, best
implements the Product Delivery Model, along with MetaDeploy and other
applications in the CumulusCI suite.

## Anyone Can Use CumulusCI

Salesforce.org uses CumulusCI to develop products for our nonprofit and
education constituents --- both public, open source products such as
NPSP and commercial managed package products developed in private GitHub
repositories. But anyone developing on the Salesforce platform can use
CumulusCI. It supports both open source and private development, and
building managed package products or org implementations.

Automation defined using CumulusCI can support all roles on a project.

-   _Developers_ can create new development environments for different
    feature branches.
-   _Quality engineers_ can create test environments from feature
    branches and managed package installs.
-   _Documentation teams_ can create environments to interact with new
    features and retrieve screenshots.
-   _Product managers_ can create environments to interact with new
    features and provide feedback on future work.
-   _Release engineers_ can create beta and final releases and push them
    to subscriber orgs.
-   _Partners_ can create their own projects on top of your package.
-   _Customers_ can install the product and get set up using the same
    automation steps used during development and QA.

## Where Does CumulusCI Fit in the Toolchain?

Developers often ask whether CumulusCI competes with or replaces
Salesforce DX, the Salesforce command line interface (CLI) for
development, testing, and continuous integration. It doesn't. Like
Salesforce DX, CumulusCI is designed to maintain the source of truth for
a project in a version-controlled repository, and to make it as easy as
possible to set up an org from scratch. CumulusCI uses the Salesforce
CLI to perform operations such as creating scratch orgs, and is an
alternative to bash scripts for running sequences of Salesforce CLI
commands.

CumulusCI builds on top of the commands provided by the Salesforce CLI,
and helps to manage and orchestrate them into a simple, straightforward
user experience. CumulusCI implements a complete development, test, and
release process that comes with a standard library of functionality,
while the Salesforce CLI is a lower-level toolbelt that drives
particular workflows within the overall process.

For non-developers, knowing Salesforce DX isn't a requirement for using
CumulusCI. Neither is knowing Python, the language CumulusCI is written
in (in the same way that most Salesforce DX users don't need to know
Node.js). If you're going to get fancy with CumulusCI customizations,
only then does Python come in handy.

## Why Is It Called CumulusCI?

Before there was the toolset known today as CumulusCI, there was a
product that would go on to become Nonprofit Success Pack (NPSP). This
product had the code name Cumulus. Early on, continuous integration (CI)
tools were created for the Cumulus product. This tooling expanded in
scope and scale to eventually become CumulusCI. Even though it's used
for much more than CI, and for many more products than NPSP, the name
has stuck.

## Learn More Through Demos

Love demos? These no-audio screencasts show how to use CumulusCI from a
command line.

```{html}
<!-- https://stackoverflow.com/a/58399508/113477 -->
<link rel="stylesheet"
  type="text/css"
  href="https://cdnjs.cloudflare.com/ajax/libs/asciinema-player/2.4.1/asciinema-player.min.css" />
<script src="https://cdn.jsdelivr.net/npm/asciinema-player@2.6.1/resources/public/js/asciinema-player.min.js"></script>
```

Initialize a fresh CumulusCI project.

```{html}
<asciinema-player preload="True" poster="npt:0:01" src="https://raw.githubusercontent.com/SFDO-Tooling/cci-demo-animations/master/build/1_setup.cast"></asciinema-player>
```

Retrieve metadata from a Salesforce org and save it in GitHub.

```{html}
<asciinema-player preload="True" poster="npt:0:01" src="https://raw.githubusercontent.com/SFDO-Tooling/cci-demo-animations/master/build/2_retrieve_changes.cast"></asciinema-player>
```

Manage sample or test data.

```{html}
<asciinema-player preload="True" poster="npt:0:01" src="https://raw.githubusercontent.com/SFDO-Tooling/cci-demo-animations/master/build/3_populate_data.cast"></asciinema-player>
```

Customize flows and use CumulusCI for QA.

```{html}
<asciinema-player preload="True" poster="npt:0:01" src="https://raw.githubusercontent.com/SFDO-Tooling/cci-demo-animations/master/build/4_qa_org.cast"></asciinema-player>
```

For a narrated demo, see Jason Lantz's [PyCon 2020
presentation](https://www.youtube.com/watch?v=XL77lRTVF3g) (00:36
through 00:54).
