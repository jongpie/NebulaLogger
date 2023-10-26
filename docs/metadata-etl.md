# Metadata ETL

## Introduction to Metadata ETL

"ETL" refers to "extract, transform, and load" operations, usually
applied to data. CumulusCI offers a suite of functionality we call
_Metadata ETL_. Metadata ETL makes it easy to define automation that
executes targeted transformations of metadata that already exists in an
org.

Metadata ETL is particularly useful for building automation in projects
that extend other managed packages or that perform complex setup
operations during installations, such as through MetaDeploy. By using
Metadata ETL tasks, projects can often avoid storing and deploying
unpackaged metadata by instead extracting metadata from the target org,
making changes, and then re-deploying. This mode of configuration is
lower-risk and lower-maintenance than storing extensive unpackaged
metadata, which may become out-of-sync, incur accidental feature
dependencies, or entail more destructive deployment operations.

A primary example use case for Metadata ETL is deployment of Standard
Value Sets. Standard Value Sets, which define the picklist values
available on standard fields like `Opportunity.StageName`, are not
packageable, and as such must be part of an application's unpackaged
metadata. They're critical to many applications: a Business Process,
for example, will fail to deploy if the Stage values it includes are not
available. And lastly, they come with a serious danger for deployment
into subscriber orgs: deploying Standard Value Sets is an overwrite
operation, so all existing values in the target org that aren't part of
the deployment are deactivated. This means that it's neither safe nor
maintainable to store static Standard Value Set metadata in a project
and deploy it.

These three facets - non-packageability, application requirements, and
deployment safety -all support a Metadata ETL approach. Rather than
attempting to deploy static metadata stored in the repository, the
product's automation should _extract_ the Standard Value Set metadata
from the org, _transform_ it to include the desired values (as well as
all existing customization), and _load_ the transformed metadata back
into the org. CumulusCI now ships with a task,
`add_standard_value_set_entries`, that makes it easy to do just this:

```yaml
add_standard_value_set_entries:
    options:
        entries:
            - fullName: "New_Value"
              label: "New Value"
              closed: False
        api_names:
            - CaseStatus
```

This task would retrieve the existing `Case.Status` picklist value set
from the org, add the `New_Value` entry to it, and redeploy the modified
metadata - ensuring that the application's needs are met with a safe,
minimal intervention in the target org.

## Standard Metadata ETL Tasks

CumulusCI includes several Metadata ETL tasks in its standard library.
For information about all of the available tasks, see `cci task list`
for tasks in the group Metadata Transformations.

Most Metadata ETL tasks accept the option `api_names`, which specifies
the developer names of the specific metadata components which should be
included in the operation. In most cases, more than one entity may be
transformed in a single operation. Each task performs a single Metadata
API retrieve and a single atomic deployment. Please note, however, that
the extract-transform-load operation as a whole is _not_ atomic; it is
not safe to run Metadata ETL tasks in parallel or to mutate metadata by
other means during the run of a Metadata ETL task.

Consult the Task Reference or use the `cci task info` command for more
information on the usage of each task.

The Metadata ETL framework makes it easy to add more tasks. For
information about implementing Metadata ETL tasks, see TODO: link to
section in Python customization.

## Namespace Injection

All out-of-the-box Metadata ETL tasks accept a Boolean `managed` option.
If `True`, CumulusCI will replace the token `%%%NAMESPACE%%%` in API
names and in values used for transforming metadata with the project's
namespace; if `False`, the token will simply be removed. See [](namespace-injection) for more information.

## Implementation of Metadata ETL Tasks

This section covers internals of the Metadata ETL framework, and is
intended for users who wish to build their own Metadata ETL tasks.

The Metadata ETL framework, and out-of-the-box Metadata ETL tasks, are
part of the `cumulusci.tasks.metadata_etl` package. The
`cumulusci.tasks.metadata_etl.base` module contains all of the base
classes inherited by Metadata ETL classes.

The easiest way to implement a Metadata ETL class that extracts,
transforms, and loads a specific entity, such as `CustomObject` or
`Layout`, is to subclass `MetadataSingleEntityTransformTask`.

This abstract base class has two override points: the class attribute
`entity` should be defined to the Metadata API entity that this class is
intended to transform, and the method
`_transform_entity(self, metadata: MetadataElement, api_name: str)` must
be overridden. This method should make any desired changes to the
supplied `MetadataElement`, and either return a `MetadataElement` for
deployment, or `None` to suppress deployment of this entity. Classes may
also opt to include their own options in `task_options`, but generally
should also incorporate the base class's options, and override
`_init_options()` (`super`'s implementation should also be called to
ensure that supplied API names are processed appropriately).

The `SetDuplicateRuleStatus` class is a simple example of implementing a
`MetadataSingleEntityTransformTask` subclass, presented here with
additional comments:

```python
from typing import Optional

from cumulusci.tasks.metadata_etl import MetadataSingleEntityTransformTask
from cumulusci.utils.xml.metadata_tree import MetadataElement
from cumulusci.core.utils import process_bool_arg


class SetDuplicateRuleStatus(MetadataSingleEntityTransformTask):
    ## Subclasses *must* define `entity`
    entity = "DuplicateRule"

    ## Most subclasses include the base class's options via
    ## **MetadataSingleEntityTransformTask.task_options. Further
    ## options may be added for this specific task. The base class
    ## options include in particular the standard `api_names` option,
    ## which base class functionality requires.
    task_options = {
        "active": {
            "description": "Boolean value, set the Duplicate Rule to either active or inactive",
            "required": True,
        },
        **MetadataSingleEntityTransformTask.task_options,
    }

    ## The `_transform_entity()` method must be overriden.
    def _transform_entity(
        self, metadata: MetadataElement, api_name: str
    ) -> Optional[MetadataElement]:
        ## This method modifies the supplied `MetadataElement`, using methods
        ## from CumulusCI's metadata_tree module, to match the desired configuration.
        status = "true" if process_bool_arg(self.options["active"]) else "false"
        metadata.find("isActive").text = status

        ## Always return the modified `MetadataElement` if deployment is desired.
        ## To not deploy this element, return `None`.
        return metadata
```

### Advanced Metadata ETL Base Classes

Most Metadata ETL tasks subclass `MetadataSingleEntityTransformTask`.
However, the framework also includes classes that provide more
flexibility for complex metadata transformation and synthesis
operations.

The most general base class available is `BaseMetadataETLTask`. Concrete
tasks should rarely subclass `BaseMetadataETLTask`. Doing so requires
you to generate `package.xml` content manually by overriding
`_get_package_xml_content()`, and requires you to override
`_transform()`, which directly accesses retrieved metadata files on disk
in `self.retrieve_dir` and places transformed versions into
`self.deploy_dir`. Subclasses must also set the Boolean class attributes
`deploy` and `retrieve` to define the desired mode of operation.

Tasks which wish to _synthesize_ metadata, without doing a retrieval,
should subclass `BaseMetadataSynthesisTask`. Subclasses must override
`_synthesize()` to generate metadata files in `self.deploy_dir`. The
framework will automatically create a `package.xml` and perform a
deployment.

`BaseMetadataTransformTask` can be used as the base class for ETL tasks
that require more flexibility than is permitted by
`MetadataSingleEntityTransformTask`, such as tasks that must mutate
multiple Metadata API entities in a single operation. Subclasses must
override `_get_entities()` to return a dict mapping Metadata API
entities to collections of API names. (The base class will generate a
corresponding `package.xml`). Subclasses must also implement
`_transform()`, as with `BaseMetadataETLTask`.

`UpdateFirstAttributeTextTask` is a base class and generic concrete task
that makes it easy to perform a specific, common transformation: setting
the value of the first instance of a specific top-level tag in a given
metadata entity. Subclasses (or tasks defined in `cumulusci.yml`) must
define the `entity`, targeted `attribute`, and desired `value` to set.
Example:

```yaml
assign_account_compact_layout:
    description: "Assigns the Fancy Compact Layout as Account's Compact Layout."
    class_path: cumulusci.tasks.metadata_etl.UpdateFirstAttributeTextTask
    options:
        managed: False
        namespace_inject: $project_config.project__package__namespace
        entity: CustomObject
        api_names: Account
        attribute: compactLayoutAssignment
        value: "%%%NAMESPACE%%%Fancy_Account_Compact_Layout"
```
