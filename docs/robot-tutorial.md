# Robot Tutorial

This tutorial will step you through writing your first test, then
enhancing that test with a custom keyword implemented as a page object.
It is not a comprehensive tutorial on using Robot Framework. For Robot
Framework documentation see the [Robot Framework User
Guide](http://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html)

It is assumed you've worked through the CumulusCI [](get-started) section at least up to the point where you've called `cci project init`. It is also assumed that
you've read the [](acceptance-testing-with-robot-framework) section of this document, which gives an overview of CumulusCI and Robot Framework integration.

## Part 1: Folder Structure

We recommend that all Robot tests, keywords, data, and log and report
files live under a folder named `robot`, at the root of your repository.
If you worked through the [](get-started) section, the following folders will have been created under
`MyProject/robot/MyProject`:

-   `doc` - a place to put documentation for your tests
-   `resources` - a place to put Robot libraries and keyword files that
    are unique to your project
-   `results` - a place for Robot to write its log and report files
-   `tests` - a place for all of your tests.

## Part 2: Creating a custom object

For this tutorial we're going to use a Custom Object named `MyObject`
(e.g. `MyObject__c`). In addition, we need a Custom Tab that is
associated with that object.

If you want to run the tests and keywords in this tutorial verbatim, you
will need to go to Setup and create the following:

1.  A Custom Object with the name `MyObject`.
2.  A Custom Tab associated with this object.

## Part 3: Creating and running your first Robot test

The first thing we want to do is create a test that verifies we can get
to the listing page of the Custom Object. This will let us know that
everything is configured properly.

Open up your favorite editor and create a file named `MyObject.robot` in
the folder `robot/MyProject/tests`. Copy and paste the following into
this file, and then save it.

```robotframework
*** Settings ***
Resource  cumulusci/robotframework/Salesforce.robot
Library   cumulusci.robotframework.PageObjects

Suite Setup     Open test browser
Suite Teardown  Delete records and close browser

*** Test Cases ***
Test the MyObject listing page
    Go to page  Listing  MyObject__c
    Current page should be  Listing  MyObject__c
```

```{note}
The above code uses `Go to page` and `Current page should be`, which
accept a page type (`Listing`) and object name (`MyObject__c`). Even
though we have yet to create that page object, the keywords will work by
using a generic implementation. Later, once we've created the page
object, the test will start using our implementation.
```

To run just this test, run the following command at the prompt:

```console
$ cci task run robot -o suites robot/MyProject/tests/MyObject.robot --org dev
```

If everything is set up correctly, you should see the output that looks
similar to this:

```console
$ cci task run robot -o suites robot/MyProject/tests/MyObject.robot --org dev
2019-05-21 17:29:25: Getting scratch org info from Salesforce DX
2019-05-21 17:29:29: Beginning task: Robot
2019-05-21 17:29:29:        As user: test-wftmq9afc3ud@example.com
2019-05-21 17:29:29:         In org: 00Df0000003cuDx
2019-05-21 17:29:29:
==============================================================================
MyObject
==============================================================================
Test the MyObject listing page                                        | PASS |
------------------------------------------------------------------------------
MyObject                                                              | PASS |
1 critical test, 1 passed, 0 failed
1 test total, 1 passed, 0 failed
==============================================================================
Output:  /Users/boakley/dev/MyProject/robot/MyProject/results/output.xml
Log:     /Users/boakley/dev/MyProject/robot/MyProject/results/log.html
Report:  /Users/boakley/dev/MyProject/robot/MyProject/results/report.html
```

## Part 4: Creating a page object

Most projects are going to need to write custom keywords that are unique
to that project. For example, NPSP has a keyword for filling in a batch
gift entry form, EDA has a keyword with some custom logic for validating
and affiliated contact, and so on.

The best way to create and organize these keywords is to place them in
page object libraries. These libraries contain normal Python classes and
methods which have been decorated with the `pageobjects` decorator
provided by CumulusCI. By using page objects, you can write keywords
that are unique to a given page, making them easier to find and easier
to manage.

### Defining the class

CumulusCI provides the base classes that are a good starting point for
your page object (see [](page-object-base-classes)). In this case we're writing a keyword that works on the
listing page, so we want our class to inherit from the `ListingPage`
class.

```{note}
Our class also needs to use the `pageobject` decorator, so we must
import that along with the `ListingPage` class.
```

To get started, create a new file named `MyObjectPages.py` in the folder
`robot/MyProject/resources`. At the top of the new keyword file, add the
following import statement:

```python
from cumulusci.robotframework.pageobjects import pageobject, ListingPage
```

Next we can create the class definition by adding the following two
lines:

```python
@pageobject(page_type="Listing", object_name="MyObject__c")
class MyObjectListingPage(ListingPage):
```

The first line registers this class as a page object for a listing page
for the object `MyObject__c`. The second line begins the class
definition.

### Creating the keyword

At this point, all we need to do to create the keyword is to create a
method on this object. The method name should be all lowercase, with
underscores instead of spaces. When called from a Robot test, the case
is ignored and all spaces are converted to underscores.

In this case we want to create a method named
`click_on_the_row_with_name`. All we want it to do is to find a link
with the given name, click on the link, and then wait for the new page
to load. To make the code more bulletproof, it will use a keyword from
`SeleniumLibrary` to wait until the page contains the link before
clicking on it. While probably not strictly necessary on this page,
waiting for elements before interacting with them is a good habit to get
into.

Add the following under the class definition:

```python
def click_on_the_row_with_name(self, name):
    xpath='xpath://a[@title="{}"]'.format(name)
    self.selenium.wait_until_page_contains_element(xpath)
    self.selenium.click_link(xpath)
    self.salesforce.wait_until_loading_is_complete()
```

Notice that the above code is able to use the built-in properties
`self.selenium` and `self.salesforce` to directly call keywords in the
`SeleniumLibrary` and `Salesforce` keyword libraries.

### Putting it all together

After adding all of the above code, our file should now look like this:

```python
from cumulusci.robotframework.pageobjects import pageobject, ListingPage


@pageobject(page_type="Listing", object_name="MyObject__c")
class MyObjectListingPage(ListingPage):
    def click_on_the_row_with_name(self, name):
        xpath='xpath://a[@title="{}"]'.format(name)
        self.selenium.wait_until_page_contains_element(xpath)
        self.selenium.click_link(xpath)
        self.salesforce.wait_until_loading_is_complete()
```

We now need to import this page object into our tests. In the first
iteration of the test, we imported
`cumulusci.robotframework.PageObjects`, which provided our test with
keywords such as `Go to page` and `Current page should be`. In addition
to being the source of these keywords, it is also the way to import page
object files into a test case.

To import a file with one or more page objects you need to supply the
path to the page object file as an argument when importing
`PageObjects`. The easiest way is to use Robot's continuation
characters `...` on a separate line.

Modify the import statements at the top of `MyObject.robot` to look like
the following:

```robotframework
*** Settings ***
Resource  cumulusci/robotframework/Salesforce.robot
Library   cumulusci.robotframework.PageObjects
...  robot/MyProject/resources/MyObjectPages.py
```

This will import the page object definitions into the test case, but the
keywords won't be available until the page object is loaded. Page
objects are loaded automatically when you call `Go to page`, or you can
explicitly load them with `Load page object`. In both cases, the first
argument is the page type (eg: [Listing]{.title-ref},
[Home]{.title-ref}, etc) and the second argument is the object name (eg:
`MyObject__c`).

Our test is already using `Go to page`, so our keyword should already be
available to us once we've gone to that page.

## Part 5: Adding test data

We want to be able to test that when we click on one of our custom
objects on the listing page that it will take us to the detail page for
that object. To do that, our test needs some test data. While that can
be very complicated in a real-world scenario, for simple tests we can
use the Salesforce API to create test data when the suite first starts
up.

To create the data when the suite starts, we can add a `Suite Setup` in
the settings section of the test. This takes as an argument the name of
a keyword. In our case we're going to create a custom keyword right in
the test to add some test data for us.

It is not necessary to do it in a setup. It could be a step in an
individual test case, for example. However, putting it in the
`Suite Setup` guarantees it will run before any tests in the same file
are run.

Open up `MyObject.robot` and add the following just before
`*** Test Cases ***`:

```robotframework
*** Keywords ***
Create test data
    [Documentation]
    ...  Creates a MyObject record named "Leeroy Jenkins"
    ...  if one doesn't exist

    ## Check to see if the record is already in the database,
    ## and return if it already exists
    ${status}  ${result}=  Run keyword and ignore error  Salesforce get  MyObject__c  Name=Leeroy Jenkins
    Return from keyword if  '${status}'=='PASS'

    ## The record didn't exist, so create it
    Log  creating MyObject object with name 'Leeroy Jenkins'  DEBUG
    Salesforce Insert  MyObject__c  Name=Leeroy Jenkins
```

We also need to modify our `Suite Setup` to call this keyword in
addition to calling the `Open Test Browser` keyword. Since `Suite Setup`
only accepts a single keyword, we can use the built-in keyword
`Run keywords` to run more than one keyword in the setup.

Change the suite setup to look like the following, again using Robot's
continuation characters to spread the code across multiple rows for
readability.

```{note}
It is critical that you use all caps for `AND`, as that's the way Robot
knows where one keyword ends and the next begins.
```

```robotframework
Suite Setup     Run keywords
...  Create test data
...  AND  Open test browser
```

Notice that our `Suite Teardown` calls
`Delete records and close browser`. The `records` in that keyword
refers to any data records created by `Salesforce Insert`. This makes it
possible to both create and later clean up temporary data used for a
test.

It is important to note that the suite teardown isn't guaranteed to run
if you forcibly kill a running Robot test. For that reason, we added a
step in `Create test data` to check for an existing record before adding
it. If a previous test was interrupted and the record already exists,
there's no reason to create a new record.

## Part 6: Using the new keyword

We are now ready to modify our test to use our new keyword, since we now
have some test data in our database, and the keyword definition in our
page object file.

Once again, edit `MyObject.robot` to add the following two statements at
the end of our test:

```robotframework
Click on the row with name  Leeroy Jenkins
Current page should be  Detail  MyObject__c
```

The complete test should now look like this:

```robotframework
*** Settings ***
Resource  cumulusci/robotframework/Salesforce.robot
Library   cumulusci.robotframework.PageObjects
...  robot/MyProject/resources/MyObjectPages.py

Suite Setup     Run keywords
...  Create test data
...  AND  Open test browser
Suite Teardown  Delete records and close browser

*** Keywords ***
Create test data
    [Documentation]  Creates a MyObject record named "Leeroy Jenkins" if one doesn't exist

    ## Check to see if the record is already in the database,
    ## and do nothing if it already exists
    ${status}  ${result}=  Run keyword and ignore error  Salesforce get  MyObject__c  Name=Leeroy Jenkins
    Return from keyword if  '${status}'=='PASS'

    ## The record didn't exist, so create it
    Log  creating MyObject object with name 'Leeroy Jenkins'  DEBUG
    Salesforce Insert  MyObject__c  Name=Leeroy Jenkins

*** Test Cases ***
Test the MyObject listing page
    Go to page  Listing  MyObject__c
    Current page should be  Listing  MyObject__c

    Click on the row with name  Leeroy Jenkins
    Current page should be  Detail  MyObject__c
```

With everything in place, we should be able to run the test using the
same command as before:

```console
$ cci task run robot -o suites robot/MyProject/tests/MyObject.robot --org dev
2019-05-21 22:02:27: Getting scratch org info from Salesforce DX
2019-05-21 22:02:31: Beginning task: Robot
2019-05-21 22:02:31:        As user: test-wftmq9afc3ud@example.com
2019-05-21 22:02:31:         In org: 00Df0000003cuDx
2019-05-21 22:02:31:
==============================================================================
MyObject
==============================================================================
Test the MyObject listing page                                        | PASS |
------------------------------------------------------------------------------
MyObject                                                              | PASS |
1 critical test, 1 passed, 0 failed
1 test total, 1 passed, 0 failed
==============================================================================
Output:  /Users/boakley/dev/MyProject/robot/MyProject/results/output.xml
Log:     /Users/boakley/dev/MyProject/robot/MyProject/results/log.html
Report:  /Users/boakley/dev/MyProject/robot/MyProject/results/report.html
```
