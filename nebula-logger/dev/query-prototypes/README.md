# Query / Repository Prototypes

Three prototype designs for replacing the existing `*Selector` classes with a
`LoggerRepositoryFactory` + per-SObject repositories. All three keep the
factory as the single top-level entry point so we don't add many top-level
Apex classes; they differ only in **how tests stub repository results**.

The same target scenario is rewritten in each prototype so the ergonomics can
be compared apples-to-apples. The scenario is a simplified version of
`LogHandler.executeBeforeInsert` covering 3 repository calls:

1. `LogRepository.getLogsByTransactionId(...)` (used by `setParentLog`)
2. `GroupRepository.getQueuesByDeveloperName(...)` (used by `setOwnerId`)
3. `UserRepository.getUsersByUsername(...)` (used by `setOwnerId`)

…plus one DML call routed through `LoggerDataStore` (left unchanged).

## Layout

```
query-prototypes/
├── README.md                              ← you are here
├── 01-virtual-factory/                    ← virtual factory + virtual repos
│   ├── LoggerRepositoryFactory.cls
│   ├── LoggerRepositoryFactory.cls-meta.xml
│   ├── LogHandlerSlice.cls                ← simplified LogHandler against factory
│   ├── LogHandlerSlice.cls-meta.xml
│   ├── LogHandlerSlice_Tests.cls          ← test rewritten for this prototype
│   ├── LogHandlerSlice_Tests.cls-meta.xml
│   └── NOTES.md
├── 02-stub-api/                           ← Test.createStub against interfaces
│   └── (same structure)
└── 03-method-registry/                    ← per-method whenCalled().thenReturn()
    └── (same structure)
```

`LogHandlerSlice` is intentionally a small slice of [`LogHandler`](../../core/main/log-management/classes/LogHandler.cls)
focused on just the multi-repo paths so the test diffs stay readable. The
shape of the *production* call site is identical across all three prototypes —
only the test code changes.

## What to compare

When reading the three `LogHandlerSlice_Tests.cls` files side-by-side, look
for:

1. **Lines of test setup** for the common case (stub 1 method) and the
   complex case (stub 3 methods across 3 repos).
2. **Refactor safety** — if someone renames a repository method, does the
   test fail at compile-time, test-runtime, or silently call through?
3. **Public surface** — how many new top-level types each forces us to
   expose.
4. **Readability** — at-a-glance, can you tell what was stubbed and what
   wasn't?
5. **Call verification** — how easy is "assert this method was called with
   these args".

## ⚠️ Not for deployment

These files are **not intended to be deployed** — they live under
`nebula-logger/dev/` outside the package contents. Once a winner is picked,
the chosen prototype is moved into `nebula-logger/core/main/...` and the
others deleted.
