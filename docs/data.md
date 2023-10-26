# Automate Data Operations

CumulusCI offers a suite of tasks to help you to manage data as part of
your project automation. Within your repository, you can define one or
several _datasets_, collections of data you use for specific purposes.
CumulusCI tasks support extracting defined datasets from scratch orgs or
persistent orgs, storing those snapshots within the repository, and
automating the load of datasets into orgs. Data operations are executed
via the Bulk and REST APIs.

CumulusCI has both high level tasks for working with Sample Datasets
and low-level tasks for generic Extract, Transform and Load of
any data.

## Sample Data

Note: Sample Data features are still under active
development and may change based on user feedback.

CumulusCI has easy to use tasks for working with the primary
sample datasets used for projects. There is a 'default' dataset
which would be used in scratch org configuration flows, as well
as other datasets specific to the needs of specific scratch org configurations.

For example, the 'dev' dataset is for 'dev' orgs, and it is used
instead of the default dataset if it exists.

You can create a dataset by extracting data from an existing org
or by authoring a [Snowfakery recipe](Generate-Fake-Data).
Extracting from an existing org is easy for use-cases where the
data already exists or can be readily created in an org. Snowfakery
is better for cases where either a) you would like to dynamically
generate data, or b) you would rather edit static data in a text
editor.

A Snowfakery dataset can consist of a single file with a name like
`datasets/<datasetname>/<datasetname>.recipe.yml` . For example,
`datasets/default/default.recipe.yml` or
`datasets/qa/qa.recipe.yml`. The rest of what you need to know
about Snowfakery is in the section [Generate Fake Data](Generate-Fake-Data).

### Extracting and Loading Sample Datasets

In the simplest case, you can extract all data from an org
using the task `capture_sample_data` like this:

```s
$ cci task run capture_sample_data --org orgname
```

That will extract the data from the Salesforce
org named `orgname` into the dataset named `default`.

You can then load it into any target org (e.g.
`org2`) like this:

```s
$ cci task run load_sample_data --org org2
```

A main benefit of sample datasets is that they are always
loaded automatically into scratch orgs by the scratch org
setup flows like `dev_org` and `qa_org`.

The exact subset of data captured depends on heuristics
that may change over time, so do not depend on this task
in a highly automated situation. It is designed to be
used interactively, and you can control its behavior
with an [Extract Declaration](data/extract_declarations.md) file.

The extract process generates a mapping YAML file which will be used for subsequent
loads. It has the name `datasets/<datasetname>/<datasetname>.mapping.yml`.
It is possible to edit this file, but this may not be the best choice.
Changes to the file can be overwritten when you capture data a second time.
Rather than editing the file, it is preferable to create a Loading Rules
file and then re-create the mapping file by capturing sample data again.

A Loading Rules file is a file named
`datasets/<datasetname>/<datasetname>.load.yml` which can specify instructions
like which API to use and in which order to load objects. This file is in
the [Loading Rules](data/loading_rules.md) format. If you create such a file
and then re-capture sample data, the mapping file will be updated to match.

### Multiple Sample Datasets

If you want different datasets for different scratch org types
(e.g. QA orgs verus Dev orgs) then you can change the data
loaded by those types by making datasets specific to each one.
This data will load instead of the default dataset.

```s
$ cci task run capture_sample_data --dataset dev --org org1
```

```s
$ cci task run capture_sample_data --dataset qa --org org2
```

This would create two datasets in `datasets/dev` and `datasets/qa`
which would be loaded instead of `datasets/default`. You can
create as many datasets as you want.

You can download just a subset of the objects or fields in an org with
an [Extract Declaration](data/extract_declarations.md) file.

## Low level datasets

A dataset consists of:

-   a _definition file_, written in YAML, which specifies the sObjects
    and fields contained in the dataset and the order in which they are
    loaded or extracted from an org.
-   a _storage location_, which may take the form of a SQL database
    (typically, a SQLite file stored within the repository, although
    external databases are supported) or a SQL script file.

Datasets are stored in the `datasets/` folder within a repository by
default. Projects created with a recent version of CumulusCI ship with
this directory in place.

If `load_dataset` is called without any path options, it will automatically use a dataset that matches the org shape, if one exists. For example, a `dev` org will automatically use a dataset that exists at `datasets/dev/`. Within that folder, two files must exist, also matching the org shape name: `dev.mapping.yml` and `dev.dataset.sql`, in this example. If the directory or files do not exist and no paths options were specified, the task will look for `datasets/mapping.yml` and `datasets/dataset.sql` by default. When the `default_dataset_only` option is `True`, this overrides any path options and default files and looks _only_ for a dataset directory that matches the org shape name. The `default_dataset_only` option defaults to `False`.

In addition, `load_dataset` is included in `config_dev`, `config_qa`, and `config_managed`, so it is automatically called when running most org setup flows. In this context, it runs with `default_dataset_only` set to `True`, to avoid double loading for backwards compatibility with customer flows that are already customized to call `load_dataset`.

## The Lifecycle of a Dataset

A dataset starts with a definition: which objects, and which fields, are
to be captured, persisted, and loaded into orgs? (The details of
definition file format are covered below).

With a definition available, the dataset may be captured from an org
into the repository. A captured dataset may be stored under version
control and incorporated into project automation, loaded as part of
flows during org builds or at need. As the project's needs evolve,
datasets may be re-captured from orgs and versioned alongside the
project metadata.

Projects may define one or many datasets. Datasets can contain an
arbitrary amount of data.

## Defining Datasets

A dataset is defined in YAML as a series of steps. Each step registers a
specific sObject as part of the dataset, and defines the relevant fields
on that sObject as well as its relationships to other sObjects that are
included in the data set.

```{note}
This section discusses how to define a dataset and the format of
the definition file. In many cases, it's easier to use the
`generate_dataset_mapping` task than to create this definition by
hand. See below for more details.
```

A simple dataset definition looks like this:

```yaml
Accounts:
    sf_object: Account
    fields:
        - Name
        - Description
        - RecordTypeId
    lookups:
        ParentId:
            table: Account
            after: Accounts
Contacts:
    sf_object: Contact
    fields:
        - FirstName
        - LastName
        - Email
    lookups:
        AccountId:
            table: Account
```

This example defines two steps: `Accounts` and `Contacts`. (The names of
steps are arbitrary). Each step governs the extraction or load of
records in the sObject denoted in its `sf_object` property.

Relationships are defined in the `lookups` section. Each key within
`lookups` is the API name of the relationship field. Beneath, the
`table` key defines the stored table to which this relationship refers.

CumulusCI loads steps in order. However, sObjects earlier in the
sequence of steps may include lookups to sObjects loaded later, or to
themselves. For these cases, the `after` key may be included in a lookup
definition, with a value set to the name of the step after which the
referenced record is expected to be available. CumulusCI will defer
populating the lookup field until the referenced step has been
completed. In the example above, an `after` definition is used to
support the `ParentId` self-lookup on `Account`.

(api-selection)=

### API Selection

By default, CumulusCI will determine the data volume of the specified
object and select an API for you: for under 2,000 records, the REST
Collections API is used; for more, the Bulk API is used. The Bulk API is
also used for delete operations where the hard delete operation is
requested, as this is available only in the Bulk API. Smart API
selection helps increase speed for low- and moderate-volume data loads.

To prefer a specific API, set the `api` key within any mapping step;
allowed values are `"rest"`, `"bulk"`, and `"smart"`, the default.

CumulusCI defaults to using the Bulk API in Parallel mode. If required
to avoid row locks, specify the key `bulk_mode: Serial` in each step
requiring the use of serial mode.

For all API modes, you can specify a batch size using the `batch_size`
key. Allowed values are between 1 and 200 for the REST API and 1 and
10,000 for the Bulk API.

Note that the semantics of batch sizes differ somewhat between the REST
API and the Bulk API. In the REST API, the batch size is the size of
upload batches and also the actual size of individual transactions. In
the Bulk API, the batch size is the maximum record count in a Bulk API
upload batch, which is subject to its own limits, including restrictions
on total processing time. Bulk API batches are automatically chunked
further into transactions by the platform, and the transaction size
cannot be controlled.

### Upserts

The definition of "upsert" is an operation which creates new records
and updates existing records depending on a field (the update key) which
determines whether the input row and the existing row are "the same".

You can do ID-based,
[idLookup-based](https://developer.salesforce.com/docs/atlas.en-us.204.0.object_reference.meta/object_reference/access_for_fields.htm##access_lookup)
and [external
ID](https://help.salesforce.com/s/articleView?id=sf.faq_import_general_what_is_an_external.htm&type=5)-based
[upserts](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_dml_examples_upsert.htm)
and updates by specifying additional settings in a mapping step.

```yaml
Insert Accounts:
    sf_object: Account
    action: upsert
    update_key: Extid__c
    fields:
        - Name
        - Extid__c
```

Whenever `update_key` is supplied, the action must be `upsert` and vice
versa.

### Database Mapping

CumulusCI's definition format includes considerable flexibility for use
cases where datasets are stored in SQL databases whose structure is not
identical to the Salesforce database. Salesforce objects may be assigned
to arbitrary database tables, and Salesforce field names mapped to
arbitrary columns.

For new mappings, it's recommended to allow CumulusCI to use sensible
defaults by specifying only the Salesforce entities. Legacy datasets are
likely to include explicit database mappings, which would look like this
for the same data model as above:

```yaml
Accounts:
    sf_object: Account
    table: Account
    fields:
        Name: Name
        Description: Description
        RecordTypeId: RecordTypeId
    lookups:
        ParentId:
            table: Account
            after: Accounts
Contacts:
    sf_object: Contact
    table: Contact
    fields:
        FirstName: FirstName
        LastName: LastName
        Email: Email
    lookups:
        AccountId:
            table: Account
```

Note that in this version, fields are specified as a colon-separated
mapping, not a list. Each pair in the field map is structured as
`Salesforce API Name: Database Column Name`. Additionally, each object
has a `table` key to specify the underlying database table.

New mappings that do not connect to an external SQL database (that is,
mappings which simply extract and load data between Salesforce orgs)
should not need to use this feature, and new mappings that are generated
by CumulusCI use the simpler version shown above. Existing mappings may
be converted to this streamlined style in most cases by loading the
existing dataset, modifying the mapping file, and then extracting a
fresh copy of the data. Note however that datasets which make use of
older and deprecated CumulusCI features, such as the `record_type` key,
may need to continue using explicit database mapping.

### Record Types

CumulusCI supports automatic mapping of Record Types between orgs, keyed
upon the Developer Name. To take advantage of this support, simply
include the `RecordTypeId` field in any step. CumulusCI will
transparently extract Record Type information during dataset capture and
map Record Types by Developer Name into target orgs during loads.

Older dataset definitions may also use a `record_type` key:

```yaml
Accounts:
    sf_object: Account
    fields:
        - Name
    record_type: Organization
```

This feature limits extraction to records possessing that specific
Record Type, and assigns the same Record Type upon load.

It's recommended that new datasets use Record Type mapping by including
the `RecordTypeId` field. Using `record_type` will result in CumulusCI
issuing a warning.

### Relative Dates

CumulusCI supports maintaining _relative dates_, helping to keep the
dataset relevant by ensuring that date and date-time fields are updated
when loaded.

Relative dates are enabled by defining an _anchor date_, which is
specified in each mapping step with the `anchor_date` key, whose value
is a date in the format `2020-07-01`.

When you specify a relative date, CumulusCI modifies all date and
date-time fields on the object such that when loaded, they have the same
relationship to today as they did to the anchor date. Hence, given a
stored date of 2020-07-10 and an anchor date of 2020-07-01, if you
perform a load on 2020-09-10, the date field will be rendered as
2020-09-19 -nine days ahead of today's date, as it was nine days ahead
of the anchor date.

Relative dates are also adjusted upon extract so that they remain
stable. Extracting the same data mentioned above would result in
CumulusCI adjusting the date back to 2020-07-10 for storage, keeping it
relative to the anchor date.

Relative dating is applied to all date and date-time fields on any
mapping step that contains the `anchor_date` clause. If orgs are
[configured](https://help.salesforce.com/articleView?id=000334139&language=en_US&type=1&mode=1)
to permit setting audit fields upon record creation and the appropriate
user permission is enabled, CumulusCI can apply relative dating to audit
fields, such as `CreatedDate`. For more about how to automate that
setup, review the `create_bulk_data_permission_set` task below.

For example, this mapping step:

```yaml
Contacts:
    sf_object: Contact
    fields:
        - FirstName
        - LastName
        - Birthdate
    anchor_date: 1990-07-01
```

would adjust the `Birthdate` field on both load and extract around the
anchor date of July 1, 1990. Note that date and datetime fields not
mapped, as well as fields on other steps, are unaffected.

### Person Accounts

CumulusCI supports extracting and loading person account data. In your
dataset definition, map person account fields like `LastName`,
`PersonBirthdate`, or `CustomContactField__pc` to **Account** steps
(i.e. where `sf_object` equals **Account**).

```yaml
Account:
    sf_object: Account
    table: Account
    fields:
        ## Business Account Fields
        - Name
        - AccountNumber
        - BillingStreet
        - BillingCity

        ## Person Account Fields
        - FirstName
        - LastName
        - PersonEmail
        - CustomContactField__pc

        ## Optional (though recommended) Record Type
        - RecordTypeId
```

#### Record Types

It's recommended, though not required, to extract Account Record Types
to support datasets with person accounts so there is consistency in the
Account record types loaded. If Account `RecordTypeId` is not extracted,
the default business account Record Type and default person account
Record Type will be applied to business and person account records
respectively.

#### Extract

During dataset extraction, if the org has person accounts enabled, the
`IsPersonAccount` field is extracted for **Account** and **Contact**
records so CumulusCI can properly load these records later.
Additionally, `Account.Name` is not createable for person account
**Account** records, so `Account.Name` is not extracted for person
account **Account** records.

#### Load

Before loading, CumulusCI checks if the dataset contains any person
account records (i.e. any **Account** or **Contact** records with
`IsPersonAccount` as `true`). If the dataset does contain any person
account records, CumulusCI validates the org has person accounts
enabled.

You can enable person accounts for scratch orgs by including the
[PersonAccounts](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_scratch-orgs_def_file_config_values.htm##so_personaccounts/)
feature in your scratch org definition.

### Advanced Features

CumulusCI supports two additional keys within each step

The `filters` key encompasses filters applied to the SQL data store when
loading data. Use of `filters` can support use cases where only a subset
of stored data should be loaded. :

```yaml
filters:
    - "SQL string"
```

Note that `filters` uses SQL syntax, not SOQL. Filters do not perform
filtration or data subsetting upon extraction; they only impact loading.
This is an advanced feature.

The `static` key allows individual fields to be populated with a fixed,
static value:

```yaml
static:
    CustomCheckbox__c: True
    CustomDateField__c: 2019-01-01
```

The `soql_filter` key lets you specify a WHERE clause that should be
used when extracting data from your Salesforce org:

```yaml
Account:
    sf_object: Account
    table: Account
    fields:
        - Name
        - Industry
        - Type
    soql_filter: "Industry = 'Higher Education' OR Type = 'Higher Education'"
```

Note that trying to load data that is extracted using `soql_filter` may
cause "invalid cross reference id" errors if related object records
are filtered on extract. Use this feature only if you fully understand
how [CumulusCI load data task](data-load-dataset)
resolves references to related records when loading data to a Salesforce
org.

#### Primary Keys

CumulusCI offers two modes of managing Salesforce Ids and primary keys
within the stored database.

If the `fields` list for an sObject contains a mapping:

```yaml
Id: sf_id
```

CumulusCI will extract the Salesforce Id for each record and use that Id
as the primary key in the stored database.

If no such mapping is provided, CumulusCI will remove the Salesforce Id
from extracted data and replace it with an autoincrementing integer
primary key.

Use of integer primary keys may help yield more readable text diffs when
storing data in SQL script format. However, it comes at some performance
penalty when extracting data. It's recommended that most mappings do
not map the Id field and allow CumulusCI to utilize the automatic
primary key.

#### Handling Namespaces

All CumulusCI bulk data tasks support automatic namespace injection or
removal. In other words, the same mapping file will work for namespaced
and unnamespaced orgs, as well as orgs with the package installed
managed or unmanaged. If a mapping element has no namespace prefix and
adding the project's namespace prefix is required to match a name in
the org, CumulusCI will add one. Similarly, if removing a namespace is
necessary, CumulusCI will do so.

In the extremely rare circumstance that an org contains the same mapped
schema element in both namespaced and non-namespaced form, CumulusCI
does not perform namespace injection or removal for that element.

Namespace injection can be deactivated by setting the
`inject_namespaces` option to `False`.

The `generate_dataset_mapping` generates mapping files with no namespace
and this is the most common pattern in CumulusCI projects.

#### Namespace Handing with Multiple Mapping Files

It's also possible, and common in older managed package products, to
use multiple mapping files to achieve loading the same data set in both
namespaced and non-namespaced contexts. This is no longer recommended
practice.

A mapping file that is converted to use explicit namespacing might look
like this:

Original version:

```yaml
Destinations:
    sf_object: Destination__c
    fields:
        Name: Name
        Target__c: Target__c
    lookups:
        Supplier__c:
            table: Supplier__c
```

Namespaced version:

```yaml
Destinations:
    sf_object: MyNS__Destination__c
    table: Destination__c
    fields:
        MyNS__Name: Name
        MyNS__Target__c: Target__c
    lookups:
        MyNS__Supplier__c:
            key_field: Supplier__c
            table: Supplier__c
```

Note that each of the definition elements that refer to _local_ storage
remains un-namespaced, while those elements referring to the Salesforce
schema acquire the namespace prefix.

For each lookup, an additional `key_field` declaration is required,
whose value is the original storage location in local storage for that
field's data. In most cases, this is simply the version of the field
name in the original definition file.

Adapting an originally-namespaced definition to load into a
non-namespaced org follows the same pattern, but in reverse.

Note that mappings which use the flat list style of field specification
must use mapping style to convert between namespaced and non-namespaced
deployment.

It's recommended that all new mappings use flat list field
specifications and allow CumulusCI to manage namespace injection. This
capability typically results in significant simplication in automation.

#### Optional Data Elements

Some projects need to build datasets that include optional data
elements - fields and objects that are loaded into some of the
project's orgs, but not others. This can cover both optional managed
packages and features that are included in some, but not all, orgs. For
example, a managed package A that does not require another managed
package B but is designed to work with it may wish to include data for
managed package B in its data sets, but load that data if and only if B
is installed. Likewise, a package might wish to include data supporting
a particular org feature, but not load that data in an org where the
feature is turned off (and its associated fields and objects are for
that reason unavailable).

To support this use case, the `load_dataset` and `extract_dataset` tasks
offer a `drop_missing_schema` option. When enabled, this option results
in CumulusCI ignoring any mapped fields, sObjects, or lookups that
correspond to schema that is not present in the org.

Projects that require this type of conditional behavior can build their
datasets in an org that contains managed package B, capture it, and then
load it safely in orgs that both do and do not contain B. However, it's
important to always capture from an org with B present, or B data will
not be preserved in the dataset.

## Custom Settings

Datasets don't support Custom Settings. However, a separate task is
supplied to deploy Custom Settings (both list and hierarchy) into an
org: [](load-custom-settings). The data for this task is defined in a YAML
text file

Each top-level YAML key should be the API name of a Custom Setting. List
Custom Settings should contain a nested map of names to values.
Hierarchy Custom settings should contain a list, each of which contains
a `data` key and a `location` key. The
`location` key may contain either `profile: <profile name>`, `user: name: <username>`,
`user: email: <email>`, or `org`.

Example:

```yaml
List__c:
    Test:
        MyField__c: 1
    Test 2:
        MyField__c: 2
Hierarchy__c:
    - location: org
      data:
          MyField__c: 1
    - location:
          user:
              name: test@example.com
      data:
          MyField__c: 2
```

CumulusCI will automatically resolve the `location` specified for
Hierarchy Custom Settings to a `SetupOwnerId`. Any Custom Settings
existing in the target org with the specified name (List) or setup owner
(Hierarchy) will be updated with the given data.

## Dataset Tasks

### `create_bulk_data_permission_set`

Create and assign a Permission Set that enables key features used in
Bulk Data tasks (Hard Delete and Set Audit Fields) for the current user.
The Permission Set will be called `CumulusCI Bulk Data`.

Note that prior to running this task you must ensure that your org is
configured to allow the use of Set Audit Fields. You can do so by
manually updating the required setting in the User Interface section of
Saleforce Setup, or by updating your scratch org configuration to
include :

```json
"securitySettings": {
    "enableAuditFieldsInactiveOwner": true
}
```

For more information about the Set Audit Fields feature, review [this
Knowledge
article](https://help.salesforce.com/articleView?id=000213290&type=1).

After this task runs, you'll be able to run the `delete_data` task with
the `hardDelete` option, and you'll be able to map audit fields like
`CreatedDate`.

### `extract_dataset`

Extract the data for a dataset from an org and persist it to disk.

#### Options

-   `mapping`: the path to the YAML definition file for this dataset.
-   `sql_path`: the path to a SQL script storage location for this
    dataset.
-   `database_url`: the URL for the database storage location for this
    dataset.

`mapping` and either `sql_path` or `database_url` must be supplied.

Example: :

    cci task run extract_dataset -o mapping datasets/qa/mapping.yml -o sql_path datasets/qa/data.sql --org qa

### <a name="data-load-dataset"></a> `load_dataset`

Load the data for a dataset into an org. If the storage is a database,
persist new Salesforce Ids to storage.

#### Options

-   `mapping`: the path to the YAML definition file for this dataset.
-   `sql_path`: the path to a SQL script storage location for this
    dataset.
-   `database_url`: the URL for the database storage location for this
    dataset.
-   `start_step`: the name of the step to start the load with (skipping
    all prior steps).
-   `ignore_row_errors`: If True, allow the load to continue even if
    individual rows fail to load. By default, the load stops if any
    errors occur.

`mapping` and either `sql_path` or `database_url` must be supplied.

Example: :

    cci task run load_dataset -o mapping datasets/qa/mapping.yml -o sql_path datasets/qa/data.sql --org qa

### `generate_dataset_mapping`

Inspect an org and generate a dataset definition for the schema found
there.

This task is intended to streamline the process of creating a dataset
definition. To use it, first build an org (scratch or persistent)
containing all of the schema needed for the dataset.

Then, execute `generate_dataset_mapping`. The task inspects the target
org and creates a dataset definition encompassing the project's schema,
attempting to be minimal in its inclusion outside that schema.
Specifically, the definition will include:

-   Any custom object without a namespace
-   Any custom object with the project's namespace
-   Any object with a custom field matching the same namespace criteria
-   Any object that's the target of a master-detail relationship, or a
    custom lookup relationship, from another included object.

On those sObjects, the definition will include

-   Any custom field (including those defined by other packages)
-   Any required field
-   Any relationship field targeting another included object
-   The `Id`, `FirstName`, `LastName`, and `Name` fields, if present

Certain fields will always be omitted, including

-   Lookups to the User object
-   Binary-blob (base64) fields
-   Compound fields
-   Non-createable fields

The resulting definition file is intended to be a viable starting point
for a project's dataset. However, some additional editing is typically
required to ensure the definition fully suits the project's use case.
In particular, any fields required on standard objects that aren't
automatically included must be added manually.

#### Reference Cycles

Dataset definition files must execute in a sequence, one sObject after
another. However, Salesforce schemas often include _reference cycles_:
situations in which Object A refers to Object B, which also refers to
Object A, or in which Object A refers to itself.

CumulusCI will detect these reference cycles during mapping generation
and ask the user for assistance resolving them into a linear sequence of
load and extract operations. In most cases, selecting the schema's most
core object (often a standard object like Account) will successfully
resolve reference cycles. CumulusCI will automatically tag affected
relationship fields with `after` directives to ensure they're populated
after their target records become available.

#### Options

-   `path`: Location to write the mapping file. Default:
    datasets/mapping.yml
-   `ignore`: Object API names, or fields in Object.Field format, to
    ignore
-   `namespace_prefix`: The namespace prefix to treat as belonging to
    the project, if any

Example: :

    cci task run generate_dataset_mapping --org qa -o namespace_prefix my_ns

### `load_custom_settings`

Load custom settings stored in YAML into an org.

#### Options

-   `settings_path`: Location of the YAML settings file.

### `delete_data`

You can also delete records using CumulusCI. You can either delete every
record of a particular object, certain records based on a `where` clause
or every record of multiple objects. Because `where` clauses seldom make
logical sense when applied to multiple objects, you cannot use a `where`
clause when specifying multiple objects.

Details are available with `cci org info delete_data` and [in the task reference] (delete-data).

#### Examples

```
cci task run delete_data -o objects Opportunity,Contact,Account --org qa

cci task run delete_data -o objects Opportunity -o where "StageName = 'Active' "

cci task run delete_data -o objects Account -o ignore_row_errors True

cci task run delete_data -o objects Account -o hardDelete True
```

### `update_data`

To update records using CumulusCI, provide:

-   a command line or task configuration describing what to update
-   a recipe in a subset of Snowfakery syntax that says how to update it

On the command line, you can run an update like this:

`$ cci task run update_data --recipe datasets/update.recipe.yml --object Account`

This command downloads every Account in the org and applies the fields
from the specified update recipe file.

You can filter the rows that you're updating like this:

`$ cci task run update_data --recipe datasets/update.recipe.yml --object Account --where "name like 'AAA%'"`

The recipe for an update can be as simple as this:

```yaml
object: Account
fields:
    NumberOfEmployees: 10000
```

You can use all of the power of `snowfakery` to add fake data:

```yaml
object: Account
fields:
    NumberOfEmployees: 10_000
    BillingStreet:
        fake: Streetname
```

Using Snowfakery formulas, you can also refer to specific input fields
like this:

```yaml
object: Account
fields:
    Description: ${{input.Name}} is our favorite customer in ${{input.BillingCity}}
```

To tell CumulusCI to extract those fields and make them use the `fields`
option:

`$ cci task run update_data --recipe datasets/update.recipe.yml --object Account --Fields Name,BillingCity`

You can learn more about Snowfakery syntax in the next section.

## Generate Fake Data

It is possible to use CumulusCI to generate arbitrary amounts of
synthetic data using the `snowfakery`
[task](https://cumulusci.readthedocs.io/en/latest/tasks.html#snowfakery).
That task is built on the [Snowfakery
language](https://snowfakery.readthedocs.io/en/docs/). CumulusCI ships
with Snowfakery embedded, so you do not need to install it.

To start, you will need a Snowfakery recipe. You can learn about writing
them in the [Snowfakery
docs](https://snowfakery.readthedocs.io/en/docs/).

Once you have it, you can fill an org with data like this:

`$ cci task run snowfakery --recipe datasets/some_snowfakery_recipe.yml`

If you would like to execute the recipe multiple times to generate more
data, you do so like this:

`$ cci task run generate_and_load_from_yaml --run-until-recipe-repeated 400`

Which will repeat the recipe 400 times.

There are two other ways to control how many times the recipe is
repeated: `--run-until-records-loaded` and
`--run-until-records-in-org`.

### Generated Record Counts

Consider this example:

`$ cci task run snowfakery --run-until-records-loaded 1000:Account`

This would say to run the recipe until the task has loaded 1000 new
Accounts. In the process, it might also load Contacts, Opportunities,
custom objects oor whatever else is in the recipe. But it finishes when
it has loaded 400 Accounts.

The counting works like this:

-   Snowfakery always executes a _complete_ recipe. It never stops
    halfway through. If your recipe creates more records than you
    need, you might overshoot. Usually the amount of overshoot is just
    a few records, but it depends on the details of your recipe.
-   At the end of executing a recipe, it checks whether it has created
    enough of the object type mentioned by the
    `--run-until-records-loaded` parameter.
-   If so, it finishes. If not, it runs the recipe again.

So if your recipe creates 10 Accounts, 5 Contacts and 15 Opportunities,
then when you run the command above it will run the recipe 100 times
(100\*10=1000) which will generate 1000 Accounts, 500 Contacts and 1500
Opportunities.

`--run-until-records-in-org`} works similarly, but it
determines how many times to run the recipe based on how many records
are in the org at the start. For example, if the org already has 300
Accounts in it then:

`$ cci task run snowfakery --run-until-records-in-org 1000:Account`

Would be equivalent to `--run-until-records-loaded 700:Account` because one needs to add 700 Accounts to the
300 resdent ones to get to 1000.

### Controlling the Loading Process

CumulusCI's data loader has many knobs and switches that you might want
to adjust during your load. It supports a
[".load.yml"](data/loading_rules.md) file format
which allows you to manipulate these load settings. The simplest way to
use this file format is to make a file in the same directory as your
recipe with a filename that is derived from the recipe's by replacing
everything after the first "." with ".load.yml". For example, if
your recipe is called "babka.recipe.yml" then your load file would be
"babka.load.yml".

### Batch Sizes

You can also control batch sizes with the `-o batch_size BATCHSIZE`
parameter. This is not the Salesforce bulk API batch size. No matter
what batch size you select, CumulusCI will properly split your data into
batches for the bulk API.

You need to understand the loading process to understand why you might
want to set the `batch_size`.

If you haven't set the `batch_size` then Snowfakery generates all of
the records for your load job at once.

So the first reason why you might want to set the batch_size is because
you don't have enough local disk space for the number of records you
are generating (across all tables).

This isn't usually a problem though.

The more common problem arises from the fact that Salesforce bulk
uploads are always done in batches of records a particular SObject. So
in the case above, it would upload 1000 Accounts, then 500 Contacts,
then 1500 Opportunities. (remember that our scenario involves a recipe
that generates 10 Accounts, 5 Contacts and 15 Opportunities).

Imagine if the numbers were more like 1M, 500K and 1.5M. And further,
imagine if your network crashed after 1M Accounts and 499K Contacts were
uploaded. You would not have a single "complete set" of 10/5/15.
Instead you would have 1M "partial sets".

If, by contrast, you had set your batch size to 100*000, your network
might die more around the 250,000 Account mark, but you would have
200,000/20[^1] =10K \_complete sets* plus some "extra" Accounts which
you might ignore or delete. You can restart your load with a smaller
goal (800K Accounts) and finish the job.

Another reason you might choose smaller batch sizes is to minimize the
risk of row locking errors when you have triggers enabled. Turning off
triggers is generally preferable, and CumulusCI [has a
task](https://cumulusci.readthedocs.io/en/latest/tasks.html#disable-tdtm-trigger-handlers)
for doing for TDTM trigger handlers, but sometimes you cannot avoid
them. Using smaller batch sizes may be preferable to switching to serial
mode. If every SObject in a batch uploads less than 10,000 rows then you
are defacto in serial mode (because only one "bulk mode batch" at a
time is being processed).

In general, bigger batch sizes achieve higher throughput. No batching at
all is the fastest.

Smaller batch sizes reduce the risk of something going wrong. You may
need to experiment to find the best batch size for your use case.

[^1]: remember that our sets have 20 Accounts each
