# Prototype 2 — Test.createStub against Interfaces

Tests build stubs via Apex's built-in `System.Test.createStub()` against the
per-repo interfaces (`ILogRepository`, etc.) using a small reusable
`LoggerStubHandler` to keep the syntax fluent.

## Pros

- **No subclasses per test.** Stubbing one method takes one line:
  `.whenCalled('getLogsByTransactionId', returnValue)`. Compare to ~15 lines
  per stub class in Prototype 1.
- **Built-in call-count tracking.** `stub.callCountFor('methodName')` works
  for free, so tests can easily assert "this method was never called" /
  "called exactly once".
- **Stubs don't leak into production class hierarchy.** Production repos
  don't need to be `virtual`, constructors don't need to be `protected
  @TestVisible`, etc. Cleaner production-side surface.
- **`LoggerStubHandler` is reusable.** Once written, it's the ONE helper
  every test in the codebase shares.

## Cons

- **Method names are strings.** Renaming a repo method does NOT break test
  compilation; the test silently falls through to a default null and fails
  with a confusing NPE / wrong-result later. Mitigation: name a `static
  final String METHOD_NAME = 'getLogsByTransactionId'` constant on the repo
  interface so a rename forces test updates — but that's a discipline cost.
- **Public surface adds 3 interfaces.** `ILogRepository`, `IGroupRepository`,
  `IUserRepository`. They're inner types of `LoggerRepositoryFactory`, but
  customers consuming the package may end up depending on them. Could be
  mitigated with naming (`LoggerRepositoryFactory.LogContract`?).
- **One extra top-level class.** `LoggerStubHandler` lives at top level
  because `@IsTest` classes can't be inner classes of non-test classes if
  also referenced from tests in other packages.
- **`@IsTest` global** would be needed for plugins/customers to use the
  helper too, which expands the supported public surface further.

## When this wins

Tests that stub 1–3 methods. The fluent `.whenCalled(...)` builder is
hard to beat for that case, and the built-in call-count tracking makes
verification ergonomic.

## When it loses

Heavy reuse of the same stub config across many tests — there's no clean
"shared stub class" pattern; every test rebuilds the stub. Could be
softened by extracting per-test-class helpers, but that's per-team
discipline.

## Open questions for review

- Are method-name strings acceptable, or is the loss of compile-time safety
  a dealbreaker? It's the single biggest tradeoff vs. Prototype 1.
- Should `ILogRepository` be `global` so plugins can use it? If yes, the
  whole interface becomes part of the supported API — every method on it
  is permanent.
- Should `LoggerStubHandler` support more than just method-name matching
  (e.g. argument matchers)? The bare-bones version is enough for the prototype
  but real tests sometimes need "return X for empty list, Y for non-empty".
