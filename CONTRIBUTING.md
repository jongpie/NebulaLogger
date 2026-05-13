# Contributing

Contributions to Nebula Logger are welcome - following these guidelines will help make it easier & faster to review & merge any changes you want to contribute. When contributing, the typical process is:

1. Familiarize yourself with the codebase - you can check out the [wiki](https://github.com/jongpie/NebulaLogger/wiki) and the [Apex docs site](https://jongpie.github.io/NebulaLogger/) to learn more about the code.
2. Before starting your work, create a new issue (or add a comment to an existing issue you want to contribute to) so that we can keep track of who is actively working on an item.
3. Fork this repository.
4. Create a `feature` or `bugfix` branch in your fork based on the `main` branch.
5. Edit the code/metadata in your fork.
6. Send us a pull request when you are done. We'll review your code, provide feedback for any suggestions or required changes, and then merge it when everything is ready.

# Development

Once you're ready to start working on an issue, you can develop your changes in any scratch org, sandbox, or developer-edition org of your choosing. Using SFDX (Salesforce CLI), VS Code and npm are recommended - this repository includes several scripts and automations using these tools. However, you can use any tools that you prefer, so long as the resulting code changes still conform to the repository's coding standards.

- Clone your fork of the Nebula Logger repository locally
- Run `npm -i` or `npm install` to grab the latest version of our dependencies, and setup the repository's git hooks
- When committing your changes in `git`, the repository's git hooks automatically run to:
  1. Automatically fix/standardize some quality standards - for example, all Apex files will automatically be formatted using `prettier`
  2. Automatically verify coding standards - for example, all Apex files will be automatically scanned for PMD rule violations, based on the repository's configured PMD rules.
- Run all unit tests for LWC and Apex, and verify everything is passing prior to submitting a pull request

# Running the Build Pipeline Locally

The GitHub Actions workflow at `.github/workflows/build.yml` can be run locally with [nektos/act](https://github.com/nektos/act) and Docker. This is useful for catching pipeline failures before pushing.

## Prerequisites

- [Docker](https://www.docker.com/) (Docker Desktop on Windows/macOS, or the Docker engine on Linux)
- [`act`](https://github.com/nektos/act#installation) — install with `brew install act`, `winget install nektos.act`, or `choco install act-cli`

The repository's `.actrc` already pins the `ubuntu-22.04` runner image to `catthehacker/ubuntu:act-22.04`, which mirrors what GitHub Actions uses.

## Jobs that run locally without secrets

These two jobs work straight away — no Salesforce or Codecov credentials needed:

```bash
act -j code-quality-tests
act -j lwc-jest-tests
```

## Jobs that need real credentials

Every scratch-org job and the package-creation jobs hit a real Dev Hub. To run them locally:

1. Copy `.env.example` to `.env` (gitignored):

   ```bash
   cp .env.example .env
   ```

2. Fill in the values. `DEV_HUB_JWT_SERVER_KEY` is multi-line PEM content — `act` reads `.env` in dotenv format, so put the entire key on one line with literal `\n` separators between lines.

3. Pass the file to `act` for both env vars and secrets, then run a matrix entry:

   ```bash
   # Run all 6 scratch-org matrix entries (slow; creates 6 real scratch orgs)
   act -j scratch-org-tests --env-file .env --secret-file .env

   # Or run just one matrix entry
   act -j scratch-org-tests --env-file .env --secret-file .env --matrix config:base
   ```

   Tip: once you've created `.env`, you can drop `--secret-file .env` and `--env-file .env` into `.actrc` to have them applied automatically on every `act` invocation.

The Dev Hub allows a maximum of 3 active scratch orgs at a time, which the workflow enforces with `max-parallel: 3`.

## Triggering specific events

By default `act` runs the workflow's `push` event. To simulate a pull request:

```bash
act pull_request
```

# Pull Requests

- All pull requests should use the `main` branch as the base branch
- Your pull request should have a detailed description that describes your changes, and include any screenshots of noteworthy UI changes (when applicable)
- Pull request merging is restricted to only 'squash and merge'
