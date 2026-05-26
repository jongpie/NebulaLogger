# Prototype 1 — Virtual Factory + Virtual Repos

Tests subclass `LoggerRepositoryFactory` and the inner repo classes; results
are returned by overriding methods. Closest in spirit to the existing
`*Selector` pattern.

## Pros

- **100% compile-time safe.** Rename a method on the base repo and every
  override breaks loudly.
- **Debuggable.** Stack traces point at real overridden methods, not stub
  handlers or registry lookups.
- **No new top-level classes.** Repos are inner classes of the factory; tests
  declare their stubs as inner classes inside the test.
- **Familiar.** This is structurally what Nebula Logger already does with
  `LogManagementDataSelector` etc., just consolidated under one factory.

## Cons

- **Boilerplate per stubbed method.** Each repo method you want to mock needs
  a public field + an override on the stub repo. The two tests in the example
  produce ~50 lines of stub plumbing for ~3 mocked methods.
- **Stub repos must extend the base repo.** Means tests can't (easily) assert
  "this method was never called" — you'd need to add a counter field manually
  to each override.
- **Constructors must be `protected` + `@TestVisible`** to permit subclassing
  outside the factory while keeping the production-side `new` calls
  uncontrolled.

## When this wins

Tests that stub **many methods on the same repo** and reuse those stubs
across many test methods — once the stub class is written, every test gets
to use it cheaply.

## When it loses

Tests that only stub 1–2 methods and don't reuse the stub elsewhere — the
boilerplate cost-per-stub is high.

## Open questions for review

- Is the `WithXxxRepository(...)` builder on the mock factory worth keeping,
  or should the test just assign public fields directly? (Builder reads
  better but is more code on the stub side.)
- Should the `protected` constructor on `LogRepository` etc. be `@TestVisible
  protected` or fully `public`? `protected` enforces that production code
  always goes through the factory, which is the design intent.
