# Prototype 3 — Tagged Queries

Production code opts a query into mockability by giving it a unique tag.
Tests stub the result by that tag. Untagged queries always run real SOQL.

```apex
// Production:
List<Log__c> parentLogs = (List<Log__c>) LoggerQuery.of(Schema.Log__c.SObjectType)
  .tag('LogHandler.parentLookup')
  .selectField(Schema.Log__c.Id)
  .whereField(Schema.Log__c.TransactionId__c)
  .inCollection(parentLogTransactionIds)
  .toList();

// Test:
LoggerQuery.mockResult('LogHandler.parentLookup', new List<Log__c>{ mockParentLog });
```

## Pros

- **Unambiguous matching.** The tag is a unique key; there's no fingerprint
  overlap and no risk of one stub matching multiple production queries.
  Two queries that filter `Log__c` by `TransactionId__c` get distinct tags
  if they serve distinct purposes — the test author is forced to be
  explicit.
- **Shortest test syntax of the three.** A single fluent expression
  (`LoggerQuery.mockResult('tag', value)`) — no fingerprint builder,
  no executor class.
- **Free call-count assertions.** Because each tag is unique, the
  registry can count invocations per tag, giving you
  `Assert.areEqual(0, LoggerQuery.callCountForTag('...'))` with no extra
  instrumentation.
- **Untagged queries are explicitly un-stubbable.** Anything performance-
  critical or "this should hit the DB no matter what" can simply omit
  `.tag(...)` and become unmockable by design.
- **Easy to grep.** "Where is `LogHandler.parentLookup` set?" → grep the
  string. The tag links production and test files together.

## Cons

- **Production code carries a test-only concern.** `.tag('...')` exists
  solely to support testing. That's a meaningful philosophical departure
  from prototypes 1 and 2, where production code is mock-unaware.
- **Tags are stringly-typed.** No compile-time check that
  `LoggerQuery.mockResult('LogHandler.parentLookup', ...)` matches a real
  tag in production code. Renaming the production tag breaks tests
  silently (test still compiles, but the stub never fires and the query
  hits the DB during the test — which then fails for unrelated reasons).
  Mitigation: tag constants on the calling class, e.g.
  `LogHandler.PARENT_LOOKUP_TAG = 'LogHandler.parentLookup'`. But that
  adds the boilerplate back.
- **Tags become public API.** Once a tag is referenced by a test (or
  worse, by a customer's plugin test), renaming it is a breaking change.
- **Easy to forget.** A new query that should be mockable but isn't tagged
  will silently hit the DB during tests. Prototype 2's "throw on unknown
  query" mitigation isn't available here, because the registry doesn't
  even know the query exists if it has no tag.
- **Tag uniqueness is by convention, not enforced.** Two callers
  accidentally using the same tag will share the stub. Could add a
  registration-time guard, but that doesn't help the test author who's
  reusing a tag deliberately for "all of these should return the same
  thing".

## When this wins

- Tests that need rock-solid identification of which query is being
  stubbed (e.g. a class with two structurally-similar queries on the
  same SObjectType, where Prototype 1's fingerprint matching falls
  apart).
- Codebases that want call-count assertions on specific queries without
  building an executor framework.
- Teams that prefer the shortest possible test syntax.

## When it loses

- Codebases where "production code must not contain test concerns" is a
  hard requirement. The tag is unambiguously a test concern leaking into
  production code.
- Cases where the set of queries is large and labeling each one is
  tedious. Prototype 1's fingerprint registers once and matches many.

## Open questions for review

- Should tags be enforced as constants somewhere (e.g. an `enum` or a
  class of `static final` strings), or is free-form string OK?
- Should there be a lint / PMD rule that fails CI when production code
  contains a tag that no test references (dead-tag detection)?
- Does the `Object` return type on `mockResult` cost us too much
  type safety? An overloaded set (`mockResult(tag, List<SObject>)`,
  `mockResult(tag, SObject)`) would catch some classes of typo at
  compile time.
- Should `tag(...)` be a no-op outside of tests (i.e. only stored when
  `Test.isRunningTest()` is true), to make explicit that production
  doesn't carry the cost? Probably negligible either way, but worth
  thinking about.
