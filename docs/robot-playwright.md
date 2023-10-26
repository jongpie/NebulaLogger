# Playwright Technology Preview

Since its inception, CumulusCI has relied on Selenium to provide the
foundation of our browser automation keywords.

In 2020, Microsoft introduced a new browser automation tool named
[Playwright](https://playwright.dev/). Playwright is a ground-up
reinvention of a browser automation library that aims to address several
shortcomings of Selenium. For example, Playwright has built-in support
for waiting for elements to appear, for working with the shadow DOM,
video capture of a testing session, and so on.

In 2021 the Robot Framework project introduced the
[Browser](https://robotframework-browser.org/) library which adds
keywords that use the Playwright API.

Starting with CumulusCI version 3.59.0, we are providing experimental
support for Playwright and the Browser library in CumulusCI.

In CumulusCI 3.60, we've reorganized our keywords so that a test can
import the API and performance keywords without importing Selenium
keywords. To use Playwright-based keywords, import the resource file
[SalesforcePlaywright.robot](https://cumulusci.readthedocs.io/en/stable/Keywords.html#file-cumulusci/robotframework/SalesforcePlaywright.robot),
which imports the non-Selenium keywords along with the keywords in the
[SalesforcePlaywright
library](https://cumulusci.readthedocs.io/en/stable/Keywords.html#file-cumulusci.robotframework.SalesforcePlaywright).

## Installation

We have not yet bundled Playwright and the Browser library with
CumulusCI. However, we have provided a script to make it easy to install
or uninstall Playwright and the Browser library while we continue to
work on fully supporting it.

### Step 1: Install Node.js

Playwright is based on Node.js. If you don't already have Node.js
installed, you can find a Node.js installer for your platform on the
[Node.js downloads page](https://nodejs.org/en/download/).

```{important}
You must have Node.js installed before continuing with these
instructions.
```

### Step 2: Run the Playwright installation command

Installing the browser library requires a couple of manual steps, which
we've automated in a single script. This script does three things:

-   it verifies that Node.js has been installed
-   it downloads and installs the Browser keyword library
-   it downloads and installs the Node.js modules and drivers for
    playwright.

```{note}
The installation of Playwright contains drivers for all supported
browsers, so there's no need to manually install drivers such as
ChromeDriver. It works right out of the box!
```

Before you run the script, make sure your working directory is at the
root of your repository. You can then run the script with the following
command:

```console
$ cci robot install_playwright
```

```{tip}
You can use the `--dry_run` (or `-n`) option to see what the command
will do without actually installing.
```

## Running an example test

As mentioned earlier, this is an experimental release of Playwright
integration, so any CumulusCI keywords that rely on Selenium won't
work. However, the following example shows how easy it can be to write
Playwright-based tests with off-the-shelf [keywords provided by the
Browser
library](https://marketsquare.github.io/robotframework-browser/Browser.html)

To initialize Playwright support in a test suite, import the
`SalesforcePlaywright.robot` resource file as shown in the following
example. It imports the Browser library and defines the keywords
`Open Test Browser` and `Delete records and close browser`.

```robotframework
*** Settings ***
Resource     cumulusci/robotframework/SalesforcePlaywright.robot

Suite Setup      Open test browser
Suite Teardown   Delete records and close browser

*** Test Cases ***

Go to user profile
    Click    button:has-text("View profile")
    Click    .profile-card-name .profile-link-label

    Wait until network is idle
    Take screenshot

Go to contacts home
    Click            button:has-text("App Launcher")
    Fill text        input[placeholder='Search apps and items...']  Contacts
    Click            one-app-launcher-menu-item:has-text("Contacts")

    Wait until network is idle
    Take screenshot
```

To run the test, save the above code in a `.robot file` (e.g.
`example.robot`) and then run it with the standard robot task:

```console
$ cci task run robot --suites example.robot
```

### Things to Notice

This example test is unable to use any of the existing Selenium-based
keywords, except for two. We've created a new library based on
Playwright and the Browser library with two keywords that are similar to
existing keywords: [Open Test
Browser](https://cumulusci.readthedocs.io/en/stable/Keywords.html#SalesforcePlaywright.Open%20Test%20Browser) and
[Delete Records and Close
Browser](https://cumulusci.readthedocs.io/en/stable/Keywords.html#SalesforcePlaywright.Delete%20Records%20And%20Close%20Browser)

This test also uses the Browser keyword [Wait until network is
idle](https://marketsquare.github.io/robotframework-browser/Browser.html#Wait%20Until%20Network%20Is%20Idle)
before taking a screenshot. This is a keyword that waits for there to be
at least one instance of 500ms of no network traffic on the page after
it starts to load. This seems to be more reliable and easier to use
method than waiting for a page-specific element to appear.

This test has no explicit waits for the buttons and links that it clicks
on. The underlying Playwright engine automatically waits for elements,
so there should almost never be a need for keywords such as
`Wait until page contains element` or `Wait until element is enabled`.

Finally, notice how easy it is to interact with both the app menu and
the user profile. Playwright locators are often much easier to write
than Selenium locators, which translates to tests and keywords that
don't have to be tweaked when the page markup changes.

## Writing keywords in JavaScript

At its core, Playwright is built on Node.js, which makes it possible
to write keywords in JavaScript. This is enabled by providing the path
to a JavaScript library when the Browser library is
imported. CumulusCI comes with a small bootstrap file which will
import a Node module from your project, which itself can import any number of other
modules.

```{tip}
For more information about writing keywords in Javascript see [Extending Browser library with a JavaScript module](
https://marketsquare.github.io/robotframework-browser/Browser.html#Extending%20Browser%20library%20with%20a%20JavaScript%20module)
in the [Browser library documentation](https://marketsquare.github.io/robotframework-browser/Browser.html).
```

### Creating a keyword file in JavaScript

When you import `SalesforcePlaywright.robot` into a test, it will import
the Browser library and pass it the name of a small bootstrap
JavaScript file. This bootstrap file will import the file
`robot/<ProjectName>/javascript/index.js`, exposing the exported
functions as keywords.

### Example

Who doesn't love a good "Hello, world" example? Start by creating the
`javascript` folder in your `robot` folder. For example, if your
project is named Food-Bank, you should create a folder named
`robot/Food-Bank/javascript`.

In that folder, create a file named `keywords.js` with the following
content:

```javascript
// keywords.js
function hello_javascript() {
    return "Hello, JavaScript!";
}

exports.__esModule = true;
module.exports = { hello_javascript };
```

```{note}
The Browser documentation for [writing keywords in javascript](https://marketsquare.github.io/robotframework-browser/Browser.html#Extending%20Browser%20library%20with%20a%20JavaScript%20module) uses async functions
in all of the examples, but async functions are not strictly required.
```

Next, create a file named `index.js` in the same folder. This file
is where you can import the `keywords.js` file and any other files
you need to import. For our simple example `index.js` should look
like the following example.

```javascript
// index.js
exports.__esModule = true;
module.exports = {
    ...require("keywords.js"),
};
```

### Getting CumulusCI test context

CumumlusCI comes with a node module named `cumulusci` which provides
access to information about the repository and org.

Let's extend our earlier example to include a keyword for getting the
instance URL of the org under test.

The first step is to import the `cumulusci` module. This module
returns data that looks like the following:

```json
{
    "project_config": {
        "repo_name": "Food-Bank",
        "repo_root": "/projects/Food-Bank"
    },
    "org": {
        "name": "dev",
        "instance_url": "https://something-clever.my.salesforce.com",
        "org_id": "00D5C..."
    }
}
```

We can directly access these member attributes with a keyword. Edit
the `keywords.js` file to look like the following example.

```javascript
var cci = require("cumulusci");

function hello_javascript() {
    return "Hello, Javascript!";
}

function get_instance_url() {
    return cci.org.instance_url;
}

exports.__esModule = true;
module.exports = {
    hello_javascript,
    get_instance_url,
};
```

## Summary

This is just a preview of things to come. The CumulusCI team will be
spending more time evaluating Playwright, with an eye toward making it a
viable and more robust replacement for Selenium.

## Resources

-   [Browser Library Home Page](https://robotframework-browser.org/)
-   [Browser Library Keyword
    Documentation](https://marketsquare.github.io/robotframework-browser/Browser.html)
-   [Playwright Home Page](https://playwright.dev)
