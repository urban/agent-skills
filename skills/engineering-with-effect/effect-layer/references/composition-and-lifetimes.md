# Composition and lifetimes

## Construction dependencies and output visibility

`consumer.pipe(Layer.provide(dependency))` builds the dependency first, feeds its Context into consumer construction, and returns only the consumer's output. `provideMerge` does the same wiring but retains both outputs. Hiding a dependency is not early release: it remains owned by the build's scope.

For already-chosen recipes `PoolLive`, `RepositoryLive` and `ReporterLive`, where both consumers require the pool:

```ts
import { Layer } from "effect"

// Both consumers receive the same pool acquisition in this build.
const Internal = Layer.merge(RepositoryLive, ReporterLive).pipe(
  Layer.provide(PoolLive)
)

// Alternatively, configure each consumer, then merge; stable PoolLive identity
// still permits sharing within the graph.
const Configured = Layer.merge(
  RepositoryLive.pipe(Layer.provide(PoolLive)),
  ReporterLive.pipe(Layer.provide(PoolLive))
)
```

Neither result exports the pool. Use `provideMerge(PoolLive)` instead when downstream code intentionally needs pool access. `Layer.merge(PoolLive, RepositoryLive)` does not wire the pool into repository construction: peers build concurrently from the same inputs.

Context service identity and Layer sharing identity are different. Context uses the service's string key; memoization uses the Layer object. Distinct providers for the same service key can both acquire resources even though only one value survives in the output. For duplicate keys, `merge`/`mergeAll` keep the later provider's value; `provideMerge` keeps the consumer's value over the dependency's. Avoid using collisions as an implicit implementation-selection mechanism.

## Sharing boundaries

A memo map caches acquisitions by layer identity, not by service key or construction inputs. Reuse a stable recipe for consumers that should share. Do not reuse the same input-dependent recipe under different configurations in one map and expect distinct instances.

| Boundary | Sharing behavior |
| --- | --- |
| One composed graph | Repeated memoized layer values share, including concurrent consumers |
| `Layer.build` / `buildWithScope` | Forks the ambient memo map, or creates a root if none exists |
| Nested `Effect.provide` with a layer | Reuses entries already present in the ambient map; new acquisitions stay local to its child map |
| `Effect.provide(effect, layer, { local: true })` | Uses an independent root map, without ambient acquisition reuse |
| `Layer.buildWithMemoMap` | Uses exactly the supplied map and scope; appropriate when the host must coordinate sharing explicitly |
| `Layer.fresh(subtree)` | Builds that subtree with a new root map on every build, while keeping the supplied scope |

A child memo map can reuse entries already built in its parent, but does not publish its own new entries back to the parent. Sibling builds therefore do not automatically share newly created resources. Two separate builds in the same scope are not, by that fact alone, one memoization domain.

Memoized acquisitions can have multiple scope owners. Closing one owner does not release a resource still observed by another; the last owner closes the acquisition scope and removes the entry. The map alone does not keep resources alive forever.

`fresh` isolates the subtree from outside memoization but preserves normal sharing *inside* that build. It does not clone preconstructed values or recreate dependencies already captured in closures. Keep expensive global pools outside a fresh request-state subtree and feed them in intentionally rather than freshening an entire graph.

## Scoped construction and host ownership

`Layer.effect` runs acquisition in the layer scope. Put `Effect.acquireRelease` or scope finalizers there; do not close an inner `Effect.scoped` around acquisition and then export the already-released handle. For background work, use scope-bound fiber ownership rather than detached workers.

Sequential dependency construction gives dependents a chance to finalize before their dependencies. Parallel peer construction does not establish a total acquisition or finalization order. On failed or interrupted construction, acquired resources must still be released; test observable cleanup rather than relying on peer ordering.

Manual building belongs at boundaries whose host explicitly owns the scope, such as plugin lifetimes. Use services only while their owner remains open. A returned Context is a lookup structure, not a transferable resource owner.

For repeated calls from a non-Effect host, `ManagedRuntime.make(layer)` lazily builds and caches the graph. Separate runtimes have separate memo maps by default; supplying the same map intentionally shares matching layer identities across them. Each runtime still needs disposal. Disposal interrupts and awaits its managed request fibers before releasing its layer resources; shared resources survive until the last observing owner closes. Do not reuse a disposed runtime.

Operation-local provision is appropriate for deliberate activation or lifetime policy, not incidental wiring. Its scope closes when the wrapped operation exits, but default memo-map inheritance may reuse outer acquisitions. Choose isolation explicitly when state must be independent.

## Deferred selection and construction failures

An ordinary layer recipe defers effectful acquisition, not arbitrary JavaScript used to create the recipe. `Layer.suspend(() => recipe)` defers recipe creation; `Layer.unwrap(effectSelectingRecipe)` supports effectful selection. Their selection is shared with the resulting memoized layer, not repeated for every service-method invocation.

Keep construction failures recoverable while a caller can select a fallback, report configuration, or retry startup. Convert them to defects only at a boundary where no caller can recover. `ManagedRuntime` caches a failed build as well as a successful one: repeating or retrying host calls will see that failure again. Apply recovery inside construction or dispose and create a new runtime.

## Disabled branches and optional recovery

Choose disabled behavior from the capability contract. `Layer.empty` fits additive infrastructure such as optional tracing, where the program needs no service supplied exclusively by that branch. If the program needs a client in both modes, select between implementations of that client. A no-op is appropriate only when doing nothing is valid product behavior; it is not a safe default for required authorization or persistence.

Optionality also determines recovery ownership. Required infrastructure normally retains typed acquisition failures. For diagnostics that may be lost without changing product behavior, recover narrowly on the diagnostics Layer before providing it to the program. For example, if the policy deliberately tolerates all diagnostics construction causes:

```ts
const bestEffortDiagnostics = diagnosticsLive.pipe(
  Layer.catchCause(() => Layer.empty)
)

const run = program.pipe(Effect.provide(bestEffortDiagnostics))
```

Prefer recovery for specific typed failures when defects are not part of the fallback policy. Cause-level recovery is a broader choice, not a requirement for optional infrastructure or a way to continue canceled work. Configuration validation can remain outside the recovered Layer when malformed configuration must still be reported.

Putting recovery around `program.pipe(Effect.provide(diagnosticsLive))` also catches program failures and can turn a failed operation into success. Let ordinary provision preserve the program's success, typed failure, defects, and interruption; do not catch and reconstruct them merely to observe execution.
