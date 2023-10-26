# Continuous Integration

The "CI" in CumulusCI stands for "continuous integration".
Continuous integration is the practice of automatically running a
project's tests for any change before merging that change to the `main`
branch in the repository. Continuous integration also configures the
repository so that changes are merged only if the tests have passed.
This practice keeps the `main` branch in an error-free state where it
can be released any time.

Teams can create bespoke automation for CumulusCI tailored to their
project's needs. Once created, the automation is available to all
project participants, from developers and quality engineers, to
documentation writers and product managers. CumulusCI takes this reuse
of automation one step further by letting it run in the context of CI
systems like GitHub Actions, CircleCI, or Azure Pipelines. This
consistent reuse of automation from local environments to cloud-based CI
systems gives teams the ability to develop, test, and deploy their
projects with confidence.

## CumulusCI Flow

CumulusCI Flow is the process by which Salesforce metadata is developed,
tested, and deployed to our customers. It is similar to GitHub Flow,
with a few tweaks and additions.

To learn which CumulusCI flows are best designed for creating scratch
orgs, running CI builds, managing the development process, and more, see
[](cumulusci-flow).

## CumulusCI in GitHub Actions

GitHub Actions specify custom workflows that run directly in your GitHub
repository. These workflows perform a variety of tasks, such as running
test suites, performing linting checks on code, and creating code
coverage reports. CumulusCI can also execute flows in GitHub Actions,
making it possible to run scratch org builds and execute Apex and Robot
Framework tests that leverage the custom automation defined in
`cumulusci.yml`.

We offer a comprehensive framework for using [CumulusCI in GitHub Actions](github-actions).

## Other CI Systems and Servers

CumulusCI runs on top of virtually any containerized CI platform.
Running CumulusCI in these contexts requires configuring environment
variables to provide access to orgs and services [in a headless context](headless).

## Testing with Second-Generation Packaging

CumulusCI makes it easy to harness the power of second-generation
managed packages to implement an advanced, comprehensive testing process
for both first- and second-generation managed package products. This is
described in [](2gp-testing).

## Further Reading

```{toctree}
---
maxdepth: 1
---

cumulusci-flow
github-actions
2gp-testing
headless
```
