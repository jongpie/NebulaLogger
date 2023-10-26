# Managing Locators

The keywords that come with CumulusCI are based on the open source
keyword library
[SeleniumLibrary](http://robotframework.org/SeleniumLibrary/SeleniumLibrary.html).
This library supports multiple ways to reference an element: by XPath,
by CSS selector, by id, by text, and so on. SeleniumLibrary calls these
_location strategies._

You can specify a strategy by providing a prefix to the locator. For
example:

-   `id:123` specifies an element with an id of 123
-   `xpath://div[text()='Hello, world']` lets you specify an element by
    an xpath expression
-   `css:div.slds-spinner` defines an object by its css path

```{tip}
You can find the full list of supported locator strategies in the
section titled [Explicit locator
strategy](https://robotframework.org/SeleniumLibrary/SeleniumLibrary.html#Explicit%20locator%20strategy)
in the SeleniumLibrary documentation.
```

In this section, we'll show how to create a project-specific locator
strategy by storing locators in a dictionary and then associating them
with a custom prefix.

## Storing locators in a dictionary

The first step toward creating custom locator strategies with the
locator manager is to define your project's locators in a dictionary. If
you have just a handful of locators you can define them directly in a
keyword library. You can also save them in a separate file.

If you need to be able to run tests against a prerelease org you might
want to store your locators in two files: one for the current release
and one for the prerelease. You can then import the appropriate version
at runtime.

```{note}
In order to keep the examples short we're only going to focus on
supporting one release at a time in this documentation.
```

The locator dictionary can include nested dictionaries, so you can
organize locators into logical groups. Each leaf node can be any locator
string supported by SeleniumLibrary. Notice that these locator strings
can include locators of different types.

For example, consider the following set of locators which we might find
in a library of keywords for dealing with the calendar tab:

```python
locators = {
    "sidebar": {
        "options button": "css:a[role='button'][title='Calendar Options']",
        "new button": "css:a[role='menuitem'][title='New Calendar']",
    },
    "modal": {
        "window": "xpath://div[@role='dialog'][.//h2[.='Create Calendar']]",
        "next button": "css:a.wzButtonSaveAndNext",
    }
}
```

We've organized the locators into two logical groupings: one related to
elements on the sidebar, and one related to elements of a modal window.
Notice also that three of the locators are CSS selectors and one is an
XPath.

```{tip}
Dictionaries can be nested as deeply as you want, but it's rarely
necessary to have locators more than a couple of levels deep.
```

## Registering the locator dictionary

SeleniumLibrary provides a way to register [custom location
strategies](http://robotframework.org/SeleniumLibrary/SeleniumLibrary.html#Custom%20locators)
via the [Add Location
Strategy](http://robotframework.org/SeleniumLibrary/SeleniumLibrary.html#Add%20Location%20Strategy)
keyword. While it's possible to write your own strategies using
keywords, the locator manager makes it easy to associate a locator
prefix with a dictionary of locators.

This registration is done via the `register_locators` method of the
locator manager, and should be done in the `__init__` method of a
keyword library.

For example, here is what it might look like for a library that contains
keywords for the calendar tab.

```python
from robot.libraries.BuiltIn import BuiltIn
from cumulusci.robotframework import locator_manager

locators = {...}  ## see previous example

class CalendarLibrary:
    ROBOT_LIBRARY_SCOPE = "GLOBAL"

    def __init__(self):
        locator_manager.register_locators("calendar", locators)
```

When this library is imported into a test case file, the prefix
"calendar" is registered with SeleniumLibrary as a custom locator
strategy.

## Using custom locators

Once the dictionary has been defined and has been registered with a
prefix, the locators work very similarly to any other locator. If the
dictionaries are nested, you can separate the levels with a period (ie:
dot notation).

For example, with our example locators the options button locator can be
used like this:

```
Click element   calendar:sidebar.options button
```

The following table shows how the locator is parsed:

---

`calendar:` locator prefix

`sidebar` first level of the dictionary (eg: `locators['sidebar']`)

`.` a level separator

`options button` the next level of a nested dictionary (eg:
`locators['sidebar']['options_button']`)

---

## Parameterized Locators

Sometimes the only difference between multiple elements on a page is the
text displayed in that element. For example, the html markup for a save,
edit, and cancel button may be identical except for the word "Save",
"Edit", or "Cancel".

While you can create a separate locator for each button, it's better to
use a single parameterized locator for multiple buttons, which gives you
more flexibility.

Notice in our calendar locators we have one locator for a `menuitem`
with the title of 'New Calendar':

```
locators = {
    ...
    "new_button": "css:a[role='menuitem'][title='New Calendar']",
    ...
}
```

For a calendar menu with multiple menuitems, you can use a unique
locator for each, or a single parameterized locator so that you only
need to maintain one locator.

To create a locator with one or more parameters, replace a portion of
the locator with [{}]{.title-ref} like this:

```
locators = {
    ...
    "menu_item": "css:a[role='menuitem'][title='{}']",
    ...
}
```

When you use the locator, you can pass one or more parameters by
specfying a comma separated list of values after a colon. For example:

```
Click element  calendar:sidebar.menu_item:New Calendar
```

The [{}]{.title-ref} placeholders are replaced with the parameter
values, in order. For example, the title in the above example becomes
[New Calendar]{.title-ref}.

```{note}
If your locator has more than one parameter (ie: more than one instance
of [{}]{.title-ref} within the locator definition), parameters will be
replaced in the order in which they are supplied. The first parameter
after the [:]{.title-ref} and before a comma will be used in place of
the first [{}]{.title-ref}, the next parameter will be used in place of
the next [{}]{.title-ref}, and so on.
```
