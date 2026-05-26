# Prototype 1 — Fingerprint Matching

Each `LoggerQuery` carries metadata about which `SObjectType` it queries and
which fields appear in its `WHERE` clauses. Tests register mock results
keyed by that fingerprint:

```apex
LoggerQuery.mockResult()
  .forSObjectType(Schema.Log__c.SObjectType)
  .withFilterOn(Schema.Log__c.TransactionId__c)
  .thenReturn(new List<Log__c>{ mockLog });
```

When `query.toList()` runs, it walks the registry; if any registration's
SObjectType matches and its filter-field set is a subset of the query's
filter-field set, the registered result is returned and the SOQL never
executes.

## Pros

- **Production code is mock-unaware.** No tags, no executor argument — the
  call site just builds the query naturally. Mockability is a property of
  `LoggerQuery`, not of the calling code.
- **Field references are typed.** `withFilterOn(Schema.Log__c.TransactionId__c)`
  fails at compile time if the field is renamed.
- **The mock match is meaningful.** "All `Log__c` queries that filter on
  `TransactionId__c`" is a real description of what's being intercepted —
  reviewers can read the test and predict what it stubs.
- **Catch-all is available** by registering with no filter fields, which is
  the right primitive for "I don't care which Log__c query — just don't hit
  the DB."

## Cons

- **Ambiguity when multiple queries share a fingerprint.** If two production
  queries both filter `Log__c` by `TransactionId__c` (entirely possible),
  the test stubs both with one registration. Sometimes that's what you
  want; sometimes it's a bug waiting to happen.
- **Subset matching is a footgun.** A registration with
  `withFilterOn(Schema.Log__c.Id)` will match a query that filters on
  `Id AND TransactionId__c`. The test author may not realize they're stubbing
  more queries than intended.
- **Refactor sensitivity is mid.** Adding a new filter to a query *won't*
  break tests (subset still matches), but renaming the *only* filter field
  will (compile error on `withFilterOn`). That asymmetry is non-obvious.
- **No call verification by default.** "Was this query executed?" requires
  adding instrumentation to the registry.
- **Static registry leaks across tests** unless explicitly cleared. Easy
  fix: a `Test.startTest` hook or a `@TestVisible` `clearMocks()`.

## When this wins

The "obvious" case: each test wants to stub *the* query against *some*
SObjectType. Most existing Selector-based tests would translate to one
registration per stubbed query — readable and direct.

## When it loses

Tests that need to distinguish between two structurally-similar queries on
the same SObjectType (e.g. `Log__c` filtered by `Id` for the
"getDeleteableLogs" path vs. `Log__c` filtered by `Id` for the "getById"
path). Fingerprints aren't unique enough to tell them apart.

## Open questions for review

- Should subset matching be the default, or strict-equality matching?
  Strict means more registrations needed but no surprise overlaps.
- Should the registry be auto-cleared between tests, or should that be
  explicit? Auto-clear via a `@TestSetup` convention is fragile.
- For "I want to assert this query ran" — should the registry track which
  registrations were used, and offer a `LoggerQuery.assertAllMocksUsed()`
  helper?
- Does the `withFilterOn` API need to also support filter *values* for
  finer-grained matching, or is field-only enough? (Field-only is what
  most tests actually need based on the existing Selector-test corpus.)
