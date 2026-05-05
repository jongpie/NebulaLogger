<!--
  Thanks for contributing!

  This repository requires that pull requests be tied to an issue that has already
  been labeled `accepted` by a maintainer. Pull requests referencing an un-triaged
  issue (or no issue at all) will be held until the underlying issue is accepted —
  or closed if the underlying request is out of scope or a duplicate.

  Please read CONTRIBUTING.md before submitting:
  https://github.com/jongpie/NebulaLogger/blob/main/CONTRIBUTING.md
-->

## Linked Issue

Fixes #

> This pull request will not be reviewed unless the linked issue has been labeled `accepted`.

## Summary of Changes

<!-- What changed and why. Keep it focused — one logical change per PR. -->

## Type of Change

- [ ] Bug fix
- [ ] New feature (accepted issue)
- [ ] Refactor (no behavior change)
- [ ] Documentation
- [ ] CI / tooling / build

## Tests Added or Updated

<!--
  Describe the Apex and/or Jest tests you added or updated.
  If you did not add tests, explain why (e.g. metadata-only change).
-->

- Apex tests:
- Jest tests:

## Local Verification

Paste the commands you ran locally and confirm the results:

```text
npm run prettier:verify
npm run scan
npm run test:lwc:core   # or npm run test:lwc
npm run test:apex
```

## Checklist

- [ ] The linked issue has been labeled `accepted` by a maintainer.
- [ ] This pull request addresses a single logical change.
- [ ] New or modified Apex is covered by Apex tests (or explained above).
- [ ] New or modified LWC is covered by Jest tests (or explained above).
- [ ] `npm run scan`, `npm run prettier:verify`, and `npm test` pass locally.
- [ ] I have **not** modified generated artifacts: files under `docs/`, `website/`, package version IDs in `sfdx-project.json`, or package manifests.
- [ ] For UI changes, I attached screenshots or a short recording below.
- [ ] I have noted any risk, migration, or rollback considerations.

## Screenshots / Recordings

<!-- Required for UI changes. Delete this section if not applicable. -->

## Risk / Rollback Notes

<!-- Anything the maintainer should know about risk, migration, data impact, or rollback. Delete this section if not applicable. -->
