# Contribute to CumulusCI

Contributions are welcome, and they are greatly appreciated!

## Types of Contributions

You can contribute in many ways:

### Report Bugs

Report bugs at <https://github.com/SFDO-Tooling/CumulusCI/issues>.

When reporting a bug, please include:

-   Your operating system name and version.
-   Any details about your local setup that might be helpful in
    troubleshooting.
-   Detailed steps to reproduce the bug.

### Fix Bugs

Look through the GitHub issues for bugs. Anything tagged with "bug"
and "help wanted" is open to whomever wants to implement it.

### Implement Features

Look through the GitHub issues for features. Anything tagged with
"enhancement" and "help wanted" is open to whomever wants to
implement it.

### Write Documentation

CumulusCI could always use more documentation, whether as part of the
official CumulusCI docs, in docstrings, or even on the web in blog
posts, articles, and such.

### Submit Feedback

The best way to send feedback is to file an
[issue](https://github.com/SFDO-Tooling/CumulusCI/issues).

If you are proposing a feature:

-   Explain in detail how it would work.
-   Keep the scope as narrow as possible, to make it easier to
    implement.
-   Remember that this is a volunteer-driven project, and that
    contributions are welcome :)

## Install for Development

Ready to contribute? Here's how to set up CumulusCI for local
development.

1.  Fork the CumulusCI repo on GitHub.

2.  Clone your fork to your local workspace.

3.  Create a fresh Python 3 virtual environment and activate it (to keep
    this isolated from other Python software on your machine). Here is
    one way:

        $ python3 -m venv cci_venv
        $ source cci_venv/bin/activate

4.  Install the development requirements:

        $ make dev-install

5.  Install `pre-commit` hooks for `black` and `flake8`:

        $ pre-commit install --install-hooks

6.  After making changes, run the tests and make sure they all pass:

        $ pytest

7.  Your new code should also have meaningful tests. One way to double
    check that your tests cover everything is to ensure that your new
    code has test code coverage:

        $ make coverage

8.  Push your changes to GitHub and submit a Pull Request. The base
    branch should be a new feature branch that we create to receive the
    changes (contact us to create the branch). This allows us to test
    the changes using our build system before merging to main.

```{note}
We enable typeguard with pytest so if you add type declarations to your
code, those declarations will be treated as runtime assertions in your
Python tests.
```

## Pull Request Guidelines

Before you submit a pull request, check that it meets these guidelines:

-   Documentation is updated to reflect all changes.
-   New classes, functions, etc have docstrings.
-   New code has comments.
-   Code style and file structure is similar to the rest of the project.
-   You have run the `black` code formatter.
-   If you are a new contributor, don't forget to add yourself to the
    `AUTHORS.rst` file in your pull request (either GitHub username, or
    first/last name).
-   You have labeled your pull request:
    -   `critical-changes` for breaking changes,
    -   `enhancement` for new features,
    -   `bug` for when fixing a bug or closing an issue, or
    -   `ignore-for-release` for internal changes.

## Testing CumulusCI

### Org-reliant Automated Tests

Some tests are marked `@pytest.mark.vcr()` which means that they can
either call into a real (configured) Salesforce org or use a cached YAML
file of the request/response.

By default using pytest will use the cached YAML. If you want to work
against a real scratch org, you do so like this:

    $ pytest --org qa <other arguments and options, such as filename or -k testname>

Where "orgname" is a configured org name like "qa", "dev", etc.

To regenerate the VCR file, you can run this command:

    $ pytest --replace-vcrs --org qa

This will configure an org named "qa" and regenerate them.

That will run all VCR-backed tests against the org, including all of the
slow integration tests.

### Running Integration Tests

Some tests generate so much data that we do not want to store the VCR
cassettes in our repo. You can mark tests like that with
`@pytest.mark.large_vcr()`. When they are executed, their cassettes will
go in a .gitignore'd folder called `large_cassettes`.

Do not commit the files (`large_cassettes/\*.yml`) to the repository.

Some tests generate even more network traffic data and it isn't
practical to use VCR at all. Still, we'd like to run them when we run
all of the other org-reliant tests with --org. Mark them with
`@pytest.mark.needs_org()` and they will run with the VCR tests.

Some tests are so slow that you only want to run them on an opt-in
basis. Mark these tests with `@pytest.mark.slow()` and run them with
`pytest --run-slow-tests` or
`pytest --run-slow-tests --orgname <orgname>`.

### Writing Integration Tests

All features should have integration tests which work against real orgs
or APIs.

Our test suite makes extensive use of pytest fixtures; the ones below
should be used in your tests where appropriate. Search the repo to see
examples where they are used in context, or to see their definitions:

-   gh_api - get a fake github API
-   with temp_db():\... - create a temporary SQLite Database
-   delete_data_from_org("Account,Contacts") - delete named sobjects
    from an org
-   run_code_without_recording(func) - run a function ONLY when the
    integration tests are being used against real orgs and DO NOT record
    the network traffic in a VCR cassette
-   sf - a handle to a simple-salesforce client tied to the current org
-   mock_http_response(status) - make a mock HTTP Response with a
    particular status
-   runtime - Get the CumulusCI runtime for the current working
    directory
-   project_config - Get the project config for the current working
    directory
-   org_config - Get the project config for the current working
    directory
-   create*task - Get a task \_factory* which can be used to
    construct task instances.
-   global_describe - Get a function that will generate the JSON that
    Salesforce would generate if you do a GET on the /sobjects endpoint

Decorators for tests:

-   pytest.mark.slow(): a slow test that should only be executed when
    requested with --run-slow-tests
-   pytest.mark.large_vcr(): a network-based test that generates VCR
    cassettes too large for version control. Use --org to generate
    them locally.
-   pytest.mark.needs_org(): a test that needs an org (or at least
    access to the network) but should not attempt to store VCR
    cassettes. Most tests that need network access do so because they
    need to talk to an org, but you can also use this decorator to
    give access to the network to talk to github or any other API.
-   pytest.mark.org_shape('qa', 'qa_org'): - switch the current
    org to an org created with org template "qa" after running flow
    "qa_org". As with all tests, clean up any changes you make,
    because this org may be reused by other tests.

A complete list is available with:

> $ pytest --markers

### Randomized tests

Tests should be executable in any order. You can run this command a few
times to verify if they are:

> pytest --random-order

It will output something like this:

> Using --random-order-bucket=module Using --random-order-seed=986925

Using those two parameters on the command line, you can replicate a
particular run later.

In extremely rare cases where it's not possible to make tests
independent, you can [enforce an
order](https://pythonhosted.org/pytest-random-order/##disable-shuffling-in-module-or-class)
