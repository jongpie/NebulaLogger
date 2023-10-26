# Decision Records

This directory contains the Architectural Decision Records (ADRs) for this project.

## Architectural Decisions (ADs)

We define "architectural decision" as any software design choice that addresses a functional or non-functional requirement that is architecturally significant, for example:

-   Which web framework to use
-   Whether to denormalize a database table
-   Whether or not to abandon a third-party test coverage aggregator

We store ADRs in the `docs/adrs` directory, named in this format: `000x-Title-of-ADR.md`.

## Tools

[`adr-tools`](https://github.com/npryce/adr-tools) is a simple CLI tool that manages ADRs. To install it via Homebrew:

```shell
brew install adr-tools
```

Create a new ADR

```shell
adr new Use FastDRF Library
```

which will create a new markdown document with the next number and open it for editing. To create a new decision record manually, simply copy the template at `templates/template.md` into this directory and name it appropriately.

## Workflow

1. Write an ADR outlining a decision for a particular problem.
2. Create a pull request assigned to yourself and submit. If you know who will review your PR, you should request a review.[^1]
3. The reviewer and other team members discuss the ADR. The ADR is updated during the review to add context, etc.
4. At the end of the review period, the ADR is either:

-   Approved: Status is "Accepted" and merge the PR, or
-   Rejected: Update Status to "Rejected" and close the PR.

5. Create a new ADR when reversing or revisiting a decision, linking to the decision record that it supercedes. Update the old ADR with a link to the superceding ADR.

## Links

-   [Suggestions for writing good ADRs](https://github.com/joelparkerhenderson/architecture-decision-record#suggestions-for-writing-good-adrs)

[^1]: We encourage you to include your ADR in pull requests alongside related code changes when it makes sense to review them together.
