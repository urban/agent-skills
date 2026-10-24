# Optimistic updates, React, and tests

## Services and invalidation

Keep service-backed reads and writes in an `Atom.runtime(layer)` graph. Its default layer memoization and Reactivity service are registry-scoped: disposing one registry does not tear down another registry's services. Supplying a concrete memo map through `Atom.context({ memoMap })` deliberately shares layers across registries; do not use that to accidentally share session-owned clients.

Family keys identify distinct cached values. Reactivity keys group values affected by a write; they are not another cache. Attach query keys with the runtime factory's `withReactivity` and matching mutation keys through `runtime.fn`'s `reactivityKeys`. Use tenant/entity-qualified keys where broad invalidation would refresh unrelated views. Default invalidations do not broadcast across registries.

For Effect-backed mutations, automatic invalidation happens on success, not failure. If a failed request might have committed remotely, define an explicit reconciliation/refetch policy rather than assuming success-only invalidation discovers that outcome.

## Optimism and mutation overlap

`Atom.optimistic(source)` displays provisional values from transition atoms. `Atom.optimisticFn` computes a provisional value from the current view and input, then runs the mutation. For an async source, return an `AsyncResult` from the reducer so the view retains its lifecycle.

The source remains authoritative:

- Waiting successes from transitions supply the provisional display.
- While transitions remain active, source changes update the tracked source value without replacing the optimistic display.
- After transitions settle, any successful transition triggers source refresh; if all failed, the view returns to the latest observed source value, not an old captured snapshot.
- The mutation atom carries its failure; rolling back the displayed value is not a substitute for surfacing the failed write.

Treat this as UI reconciliation, not a transaction or a merge algorithm. Choose whether pending edits compose, replace one another, or must be serialized. Use server versions/idempotency where the domain requires protection against conflicting writes.

Ordinary `Atom.fn` replaces the running computation on another write; interruption cannot undo a server-side commit. `{ concurrent: true }` permits overlap but does not provide one independent result per call: an Effect-backed function waits for earlier active calls, and an earlier failure can determine the shared result even after a later success. Use separate mutation identities for independent operations, or serialize writes that must be ordered. Do not infer a queue or latest-response-wins behavior from the flag.

## React ownership and rendering

Use hooks from `@effect/atom-react`. Place a `RegistryProvider` at the state ownership boundary, not around every consumer. Without a provider, hooks use a standalone default registry; that is not request/session isolation.

The provider creates its registry once. Changing `initialValues` or other options later does not recreate or reseed it. `useAtomInitialValues` also initializes each atom at most once per registry; neither mechanism is ongoing prop synchronization. Use explicit writes for live inputs or a new registry boundary when ownership changes.

Choose rendering semantics deliberately:

- `useAtomValue` exposes the full lifecycle for explicit stale/error UI; a selector can narrow a rendered view without duplicating state.
- `useAtomSuspense` suspends on Initial, not refreshing values by default. Opt into `suspendOnWaiting` only if refresh should hide current content. Failures go to an error boundary unless `includeFailure` keeps them in the returned result.
- `useAtomSet(..., { mode: "promiseExit" })` returns an `Exit` for cause-aware event handling; `"promise"` rejects on failure. Both await the shared atom's next settled result. They do not correlate overlapping calls with their individual writes.

## Tests that exercise ownership

Test atom definitions through fresh registries; use provider tests for hook rendering and registry boundaries. Replace a runtime layer instead of mocking atom definitions:

```ts
import assert from "node:assert/strict"
import { Context, Effect, Layer } from "effect"
import { Atom, AtomRegistry } from "effect/reactivity"

const Count = Context.Service<{ readonly read: Effect.Effect<number> }>("Count")
const runtime = Atom.runtime(Layer.succeed(Count, { read: Effect.succeed(0) }))
const query = runtime.atom(Count.use((service) => service.read))
const testLayer = Layer.succeed(Count, { read: Effect.succeed(10) })
const registry = AtomRegistry.make({
  initialValues: [Atom.initialValue(runtime.layer, testLayer)]
})
try {
  const unmount = registry.mount(query)
  try {
    const result = registry.get(query)
    assert(result._tag === "Success")
    assert.equal(result.value, 10)
    assert.equal(result.waiting, false)
  } finally {
    unmount()
  }
} finally {
  registry.dispose()
}
```

High-value cases are domain-specific: equivalent keys reuse a member; distinct tenants/locales stay isolated; a failed refresh retains data and its cause; disposal releases streams/services; failed writes roll back to the latest source; reversed completion orders do not lose later edits. Assert provisional and reconciled values separately, including server-normalized responses.

Use latches or deferred responses to control completion order rather than relying on sleeps. For retention/freshness tests, control JavaScript timers and `Date.now()` as well as scheduled work: registry idle cleanup, refresh timers, and SWR timestamps are not driven solely by an Effect test clock.
