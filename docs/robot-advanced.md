# Robot Advanced Topics

In the previous section we gave a broad overview of how Robot Framework
is integrated with CumulsCI. In this section we'll take a deeper dive
into some advanced topics.

## Running CumulusCI Tasks

CumulusCI provides two keywords for running a task from within a robot
test case: [Run Task](https://cumulusci.readthedocs.io/en/stable/Keywords.html#CumulusCI.Run-Task) and [Run Task
Class](https://cumulusci.readthedocs.io/en/stable/Keywords.html#CumulusCI.Run-Task-Class).

[Run Task](https://cumulusci.readthedocs.io/en/stable/Keywords.html#CumulusCI.Run-Task) can be used to run any
CumulusCI tasks configured for the project. Tasks run can be any of
CumulusCI's standard tasks as well as project-specific custom tasks
from the project's `cumulusci.yml` file. `Run Task` accepts a single
argument, the task name, along with any arguments required by the task.

[Run Task Class](https://cumulusci.readthedocs.io/en/stable/Keywords.html#CumulusCI.Run-Task-Class) works in a
similar fashion, but the task can be specified as a python class rather
than a task name. For example, you can use this keyword to run logic
from CumulusCI tasks which have not been configured in the project's
cumulusci.yml file. This is most useful in cases where a test needs to
use task logic for logic unique to the test and thus not worth making
into a named task for the project.

## Performance Testing

The Salesforce keyword library somes with several keywords to aid in
performance testing.

### Setting the elapsed time

Normally, the full execution time of a test is recorded in the robot
framework log. This includes the time spent in both test setup and
teardown. Sometimes it is preferable to report only the time spent in
the test case itself.

The [Set Test Elapsed
Time](https://cumulusci.readthedocs.io/en/stable/Keywords.html#Salesforce.Set-Test-Elapsed-Time) keyword
allows you to record a computed elapsed time. For example, when
performance testing a Salesforce batch process, you have the option to
store the Salesforce-measured elapsed time of the batch process instead
of the time measured in the CumulusCI client process.

The [Set Test Elapsed
Time](https://cumulusci.readthedocs.io/en/stable/Keywords.html#Salesforce.Set-Test-Elapsed-Time) keyword
takes a single optional argument, either a number of seconds or a [Robot
time
string](https://robotframework.org/robotframework/latest/libraries/DateTime.html#Time%20formats).

When using this keyword, the tag `cci_metric_elapsed_time` will
automatically be added to the test case.

When the test is run via MetaCI, the computed time will be retrieve and
stored inside MetaCI instead of the total elapsed time as measured by
Robot Framework.

### Start and End Performance Time

A time can be recorded for any group of keywords by calling Start
Performance Timer and Stop Performance Timer. The latter will
automatically call the [Set Test Elapsed
Time](https://cumulusci.readthedocs.io/en/stable/Keywords.html#Salesforce.Set-Test-Elapsed-Time) keyword.

The [Start Performance
Timer](https://cumulusci.readthedocs.io/en/stable/Keywords.html#Salesforce.Start-Performance-Timer) keyword
starts a timer. The [Stop Performance
Timer](https://cumulusci.readthedocs.io/en/stable/Keywords.html#Salesforce.Stop-Performance-Timer) keyword
stops the timer and stores the result with [Set Test Elapsed
Time](https://cumulusci.readthedocs.io/en/stable/Keywords.html#Set-Test-Elapsed-Time).

### Setting Test Metrics

The [Set Test Metric](https://cumulusci.readthedocs.io/en/stable/Keywords.html#Salesforce.Set-Test-Metric)
keyword retrieves any metric for performance monitoring, such as number
of queries, rows processed, CPU usage, and more.

The keyword takes a metric name, which can be any string, and a value,
which can be any number.

Using this keyword will automatically add the tag `cci_metric` to the
test case and `${cci_metric_<metric_name>}` to the test's variables.
These permit downstream processing in tools like CCI and MetaCI.

Note: `cci_metric` is not included in Robot's html statistical
roll-ups.

```robot
Set Test Metric    Max_CPU_Percent    30
```

Performance test metrics are output in the CCI logs, log.html and
output.xml. MetaCI captures them but does not currently have a user
interface for displaying them.

### Elapsed Time for Last Record

The [Elapsed Time For Last
Record](https://cumulusci.readthedocs.io/en/stable/Keywords.html#Salesforce.Elapsed-Time-For-Last-Record)
keyword queries Salesforce for its recorded log of a job.

For example, to query an Apex bulk job:

```robot
${time_in_seconds} =    Elapsed Time For Last Record
...             obj_name=AsyncApexJob
...             where=ApexClass.Name='BlahBlah'
...             start_field=CreatedDate
...             end_field=CompletedDate
...             order_by=CompletedDate
```

## Browser Testing

Testing salesforce from within a browser presents some unique
challenges. This section covers some Salesforce-specific features of our
keyword libraries.

### Waiting for Lightning UI

A common challenge when writing end-to-end UI tests is waiting for
asynchronous actions to complete before proceeding to run the next
interaction. The Salesforce Library is aware of the Lightning UI and can
handle waiting automatically. After each click, the Salesforce Library
waits for any pending requests to the server to complete. (Manually
waiting using "sleep", or waiting for a particular element to appear,
can still be necessary after specific interactions, and when interacting
with pages that don't use the Lightning UI.)

## API Keywords

In addition to browser interactions, the Salesforce Library also
provides keywords for interacting with the Salesforce REST API. Here are
the keywords we provide which talk directly to Salesforce via an API
rather than through the UI:

-   [Salesforce Collection
    Insert](https://cumulusci.readthedocs.io/en/stable/Keywords.html#Salesforce.Salesforce-Collection-Insert):
    Creates a collection of objects based on a template.
-   [Salesforce Collection
    Update](https://cumulusci.readthedocs.io/en/stable/Keywords.html#Salesforce.Salesforce-Collection-Update):
    Updates a collection of objects.
-   [Salesforce Delete](https://cumulusci.readthedocs.io/en/stable/Keywords.html#Salesforce.Salesforce-Delete):
    Deletes a record using its type and ID.
-   [Salesforce Get](https://cumulusci.readthedocs.io/en/stable/Keywords.html#Salesforce.Salesforce-Get): Gets a
    dictionary of a record from its ID.
-   [Salesforce Insert](https://cumulusci.readthedocs.io/en/stable/Keywords.html#Salesforce.Salesforce-Insert):
    Inserts a record using its type and field values. Returns the ID.
-   [Salesforce Query](https://cumulusci.readthedocs.io/en/stable/Keywords.html#Salesforce.Salesforce-Query):
    Runs a simple query using the `object type` and `<field_name=value>`
    syntax. Returns a list of matching record dictionaries.
-   [Salesforce Update](https://cumulusci.readthedocs.io/en/stable/Keywords.html#Salesforce.Salesforce-Update):
    Updates a record using its type, ID, and `<field_name=value>`
    syntax.
-   [SOQL Query](https://cumulusci.readthedocs.io/en/stable/Keywords.html#Salesforce.SOQL-Query): Runs a SOQL
    query and returns a REST API result dictionary.

Using Page Objects -----------------

The
[PageObjects](https://cumulusci.readthedocs.io/en/stable/Keywords.html#file-cumulusci.robotframework.PageObjects)
library provides support for page objects, Robot Framework-style. Even
though Robot is a keyword-driven framework, it's also possible to
dynamically load in keywords unique to a page or an object on the page.

With the `PageObjects` library, you can define classes that represent
page objects. Each class provides keywords that are unique to a page or
a component. These classes can be imported on demand only for tests that
use these pages or components.

### The `pageobject` Decorator

Page objects are normal Python classes that use the `pageobject`
decorator provided by CumulusCI. Unlike traditional Robot Framework
keyword libraries, you can easily define and use keywords in multiple
classes within a single file.

To create a page object class, start by inheriting from one of the
provided base classes. You need to use the `pageobject` decorator to
designate the class as a page object, and to describe the type of page
(Listing, Detail, etc) and the associated salesfore object. From within
a test, these page objects are referenced using both the type and object
name (eg: `Go to page Listing CustomObject__c`).

The following example illustrates how to create a `Listing` page object
for `CustomObject__c`.

```python
from cumulusci.robotframework.pageobjects import ListingPage, pageobject

@pageobject(page_type='Listing', object_name='CustomObject__c')
class CustomObjectListingPage(ListingPage):
    ...
```

#### Using object aliases

Within a test, if you want to refer to the page object with a more
human-readable name such as `Custom Object` rather than
`CustomObject__c` you can do so by setting `object_name` to
`Custom Object` and then defining `_object_name` in the class, as in the
following example.

```python
from cumulusci.robotframework.pageobjects import ListingPage, pageobject

@pageobject(page_type = 'Listing', object_name = 'My Object')
class CustomObjectListingPage(ListingPage):
    _object_name = 'MyObject__c'
    ...
```

By using an alias, you can reference the page object with either the
alias or the actual object name. For example, if `object_name` is set as
described above, the following two uses of `Go to page` are identical:

```robot
Go to page  Listing  My Object
Go to page  Listing  MyObject__c
```

(page-object-base-classes)=

### Page Object Base Classes

CumulusCI provides the following base classes, which should be used for
all classes that use the `pageobject` decorator. You can import these
base classes from `cumulusci.robotframework.pageobjects`.

-   [cumulusci.robotframework.pageobjects.BasePage](https://cumulusci.readthedocs.io/en/stable/Keywords.html#file-cumulusci/robotframework/pageobjects/BasePageObjects.py) A generic base class used by the other pageobject classes. Use the `BasePage` class for creating custom page objects when none of the other base classes make sense.

    : - The `BasePage` adds the `Log current page object` keyword to
    every page object. This keyword is most useful when
    debugging tests. It will add information about the currently
    loaded page object to the log file generated when the test
    runs.

-   `cumulusci.robotframework.pageobjects.DetailPage`: A class for a
    page object that represents a detail page.

-   `cumulusci.robotframework.pageobjects.HomePage`: A class for a page
    object that represents a home page.

-   `cumulusci.robotframework.pageobjects.ListingPage`: A class for a
    page object that represents a listing page.

-   `cumulusci.robotframework.pageobject.NewModal`: A class for a page
    object that represents the "new object" modal.

-   `cumulusci.robotframework.pageobject.ObjectManagerPage`: A class for
    interacting with the object manager.

### Common page object attributes

When using the decorator and inheriting from one of the page object base
classes, your class inherits the following attributes and properties.

-   `self._object_name`: The name of the object related to the class. If
    the class does not define this property, it is set to the value
    provided as the `object_name` parameter to the `pageobject`
    decorator. Note: do not add the namespace prefix in the decorator.
    This attribute automatically adds the prefix from the
    `cumulusci.yml` file when necessary.
-   `self.object_name`: A property that combines the `_object_name`
    attribute with the namespace returned by the `get namespace prefix`
    keyword from the CumulusCI library. If there is no namespace, this
    returns the value of the `_object_name` attribute.
-   `self.builtin`: A reference to the Robot Framework `BuiltIn` library
    that you can use to directly call built-in keywords. You can call
    any built-in keyword by converting the name to all lowercase, and
    replacing all spaces with underscores (such as `self.builtin.log`
    and `self.builtin.get_variable_value`).
-   `self.cumulusci`: A reference to the CumulusCI keyword library. You
    can call any keyword in this library by converting the name to all
    lowercase, and replacing all spaces with underscores (such as
    `self.cumulusci.get_org_info`).
-   `self.salesforce`: A reference to the Salesforce keyword library.
    You can call any keyword in this library by converting the name to
    all lowercase, and replacing all spaces with underscores (such as
    `self.salesforce.wait_until_loading_is_complete`).
-   `self.selenium`: A reference to SeleniumLibrary. You can call any
    keyword in this library by converting the name to all lowercase, and
    replacing all spaces with underscores (such as
    `self.selenim.wait_until_page_contains_element`).

### Example Page Object

This example shows the definition of a page object for the listing page
of custom object `MyObject__c` wherein a new custom keyword,
`Click on the row with name`, is added.

```python
from cumulusci.robotframework.pageobjects import pageobject, ListingPage

@pageobject(page_type="Listing", object_name="MyObject__c")
class MyObjectListingPage(ListingPage):

    def click_on_the_row_with_name(self, name):
        self.selenium.click_link('xpath://a[@title="{}"]'.format(name))
        self.salesforce.wait_until_loading_is_complete()
```

### Importing the Page Object Library Into a Test

The `PageObjects` library is not only a keyword library, but also the
mechanism to import files that contain page object classes. You can
import these files by providing the paths to one or more Python files
that implement page objects. You can also import `PageObjects` without
passing any files to it to take advantage of general purpose page
objects.

For example, consider a case where you create two files that each have
one or more page object definitions: `PageObjects.py` and
`MorePageObjects.py`, both located in the `robot/MyProject/resources`
folder. You can import these page objects from these files into a test
suite.

```robotframework
*** Settings ***
Library         cumulusci.robotframework.PageObjects
...  robot/MyProject/resources/PageObjects.py
...  robot/MyProject/resources/MorePageObjects.py
```

### Using Page Objects

As mentioned in the previous section, you must first import the
`PageObjects` library and any custom page object files you wish to use.

Next, either explicitly load the keywords for a page object, or
reference a page object with one of the generic [page object
keywords](page-object-keywords) provided by the `PageObjects` library.

To explicitly load the keywords for a page object, use the
`Load Page Object` keyword provided by the `PageObjects` library. If
successful, the `PageObjects` library will automatically import the
keywords.

For example, call the `Go To Page` keyword followed by a page object
reference. If the keyword (or page object reference?) navigates you to
the proper page, its keywords will automatically be loaded.

(page-object-keywords)=

### Page Object Keywords

The `PageObjects` library provides these keywords.

-   [Current Page Should
    Be](https://cumulusci.readthedocs.io/en/stable/Keywords.html#PageObjects.Current-Page-Should-Be)
-   [Get Page Object](https://cumulusci.readthedocs.io/en/stable/Keywords.html#PageObjects.Get-Page-Object)
-   [Go To Page
    Object](https://cumulusci.readthedocs.io/en/stable/Keywords.html#PageObjects.Go-To-Page-Object)
-   [Load Page Object](https://cumulusci.readthedocs.io/en/stable/Keywords.html#PageObjects.Load-Page-Object)
-   [Log Page Object
    Keywords](https://cumulusci.readthedocs.io/en/stable/Keywords.html#PageObjects.Log-Page-Object)
-   [Wait For Modal](https://cumulusci.readthedocs.io/en/stable/Keywords.html#PageObjects.Wait-For-Modal)
-   [Wait For Page
    Object](https://cumulusci.readthedocs.io/en/stable/Keywords.html#PageObjects.Wait-For-Page-Object)

### Current Page Should Be

Example: `Current Page Should Be Listing Contact`

This keyword attempts to validate that the given page object represents
the current page. Each page object may use its own method for making the
determination, but the built-in page objects all compare the page
location to an expected pattern (such as `.../lightning/o/...`). If the
assertion passes, the keywords for that page object automatically load.

This keyword is useful if you get to a page via a button or some other
form of navigation because it lets you assert that you are on the page
you think you should be on, and load the keywords for that page, with a
single statement.

#### Get Page Object

Example: `Get page object Listing Contact`

This keyword is most often used to get the reference to a keyword from
another keyword. It is similar in function to robot's built-in [Get
Library
Instance](http://robotframework.org/robotframework/latest/libraries/BuiltIn.html#Get%20Library%20Instance)
keyword. It is rarely used in a test.

#### Go To Page

Example: `Go to page Listing Contact`

This keyword attempts to go to the listing page for the Contact object,
and then load the keywords for that page.

#### Log Page Object Keywords

Example: `Log Page Object Keywords`

This keyword is primarily used as a debugging tool. When called, it will
log each of the keywords for the current page object.

#### Load Page Object

Example: `Load page object Listing Contact`

This keyword loads the page object for the given `page_type` and
`object_name`. It is useful when you want to use keywords from a page
object without first navigating to that page (for example, when you are
already on the page and don't want to navigate away).

#### Wait for Modal

Example: `Wait for modal New Contact`

This keyword can be used to wait for a modal, such as the one that pops
up when creating a new object. The keyword returns once a modal appears,
and has a title of `New <object_name>` (such as "New Contact").

#### Wait for Page Object

Example: `Wait for page object Popup ActivityManager`

Page objects don't have to represent entire pages. You can use the
`Wait for page object` keyword to wait for a page object representing a
single element on a page, such as a popup window.

### Generic Page Objects

You don't need to create a page object in order to take advantage of
page object keywords. If you use one of the page object keywords for a
page that does not have its own page object, the `PageObjects` library
attempts to find a generic page.

For example, if you use `Current page should be Home Event` and there
is no page object by that name, a generic `Home` page object will be
loaded, and its object name will be set to `Event`.

Or let's say your project has created a custom object named
`Island__c`. You don't have a home page, but the object does have a
standard listing page. Without creating any page objects, this test
works by using generic implementations of the `Home` and `Listing` page
objects:

```robotframework
*** Test Cases ***
Example test which uses generic page objects
    ## Go to the custom object home page, which should
    ## redirect to the listing page
    Go To Page  Home  Island__c

    ## Verify that the redirect happened
    Current Page Should Be  Listing  Island__c
```

CumulusCI provides these generic page objects.

#### Detail

Example: `Go to page Detail Contact ${contact id}`

Detail pages refer to pages with a URL that matches the pattern
`<host>/lightning/r/<object name>/<object id>/view`.

#### Home

Example: `Go to page Home Contact`

Home pages refer to pages with a URL that matches the pattern
"\<host\>/lightning/o/\<object name\>/home"

### `Listing`

Example: `Go to page Listing Contact`

Listing pages refer to pages with a URL that matches the pattern
"\<host\>b/lightning/o/\<object name\>/list"

#### New

Example: `Wait for modal New Contact`

The New page object refers to the modal that pops up when creating a new
object.

Of course, the real power comes when you create your own page object
class that implements keywords that can be used with your custom
objects.

## Configuring the robot_libdoc Task

If you define a robot resource file named `MyProject.resource` and place
it in the `resources` folder, you can add this configuration to the
`cumulusci.yml` file to enable the `robot_libdoc` task to generate
documentation.

```yaml
tasks:
    robot_libdoc:
        description: Generates HTML documentation for the MyProject Robot Framework Keywords
        options:
            path: robot/MyProject/resources/MyProject.resource
            output: robot/MyProject/doc/MyProject_Library.html
```

Normally this task will generate HTML output. If the output file ends
with ".csv", a csv file will be generated instead.

To generate documentation for more than one keyword file or library,
give a comma-separated list of files for the `path` option, or define
`path` as a list under `tasks__robot_libdoc` in the `cumulusci.yml`
file.

For example, generate documentation for `MyLibrary.py` and
`MyLibrary.resource`.

```yaml
tasks:
    robot_libdoc:
        description: Generates HTML documentation for the MyProject Robot Framework Keywords
        options:
            path:
                - robot/MyProject/resources/MyProject.resource
                - robot/MyProject/resources/MyProject.py
            output: robot/MyProject/doc/MyProject_Library.html
```

You can also use basic filesystem wildcards.

For example, to document all Robot files in `robot/MyProject/resources`,
configure the `path` option under `tasks__robot_libdoc` in the
`cumulusci.yml` file.

```yaml
tasks:
    robot_libdoc:
        description: Generates HTML documentation for the MyProject Robot Framework Keywords
        options:
            path: robot/MyProject/resources/*.resource
            output: robot/MyProject/doc/MyProject_Library.html
```

## Using Keywords and Tests from a Different Project

Much like you can [use tasks and flows from a different project](tasks-and-flows-from-a-different-project), you can also use keywords and tests from other
projects. The keywords are brought into your repository the same way as
with tasks and flows, via the `sources` configuration option in the
`cumulusci.yml` file. However, keywords and tests require extra
configuration before they can be used.

```{note}
This feature isn't for general purpose sharing of keywords between
multiple projects. It was designed specifically for the case where a
product is being built on top of another project and needs access to
product-specific keywords.
```

### Using Keywords

In order to use the resources from another project, you must first
configure the `robot` task to use one of the sources that have been
defined for the project. To do this, add a `sources` option under the
`robot` task, and add to it the name of an imported source.

For exmple, if your project is built on top of NPSP, and you want to use
keywords from the NPSP project, first add the NPSP repository as a
source in the project's `cumulusci.yml` file:

```yaml
sources:
    npsp:
        github: https://github.com/SalesforceFoundation/NPSP
        release: latest_beta
```

Then add `npsp` under the `sources` option for the robot task. This is
because the project as a whole can use tasks or flows from multiple
projects, but `robot` only needs keywords from a single project.

```yaml
tasks:
    robot:
        options:
            sources:
                - npsp
```

When the `robot` task runs, it adds the directory that contains the code
for the other repository to `PYTHONPATH`, which Robot uses when
resolving references to libraries and keyword files.

Once this configuration has been saved, you can import the resources as
if you were in the NPSP repository.

For example, in a project which has been configured to use NPSP as a
source, the `NPSP.robot` file can be imported into a test suite.

```robot
*** Settings ***
Resource   robot/Cumulus/resources/NPSP.robot
```

```{note}
Even with proper configuration, some keywords or keyword libraries might
not be usable. Be careful to avoid using files that have the exact same
name in multiple repositories.
```

### Running Tests

Running a test from another project requires prefixing the path to the
test with the source name. The path needs to be relative to the root of
the other repo.

For example, starting from the previous example, to run the
`create_organization.robot` test suite from NPSP:

```console
$ cci task run robot --suites npsp:robot/Cumulus/tests/browser/contacts_accounts/create_organization.robot
```
