# Dynamic-Query Mocking Prototypes

Three prototype designs for replacing the existing `*Selector` classes with
**dynamic queries** (`LoggerQuery`). All three share the same production
shape — call sites build queries inline with a fluent, typed
`LoggerQuery.of(SObjectType).whereField(...).toList()` — so there are
**no per-query hand-written methods on the repositories**. Repositories are
thin facades that expose `newQuery()` plus any genuinely non-trivial
domain helpers; routine queries live at the call site.

The interesting question is: **with dynamic queries, how do tests stub
specific query results?** Each prototype answers it differently.

## The 3 approaches

| | What the test code looks like | Where the magic lives |
|--|--|--|
| **1. Fingerprint matching** | `LoggerQuery.mockResult().forSObjectType(Log__c.SObjectType).withFilterOn(Log__c.TransactionId__c).thenReturn(...)` | Each query computes a "fingerprint" (SObject + filter fields) and looks it up in a registry |
| **2. Pluggable executor** | `LoggerQuery.setExecutor(mockExecutor)` where the executor is a test-defined class that maps queries → results however it wants | A single `Executor` interface inside `LoggerQuery` is swappable; tests provide their own |
| **3. Tagged queries** | Production: `LoggerQuery.of(...).tag('LogHandler.parentLookup')...` Test: `LoggerQuery.mockResult('LogHandler.parentLookup', ...)` | Production code opts-in to mockability by tagging specific queries with a unique name |

## Layout

```
query-prototypes/
├── README.md                              ← you are here
├── 01-fingerprint-match/                  ← match by SObject + filter fields
│   ├── LoggerQuery.cls
│   ├── LoggerRepositoryFactory.cls
│   ├── LogHandlerSlice.cls                ← shared shape: 3 dynamic queries
│   ├── LogHandlerSlice_Tests.cls
│   └── NOTES.md
├── 02-pluggable-executor/                 ← swap the entire executor in tests
│   └── (same structure)
└── 03-tagged-queries/                     ← per-query opt-in tag
    └── (same structure)
```

## Same scenario across all three

The production-side `LogHandlerSlice` runs the same 3 dynamic queries in
each prototype:

1. **Parent-log lookup** — `Log__c` filtered by `TransactionId__c` IN list
2. **Queue lookup** — `Group` filtered by `Type = 'Queue'` AND `DeveloperName` IN list
3. **User lookup** — `User` filtered by `Username` IN list

…then writes derived fields back to the input logs. Tests cover the
"happy path" and one edge case to show how each prototype scales from
1 stubbed query to 3.

## What to compare

When reading the three test files side-by-side:

1. **Test setup lines** for the 1-query case and 3-query case.
2. **Specificity of the mock match** — does it stub *exactly* the right
   query, or could it accidentally match an unrelated query in the same
   transaction?
3. **What happens to "unmocked" queries** — do they hit the database, or
   error loudly?
4. **Refactor safety** — if production code adds a new filter to an existing
   query, does the test break (good — forces re-thinking) or silently keep
   matching?
5. **Production code intrusion** — does production code need to know it's
   being mocked?

## ⚠️ Not for deployment

These files live under `nebula-logger/dev/` outside the package contents and
are not deployed. Once a winner is picked, it moves into
`nebula-logger/core/main/...` and the others are deleted.
