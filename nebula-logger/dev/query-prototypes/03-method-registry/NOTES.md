# Prototype 3 — Per-Method whenCalled Registry

Each repo carries its own `StubRegistry`. Tests configure it with
`repo.whenCalled('method').thenReturn(value)`. Production-side method bodies
each have one extra line at the top: `if stubs.hasStubFor('x') return
stubs.stubResultFor('x')`.

## Pros

- **Shortest test setup of the three.** One line per stub, no factory
  subclass, no Test.createStub(), no interface to reference.
- **No new top-level types.** Just `LoggerRepositoryFactory` and its inner
  `StubRegistry`. Smaller public surface than Prototype 2.
- **Production sees concrete classes** (no interface indirection), which
  also means call-site `instanceof` checks and direct member references work
  if ever needed.
- **Call-count tracking comes for free**, same as Prototype 2.

## Cons

- **Method names are strings.** Same downside as Prototype 2.
- **Production code carries stubbing concerns.** Every repo method has a
  `hasStubFor` check at the top. That's ~1 line of overhead per method
  forever, and the registry exists in production memory even when not used
  (small but real). Reviewers will reasonably ask "why does the production
  query path know about stubs?".
- **The `stubs` field is `public`** on each repo so tests can read call
  counts. That's a public, mutable field on a production class that no
  production caller should ever touch — slightly icky.
- **Stale stubs leak across tests** unless `@IsTest` setup explicitly resets
  them. Because the factory is a singleton and the repos cache their stubs,
  a stub registered in one test method bleeds into the next unless the
  factory or repos are reset between tests. (Prototype 1 & 2 don't have this
  because the mock is replaced wholesale per test.)

## When this wins

The "casual stub" case — drop in 1–3 lines and move on. For tests that don't
care about argument matching or call-order verification, this is the lowest
ceremony of the three.

## When it loses

- Anything where the production-code overhead bothers reviewers.
- Tests that need to share stub configuration across many test methods —
  there's no clean way to factor it out short of a shared static helper that
  re-registers stubs, which negates the brevity advantage.
- Anywhere the cross-test bleed of registered stubs is a footgun.

## Open questions for review

- Is the "production code knows about stubs" tradeoff acceptable? Could be
  softened by making `hasStubFor` return false in production via a
  `Test.isRunningTest()` short-circuit, but that hardcodes the test
  environment in a way I'd rather avoid.
- Should the factory expose a `resetStubs()` method that clears all
  registries, to make the cross-test bleed problem visible & solvable?
- Is having `stubs` as a public field on the repo too leaky? Could hide it
  behind `@TestVisible private` and add a public `callCountFor()` accessor on
  the repo itself.
