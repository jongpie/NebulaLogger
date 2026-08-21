---
title: PR conventions
description: Commit style, PR style, and the checklist for opening a PR against NebulaLogger.
---

## Base branch and merge strategy

- Base branch is `main`. Fork the repo, work in a `feature/*` or `bugfix/*` branch, open a PR against `main`.
- **Squash-and-merge only** (repo setting). Write your commits as if they'll be squashed - the PR title and description are what land in `main`.

## Commit style

- **Past tense**, describes the change: "Added X", "Fixed Y", "Split A into B".
- Do NOT use `feat:` / `chore:` / `fix:` conventional-commit prefixes. They don't match this repo's history.
- Do NOT hard-wrap commit-message bodies. A paragraph is one line, however long it needs to be. Only insert newlines between subject/body and between logical paragraphs.
- Do NOT use em dashes (`-`) or en dashes (`–`). Use a plain ASCII hyphen (`-`) with spaces on both sides for a pause: `-`.
- Do NOT mention test-pass counts. Green tests are the precondition for committing at all - noting "all N tests pass" is redundant.
- No Markdown formatting inside the commit message body (no `**bold**`, no `##` headings, no bullet decorations). `git log` renders commit messages verbatim.

## Identifiers

- Spell in full. `directory` not `dir`, `configuration` not `cfg`.
- Acronyms are uppercase in prose: `ID`, `URL`, `API`, `JSON`. In code, follow the file's existing casing convention.
- Don't repeat the object name in a field name. On `LoggerNotificationRecipient__c`, the recipient's user lookup is `User__c`, not `RecipientUser__c`.
- Boolean fields start with a verb - `IsEnabled__c`, `SupportsUser__c`, `HasError__c`. Avoid bare adjectives like `Required__c`.

## Naming: no `Base` in identifiers

Do not name files, classes, or components `<Something>Base`, `<Something>BaseClass`, or any variant containing the word `Base`. Name things after what they do, not their role in a composition or inheritance hierarchy.

## SObjectType casing

Write `SObjectType` (PascalCase) or `sobjectType` (camelCase). Never `SobjectType` (only leading `S`) and never `sObjectType` (capital `O` mid-word).

## Product name

The product is **Nebula Logger**. Always use the full name in prose - never shorten to "Nebula" alone.

## DML routes through LoggerDataStore

Never write raw `insert x;` / `update x;` / etc. in Nebula Logger Apex - main code and tests. Every DML and every `System.enqueueJob(...)` routes through `LoggerDataStore.getDatabase().*` or `LoggerDataStore.getJobQueue().enqueueJob(...)`.

## Testing

Every code change ships with tests. See [Testing](/NebulaLogger/contributing/testing/).

- Apex: `Foo_Tests.cls` with `it_should_*` methods.
- LWC: colocated `__tests__/foo.test.js` using `sfdx-lwc-jest`.
- Jest tests validate the _data_ sent to Apex methods (`toHaveBeenCalledWith`), not just that they were called.

## Before opening a PR

1. `npm run prettier:fix` - format staged files.
2. `npm run scan` - PMD + ESLint + SLDS.
3. `npm run test:apex:nocoverage` (or full `npm run test:apex` if the change is bigger).
4. `npm run test:lwc:nocoverage` (or full `npm run test:lwc`).
5. Update docs if you changed public API - see [Docs generation](#docs-generation) below.
6. Squash or amend as needed to keep the history clean.

## Docs generation

Public/global Apex and LWC APIs are documented via `@cparra/apexdocs` and `jsdoc-to-markdown`. If you change a public API:

```bash
npm run docs:fix
```

That runs the docs generation script. Commit the updated Markdown files under `docs/src/content/docs/reference/`.

Verify before pushing:

```bash
npm run docs:verify
```

Passes if the docs are already up-to-date. Fails and prints the diff if not.

## AI contributor guide

`CLAUDE.md` at the repo root contains conventions specifically for AI coding agents. If you're working with Claude Code, Cursor, or a similar tool, that file is what they'll load. Human contributors should skim it too - it's a short-form companion to `CONTRIBUTING.md`.

## Where next

- [Repo layout](/NebulaLogger/contributing/repo-layout/).
- [Local development setup](/NebulaLogger/contributing/local-setup/).
- [Testing](/NebulaLogger/contributing/testing/).
