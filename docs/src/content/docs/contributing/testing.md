---
title: Testing
description: Running Nebula Logger's Apex, LWC, and Playwright test suites locally.
---

Every code change ships with tests in the same PR - not a follow-up. This page covers how to run them locally.

## Apex tests

Against the default org (with coverage):

```bash
npm run test:apex
```

Faster - no coverage:

```bash
npm run test:apex:nocoverage
```

Targeted by suite (each plugin has its own):

```bash
npm run test:apex:suite:core
```

## LWC tests

```bash
npm run test:lwc
```

Or without coverage (faster for iteration):

```bash
npm run test:lwc:nocoverage
```

**Do not run `npx jest` directly.** The repo uses `sfdx-lwc-jest`, which isolates a pre-existing test pollution issue that raw `jest` exposes.

## Everything at once

```bash
npm test
```

Runs `test:lwc` then `test:apex`.

## Static analysis

```bash
npm run scan
```

Runs `sf code-analyzer` for both Apex (PMD) and LWC (ESLint + SLDS linter). CI treats any severity 1-3 violation as failure - fix it, don't add to the ignore list.

Individually:

```bash
npm run scan:apex
npm run scan:lwc
```

## Formatting

```bash
npm run prettier:fix
```

Runs Prettier across the codebase. There's a pre-commit hook, but running manually before pushing catches formatting drift early.

## When touching a test, actually run it

Writing or editing a test without running the suite once before signaling "done" is not a task done - it's a task in a broken state that the maintainer has to babysit. The rule applies to every level:

- **Apex tests**: `npm run test:apex:nocoverage` (fast) or targeted `sf apex run test --tests <ClassName>`.
- **LWC tests**: `npm run test:lwc:nocoverage`.
- **Playwright / e2e tests** (`nebula-logger/plugins/notifications` and similar): `npm run test:e2e:notifications` (or `:headed` for local iteration).

E2e is the one that gets skipped most often because it's slow - don't skip it. If a spec you touched hangs or times out, that's the bug to fix, not to hand off.

## Where next

- [Repo layout](/contributing/repo-layout/) - where test files live.
- [PR conventions](/contributing/pr-conventions/) - commit and PR style.
