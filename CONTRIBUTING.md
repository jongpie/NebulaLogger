# Contributing to Nebula Logger

Thanks for your interest in contributing! Nebula Logger is maintained primarily by one person, so a little process goes a long way toward getting your change merged. Please read this document carefully before opening an issue or pull request.

## Before You Write Any Code

1. **Search first.** Check [open and closed issues](https://github.com/jongpie/NebulaLogger/issues?q=is%3Aissue), the [wiki](https://github.com/jongpie/NebulaLogger/wiki), and the [documentation site](https://jongpie.github.io/NebulaLogger/). Most requests have already been discussed.
2. **Open an issue and wait for triage.** Do **not** open a pull request at the same time as (or immediately after) opening an issue. Issues are triaged and must be labeled `accepted` by a maintainer before a pull request will be reviewed. This avoids wasted work on duplicates, out-of-scope requests, or changes that conflict with the roadmap.
3. **Expect discussion.** Bug reports may need reproduction steps. Feature requests may be declined, deferred, or reshaped. Please don't take it personally — the goal is a sustainable, coherent product.

## Questions vs. Bugs

"How do I…" and "Is this supported?" belong in [Discussions](https://github.com/jongpie/NebulaLogger/discussions), not Issues. The issue tracker is reserved for actionable bugs and accepted enhancements.

## What Will Get a Pull Request Rejected or Held

To save everyone time, pull requests are closed or held if they:

- Reference an issue that has not been labeled `accepted`.
- Add or change production Apex without Apex test coverage for the new behavior.
- Add or change an LWC or Aura component without corresponding Jest tests.
- Fail CI: `npm run scan:apex`, `npm run scan:lwc`, `npm run prettier:verify`, `npm run test:lwc`, or any of the scratch-org Apex test jobs.
- Bundle unrelated changes, opportunistic refactors, or whitespace-only churn alongside a fix. Keep pull requests focused on one issue.
- Change public Apex, LWC, or Flow APIs without a clear deprecation plan.
- Modify packaging metadata (`sfdx-project.json`, package manifests, package version IDs) without coordinating with the maintainer first — the release pipeline generates these.
- Edit files under `docs/` or `website/` by hand; those are generated via `npm run docs:fix`.

## Pull Request Checklist

- [ ] Linked to an `accepted` issue using `Fixes #1234` in the pull request description.
- [ ] One logical change. Title describes what, not how (≤ 70 characters).
- [ ] New or modified Apex is covered by Apex tests.
- [ ] New or modified LWC is covered by Jest tests.
- [ ] `npm test` passes locally.
- [ ] `npm run scan` passes locally (no new PMD or ESLint violations).
- [ ] `npm run prettier:verify` passes locally.
- [ ] Screenshots or a short recording attached for UI changes.
- [ ] No changes to generated artifacts (`docs/`, package version IDs, manifests).

## Test Expectations

- **Apex:** any new class, method, or branch must be covered by a focused test in the corresponding `*_Tests.cls`. Aim for behavior assertions, not just coverage. Tests use `LoggerMockDataCreator` and related utilities — follow existing patterns rather than introducing new mocking styles.
- **LWC:** co-locate Jest tests under `__tests__/`. Mock Apex imports via `@salesforce/sfdx-lwc-jest`. See existing tests such as `relatedLogEntries.test.js` for the pattern.
- **Coverage:** the repo targets high coverage (reported via Codecov). Pull requests that materially drop coverage will be sent back for more tests.
- **No-test exceptions:** metadata-only or documentation-only changes may be submitted without new tests. Call this out explicitly in the pull request description — "No tests added because ..." — so the reviewer doesn't have to guess.

## Scope Guidance

Nebula Logger is intentionally broad (Apex, LWC, Flow, Platform Events, Big Objects, plugins). Please:

- Propose cross-cutting refactors **as an issue first**, not as a pull request.
- Keep bug fixes minimal — fix the bug and add the regression test; don't restructure surrounding code in the same pull request.
- Don't introduce new dependencies without prior discussion.

## Local Development

Once an issue is `accepted` and you're ready to start work, develop in any scratch org, sandbox, or developer-edition org. Salesforce CLI, VS Code, and npm are recommended — this repository includes several scripts and automations using these tools. You can use any tools you prefer, so long as the resulting changes conform to the repository's coding standards.

1. Fork this repository and clone your fork locally.
2. Create a `feature/<short-name>` or `bugfix/<short-name>` branch from `main`.
3. Run `npm install` to install dependencies and register the repository's git hooks.
4. Make your changes. The pre-commit hook will:
   - Auto-format with Prettier.
   - Run code-analyzer (PMD for Apex, ESLint for LWC) on changed files.
5. Run these commands before pushing:
   - `npm run scan`
   - `npm run test:lwc:core` (or `npm run test:lwc` for broader LWC impact)
   - `npm run test:apex`
6. Open a pull request against `main`.

## Commit and Branch Conventions

- Branch from `main` as `bugfix/short-name` or `feature/short-name`.
- Pull requests are squash-merged, so commit history inside the branch is flexible — but write a meaningful final squash message.
- Do not force-push after review has started unless asked.

## Pull Request Description: What to Include

- Linked issue (`Fixes #123`).
- What changed and why.
- Commands you ran locally and the results.
- Screenshots or recordings for UI changes.
- Risk and rollback notes for impactful metadata changes.
- If no tests were added or updated, a short "why not" explanation.

## Security

Do **not** file public issues for security vulnerabilities. Use [private vulnerability reporting](https://github.com/jongpie/NebulaLogger/security/advisories/new) instead.

## Code of Conduct

Participation in this project is governed by the [Code of Conduct](./CODE_OF_CONDUCT.md).
