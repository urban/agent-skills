# Async state and identity

## Identity belongs to a registry

Import core primitives from `effect/reactivity` (or subpaths such as `effect/reactivity/Atom`). An atom describes state; an `AtomRegistry` holds its current value and dependency graph. The same definition can hold different values in different registries.

`Atom.family` memoizes definitions, not durable values. It uses `MutableHashMap` equality: plain records and arrays compare structurally by default; custom `Equal`/`Hash` implementations can change identity. Do not assume fresh object literals necessarily miss the cache, or mutate keys after hashing.

Include all dimensions that change meaning, not every transient UI field:

```ts
import { Atom } from "effect/reactivity"

type DraftKey = {
  readonly tenantId: string
  readonly documentId: string
  readonly locale: string
}

const draft = Atom.family((_key: DraftKey) => Atom.make(""))
const english = draft({ tenantId: "a", documentId: "42", locale: "en" })
const sameDraft = draft({ tenantId: "a", documentId: "42", locale: "en" })
const french = draft({ tenantId: "a", documentId: "42", locale: "fr" })
// english === sameDraft; english !== french
```

Where supported, families weakly retain their atom definitions. A later call can recreate a collected member; family membership does not keep its registry value alive. Scope private sessions with separate registries or include session identity in keys; a family is not itself a security boundary.

## Async lifecycle is two-dimensional

| State | Meaning | Rendering decision |
| --- | --- | --- |
| Initial | No completed result | Distinguish idle mutation from pending work using `waiting` |
| Success | Value and timestamp | Display data, with progress when `waiting` |
| Failure | Cause and optional `previousSuccess` | Show failure; deliberately decide whether retained data remains visible |

`waiting` is independent of the tag: a retry can be a waiting Failure. Effect/stream atoms preserve the latest exposed success on failure. `AsyncResult.value` also returns retained data from a Failure, so extracting a value alone is not evidence of request success. An effect that finishes synchronously may never expose a loading state.

Keep lifecycle through derived views:

```ts
import { Atom, AsyncResult } from "effect/reactivity"

const totals = Atom.make(AsyncResult.success({ unread: 3, archived: 8 }))
const unread = totals.pipe(Atom.mapResult((value) => value.unread))
```

`mapResult` maps the retained previous success too. Do not replace this with a component-local snapshot that stops tracking refresh or failure.

## Retention is not freshness

- Ordinary atoms auto-dispose when unused; active subscribers or dependents retain them. A one-off registry read is not a lifetime guarantee. Mount when work must remain live without a reader.
- `Atom.setIdleTTL` retains unused nodes for reuse; it does not make old data fresh or trigger a refetch when data reaches that age.
- `Atom.keepAlive` retains a used atom even without subscribers, but only within its registry. Disposing that registry still releases nodes and resources.

Define refresh policy beside the query. Use explicit invalidation for known writes, `Atom.withRefresh` for timed refresh, or `Atom.swr` when stale values should remain visible during revalidation. `swr` separates `staleTime` from retention; manual refresh still forces a source refresh. Its focus policy requires a signal, for example `focusSignal: Atom.windowFocusSignal`; `revalidateOnFocus: true` respects staleness, while `"always"` forces refresh. `Atom.refreshOnWindowFocus` is the unconditional signal-driven alternative.
