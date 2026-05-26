# Prototype 2 — Pluggable Executor

`LoggerQuery` never calls `Database.query` directly. It hands itself to an
`Executor` interface that production wires to a real-SOQL implementation
and tests swap with their own. The test executor receives the full
`LoggerQuery` (SObjectType, selected fields, filter fields, filter values,
limit) and decides what to return — using whatever matching logic the test
cares about.

```apex
StubExecutor stub = new StubExecutor()
  .when(Schema.Log__c.SObjectType, Schema.Log__c.TransactionId__c, mockLogs)
  .when(Schema.Group.SObjectType, Schema.Group.DeveloperName, mockQueues);
LoggerQuery.setExecutor(stub);
```

## Pros

- **Most flexible matching of the three.** The executor sees the full
  query — it can match on filter values, exact SOQL string, query order,
  call count, anything. Prototypes 1 and 3 are limited to the matching
  primitives baked into the registry.
- **Production code is mock-unaware.** Same as Prototype 1.
- **Unmocked queries fail loudly.** A well-written test executor throws on
  unregistered queries, so a refactor that adds a new query path can't
  silently hit the database mid-test.
- **Trivially extensible per-test.** Need to match on something weird (e.g.
  "second call returns empty")? Write a one-off executor inline. No
  framework changes.
- **Reusable at multiple altitudes.** Common matching patterns become
  shared executor utilities (e.g. `BySObjectTypeStubExecutor` lives in a
  test helper); one-off matching stays inline. Prototypes 1 and 3 force
  one matching style.

## Cons

- **More boilerplate for the simple case.** The simplest test still needs
  to write `new StubExecutor().when(...)` and `LoggerQuery.setExecutor(...)`.
  Prototype 1's `LoggerQuery.mockResult()...` is one expression.
- **No built-in matching primitives.** Every project / team writes their
  own `StubExecutor`. Could be solved with a default helper shipped under
  `LoggerQuery` — but then we're partially recreating Prototype 1 inside
  Prototype 2's framework.
- **Test executors are full classes** in Apex (no closures). For one-off
  matching, this is more ceremony than Prototype 1's fluent registration.
- **Forgetting to reset the executor between tests** is silent — the
  previous test's executor stays active. Mitigation: a `@TestSetup` that
  calls `LoggerQuery.setExecutor(...)` with the default, or auto-reset on
  `Test.startTest()`.

## When this wins

- Tests that need to match on **filter values** or other query specifics
  beyond just SObjectType + filter fields.
- Codebases that expect to add custom test-time behaviors over time
  (e.g. record-level result fixtures, query-count assertions, simulated
  governor-limit failures). The executor is the natural extension point.
- Plugin/customer tests that want to define their *own* matching DSL
  rather than living inside ours.

## When it loses

- The vast majority of tests where "stub one query, return one list"
  is the entire need. Prototype 1's fluent registration is shorter for
  that case.
- Teams that don't want to maintain a shared `StubExecutor` helper —
  every team rebuilds it slightly differently.

## Open questions for review

- Should we ship a default `BySObjectTypeStubExecutor` helper alongside
  `LoggerQuery` so the simple case isn't slow? If yes, does that just
  reinvent Prototype 1 with extra steps?
- Should `Executor` be `global` so plugins/customers can implement it?
  If yes, the interface is part of the supported public API forever.
- Is exposing the LoggerQuery's filter values via a public getter
  acceptable, or does that leak too much internal state? (The executor
  needs *some* way to inspect the query.)
- Should there be a guard that prevents `setExecutor()` outside of
  `Test.isRunningTest()`? Otherwise plugin code could swap the executor
  in production, which is almost certainly a footgun.
