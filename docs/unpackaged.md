# Manage Unpackaged Configuration

Not everything that's part of an application can be part of a package.

CumulusCI implements the Product Delivery Model by offering support for
complex applications -- applications that may include multiple managed
packages as well as unpackaged metadata, and setup automation that
configures org settings or makes precise changes to existing
configuration.

The tools used to implement that support are _unpackaged metadata_ and
_Metadata ETL_.

Unpackaged metadata refers to metadata that is not delivered as part of
a package, and can include both support metadata delivered to users as
well as metadata that operationally configures orgs used by the product.

Metadata ETL is a suite of tasks that supports surgically altering
existing metadata in an org. It's a powerful technique that alters the
unpackaged configuration in an org without risking damage to existing
customizations by overwriting them with incoming metadata. Metadata ETL
is relevant for delivering applications to customers safely, and is
often a superior alternative to unpackaged metadata.

To learn more, see [](metadata-etl).

(roles-of-unpackaged-metadata)=

## Roles of Unpackaged Metadata

### `unpackaged/pre`: Prepare an Org

Some projects require that unpackaged metadata be deployed to finish the
customization of an org _before_ the package's own code and metadata
are deployed.

For example, the [Nonprofit Success Pack
(NPSP)](https://github.com/SalesforceFoundation/NPSP) must deploy
unpackaged Record Types prior to installing its own packages.
`unpackaged/pre` is the location designed for such metadata, which is
stored in subdirectories such as `unpackaged/pre/first`.

CumulusCI's standard flows that build orgs, such as `dev_org` and
`install_prod`, always deploy metadata bundles found in `unpackaged/pre`
before proceeding to the deployment of the application. It's also easy
to include `unpackaged/pre` metadata in customer-facing installers run
via MetaDeploy.

The `deploy_pre` task, which is part of the `dependencies` flow, is
responsible for deploying these bundles.

```{important}
Do not include metadata in `unpackaged/pre` unless it is intended to be
delivered to _all_ installations of the product.
```

### `unpackaged/post`: Configuration After Package Install

Projects often include metadata that is genuinely part of the
application, but cannot be delivered as part of a managed package for
operational reasons. This metadata must be deployed _after_ the
package's own code and metadata are deployed first and the org is
configured.

For example, a product can't deliver `TopicsForObjects` metadata as
part of a managed package because that type of metadata isn't
packageable. `unpackaged/post` is the home for this kind of metadata,
which is stored in subdirectories such as `unpackaged/post/first`.

```{note}
To learn more about which components are packageable, see the [Metadata
Coverage
Report](https://mdcoverage.secure.force.com/docs/metadata-coverage).
```

CumulusCI's standard flows that build orgs, such as `dev_org` and
`install_prod`, always deploy metadata bundles found in
`unpackaged/post`, making it a full-fledged part of the application.
It's also easy to include `unpackaged/post` metadata in customer-facing
installers run via MetaDeploy.

The `deploy_post` task, which is part of the `config_dev`, `config_qa`,
and `config_managed` flows, is responsible for deploying these bundles.

```{important}
Do not include metadata in `unpackaged/post` unless it is intended to be
delivered to _all_ environments (both managed installations and
unmanaged deployments). It's also critical for managed package projects
that this metadata include namespace tokens (see [namespace
injection](namespace-injection)).
```

### `unpackaged/config`: Tailor an Org

Projects can come with more than one supported configuration in their
CumulusCI automation. For example, projects often support distinct,
tailored `dev_org`, `qa_org`, and `install_prod` flows, each of which
performs a unique setup for their specific use case.

Unpackaged metadata stored in `unpackaged/config` is a tool to support
operational needs that tailor orgs to different configurations. For
instance, a testing-oriented scratch org may need to deploy a customized
set of Page Layouts to help testers easily visualize data under test.
Such page layouts are stored in `unpackaged/config/qa`.

## Unpackaged Metadata Folder Structure

All unpackaged metadata is stored in the `unpackaged` directory tree,
which contains these top-level directories.

-   `unpackaged/pre`
-   `unpackaged/post`
-   `unpackaged/config`

These trees contain metadata bundles in Metadata API or Salesforce DX
format. CumulusCI automatically converts Salesforce DX-format unpackaged
bundles to Metadata API format before deploying them.

(namespace-injection)=

## Namespace Injection

Projects that build managed packages often construct their unpackaged
metadata to be deployable in multiple contexts, such as:

-   Unmanaged deployments, such as developer orgs.
-   Unmanaged namespaced scratch orgs.
-   Managed contexts, such as a beta test org or a demo org created with
    `install_prod`.

For example, metadata located in `unpackaged/post` is deployed after the
application code in both unmanaged and managed contexts. If that
metadata contains references to the application components, it must be
deployable when that metadata is namespaced (in a managed context or
namespaced scratch org) _and_ when it is not (in an unmanaged context).

CumulusCI uses a strategy called _namespace injection_ to support this
use case. Namespace injection is very powerful, and requires care from
the project team to ensure that metadata remains deployable in all
contexts.

```{important}
Projects that are building an org implementation or a non-namespaced
package do not have a namespace, or a distinction between managed and
unmanaged contexts. These projects typically don't need to use
namespace injection.
```

Metadata files where a namespace is conditionally applied to components
for insertion into different contexts must replace the namespace with a
_token_, which CumulusCI replaces with the appropriate value or with an
empty string as appropriate to the context.

-   `%%%NAMESPACE%%%` is replaced with the package's namespace in any
    context with a namespace (such as a namespaced org or managed org).
    Otherwise, it remains blank.

-   `%%%NAMESPACED_ORG%%%` is replaced with the package's namespace in a namespaced org _only_, not in a managed installation. Otherwise, it remains blank.

```{note}
This token supports use cases where components in one unpackaged
metadata bundle refer to components in another, and the
dependency bundle acquires a namespace by being deployed into a
namespaced org.
```

-   `%%%NAMESPACE_OR_C%%%` is replaced with the package's namespace in
    any context with a namespace (such as a namespaced org or managed
    org). Otherwise, it is replaced with `c`, the generic namespace used
    in Lightning components.

-   `%%%NAMESPACED_ORG_OR_C%%%` is replaced with the package's
    namespace in a namespaced org _only_, not in a managed installation.
    Otherwise, it is replaced with `c`, the generic namespace used in
    Lightning components.

-   `%%%NAMESPACE_DOT%%%` is replaced with the package's namespace in any context with a namespace (such as a namespaced org or managed org) followed by a period (`.`) rather than two underscores.

```{note}
This token is used to construct references to packaged Record
Types and Apex classes.
```

An example case for namespace injection can be found in
Salesforce.org's [Nonprofit Success Pack
(NPSP)](https://github.com/SalesforceFoundation/NPSP) managed package. A
portion of metadata from NPSP is stored in a subdirectory under
`unpackaged/post`, meaning it's deployed after the application
metadata. This metadata updates a Compact Layout on the `Account`
object, and references packaged metadata from the application as well as
from other managed packages. To deploy this as a managed context, this
metadata requires the use of namespace tokens to represent the `npsp`
namespace, letting CumulusCI automatically adapt the metadata to deploy
into managed and unmanaged contexts.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <compactLayouts>
        <fullName>NPSP_Household_Account</fullName>
        <fields>Name</fields>
        <fields>npo02__TotalOppAmount__c</fields>
        <fields>%%%NAMESPACE%%%Number_of_Household_Members__c</fields>
        <label>NPSP Household Account</label>
    </compactLayouts>
</CustomObject>
```

Note that only the reference to the NPSP field
`Number_of_Household_Members__c` is tokenized. (When installed as part
of the managed package, this field appears as
`npsp__Number_of_Household_Members__c`.) References to NPSP's own
managed package dependency, `npo02`, are not tokenized because this
metadata is always namespaced when installed.

If this metadata isn't tokenized, it fails to deploy into an org
containing NPSP as a beta or released managed package (because in that
context the field `Number_of_Household_Members__c` is namespaced as
`npsp__Number_of_Household_Members__c`, and must be referred to as
such).

```{note}
The resolution of component references in namespaced scratch orgs and in
managed installations of the same metadata are not identical. Metadata
that is tokenized and deploys cleanly in a namespaced scratch org can
still fail in a managed context.
```

### Configuration

Most CumulusCI tasks can intelligently determine whether or not to
inject the namespace based on the target org. For example, if tokenized
metadata is being deployed into an org that contains the project
installed as a managed package, CumulusCI knows to inject the namespace;
otherwise, it replaces namespace tokens with an empty string for an
unmanaged installation.

You can also specify explicit configuration for namespace injection in
circumstances where CumulusCI's automatic functionality does not meet
your needs, such as when deploying tokenized metadata from another
project. If the metadata you are deploying has been tokenized, and you
want to deploy metadata with a namespace, use the
`namespace_inject: <namespace>` option to inject the namespace.

```yaml
project:
    dependencies:
        - zip_url: https://github.com/SalesforceFoundation/EDA/archive/master.zip
          subfolder: EDA-master/dev_config/src/admin_config
          namespace_inject: hed
```

The metadata in the zip contains the string tokens `%%%NAMESPACE%%%` and
`___NAMESPACE___` which is replaced with `hed__` before the metadata is
deployed.

To deploy tokenized metadata without any namespace references, specify
both `namespace_inject: <namespace>` and `unmanaged: True`. In this
example, we do just this for the EDA dependency.

```yaml
project:
    dependencies:
        - zip_url: https://github.com/SalesforceFoundation/EDA/archive/master.zip
          subfolder: EDA-master/dev_config/src/admin_config
          namespace_inject: hed
          unmanaged: True
```

The namespace tokens are replaced with an empty string instead of the
namespace, effectively stripping the tokens from the files and
filenames.

## Retrieve Unpackaged Metadata

CumulusCI provides tasks to [retrieve changes](retrieve-changes) to unpackaged metadata, just as with packaged metadata.

When working with unpackaged metadata, it's important to maintain
awareness of key considerations related to retrieving metadata that is
not part of the main application.

-   Take care to separate your development between the different bundles
    you wish to retrieve. For example, if you have changes to make in
    the application as well as in unpackaged metadata, complete the
    application changes first, retrieve them, and then make the
    unpackaged changes and retrieve those. If you conflate changes to
    components that live in separate elements of your project, it's
    difficult to untangle them.
-   Whenever possible, build your unpackaged metadata in an org that
    contains a beta or released managed package. By doing so, the
    metadata contains namespaces when extracted, which CumulusCI easily
    replaces with tokens when retrieving metadata. It's difficult to
    manually tokenize metadata that's retrieved from an unmanaged org
    without namespaces.

After building changes to unpackaged metadata in a managed org, retrieve
it using the `retrieve_changes` task with the additional
`namespace_tokenize` option, and use the `path` option to direct the
retrieved metadata to your desired unpackaged directory.

In the following example, we run the `retrieve_changes` task to retrieve
metadata changes into the `unpackaged/config/qa` subdirectory, and
replace references to the namespace `npsp` with the appropriate token.

```console
$ cci task run retrieve_changes --path unpackaged/config/qa --namespace_tokenize npsp
```

Projects that use unpackaged metadata extensively define retrieve tasks
to streamline this process.

For example, here is a custom task that retrieves changes to specific
directory where metadata for QA configuration is kept.

```yaml
retrieve_qa_config:
    description: Retrieves changes to QA configuration metadata
    class_path: cumulusci.tasks.salesforce.sourcetracking.RetrieveChanges
    options:
        path: unpackaged/config/qa
        namespace_tokenize: $project_config.project__package__namespace
```

The `retrieve_changes` task retrieves unpackaged metadata in a managed
org, but in this case you must manually insert namespace tokens to
deploy metadata in a managed or namespaced context.

## Customize Config Flows

Projects often customize new tasks that deploy `unpackaged/config`
bundles, and harness these tasks in flows.

Projects that use `unpackaged/config/qa` often define a
`deploy_qa_config` task.

```yaml
deploy_qa_config:
    description: Deploys additional fields used for QA purposes only
    class_path: cumulusci.tasks.salesforce.Deploy
    options:
        path: unpackaged/config/qa
```

This task is then added to relevant flows, such as `config_qa`.

```yaml
config_qa:
    steps:
        3:
            task: deploy_qa_config
```

In most cases, CumulusCI intelligently determines whether or not to
inject the namespace. It's rarely necessary to explicitly configure an
injection mode. If you need to do so, use the `unmanaged` option:

```yaml
config_regression:
    steps:
        3:
            task: deploy_qa_config
            options:
                unmanaged: False
```

For more details on customizing tasks and flows, see the
[](config) section.
